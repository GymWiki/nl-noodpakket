import 'plan_models.dart';

/// Welke afspraken zijn relevant voor dit huishouden? Kinderen, huisdieren en
/// hulpbehoevenden alleen als ze in het plan voorkomen.
List<String> requiredAgreementKeys(Plan p) => [
      PlanKeys.checkin,
      PlanKeys.noteLeft,
      if (p.members.any((m) => m.isChild)) PlanKeys.kids,
      if (p.pets.isNotEmpty) PlanKeys.pets,
      if (p.members.any((m) => !m.isPet && m.needsHelp)) PlanKeys.vulnerable,
    ];

SectionStatus _fromCounts(int filled, int required) {
  if (filled == 0) return SectionStatus.empty;
  return filled >= required ? SectionStatus.done : SectionStatus.partial;
}

/// Status van één onderdeel. Overgeslagen onderdelen tellen als afgehandeld,
/// zodat er geen druk ontstaat om alles te vullen.
SectionStatus sectionStatus(Plan p, PlanSection s) {
  final status = _rawStatus(p, s);
  // Overslaan telt alleen zolang er niets is ingevuld.
  if (status == SectionStatus.empty && p.skipped.contains(s)) return SectionStatus.skipped;
  return status;
}

SectionStatus _rawStatus(Plan p, PlanSection s) {
  switch (s) {
    case PlanSection.household:
      if (p.members.isEmpty) return SectionStatus.empty;
      return p.members.every((m) => m.name.trim().isNotEmpty)
          ? SectionStatus.done
          : SectionStatus.partial;
    case PlanSection.contacts:
      // Klaar: een contact buiten de regio én minstens één noodcontact.
      final outside = p.contactsOf(PlanKeys.roleOutside).isNotEmpty;
      final emergency = p.contactsOf(PlanKeys.roleEmergency).isNotEmpty;
      if (p.contacts.isEmpty) return SectionStatus.empty;
      return outside && emergency ? SectionStatus.done : SectionStatus.partial;
    case PlanSection.places:
      final filled = PlanKeys.placeKinds
          .where((k) => (p.place(k)?.address.trim() ?? '').isNotEmpty)
          .length;
      return _fromCounts(filled, PlanKeys.placeKinds.length);
    case PlanSection.agreements:
      final required = requiredAgreementKeys(p);
      final anyFilled = PlanKeys.agreementKeys.any((k) => p.agreement(k).isNotEmpty);
      if (!anyFilled) return SectionStatus.empty;
      return required.every((k) => p.agreement(k).isNotEmpty)
          ? SectionStatus.done
          : SectionStatus.partial;
    case PlanSection.home:
      final anyFilled = PlanKeys.homeKeys.any((k) => !(p.locations[k]?.isEmpty ?? true));
      if (!anyFilled) return SectionStatus.empty;
      return PlanKeys.homeCoreKeys.every((k) => p.locationText(k).isNotEmpty)
          ? SectionStatus.done
          : SectionStatus.partial;
    case PlanSection.care:
      // Optioneel: alles wat is ingevuld is genoeg.
      return p.hasCare || p.documents.trim().isNotEmpty
          ? SectionStatus.done
          : SectionStatus.empty;
    case PlanSection.neighbours:
      final filled = PlanKeys.neighbourKeys.where((k) => p.agreement(k).isNotEmpty).length;
      return _fromCounts(filled, 2);
  }
}

class PlanProgress {
  const PlanProgress(this.statuses);
  final Map<PlanSection, SectionStatus> statuses;

  int get total => PlanSection.values.length;
  int get completed => statuses.values
      .where((s) => s == SectionStatus.done || s == SectionStatus.skipped)
      .length;
  bool get started => statuses.values.any((s) => s != SectionStatus.empty);
  bool get isComplete => completed == total;
}

PlanProgress planProgress(Plan p) => PlanProgress({
      for (final s in PlanSection.values) s: sectionStatus(p, s),
    });
