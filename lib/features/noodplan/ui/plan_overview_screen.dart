import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

/// Kaart op het tabblad "Noodgevallen".
class PlanEntryCard extends ConsumerWidget {
  const PlanEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final progress = ref.watch(planProgressProvider);
    return SoftCard(
      onTap: () => context.push('/plan'),
      child: Row(children: [
        const IconBadge(Icons.assignment_outlined),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(S.planTitle, style: t.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              progress.started
                  ? S.planCardSub(progress.completed, progress.total)
                  : S.planCardStart,
              style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant),
            ),
            if (progress.started) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress.completed / progress.total,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          ]),
        ),
        Icon(Icons.chevron_right_rounded, color: t.colorScheme.onSurfaceVariant),
      ]),
    );
  }
}

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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(S.planBannerText,
              style: t.textTheme.titleMedium?.copyWith(color: t.colorScheme.onSecondaryContainer)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            FilledButton(
              onPressed: () => context.push('/plan'),
              child: const Text(S.planBannerCta),
            ),
            TextButton(
              onPressed: () async {
                final repo = ref.read(settingsRepositoryProvider);
                await repo.save((await repo.load()).copyWith(planBannerDismissed: true));
              },
              child: const Text(S.planBannerDismiss),
            ),
          ]),
        ]),
      ),
    );
  }
}

/// Zet de halfjaarlijkse noodplan-herinnering aan of uit. De meldingstoestemming
/// wordt pas gevraagd op het moment dat de herinnering wordt aangezet.
Future<void> togglePlanReminder(BuildContext context, WidgetRef ref, bool on) async {
  final repo = ref.read(settingsRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  await repo.save((await repo.load()).copyWith(planReminder: on));
  if (!on) return;
  final granted = await ref.read(notificationServiceProvider).requestPermission();
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(S.planLoadError),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: () => ref.invalidate(planProvider), child: const Text(S.retry)),
          ]),
        ),
        data: (plan) {
          final progress = planProgress(plan);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(S.planOverviewIntro, style: t.textTheme.bodyLarge),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(S.planCardSub(progress.completed, progress.total),
                        style: t.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress.completed / progress.total,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ]),
                ),
              ),
              if (plan.changedSinceShared) ...[
                const SizedBox(height: 12),
                Card(
                  color: t.colorScheme.tertiaryContainer,
                  child: ListTile(
                    leading: Icon(Icons.update, color: t.colorScheme.onTertiaryContainer),
                    title: Text(S.planChangedSinceShare,
                        style: TextStyle(color: t.colorScheme.onTertiaryContainer)),
                    trailing: TextButton(
                      onPressed: () => context.push('/plan/delen'),
                      child: const Text(S.planReshare),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push('/plan/wizard'),
                child: Text(progress.started ? S.planContinue : S.planStartPlan),
              ),
              const SizedBox(height: 8),
              for (final s in PlanSection.values)
                Builder(builder: (context) {
                  final st = progress.statuses[s]!;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    minVerticalPadding: 12,
                    leading: Icon(sectionIcon(s)),
                    title: Text(sectionTitle(s)),
                    subtitle: Row(children: [
                      Icon(statusIcon(st), size: 16),
                      const SizedBox(width: 4),
                      Text(statusLabel(st)),
                    ]),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/plan/wizard?s=${s.name}'),
                  );
                }),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.push('/plan/gesprek'),
                icon: const Icon(Icons.forum_outlined),
                label: const Text(S.planTalk),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: plan.hasContent ? () => context.push('/plan/delen') : null,
                icon: const Icon(Icons.ios_share),
                label: const Text(S.planShare),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: plan.hasContent
                    ? () async {
                        await ref.read(planRepositoryProvider).confirmAll();
                      }
                    : null,
                icon: const Icon(Icons.verified_outlined),
                label: const Text(S.planConfirm),
              ),
              TextButton.icon(
                onPressed: () => startPlanImport(context, ref),
                icon: const Icon(Icons.file_open_outlined),
                label: const Text(S.planImport),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(S.planReminder),
                subtitle: const Text(S.planReminderSub),
                value: settings.planReminder,
                onChanged: (v) => togglePlanReminder(context, ref, v),
              ),
              const Divider(),
              if (plan.updatedAt != null) Text(S.planUpdated(fmtDate(plan.updatedAt!))),
              if (plan.lastConfirmedAt != null) Text(S.planConfirmed(fmtDate(plan.lastConfirmedAt!))),
              if (plan.lastSharedAt != null) Text(S.planLastShared(fmtDate(plan.lastSharedAt!))),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.lock_outline, size: 18, color: t.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(child: Text(S.planPrivacy)),
              ]),
            ],
          );
        },
      ),
    );
  }
}
