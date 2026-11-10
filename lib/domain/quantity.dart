import 'models.dart';

/// Aanbevolen hoeveelheid voor een standaarditem bij dit huishouden.
/// Altijd minimaal 1 (een item dat relevant is, is er minstens één van).
double recommendedQuantity(SeedItem s, Household h) {
  final total = s.base +
      s.perAdult * h.adults +
      s.perChild * h.children +
      s.perBaby * h.babies +
      s.perSenior * h.seniors +
      s.perPet * h.pets;
  final rounded = total.ceilToDouble();
  return rounded < 1 ? 1 : rounded;
}

/// Is het standaarditem relevant voor dit huishouden?
bool isRelevant(SeedItem s, Household h) => s.need == null || h.has(s.need!);
