import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/strings.dart';
import '../../core/ui.dart';
import 'hacks_models.dart';
import 'hacks_providers.dart';
import 'hacks_widgets.dart';

/// Kaarten op het tabblad Noodgevallen: "Mijn pakket is op" en "Noodhacks".
class HacksEntryCards extends StatelessWidget {
  const HacksEntryCards({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    return Column(children: [
      SoftCard(
        color: c.primaryContainer,
        borderColor: Colors.transparent,
        onTap: () => context.push('/hacks/pakket-op'),
        child: Row(children: [
          IconBadge(Icons.inventory_2_outlined, background: c.surface.withValues(alpha: 0.6), foreground: c.onPrimaryContainer),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(S.hacksIntroOut, style: t.textTheme.titleMedium?.copyWith(color: c.onPrimaryContainer)),
              const SizedBox(height: 2),
              Text(S.hacksIntroOutSub, style: t.textTheme.bodyMedium?.copyWith(color: c.onPrimaryContainer)),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: c.onPrimaryContainer),
        ]),
      ),
      const SizedBox(height: 12),
      SoftCard(
        onTap: () => context.push('/hacks'),
        child: Row(children: [
          const IconBadge(Icons.tips_and_updates_outlined),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(S.hacksTitle, style: t.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(S.hacksEntrySub, style: t.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: c.onSurfaceVariant),
        ]),
      ),
    ]);
  }
}

/// "Als je pakket op is": passende noodhacks bij een noodgeval in de wiki.
class HacksForEmergency extends ConsumerWidget {
  const HacksForEmergency({super.key, required this.emergencyId});
  final String emergencyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(hacksProvider).value?.forEmergency(emergencyId) ?? const <Hack>[];
    // Mythes pas na de veilige alternatieven.
    final sorted = [...list]..sort((a, b) => (a.label == HackLabel.nooit ? 1 : 0).compareTo(b.label == HackLabel.nooit ? 1 : 0));
    if (sorted.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(S.hacksRelatedBlock, padding: EdgeInsets.only(bottom: 8)),
        SoftCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (var i = 0; i < sorted.length; i++) ...[
              if (i > 0) const Divider(indent: 16, endIndent: 16),
              HackTile(hack: sorted[i]),
            ],
          ]),
        ),
        TextButton(onPressed: () => context.push('/hacks'), child: const Text(S.hacksAllHacks)),
      ]),
    );
  }
}

/// "Handige hacks" bij een checklist-item.
class HacksForItem extends ConsumerWidget {
  const HacksForItem({super.key, required this.itemId});
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(hacksProvider).value?.forItem(itemId) ?? const <Hack>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${S.hacksHandy}:', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final h in list)
            ActionChip(
              avatar: Icon(hackLabelIcon(h.label), size: 18),
              label: Text(h.titel),
              onPressed: () => openHack(context, ref, h),
            ),
        ]),
      ]),
    );
  }
}
