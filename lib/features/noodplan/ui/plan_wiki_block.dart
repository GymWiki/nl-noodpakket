import 'package:flutter/material.dart';
import '../../deel/deel_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/category_palette.dart';
import '../../../core/ui.dart';
import '../domain/plan_links.dart';

/// "Jouw afspraken": het deel van het noodplan dat bij dit noodgeval hoort.
class PlanWikiBlock extends ConsumerWidget {
  const PlanWikiBlock({super.key, required this.emergencyId});
  final String emergencyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refs = planLinks[emergencyId];
    if (refs == null || refs.isEmpty) return const SizedBox.shrink();
    final eff = ref.watch(effectivePlanProvider);
    final plan = eff.plan;
    final t = Theme.of(context);
    final empties = [for (final r in refs) if (r.valueIn(plan).isEmpty) r];

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: SoftCard(
        // Alleen het bolletje is gekleurd (tint van het noodplan); het vlak blijft neutraal.
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              IconBadge(Icons.assignment_outlined, size: 36, tint: menuTint(MenuItemKind.plan)),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(S.planWikiBlock, style: t.textTheme.titleLarge),
                ),
              ),
            ]),
            if (eff.isShared)
              Text(S.sharedFrom(eff.fromName!), style: t.textTheme.labelLarge),
            const SizedBox(height: 8),
            for (final r in refs)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.label, style: t.textTheme.labelLarge),
                  Text(
                    r.valueIn(plan).isEmpty ? S.planWikiEmpty : r.valueIn(plan),
                    style: t.textTheme.bodyLarge?.copyWith(
                      fontStyle: r.valueIn(plan).isEmpty ? FontStyle.italic : null,
                    ),
                  ),
                ]),
              ),
            if (!eff.isShared)
              FilledButton.tonal(
                onPressed: () {
                  final target = (empties.isNotEmpty ? empties.first : refs.first).section;
                  context.push('/plan/wizard?s=${target.name}');
                },
                child: Text(empties.isNotEmpty ? S.planWikiFill : S.planWikiEdit),
              ),
          ]),
        ),
      ),
    );
  }
}
