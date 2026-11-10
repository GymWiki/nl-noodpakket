import 'dart:convert';
import 'dart:typed_data';

import '../data/vault_files.dart';
import '../domain/lock_policy.dart';
import 'vault_crypto.dart';

// ------------------------------------------------------------ biometrie

enum BiometricStatus { available, notEnrolled, unavailable }

/// Mislukte of geannuleerde biometrische toegang.
class BiometricCancelled implements Exception {
  const BiometricCancelled();
}

/// De hardwaresleutel is ongeldig geworden (bijv. vingerafdruk toegevoegd/verwijderd).
class BiometricInvalidated implements Exception {
  const BiometricInvalidated();
}

/// Opslag van een sleutel die alleen na biometrische authenticatie leesbaar is
/// (Android Keystore / iOS Keychain). Abstract, zodat tests een fake kunnen gebruiken.
abstract class BiometricKeyStore {
  Future<BiometricStatus> status();
  Future<void> write(Uint8List key);

  /// Toont de biometrische prompt. Gooit [BiometricCancelled] of [BiometricInvalidated].
  Future<Uint8List> read();
  Future<void> delete();
}

// ---------------------------------------------------------------- fouten

class WrongPinException implements Exception {
  const WrongPinException(this.failedAttempts);
  final int failedAttempts;
}

class LockedOutException implements Exception {
  const LockedOutException(this.until);
  final DateTime until;
}

class VaultNotSetUpException implements Exception {
  const VaultNotSetUpException();
}

class SetupResult {
  const SetupResult(this.dataKey, this.recoveryCode);
  final Uint8List dataKey;
  final String recoveryCode;
}

/// Sleutelbeheer: één willekeurige datasleutel (DK, 256 bit) versleutelt alle
/// bestanden en metadata. DK staat nooit leesbaar op schijf, maar wordt drie
/// keer onafhankelijk "gewrapt" (AES-256-GCM):
///  - door een sleutel uit de kluis-PIN (Argon2id),
///  - door de herstelcode (HKDF, hoge entropie),
///  - door een hardware-sleutel met biometrie (optioneel).
class VaultKeyManager {
  VaultKeyManager(
    this.files, {
    required this.bio,
    this.kdf = KdfParams.pin,
    this.deriveInIsolate = true,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final VaultFiles files;
  final BiometricKeyStore bio;
  final KdfParams kdf;
  final bool deriveInIsolate;
  final DateTime Function() _now;

  static const minPinLength = 6;
  static const maxPinLength = 16;

  static List<int> _aad(String label) => utf8.encode('noodkluis:v1:$label');

  Future<Map<String, dynamic>?> _readHeader() async {
    final b = await files.readBytes(files.header);
    if (b == null) return null;
    try {
      return jsonDecode(utf8.decode(b)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeHeader(Map<String, dynamic> h) =>
      files.writeAtomic(files.header, utf8.encode(jsonEncode(h)));

  Future<bool> isSetUp() async => (await _readHeader()) != null;

  Future<bool> biometricsEnabled() async =>
      ((await _readHeader())?['bio'] as Map?)?['wrap'] != null;

  static bool isValidPin(String pin) =>
      RegExp('^[0-9]{$minPinLength,$maxPinLength}\$').hasMatch(pin);

  // -------------------------------------------------------------- instellen

  /// Richt de kluis in. Geeft de datasleutel (voor deze sessie) en de eenmalig
  /// te tonen herstelcode terug.
  Future<SetupResult> setUp({required String pin, required bool enableBiometrics}) async {
    if (!isValidPin(pin)) throw ArgumentError('ongeldige PIN');
    await files.ensure();
    final dk = randomBytes(keyLength);
    final pinSalt = randomBytes(16);
    final recSalt = randomBytes(16);
    final recoveryCode = generateRecoveryCode();

    final kPin = await deriveKeyFromSecret(pin, pinSalt, kdf, inIsolate: deriveInIsolate);
    final kRec = await deriveKeyHkdf(
        Uint8List.fromList(utf8.encode(recoveryCode)), recSalt, 'noodkluis recovery');
    final header = <String, dynamic>{
      'v': 1,
      'kdf': kdf.toJson(),
      'pin': {
        'salt': base64Encode(pinSalt),
        'wrap': base64Encode(await seal(kPin, dk, aad: _aad('pin'))),
      },
      'recovery': {
        'salt': base64Encode(recSalt),
        'wrap': base64Encode(await seal(kRec, dk, aad: _aad('recovery'))),
      },
      'createdAt': _now().toIso8601String(),
    };
    zero(kPin);
    zero(kRec);
    await _writeHeader(header);
    await _writeLockState(0, null);
    if (enableBiometrics) {
      await enableBiometricsFor(dk);
    }
    return SetupResult(dk, recoveryCode);
  }

  // ------------------------------------------------------------- ontgrendelen

  Future<Uint8List> _unwrap(Uint8List kek, String b64, String label) async =>
      open(kek, base64Decode(b64), aad: _aad(label));

  Future<Uint8List> unlockWithPin(String pin) async {
    final h = await _readHeader();
    if (h == null) throw const VaultNotSetUpException();

    final state = await _readLockState();
    final now = _now();
    if (state.until != null && state.until!.isAfter(now)) {
      throw LockedOutException(state.until!);
    }

    final params = KdfParams.fromJson(Map<String, dynamic>.from(h['kdf'] as Map));
    final pinPart = Map<String, dynamic>.from(h['pin'] as Map);
    final kPin = await deriveKeyFromSecret(
        pin, base64Decode(pinPart['salt'] as String), params, inIsolate: deriveInIsolate);
    try {
      final dk = await _unwrap(kPin, pinPart['wrap'] as String, 'pin');
      await _writeLockState(0, null);
      return dk;
    } on VaultAuthException {
      final failed = state.failed + 1;
      final delay = LockoutPolicy.delayFor(failed);
      await _writeLockState(failed, delay == Duration.zero ? null : now.add(delay));
      throw WrongPinException(failed);
    } finally {
      zero(kPin);
    }
  }

  Future<Uint8List> unlockWithRecovery(String code) async {
    final h = await _readHeader();
    if (h == null) throw const VaultNotSetUpException();
    if (!isValidRecoveryCode(code)) throw const VaultAuthException();
    final rec = Map<String, dynamic>.from(h['recovery'] as Map);
    final k = await deriveKeyHkdf(
        Uint8List.fromList(utf8.encode(normalizeRecoveryCode(code))),
        base64Decode(rec['salt'] as String),
        'noodkluis recovery');
    try {
      final dk = await _unwrap(k, rec['wrap'] as String, 'recovery');
      await _writeLockState(0, null);
      return dk;
    } finally {
      zero(k);
    }
  }

  /// Ontgrendelt met biometrie. Bij [BiometricInvalidated] moet de gebruiker de
  /// PIN invoeren; daarna kan [rewrapBiometrics] de sleutel opnieuw koppelen.
  Future<Uint8List> unlockWithBiometrics() async {
    final h = await _readHeader();
    if (h == null) throw const VaultNotSetUpException();
    final wrap = (h['bio'] as Map?)?['wrap'] as String?;
    if (wrap == null) throw const BiometricInvalidated();
    final kBio = await bio.read();
    try {
      return await _unwrap(kBio, wrap, 'bio');
    } on VaultAuthException {
      // Sleutel hoort niet meer bij de gewrapte datasleutel.
      throw const BiometricInvalidated();
    } finally {
      zero(kBio);
    }
  }

  // ------------------------------------------------------------- wijzigen

  Future<void> changePin(Uint8List dataKey, String newPin) async {
    if (!isValidPin(newPin)) throw ArgumentError('ongeldige PIN');
    final h = await _readHeader();
    if (h == null) throw const VaultNotSetUpException();
    final salt = randomBytes(16);
    final k = await deriveKeyFromSecret(newPin, salt, kdf, inIsolate: deriveInIsolate);
    h['kdf'] = kdf.toJson();
    h['pin'] = {
      'salt': base64Encode(salt),
      'wrap': base64Encode(await seal(k, dataKey, aad: _aad('pin'))),
    };
    zero(k);
    await _writeHeader(h);
    await _writeLockState(0, null);
  }

  /// Koppelt de datasleutel aan een nieuwe biometrische hardwaresleutel.
  Future<void> enableBiometricsFor(Uint8List dataKey) async {
    final kBio = randomBytes(keyLength);
    await bio.delete();
    await bio.write(kBio);
    final h = (await _readHeader())!;
    h['bio'] = {'wrap': base64Encode(await seal(kBio, dataKey, aad: _aad('bio')))};
    zero(kBio);
    await _writeHeader(h);
  }

  /// Na gewijzigde biometrie: maak een nieuwe hardwaresleutel en wrap opnieuw.
  Future<void> rewrapBiometrics(Uint8List dataKey) => enableBiometricsFor(dataKey);

  Future<void> disableBiometrics() async {
    final h = await _readHeader();
    if (h != null) {
      h.remove('bio');
      await _writeHeader(h);
    }
    try {
      await bio.delete();
    } catch (_) {}
  }

  // --------------------------------------------------------------- wissen

  Future<void> wipe() async {
    try {
      await bio.delete();
    } catch (_) {}
    await files.deleteAll();
  }

  // ----------------------------------------------------------- lockout-staat

  Future<({int failed, DateTime? until})> _readLockState() async {
    try {
      final b = await files.readBytes(files.lockState);
      if (b == null) return (failed: 0, until: null);
      final j = jsonDecode(utf8.decode(b)) as Map<String, dynamic>;
      final ms = j['until'] as int?;
      return (
        failed: (j['failed'] as int?) ?? 0,
        until: ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms),
      );
    } catch (_) {
      return (failed: 0, until: null);
    }
  }

  Future<void> _writeLockState(int failed, DateTime? until) => files.writeAtomic(
        files.lockState,
        utf8.encode(jsonEncode({'failed': failed, 'until': until?.millisecondsSinceEpoch})),
      );

  Future<DateTime?> lockedUntil() async {
    final s = await _readLockState();
    return s.until != null && s.until!.isAfter(_now()) ? s.until : null;
  }
}
