import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/calm.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/category_palette.dart';
import '../../core/ui.dart';
import 'hacks_models.dart';
import 'hacks_providers.dart';
import 'hacks_widgets.dart';

/// Twee rijen in "Extra hulp" op het tabblad Noodgevallen: "Mijn pakket is op" en "Noodhacks".
class HacksEntryCards extends StatelessWidget {
  const HacksEntryCards({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Column(children: [
      StatusRow(
        icon: Icons.inventory_2_outlined,
        tint: CategoryTint.blue,
        title: S.hacksIntroOut,
        subtitle: S.hacksIntroOutSub,
        onTap: () => context.push('/hacks/pakket-op'),
      ),
      Divider(height: 1, indent: Space.screen, endIndent: Space.screen, color: c.outlineVariant),
      StatusRow(
        icon: Icons.tips_and_updates_outlined,
        tint: CategoryTint.blue,
        title: S.hacksTitle,
        subtitle: S.hacksEntrySub,
        onTap: () => context.push('/hacks'),
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
