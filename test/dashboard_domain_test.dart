import 'package:flutter_test/flutter_test.dart';
import 'package:mijnnoodpakket/core/format.dart';
import 'package:mijnnoodpakket/data/seed/seed_items.dart';
import 'package:mijnnoodpakket/domain/models.dart';
import 'package:mijnnoodpakket/features/dashboard/domain/dash_prefs.dart';
import 'package:mijnnoodpakket/features/dashboard/domain/maintenance.dart';
import 'package:mijnnoodpakket/features/dashboard/domain/readiness.dart';
import 'package:mijnnoodpakket/features/dashboard/domain/seasonal.dart';
import 'package:mijnnoodpakket/features/dashboard/domain/suggestions.dart';

Item item(
  String id, {
  Coverage coverage = Coverage.none,
  ItemPriority priority = ItemPriority.aanvullend,
  bool inHouse = false,
  double? have,
  DateTime? expiry,
  bool hidden = false,
  String category = Cat.other,
}) =>
    Item(
      id: id,
      isCustom: false,
      hidden: hidden,
      name: id,
      category: category,
      why: '',
      unit: 'stuks',
      recommended: 1,
      inHouse: inHouse,
      quantityHave: have,
      expiryDate: expiry,
      priority: priority,
      coverage: coverage,
    );

void main() {
  prefsTests();
  unitTests();
  final now = DateTime(2026, 11, 11, 12);

  group('seed: prioriteit en dekking', () {
    SeedItem s(String id) => seedItems.firstWhere((e) => e.id == id);

    test('kritiek: water, voedsel, medicatie, radio, zaklamp, powerbank', () {
      for (final id in ['water', 'food', 'medication', 'radio', 'flashlight', 'powerbank']) {
        expect(s(id).priority, ItemPriority.kritiek, reason: id);
      }
    });
    test('alleen water en voedsel tellen mee voor dagen; liters en maaltijden', () {
      expect(s('water').coverage, Coverage.water);
      expect(s('water').unit, 'liter');
      expect(s('food').coverage, Coverage.food);
      expect(s('food').unit, 'maaltijden');
      expect(seedItems.where((e) => e.coverage != Coverage.none).length, 2);
    });
    test('elk item heeft een prioriteit; er zijn van elke soort', () {
      expect(seedItems.map((e) => e.priority).toSet(), ItemPriority.values.toSet());
    });
  });

  group('paraatheid', () {
    const h2 = Household(adults: 2);

    test('2 volwassenen, 18 liter en 18 maaltijden = 3 dagen: doel bereikt', () {
      final r = computeReadiness([
        item('water', coverage: Coverage.water, inHouse: true, have: 18),
        item('food', coverage: Coverage.food, inHouse: true, have: 18),
      ], h2, now);
      expect(r.waterDays, 3);
      expect(r.foodDays, 3);
      expect(r.days, 3);
      expect(r.goalReached, isTrue);
      expect(r.displayDays, 3);
      expect(r.ringValue, 1);
    });

    test('het minimum van water en voedsel bepaalt de uitkomst', () {
      final r = computeReadiness([
        item('water', coverage: Coverage.water, inHouse: true, have: 18),
        item('food', coverage: Coverage.food, inHouse: true, have: 9),
      ], h2, now);
      expect(r.waterDays, 3);
      expect(r.foodDays, 1.5);
      expect(r.days, 1.5);
      expect(r.goalReached, isFalse);
    });

    test('verlopen items tellen niet mee', () {
      final r = computeReadiness([
        item('water', coverage: Coverage.water, inHouse: true, have: 18, expiry: DateTime(2026, 11, 10)),
        item('food', coverage: Coverage.food, inHouse: true, have: 18),
      ], h2, now);
      expect(r.waterLiters, 0);
      expect(r.days, 0);
      expect(r.excluded, 1);
      // vandaag verlopen telt nog wel
      final today = computeReadiness([
        item('water', coverage: Coverage.water, inHouse: true, have: 18, expiry: DateTime(2026, 11, 11)),
        item('food', coverage: Coverage.food, inHouse: true, have: 18),
      ], h2, now);
      expect(today.waterLiters, 18);
    });

    test('afgevinkt zonder hoeveelheid telt niet (niet-optimistisch) en vraagt om invoer', () {
      final r = computeReadiness([
        item('water', coverage: Coverage.water, inHouse: true),
        item('food', coverage: Coverage.food, inHouse: true),
      ], h2, now);
      expect(r.days, 0);
      expect(r.hasInput, isFalse);
      expect(r.needsQuantities, isTrue);
    });

    test('huishouden wijzigen herberekent: meer personen = minder dagen', () {
      final items = [
        item('water', coverage: Coverage.water, inHouse: true, have: 18),
        item('food', coverage: Coverage.food, inHouse: true, have: 18),
      ];
      expect(computeReadiness(items, const Household(adults: 2), now).days, 3);
      expect(computeReadiness(items, const Household(adults: 2, children: 1), now).days, 2);
      expect(computeReadiness(items, const Household(adults: 1), now).days, 6);
    });

    test('geen deling door nul: 0 personen telt als 1; lege lijst geeft 0', () {
      final r = computeReadiness([item('water', coverage: Coverage.water, have: 9, inHouse: true)],
          const Household(adults: 0), now);
      expect(r.persons, 1);
      expect(r.waterDays, 3);
      final empty = computeReadiness(const [], const Household(adults: 0), now);
      expect(empty.days, 0);
      expect(empty.completeness, 0);
      expect(empty.hasInput, isFalse);
    });

    test('verborgen voedsel wordt niet verplicht; beide verborgen = 0', () {
      final r = computeReadiness([
        item('water', coverage: Coverage.water, inHouse: true, have: 18),
        item('food', coverage: Coverage.food, hidden: true),
      ], h2, now);
      expect(r.days, 3);
      final none = computeReadiness([
        item('water', coverage: Coverage.water, hidden: true),
        item('food', coverage: Coverage.food, hidden: true),
      ], h2, now);
      expect(none.days, 0);
    });

    test('weergave: nooit boven het doel, naar beneden afgerond', () {
      final r = computeReadiness([
        item('water', coverage: Coverage.water, inHouse: true, have: 100),
        item('food', coverage: Coverage.food, inHouse: true, have: 17),
      ], h2, now);
      expect(r.days, closeTo(17 / 6, 1e-9));
      expect(r.displayDays, 2.8); // 2,83 -> 2,8
      final big = computeReadiness([
        item('water', coverage: Coverage.water, inHouse: true, have: 100),
        item('food', coverage: Coverage.food, inHouse: true, have: 100),
      ], h2, now);
      expect(big.displayDays, 3);
    });

    test('gewogen compleetheid: kritiek telt zwaarder', () {
      final r = computeReadiness([
        item('a', priority: ItemPriority.kritiek, inHouse: true),
        item('b', priority: ItemPriority.aanvullend),
      ], h2, now);
      expect(r.completeness, 3 / 4);
      final r2 = computeReadiness([
        item('a', priority: ItemPriority.kritiek),
        item('b', priority: ItemPriority.aanvullend, inHouse: true),
      ], h2, now);
      expect(r2.completeness, 1 / 4);
    });
  });

  group('suggesties', () {
    SuggestionInput input({
      List<Item>? items,
      Household household = const Household(adults: 2),
      bool nlAlertDone = true,
      bool planStarted = true,
      bool planComplete = true,
      DateTime? planLastCheck,
      bool vaultHasDocs = true,
      int maintenanceDue = 0,
      Map<String, DateTime> later = const {},
      Set<String> dismissed = const {},
    }) {
      final list = items ?? [];
      return SuggestionInput(
        items: list,
        household: household,
        readiness: computeReadiness(list, household, now),
        leadDays: 30,
        now: now,
        planStarted: planStarted,
        planComplete: planComplete,
        planLastCheck: planLastCheck ?? DateTime(2026, 10, 1),
        vaultHasDocs: vaultHasDocs,
        nlAlertDone: nlAlertDone,
        maintenanceDue: maintenanceDue,
        later: later,
        dismissed: dismissed,
      );
    }

    test('volgorde: huishouden, NL-Alert, water, verlopen, plan, kluis, items, onderhoud', () {
      final i = input(
        household: const Household(adults: 0),
        nlAlertDone: false,
        planStarted: false,
        vaultHasDocs: false,
        maintenanceDue: 1,
        items: [
          item('water', coverage: Coverage.water, have: 2, inHouse: true),
          item('x', expiry: DateTime(2026, 11, 20), inHouse: true),
          item('y', priority: ItemPriority.kritiek),
          item('z', priority: ItemPriority.aanvullend),
        ],
      );
      final ids = buildSuggestions(i).map((s) => s.id).toList();
      expect(ids, ['household', 'nlalert', 'water', 'expiring', 'plan', 'vault', 'item:y', 'item:z', 'maintenance']);
    });

    test('overige ontbrekende items staan op prioriteit: kritiek, belangrijk, aanvullend', () {
      final s = buildSuggestions(input(items: [
        item('a', priority: ItemPriority.aanvullend),
        item('b', priority: ItemPriority.kritiek),
        item('c', priority: ItemPriority.belangrijk),
      ]));
      expect(s.where((x) => x.kind == SuggestionKind.item).map((x) => x.id), ['item:b', 'item:c', 'item:a']);
    });

    test('verlopen gaat voor bijna verlopen', () {
      final s = buildSuggestions(input(items: [
        item('a', expiry: DateTime(2026, 11, 1), inHouse: true),
        item('b', expiry: DateTime(2026, 11, 20), inHouse: true),
      ]));
      final e = s.firstWhere((x) => x.id == 'expiring');
      expect(e.variant, 'expired');
      expect(e.count, 1);
    });

    test('water: geen suggestie als het doel gehaald is', () {
      final ok = buildSuggestions(input(items: [
        item('water', coverage: Coverage.water, have: 18, inHouse: true),
      ]));
      expect(ok.any((x) => x.kind == SuggestionKind.water), isFalse);
      final low = buildSuggestions(input(items: [
        item('water', coverage: Coverage.water, have: 3, inHouse: true),
      ]));
      expect(low.firstWhere((x) => x.kind == SuggestionKind.water).days, 0.5);
    });

    test('noodplan: nieuw, afmaken en langer dan 6 maanden niet gecontroleerd', () {
      String? variant(SuggestionInput i) =>
          buildSuggestions(i).where((x) => x.id == 'plan').map((x) => x.variant).firstOrNull;
      expect(variant(input(planStarted: false)), 'new');
      expect(variant(input(planComplete: false)), 'finish');
      expect(variant(input(planLastCheck: DateTime(2026, 5, 1))), 'stale');
      expect(variant(input(planLastCheck: DateTime(2026, 6, 1))), isNull); // net binnen 6 maanden
    });

    test('kluis: ook als ID-kopieën nog open staan', () {
      final s = buildSuggestions(input(
        vaultHasDocs: true,
        items: [item('id_copies', inHouse: false)],
      ));
      expect(s.any((x) => x.id == 'vault'), isTrue);
    });

    test('"Later" verbergt 7 dagen, "Niet relevant" blijft verborgen', () {
      final base = input(nlAlertDone: false);
      expect(buildSuggestions(base).any((x) => x.id == 'nlalert'), isTrue);
      final later = input(nlAlertDone: false, later: {'nlalert': DateTime(2026, 11, 18)});
      expect(buildSuggestions(later).any((x) => x.id == 'nlalert'), isFalse);
      // na de verborgen-datum komt hij terug
      final back = input(nlAlertDone: false, later: {'nlalert': DateTime(2026, 11, 11)});
      expect(buildSuggestions(back).any((x) => x.id == 'nlalert'), isTrue);
      final gone = input(nlAlertDone: false, dismissed: {'nlalert'});
      expect(buildSuggestions(gone).any((x) => x.id == 'nlalert'), isFalse);
    });

    test('alles op orde: geen suggesties', () {
      expect(buildSuggestions(input(items: [
        item('water', coverage: Coverage.water, have: 18, inHouse: true),
        item('a', inHouse: true),
      ])), isEmpty);
    });

    test('later-dagen is 7', () => expect(laterDays, 7));
  });

  group('seizoen en NL-Alert-test', () {
    test('eerste maandag van juni en december', () {
      expect(firstMonday(2026, 6), DateTime(2026, 6, 1));
      expect(firstMonday(2026, 12), DateTime(2026, 12, 7));
      expect(firstMonday(2027, 6), DateTime(2027, 6, 7));
    });

    test('volgende testbericht', () {
      expect(nextNlAlertTest(DateTime(2026, 11, 11)), DateTime(2026, 12, 7));
      expect(nextNlAlertTest(DateTime(2026, 12, 7, 15)), DateTime(2026, 12, 7)); // op de dag zelf
      expect(nextNlAlertTest(DateTime(2026, 12, 8)), DateTime(2027, 6, 7));
      expect(nextNlAlertTest(DateTime(2027, 1, 20)), DateTime(2027, 6, 7));
    });

    test('NL-Alert-kaart in de week ervoor, winterkaart in dec t/m feb, anders niets', () {
      expect(seasonalFor(DateTime(2026, 11, 29)), isNull); // 8 dagen ervoor: nog niet
      expect(seasonalFor(DateTime(2026, 11, 30))!.kind, SeasonalKind.nlAlertTest); // 7 dagen ervoor
      final test = seasonalFor(DateTime(2026, 12, 3))!;
      expect(test.kind, SeasonalKind.nlAlertTest);
      expect(test.date, DateTime(2026, 12, 7));
      expect(seasonalFor(DateTime(2026, 12, 7))!.kind, SeasonalKind.nlAlertTest);
      expect(seasonalFor(DateTime(2026, 12, 8))!.kind, SeasonalKind.winter);
      expect(seasonalFor(DateTime(2027, 1, 15))!.kind, SeasonalKind.winter);
      expect(seasonalFor(DateTime(2027, 2, 28))!.kind, SeasonalKind.winter);
      expect(seasonalFor(DateTime(2026, 11, 11)), isNull);
      expect(seasonalFor(DateTime(2027, 4, 10)), isNull);
      expect(seasonalFor(DateTime(2027, 7, 15)), isNull); // geen officiële hitteperiode
      expect(seasonalFor(DateTime(2027, 6, 3))!.kind, SeasonalKind.nlAlertTest);
    });

    test('de winterkaart verwijst naar bestaande wiki-stappenplannen', () {
      final w = seasonalFor(DateTime(2027, 1, 15))!;
      expect(w.wikiIds, ['co-vergiftiging', 'kou-gladheid']);
    });
  });

  group('onderhoud', () {
    final anchor = DateTime(2026, 5, 11);

    test('nooit gedaan: vervalt anker + interval', () {
      final r = routines.firstWhere((x) => x.id == 'pakket');
      expect(routineDue(r, anchor: anchor), DateTime(2026, 11, 11));
    });

    test('gedaan: nieuwe vervaldatum = gedaan + interval', () {
      final r = routines.firstWhere((x) => x.id == 'rookmelder');
      expect(routineDue(r, lastDone: DateTime(2026, 11, 11), anchor: anchor), DateTime(2026, 12, 11));
    });

    test('openstaand: vervallen routines, nog niet vervallen niet', () {
      final due = dueRoutines(now, done: {}, anchor: anchor);
      expect(due.map((r) => r.id), containsAll(['rookmelder', 'pakket', 'powerbank']));
      expect(due.map((r) => r.id), isNot(contains('batterijen'))); // 12 maanden
      final after = dueRoutines(now, done: {'rookmelder': DateTime(2026, 11, 11)}, anchor: anchor);
      expect(after.map((r) => r.id), isNot(contains('rookmelder')));
    });

    test('herinnering om 10:00; voorbij = morgen', () {
      expect(routineReminderTime(DateTime(2026, 12, 1), now), DateTime(2026, 12, 1, 10));
      expect(routineReminderTime(DateTime(2026, 11, 1), now), DateTime(2026, 11, 12, 10));
    });
  });
}

void unitTests() {
  test('enkelvoud bij 1: stuk, set, maaltijd', () {
    expect(unitFor('stuks', 1), 'stuk');
    expect(unitFor('stuks', 2), 'stuks');
    expect(unitFor('sets', 1), 'set');
    expect(unitFor('liter', 1), 'liter');
    expect(unitFor('maaltijden', 1), 'maaltijd');
  });
}

void prefsTests() {
  group('dashboard-voorkeuren', () {
    test('lezen uit de opgeslagen waarden', () {
      final p = DashPrefs.fromRaw({
        DashKeys.later: encodeDayMap({'water': DateTime(2026, 11, 18)}),
        DashKeys.dismissed: encodeSet({'plan', 'vault'}),
        DashKeys.nlAlertDone: '2026-11-01',
        DashKeys.maintDone: encodeDayMap({'rookmelder': DateTime(2026, 10, 1)}),
        DashKeys.maintAnchor: '2026-05-11',
        DashKeys.maintRemind: encodeSet({'powerbank'}),
      });
      expect(p.later['water'], DateTime(2026, 11, 18));
      expect(p.dismissed, {'plan', 'vault'});
      expect(p.nlAlertDone, DateTime(2026, 11, 1));
      expect(p.maintDone['rookmelder'], DateTime(2026, 10, 1));
      expect(p.maintAnchor, DateTime(2026, 5, 11));
      expect(p.maintRemind, {'powerbank'});
    });

    test('lege of kapotte waarden geven veilige standaarden', () {
      final p = DashPrefs.fromRaw({DashKeys.later: 'kapot', DashKeys.dismissed: '{', DashKeys.nlAlertDone: 'x'});
      expect(p.later, isEmpty);
      expect(p.dismissed, isEmpty);
      expect(p.nlAlertDone, isNull);
      expect(DashPrefs.fromRaw(const {}).maintAnchor, isNull);
    });

    test('dayString is stabiel', () => expect(dayString(DateTime(2026, 1, 5, 23)), '2026-01-05'));
  });
}
