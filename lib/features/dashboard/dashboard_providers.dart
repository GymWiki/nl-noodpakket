import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../deel/deel_providers.dart';
import '../../core/providers.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/expiry.dart';
import '../../domain/models.dart';
import '../kluis/data/vault_controller.dart';
import '../noodplan/plan_providers.dart';
import 'domain/dash_prefs.dart';
import 'domain/maintenance.dart';
import 'domain/readiness.dart';
import 'domain/seasonal.dart';
import 'domain/suggestions.dart';

/// "Nu": apart zodat tests de tijd kunnen vastzetten.
final dashNowProvider = Provider<DateTime>((ref) => DateTime.now());

final dashPrefsProvider = Provider<DashPrefs>((ref) => DashPrefs.fromRaw(
    ref.watch(settingsProvider.select((s) => s.value?.raw)) ?? const {}));

final _householdProvider = Provider<Household>((ref) =>
    ref.watch(settingsProvider.select((s) => s.value?.household)) ?? const Household());

final readinessProvider = Provider<Readiness>((ref) => computeReadiness(
    ref.watch(allItemsProvider).value ?? const [],
    ref.watch(_householdProvider),
    ref.watch(dashNowProvider)));

/// Verlopen en bijna verlopen items, oudste eerst (alleen zichtbare items).
final expiringProvider = Provider<List<({Item item, DateTime due, ExpiryStatus status})>>((ref) {
  final now = ref.watch(dashNowProvider);
  final lead = ref.watch(settingsProvider.select((s) => s.value?.leadDays)) ?? 30;
  final out = <({Item item, DateTime due, ExpiryStatus status})>[];
  for (final i in ref.watch(visibleItemsProvider).value ?? const <Item>[]) {
    final d = dueDate(i);
    final st = statusFor(d, now, lead);
    if (d != null && (st == ExpiryStatus.soon || st == ExpiryStatus.expired)) {
      out.add((item: i, due: d, status: st));
    }
  }
  out.sort((a, b) => a.due.compareTo(b.due));
  return out;
});

DateTime _anchor(DashPrefs p, DateTime now) => p.maintAnchor ?? dateOnly(now);

final maintenanceDueProvider = Provider<List<Routine>>((ref) {
  final now = ref.watch(dashNowProvider);
  final p = ref.watch(dashPrefsProvider);
  return dueRoutines(now, done: p.maintDone, anchor: _anchor(p, now));
});

/// Vervaldatum per routine (voor de onderhoudslijst).
final routineDatesProvider = Provider<Map<String, DateTime>>((ref) {
  final now = ref.watch(dashNowProvider);
  final p = ref.watch(dashPrefsProvider);
  return {
    for (final r in routines)
      r.id: routineDue(r, lastDone: p.maintDone[r.id], anchor: _anchor(p, now)),
  };
});

/// Herinneringsmomenten voor routines waarvoor de gebruiker een herinnering aanzette.
final maintenanceReminderTimesProvider = Provider<List<DateTime>>((ref) {
  final now = ref.watch(dashNowProvider);
  final p = ref.watch(dashPrefsProvider);
  final dates = ref.watch(routineDatesProvider);
  return [
    for (final id in p.maintRemind)
      if (dates[id] != null) routineReminderTime(dates[id]!, now),
  ]..sort();
});

final seasonalProvider =
    Provider<SeasonalCard?>((ref) => seasonalFor(ref.watch(dashNowProvider)));

final _suggestionInputProvider = Provider<SuggestionInput>((ref) {
  final now = ref.watch(dashNowProvider);
  final items = ref.watch(visibleItemsProvider).value ?? const <Item>[];
  final h = ref.watch(_householdProvider);
  final progress = ref.watch(planProgressProvider);
  final plan = ref.watch(planProvider).value;
  final p = ref.watch(dashPrefsProvider);
  return SuggestionInput(
    items: items,
    household: h,
    readiness: ref.watch(readinessProvider),
    leadDays: ref.watch(settingsProvider.select((s) => s.value?.leadDays)) ?? 30,
    now: now,
    planStarted: progress.started,
    planComplete: progress.isComplete,
    planLastCheck: plan == null ? null : (plan.lastConfirmedAt ?? plan.updatedAt ?? plan.createdAt),
    vaultHasDocs: ref.watch(vaultHasDocsProvider).value ?? false,
    nlAlertDone: p.nlAlertDone != null,
    maintenanceDue: ref.watch(maintenanceDueProvider).length,
    later: p.later,
    dismissed: p.dismissed,
  );
});

/// Alle openstaande suggesties in vaste volgorde (het dashboard toont de eerste drie).
final suggestionsProvider =
    Provider<List<Suggestion>>((ref) => buildSuggestions(ref.watch(_suggestionInputProvider)));

/// Zelfde lijst zonder wat de gebruiker verborg: voor "Herstel verborgen suggesties".
final hiddenSuggestionCountProvider = Provider<int>((ref) {
  final p = ref.watch(dashPrefsProvider);
  final now = ref.watch(dashNowProvider);
  final today = dateOnly(now);
  return p.dismissed.length + p.later.values.where((d) => d.isAfter(today)).length;
});

/// Status van het noodplan en de kluis voor de twee kleine kaarten.
class PlanVaultStatus {
  const PlanVaultStatus({
    required this.planStarted,
    required this.planDone,
    required this.planTotal,
    required this.planStale,
    required this.vaultHasDocs,
    this.sharedFrom,
  });
  final bool planStarted, planStale, vaultHasDocs;
  final int planDone, planTotal;

  /// Naam van wie een plan met mij deelde (als ik geen eigen plan heb).
  final String? sharedFrom;
}

final planVaultStatusProvider = Provider<PlanVaultStatus>((ref) {
  final pr = ref.watch(planProgressProvider);
  final plan = ref.watch(planProvider).value;
  final last = plan == null ? null : (plan.lastConfirmedAt ?? plan.updatedAt ?? plan.createdAt);
  return PlanVaultStatus(
    planStarted: pr.started,
    planDone: pr.completed,
    planTotal: pr.total,
    planStale: pr.isComplete && planIsStale(last, ref.watch(dashNowProvider)),
    vaultHasDocs: ref.watch(vaultHasDocsProvider).value ?? false,
    sharedFrom: ref.watch(effectivePlanProvider).fromName,
  );
});

/// Gegevens waarop de kaartenregistry beslist wat zichtbaar is.
class DashboardData {
  const DashboardData({
    required this.hasItems,
    required this.readiness,
    required this.suggestions,
    required this.expiring,
    required this.seasonal,
    required this.maintenanceDue,
    required this.simpleStart,
  });
  final bool hasItems;
  final Readiness readiness;
  final List<Suggestion> suggestions;
  final List<({Item item, DateTime due, ExpiryStatus status})> expiring;
  final SeasonalCard? seasonal;
  final List<Routine> maintenanceDue;
  final bool simpleStart;
}

final dashboardDataProvider = Provider<DashboardData>((ref) => DashboardData(
      hasItems: (ref.watch(visibleItemsProvider).value ?? const []).isNotEmpty,
      readiness: ref.watch(readinessProvider),
      suggestions: ref.watch(suggestionsProvider),
      expiring: ref.watch(expiringProvider),
      seasonal: ref.watch(seasonalProvider),
      maintenanceDue: ref.watch(maintenanceDueProvider),
      simpleStart: ref.watch(settingsProvider.select((s) => s.value?.simpleStart)) ?? false,
    ));

/// Schrijfacties van het dashboard (alles in de lokale instellingen).
class DashActions {
  DashActions(this._ref);
  final Ref _ref;

  SettingsRepository get _repo => _ref.read(settingsRepositoryProvider);
  DashPrefs get _p => _ref.read(dashPrefsProvider);
  DateTime get _now => _ref.read(dashNowProvider);

  /// "Later": 7 dagen verborgen.
  Future<void> later(String id) => _repo.setRaw(
      DashKeys.later, encodeDayMap({..._p.later, id: dateOnly(_now).add(const Duration(days: laterDays))}));

  /// "Niet relevant": blijft verborgen tot herstel in Instellingen.
  Future<void> dismiss(String id) =>
      _repo.setRaw(DashKeys.dismissed, encodeSet({..._p.dismissed, id}));

  Future<void> restoreHidden() async {
    await _repo.deleteRaw(DashKeys.dismissed);
    await _repo.deleteRaw(DashKeys.later);
  }

  Future<void> nlAlertDone() => _repo.setRaw(DashKeys.nlAlertDone, dayString(_now));

  Future<void> maintenanceDone(String id) =>
      _repo.setRaw(DashKeys.maintDone, encodeDayMap({..._p.maintDone, id: dateOnly(_now)}));

  Future<void> setReminder(String id, bool on) {
    final s = {..._p.maintRemind};
    on ? s.add(id) : s.remove(id);
    return _repo.setRaw(DashKeys.maintRemind, encodeSet(s));
  }

  /// Eerste keer dat het dashboard is gezien: nieuwe gebruikers krijgen niet meteen een lijst.
  Future<void> ensureAnchor() async {
    if (_p.maintAnchor == null) await _repo.setRaw(DashKeys.maintAnchor, dayString(_now));
  }
}

final dashActionsProvider = Provider((ref) => DashActions(ref));
