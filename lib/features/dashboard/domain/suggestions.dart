import '../../../domain/expiry.dart';
import '../../../domain/models.dart';
import 'readiness.dart';

enum SuggestionKind { household, nlAlert, water, expiring, plan, vault, item, maintenance }

class Suggestion {
  const Suggestion({
    required this.id,
    required this.kind,
    required this.route,
    this.count = 0,
    this.days = 0,
    this.itemName = '',
    this.variant = '',
  });

  /// Stabiel id, gebruikt voor "Later" en "Niet relevant".
  final String id;
  final SuggestionKind kind;
  final String route;
  final int count;
  final double days;
  final String itemName;

  /// Verfijnt de tekst: bijv. "verlopen" of "bijna", of "afmaken" voor het noodplan.
  final String variant;
}

class SuggestionInput {
  const SuggestionInput({
    required this.items,
    required this.household,
    required this.readiness,
    required this.leadDays,
    required this.now,
    required this.planStarted,
    required this.planComplete,
    required this.planLastCheck,
    required this.vaultHasDocs,
    required this.nlAlertDone,
    required this.maintenanceDue,
    this.later = const {},
    this.dismissed = const {},
  });

  final List<Item> items;
  final Household household;
  final Readiness readiness;
  final int leadDays;
  final DateTime now;
  final bool planStarted, planComplete, vaultHasDocs, nlAlertDone;
  final DateTime? planLastCheck;
  final int maintenanceDue;

  /// Suggestie-id -> verborgen tot (Later, 7 dagen).
  final Map<String, DateTime> later;

  /// Permanent verborgen ("Niet relevant").
  final Set<String> dismissed;
}

const laterDays = 7;

/// Een noodplan dat al meer dan zes maanden niet is nagelopen.
bool planIsStale(DateTime? lastCheck, DateTime now) =>
    lastCheck != null && addMonths(dateOnly(lastCheck), 6).isBefore(dateOnly(now));

/// Deterministische volgorde van suggesties (voor het dashboard worden de
/// eerste drie getoond):
///  1 huishouden, 2 NL-Alert, 3 water, 4 verlopen/bijna verlopen,
///  5 noodplan, 6 kluis, 7 overige ontbrekende items op prioriteit, 8 onderhoud.
List<Suggestion> buildSuggestions(SuggestionInput s) {
  final out = <Suggestion>[];
  final today = dateOnly(s.now);

  if (s.household.people == 0) {
    out.add(const Suggestion(id: 'household', kind: SuggestionKind.household, route: '/instellingen'));
  }
  if (!s.nlAlertDone) {
    out.add(const Suggestion(id: 'nlalert', kind: SuggestionKind.nlAlert, route: '/start/nl-alert'));
  }

  final waterItems = s.items.where((i) => i.coverage == Coverage.water && !i.hidden);
  if (waterItems.isNotEmpty && s.readiness.waterDays < readinessTargetDays) {
    out.add(Suggestion(
      id: 'water',
      kind: SuggestionKind.water,
      route: '/item/${waterItems.first.id}',
      days: s.readiness.waterDays,
      variant: s.readiness.hasInput ? 'few' : 'none',
    ));
  }

  var expired = 0, soon = 0;
  for (final i in s.items) {
    if (i.hidden) continue;
    switch (statusFor(dueDate(i), s.now, s.leadDays)) {
      case ExpiryStatus.expired:
        expired++;
      case ExpiryStatus.soon:
        soon++;
      default:
    }
  }
  if (expired + soon > 0) {
    out.add(Suggestion(
      id: 'expiring',
      kind: SuggestionKind.expiring,
      route: '/checklist?tab=vervangen',
      count: expired > 0 ? expired : soon,
      variant: expired > 0 ? 'expired' : 'soon',
    ));
  }

  if (!s.planStarted) {
    out.add(const Suggestion(id: 'plan', kind: SuggestionKind.plan, route: '/plan', variant: 'new'));
  } else if (!s.planComplete) {
    out.add(const Suggestion(id: 'plan', kind: SuggestionKind.plan, route: '/plan', variant: 'finish'));
  } else if (planIsStale(s.planLastCheck, s.now)) {
    out.add(const Suggestion(id: 'plan', kind: SuggestionKind.plan, route: '/plan', variant: 'stale'));
  }

  final idCopies = s.items.where((i) => i.id == 'id_copies' && !i.hidden && !i.inHouse);
  if (!s.vaultHasDocs || idCopies.isNotEmpty) {
    out.add(const Suggestion(id: 'vault', kind: SuggestionKind.vault, route: '/kluis'));
  }

  final missing = [
    for (final i in s.items)
      if (!i.inHouse && !i.hidden && i.coverage != Coverage.water) i,
  ]..sort((a, b) => a.priority.index.compareTo(b.priority.index));
  for (final i in missing.take(5)) {
    out.add(Suggestion(
      id: 'item:${i.id}',
      kind: SuggestionKind.item,
      route: '/item/${i.id}',
      itemName: i.name,
      variant: i.priority.name,
    ));
  }

  if (s.maintenanceDue > 0) {
    out.add(Suggestion(
        id: 'maintenance', kind: SuggestionKind.maintenance, route: '/start', count: s.maintenanceDue));
  }

  return [
    for (final x in out)
      if (!s.dismissed.contains(x.id) && !(s.later[x.id]?.isAfter(today) ?? false)) x,
  ];
}
