import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/calm.dart';
import '../../../core/format.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/providers.dart';
import '../../../core/ui.dart';
import '../../../data/repositories/settings_repository.dart';
import '../domain/plan_models.dart';
import '../domain/plan_progress.dart';
import '../plan_providers.dart';
import 'plan_import.dart';
import 'plan_widgets.dart';

/// Wegklikbare banner in de checklist zolang er geen plan is.
class PlanBanner extends ConsumerWidget {
  const PlanBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final plan = ref.watch(planProvider);
    if (settings == null || settings.planBannerDismissed || !plan.hasValue) {
      return const SizedBox.shrink();
    }
    if (plan.value!.hasContent) return const SizedBox.shrink();
    final t = Theme.of(context);
    return Card(
      color: t.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.planBannerText,
              style: t.textTheme.titleMedium?.copyWith(
                color: t.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: () => context.push('/plan'),
                  child: const Text(S.planBannerCta),
                ),
                TextButton(
                  onPressed: () async {
                    final repo = ref.read(settingsRepositoryProvider);
                    await repo.save(
                      (await repo.load()).copyWith(planBannerDismissed: true),
                    );
                  },
                  child: const Text(S.planBannerDismiss),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Zet de halfjaarlijkse noodplan-herinnering aan of uit. De meldingstoestemming
/// wordt pas gevraagd op het moment dat de herinnering wordt aangezet.
Future<void> togglePlanReminder(
  BuildContext context,
  WidgetRef ref,
  bool on,
) async {
  final repo = ref.read(settingsRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  await repo.save((await repo.load()).copyWith(planReminder: on));
  if (!on) return;
  final granted = await ref
      .read(notificationServiceProvider)
      .requestPermission();
  await repo.save((await repo.load()).copyWith(permissionAsked: true));
  if (!granted) {
    messenger.showSnackBar(const SnackBar(content: Text(S.notifDenied)));
  }
}

class PlanOverviewScreen extends ConsumerWidget {
  const PlanOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(planProvider);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(S.planTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(S.planLoadError),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(planProvider),
                child: const Text(S.retry),
              ),
            ],
          ),
        ),
        data: (plan) {
          final progress = planProgress(plan);
          return ListView(
            padding: const EdgeInsets.fromLTRB(Space.screen, 8, Space.screen, 32),
            children: [
              Text(S.planOverviewIntro, style: t.textTheme.bodyLarge),
              const SizedBox(height: Space.group),
              SoftCard(
                padding: const EdgeInsets.all(Space.screen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.planCardSub(progress.completed, progress.total),
                      style: t.textTheme.titleMedium,
                    ),
                    const SizedBox(height: Space.group),
                    LinearProgressIndicator(
                      value: progress.completed / progress.total,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ],
                ),
              ),
              if (plan.changedSinceShared) ...[
                const SizedBox(height: Space.group),
                SoftCard(
                  color: t.colorScheme.tertiaryContainer,
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(Icons.update, color: t.colorScheme.onTertiaryContainer),
                    title: Text(
                      S.planChangedSinceShare,
                      style: TextStyle(color: t.colorScheme.onTertiaryContainer),
                    ),
                    trailing: TextButton(
                      onPressed: () => context.push('/plan/delen'),
                      child: const Text(S.planReshare),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: Space.group),
              FilledButton(
                onPressed: () => context.push('/plan/wizard'),
                child: Text(progress.started ? S.planContinue : S.planStartPlan),
              ),
              const SizedBox(height: Space.group),
              CalmListGroup(children: [
                for (final s in PlanSection.values)
                  StatusRow(
                    icon: sectionIcon(s),
                    title: sectionTitle(s),
                    subtitle: statusLabel(progress.statuses[s]!),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(statusIcon(progress.statuses[s]!), size: 18),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, color: t.colorScheme.onSurfaceVariant),
                    ]),
                    onTap: () => context.push('/plan/wizard?s=${s.name}'),
                  ),
              ]),
              // Acties als één rustige lijst in plaats van losse knoppen.
              CalmSection(
                child: CalmListGroup(children: [
                  ListTile(
                    leading: const Icon(Icons.forum_outlined),
                    title: const Text(S.planTalk),
                    onTap: () => context.push('/plan/gesprek'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.ios_share),
                    title: const Text(S.planShare),
                    enabled: plan.hasContent,
                    onTap: plan.hasContent ? () => context.push('/plan/delen') : null,
                  ),
                  ListTile(
                    leading: const Icon(Icons.verified_outlined),
                    title: const Text(S.planConfirm),
                    enabled: plan.hasContent,
                    onTap: plan.hasContent ? () => ref.read(planRepositoryProvider).confirmAll() : null,
                  ),
                  ListTile(
                    leading: const Icon(Icons.file_open_outlined),
                    title: const Text(S.planImport),
                    onTap: () => startPlanImport(context, ref),
                  ),
                  SwitchListTile(
                    title: const Text(S.planReminder),
                    subtitle: const Text(S.planReminderSub),
                    value: settings.planReminder,
                    onChanged: (v) => togglePlanReminder(context, ref, v),
                  ),
                ]),
              ),
              const SizedBox(height: Space.section),
              if (plan.updatedAt != null) Text(S.planUpdated(fmtDate(plan.updatedAt!)), style: t.textTheme.bodySmall),
              if (plan.lastConfirmedAt != null)
                Text(S.planConfirmed(fmtDate(plan.lastConfirmedAt!)), style: t.textTheme.bodySmall),
              if (plan.lastSharedAt != null)
                Text(S.planLastShared(fmtDate(plan.lastSharedAt!)), style: t.textTheme.bodySmall),
              const SizedBox(height: Space.tight),
              Row(
                children: [
                  Icon(Icons.lock_outline, size: 18, color: t.colorScheme.onSurfaceVariant),
                  const SizedBox(width: Space.tight),
                  Expanded(child: Text(S.planPrivacy, style: t.textTheme.bodySmall)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
