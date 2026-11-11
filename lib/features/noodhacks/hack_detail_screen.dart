import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/dialer.dart';
import '../../core/format.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import 'hacks_models.dart';
import 'hacks_providers.dart';
import 'hacks_widgets.dart';

class HackDetailScreen extends ConsumerWidget {
  const HackDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(hacksProvider);
    return data.when(
      loading: () => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(appBar: AppBar(), body: const Center(child: Text(S.hacksLoadError))),
      data: (d) {
        final h = d.byId(id);
        if (h == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text(S.hacksNotFound)));
        return _Detail(h: h, data: d);
      },
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.h, required this.data});
  final Hack h;
  final HackData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final owned = ref.watch(hacksMaterialsProvider).value ?? const <String>{};
    final favs = ref.watch(hacksFavoritesProvider).value ?? const <String>{};
    final never = h.label == HackLabel.nooit;

    Widget section(String title) => SectionHeader(title);

    return Scaffold(
      appBar: AppBar(
        title: Text(h.titel, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: favs.contains(h.id) ? S.hacksRemoveFav : S.hacksAddFav,
            icon: Icon(favs.contains(h.id) ? Icons.star_rounded : Icons.star_border_rounded),
            onPressed: () => ref.read(hacksPrefsProvider).toggleFavorite(h.id, favs),
          ),
          IconButton(tooltip: S.wikiCall112, icon: const Icon(Icons.call_rounded), onPressed: () => openDialer(context, '112')),
        ],
      ),
      body: ListView(
        padding: Gap.page,
        children: [
          Align(alignment: Alignment.centerLeft, child: HackLabelBadge(h.label)),
          const SizedBox(height: 12),
          Text(h.titel, style: t.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(h.intro, style: t.textTheme.bodyLarge),
          if (never) ...[
            const SizedBox(height: Gap.m),
            SoftCard(
              color: c.errorContainer,
              borderColor: Colors.transparent,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.block_rounded, color: c.onErrorContainer),
                  const SizedBox(width: 10),
                  Text(S.hacksWhyNot, style: t.textTheme.titleMedium?.copyWith(color: c.onErrorContainer)),
                ]),
                const SizedBox(height: 8),
                Text(h.reden, style: t.textTheme.bodyLarge?.copyWith(color: c.onErrorContainer)),
              ]),
            ),
          ],
          const SizedBox(height: Gap.m),
          if (!never)
            FilledButton.icon(
              onPressed: () => context.push('/hacks/${h.id}/stappen'),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(S.hacksStart),
            ),
          if (h.waarschuwingen.isNotEmpty && !never) ...[
            section(S.hacksWarnings),
            SoftCard(
              color: c.tertiaryContainer,
              borderColor: Colors.transparent,
              child: Column(children: [
                for (final w in h.waarschuwingen)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2, right: 10),
                        child: Icon(Icons.warning_amber_rounded, size: 20, color: c.onTertiaryContainer),
                      ),
                      Expanded(child: Text(w, style: t.textTheme.bodyLarge?.copyWith(color: c.onTertiaryContainer))),
                    ]),
                  ),
              ]),
            ),
          ],
          if (!never) ...[
            section(S.hacksNeed),
            if (h.materialen.isEmpty)
              const Text(S.hacksNoMaterial)
            else
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final m in h.materialen)
                  Chip(
                    avatar: Icon(
                      owned.contains(m) ? Icons.check_circle_rounded : hackMaterialIcon(data.material(m)?.icoon ?? ''),
                      size: 18,
                      color: owned.contains(m) ? c.secondary : null,
                    ),
                    label: Text(data.material(m)?.label ?? m),
                  ),
              ]),
          ],
          section(never ? S.hacksInstead : S.hacksSteps),
          for (var i = 0; i < h.stappen.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ExcludeSemantics(
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: c.primaryContainer,
                    foregroundColor: c.onPrimaryContainer,
                    child: Text('${i + 1}', style: const TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    label: 'Stap ${i + 1}: ${h.stappen[i]}',
                    excludeSemantics: true,
                    child: Text(h.stappen[i], style: t.textTheme.bodyLarge),
                  ),
                ),
              ]),
            ),
          if (h.waarschuwingen.isNotEmpty && never) ...[
            section(S.hacksWarnings),
            for (final w in h.waarschuwingen) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(w)),
          ],
          if (h.alternatiefIds.isNotEmpty) ...[
            section(never ? S.hacksInstead : S.hacksHandy),
            SoftCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (final a in h.alternatiefIds)
                  if (data.byId(a) != null) HackTile(hack: data.byId(a)!),
              ]),
            ),
          ],
          section(S.hacksSources),
          Text(h.bronType == 'officieel' ? S.hacksSourceOfficial : S.hacksSourceGeneral,
              style: t.textTheme.bodySmall),
          const SizedBox(height: 4),
          for (final b in h.bronnen)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.open_in_new_rounded, size: 20),
              title: Text(b.naam),
              onTap: () => openExternal(context, b.url),
            ),
          const SizedBox(height: 8),
          Text(S.hacksReviewed(fmtDate(h.lastReviewed)), style: t.textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(S.hacksDisclaimer, style: t.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Eén stap per scherm, in grote letters. Waarschuwingen komen eerst.
class HackStepsScreen extends ConsumerStatefulWidget {
  const HackStepsScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<HackStepsScreen> createState() => _HackStepsScreenState();
}

class _HackStepsScreenState extends ConsumerState<HackStepsScreen> {
  int _i = 0;
  bool _list = false;

  @override
  void initState() {
    super.initState();
    _wake(true);
  }

  @override
  void dispose() {
    _wake(false);
    super.dispose();
  }

  Future<void> _wake(bool on) async {
    try {
      await (on ? WakelockPlus.enable() : WakelockPlus.disable());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(hacksProvider);
    return data.when(
      loading: () => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(appBar: AppBar(), body: const Center(child: Text(S.hacksLoadError))),
      data: (d) {
        final h = d.byId(widget.id);
        if (h == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text(S.hacksNotFound)));
        return _build(context, h);
      },
    );
  }

  Widget _build(BuildContext context, Hack h) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final hasWarn = h.waarschuwingen.isNotEmpty;
    final pages = [if (hasWarn) null, ...h.stappen]; // null = waarschuwingen
    final n = pages.length;
    final i = _i.clamp(0, n - 1);
    final last = i == n - 1;

    Widget warnings() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.warning_amber_rounded, color: c.tertiary, size: 32),
            const SizedBox(width: 10),
            Text(S.hacksReadFirst, style: t.textTheme.headlineSmall),
          ]),
          const SizedBox(height: 16),
          for (final w in h.waarschuwingen)
            Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(w, style: t.textTheme.titleLarge?.copyWith(height: 1.35))),
        ]);

    return Scaffold(
      appBar: AppBar(
        title: Text(h.titel, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: _list ? S.hacksStepsOne : S.hacksStepsList,
            icon: Icon(_list ? Icons.looks_one_outlined : Icons.format_list_numbered),
            onPressed: () => setState(() => _list = !_list),
          ),
          IconButton(tooltip: S.wikiCall112, icon: const Icon(Icons.call_rounded), onPressed: () => openDialer(context, '112')),
        ],
      ),
      body: SafeArea(
        child: _list
            ? ListView(padding: Gap.page, children: [
                if (hasWarn) warnings(),
                const SizedBox(height: 16),
                for (var k = 0; k < h.stappen.length; k++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text('${k + 1}. ${h.stappen[k]}', style: t.textTheme.titleLarge?.copyWith(height: 1.35)),
                  ),
              ])
            : Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: LinearProgressIndicator(value: (i + 1) / n, borderRadius: BorderRadius.circular(5)),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: pages[i] == null
                        ? warnings()
                        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(S.planStepOf(i + 1 - (hasWarn ? 1 : 0), h.stappen.length),
                                style: t.textTheme.titleMedium?.copyWith(color: c.primary)),
                            const SizedBox(height: 12),
                            Semantics(
                              liveRegion: true,
                              child: Text(pages[i]!, style: t.textTheme.headlineMedium?.copyWith(height: 1.3)),
                            ),
                          ]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: i > 0 ? () => setState(() => _i = i - 1) : null,
                        child: const Text(S.wikiPrev),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: last ? () => Navigator.of(context).maybePop() : () => setState(() => _i = i + 1),
                        child: Text(last ? S.wikiFinish : S.wikiNext),
                      ),
                    ),
                  ]),
                ),
              ]),
      ),
    );
  }
}
