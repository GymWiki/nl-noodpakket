import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mijnnoodpakket/data/db/database.dart'
    hide PlanContact, PlanLocation, PlanMember, PlanPlace;
import 'package:mijnnoodpakket/data/repositories/item_repository.dart';
import 'package:mijnnoodpakket/data/repositories/plan_repository.dart';
import 'package:mijnnoodpakket/domain/models.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_models.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_progress.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_share.dart';

Plan filledPlan() => Plan(
      householdName: 'Familie De Vries',
      members: const [
        PlanMember(name: 'Anna', ageGroup: 'adult'),
        PlanMember(name: 'Sam', ageGroup: 'child', needsHelp: true),
        PlanMember(name: 'Bello', isPet: true),
      ],
      contacts: const [
        PlanContact(role: PlanKeys.roleOutside, name: 'Oma', phone: '0612345678'),
        PlanContact(role: PlanKeys.roleEmergency, name: 'Piet', phone: '0687654321'),
      ],
      places: const {
        PlanKeys.placeHome: PlanPlace(kind: PlanKeys.placeHome, address: 'Bij de lantaarnpaal'),
        PlanKeys.placeNeighbourhood:
            PlanPlace(kind: PlanKeys.placeNeighbourhood, address: 'Speeltuin', notes: 'bij de glijbaan'),
      },
      agreements: const {
        PlanKeys.checkin: 'Elk heel uur een sms',
        PlanKeys.noteLeft: 'Op de keukentafel',
        PlanKeys.kids: 'Anna haalt ze op',
      },
      locations: const {
        PlanKeys.noodpakket: PlanLocation(key: PlanKeys.noodpakket, body: 'Gangkast'),
        PlanKeys.meterkast: PlanLocation(key: PlanKeys.meterkast, body: 'Naast de voordeur'),
      },
      medication: 'Anna: bloeddrukmedicatie',
      devices: 'Zuurstofapparaat',
      sharedVersion: 2,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 2, 1),
    );

void main() {
  group('voortgang', () {
    test('leeg plan: alles leeg, niet gestart', () {
      final p = planProgress(const Plan());
      expect(p.completed, 0);
      expect(p.started, isFalse);
      expect(p.statuses.values.every((s) => s == SectionStatus.empty), isTrue);
    });

    test('huishouden: deels (naamloos lid) en klaar', () {
      expect(sectionStatus(const Plan(members: [PlanMember(name: '')]), PlanSection.household),
          SectionStatus.partial);
      expect(sectionStatus(const Plan(members: [PlanMember(name: 'A')]), PlanSection.household),
          SectionStatus.done);
    });

    test('contacten: klaar bij contact buiten regio + noodcontact', () {
      expect(
          sectionStatus(
              const Plan(contacts: [PlanContact(role: PlanKeys.roleDoctor, name: 'Dr')]),
              PlanSection.contacts),
          SectionStatus.partial);
      expect(sectionStatus(filledPlan(), PlanSection.contacts), SectionStatus.done);
    });

    test('verzamelplekken: 2 van 3 is gedeeltelijk', () {
      expect(sectionStatus(filledPlan(), PlanSection.places), SectionStatus.partial);
    });

    test('afspraken: alleen relevante afspraken zijn vereist', () {
      // gezin met kind en huisdier en hulpbehoevende: kids + pets + vulnerable vereist
      expect(requiredAgreementKeys(filledPlan()),
          containsAll([PlanKeys.checkin, PlanKeys.noteLeft, PlanKeys.kids, PlanKeys.pets, PlanKeys.vulnerable]));
      expect(sectionStatus(filledPlan(), PlanSection.agreements), SectionStatus.partial);
      // alleenstaande volwassene: checkin + briefje is genoeg
      const solo = Plan(
        members: [PlanMember(name: 'A')],
        agreements: {PlanKeys.checkin: 'x', PlanKeys.noteLeft: 'y'},
      );
      expect(requiredAgreementKeys(solo), [PlanKeys.checkin, PlanKeys.noteLeft]);
      expect(sectionStatus(solo, PlanSection.agreements), SectionStatus.done);
    });

    test('thuis: klaar pas als de kernlocaties zijn ingevuld', () {
      expect(sectionStatus(filledPlan(), PlanSection.home), SectionStatus.partial);
      final all = Plan(locations: {
        for (final k in PlanKeys.homeCoreKeys) k: PlanLocation(key: k, body: 'ergens'),
      });
      expect(sectionStatus(all, PlanSection.home), SectionStatus.done);
    });

    test('zorg is optioneel en overslaan telt als afgehandeld', () {
      expect(sectionStatus(const Plan(), PlanSection.care), SectionStatus.empty);
      expect(sectionStatus(filledPlan(), PlanSection.care), SectionStatus.done);
      final skipped = const Plan(skipped: {PlanSection.care});
      expect(sectionStatus(skipped, PlanSection.care), SectionStatus.skipped);
      expect(planProgress(skipped).completed, 1);
    });

    test('buren: 2 van 3 is klaar', () {
      const p = Plan(agreements: {PlanKeys.helpMe: 'a', PlanKeys.iHelp: 'b'});
      expect(sectionStatus(p, PlanSection.neighbours), SectionStatus.done);
      expect(sectionStatus(const Plan(agreements: {PlanKeys.helpMe: 'a'}), PlanSection.neighbours),
          SectionStatus.partial);
    });
  });

  group('delen: bestand en tekst', () {
    final now = DateTime(2026, 11, 10, 12);

    test('roundtrip: exporteren en weer inlezen', () {
      final json = planToJsonString(filledPlan(), const ShareOptions(care: true), now: now);
      final parsed = parsePlanFile(json).plan;
      expect(parsed.householdName, 'Familie De Vries');
      expect(parsed.members.map((m) => m.name), ['Anna', 'Sam', 'Bello']);
      expect(parsed.members.last.isPet, isTrue);
      expect(parsed.members[1].needsHelp, isTrue);
      expect(parsed.contacts.map((c) => c.phone), ['0612345678', '0687654321']);
      expect(parsed.place(PlanKeys.placeNeighbourhood)!.notes, 'bij de glijbaan');
      expect(parsed.agreement(PlanKeys.checkin), 'Elk heel uur een sms');
      expect(parsed.locationText(PlanKeys.meterkast), 'Naast de voordeur');
      expect(parsed.medication, 'Anna: bloeddrukmedicatie');
    });

    test('zorg staat standaard uit en komt dan niet in bestand of tekst', () {
      const o = ShareOptions();
      expect(o.care, isFalse);
      expect(o.photos, isFalse);
      final json = planToJsonString(filledPlan(), o, now: now);
      expect(json, isNot(contains('bloeddruk')));
      expect(parsePlanFile(json).plan.hasCare, isFalse);
      expect(planSummaryText(filledPlan(), o, now), isNot(contains('bloeddruk')));
      expect(planSummaryText(filledPlan(), o.copyWith(care: true), now), contains('bloeddruk'));
    });

    test('uitgeschakelde onderdelen komen niet mee', () {
      final json = planToJsonString(
          filledPlan(), const ShareOptions(contacts: false, places: false), now: now);
      final p = parsePlanFile(json).plan;
      expect(p.contacts, isEmpty);
      expect(p.places, isEmpty);
      expect(p.agreements, isNotEmpty);
    });

    test('tekstsamenvatting bevat 112, contacten en voettekst', () {
      final t = planSummaryText(filledPlan(), const ShareOptions(), now);
      expect(t, contains('Noodplan Familie De Vries'));
      expect(t, contains('bel 112'));
      expect(t, contains('0612345678'));
      expect(t, contains('niet van de overheid'));
    });

    test('ongeldige bestanden worden geweigerd', () {
      PlanFileError? err(String s) {
        try {
          parsePlanFile(s);
          return null;
        } on PlanFileException catch (e) {
          return e.error;
        }
      }

      expect(err('geen json'), PlanFileError.invalid);
      expect(err('[]'), PlanFileError.invalid);
      expect(err('{"app":"iets-anders","schemaVersion":1}'), PlanFileError.invalid);
      expect(err('{"app":"$planFileApp"}'), PlanFileError.invalid);
      expect(err('{"app":"$planFileApp","schemaVersion":0}'), PlanFileError.invalid);
      expect(err('{"app":"$planFileApp","schemaVersion":1,"members":"kapot"}'),
          PlanFileError.invalid);
    });

    test('nieuwer bestand (hogere schemaVersion) wordt netjes geweigerd', () {
      expect(
        () => parsePlanFile('{"app":"$planFileApp","schemaVersion":${planFileSchemaVersion + 1}}'),
        throwsA(isA<PlanFileException>().having((e) => e.error, 'error', PlanFileError.tooNew)),
      );
    });

    test('samenvoegen: eigen invulling blijft, nieuwe dingen komen erbij zonder dubbelen', () {
      final own = Plan(
        members: const [PlanMember(name: 'Anna')],
        contacts: const [PlanContact(role: PlanKeys.roleOutside, name: 'Oma', phone: '1')],
        agreements: const {PlanKeys.checkin: 'eigen'},
      );
      final incoming = Plan(
        householdName: 'Buren',
        members: const [PlanMember(name: 'anna'), PlanMember(name: 'Tom')],
        contacts: const [
          PlanContact(role: PlanKeys.roleOutside, name: 'Oma', phone: '1'),
          PlanContact(role: PlanKeys.roleDoctor, name: 'Dr. Jansen', phone: '2'),
        ],
        agreements: const {PlanKeys.checkin: 'andere', PlanKeys.noteLeft: 'tafel'},
      );
      final m = mergePlans(own, incoming);
      expect(m.householdName, 'Buren');
      expect(m.members.map((e) => e.name), ['Anna', 'Tom']);
      expect(m.contacts.length, 2);
      expect(m.agreement(PlanKeys.checkin), 'eigen');
      expect(m.agreement(PlanKeys.noteLeft), 'tafel');
    });
  });

  group('wijzigingen sinds delen', () {
    test('alleen na eerder delen en latere wijziging', () {
      final p = Plan(updatedAt: DateTime(2026, 3, 1), lastSharedAt: DateTime(2026, 2, 1));
      expect(p.changedSinceShared, isTrue);
      expect(Plan(updatedAt: DateTime(2026, 1, 1), lastSharedAt: DateTime(2026, 2, 1)).changedSinceShared,
          isFalse);
      expect(Plan(updatedAt: DateTime(2026, 1, 1)).changedSinceShared, isFalse);
    });
  });

  group('repository', () {
    late AppDatabase db;
    late PlanRepository repo;
    late Directory photos;
    var tick = 0;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      photos = Directory.systemTemp.createTempSync('plan_photos');
      repo = PlanRepository(db,
          photoDir: () async => photos,
          clock: () => DateTime(2026, 1, 1).add(Duration(minutes: tick++)));
    });
    tearDown(() async {
      await db.close();
      photos.deleteSync(recursive: true);
    });

    test('opslaan, laden en wijzigingsdatum', () async {
      expect((await repo.load()).hasContent, isFalse);
      await repo.setHouseholdName('Familie X');
      final id = await repo.addMember(const PlanMember(name: 'Anna'));
      await repo.addContact(const PlanContact(role: PlanKeys.roleOutside, name: 'Oma', phone: '1'));
      await repo.setPlace(PlanKeys.placeHome, address: 'Lantaarnpaal');
      await repo.setAgreement(PlanKeys.checkin, 'Elk uur');
      await repo.setLocation(PlanKeys.meterkast, 'Gang');
      final p = await repo.load();
      expect(p.householdName, 'Familie X');
      expect(p.members.single.id, id);
      expect(p.place(PlanKeys.placeHome)!.address, 'Lantaarnpaal');
      expect(p.agreement(PlanKeys.checkin), 'Elk uur');
      expect(p.createdAt, isNotNull);
      expect(p.updatedAt!.isAfter(p.createdAt!) || p.updatedAt == p.createdAt, isTrue);
    });

    test('delen en bevestigen markeren niet als gewijzigd; bewerken wel', () async {
      await repo.setAgreement(PlanKeys.checkin, 'a');
      await repo.markShared(1);
      var p = await repo.load();
      expect(p.changedSinceShared, isFalse);
      expect(p.sharedVersion, 1);
      await repo.confirmAll();
      p = await repo.load();
      expect(p.lastConfirmedAt, isNotNull);
      expect(p.changedSinceShared, isFalse);
      await repo.setAgreement(PlanKeys.checkin, 'b');
      expect((await repo.load()).changedSinceShared, isTrue);
    });

    test('foto opslaan, vervangen en verwijderen ruimt bestanden op', () async {
      await repo.setLocationPhoto(PlanKeys.meterkast, Uint8List.fromList([1, 2, 3]));
      var path = (await repo.load()).locations[PlanKeys.meterkast]!.photoPath!;
      expect(File(path).existsSync(), isTrue);
      await repo.setLocationPhoto(PlanKeys.meterkast, Uint8List.fromList([4, 5]));
      expect(File(path).existsSync(), isFalse);
      path = (await repo.load()).locations[PlanKeys.meterkast]!.photoPath!;
      await repo.removeLocationPhoto(PlanKeys.meterkast);
      expect(File(path).existsSync(), isFalse);
      expect((await repo.load()).locations[PlanKeys.meterkast]!.photoPath, isNull);
    });

    test('voorinvullen uit huishouden alleen bij leeg plan', () async {
      const h = Household(adults: 2, children: 1, pets: 1);
      await repo.prefillMembers(h, personName: (g, n) => '$g $n', petName: 'Huisdier');
      var p = await repo.load();
      expect(p.members.map((m) => m.name), ['adult 1', 'adult 2', 'child 1', 'Huisdier']);
      expect(p.pets.single.isPet, isTrue);
      await repo.prefillMembers(h, personName: (g, n) => 'x', petName: 'x');
      p = await repo.load();
      expect(p.members.length, 4);
    });

    test('importeren: vervangen en samenvoegen', () async {
      await repo.addMember(const PlanMember(name: 'Eigen'));
      await repo.setAgreement(PlanKeys.checkin, 'eigen');
      final incoming = parsePlanFile(planToJsonString(filledPlan(), const ShareOptions(care: true),
              now: DateTime(2026, 11, 10)))
          .plan;

      await repo.replaceAll(mergePlans(await repo.load(), incoming));
      var p = await repo.load();
      expect(p.members.map((m) => m.name), containsAll(['Eigen', 'Anna']));
      expect(p.agreement(PlanKeys.checkin), 'eigen'); // eigen blijft bij samenvoegen

      await repo.replaceAll(incoming, keepMeta: false);
      p = await repo.load();
      expect(p.members.map((m) => m.name), ['Anna', 'Sam', 'Bello']);
      expect(p.agreement(PlanKeys.checkin), 'Elk heel uur een sms');
    });

    test('algemene back-up neemt het plan mee en reset wist het', () async {
      final items = ItemRepository(db);
      await repo.setHouseholdName('Back-up');
      await repo.addContact(const PlanContact(role: PlanKeys.roleOutside, name: 'Oma', phone: '1'));
      await repo.setSkipped(PlanSection.care, true, const {});
      await repo.markShared(3);
      final json = await items.exportJson();
      expect(jsonDecode(json)['noodplan'], isNotNull);

      await items.resetAll();
      expect((await repo.load()).hasContent, isFalse);

      await items.importJson(json);
      final p = await repo.load();
      expect(p.householdName, 'Back-up');
      expect(p.contacts.single.name, 'Oma');
      expect(p.skipped, {PlanSection.care});
      expect(p.sharedVersion, 3);
    });

    test('import van oude back-up (zonder plan) wist het plan niet stilzwijgend verkeerd', () async {
      final items = ItemRepository(db);
      await repo.setHouseholdName('Weg');
      final legacy = jsonEncode({'app': 'nl-noodpakket', 'version': 1, 'items': [], 'settings': {}});
      await items.importJson(legacy);
      // Een back-up zonder plan vervangt alles: het plan is dan leeg.
      expect((await repo.load()).hasContent, isFalse);
    });
  });

  group('migratie v1 -> v2', () {
    test('bestaande data blijft staan en plantabellen worden aangemaakt', () async {
      final executor = NativeDatabase.memory(setup: (raw) {
        raw.execute('''
          CREATE TABLE item_rows (
            id TEXT NOT NULL PRIMARY KEY,
            is_custom INTEGER NOT NULL DEFAULT 0,
            hidden INTEGER NOT NULL DEFAULT 0,
            name TEXT NULL,
            category_id TEXT NULL,
            why TEXT NULL,
            unit TEXT NULL,
            in_house INTEGER NOT NULL DEFAULT 0,
            quantity_have REAL NULL,
            quantity_override REAL NULL,
            expiry_date INTEGER NULL,
            interval_months INTEGER NULL,
            last_checked INTEGER NULL,
            notes TEXT NOT NULL DEFAULT ''
          )''');
        raw.execute('CREATE TABLE setting_rows (key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)');
        raw.execute("INSERT INTO item_rows (id, in_house, notes) VALUES ('water', 1, 'blijft')");
        raw.execute("INSERT INTO setting_rows (key, value) VALUES ('leadDays', '14')");
        raw.execute('PRAGMA user_version = 1');
      });
      final db = AppDatabase.forTesting(executor);
      addTearDown(db.close);

      final rows = await db.select(db.itemRows).get();
      expect(rows.single.id, 'water');
      expect(rows.single.inHouse, isTrue);
      expect(rows.single.notes, 'blijft');
      expect((await db.select(db.settingRows).get()).single.value, '14');

      // nieuwe tabellen bestaan en zijn bruikbaar
      final repo = PlanRepository(db);
      await repo.setHouseholdName('Na migratie');
      expect((await repo.load()).householdName, 'Na migratie');
      final v = await db.customSelect('PRAGMA user_version').getSingle();
      expect(v.data.values.first, 2);
    });
  });
}
