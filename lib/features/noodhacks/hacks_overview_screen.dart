import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/calm.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/category_palette.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import 'hacks_models.dart';
import 'hacks_providers.dart';
import 'hacks_widgets.dart';

/// Noodhacks: praktische tips voor als het noodpakket op of ontoereikend is.
class HacksOverviewScreen extends ConsumerStatefulWidget {
  const HacksOverviewScreen({super.key});

  @override
  ConsumerState<HacksOverviewScreen> createState() => _HacksOverviewScreenState();
}

class _HacksOverviewScreenState extends ConsumerState<HacksOverviewScreen> {
  String _query = '';
  HackLabel? _label;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(hacksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(S.hacksTitle)),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(S.hacksLoadError),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => ref.invalidate(hacksProvider), child: const Text(S.retry)),
          ]),
        ),
        data: (d) => _body(context, d),
      ),
    );
  }

  Widget _body(BuildContext context, HackData d) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final favs = ref.watch(hacksFavoritesProvider).value ?? const <String>{};
    final filtering = _query.trim().isNotEmpty || _label != null;
    final results = searchHacks(d.hacks, query: _query, label: _label);

    Widget action(IconData icon, String title, String sub, String route, MenuItemKind kind) => StatusRow(
          icon: icon,
          tint: menuTint(kind),
          title: title,
          subtitle: sub,
          onTap: () => context.push(route),
        );

    Widget tile(Hack h) => HackTile(
          hack: h,
          trailing: IconButton(
            tooltip: favs.contains(h.id) ? S.hacksRemoveFav : S.hacksAddFav,
            icon: Icon(favs.contains(h.id) ? Icons.star_rounded : Icons.star_border_rounded),
            onPressed: () => ref.read(hacksPrefsProvider).toggleFavorite(h.id, favs),
          ),
        );

    Widget list(List<Hack> hs) => CalmListGroup(children: [for (final h in hs) tile(h)]);

    return ListView(
      padding: Gap.page,
      children: [
        // De waarschuwing blijft staan, maar als rustige regel in plaats van een gekleurde kaart.
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline_rounded, size: 20, color: c.onSurfaceVariant),
          const SizedBox(width: Space.tight),
          Expanded(child: Text(S.hacksDisclaimer, style: t.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant))),
        ]),
        const SizedBox(height: Space.group),
        CalmListGroup(children: [
          action(Icons.inventory_2_outlined, S.hacksIntroOut, S.hacksIntroOutSub, '/hacks/pakket-op', MenuItemKind.packetOut),
          action(Icons.checklist_rounded, S.hacksHave, S.hacksHaveSub, '/hacks/in-huis', MenuItemKind.hacksHave),
        ]),
        const SizedBox(height: Space.group),
        TextField(
          decoration: const InputDecoration(hintText: S.hacksSearchHint, prefixIcon: Icon(Icons.search_rounded)),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: Gap.s),
        // Eén filterrij die zijwaarts scrolt (geen tweede rij).
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            ChoiceChip(
              label: const Text(S.hacksFilterAll),
              selected: _label == null,
              onSelected: (_) => setState(() => _label = null),
            ),
            for (final l in HackLabel.values) ...[
              const SizedBox(width: Space.tight),
              ChoiceChip(
                avatar: Icon(hackLabelIcon(l), size: 18),
                label: Text(hackLabelText(l)),
                selected: _label == l,
                onSelected: (_) => setState(() => _label = _label == l ? null : l),
              ),
            ],
          ]),
        ),
        if (filtering) ...[
          const SizedBox(height: Gap.m),
          if (results.isEmpty)
            const Padding(padding: EdgeInsets.all(Gap.l), child: Text(S.hacksNoResults, textAlign: TextAlign.center))
          else
            list(results),
        ] else ...[
          if (favs.isNotEmpty) ...[
            const SectionHeader(S.hacksFavorites),
            list([for (final h in d.hacks) if (favs.contains(h.id)) h]),
          ],
          for (final cat in d.categories) ...[
            CalmSection(title: cat.titel, child: list([for (final h in d.hacks) if (h.categorie == cat.id) h])),
          ],
        ],
      ],
    );
  }
}
