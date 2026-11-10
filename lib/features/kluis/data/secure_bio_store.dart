import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/l10n/strings.dart';
import '../crypto/vault_keys.dart';

/// Hardware-ondersteunde opslag van de biometrische wrapsleutel.
///  - Android: Keystore-sleutel die per bewerking sterke biometrie vereist
///    (BiometricPrompt, Class 3).
///  - iOS: Keychain-item met toegangscontrole `biometryCurrentSet`
///    (Face ID/Touch ID, ongeldig zodra de biometrische set wijzigt).
class SecureBiometricKeyStore implements BiometricKeyStore {
  SecureBiometricKeyStore({FlutterSecureStorage? storage, LocalAuthentication? auth})
      : _storage = storage ?? const FlutterSecureStorage(),
        _auth = auth ?? LocalAuthentication();

  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth;

  static const _key = 'kluis_bio_key';

  AndroidOptions get _android => const AndroidOptions.biometric(
        enforceBiometrics: true,
        requireBiometricsPerOperation: true,
        biometricType: AndroidBiometricType.strongBiometricOnly,
        storageNamespace: 'kluis',
        biometricPromptTitle: S.vaultBioPromptTitle,
        biometricPromptSubtitle: S.vaultBioPromptSubtitle,
        biometricPromptNegativeButton: S.vaultBioUsePin,
      );

  IOSOptions get _ios => const IOSOptions(
        accessibility: KeychainAccessibility.passcode,
        accessControlFlags: [AccessControlFlag.biometryCurrentSet],
      );

  @override
  Future<BiometricStatus> status() async {
    try {
      if (!await _auth.isDeviceSupported()) return BiometricStatus.unavailable;
      final types = await _auth.getAvailableBiometrics();
      return types.isEmpty ? BiometricStatus.notEnrolled : BiometricStatus.available;
    } catch (_) {
      return BiometricStatus.unavailable;
    }
  }

  @override
  Future<void> write(Uint8List key) => _storage.write(
        key: _key,
        value: base64Encode(key),
        aOptions: _android,
        iOptions: _ios,
      );

  @override
  Future<Uint8List> read() async {
    try {
      final v = await _storage.read(key: _key, aOptions: _android, iOptions: _ios);
      if (v == null) throw const BiometricInvalidated();
      return Uint8List.fromList(base64Decode(v));
    } on BiometricInvalidated {
      rethrow;
    } on PlatformException catch (e) {
      final m = '${e.code} ${e.message}'.toLowerCase();
      if (m.contains('cancel') || m.contains('negative') || m.contains('user') && m.contains('abort')) {
        throw const BiometricCancelled();
      }
      throw const BiometricInvalidated();
    } catch (_) {
      throw const BiometricInvalidated();
    }
  }

  @override
  Future<void> delete() =>
      _storage.delete(key: _key, aOptions: _android, iOptions: _ios);
}
