import 'package:flutter/material.dart';
import '../deel/deel_providers.dart';
import '../../core/theme/category_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/calm.dart';
import '../../core/dialer.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../noodhacks/hacks_links.dart';
import '../rampenzender/data/radio_lines.dart';
import '../rampenzender/rampenzender_providers.dart';
import '../rampenzender/ui/rampenzender_widgets.dart';
import 'wiki_icons.dart';
import 'wiki_models.dart';
import 'wiki_pdf.dart';
import 'wiki_providers.dart';

/// Tabblad "Noodgevallen": wat te doen, snel te vinden, ook onder stress.
class WikiOverviewScreen extends ConsumerStatefulWidget {
  const WikiOverviewScreen({super.key});

  @override
  ConsumerState<WikiOverviewScreen> createState() => _WikiOverviewScreenState();
}

class _WikiOverviewScreenState extends ConsumerState<WikiOverviewScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final wiki = ref.watch(wikiProvider);
    return Scaffold(
      body: SafeArea(
        child: wiki.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text(S.wikiLoadError),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: () => ref.invalidate(wikiProvider), child: const Text(S.retry)),
            ]),
          ),
          data: (d) => _body(context, d),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WikiData d) {
    final t = Theme.of(context);
    final favs = ref.watch(wikiFavoritesProvider).value ?? const <String>{};
    final searching = _query.trim().isNotEmpty;
    final results = searchEmergencies(d.emergencies, _query);

    return ListView(
      padding: Gap.page,
      children: [
        const PageTitle(S.wikiTitle, subtitle: S.wikiRule),
        Semantics(
          button: true,
          label: '${S.wikiCall112}. ${S.wikiCall112Hint}',
          excludeSemantics: true,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
            onPressed: () => openDialer(context, '112'),
            icon: const Icon(Icons.call_rounded, size: 26),
            label: const Text(S.wikiCall112, style: TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(height: Space.group),
        TextField(
          decoration: const InputDecoration(
            hintText: S.wikiSearchHint,
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: Space.group),
        if (!searching) _FirstHourCard(first: d.eersteUur),
        if (searching) ...[
          if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.all(Gap.l),
              child: Text(S.wikiNoResults, textAlign: TextAlign.center),
            ),
          if (results.isNotEmpty)
            CalmListGroup(children: [
              for (final r in results) _EmergencyTile(e: r, fav: favs.contains(r.id), favs: favs),
            ]),
        ] else ...[
          if (favs.isNotEmpty)
            CalmSection(
              title: S.wikiFavorites,
              child: CalmListGroup(children: [
                for (final e in d.emergencies.where((e) => favs.contains(e.id)))
                  _EmergencyTile(e: e, fav: true, favs: favs),
              ]),
            ),
          // Eén lijst met alle categorieën; uitklappen toont de situaties.
          CalmSection(
            child: CalmListGroup(children: [
              for (final c in d.categories)
                _CategoryRow(
                  category: c,
                  items: d.emergencies.where((e) => e.categorie == c.id).toList(),
                  favs: favs,
                ),
            ]),
          ),
          // Rustige ingangen onderaan: geen gelijke kaarten tussen de categorieën.
          CalmSection(
            title: S.wikiMoreHelp,
            child: CalmListGroup(children: [
              const HacksEntryCards(),
              const RadioEntryCard(),
              StatusRow(
                icon: Icons.picture_as_pdf_outlined,
                tint: menuTint(MenuItemKind.meterkast),
                title: S.wikiPdfCard,
                subtitle: S.wikiPdfCardSub,
                onTap: () => shareMeterkastCard(context, d,
                    plan: ref.read(effectivePlanProvider).plan,
                    radioLines: radioDocLines(ref.read(radioResultProvider), areaId: ref.read(radioPrefsProvider).area)),
              ),
            ]),
          ),
        ],
        const SizedBox(height: Space.section),
        Text(S.disclaimer, style: t.textTheme.bodySmall),
      ],
    );
  }
}

class _FirstHourCard extends StatelessWidget {
  const _FirstHourCard({required this.first});
  final WikiEmergency first;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context);
    return SoftCard(
      color: c.tertiaryContainer,
      borderColor: Colors.transparent,
      onTap: () => context.push('/wiki/${first.id}'),
      child: Row(children: [
        IconBadge(Icons.schedule_rounded, background: c.surface.withValues(alpha: 0.6), foreground: c.onTertiaryContainer),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(first.titel, style: t.textTheme.titleMedium?.copyWith(color: c.onTertiaryContainer)),
            const SizedBox(height: 2),
            Text(first.intro, style: t.textTheme.bodyMedium?.copyWith(color: c.onTertiaryContainer)),
          ]),
        ),
        Icon(Icons.chevron_right_rounded, color: c.onTertiaryContainer),
      ]),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.items, required this.favs});
  final WikiCategory category;
  final List<WikiEmergency> items;
  final Set<String> favs;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Theme(
      data: t.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: IconBadge(wikiIcon(category.icoon), size: 40, tint: wikiTint(category.id)),
        title: Text(category.titel, style: t.textTheme.titleSmall?.copyWith(fontSize: 16)),
        childrenPadding: const EdgeInsets.only(bottom: Space.tight),
        children: [
          for (final e in items) _EmergencyTile(e: e, fav: favs.contains(e.id), favs: favs),
        ],
      ),
    );
  }
}

class _EmergencyTile extends ConsumerWidget {
  const _EmergencyTile({required this.e, required this.fav, required this.favs});
  final WikiEmergency e;
  final bool fav;
  final Set<String> favs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      minVerticalPadding: 12,
      leading: IconBadge(wikiIcon(e.icoon), size: 36, tint: wikiTint(e.categorie)),
      title: Text(e.titel),
      trailing: IconButton(
        tooltip: fav ? S.wikiRemoveFavorite : S.wikiAddFavorite,
        iconSize: 28,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        icon: Icon(fav ? Icons.star_rounded : Icons.star_border_rounded),
        onPressed: () => ref.read(wikiPrefsProvider).toggleFavorite(e.id, favs),
      ),
      onTap: () => context.push('/wiki/${e.id}'),
    );
  }
}
