import '../../../domain/expiry.dart';
import '../../../domain/models.dart';

/// Doel: 3 dagen (72 uur) zelfredzaam, zoals het advies van Denk Vooruit.
const readinessTargetDays = 3;

/// Reken met 3 liter water en 3 maaltijden per persoon per dag.
const litersPerPersonPerDay = 3.0;
const mealsPerPersonPerDay = 3.0;

class Readiness {
  const Readiness({
    required this.persons,
    required this.waterLiters,
    required this.waterDays,
    required this.foodMeals,
    required this.foodDays,
    required this.days,
    required this.hasInput,
    required this.needsQuantities,
    required this.excluded,
    required this.completeness,
  });

  final int persons;
  final double waterLiters, waterDays, foodMeals, foodDays;

  /// Dagen zelfredzaam: het minimum van water en voedsel (alleen wat bijgehouden wordt).
  final double days;

  /// Is er ooit een hoeveelheid voor water of voedsel ingevuld?
  final bool hasInput;

  /// Water of voedsel is afgevinkt als "in huis" maar zonder hoeveelheid; dat telt niet mee.
  final bool needsQuantities;

  /// Aantal items dat niet meetelt omdat de houdbaarheid verlopen is.
  final int excluded;

  /// Gewogen compleetheid 0..1 (kritiek telt 3, belangrijk 2, aanvullend 1).
  final double completeness;

  bool get goalReached => days >= readinessTargetDays;

  /// Dagen voor weergave: nooit boven het doel, naar beneden afgerond op 0,1.
  double get displayDays => (days.clamp(0, readinessTargetDays) * 10).floor() / 10;

  double get ringValue => (days / readinessTargetDays).clamp(0.0, 1.0);
}

int priorityWeight(ItemPriority p) => switch (p) {
      ItemPriority.kritiek => 3,
      ItemPriority.belangrijk => 2,
      ItemPriority.aanvullend => 1,
    };

bool isExpired(Item i, DateTime now) {
  final d = dueDate(i);
  return d != null && d.isBefore(dateOnly(now));
}

/// Berekent de paraatheid. Bewust niet-optimistisch:
///  - alleen ingevulde hoeveelheden tellen (afgevinkt zonder hoeveelheid = 0),
///  - verlopen items tellen niet mee,
///  - het resultaat is het minimum van water en voedsel,
///  - een type dat de gebruiker heeft verborgen, wordt niet verplicht.
Readiness computeReadiness(List<Item> items, Household h, DateTime now) {
  final persons = h.people < 1 ? 1 : h.people;
  var liters = 0.0, meals = 0.0;
  var excluded = 0;
  var hasWaterItem = false, hasFoodItem = false;
  var hasInput = false, needsQ = false;

  for (final i in items) {
    if (i.coverage == Coverage.none || i.hidden) continue;
    if (i.coverage == Coverage.water) hasWaterItem = true;
    if (i.coverage == Coverage.food) hasFoodItem = true;
    final have = i.quantityHave;
    if (i.inHouse && (have == null || have <= 0)) needsQ = true;
    if (have == null || have <= 0) continue;
    hasInput = true;
    if (isExpired(i, now)) {
      excluded++;
      continue;
    }
    if (i.coverage == Coverage.water) liters += have;
    if (i.coverage == Coverage.food) meals += have;
  }

  final waterDays = liters / (persons * litersPerPersonPerDay);
  final foodDays = meals / (persons * mealsPerPersonPerDay);
  final tracked = <double>[
    if (hasWaterItem) waterDays,
    if (hasFoodItem) foodDays,
  ];
  final days = tracked.isEmpty ? 0.0 : tracked.reduce((a, b) => a < b ? a : b);

  var got = 0, total = 0;
  for (final i in items) {
    if (i.hidden) continue;
    final w = priorityWeight(i.priority);
    total += w;
    if (i.inHouse && !isExpired(i, now)) got += w;
  }

  return Readiness(
    persons: persons,
    waterLiters: liters,
    waterDays: waterDays,
    foodMeals: meals,
    foodDays: foodDays,
    days: days,
    hasInput: hasInput,
    needsQuantities: needsQ,
    excluded: excluded,
    completeness: total == 0 ? 0 : got / total,
  );
}
