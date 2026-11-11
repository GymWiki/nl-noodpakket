import 'package:flutter/material.dart';
import '../../core/theme/category_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dialer.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../noodhacks/hacks_links.dart';
import '../noodplan/plan_providers.dart';
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
        const SizedBox(height: Gap.m),
        TextField(
          decoration: const InputDecoration(
            hintText: S.wikiSearchHint,
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: Gap.m),
        if (!searching) ...[
          _FirstHourCard(first: d.eersteUur),
          const SizedBox(height: 12),
          const HacksEntryCards(),
        ],
        if (searching) ...[
          if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.all(Gap.l),
              child: Text(S.wikiNoResults, textAlign: TextAlign.center),
            ),
          if (results.isNotEmpty)
            SoftCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (var i = 0; i < results.length; i++) ...[
                  if (i > 0) const Divider(indent: 72, endIndent: 16),
                  _EmergencyTile(e: results[i], fav: favs.contains(results[i].id), favs: favs),
                ],
              ]),
            ),
        ] else ...[
          if (favs.isNotEmpty) ...[
            const SectionHeader(S.wikiFavorites),
            SoftCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (final e in d.emergencies.where((e) => favs.contains(e.id)))
                  _EmergencyTile(e: e, fav: true, favs: favs),
              ]),
            ),
          ],
          const SizedBox(height: Gap.s),
          for (final c in d.categories)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _CategoryCard(
                category: c,
                items: d.emergencies.where((e) => e.categorie == c.id).toList(),
                favs: favs,
              ),
            ),
          const SizedBox(height: Gap.m),
          SoftCard(
            onTap: () => shareMeterkastCard(context, d, plan: ref.read(planProvider).value),
            child: Row(children: [
              const IconBadge(Icons.picture_as_pdf_outlined, tint: CategoryTint.blue),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(S.wikiPdfCard, style: t.textTheme.titleSmall?.copyWith(fontSize: 16)),
                  Text(S.wikiPdfCardSub,
                      style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                ]),
              ),
            ]),
          ),
        ],
        const SizedBox(height: Gap.l),
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.items, required this.favs});
  final WikiCategory category;
  final List<WikiEmergency> items;
  final Set<String> favs;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: t.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: IconBadge(wikiIcon(category.icoon), size: 40, tint: wikiTint(category.id)),
          title: Text(category.titel, style: t.textTheme.titleMedium),
          subtitle: Text(S.wikiSituations(items.length)),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children: [
            for (final e in items) _EmergencyTile(e: e, fav: favs.contains(e.id), favs: favs),
          ],
        ),
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
