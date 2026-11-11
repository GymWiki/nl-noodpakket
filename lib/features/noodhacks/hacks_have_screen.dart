import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import 'hacks_models.dart';
import 'hacks_providers.dart';
import 'hacks_widgets.dart';

/// "Wat heb ik in huis?": kies materialen en zie welke noodhacks kunnen.
class HacksHaveScreen extends ConsumerWidget {
  const HacksHaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(hacksProvider);
    final owned = ref.watch(hacksMaterialsProvider).value ?? const <String>{};
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(S.hacksHaveTitle)),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text(S.hacksLoadError)),
        data: (d) {
          final matches = matchHacks(d.hacks, owned);
          final possible = [for (final m in matches) if (m.possible) m];
          final almost = [for (final m in matches) if (!m.possible) m];
          final prefs = ref.read(hacksPrefsProvider);

          Widget group(List<HackMatch> list) => SoftCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  for (var i = 0; i < list.length; i++) ...[
                    if (i > 0) const Divider(indent: 16, endIndent: 16),
                    HackTile(
                      hack: list[i].hack,
                      subtitle: list[i].possible
                          ? null
                          : Text(
                              S.hacksMissing(list[i].missing.map((m) => d.material(m)?.label ?? m).join(', ')),
                              style: t.textTheme.bodyMedium,
                            ),
                    ),
                  ],
                ]),
              );

          return ListView(
            padding: Gap.page,
            children: [
              Text(S.hacksHaveIntro, style: t.textTheme.bodyLarge),
              const SizedBox(height: Gap.m),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final m in d.materials)
                  FilterChip(
                    avatar: Icon(hackMaterialIcon(m.icoon), size: 18),
                    label: Text(m.label),
                    selected: owned.contains(m.id),
                    onSelected: (on) {
                      final next = {...owned};
                      on ? next.add(m.id) : next.remove(m.id);
                      prefs.setMaterials(next);
                    },
                  ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(child: Text(S.hacksHaveSaved, style: t.textTheme.bodySmall)),
                if (owned.isNotEmpty)
                  TextButton(onPressed: () => prefs.setMaterials({}), child: const Text(S.hacksHaveClear)),
              ]),
              if (owned.isEmpty && possible.isEmpty) const Padding(padding: EdgeInsets.all(Gap.l), child: Text(S.hacksHaveNone)),
              if (possible.isNotEmpty) ...[const SectionHeader(S.hacksHavePossible), group(possible)],
              if (almost.isNotEmpty) ...[const SectionHeader(S.hacksHaveAlmost), group(almost)],
              const SizedBox(height: Gap.l),
              Text(S.hacksDisclaimer, style: t.textTheme.bodySmall),
            ],
          );
        },
      ),
    );
  }
}
