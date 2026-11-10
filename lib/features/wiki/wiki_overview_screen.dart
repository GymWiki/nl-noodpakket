import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dialer.dart';
import '../../core/l10n/strings.dart';
import '../kluis/ui/vault_link.dart';
import '../noodplan/plan_providers.dart';
import '../noodplan/ui/plan_overview_screen.dart';
import 'wiki_icons.dart';
import 'wiki_models.dart';
import 'wiki_pdf.dart';
import 'wiki_providers.dart';

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
      appBar: AppBar(title: const Text(S.wikiTitle)),
      body: wiki.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(S.wikiLoadError),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: () => ref.invalidate(wikiProvider),
                child: const Text(S.retry)),
          ]),
        ),
        data: (d) => _body(context, d),
      ),
    );
  }

  Widget _body(BuildContext context, WikiData d) {
    final t = Theme.of(context);
    final favs = ref.watch(wikiFavoritesProvider).value ?? const <String>{};
    final searching = _query.trim().isNotEmpty;
    final results = searchEmergencies(d.emergencies, _query);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(S.wikiRule, style: t.textTheme.bodyLarge),
        const SizedBox(height: 4),
        Text(S.disclaimer,
            style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        Semantics(
          button: true,
          label: '${S.wikiCall112}. ${S.wikiCall112Hint}',
          excludeSemantics: true,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              backgroundColor: t.colorScheme.primary,
            ),
            onPressed: () => openDialer(context, '112'),
            icon: const Icon(Icons.call),
            label: const Text(S.wikiCall112, style: TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            hintText: S.wikiSearchHint,
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 16),
        if (!searching) ...[
          const PlanEntryCard(),
          const VaultEntryCard(),
          const SizedBox(height: 4),
          _FirstHourCard(first: d.eersteUur),
        ],
        if (searching) ...[
          if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(S.wikiNoResults, textAlign: TextAlign.center),
            ),
          for (final e in results) _EmergencyTile(e: e, fav: favs.contains(e.id), favs: favs),
        ] else ...[
          if (favs.isNotEmpty) ...[
            _SectionTitle(S.wikiFavorites),
            for (final e in d.emergencies.where((e) => favs.contains(e.id)))
              _EmergencyTile(e: e, fav: true, favs: favs),
          ],
          for (final c in d.categories) ...[
            _CategoryCard(
              category: c,
              items: d.emergencies.where((e) => e.categorie == c.id).toList(),
              favs: favs,
            ),
          ],
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text(S.wikiPdfCard),
            subtitle: const Text(S.wikiPdfCardSub),
            onTap: () => shareMeterkastCard(context, d, plan: ref.read(planProvider).value),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Semantics(
            header: true,
            child: Text(text, style: Theme.of(context).textTheme.titleLarge)),
      );
}

class _FirstHourCard extends StatelessWidget {
  const _FirstHourCard({required this.first});
  final WikiEmergency first;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      color: t.colorScheme.tertiaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/wiki/${first.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Icon(Icons.schedule, size: 36, color: t.colorScheme.onTertiaryContainer),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(first.titel,
                      style: t.textTheme.titleLarge
                          ?.copyWith(color: t.colorScheme.onTertiaryContainer)),
                  const SizedBox(height: 4),
                  Text(first.intro,
                      style: TextStyle(color: t.colorScheme.onTertiaryContainer)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: t.colorScheme.onTertiaryContainer),
          ]),
        ),
      ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: t.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Icon(wikiIcon(category.icoon), color: t.colorScheme.primary),
            title: Text(category.titel, style: t.textTheme.titleMedium),
            subtitle: Text('${items.length}'),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            children: [
              for (final e in items) _EmergencyTile(e: e, fav: favs.contains(e.id), favs: favs),
            ],
          ),
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
      leading: Icon(wikiIcon(e.icoon)),
      title: Text(e.titel),
      trailing: IconButton(
        tooltip: fav ? S.wikiRemoveFavorite : S.wikiAddFavorite,
        iconSize: 28,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        icon: Icon(fav ? Icons.star : Icons.star_border),
        onPressed: () => ref.read(wikiPrefsProvider).toggleFavorite(e.id, favs),
      ),
      onTap: () => context.push('/wiki/${e.id}'),
    );
  }
}
