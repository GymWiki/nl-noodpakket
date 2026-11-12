import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme.dart';
import '../../../core/ui.dart';
import '../data/rampenzender_models.dart';
import '../rampenzender_providers.dart';
import '../rampenzender_strings.dart';

/// Gemeente zoeken (offline) en opslaan als standaardregio. Geen locatie nodig.
class RegionPickerScreen extends ConsumerStatefulWidget {
  const RegionPickerScreen({super.key});

  @override
  ConsumerState<RegionPickerScreen> createState() => _RegionPickerScreenState();
}

class _RegionPickerScreenState extends ConsumerState<RegionPickerScreen> {
  String _q = '';

  Future<void> _pick(RadioRegion r) async {
    await ref.read(radioActionsProvider).chooseRegion(r.gm);
    if (!mounted) return;
    // Terug naar het resultaat (of er naartoe als we vanuit Instellingen kwamen).
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/rampenzender');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final data = ref.watch(radioDataProvider);
    final prefs = ref.watch(radioPrefsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(RZ.pickTitle)),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text(S.wikiLoadError)),
        data: (d) {
          final results = d.search(_q);
          final broadcasters = {for (final b in d.broadcasters) b.id: b};
          return ListView(padding: Gap.page, children: [
            TextField(
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(hintText: RZ.pickHint, prefixIcon: Icon(Icons.search_rounded)),
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: Gap.s),
            Text(RZ.pickNoLocation, style: t.textTheme.bodyMedium),
            const SizedBox(height: Gap.m),
            if (_q.trim().isEmpty)
              Text(RZ.pickStart, style: t.textTheme.bodyLarge)
            else if (results.isEmpty)
              Text(RZ.pickNone, style: t.textTheme.bodyLarge)
            else
              SoftCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  for (var i = 0; i < results.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      minVerticalPadding: 12,
                      title: Text(results[i].name),
                      subtitle: Text(
                          '${broadcasters[results[i].broadcasterId]?.name ?? ''}, ${results[i].province}'),
                      selected: prefs.gm == results[i].gm,
                      trailing: prefs.gm == results[i].gm ? const Icon(Icons.check_rounded) : null,
                      onTap: () => _pick(results[i]),
                    ),
                  ],
                ]),
              ),
            if (prefs.gm != null) ...[
              const SizedBox(height: Gap.m),
              TextButton.icon(
                onPressed: () async {
                  await ref.read(radioActionsProvider).clearRegion();
                  if (context.mounted && context.canPop()) context.pop();
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text(RZ.remove),
              ),
            ],
          ]);
        },
      ),
    );
  }
}
