import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/core/providers.dart';
import 'package:mijnnoodpakket/data/db/database.dart';
import 'package:mijnnoodpakket/data/repositories/settings_repository.dart';
import 'package:mijnnoodpakket/features/kluis/crypto/vault_crypto.dart';
import 'package:mijnnoodpakket/features/kluis/data/vault_controller.dart';
import 'package:mijnnoodpakket/features/kluis/data/vault_files.dart';
import 'package:mijnnoodpakket/features/kluis/data/vault_images.dart';
import 'package:mijnnoodpakket/features/kluis/data/vault_temp.dart';
import 'package:mijnnoodpakket/features/kluis/domain/lock_policy.dart';
import 'package:mijnnoodpakket/features/kluis/domain/vault_models.dart';

import 'kluis_crypto_test.dart' show FakeBio;

Uint8List jpegBytes({int w = 120, int h = 80}) {
  final im = img.Image(width: w, height: h);
  img.fill(im, color: img.ColorRgb8(200, 30, 30));
  return Uint8List.fromList(img.encodeJpg(im, quality: 90));
}

Uint8List fakePdf() => Uint8List.fromList(utf8.encode('%PDF-1.4\nGEHEIME-PDF-INHOUD\n%%EOF'));

List<File> allFiles(Directory d) =>
    d.existsSync() ? d.listSync(recursive: true).whereType<File>().toList() : [];

void main() {
  late Directory dir;
  late AppDatabase db;
  late FakeBio bio;
  late ProviderContainer c;
  late VaultFiles files;
  late Directory tmp;

  Future<VaultController> boot() async {
    final ctl = c.read(vaultProvider.notifier);
    await ctl.init();
    return ctl;
  }

  setUp(() {
    dir = Directory.systemTemp.createTempSync('kluis_ctl');
    tmp = Directory('${dir.path}/tmp');
    files = VaultFiles(Directory('${dir.path}/vault'));
    bio = FakeBio();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    c = ProviderContainer(overrides: [
      vaultEnvProvider.overrideWith((ref) async => VaultEnv(
            files: files,
            bio: bio,
            tmpDir: tmp,
            kdf: KdfParams.test,
            deriveInIsolate: false,
          )),
      settingsRepositoryProvider.overrideWithValue(SettingsRepository(db)),
    ]);
  });
  tearDown(() async {
    c.dispose();
    await db.close();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('startstatus: niet ingericht; na instellen ontgrendeld; vergrendelen wist de meta', () async {
    final ctl = await boot();
    expect(c.read(vaultProvider).status, VaultStatus.notSetUp);
    final code = await ctl.setUp(pin: '123456', enableBiometrics: true);
    expect(isValidRecoveryCode(code), isTrue);
    expect(c.read(vaultProvider).unlocked, isTrue);
    ctl.lock();
    expect(c.read(vaultProvider).status, VaultStatus.locked);
    expect(c.read(vaultProvider).meta.documents, isEmpty);
    await expectLater(ctl.readFile('123e4567-e89b-12d3-a456-426614174000'), throwsStateError);
  });

  test('ontgrendelen met PIN, biometrie en herstelcode (nieuwe PIN)', () async {
    final ctl = await boot();
    final code = await ctl.setUp(pin: '123456', enableBiometrics: true);
    ctl.lock();
    expect(await ctl.unlockWithPin('000000'), UnlockResult.wrongPin);
    expect(await ctl.unlockWithPin('123456'), UnlockResult.ok);
    ctl.lock();
    expect(await ctl.unlockWithBiometrics(), UnlockResult.ok);
    ctl.lock();
    bio.cancel = true;
    expect(await ctl.unlockWithBiometrics(), UnlockResult.cancelled);
    bio.cancel = false;
    // PIN vergeten
    ctl.lock();
    expect(await ctl.recoverWithCode(code, '654321'), UnlockResult.ok);
    ctl.lock();
    expect(await ctl.unlockWithPin('123456'), UnlockResult.wrongPin);
    expect(await ctl.unlockWithPin('654321'), UnlockResult.ok);
  });

  test('gewijzigde biometrie: PIN gevraagd en daarna opnieuw gekoppeld', () async {
    final ctl = await boot();
    await ctl.setUp(pin: '123456', enableBiometrics: true);
    ctl.lock();
    bio.invalidated = true;
    expect(await ctl.unlockWithBiometrics(), UnlockResult.needsPin);
    expect(c.read(vaultProvider).bioNeedsPin, isTrue);
    expect(await ctl.unlockWithPin('123456'), UnlockResult.ok);
    expect(c.read(vaultProvider).bioNeedsPin, isFalse);
    ctl.lock();
    expect(await ctl.unlockWithBiometrics(), UnlockResult.ok);
  });

  test('na 5 foute pogingen volgt een wachttijd', () async {
    final ctl = await boot();
    await ctl.setUp(pin: '123456', enableBiometrics: false);
    ctl.lock();
    for (var i = 0; i < 5; i++) {
      expect(await ctl.unlockWithPin('000000'), UnlockResult.wrongPin);
    }
    expect(await ctl.unlockWithPin('123456'), UnlockResult.lockedOut);
    expect(c.read(vaultProvider).lockedUntil, isNotNull);
  });

  group('documenten', () {
    late VaultController ctl;
    setUp(() async {
      ctl = await boot();
      await ctl.setUp(pin: '123456', enableBiometrics: false);
    });

    test('toevoegen: alles op schijf is versleuteld (geen JPEG/PDF-herkenning, geen titel)', () async {
      final doc = await ctl.addDocument(NewDocument(
        title: 'Mijn Paspoort Geheimtitel',
        typeId: 'passport',
        owner: 'Anna Geheimnaam',
        pages: [NewPage(jpegBytes()), NewPage(fakePdf())],
      ));
      expect(doc.pages.length, 2);
      final raw = allFiles(files.root);
      expect(raw, isNotEmpty);
      for (final f in raw) {
        final b = f.readAsBytesSync();
        final text = String.fromCharCodes(b);
        expect(text.contains('Geheimtitel'), isFalse, reason: f.path);
        expect(text.contains('Geheimnaam'), isFalse, reason: f.path);
        expect(text.contains('GEHEIME-PDF-INHOUD'), isFalse, reason: f.path);
        if (f.path.contains('${Platform.pathSeparator}d${Platform.pathSeparator}')) {
          expect(sniffMime(b), isNull, reason: 'leesbaar bestandstype op schijf: ${f.path}');
        }
      }
      // bestandsnamen: uuid zonder extensie
      for (final f in allFiles(files.data)) {
        final name = f.uri.pathSegments.last;
        expect(name.contains('.'), isFalse);
        expect(RegExp(r'^[0-9a-f\-]{36}$').hasMatch(name), isTrue);
      }
    });

    test('terugkeren na vergrendelen: documenten en bestanden zijn leesbaar', () async {
      final jpg = jpegBytes();
      final doc = await ctl.addDocument(NewDocument(
        title: 'Rijbewijs',
        typeId: 'driving',
        pages: [NewPage(jpg)],
      ));
      ctl.lock();
      expect(await ctl.unlockWithPin('123456'), UnlockResult.ok);
      final loaded = c.read(vaultProvider).meta.documents.single;
      expect(loaded.title, 'Rijbewijs');
      final page = await ctl.readFile(loaded.pages.first.fileId);
      expect(sniffMime(page), 'image/jpeg');
      final thumb = await ctl.readFile(loaded.pages.first.thumbId!);
      expect(sniffMime(thumb), 'image/jpeg');
      expect(doc.id, loaded.id);
    });

    test('afbeeldingen worden gecomprimeerd maar blijven leesbaar', () async {
      final big = jpegBytes(w: 4000, h: 3000);
      final doc = await ctl.addDocument(
          NewDocument(title: 'Groot', typeId: 'other', pages: [NewPage(big)]));
      final stored = await ctl.readFile(doc.pages.first.fileId);
      final decoded = img.decodeJpg(stored)!;
      expect(decoded.width, maxSide);
      expect(decoded.height, 1800);
      final thumb = img.decodeJpg(await ctl.readFile(doc.pages.first.thumbId!))!;
      expect(thumb.width, thumbSide);
    });

    test('onbekend of te groot bestand wordt geweigerd en laat niets achter', () async {
      await expectLater(
          ctl.addDocument(NewDocument(
              title: 'x', typeId: 'other', pages: [NewPage(jpegBytes()), NewPage(Uint8List.fromList([1, 2, 3, 4, 5]))])),
          throwsA(isA<VaultUnsupportedException>()));
      expect(allFiles(files.data), isEmpty, reason: 'eerste pagina moet teruggedraaid zijn');
      expect(c.read(vaultProvider).meta.documents, isEmpty);
    });

    test('verwijderen wist metadata en alle bestanden', () async {
      final doc = await ctl.addDocument(NewDocument(
          title: 'Weg', typeId: 'other', pages: [NewPage(jpegBytes()), NewPage(fakePdf())]));
      expect(allFiles(files.data), isNotEmpty);
      await ctl.deleteDocument(doc.id);
      expect(allFiles(files.data), isEmpty);
      expect(c.read(vaultProvider).meta.documents, isEmpty);
    });

    test('pagina toevoegen en verwijderen', () async {
      final doc = await ctl.addDocument(
          NewDocument(title: 'Doc', typeId: 'other', pages: [NewPage(jpegBytes())]));
      final firstId = doc.pages.first.fileId;
      await ctl.updateDocument(doc, addPages: [NewPage(jpegBytes(w: 50, h: 50))]);
      var cur = c.read(vaultProvider).meta.documents.single;
      expect(cur.pages.length, 2);
      await ctl.updateDocument(cur, removePageFileIds: {firstId});
      cur = c.read(vaultProvider).meta.documents.single;
      expect(cur.pages.length, 1);
      expect(files.fileFor(firstId).existsSync(), isFalse);
    });

    test('verweesde bestanden (onderbroken toevoegen) worden bij ontgrendelen opgeruimd', () async {
      await ctl.addDocument(
          NewDocument(title: 'Doc', typeId: 'other', pages: [NewPage(jpegBytes())]));
      final session = ctl.requireSession();
      final orphan = await session.putFile(Uint8List.fromList(utf8.encode('x')));
      expect(files.fileFor(orphan).existsSync(), isTrue);
      ctl.lock();
      await ctl.unlockWithPin('123456');
      expect(files.fileFor(orphan).existsSync(), isFalse);
      expect(c.read(vaultProvider).meta.documents.length, 1);
    });

    test('metadata gemanipuleerd: lezen faalt (geen stil verlies van authenticiteit)', () async {
      await ctl.addDocument(
          NewDocument(title: 'Doc', typeId: 'other', pages: [NewPage(jpegBytes())]));
      ctl.lock();
      final b = files.meta.readAsBytesSync();
      b[b.length ~/ 2] ^= 1;
      files.meta.writeAsBytesSync(b);
      expect(await ctl.unlockWithPin('123456'), UnlockResult.error);
      expect(c.read(vaultProvider).unlocked, isFalse);
    });

    test('bestanden kunnen niet worden omgewisseld (aad bindt aan bestands-id)', () async {
      final a = await ctl.addDocument(
          NewDocument(title: 'A', typeId: 'other', pages: [NewPage(jpegBytes(w: 30, h: 30))]));
      final b = await ctl.addDocument(
          NewDocument(title: 'B', typeId: 'other', pages: [NewPage(jpegBytes(w: 60, h: 60))]));
      final fa = files.fileFor(a.pages.first.fileId);
      final fb = files.fileFor(b.pages.first.fileId);
      fa.writeAsBytesSync(fb.readAsBytesSync());
      await expectLater(ctl.readFile(a.pages.first.fileId), throwsA(isA<VaultAuthException>()));
    });

    test('bekijken zet geen bestanden op schijf', () async {
      final doc = await ctl.addDocument(
          NewDocument(title: 'Doc', typeId: 'other', pages: [NewPage(jpegBytes()), NewPage(fakePdf())]));
      final before = allFiles(dir).map((f) => f.path).toSet();
      for (final p in doc.pages) {
        final b = await ctl.readFile(p.fileId);
        expect(b, isNotEmpty);
        zero(b);
      }
      expect(allFiles(dir).map((f) => f.path).toSet(), before);
    });

    test('eigen types toevoegen', () async {
      final t = await ctl.addCustomType('Huurcontract', identity: false);
      expect(c.read(vaultProvider).meta.typeOf(t.id)!.label, 'Huurcontract');
      ctl.lock();
      await ctl.unlockWithPin('123456');
      expect(c.read(vaultProvider).meta.customTypes.single.label, 'Huurcontract');
    });

    test('Noodmap-markering wisselt', () async {
      final doc = await ctl.addDocument(
          NewDocument(title: 'Doc', typeId: 'other', pages: [NewPage(jpegBytes())]));
      await ctl.toggleEmergency(doc.id);
      expect(c.read(vaultProvider).meta.documents.single.emergency, isTrue);
      await ctl.toggleEmergency(doc.id);
      expect(c.read(vaultProvider).meta.documents.single.emergency, isFalse);
    });

    test('afgeleide gegevens buiten de kluis bevatten geen titels of namen', () async {
      final settings = SettingsRepository(db);
      await ctl.addDocument(NewDocument(
        title: 'Paspoort Anna Geheim',
        typeId: 'passport',
        owner: 'Anna Geheim',
        note: 'nummer NP1234567',
        expiry: DateTime.now().add(const Duration(days: 200)),
        pages: [NewPage(jpegBytes())],
      ));
      expect(await settings.getRaw('kluis_has_docs'), 'true');
      final times = await settings.getRaw('kluis_reminders');
      expect(times, isNotNull);
      for (final forbidden in ['Paspoort', 'Anna', 'Geheim', 'NP1234567']) {
        expect(times!.contains(forbidden), isFalse);
      }
      expect((jsonDecode(times!) as List).length, 2); // 90 en 30 dagen vooraf
      // alle settingrijen samen: nergens titel/naam/nummer
      final rows = await db.select(db.settingRows).get();
      final all = rows.map((r) => '${r.key}=${r.value}').join('\n');
      for (final forbidden in ['Anna', 'Geheim', 'NP1234567']) {
        expect(all.contains(forbidden), isFalse);
      }
    });

    test('herinneringsdagen aanpassen werkt de tijden bij', () async {
      final settings = SettingsRepository(db);
      await ctl.addDocument(NewDocument(
        title: 'X',
        typeId: 'other',
        expiry: DateTime.now().add(const Duration(days: 400)),
        pages: [NewPage(jpegBytes())],
      ));
      await ctl.setReminderDays([180, 90, 30]);
      expect((jsonDecode((await settings.getRaw('kluis_reminders'))!) as List).length, 3);
    });

    test('PIN wijzigen vereist de huidige PIN', () async {
      expect(await ctl.changePin('000000', '111222'), isFalse);
      expect(await ctl.changePin('123456', '111222'), isTrue);
      ctl.lock();
      expect(await ctl.unlockWithPin('111222'), UnlockResult.ok);
    });

    test('kluis wissen: alles weg en opnieuw in te richten', () async {
      await ctl.addDocument(
          NewDocument(title: 'Doc', typeId: 'other', pages: [NewPage(jpegBytes())]));
      await ctl.wipe();
      expect(c.read(vaultProvider).status, VaultStatus.notSetUp);
      expect(allFiles(files.root), isEmpty);
      expect(bio.stored, isNull);
      final settings = SettingsRepository(db);
      expect(await settings.getRaw('kluis_has_docs'), isNull);
      expect(await settings.getRaw('kluis_reminders'), isNull);
    });
  });

  group('tijdelijke bestanden', () {
    test('withTempPlaintext ruimt altijd op, ook bij een fout', () async {
      final t = Directory('${dir.path}/t');
      File? seen;
      await withTempPlaintext(t, Uint8List.fromList([1, 2, 3]), 'jpg', (f) async {
        seen = f;
        expect(f.existsSync(), isTrue);
      });
      expect(seen!.existsSync(), isFalse);
      await expectLater(
        withTempPlaintext(t, Uint8List.fromList([1]), 'jpg', (f) async {
          seen = f;
          throw StateError('delen mislukt');
        }),
        throwsStateError,
      );
      expect(seen!.existsSync(), isFalse);
      expect(allFiles(t), isEmpty);
    });

    test('restanten worden bij start opgeruimd', () async {
      tmp.createSync(recursive: true);
      File('${tmp.path}/restant.jpg').writeAsBytesSync([9, 9, 9]);
      File('${files.root.path}/x.tmp').createSync(recursive: true);
      await boot();
      expect(allFiles(tmp), isEmpty);
      expect(allFiles(files.root).any((f) => f.path.endsWith('.tmp')), isFalse);
    });
  });

  group('verloopdatums', () {
    final now = DateTime(2026, 11, 10, 12);
    VaultDocument doc(DateTime? e) => VaultDocument(
          id: 'a', title: 't', typeId: 'passport', expiry: e,
          createdAt: now, updatedAt: now);

    test('status', () {
      expect(docExpiryStatus(doc(null), now), DocExpiry.none);
      expect(docExpiryStatus(doc(DateTime(2026, 11, 9)), now), DocExpiry.expired);
      expect(docExpiryStatus(doc(DateTime(2026, 11, 10)), now), DocExpiry.soon);
      expect(docExpiryStatus(doc(DateTime(2027, 2, 8)), now), DocExpiry.soon); // 90 dagen
      expect(docExpiryStatus(doc(DateTime(2027, 2, 9)), now), DocExpiry.ok);
    });

    test('herinneringstijden: alleen toekomst, 10:00, 90 en 30 dagen vooraf', () {
      final t = expiryReminderTimes([doc(DateTime(2027, 6, 30))], [90, 30], now);
      expect(t, [DateTime(2027, 4, 1, 10), DateTime(2027, 5, 31, 10)]);
      // verlopen of te dichtbij: alleen wat nog in de toekomst ligt
      expect(expiryReminderTimes([doc(DateTime(2026, 12, 1))], [90, 30], now),
          [DateTime(2026, 11, 1, 10)].where((d) => d.isAfter(now)).toList());
      expect(expiryReminderTimes([doc(DateTime(2026, 1, 1)), doc(null)], [90, 30], now), isEmpty);
    });

    test('notificatieteksten zijn neutraal', () {
      for (final s in [S.notifTitleVault, S.notifBodyVault]) {
        expect(RegExp(r'\d').hasMatch(s), isFalse);
        for (final t in builtinTypes) {
          expect(s.toLowerCase().contains(t.label.toLowerCase()), isFalse, reason: t.label);
        }
      }
      expect(S.notifBodyVault, 'Een document in je kluis verloopt binnenkort.');
    });

    test('automatisch vergrendelen gebruikt de gekozen instelling', () async {
      final ctl = await boot();
      await ctl.setAutoLock(AutoLockMode.fiveMinutes);
      expect(c.read(vaultProvider).autoLock, AutoLockMode.fiveMinutes);
      await ctl.setUp(pin: '123456', enableBiometrics: false);
      ctl.onBackground();
      ctl.onResume(); // < 5 minuten: blijft ontgrendeld
      expect(c.read(vaultProvider).unlocked, isTrue);
      await ctl.setAutoLock(AutoLockMode.immediately);
      ctl.onBackground();
      ctl.onResume();
      expect(c.read(vaultProvider).unlocked, isFalse);
    });
  });
}
