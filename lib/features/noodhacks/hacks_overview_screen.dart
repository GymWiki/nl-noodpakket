import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/strings.dart';
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

    Widget action(IconData icon, String title, String sub, String route, {Color? bg, Color? fg}) => SoftCard(
          onTap: () => context.push(route),
          color: bg,
          borderColor: bg == null ? null : Colors.transparent,
          child: Row(children: [
            IconBadge(icon, background: bg == null ? null : c.surface.withValues(alpha: 0.6), foreground: fg),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: t.textTheme.titleMedium?.copyWith(color: fg)),
                const SizedBox(height: 2),
                Text(sub, style: t.textTheme.bodyMedium?.copyWith(color: fg ?? c.onSurfaceVariant)),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: fg ?? c.onSurfaceVariant),
          ]),
        );

    Widget tile(Hack h) => HackTile(
          hack: h,
          trailing: IconButton(
            tooltip: favs.contains(h.id) ? S.hacksRemoveFav : S.hacksAddFav,
            icon: Icon(favs.contains(h.id) ? Icons.star_rounded : Icons.star_border_rounded),
            onPressed: () => ref.read(hacksPrefsProvider).toggleFavorite(h.id, favs),
          ),
        );

    Widget list(List<Hack> hs) => SoftCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (var i = 0; i < hs.length; i++) ...[
              if (i > 0) const Divider(indent: 16, endIndent: 16),
              tile(hs[i]),
            ],
          ]),
        );

    return ListView(
      padding: Gap.page,
      children: [
        SoftCard(
          color: c.tertiaryContainer,
          borderColor: Colors.transparent,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline_rounded, color: c.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(S.hacksDisclaimer,
                  style: t.textTheme.bodyMedium?.copyWith(color: c.onTertiaryContainer)),
            ),
          ]),
        ),
        const SizedBox(height: Gap.m),
        action(Icons.inventory_2_outlined, S.hacksIntroOut, S.hacksIntroOutSub, '/hacks/pakket-op'),
        const SizedBox(height: 12),
        action(Icons.checklist_rounded, S.hacksHave, S.hacksHaveSub, '/hacks/in-huis'),
        const SizedBox(height: Gap.m),
        TextField(
          decoration: const InputDecoration(hintText: S.hacksSearchHint, prefixIcon: Icon(Icons.search_rounded)),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: Gap.s),
        Wrap(spacing: 8, children: [
          ChoiceChip(
            label: const Text(S.hacksFilterAll),
            selected: _label == null,
            onSelected: (_) => setState(() => _label = null),
          ),
          for (final l in HackLabel.values)
            ChoiceChip(
              avatar: Icon(hackLabelIcon(l), size: 18),
              label: Text(hackLabelText(l)),
              selected: _label == l,
              onSelected: (_) => setState(() => _label = _label == l ? null : l),
            ),
        ]),
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
            SectionHeader(cat.titel, leading: HackCategoryBadge(cat.id, size: 32)),
            list([for (final h in d.hacks) if (h.categorie == cat.id) h]),
          ],
        ],
        const SizedBox(height: Gap.l),
        Text(S.disclaimer, style: t.textTheme.bodySmall),
      ],
    );
  }
}
