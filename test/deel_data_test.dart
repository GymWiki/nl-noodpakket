import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mijnnoodpakket/core/providers.dart';
import 'package:mijnnoodpakket/data/db/database.dart' hide PlanContact, PlanLocation, PlanMember, PlanPlace;
import 'package:mijnnoodpakket/data/repositories/plan_repository.dart';
import 'package:mijnnoodpakket/data/repositories/settings_repository.dart';
import 'package:mijnnoodpakket/features/deel/data/shared_plan_store.dart';
import 'package:mijnnoodpakket/features/deel/deel_services.dart';
import 'package:mijnnoodpakket/features/deel/domain/shared_plan_logic.dart';
import 'package:mijnnoodpakket/features/deel/protocol/receiver.dart';
import 'package:mijnnoodpakket/features/deel/protocol/sender.dart';
import 'package:mijnnoodpakket/features/deel/protocol/session_payload.dart';
import 'package:mijnnoodpakket/features/deel/protocol/transfer_models.dart';
import 'package:mijnnoodpakket/features/kluis/crypto/vault_crypto.dart';
import 'package:mijnnoodpakket/features/kluis/data/vault_controller.dart';
import 'package:mijnnoodpakket/features/kluis/data/vault_files.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_models.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_share.dart';

import 'kluis_crypto_test.dart' show FakeBio;

Uint8List jpeg(int w, int h) {
  final im = img.Image(width: w, height: h);
  img.fill(im, color: img.ColorRgb8(10, 120, 200));
  return Uint8List.fromList(img.encodeJpg(im, quality: 90));
}

Future<void> until(bool Function() cond) async {
  final end = DateTime.now().add(const Duration(seconds: 10));
  while (!cond()) {
    if (DateTime.now().isAfter(end)) fail('time-out in test');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

class Side {
  Side(this.dir, this.db, this.c, this.ctl);
  final Directory dir;
  final AppDatabase db;
  final ProviderContainer c;
  final VaultController ctl;
  VaultState get state => c.read(vaultProvider);
}

Future<Side> makeSide(String name) async {
  final dir = Directory.systemTemp.createTempSync('deel_$name');
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final c = ProviderContainer(overrides: [
    vaultEnvProvider.overrideWith((ref) async => VaultEnv(
          files: VaultFiles(Directory('${dir.path}/vault')),
          bio: FakeBio(),
          tmpDir: Directory('${dir.path}/tmp'),
          kdf: KdfParams.test,
          deriveInIsolate: false,
        )),
    settingsRepositoryProvider.overrideWithValue(SettingsRepository(db)),
  ]);
  final ctl = c.read(vaultProvider.notifier);
  await ctl.init();
  return Side(dir, db, c, ctl);
}

Future<void> dispose(Side s) async {
  s.c.dispose();
  await s.db.close();
  await Future<void>.delayed(const Duration(milliseconds: 50));
  try {
    s.dir.deleteSync(recursive: true);
  } catch (_) {}
}

void main() {
  group('planId en versie van het eigen plan', () {
    late AppDatabase db;
    late PlanRepository repo;
    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = PlanRepository(db, photoDir: () async => Directory.systemTemp);
    });
    tearDown(() => db.close());

    test('start leeg; elke wijziging verhoogt de versie; de id blijft gelijk', () async {
      var id = await repo.identity();
      expect(id.planId, '');
      expect(id.version, 0);
      await repo.setHouseholdName('Familie A');
      id = await repo.identity();
      expect(id.planId, isNotEmpty);
      expect(id.version, 1);
      final first = id.planId;
      await repo.setHouseholdName('Familie B');
      id = await repo.identity();
      expect(id.planId, first);
      expect(id.version, 2);
    });
  });

  group('planbestand met identiteit', () {
    const plan = Plan(householdName: 'Familie A', contacts: [PlanContact(role: 'emergency', name: 'Oma', phone: '0612345678')]);

    test('planId, versie en afzender gaan mee en komen terug', () {
      final json = planToJsonString(plan, const ShareOptions(), now: DateTime(2026, 11, 11), planId: 'abc-1', version: 7, sender: 'Anna');
      final p = parsePlanFile(json);
      expect(p.planId, 'abc-1');
      expect(p.version, 7);
      expect(p.sender, 'Anna');
      expect(p.plan.contacts.single.name, 'Oma');
    });

    test('een gewoon planbestand (zonder identiteit) blijft werken; schema blijft 1', () {
      final json = planToJsonString(plan, const ShareOptions(), now: DateTime(2026, 11, 11));
      final p = parsePlanFile(json);
      expect(p.planId, '');
      expect(p.version, 0);
      expect(jsonDecode(json)['schemaVersion'], 1);
    });
  });

  group('versie- en sectielogica', () {
    test('hoger = bijwerken; gelijk of lager = al up-to-date', () {
      expect(compareVersions(existing: 3, incoming: 4), VersionRelation.newer);
      expect(compareVersions(existing: 3, incoming: 3), VersionRelation.same);
      expect(compareVersions(existing: 3, incoming: 2), VersionRelation.older);
    });

    test('gewijzigde secties worden herkend, zowel uit plannen als uit hashes', () async {
      const a = Plan(contacts: [PlanContact(role: 'emergency', name: 'Oma', phone: '1')], agreements: {'checkin': 'bel'});
      const b = Plan(contacts: [PlanContact(role: 'emergency', name: 'Oma', phone: '2')], agreements: {'checkin': 'bel'});
      expect(changedSections(a, b), [ShareSection.contacts]);
      expect(changedSections(a, a), isEmpty);
      final ha = await sectionHashes(a), hb = await sectionHashes(b);
      expect(changedSectionsByHash(ha, hb), [ShareSection.contacts]);
      expect(changedSectionsByHash(ha, ha), isEmpty);
    });

    test('secties van een plan', () {
      const p = Plan(contacts: [PlanContact(role: 'emergency', name: 'x')], medication: 'pil');
      expect(sectionsOf(p), [ShareSection.contacts, ShareSection.care]);
    });
  });

  group('gedeelde plannen (opslag)', () {
    late AppDatabase db;
    late SharedPlanStore store;
    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      store = SharedPlanStore(SettingsRepository(db));
    });
    tearDown(() => db.close());

    SharedPlan sp(String id, int v, {DateTime? at}) => SharedPlan(
          planId: id,
          fromName: 'Anna',
          version: v,
          receivedAt: at ?? DateTime(2026, 11, 11, 12),
          json: planToJsonString(const Plan(householdName: 'A'), const ShareOptions(), now: DateTime(2026, 11, 11), planId: id, version: v),
          sections: const ['contacts'],
        );

    test('opslaan, teruglezen en vervangen bij dezelfde planId', () async {
      await store.save(sp('p1', 1));
      await store.save(sp('p2', 1, at: DateTime(2026, 11, 12)));
      expect((await store.list()).map((e) => e.planId), ['p2', 'p1']); // nieuwste eerst
      await store.save(sp('p1', 2, at: DateTime(2026, 11, 13)));
      final all = await store.list();
      expect(all.length, 2);
      expect((await store.get('p1'))!.version, 2);
      expect(all.first.planId, 'p1');
      expect((await store.get('p1'))!.plan.householdName, 'A');
    });

    test('verwijderen haalt index en inhoud weg', () async {
      await store.save(sp('p1', 1));
      await store.remove('p1');
      expect(await store.list(), isEmpty);
      expect(await SettingsRepository(db).getRaw('shared_plan:p1'), isNull);
    });

    test('maximum aantal plannen; oudste vallen af', () async {
      for (var i = 0; i < SharedPlanStore.maxPlans + 3; i++) {
        await store.save(sp('p$i', 1, at: DateTime(2026, 1, 1).add(Duration(days: i))));
      }
      final all = await store.list();
      expect(all.length, SharedPlanStore.maxPlans);
      expect(all.any((e) => e.planId == 'p0'), isFalse);
    });

    test('kapotte index geeft een lege lijst (geen crash)', () async {
      await SettingsRepository(db).setRaw('shared_plans', 'kapot');
      expect(await store.list(), isEmpty);
    });

    test('laatst-gedeeld-regel bevat alleen aantallen, nooit inhoud', () {
      final log = ShareLog(at: DateTime(2026, 11, 11), device: 'Pixel', what: 'plan en 2 documenten');
      final back = ShareLog.decode(log.encode())!;
      expect(back.what, 'plan en 2 documenten');
      expect(ShareLog.decode('kapot'), isNull);
    });
  });

  group('kluisdocumenten overdragen tussen twee kluizen', () {
    late Side a, b;
    setUp(() async {
      a = await makeSide('a');
      b = await makeSide('b');
    });
    tearDown(() async {
      await dispose(a);
      await dispose(b);
    });

    Future<ShareOffer> offerOf(Side s, Set<String> ids) => buildOffer(
          repo: PlanRepository(s.db, photoDir: () async => Directory.systemTemp),
          vault: s.state,
          ctl: s.ctl,
          draft: DeelDraft(docIds: ids, options: const ShareOptions()),
        );

    Future<(ShareSenderSession, ShareReceiverSession, List<ReceiverEvent>)> run(ShareOffer offer, Side rx, {Set<String>? take}) async {
      final s = await ShareSenderSession.start(offer: offer, address: InternetAddress.loopbackIPv4, idle: const Duration(seconds: 5));
      final sEvents = <SenderEvent>[];
      s.events.listen(sEvents.add);
      final rEvents = <ReceiverEvent>[];
      final r = await ShareReceiverSession.connect(
        SessionPayload.tryParse(s.qrData)!,
        deviceName: 'Ontvanger',
        onPlan: (json, m) async {},
        onDocument: (d) => storeReceivedDocument(rx.state, rx.ctl, d),
        idle: const Duration(seconds: 5),
      );
      r.events.listen(rEvents.add);
      await until(() => sEvents.any((e) => e is SenderPeer));
      s.approve();
      await until(() => rEvents.any((e) => e is ReceiverManifest));
      final m = (rEvents.firstWhere((e) => e is ReceiverManifest) as ReceiverManifest).manifest;
      r.choose(ReceiverSelection(docIds: take ?? {for (final d in m.docs) d.id}));
      await until(() => rEvents.any((e) => e is ReceiverFinished || e is ReceiverFailed));
      return (s, r, rEvents);
    }

    test('document komt aan met titel en gegevens; alleen met de sleutel van de ontvanger leesbaar; geen leesbare restanten', () async {
      await a.ctl.setUp(pin: '123456', enableBiometrics: false);
      await b.ctl.setUp(pin: '654321', enableBiometrics: false);
      final original = jpeg(160, 100);
      final doc = await a.ctl.addDocument(NewDocument(
        title: 'Paspoort Anna',
        typeId: 'passport',
        owner: 'Anna',
        expiry: DateTime(2030, 1, 1),
        pages: [NewPage(original)],
      ));
      final (_, _, events) = await run(await offerOf(a, {doc.id}), b);
      expect(events.last, isA<ReceiverFinished>());

      final got = b.state.meta.documents.single;
      expect(got.title, 'Paspoort Anna');
      expect(got.typeId, 'passport');
      expect(got.owner, 'Anna');
      expect(got.expiry, DateTime(2030, 1, 1));
      final plain = await b.ctl.readFile(got.pages.single.fileId);
      final dec = img.decodeJpg(plain)!;
      expect((dec.width, dec.height), (160, 100));

      // geen leesbare bestanden of restanten bij de ontvanger
      final marker = original.sublist(0, 32);
      for (final f in b.dir.listSync(recursive: true).whereType<File>()) {
        final bytes = f.readAsBytesSync();
        expect(_contains(bytes, marker), isFalse, reason: f.path);
        expect(_contains(bytes, Uint8List.fromList([0xFF, 0xD8, 0xFF])), isFalse, reason: 'JPEG-kop in ${f.path}');
      }
      expect(Directory('${b.dir.path}/tmp').existsSync() ? Directory('${b.dir.path}/tmp').listSync() : const [], isEmpty);
    });

    test('ook boven de gratis kluislimiet (3 documenten) komt een ontvangen document binnen', () async {
      await a.ctl.setUp(pin: '123456', enableBiometrics: false);
      await b.ctl.setUp(pin: '654321', enableBiometrics: false);
      for (var i = 0; i < 4; i++) {
        await b.ctl.addDocument(NewDocument(title: 'Eigen $i', typeId: 'other', pages: [NewPage(jpeg(40 + i, 30))]));
      }
      final doc = await a.ctl.addDocument(NewDocument(title: 'Nieuw', typeId: 'other', pages: [NewPage(jpeg(50, 50))]));
      final (_, _, events) = await run(await offerOf(a, {doc.id}), b);
      expect(events.last, isA<ReceiverFinished>());
      expect(b.state.meta.documents.length, 5);
    });

    test('meerdere pagina\'s en meerdere documenten; de ontvanger kiest er maar één', () async {
      await a.ctl.setUp(pin: '123456', enableBiometrics: false);
      await b.ctl.setUp(pin: '654321', enableBiometrics: false);
      final d1 = await a.ctl.addDocument(NewDocument(title: 'Twee pagina\'s', typeId: 'other', pages: [NewPage(jpeg(40, 40)), NewPage(jpeg(60, 60))]));
      final d2 = await a.ctl.addDocument(NewDocument(title: 'Tweede', typeId: 'other', pages: [NewPage(jpeg(30, 30))]));
      final (_, _, events) = await run(await offerOf(a, {d1.id, d2.id}), b, take: {d1.id});
      expect(events.last, isA<ReceiverFinished>());
      expect(b.state.meta.documents.length, 1);
      expect(b.state.meta.documents.single.pages.length, 2);
    });

    test('vergrendelde of niet-ingerichte kluis bij de ontvanger: er wordt niets opgeslagen', () async {
      await a.ctl.setUp(pin: '123456', enableBiometrics: false);
      final doc = await a.ctl.addDocument(NewDocument(title: 'X', typeId: 'other', pages: [NewPage(jpeg(30, 30))]));
      // b is niet ingericht
      final (_, _, events) = await run(await offerOf(a, {doc.id}), b);
      expect(events.last, isA<ReceiverFailed>());
      expect(b.state.meta.documents, isEmpty);
    });

    test('aanbod: kluis moet ontgrendeld zijn; niets te delen geeft een nette fout', () async {
      await a.ctl.setUp(pin: '123456', enableBiometrics: false);
      final doc = await a.ctl.addDocument(NewDocument(title: 'X', typeId: 'other', pages: [NewPage(jpeg(30, 30))]));
      a.ctl.lock();
      await expectLater(offerOf(a, {doc.id}), throwsA(isA<ShareOfferException>()));
      await a.ctl.unlockWithPin('123456');
      await expectLater(offerOf(a, {}), throwsA(isA<ShareOfferException>()));
    });
  });
}

bool _contains(Uint8List haystack, Uint8List needle) {
  if (needle.isEmpty || haystack.length < needle.length) return false;
  outer:
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return true;
  }
  return false;
}
