import 'package:flutter/material.dart';
import '../../core/theme/category_palette.dart';
import '../../core/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dialer.dart';
import '../../core/format.dart';
import '../../core/l10n/strings.dart';
import '../../core/providers.dart';
import '../../domain/models.dart';
import '../kluis/ui/vault_link.dart';
import '../noodhacks/hacks_links.dart';
import '../noodplan/ui/plan_wiki_block.dart';
import 'wiki_models.dart';
import 'wiki_providers.dart';

class WikiDetailScreen extends ConsumerWidget {
  const WikiDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wiki = ref.watch(wikiProvider);
    return wiki.when(
      loading: () => Scaffold(
          appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
          appBar: AppBar(), body: const Center(child: Text(S.wikiLoadError))),
      data: (d) {
        final e = d.byId(id);
        if (e == null) {
          return Scaffold(
              appBar: AppBar(), body: const Center(child: Text(S.wikiNotFound)));
        }
        return _Detail(e: e, isFirstHour: e.id == d.eersteUur.id);
      },
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.e, required this.isFirstHour});
  final WikiEmergency e;
  final bool isFirstHour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final favs = ref.watch(wikiFavoritesProvider).value ?? const <String>{};
    final fav = favs.contains(e.id);
    final items = ref.watch(allItemsProvider).value ?? const <Item>[];
    final byId = {for (final i in items) i.id: i};
    final prepare = [for (final id in e.voorbereidenItemIds) ?byId[id]];

    Widget title(String text) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Semantics(
              header: true, child: Text(text, style: t.textTheme.titleLarge)),
        );

    Widget numbered(List<String> steps) => Column(
          children: [
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: t.colorScheme.primaryContainer,
                        foregroundColor: t.colorScheme.onPrimaryContainer,
                        child: Text('${i + 1}', style: const TextStyle(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Semantics(
                        label: 'Stap ${i + 1}: ${steps[i]}',
                        excludeSemantics: true,
                        child: Text(steps[i], style: t.textTheme.bodyLarge),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(e.titel),
        actions: [
          if (!isFirstHour)
            IconButton(
              tooltip: fav ? S.wikiRemoveFavorite : S.wikiAddFavorite,
              icon: Icon(fav ? Icons.star : Icons.star_border),
              onPressed: () =>
                  ref.read(wikiPrefsProvider).toggleFavorite(e.id, favs),
            ),
          IconButton(
            tooltip: S.wikiCall112,
            icon: const Icon(Icons.call),
            onPressed: () => openDialer(context, '112'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          TintAccentLine(wikiTint(e.categorie)),
          Text(e.intro, style: t.textTheme.bodyLarge),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push('/wiki/${e.id}/stappen'),
            icon: const Icon(Icons.play_arrow),
            label: const Text(S.wikiStartSteps),
          ),
          title(S.wikiNow),
          numbered(e.stappenNu),
          if (e.stappenDaarna.isNotEmpty) ...[
            title(S.wikiAfter),
            numbered(e.stappenDaarna),
          ],
          if (e.bel112Als.isNotEmpty) ...[
            title(S.wikiCall112If),
            for (final s in e.bel112Als)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, right: 8),
                      child: Icon(Icons.call_outlined, size: 20),
                    ),
                    Expanded(child: Text(s, style: t.textTheme.bodyLarge)),
                  ],
                ),
              ),
            OutlinedButton.icon(
              onPressed: () => openDialer(context, '112'),
              icon: const Icon(Icons.call),
              label: const Text(S.wikiCall112),
            ),
          ],
          if (e.contacten.isNotEmpty) ...[
            title(S.wikiNumbers),
            for (final c in e.contacten)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone_outlined),
                title: Text(c.label),
                subtitle: Text(c.nummer),
                onTap: () => openDialer(context, c.nummer),
              ),
          ],
          HacksForEmergency(emergencyId: e.id),
          PlanWikiBlock(emergencyId: e.id),
          if (const {'overstroming', 'natuurbrand', 'brand-in-huis', 'kernongeval'}.contains(e.id))
            const VaultLinkTile(title: S.vaultNoodmapOpen, padding: EdgeInsets.only(top: 16)),
          if (prepare.isNotEmpty) ...[
            title(S.wikiPrepare),
            for (final i in prepare)
              ListTile(
                contentPadding: EdgeInsets.zero,
                minVerticalPadding: 8,
                leading: Icon(
                  i.inHouse ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: i.inHouse ? t.colorScheme.primary : null,
                ),
                title: Text(i.name),
                subtitle: Text(
                    '${i.inHouse ? S.wikiPrepareHave : S.wikiPrepareNeed} · ${quantityText(i)}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/item/${i.id}'),
              ),
          ],
          title(S.wikiSources),
          for (final b in e.bronnen)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.open_in_new, size: 20),
              title: Text(b.naam),
              onTap: () => openExternal(context, b.url),
            ),
          const SizedBox(height: 8),
          Text(S.wikiReviewed(fmtDate(e.lastReviewed)),
              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(S.wikiRule,
              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
