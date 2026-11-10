import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mijnnoodpakket/features/kluis/crypto/vault_crypto.dart';
import 'package:mijnnoodpakket/features/kluis/crypto/vault_keys.dart';
import 'package:mijnnoodpakket/features/kluis/data/vault_files.dart';
import 'package:mijnnoodpakket/features/kluis/domain/lock_policy.dart';

/// In-memory vervanger van de hardware-biometriesleutel.
class FakeBio implements BiometricKeyStore {
  Uint8List? stored;
  bool invalidated = false;
  bool cancel = false;
  BiometricStatus st = BiometricStatus.available;

  @override
  Future<BiometricStatus> status() async => st;
  @override
  Future<void> write(Uint8List key) async {
    stored = Uint8List.fromList(key);
    invalidated = false;
  }

  @override
  Future<Uint8List> read() async {
    if (cancel) throw const BiometricCancelled();
    if (invalidated || stored == null) throw const BiometricInvalidated();
    return Uint8List.fromList(stored!);
  }

  @override
  Future<void> delete() async => stored = null;
}

Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  group('AES-256-GCM seal/open', () {
    final key = randomBytes(32);

    test('roundtrip, ook voor leeg en groot', () async {
      for (final plain in [Uint8List(0), bytes('hallo'), randomBytes(300000)]) {
        final blob = await seal(key, plain);
        expect(blob.length, plain.length + nonceLength + tagLength);
        expect(await open(key, blob), plain);
      }
    });

    test('uitvoer bevat de platte tekst niet', () async {
      final plain = bytes('GEHEIM-PASPOORTNUMMER-123456');
      final blob = await seal(key, plain);
      expect(String.fromCharCodes(blob).contains('GEHEIM'), isFalse);
    });

    test('verkeerde sleutel faalt', () async {
      final blob = await seal(key, bytes('x'));
      await expectLater(open(randomBytes(32), blob), throwsA(isA<VaultAuthException>()));
    });

    test('gemanipuleerde data wordt afgewezen (ciphertext, nonce, tag)', () async {
      final blob = await seal(key, bytes('belangrijk document'));
      for (final i in [0, nonceLength + 1, blob.length - 1]) {
        final bad = Uint8List.fromList(blob)..[i] ^= 0x01;
        await expectLater(open(key, bad), throwsA(isA<VaultAuthException>()), reason: 'byte $i');
      }
    });

    test('afgekapte of te korte data wordt afgewezen', () async {
      final blob = await seal(key, bytes('abc'));
      await expectLater(
          open(key, blob.sublist(0, blob.length - 1)), throwsA(isA<VaultAuthException>()));
      await expectLater(open(key, Uint8List(5)), throwsA(isA<VaultAuthException>()));
      await expectLater(open(key, Uint8List(0)), throwsA(isA<VaultAuthException>()));
    });

    test('aad bindt data aan context (bestand omwisselen faalt)', () async {
      final blob = await seal(key, bytes('x'), aad: utf8.encode('bestand-a'));
      expect(await open(key, blob, aad: utf8.encode('bestand-a')), bytes('x'));
      await expectLater(open(key, blob, aad: utf8.encode('bestand-b')),
          throwsA(isA<VaultAuthException>()));
      await expectLater(open(key, blob), throwsA(isA<VaultAuthException>()));
    });

    test('nonces zijn uniek over veel versleutelingen', () async {
      final nonces = <String>{};
      for (var i = 0; i < 3000; i++) {
        final blob = await seal(key, Uint8List(1));
        nonces.add(base64Encode(blob.sublist(0, nonceLength)));
      }
      expect(nonces.length, 3000);
    });

    test('zelfde tekst geeft telkens andere ciphertext', () async {
      final a = await seal(key, bytes('zelfde'));
      final b = await seal(key, bytes('zelfde'));
      expect(a, isNot(b));
    });
  });

  group('sleutelafleiding', () {
    test('Argon2id is deterministisch per salt en verschilt per salt/wachtwoord', () async {
      final salt = randomBytes(16);
      final a = await deriveKeyFromSecret('123456', salt, KdfParams.test, inIsolate: false);
      final b = await deriveKeyFromSecret('123456', salt, KdfParams.test, inIsolate: false);
      final c = await deriveKeyFromSecret('123457', salt, KdfParams.test, inIsolate: false);
      final d = await deriveKeyFromSecret('123456', randomBytes(16), KdfParams.test, inIsolate: false);
      expect(a, b);
      expect(a, isNot(c));
      expect(a, isNot(d));
      expect(a.length, 32);
    });

    test('Argon2id met echte parameters werkt in een isolate', () async {
      final k = await deriveKeyFromSecret('123456', randomBytes(16), KdfParams.pin);
      expect(k.length, 32);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('KDF-parameters uit een bestand worden gecontroleerd', () {
      expect(() => KdfParams.fromJson({'alg': 'md5', 'm': 1, 't': 1, 'p': 1}), throwsFormatException);
      expect(() => KdfParams.fromJson({'alg': 'argon2id', 'm': 1, 't': 1, 'p': 1}), throwsFormatException);
      expect(KdfParams.fromJson(KdfParams.export.toJson()).memoryKiB, KdfParams.export.memoryKiB);
    });

    test('herstelcode: formaat en validatie', () {
      final c = generateRecoveryCode();
      expect(c.length, 32);
      expect(isValidRecoveryCode(c), isTrue);
      expect(isValidRecoveryCode(formatRecoveryCode(c).toLowerCase()), isTrue);
      expect(formatRecoveryCode(c).split(' ').length, 8);
      expect(isValidRecoveryCode('ABC'), isFalse);
      expect(isValidRecoveryCode('${c.substring(0, 31)}1'), isFalse);
      expect(generateRecoveryCode(), isNot(c));
    });
  });

  group('sleutelbeheer', () {
    late Directory dir;
    late VaultFiles files;
    late FakeBio bio;
    late VaultKeyManager keys;
    var now = DateTime(2026, 11, 10, 12);

    setUp(() {
      dir = Directory.systemTemp.createTempSync('kluis_test');
      files = VaultFiles(Directory('${dir.path}/vault'));
      bio = FakeBio();
      now = DateTime(2026, 11, 10, 12);
      keys = VaultKeyManager(files,
          bio: bio, kdf: KdfParams.test, deriveInIsolate: false, clock: () => now);
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('instellen en ontgrendelen met PIN geeft dezelfde datasleutel', () async {
      final r = await keys.setUp(pin: '123456', enableBiometrics: false);
      expect(r.dataKey.length, 32);
      expect(await keys.unlockWithPin('123456'), r.dataKey);
    });

    test('de datasleutel en PIN staan niet leesbaar op schijf', () async {
      final r = await keys.setUp(pin: '246810', enableBiometrics: true);
      final header = await files.header.readAsString();
      expect(header.contains(base64Encode(r.dataKey)), isFalse);
      expect(header.contains('246810'), isFalse);
      expect(header.contains(r.recoveryCode), isFalse);
      for (final f in dir.listSync(recursive: true).whereType<File>()) {
        final raw = f.readAsBytesSync();
        expect(String.fromCharCodes(raw).contains(base64Encode(r.dataKey)), isFalse);
      }
    });

    test('ongeldige PIN bij instellen wordt geweigerd', () async {
      for (final bad in ['12345', 'abcdef', '12345a', '1' * 17, '']) {
        expect(VaultKeyManager.isValidPin(bad), isFalse, reason: bad);
        await expectLater(keys.setUp(pin: bad, enableBiometrics: false), throwsArgumentError);
      }
      expect(VaultKeyManager.isValidPin('123456'), isTrue);
    });

    test('foute PIN geeft WrongPinException en telt mee', () async {
      await keys.setUp(pin: '123456', enableBiometrics: false);
      await expectLater(
          keys.unlockWithPin('000000'),
          throwsA(isA<WrongPinException>().having((e) => e.failedAttempts, 'failed', 1)));
    });

    test('oplopende wachttijd na 5 foute pogingen; juiste PIN werkt pas daarna', () async {
      final r = await keys.setUp(pin: '123456', enableBiometrics: false);
      for (var i = 0; i < 5; i++) {
        await expectLater(keys.unlockWithPin('000000'), throwsA(isA<WrongPinException>()));
      }
      // tijdens de wachttijd wordt zelfs de juiste PIN geweigerd
      await expectLater(keys.unlockWithPin('123456'), throwsA(isA<LockedOutException>()));
      expect(await keys.lockedUntil(), now.add(const Duration(seconds: 30)));
      now = now.add(const Duration(seconds: 31));
      expect(await keys.unlockWithPin('123456'), r.dataKey);
      expect(await keys.lockedUntil(), isNull);
    });

    test('wachttijd loopt op bij herhaalde fouten', () {
      expect(LockoutPolicy.delayFor(4), Duration.zero);
      expect(LockoutPolicy.delayFor(5), const Duration(seconds: 30));
      expect(LockoutPolicy.delayFor(6), const Duration(minutes: 1));
      expect(LockoutPolicy.delayFor(7), const Duration(minutes: 5));
      expect(LockoutPolicy.delayFor(8), const Duration(minutes: 15));
      expect(LockoutPolicy.delayFor(20), const Duration(hours: 1));
    });

    test('herstelcode ontgrendelt onafhankelijk van de PIN', () async {
      final r = await keys.setUp(pin: '123456', enableBiometrics: false);
      expect(await keys.unlockWithRecovery(r.recoveryCode), r.dataKey);
      expect(await keys.unlockWithRecovery(formatRecoveryCode(r.recoveryCode).toLowerCase()), r.dataKey);
      await expectLater(keys.unlockWithRecovery(generateRecoveryCode()),
          throwsA(isA<VaultAuthException>()));
      await expectLater(keys.unlockWithRecovery('onzin'), throwsA(isA<VaultAuthException>()));
    });

    test('PIN wijzigen: oude PIN werkt niet meer, nieuwe wel, datasleutel blijft gelijk', () async {
      final r = await keys.setUp(pin: '123456', enableBiometrics: false);
      await keys.changePin(r.dataKey, '654321');
      await expectLater(keys.unlockWithPin('123456'), throwsA(isA<WrongPinException>()));
      expect(await keys.unlockWithPin('654321'), r.dataKey);
      // herstelcode blijft geldig na een PIN-wijziging
      expect(await keys.unlockWithRecovery(r.recoveryCode), r.dataKey);
    });

    test('biometrie: ontgrendelen, geannuleerd, uitzetten', () async {
      final r = await keys.setUp(pin: '123456', enableBiometrics: true);
      expect(await keys.biometricsEnabled(), isTrue);
      expect(await keys.unlockWithBiometrics(), r.dataKey);

      bio.cancel = true;
      await expectLater(keys.unlockWithBiometrics(), throwsA(isA<BiometricCancelled>()));
      bio.cancel = false;

      await keys.disableBiometrics();
      expect(await keys.biometricsEnabled(), isFalse);
      expect(bio.stored, isNull);
      await expectLater(keys.unlockWithBiometrics(), throwsA(isA<BiometricInvalidated>()));
    });

    test('gewijzigde biometrie: sleutel ongeldig -> PIN -> opnieuw wrappen', () async {
      final r = await keys.setUp(pin: '123456', enableBiometrics: true);
      bio.invalidated = true;
      await expectLater(keys.unlockWithBiometrics(), throwsA(isA<BiometricInvalidated>()));
      final dk = await keys.unlockWithPin('123456');
      await keys.rewrapBiometrics(dk);
      expect(await keys.unlockWithBiometrics(), r.dataKey);
    });

    test('een andere hardwaresleutel kan de datasleutel niet ontgrendelen', () async {
      await keys.setUp(pin: '123456', enableBiometrics: true);
      bio.stored = randomBytes(32); // sleutel vervangen
      await expectLater(keys.unlockWithBiometrics(), throwsA(isA<BiometricInvalidated>()));
    });

    test('gemanipuleerde header wordt afgewezen', () async {
      await keys.setUp(pin: '123456', enableBiometrics: false);
      final h = jsonDecode(await files.header.readAsString()) as Map<String, dynamic>;
      final wrap = base64Decode((h['pin'] as Map)['wrap'] as String);
      wrap[20] ^= 1;
      (h['pin'] as Map)['wrap'] = base64Encode(wrap);
      await files.header.writeAsString(jsonEncode(h));
      await expectLater(keys.unlockWithPin('123456'), throwsA(isA<WrongPinException>()));
    });

    test('wissen verwijdert alles, ook de hardwaresleutel', () async {
      await keys.setUp(pin: '123456', enableBiometrics: true);
      await keys.wipe();
      expect(await keys.isSetUp(), isFalse);
      expect(bio.stored, isNull);
      expect(files.root.existsSync(), isFalse);
    });

    test('zonder instellen: niet ontgrendelbaar', () async {
      await expectLater(keys.unlockWithPin('123456'), throwsA(isA<VaultNotSetUpException>()));
    });
  });

  group('auto-vergrendelen', () {
    final t0 = DateTime(2026, 1, 1, 12);
    test('direct: elke achtergrondtijd vergrendelt', () {
      expect(
          shouldLockAfterBackground(
              mode: AutoLockMode.immediately, backgroundedAt: t0, now: t0),
          isTrue);
    });
    test('1 minuut en 5 minuten', () {
      bool lock(AutoLockMode m, int s) => shouldLockAfterBackground(
          mode: m, backgroundedAt: t0, now: t0.add(Duration(seconds: s)));
      expect(lock(AutoLockMode.oneMinute, 59), isFalse);
      expect(lock(AutoLockMode.oneMinute, 60), isTrue);
      expect(lock(AutoLockMode.fiveMinutes, 299), isFalse);
      expect(lock(AutoLockMode.fiveMinutes, 300), isTrue);
    });
    test('inactiviteit in de app', () {
      expect(shouldLockAfterIdle(lastActivity: t0, now: t0.add(const Duration(minutes: 4))), isFalse);
      expect(shouldLockAfterIdle(lastActivity: t0, now: t0.add(inAppIdleTimeout)), isTrue);
    });
    test('onbekende instelling valt terug op direct', () {
      expect(AutoLockMode.parse('rommel'), AutoLockMode.immediately);
      expect(AutoLockMode.parse(null), AutoLockMode.immediately);
      expect(AutoLockMode.parse('fiveMinutes'), AutoLockMode.fiveMinutes);
    });
  });

  group('bestanden', () {
    test('atomisch schrijven laat geen tmp achter; cleanTemp ruimt restanten op', () async {
      final dir = Directory.systemTemp.createTempSync('kluis_files');
      addTearDown(() => dir.deleteSync(recursive: true));
      final files = VaultFiles(Directory('${dir.path}/v'));
      await files.writeAtomic(files.meta, [1, 2, 3]);
      expect(files.meta.readAsBytesSync(), [1, 2, 3]);
      expect(files.root.listSync().any((e) => e.path.endsWith('.tmp')), isFalse);
      // simuleer onderbroken schrijfactie
      File('${files.meta.path}.tmp').writeAsBytesSync([9, 9]);
      await files.cleanTemp();
      expect(files.root.listSync(recursive: true).any((e) => e.path.endsWith('.tmp')), isFalse);
      expect(files.meta.readAsBytesSync(), [1, 2, 3]);
    });

    test('pad-ontsnapping via bestands-id wordt geweigerd', () {
      final files = VaultFiles(Directory.systemTemp);
      expect(() => files.fileFor('../etc/passwd'), throwsArgumentError);
      expect(() => files.fileFor('a/b'), throwsArgumentError);
      expect(files.fileFor('123e4567-e89b-12d3-a456-426614174000').path, contains('d'));
    });

    test('wipeFile overschrijft en verwijdert', () async {
      final dir = Directory.systemTemp.createTempSync('kluis_wipe');
      addTearDown(() => dir.deleteSync(recursive: true));
      final f = File('${dir.path}/x')..writeAsBytesSync(List.filled(200000, 7));
      await wipeFile(f);
      expect(f.existsSync(), isFalse);
    });
  });
}
