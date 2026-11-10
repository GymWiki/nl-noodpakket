import 'package:flutter_test/flutter_test.dart';
import 'package:mijnnoodpakket/data/seed/seed_items.dart';
import 'package:mijnnoodpakket/domain/expiry.dart';
import 'package:mijnnoodpakket/domain/models.dart';
import 'package:mijnnoodpakket/domain/quantity.dart';

SeedItem seed(String id) => seedItems.firstWhere((s) => s.id == id);

Item item({DateTime? expiry, int? interval, DateTime? checked}) => Item(
      id: 'x',
      isCustom: true,
      hidden: false,
      name: 'x',
      category: Cat.other,
      why: '',
      unit: 'stuks',
      recommended: 1,
      inHouse: false,
      expiryDate: expiry,
      intervalMonths: interval,
      lastChecked: checked,
    );

void main() {
  group('hoeveelheden', () {
    test('water: 3 liter p.p.p.d. x 3 dagen, huisdier apart', () {
      const h = Household(adults: 2, children: 1, babies: 1, seniors: 1, pets: 1);
      // 5 personen x 9 liter + 1 huisdier x 2 liter
      expect(recommendedQuantity(seed('water'), h), 47);
    });

    test('contant geld: 70 per volwassene/oudere, 30 per kind, 0 per baby', () {
      const h = Household(adults: 2, children: 2, babies: 1, seniors: 1);
      expect(recommendedQuantity(seed('cash'), h), 2 * 70 + 2 * 30 + 70);
    });

    test('vaste items blijven 1, ongeacht huishoudgrootte', () {
      const h = Household(adults: 4, children: 3);
      expect(recommendedQuantity(seed('first_aid'), h), 1);
    });

    test('minimaal 1 wanneer een item relevant is', () {
      const h = Household(adults: 1);
      expect(recommendedQuantity(seed('whistle'), h), 1);
      // alleen kinderen: zaklamp-factor voor volwassenen is 0, toch minimaal 1
      expect(
          recommendedQuantity(seed('flashlight'), const Household(adults: 0, children: 2)),
          1);
    });

    test('luiers: 18 per baby', () {
      expect(
          recommendedQuantity(seed('diapers'), const Household(babies: 2)), 36);
    });

    test('relevantie: baby-, huisdier- en medicatie-items', () {
      const plain = Household();
      expect(isRelevant(seed('diapers'), plain), isFalse);
      expect(isRelevant(seed('pet_food'), plain), isFalse);
      expect(isRelevant(seed('medication'), plain), isFalse);
      expect(isRelevant(seed('water'), plain), isTrue);
      expect(isRelevant(seed('diapers'), const Household(babies: 1)), isTrue);
      expect(isRelevant(seed('medication'), const Household(usesMedication: true)),
          isTrue);
    });

    test('seed: unieke id\'s', () {
      final ids = seedItems.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('houdbaarheid', () {
    test('addMonths kapt af op einde van de maand', () {
      expect(addMonths(DateTime(2025, 1, 31), 1), DateTime(2025, 2, 28));
      expect(addMonths(DateTime(2024, 1, 31), 1), DateTime(2024, 2, 29));
      expect(addMonths(DateTime(2025, 11, 15), 3), DateTime(2026, 2, 15));
      expect(addMonths(DateTime(2025, 6, 10), 12), DateTime(2026, 6, 10));
    });

    test('dueDate: datum wint van interval; interval = controle + maanden', () {
      expect(dueDate(item(expiry: DateTime(2026, 5, 1, 13))), DateTime(2026, 5, 1));
      expect(dueDate(item(interval: 6, checked: DateTime(2026, 1, 15))),
          DateTime(2026, 7, 15));
      expect(
          dueDate(item(
              expiry: DateTime(2026, 5, 1),
              interval: 6,
              checked: DateTime(2026, 1, 15))),
          DateTime(2026, 5, 1));
      expect(dueDate(item()), isNull);
      expect(dueDate(item(interval: 6)), isNull);
    });

    final now = DateTime(2026, 11, 10, 12);
    test('status: verlopen / binnenkort / ok / geen', () {
      expect(statusFor(null, now, 30), ExpiryStatus.none);
      expect(statusFor(DateTime(2026, 11, 9), now, 30), ExpiryStatus.expired);
      expect(statusFor(DateTime(2026, 11, 10), now, 30), ExpiryStatus.soon);
      expect(statusFor(DateTime(2026, 12, 10), now, 30), ExpiryStatus.soon);
      expect(statusFor(DateTime(2026, 12, 11), now, 30), ExpiryStatus.ok);
    });

    test('herinneringstijd: 09:00, lead dagen eerder', () {
      expect(reminderTime(DateTime(2027, 1, 31), now, 30),
          DateTime(2027, 1, 1, 9));
    });

    test('herinneringstijd: al voorbij maar nog niet verlopen = morgen 09:00', () {
      expect(reminderTime(DateTime(2026, 11, 20), now, 30),
          DateTime(2026, 11, 11, 9));
    });

    test('herinneringstijd: verlopen of vandaag-na-09:00 geeft geen melding', () {
      expect(reminderTime(DateTime(2026, 11, 9), now, 30), isNull);
      expect(reminderTime(DateTime(2026, 11, 10), now, 30), isNull);
    });
  });
}
