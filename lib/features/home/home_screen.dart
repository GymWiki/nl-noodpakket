import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dialer.dart';
import '../../core/format.dart';
import '../../core/l10n/strings.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../domain/expiry.dart';
import '../../domain/models.dart';
import '../kluis/data/vault_controller.dart';
import '../noodplan/plan_providers.dart';

/// Berekent de suggesties voor "Volgende stappen" (puur, getest).
List<({String kind, String title, String sub, String route})> nextSteps({
  required List<Item> items,
  required int leadDays,
  required bool planStarted,
  required bool vaultHasDocs,
  required DateTime now,
}) {
  final out = <({String kind, String title, String sub, String route})>[];
  if (!planStarted) {
    out.add((kind: 'plan', title: S.homeStepPlan, sub: S.homeStepPlanSub, route: '/plan'));
  }
  final expiring = items.where((i) {
    final st = statusFor(dueDate(i), now, leadDays);
    return st == ExpiryStatus.soon || st == ExpiryStatus.expired;
  }).length;
  if (expiring > 0) {
    out.add((
      kind: 'expiring',
      title: S.homeStepExpiring(expiring),
      sub: S.homeStepExpiringSub,
      route: '/checklist?tab=vervangen',
    ));
  }
  // De categorie met de minste voortgang.
  final byCat = <String, List<Item>>{};
  for (final i in items) {
    byCat.putIfAbsent(i.category, () => []).add(i);
  }
  String? weakest;
  var weakestRatio = 1.0;
  for (final e in byCat.entries) {
    final done = e.value.where((i) => i.inHouse).length;
    final ratio = done / e.value.length;
    if (done < e.value.length && ratio < weakestRatio) {
      weakest = e.key;
      weakestRatio = ratio;
    }
  }
  if (weakest != null) {
    final list = byCat[weakest]!;
    out.add((
      kind: 'category',
      title: S.homeStepCategory(categoryName(weakest)),
      sub: S.homeStepCategorySub(list.where((i) => i.inHouse).length, list.length),
      route: '/checklist',
    ));
  }
  if (!vaultHasDocs) {
    out.add((kind: 'vault', title: S.homeStepVault, sub: S.homeStepVaultSub, route: '/kluis'));
  }
  return out.take(3).toList();
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static IconData _icon(String kind) => switch (kind) {
        'plan' => Icons.assignment_outlined,
        'expiring' => Icons.event_repeat_outlined,
        'category' => Icons.checklist_rounded,
        _ => Icons.lock_outline,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final items = ref.watch(visibleItemsProvider).value ?? const <Item>[];
    final settings = ref.watch(settingsProvider).value;
    final planStarted = ref.watch(planProgressProvider).started;
    final hasDocs = ref.watch(vaultHasDocsProvider).value ?? false;

    final done = items.where((i) => i.inHouse).length;
    final ratio = items.isEmpty ? 0.0 : done / items.length;
    final steps = nextSteps(
      items: items,
      leadDays: settings?.leadDays ?? 30,
      planStarted: planStarted,
      vaultHasDocs: hasDocs,
      now: DateTime.now(),
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: Gap.page,
          children: [
            const PageTitle(S.homeTitle, subtitle: S.homeSub),
            SoftCard(
              onTap: () => context.go('/checklist'),
              semanticLabel: '${S.progressTotal(done, items.length)}. ${S.homeToPacket}',
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                ProgressRing(
                  value: ratio,
                  size: 92,
                  child: Text(S.homeReady((ratio * 100).round()),
                      style: t.textTheme.titleLarge),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(S.progressTotal(done, items.length), style: t.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Row(children: [
                      Text(S.homeToPacket,
                          style: t.textTheme.labelLarge?.copyWith(color: c.primary)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 18, color: c.primary),
                    ]),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: Gap.m),
            Row(children: [
              Expanded(
                child: SoftCard(
                  onTap: () => openDialer(context, '112'),
                  semanticLabel: '${S.wikiCall112}. ${S.wikiCall112Hint}',
                  child: Row(children: [
                    IconBadge(Icons.call, background: c.primary, foreground: c.onPrimary),
                    const SizedBox(width: 12),
                    Text(S.wikiCall112, style: t.textTheme.titleMedium),
                  ]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SoftCard(
                  onTap: () => context.push('/wiki/eerste-uur'),
                  semanticLabel: S.homeFirstHour,
                  child: Row(children: [
                    IconBadge(Icons.schedule_rounded,
                        background: c.tertiaryContainer, foreground: c.onTertiaryContainer),
                    const SizedBox(width: 12),
                    Expanded(child: Text(S.homeFirstHour, style: t.textTheme.titleMedium)),
                  ]),
                ),
              ),
            ]),
            SectionHeader(S.homeNext, padding: const EdgeInsets.only(top: Gap.l, bottom: Gap.s)),
            if (steps.isEmpty)
              SoftCard(
                child: Row(children: [
                  IconBadge(Icons.check_rounded, background: c.secondaryContainer, foreground: c.onSecondaryContainer),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(S.homeAllGood, style: t.textTheme.titleMedium),
                      Text(S.homeAllGoodSub, style: t.textTheme.bodyMedium),
                    ]),
                  ),
                ]),
              )
            else
              for (final s in steps) ...[
                SoftCard(
                  onTap: () => context.push(s.route),
                  child: Row(children: [
                    IconBadge(_icon(s.kind)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.title, style: t.textTheme.titleSmall?.copyWith(fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(s.sub, style: t.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
                      ]),
                    ),
                    Icon(Icons.chevron_right_rounded, color: c.onSurfaceVariant),
                  ]),
                ),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: Gap.s),
            Text(S.disclaimer, style: t.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
