import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../domain/plan_models.dart';
import '../domain/plan_progress.dart';
import '../domain/plan_share.dart';
import '../plan_providers.dart';
import 'plan_steps.dart';
import 'plan_widgets.dart';

/// Begeleide flow: één onderwerp per scherm, alles wordt direct opgeslagen.
class PlanWizardScreen extends ConsumerStatefulWidget {
  const PlanWizardScreen({super.key, this.section});
  /// Start bij dit onderdeel; zonder: ga verder waar je gebleven was.
  final PlanSection? section;

  @override
  ConsumerState<PlanWizardScreen> createState() => _PlanWizardScreenState();
}

class _PlanWizardScreenState extends ConsumerState<PlanWizardScreen> {
  static const _sections = PlanSection.values;
  int? _index; // 0..6 = onderdelen, 7 = samenvatting

  void _go(int i) {
    setState(() => _index = i);
    ref.read(planRepositoryProvider).setWizardStep(i);
  }

  Widget _stepFor(PlanSection s, Plan p) => switch (s) {
        PlanSection.household => HouseholdStep(key: const ValueKey('s1'), plan: p),
        PlanSection.contacts => ContactsStep(key: const ValueKey('s2'), plan: p),
        PlanSection.places => PlacesStep(key: const ValueKey('s3'), plan: p),
        PlanSection.agreements => AgreementsStep(key: const ValueKey('s4'), plan: p),
        PlanSection.home => HomeStep(key: const ValueKey('s5'), plan: p),
        PlanSection.care => CareStep(key: const ValueKey('s6'), plan: p),
        PlanSection.neighbours => NeighboursStep(key: const ValueKey('s7'), plan: p),
      };

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(planProvider);
    return async.when(
      loading: () => Scaffold(
          appBar: AppBar(title: const Text(S.planWizardTitle)),
          body: const Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
          appBar: AppBar(title: const Text(S.planWizardTitle)),
          body: const Center(child: Text(S.planLoadError))),
      data: (plan) {
        _index ??= widget.section != null
            ? _sections.indexOf(widget.section!)
            : plan.wizardStep.clamp(0, _sections.length);
        return _build(context, plan);
      },
    );
  }

  Widget _build(BuildContext context, Plan plan) {
    final i = _index!;
    final isSummary = i >= _sections.length;
    final t = Theme.of(context);
    final total = _sections.length + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSummary ? S.planSummaryTitle : sectionTitle(_sections[i])),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text(S.planLater),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Semantics(
              label: S.planStepOf(i + 1, total),
              value: '${((i + 1) * 100 / total).round()}%',
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                LinearProgressIndicator(
                  value: (i + 1) / total,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text(S.planStepOf(i + 1, total),
                    style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
              ]),
            ),
          ),
          Expanded(
            child: ListView(
              key: ValueKey('page$i'),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                if (isSummary) _Summary(plan: plan) else _stepFor(_sections[i], plan),
                const SizedBox(height: 8),
                Text(S.planAutoSaved,
                    style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(children: [
              if (i > 0)
                OutlinedButton(onPressed: () => _go(i - 1), child: const Text(S.planPrev)),
              const Spacer(),
              if (!isSummary) ...[
                TextButton(
                  onPressed: () async {
                    final s = _sections[i];
                    // Overslaan is alleen zinvol als er nog niets is ingevuld.
                    if (sectionStatus(plan, s) == SectionStatus.empty) {
                      await ref
                          .read(planRepositoryProvider)
                          .setSkipped(s, true, plan.skipped);
                    }
                    _go(i + 1);
                  },
                  child: const Text(S.planSkip),
                ),
                const SizedBox(width: 8),
              ],
              FilledButton(
                onPressed: isSummary ? () => context.pop() : () => _go(i + 1),
                child: Text(isSummary
                    ? S.planFinishDone
                    : (i == _sections.length - 1 ? S.planFinish : S.planNextStep)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.plan});
  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final progress = planProgress(plan);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.planSummaryIntro, style: t.textTheme.bodyLarge),
        const SizedBox(height: 16),
        if (!plan.hasContent) const Text(S.planSummaryEmpty),
        for (final s in PlanSection.values)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(statusIcon(progress.statuses[s]!)),
            title: Text(sectionTitle(s)),
            trailing: Text(statusLabel(progress.statuses[s]!)),
            onTap: null,
          ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(S.planSummaryTitle, style: t.textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        PlanDocumentPreview(plan: plan),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => context.push('/plan/delen'),
          icon: const Icon(Icons.ios_share),
          label: const Text(S.planShare),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Icon(Icons.lock_outline, size: 18, color: t.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(S.planStoredLocal)),
        ]),
      ],
    );
  }
}

/// Voorbeeldweergave van het document (zelfde inhoud als de tekstsamenvatting).
class PlanDocumentPreview extends StatelessWidget {
  const PlanDocumentPreview({super.key, required this.plan, this.options = const ShareOptions()});
  final Plan plan;
  final ShareOptions options;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          planSummaryText(plan, options, DateTime.now()),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
