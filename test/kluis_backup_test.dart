import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mijnnoodpakket/core/providers.dart';
import 'package:mijnnoodpakket/data/db/database.dart';
import 'package:mijnnoodpakket/data/repositories/settings_repository.dart';
import 'package:mijnnoodpakket/features/kluis/crypto/vault_crypto.dart';
import 'package:mijnnoodpakket/features/kluis/data/vault_backup.dart';
import 'package:mijnnoodpakket/features/kluis/data/vault_controller.dart';
import 'package:mijnnoodpakket/features/kluis/data/vault_files.dart';

import 'kluis_crypto_test.dart' show FakeBio;

Uint8List jpeg(int shade) {
  final im = img.Image(width: 80, height: 60);
  img.fill(im, color: img.ColorRgb8(shade, 40, 40));
  return Uint8List.fromList(img.encodeJpg(im, quality: 90));
}

class Device {
  Device(String name) {
    dir = Directory.systemTemp.createTempSync('kluis_$name');
    files = VaultFiles(Directory('${dir.path}/vault'));
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      vaultEnvProvider.overrideWith((ref) async => VaultEnv(
            files: files,
            bio: FakeBio(),
            tmpDir: Directory('${dir.path}/tmp'),
            kdf: KdfParams.test,
            exportKdf: KdfParams.test,
            deriveInIsolate: false,
          )),
      settingsRepositoryProvider.overrideWithValue(SettingsRepository(db)),
    ]);
  }
  late Directory dir;
  late VaultFiles files;
  late AppDatabase db;
  late ProviderContainer container;
  VaultController get ctl => container.read(vaultProvider.notifier);

  Future<void> setUp() async {
    await ctl.init();
    await ctl.setUp(pin: '123456', enableBiometrics: false);
  }

  Future<void> close() async {
    container.dispose();
    await db.close();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  }
}

void main() {
  late Device a, b;
  setUp(() async {
    a = Device('a');
    b = Device('b');
    await a.setUp();
    await b.setUp();
  });
  tearDown(() async {
    await a.close();
    await b.close();
  });

  Future<File> makeBackup(String pw) async {
    await a.ctl.addDocument(NewDocument(
      title: 'Paspoort Anna',
      typeId: 'passport',
      owner: 'Anna',
      pages: [NewPage(jpeg(200)), NewPage(jpeg(100))],
    ));
    await a.ctl.addDocument(NewDocument(title: 'Polis', typeId: 'policy_home', pages: [NewPage(jpeg(50))]));
    await a.ctl.addCustomType('Huurcontract', identity: false);
    return a.ctl.exportBackup(pw);
  }

  test('export bevat geen leesbare gegevens', () async {
    final f = await makeBackup('wachtwoord-123');
    final bytes = f.readAsBytesSync();
    final text = String.fromCharCodes(bytes);
    expect(text.startsWith('NKLUIS01'), isTrue);
    for (final forbidden in ['Paspoort', 'Anna', 'Polis', 'Huurcontract', 'passport']) {
      expect(text.contains(forbidden), isFalse, reason: forbidden);
    }
    // geen JPEG-handtekening van een leesbare afbeelding
    expect(text.contains('JFIF'), isFalse);
  });

  test('roundtrip: exporteren en importeren op een nieuw toestel (vervangen)', () async {
    final f = await makeBackup('wachtwoord-123');
    final reader = await b.ctl.openBackup(f, 'wachtwoord-123');
    expect(reader.documentCount, 2);
    await b.ctl.applyBackup(reader, replace: true);
    final docs = b.container.read(vaultProvider).meta.documents;
    expect(docs.map((d) => d.title), containsAll(['Paspoort Anna', 'Polis']));
    expect(b.container.read(vaultProvider).meta.customTypes.single.label, 'Huurcontract');
    // bestanden zijn leesbaar met de sleutel van het nieuwe toestel
    for (final d in docs) {
      for (final p in d.pages) {
        final bytes = await b.ctl.readFile(p.fileId);
        expect(bytes.isNotEmpty, isTrue);
        expect(img.decodeJpg(bytes), isNotNull);
      }
    }
    // en blijven na vergrendelen/ontgrendelen op het nieuwe toestel
    b.ctl.lock();
    await b.ctl.unlockWithPin('123456');
    expect(b.container.read(vaultProvider).meta.documents.length, 2);
  });

  test('samenvoegen: bestaande documenten blijven, geen dubbelen bij nogmaals importeren', () async {
    final f = await makeBackup('wachtwoord-123');
    await b.ctl.addDocument(NewDocument(title: 'Eigen doc', typeId: 'other', pages: [NewPage(jpeg(10))]));
    var reader = await b.ctl.openBackup(f, 'wachtwoord-123');
    await b.ctl.applyBackup(reader, replace: false);
    expect(b.container.read(vaultProvider).meta.documents.length, 3);
    reader = await b.ctl.openBackup(f, 'wachtwoord-123');
    await b.ctl.applyBackup(reader, replace: false);
    expect(b.container.read(vaultProvider).meta.documents.length, 3);
  });

  test('vervangen wist de oude documenten en hun bestanden', () async {
    final f = await makeBackup('wachtwoord-123');
    final own = await b.ctl.addDocument(
        NewDocument(title: 'Eigen doc', typeId: 'other', pages: [NewPage(jpeg(10))]));
    final oldFile = b.files.fileFor(own.pages.first.fileId);
    expect(oldFile.existsSync(), isTrue);
    final reader = await b.ctl.openBackup(f, 'wachtwoord-123');
    await b.ctl.applyBackup(reader, replace: true);
    expect(oldFile.existsSync(), isFalse);
    expect(b.container.read(vaultProvider).meta.documents.map((d) => d.title), isNot(contains('Eigen doc')));
  });

  test('verkeerd wachtwoord wordt geweigerd en laat niets achter', () async {
    final f = await makeBackup('wachtwoord-123');
    await expectLater(
      b.ctl.openBackup(f, 'verkeerd-wachtwoord'),
      throwsA(isA<BackupException>().having((e) => e.error, 'error', BackupError.wrongPasswordOrCorrupt)),
    );
    expect(b.container.read(vaultProvider).meta.documents, isEmpty);
  });

  test('beschadigd bestand (bit omgedraaid in een record) wordt afgewezen en rolt terug', () async {
    final f = await makeBackup('wachtwoord-123');
    final bytes = f.readAsBytesSync();
    bytes[bytes.length - 100] ^= 1; // ergens in de laatste records
    final bad = File('${a.dir.path}/bad.noodkluis')..writeAsBytesSync(bytes);
    final reader = await b.ctl.openBackup(bad, 'wachtwoord-123');
    await expectLater(
      b.ctl.applyBackup(reader, replace: true),
      throwsA(isA<BackupException>()),
    );
    expect(b.container.read(vaultProvider).meta.documents, isEmpty);
    final leftovers = b.files.data.listSync().whereType<File>().toList();
    expect(leftovers, isEmpty, reason: 'half geïmporteerde bestanden moeten weg zijn');
  });

  test('afgekapt bestand wordt afgewezen', () async {
    final f = await makeBackup('wachtwoord-123');
    final bytes = f.readAsBytesSync();
    final cut = File('${a.dir.path}/cut.noodkluis')..writeAsBytesSync(bytes.sublist(0, bytes.length - 60));
    final reader = await b.ctl.openBackup(cut, 'wachtwoord-123');
    await expectLater(b.ctl.applyBackup(reader, replace: true), throwsA(isA<BackupException>()));
    expect(b.container.read(vaultProvider).meta.documents, isEmpty);
  });

  test('weggelaten record (bestand ontbreekt) wordt gedetecteerd', () async {
    final f = await makeBackup('wachtwoord-123');
    final bytes = f.readAsBytesSync();
    // sla het tweede record over door zijn lengte-prefix en inhoud te verwijderen
    final bd = ByteData.sublistView(bytes);
    final hLen = bd.getUint32(8);
    var pos = 12 + hLen;
    final firstLen = bd.getUint32(pos);
    final secondStart = pos + 4 + firstLen;
    final secondLen = bd.getUint32(secondStart);
    final without = [
      ...bytes.sublist(0, secondStart),
      ...bytes.sublist(secondStart + 4 + secondLen),
    ];
    final bad = File('${a.dir.path}/gap.noodkluis')..writeAsBytesSync(without);
    final reader = await b.ctl.openBackup(bad, 'wachtwoord-123');
    await expectLater(b.ctl.applyBackup(reader, replace: true), throwsA(isA<BackupException>()));
    expect(b.container.read(vaultProvider).meta.documents, isEmpty);
  });

  test('geen back-up of te nieuwe versie wordt netjes geweigerd', () async {
    Future<BackupError?> errOf(List<int> bytes) async {
      final f = File('${a.dir.path}/x.noodkluis')..writeAsBytesSync(bytes);
      try {
        await BackupReader.read(f, 'x', deriveInIsolate: false);
        return null;
      } on BackupException catch (e) {
        return e.error;
      }
    }

    expect(await errOf(utf8.encode('geen back-up')), BackupError.invalid);
    expect(await errOf(Uint8List(0)), BackupError.invalid);
    // te nieuwe versie
    final header = utf8.encode(jsonEncode({'v': 99}));
    final bd = ByteData(4)..setUint32(0, header.length);
    expect(await errOf([...utf8.encode('NKLUIS01'), ...bd.buffer.asUint8List(), ...header]),
        BackupError.tooNew);
    // kapotte header
    final bad = utf8.encode('{niet json');
    final bd2 = ByteData(4)..setUint32(0, bad.length);
    expect(await errOf([...utf8.encode('NKLUIS01'), ...bd2.buffer.asUint8List(), ...bad]),
        BackupError.invalid);
  });

  test('export laat geen half bestand achter bij een fout', () async {
    final session = a.ctl.requireSession();
    final out = File('${a.dir.path}/fail.noodkluis');
    // metadata verwijst naar een bestand dat niet bestaat -> export mislukt
    final doc = await a.ctl.addDocument(
        NewDocument(title: 'x', typeId: 'other', pages: [NewPage(jpeg(10))]));
    session.files.fileFor(doc.pages.first.fileId).deleteSync();
    await expectLater(
      writeBackup(
        session: session,
        meta: a.container.read(vaultProvider).meta,
        password: 'wachtwoord-123',
        out: out,
        kdf: KdfParams.test,
        deriveInIsolate: false,
      ),
      throwsA(anything),
    );
    expect(out.existsSync(), isFalse);
    expect(File('${out.path}.part').existsSync(), isFalse);
  });
}
