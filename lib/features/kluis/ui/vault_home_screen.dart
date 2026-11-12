import 'package:flutter/material.dart';
import '../../pro/pro_models.dart';
import '../../pro/pro_providers.dart';
import '../../pro/pro_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/calm.dart';
import '../../../core/l10n/strings.dart';
import '../data/vault_controller.dart';
import '../domain/vault_models.dart';
import 'vault_widgets.dart';

/// Overzicht van de kluis: Noodmap, binnenkort verlopen en alle documenten.
class VaultHomeScreen extends ConsumerStatefulWidget {
  const VaultHomeScreen({super.key});

  @override
  ConsumerState<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends ConsumerState<VaultHomeScreen> {
  String _query = '';
  String? _typeId, _owner;
  bool _grid = false;

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(vaultProvider);
    final meta = v.meta;
    final t = Theme.of(context);
    final filtered = filterVaultDocs(meta.documents, query: _query, typeId: _typeId, owner: _owner);
    final soonDays = v.reminderDays.isEmpty ? 90 : v.reminderDays.first;
    final now = DateTime.now();
    final expiring = [
      for (final d in filtered)
        if (docExpiryStatus(d, now, soonDays: soonDays) case DocExpiry.soon || DocExpiry.expired) d,
    ]..sort((a, b) => a.expiry!.compareTo(b.expiry!));
    final emergency = [for (final d in filtered) if (d.emergency) d];
    final owners = {for (final d in meta.documents) if (d.owner.isNotEmpty) d.owner}.toList()..sort();
    final usedTypes = [
      for (final ty in meta.allTypes)
        if (meta.documents.any((d) => d.typeId == ty.id)) ty,
    ];

    Widget header(String text, {String? sub}) => Padding(
          padding: const EdgeInsets.only(top: Space.section, bottom: Space.tight),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Semantics(header: true, child: Text(text, style: t.textTheme.titleMedium)),
            if (sub != null)
              Text(sub, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ]),
        );

    Widget docs(List<VaultDocument> list) => _grid
        ? GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [for (final d in list) _DocCard(doc: d, meta: meta)],
          )
        : CalmListGroup(children: [for (final d in list) _DocTile(doc: d, meta: meta)]);

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.vaultTitle),
        actions: [
          IconButton(
            tooltip: _grid ? S.vaultViewList : S.vaultViewGrid,
            icon: Icon(_grid ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _grid = !_grid),
          ),
          IconButton(
            tooltip: S.vaultSettings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/kluis/instellingen'),
          ),
          IconButton(
            tooltip: S.vaultLockNow,
            icon: const Icon(Icons.lock),
            onPressed: () => ref.read(vaultProvider.notifier).lock(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Alleen een nieuw document boven de gratis limiet vraagt Pro; al het andere blijft vrij.
          final ok = canAddVaultDocument(count: meta.documents.length, pro: ref.read(proUnlockedProvider)) ||
              await requirePro(context, ref, ProFeature.vaultUnlimited);
          if (ok && context.mounted) context.push('/kluis/toevoegen');
        },
        icon: const Icon(Icons.add),
        label: const Text(S.vaultAddDocument),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.screen, 8, Space.screen, 96),
        children: [
          // De kluis-waarschuwing blijft zichtbaar, maar als rustige regel in plaats van een gekleurde kaart.
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, size: 20, color: t.colorScheme.onSurfaceVariant),
            const SizedBox(width: Space.tight),
            Expanded(
              child: Text(S.vaultDisclaimer,
                  style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            ),
          ]),
          if (!ref.watch(proUnlockedProvider)) ...[
            const SizedBox(height: 12),
            Semantics(
              label: '${S.vaultFreeCounter(meta.documents.length)}. ${S.vaultFreeCounterHint}',
              excludeSemantics: true,
              child: Row(children: [
                Icon(Icons.folder_open_outlined, size: 20, color: t.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(S.vaultFreeCounter(meta.documents.length),
                      style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          if (meta.documents.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text(S.vaultEmpty, textAlign: TextAlign.center, style: t.textTheme.bodyLarge)),
            )
          else ...[
            TextField(
              decoration: const InputDecoration(hintText: S.vaultSearchHint, prefixIcon: Icon(Icons.search)),
              onChanged: (q) => setState(() => _query = q),
            ),
            const SizedBox(height: Space.tight),
            // Filters staan ingeklapt tot je ze nodig hebt (of als er een filter actief is).
            ExpandableSection(
              title: S.vaultFilters,
              initiallyExpanded: _typeId != null || _owner != null,
              children: [
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: _typeId,
                  decoration: const InputDecoration(labelText: S.vaultFieldType),
                  items: [
                    const DropdownMenuItem(value: null, child: Text(S.vaultFilterAllTypes)),
                    for (final ty in usedTypes) DropdownMenuItem(value: ty.id, child: Text(ty.label, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (x) => setState(() => _typeId = x),
                ),
              ),
              if (owners.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: _owner,
                    decoration: const InputDecoration(labelText: S.vaultFieldOwner),
                    items: [
                      const DropdownMenuItem(value: null, child: Text(S.vaultFilterEveryone)),
                      for (final o in owners) DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (x) => setState(() => _owner = x),
                  ),
                ),
              ],
            ]),
              ],
            ),
            if (filtered.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: Text(S.vaultNoResults)))
            else ...[
              if (expiring.isNotEmpty) ...[header(S.vaultExpiringSoon), docs(expiring)],
              if (emergency.isNotEmpty) ...[header(S.vaultNoodmap, sub: S.vaultNoodmapSub), docs(emergency)],
              header(S.vaultAllDocs),
              docs(filtered),
            ],
          ],
        ],
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({required this.doc, required this.meta});
  final VaultDocument doc;
  final VaultMeta meta;

  @override
  Widget build(BuildContext context) {
    final sub = [typeLabel(meta, doc.typeId), if (doc.owner.isNotEmpty) doc.owner, S.vaultPagesCount(doc.pages.length)].join(' · ');
    return Semantics(
      button: true,
      label: '${doc.title}, $sub',
      excludeSemantics: true,
      onTap: () => context.push('/kluis/doc/${doc.id}'),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.screen),
        minVerticalPadding: 8,
        leading: VaultThumb(doc: doc),
        title: Text(doc.title),
        subtitle: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(sub),
          DocExpiryBadge(doc: doc),
        ]),
        trailing: doc.emergency ? const Icon(Icons.star, size: 20) : const Icon(Icons.chevron_right),
        onTap: () => context.push('/kluis/doc/${doc.id}'),
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  const _DocCard({required this.doc, required this.meta});
  final VaultDocument doc;
  final VaultMeta meta;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Semantics(
      button: true,
      label: '${doc.title}, ${typeLabel(meta, doc.typeId)}',
      excludeSemantics: true,
      onTap: () => context.push('/kluis/doc/${doc.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/kluis/doc/${doc.id}'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Center(child: VaultThumb(doc: doc, size: 96))),
              const SizedBox(height: 8),
              Text(doc.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.titleSmall),
              Text(typeLabel(meta, doc.typeId),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
              DocExpiryBadge(doc: doc),
            ]),
          ),
        ),
      ),
    );
  }
}
