import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../rampenzender/ui/rampenzender_widgets.dart';
import 'hacks_providers.dart';
import 'hacks_widgets.dart';

class _Step {
  const _Step(this.title, this.icon, this.hackIds);
  final String title;
  final IconData icon;
  final List<String> hackIds;
}

const _steps = [
  _Step(S.hacksOut1, Icons.water_drop_outlined,
      ['water-vinden', 'water-koken', 'voorfilteren', 'water-ontsmetten-bleek', 'water-chemisch']),
  _Step(S.hacksOut2, Icons.local_fire_department_outlined, ['warm-kamer']),
  _Step(S.hacksOut3, Icons.clean_hands_outlined, ['handen-schoon']),
  _Step(S.hacksOut4, Icons.restaurant_outlined,
      ['eten-zonder-koken', 'buiten-koken', 'koelkast-stroomuitval', 'vriezer-ontdooid']),
];

/// "Mijn pakket is op": de volgorde van wat je doet, met links naar de hacks.
class HacksOutScreen extends ConsumerWidget {
  const HacksOutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final data = ref.watch(hacksProvider);

    Widget number(int n) => ExcludeSemantics(
          child: CircleAvatar(
            radius: 16,
            backgroundColor: c.primary,
            foregroundColor: c.onPrimary,
            child: Text('$n', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text(S.hacksOutTitle)),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text(S.hacksLoadError)),
        data: (d) => ListView(
          padding: Gap.page,
          children: [
            Text(S.hacksOutIntro, style: t.textTheme.bodyLarge),
            const SizedBox(height: Gap.m),
            const RadioTuneLine(),
            const SizedBox(height: Gap.m),
            for (var i = 0; i < _steps.length; i++) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SoftCard(
                  padding: EdgeInsets.zero,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(children: [
                        number(i + 1),
                        const SizedBox(width: 12),
                        Icon(_steps[i].icon, color: c.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Semantics(header: true, child: Text(_steps[i].title, style: t.textTheme.titleMedium))),
                      ]),
                    ),
                    for (final id in _steps[i].hackIds)
                      if (d.byId(id) != null) ...[
                        const Divider(indent: 16, endIndent: 16),
                        HackTile(hack: d.byId(id)!),
                      ],
                  ]),
                ),
              ),
            ],
            SoftCard(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  number(5),
                  const SizedBox(width: 12),
                  Icon(Icons.diversity_3_outlined, color: c.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Semantics(header: true, child: Text(S.hacksOut5, style: t.textTheme.titleMedium))),
                ]),
                const SizedBox(height: 12),
                for (final s in S.hacksOutHelp)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3, right: 10),
                        child: Icon(Icons.check_circle_outline_rounded, size: 20, color: c.secondary),
                      ),
                      Expanded(child: Text(s, style: t.textTheme.bodyLarge)),
                    ]),
                  ),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: () => context.push('/wiki/eerste-uur'),
                  icon: const Icon(Icons.schedule_rounded),
                  label: const Text(S.hacksOutFirstHour),
                ),
              ]),
            ),
            const SizedBox(height: Gap.l),
            Text(S.hacksDisclaimer, style: t.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
