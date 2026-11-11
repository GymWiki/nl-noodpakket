import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dialer.dart';
import '../../core/format.dart';
import '../../core/l10n/strings.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import 'dashboard_cards.dart';
import 'dashboard_providers.dart';
import 'domain/maintenance.dart';
import 'domain/seasonal.dart';

/// Alle openstaande suggesties (het dashboard toont er drie).
class SuggestionsScreen extends ConsumerWidget {
  const SuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(suggestionsProvider);
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(S.dashAllTitle)),
      body: SafeArea(
        child: list.isEmpty
            ? Center(child: Padding(padding: Gap.page, child: Text(S.dashAllEmpty, style: t.textTheme.titleMedium)))
            : ListView.separated(
                padding: Gap.page,
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 28),
                itemBuilder: (_, i) => SuggestionTile(list[i]),
              ),
      ),
    );
  }
}

/// Uitleg bij NL-Alert, alleen met wat nl-alert.nl en Denk Vooruit zelf vermelden.
/// Bewust geen menupaden per telefoonmerk: die verschillen en zijn niet bij ons bevestigd.
class NlAlertScreen extends ConsumerWidget {
  const NlAlertScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final now = ref.watch(dashNowProvider);
    final done = ref.watch(dashPrefsProvider).nlAlertDone != null;
    Widget fact(String s) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 12),
              child: Icon(Icons.check_circle_outline, size: 22, color: t.colorScheme.secondary),
            ),
            Expanded(child: Text(s, style: t.textTheme.bodyLarge)),
          ]),
        );
    return Scaffold(
      appBar: AppBar(title: const Text(S.nlTitle)),
      body: SafeArea(
        child: ListView(
          padding: Gap.page,
          children: [
            Text(S.nlIntro, style: t.textTheme.bodyLarge),
            const SizedBox(height: Gap.m),
            fact(S.nlFact1),
            fact(S.nlFact2),
            fact(S.nlFact3),
            fact(S.nlFact4),
            Text(S.nlNextTest(fmtDate(nextNlAlertTest(now))), style: t.textTheme.titleSmall),
            const SizedBox(height: Gap.m),
            OutlinedButton.icon(
              onPressed: () => openExternal(context, 'https://www.nl-alert.nl'),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text(S.nlOpenSite),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
            ),
            const SizedBox(height: Gap.s),
            FilledButton(
              onPressed: done
                  ? null
                  : () async {
                      final m = ScaffoldMessenger.of(context);
                      await ref.read(dashActionsProvider).nlAlertDone();
                      m.showSnackBar(const SnackBar(content: Text(S.nlDoneNote)));
                    },
              style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
              child: Text(done ? S.nlDoneNote : S.nlDone),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alle onderhoudsroutines met "Gedaan" en een eigen keuze voor een herinnering.
class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final p = ref.watch(dashPrefsProvider);
    final dates = ref.watch(routineDatesProvider);
    final due = ref.watch(maintenanceDueProvider).map((r) => r.id).toSet();
    return Scaffold(
      appBar: AppBar(title: const Text(S.maintTitle)),
      body: SafeArea(
        child: ListView(
          padding: Gap.page,
          children: [
            Text(S.maintSub, style: t.textTheme.bodyLarge),
            const SizedBox(height: Gap.m),
            for (final r in routines) ...[
              SoftCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(routineName(r.id), style: t.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${routineEvery(r)}. ${due.contains(r.id) ? S.maintDue(fmtDate(dates[r.id]!)) : S.maintNext(fmtDate(dates[r.id]!))}',
                    style: t.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    FilledButton.tonal(
                      onPressed: () => ref.read(dashActionsProvider).maintenanceDone(r.id),
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                      child: const Text(S.maintDone),
                    ),
                  ]),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(S.maintRemind),
                    value: p.maintRemind.contains(r.id),
                    onChanged: (on) async {
                      // Toestemming voor meldingen vragen we pas als je dit aanzet.
                      if (on) await ref.read(notificationServiceProvider).requestPermission();
                      await ref.read(dashActionsProvider).setReminder(r.id, on);
                    },
                  ),
                ]),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
