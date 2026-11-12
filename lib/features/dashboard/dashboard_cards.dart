import 'package:flutter/material.dart';
import '../../core/theme/category_palette.dart';
import '../kluis/data/vault_controller.dart';
import '../pro/pro_providers.dart';
import '../pro/pro_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/calm.dart';
import '../../core/dialer.dart';
import '../../core/format.dart';
import '../../core/l10n/strings.dart';
import '../../core/providers.dart';
import '../../core/ui.dart';
import '../../domain/expiry.dart';
import '../../domain/models.dart';
import '../wiki/wiki_providers.dart';
import '../rampenzender/ui/rampenzender_widgets.dart';
import 'dashboard_providers.dart';
import 'domain/maintenance.dart';
import 'domain/readiness.dart';
import 'domain/seasonal.dart';
import 'domain/suggestions.dart';

/// Eén blok op het dashboard. De registry bepaalt per kaart of hij nu
/// zichtbaar is; [slim] kaarten (de noodbalk) tellen niet mee voor het maximum.
class DashCard {
  const DashCard({
    required this.id,
    required this.priority,
    required this.isVisible,
    required this.build,
    this.slim = false,
    this.group,
  });

  final String id;
  final int priority;
  final bool slim;

  /// Kaarten met dezelfde [group] direct na elkaar worden samen in één lijstvlak getoond.
  final String? group;
  final bool Function(DashboardData d) isVisible;
  final Widget Function(BuildContext context) build;
}

/// Ongeveer zes kaarten tegelijk, naast de smalle noodbalk.
const maxDashCards = 6;

const overviewGroup = 'overview';

final dashboardCards = <DashCard>[
  DashCard(id: 'emergency', priority: 0, slim: true, isVisible: (_) => true, build: (_) => const EmergencyBar()),
  DashCard(id: 'readiness', priority: 1, isVisible: (_) => true, build: (_) => const ReadinessCard()),
  DashCard(id: 'next', priority: 2, isVisible: (d) => d.suggestions.isNotEmpty, build: (_) => const NextStepsCard()),
  DashCard(
      id: 'allgood',
      priority: 2,
      isVisible: (d) => d.suggestions.isEmpty && d.hasItems,
      build: (_) => const AllGoodCard()),
  DashCard(id: 'expiring', priority: 3, isVisible: (d) => d.expiring.isNotEmpty, build: (_) => const ExpiringCard()),
  DashCard(id: 'seasonal', priority: 4, isVisible: (d) => d.seasonal != null, build: (_) => const SeasonalCardView()),
  DashCard(
      id: 'maintenance',
      priority: 5,
      isVisible: (d) => d.maintenanceDue.isNotEmpty,
      build: (_) => const MaintenanceCard()),
  // Rustige lijst "Meer overzicht": één vlak, één regel per onderdeel.
  DashCard(
      id: 'radio',
      priority: 6,
      group: overviewGroup,
      isVisible: (d) => d.radioPending,
      build: (_) => const RadioDashCard()),
  DashCard(id: 'planvault', priority: 7, group: overviewGroup, isVisible: (_) => true, build: (_) => const PlanVaultRow()),
  DashCard(id: 'household', priority: 8, group: overviewGroup, isVisible: (_) => true, build: (_) => const HouseholdCard()),
];

/// Zichtbare kaarten in vaste volgorde, begrensd op [maxDashCards] (de noodbalk telt niet mee).
List<DashCard> visibleCards(DashboardData d, {List<DashCard>? registry, int max = maxDashCards}) {
  final all = [...(registry ?? dashboardCards)]..sort((a, b) => a.priority.compareTo(b.priority));
  final out = <DashCard>[];
  var counted = 0;
  for (final c in all) {
    if (!c.isVisible(d)) continue;
    if (!c.slim) {
      if (counted >= max) continue;
      counted++;
    }
    out.add(c);
  }
  return out;
}

bool _bigText(BuildContext c) => MediaQuery.textScalerOf(c).scale(1) > 1.3;

// ---------------------------------------------------------------------------
// 1. Noodbalk

class EmergencyBar extends StatelessWidget {
  const EmergencyBar({super.key});

  @override
  Widget build(BuildContext context) {
    final big = _bigText(context);
    final call = Semantics(
      button: true,
      label: '${S.dashCall112}. ${S.dashCall112Hint}',
      excludeSemantics: true,
      child: FilledButton.icon(
        onPressed: () => openDialer(context, '112'),
        icon: const Icon(Icons.call),
        label: const Text(S.dashCall112),
        style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
      ),
    );
    final hour = Semantics(
      button: true,
      label: S.homeFirstHour,
      excludeSemantics: true,
      child: FilledButton.tonalIcon(
        onPressed: () => context.push('/wiki/eerste-uur'),
        icon: const Icon(Icons.schedule_rounded),
        label: const Text(S.homeFirstHour),
        style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
      ),
    );
    if (big) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [call, const SizedBox(height: 8), hour]);
    return Row(children: [Expanded(child: call), const SizedBox(width: 12), Expanded(child: hour)]);
  }
}

// ---------------------------------------------------------------------------
// 2. Paraatheid

class ReadinessCard extends ConsumerWidget {
  const ReadinessCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final r = ref.watch(readinessProvider);
    final items = ref.watch(visibleItemsProvider).value ?? const <Item>[];
    final done = items.where((i) => i.inHouse).length;
    final pct = items.isEmpty ? 0 : (done * 100 / items.length).round();
    final plan = ref.watch(planVaultStatusProvider);
    final empty = !r.hasInput && !r.needsQuantities;

    final days = fmtQty(r.displayDays);
    // Alleen afgevinkt, nog geen hoeveelheden: geen "0 van 3", maar een duidelijke vraag.
    final fill = !r.hasInput && r.needsQuantities;
    final headline = empty ? S.dashReadyEmpty : (fill ? S.dashReadyFill : S.dashReadyDays(days));
    final String? note = empty
        ? S.dashReadyEmptySub
        : r.goalReached
            ? S.dashReadyGoal
            : fill
                ? S.dashReadyNeedQty
                : null;

    Widget stepRow(IconData icon, String text, String route, {bool go = false}) => InkWell(
          onTap: () => go ? context.go(route) : context.push(route),
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(children: [
              Icon(icon, size: 22, color: c.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: t.textTheme.bodyLarge)),
              Icon(Icons.chevron_right_rounded, color: c.onSurfaceVariant),
            ]),
          ),
        );

    return SoftCard(
      padding: const EdgeInsets.all(Space.screen),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(header: true, child: Text(S.dashReadyTitle, style: t.textTheme.titleMedium)),
        const SizedBox(height: Space.group),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Semantics(
            label: empty ? S.dashReadyEmpty : (fill ? S.dashReadyFill : S.dashReadyDays(days)),
            excludeSemantics: true,
            child: ProgressRing(
              value: empty || fill ? 0 : r.ringValue,
              size: 80,
              child: empty || fill
                  ? Icon(Icons.inventory_2_outlined, color: c.onSurfaceVariant)
                  : Padding(
                      padding: const EdgeInsets.all(14),
                      child: FittedBox(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(days, style: t.textTheme.headlineSmall),
                          Text('/ 3', style: t.textTheme.labelMedium?.copyWith(color: c.onSurfaceVariant)),
                        ]),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(headline, style: t.textTheme.titleMedium),
              if (note != null) ...[
                const SizedBox(height: 6),
                Text(note, style: t.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
              ],
            ]),
          ),
        ]),
        if (!empty && !fill) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => ReadinessHowSheet(readiness: r),
              ),
              child: const Text(S.dashReadyHow),
            ),
          ),
          Text(S.dashReadyEstimate, style: t.textTheme.bodySmall),
        ],
        const Divider(height: Space.section),
        Semantics(header: true, child: Text(S.dashStepsTitle, style: t.textTheme.bodySmall)),
        const SizedBox(height: 4),
        stepRow(Icons.inventory_2_outlined, S.dashStepPacket(pct), '/checklist', go: true),
        stepRow(
            Icons.assignment_outlined,
            plan.planStarted ? S.dashStepPlan(plan.planDone, plan.planTotal) : S.dashStepPlanNone,
            '/plan'),
        stepRow(Icons.forum_outlined, S.dashStepTalk, '/plan/gesprek'),
      ]),
    );
  }
}

class ReadinessHowSheet extends StatelessWidget {
  const ReadinessHowSheet({super.key, required this.readiness});
  final Readiness readiness;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final r = readiness;
    Widget p(String s) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(s, style: t.textTheme.bodyLarge));
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(header: true, child: Text(S.dashHowTitle, style: t.textTheme.titleLarge)),
          const SizedBox(height: 12),
          p(S.dashHowGoal),
          p(S.dashHowWater(r.persons, fmtQty(r.waterLiters), fmtQty(double.parse(r.waterDays.toStringAsFixed(1))))),
          p(S.dashHowFood(r.persons, fmtQty(r.foodMeals), fmtQty(double.parse(r.foodDays.toStringAsFixed(1))))),
          p(S.dashHowMin),
          p(S.dashHowRules),
          if (r.excluded > 0) p(S.dashHowExcluded(r.excluded)),
          Text(S.dashReadyEstimate, style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Volgende stap

class SuggestionText {
  const SuggestionText(this.title, this.sub, this.action, this.icon);
  final String title, sub, action;
  final IconData icon;
}

/// Kleur van het icoonbolletje per soort suggestie (alleen een extra aanwijzing).
CategoryTint suggestionTint(Suggestion s) => switch (s.kind) {
      SuggestionKind.household => CategoryTint.slate,
      SuggestionKind.nlAlert => CategoryTint.violet,
      SuggestionKind.water => CategoryTint.blue,
      SuggestionKind.expiring => CategoryTint.slate,
      SuggestionKind.plan => CategoryTint.green,
      SuggestionKind.vault => CategoryTint.indigo,
      SuggestionKind.item => CategoryTint.blue,
      SuggestionKind.maintenance => CategoryTint.teal,
    };

SuggestionText suggestionText(Suggestion s) => switch (s.kind) {
      SuggestionKind.household => const SuggestionText(
          S.dashSugHouseholdT, S.dashSugHouseholdS, S.dashSugHouseholdA, Icons.groups_outlined),
      SuggestionKind.nlAlert => const SuggestionText(
          S.dashSugNlAlertT, S.dashSugNlAlertS, S.dashSugNlAlertA, Icons.notifications_active_outlined),
      SuggestionKind.water => s.variant == 'none'
          ? const SuggestionText(S.dashSugWaterNoneT, S.dashSugWaterNoneS, S.dashSugWaterA, Icons.water_drop_outlined)
          : SuggestionText(S.dashSugWaterFewT(fmtQty(double.parse(s.days.toStringAsFixed(1)))),
              S.dashSugWaterFewS, S.dashSugWaterA, Icons.water_drop_outlined),
      SuggestionKind.expiring => SuggestionText(
          s.variant == 'expired' ? S.dashSugExpiredT(s.count) : S.dashSugSoonT(s.count),
          S.dashSugExpiringS,
          S.dashSugExpiringA,
          Icons.event_repeat_outlined),
      SuggestionKind.plan => switch (s.variant) {
          'finish' => const SuggestionText(
              S.dashSugPlanFinishT, S.dashSugPlanFinishS, S.dashSugPlanA, Icons.assignment_outlined),
          'stale' => const SuggestionText(
              S.dashSugPlanStaleT, S.dashSugPlanStaleS, S.dashSugPlanA, Icons.assignment_outlined),
          _ => const SuggestionText(
              S.dashSugPlanNewT, S.dashSugPlanNewS, S.dashSugPlanA, Icons.assignment_outlined),
        },
      SuggestionKind.vault => const SuggestionText(
          S.dashSugVaultT, S.dashSugVaultS, S.dashSugVaultA, Icons.lock_outline),
      SuggestionKind.item => SuggestionText(
          S.dashSugItemT(s.itemName),
          switch (s.variant) {
            'kritiek' => S.dashSugItemKritiek,
            'belangrijk' => S.dashSugItemBelangrijk,
            _ => S.dashSugItemAanvullend,
          },
          S.dashSugItemA,
          Icons.checklist_rounded),
      SuggestionKind.maintenance => SuggestionText(
          S.dashSugMaintT(s.count), S.dashSugMaintS, S.dashSugMaintA, Icons.build_circle_outlined),
    };

/// Eén suggestie met één hoofdactie en twee rustige opties om hem weg te leggen.
class SuggestionTile extends ConsumerWidget {
  const SuggestionTile(this.s, {super.key});
  final Suggestion s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final x = suggestionText(s);
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(dashActionsProvider);
    final route = s.kind == SuggestionKind.maintenance ? '/start/onderhoud' : s.route;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconBadge(x.icon, size: 40, tint: suggestionTint(s)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(x.title, style: t.textTheme.titleSmall?.copyWith(fontSize: 16)),
            const SizedBox(height: 2),
            Text(x.sub, style: t.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
          ]),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonal(
              onPressed: () => context.push(route),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              child: Text(x.action),
            ),
          ),
        ),
        // "Later" en "Niet relevant" blijven beschikbaar, maar rustig in een menu.
        PopupMenuButton<String>(
          tooltip: S.moreOptions,
          icon: const Icon(Icons.more_horiz_rounded),
          onSelected: (v) async {
            if (v == 'later') {
              await actions.later(s.id);
              messenger.showSnackBar(const SnackBar(content: Text(S.dashLaterDone)));
            } else {
              await actions.dismiss(s.id);
              messenger.showSnackBar(const SnackBar(content: Text(S.dashNotRelevantDone)));
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'later', child: Text(S.dashLater)),
            PopupMenuItem(value: 'dismiss', child: Text(S.dashNotRelevant)),
          ],
        ),
      ]),
    ]);
  }
}

class NextStepsCard extends ConsumerWidget {
  const NextStepsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final all = ref.watch(suggestionsProvider);
    // Eén duidelijke volgende stap; de rest staat achter "Toon alles".
    final shown = all.take(1).toList();
    return SoftCard(
      padding: const EdgeInsets.all(Space.screen),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(header: true, child: Text(S.dashNextTitle, style: t.textTheme.titleMedium)),
        const SizedBox(height: 8),
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const Divider(height: 24),
          SuggestionTile(shown[i]),
        ],
        if (all.length > shown.length)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push('/start/suggesties'),
              child: const Text(S.dashShowAll),
            ),
          ),
      ]),
    );
  }
}

class AllGoodCard extends StatelessWidget {
  const AllGoodCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    return SoftCard(
      child: Row(children: [
        IconBadge(Icons.check_rounded, background: c.secondaryContainer, foreground: c.onSecondaryContainer),
        const SizedBox(width: 14),
        Expanded(child: Text(S.dashAllGoodLine, style: t.textTheme.titleSmall?.copyWith(fontSize: 16))),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Binnenkort vervangen

class ExpiringCard extends ConsumerWidget {
  const ExpiringCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final list = ref.watch(expiringProvider);
    final shown = list.take(3).toList();
    return SoftCard(
      padding: const EdgeInsets.all(Space.screen),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(S.dashExpiringTitle,
            padding: const EdgeInsets.only(bottom: 8),
            leading: const IconBadge(Icons.event_repeat_outlined, size: 32, tint: CategoryTint.slate)),
        for (final e in shown)
          InkWell(
            onTap: () => context.push('/item/${e.item.id}'),
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.item.name, style: t.textTheme.titleSmall?.copyWith(fontSize: 16)),
                    // Alleen echt verlopen krijgt een waarschuwingskleur.
                    Text(
                      e.status == ExpiryStatus.expired ? S.dashExpiredOn(fmtDate(e.due)) : S.dashDueOn(fmtDate(e.due)),
                      style: t.textTheme.bodyMedium?.copyWith(
                          color: e.status == ExpiryStatus.expired ? c.error : c.onSurfaceVariant),
                    ),
                  ]),
                ),
                Icon(Icons.chevron_right_rounded, color: c.onSurfaceVariant),
              ]),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.go('/checklist?tab=vervangen'),
            child: const Text(S.dashExpiringAll),
          ),
        ),
        if (!ref.watch(proUnlockedProvider) && !ref.watch(proHintDismissedProvider)) ...[
          const Divider(height: 16),
          Row(children: [
            Expanded(
              child: InkWell(
                onTap: () => showPaywall(context),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Align(alignment: Alignment.centerLeft, child: Text(S.dashRemindHint, style: t.textTheme.bodyMedium)),
                ),
              ),
            ),
            TextButton(
              onPressed: () => ref.read(settingsRepositoryProvider).setRaw(proHintDismissedKey, 'true'),
              child: const Text(S.paywallNotNow),
            ),
          ]),
        ],
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Nu relevant

class SeasonalCardView extends ConsumerWidget {
  const SeasonalCardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final s = ref.watch(seasonalProvider);
    if (s == null) return const SizedBox.shrink();
    final wiki = ref.watch(wikiProvider).value;
    final isTest = s.kind == SeasonalKind.nlAlertTest;
    return SoftCard(
      color: c.tertiaryContainer,
      borderColor: c.tertiaryContainer,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconBadge(isTest ? Icons.notifications_active_outlined : Icons.ac_unit_rounded,
              size: 40, background: c.surface, foreground: c.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Semantics(
                header: true,
                child: Text(isTest ? S.dashSeasonNlAlertT(fmtDate(s.date!)) : S.dashSeasonWinterT,
                    style: t.textTheme.titleSmall?.copyWith(fontSize: 16, color: c.onTertiaryContainer)),
              ),
              const SizedBox(height: 2),
              Text(isTest ? S.dashSeasonNlAlertS : S.dashSeasonWinterS,
                  style: t.textTheme.bodyMedium?.copyWith(color: c.onTertiaryContainer)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        if (isTest)
          FilledButton.tonal(
            onPressed: () => context.push('/start/nl-alert'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            child: const Text(S.dashSeasonNlAlertA),
          )
        else
          Wrap(spacing: 8, children: [
            for (final id in s.wikiIds)
              if (wiki?.byId(id) != null)
                FilledButton.tonal(
                  onPressed: () => context.push('/wiki/$id'),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  child: Text(wiki!.byId(id)!.titel),
                ),
          ]),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. Noodplan en Kluis (alleen status, nooit documentnamen)

class PlanVaultRow extends ConsumerWidget {
  const PlanVaultRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final st = ref.watch(planVaultStatusProvider);
    final planSub = !st.planStarted && st.sharedFrom != null
        ? '${S.sharedWithMe}: ${S.sharedFrom(st.sharedFrom!)}'
        : !st.planStarted
        ? S.dashPlanNone
        : st.planDone < st.planTotal
            ? S.dashPlanPart(st.planDone, st.planTotal)
            : st.planStale
                ? S.dashPlanStale
                : S.dashPlanDone;
    final vaultCount = ref.watch(vaultDocCountProvider).value;
    final vaultSub = !st.vaultHasDocs
        ? S.dashVaultNone
        : (!ref.watch(proUnlockedProvider) && vaultCount != null && vaultCount > 0)
            ? S.vaultFreeCounter(vaultCount) // alleen een aantal, nooit namen of inhoud
            : S.dashVaultSome;

    Widget row(IconData icon, String title, String sub, String route, CategoryTint tint) => StatusRow(
          icon: icon,
          tint: tint,
          title: title,
          subtitle: sub,
          onTap: () => context.push(route),
          semanticLabel: '$title. $sub',
        );

    return Column(children: [
      row(Icons.assignment_outlined, S.dashPlanCard, planSub, '/plan', CategoryTint.green),
      Divider(height: 1, indent: Space.screen, endIndent: Space.screen, color: c.outlineVariant),
      row(Icons.lock_outline, S.dashVaultCard, vaultSub, '/kluis', CategoryTint.indigo),
    ]);
  }
}

// ---------------------------------------------------------------------------
// 7. Onderhoud

String routineName(String id) => switch (id) {
      'rookmelder' => S.maintRookmelder,
      'pakket' => S.maintPakket,
      'powerbank' => S.maintPowerbank,
      _ => S.maintBatterijen,
    };

String routineEvery(Routine r) => switch (r.intervalMonths) {
      1 => S.maintEveryMonth,
      6 => S.maintEveryHalfYear,
      _ => S.maintEveryYear,
    };

class MaintenanceCard extends ConsumerWidget {
  const MaintenanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final due = ref.watch(maintenanceDueProvider);
    final dates = ref.watch(routineDatesProvider);
    return SoftCard(
      padding: const EdgeInsets.all(Space.screen),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(S.maintTitle,
            padding: const EdgeInsets.only(bottom: 8),
            leading: const IconBadge(Icons.build_circle_outlined, size: 32, tint: CategoryTint.teal)),
        for (final r in due.take(3))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(routineName(r.id), style: t.textTheme.titleSmall?.copyWith(fontSize: 16)),
                  Text(routineEvery(r) + (dates[r.id] == null ? '' : '. ${S.maintDue(fmtDate(dates[r.id]!))}'),
                      style: t.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
                ]),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () => ref.read(dashActionsProvider).maintenanceDone(r.id),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                child: const Text(S.maintDone),
              ),
            ]),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.push('/start/onderhoud'),
            child: const Text(S.maintAll),
          ),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// 8. Huishouden

String householdSummary(Household h) {
  String n(int v, String one, String many) => '$v ${v == 1 ? one : many}';
  return [
    if (h.adults > 0) n(h.adults, 'volwassene', 'volwassenen'),
    if (h.children > 0) n(h.children, 'kind', 'kinderen'),
    if (h.babies > 0) n(h.babies, 'baby', "baby's"),
    if (h.seniors > 0) n(h.seniors, '65-plusser', '65-plussers'),
    if (h.pets > 0) n(h.pets, 'huisdier', 'huisdieren'),
    if (h.usesMedication) 'medicijngebruik',
  ].join(', ');
}

class HouseholdCard extends ConsumerWidget {
  const HouseholdCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = ref.watch(settingsProvider.select((s) => s.value?.household)) ?? const Household();
    return StatusRow(
      icon: Icons.groups_outlined,
      tint: CategoryTint.slate,
      title: S.dashHouseholdTitle,
      subtitle: householdSummary(h),
      onTap: () => context.push('/instellingen'),
      semanticLabel: '${S.dashHouseholdTitle}: ${householdSummary(h)}. ${S.dashHouseholdEdit}',
    );
  }
}
