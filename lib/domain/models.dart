/// Domeinmodellen, los van de database.
library;

/// Standaardcategorie-id's. Eigen categorieën gebruiken hun naam als id.
class Cat {
  static const water = 'water';
  static const info = 'info';
  static const light = 'light';
  static const health = 'health';
  static const docs = 'docs';
  static const other = 'other';
  static const standard = [water, info, light, health, docs, other];
}

/// Hoe belangrijk een item is voor de eerste dagen.
enum ItemPriority { kritiek, belangrijk, aanvullend }

/// Telt een item mee voor de zelfredzaamheid in dagen?
enum Coverage { none, water, food }

/// Voorwaarde waaronder een standaarditem relevant is.
enum Need { baby, child, pet, medication }

class Household {
  const Household({
    this.adults = 1,
    this.children = 0,
    this.babies = 0,
    this.seniors = 0,
    this.pets = 0,
    this.usesMedication = false,
  });

  final int adults, children, babies, seniors, pets;
  final bool usesMedication;

  int get people => adults + children + babies + seniors;

  bool has(Need n) => switch (n) {
        Need.baby => babies > 0,
        Need.child => children > 0,
        Need.pet => pets > 0,
        Need.medication => usesMedication,
      };

  Household copyWith({
    int? adults,
    int? children,
    int? babies,
    int? seniors,
    int? pets,
    bool? usesMedication,
  }) =>
      Household(
        adults: adults ?? this.adults,
        children: children ?? this.children,
        babies: babies ?? this.babies,
        seniors: seniors ?? this.seniors,
        pets: pets ?? this.pets,
        usesMedication: usesMedication ?? this.usesMedication,
      );

  Map<String, Object?> toJson() => {
        'adults': adults,
        'children': children,
        'babies': babies,
        'seniors': seniors,
        'pets': pets,
        'usesMedication': usesMedication,
      };

  factory Household.fromJson(Map<String, Object?> j) => Household(
        adults: (j['adults'] as num?)?.toInt() ?? 1,
        children: (j['children'] as num?)?.toInt() ?? 0,
        babies: (j['babies'] as num?)?.toInt() ?? 0,
        seniors: (j['seniors'] as num?)?.toInt() ?? 0,
        pets: (j['pets'] as num?)?.toInt() ?? 0,
        usesMedication: j['usesMedication'] == true,
      );

  @override
  bool operator ==(Object other) =>
      other is Household && other.toString() == toString();
  @override
  int get hashCode => toString().hashCode;
  @override
  String toString() => '$adults/$children/$babies/$seniors/$pets/$usesMedication';
}

/// Standaarditem uit de seed-data.
class SeedItem {
  const SeedItem({
    required this.id,
    required this.category,
    required this.name,
    required this.why,
    this.unit = 'stuks',
    this.shelfAdvice,
    this.intervalMonths,
    this.base = 0,
    this.perAdult = 0,
    this.perChild = 0,
    this.perBaby = 0,
    this.perSenior = 0,
    this.perPet = 0,
    this.need,
    this.priority = ItemPriority.aanvullend,
    this.coverage = Coverage.none,
  });

  final ItemPriority priority;
  final Coverage coverage;
  final String id, category, name, why, unit;
  final String? shelfAdvice;
  final int? intervalMonths;
  final double base, perAdult, perChild, perBaby, perSenior, perPet;
  final Need? need;
}

/// Samengevoegd item zoals de UI het ziet (seed + opgeslagen staat).
class Item {
  const Item({
    required this.id,
    required this.isCustom,
    required this.hidden,
    required this.name,
    required this.category,
    required this.why,
    required this.unit,
    required this.recommended,
    required this.inHouse,
    this.quantityHave,
    this.quantityOverride,
    this.expiryDate,
    this.intervalMonths,
    this.lastChecked,
    this.notes = '',
    this.shelfAdvice,
    this.suggestedIntervalMonths,
    this.priority = ItemPriority.aanvullend,
    this.coverage = Coverage.none,
  });

  final ItemPriority priority;
  final Coverage coverage;
  final String id, name, category, why, unit, notes;
  final bool isCustom, hidden, inHouse;
  final double recommended;
  final double? quantityHave, quantityOverride;
  final DateTime? expiryDate, lastChecked;
  final int? intervalMonths, suggestedIntervalMonths;
  final String? shelfAdvice;

  /// Gebruikte doelhoeveelheid: handmatig of berekend.
  double get target => quantityOverride ?? recommended;
}
