import 'package:flutter/material.dart';
import '../../core/theme/category_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/l10n/strings.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../domain/expiry.dart';
import '../../domain/models.dart';
import '../expiry/expiry_chip.dart';
import '../expiry/expiry_screen.dart';
import '../noodplan/domain/plan_models.dart';
import '../noodplan/plan_providers.dart';
import '../noodplan/ui/plan_overview_screen.dart';

enum ChecklistFilter { all, needed, inHouse, expiring }

/// Pure filterfunctie (getest in unit tests).
List<Item> filterItems(
  List<Item> items, {
  required ChecklistFilter filter,
  required String query,
  required DateTime now,
  required int leadDays,
}) {
  final q = query.trim().toLowerCase();
  return items.where((i) {
    if (q.isNotEmpty &&
        !i.name.toLowerCase().contains(q) &&
        !categoryName(i.category).toLowerCase().contains(q)) {
      return false;
    }
    return switch (filter) {
      ChecklistFilter.all => true,
      ChecklistFilter.needed => !i.inHouse,
      ChecklistFilter.inHouse => i.inHouse,
      ChecklistFilter.expiring => switch (statusFor(dueDate(i), now, leadDays)) {
          ExpiryStatus.soon || ExpiryStatus.expired => true,
          _ => false,
        },
    };
  }).toList();
}

IconData categoryIcon(String id) => switch (id) {
      Cat.water => Icons.water_drop_outlined,
      Cat.info => Icons.radio_outlined,
      Cat.light => Icons.flashlight_on_outlined,
      Cat.health => Icons.medical_services_outlined,
      Cat.docs => Icons.folder_open_outlined,
      Cat.other => Icons.category_outlined,
      _ => Icons.label_outline,
    };

/// Tabblad "Pakket": checklist en "Vervangen" in twee segmenten.
class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  late int _tab = widget.initialTab;
  ChecklistFilter _filter = ChecklistFilter.all;
  String _query = '';

  static const _labels = {
    ChecklistFilter.all: S.filterAll,
    ChecklistFilter.needed: S.filterNeeded,
    ChecklistFilter.inHouse: S.filterInHouse,
    ChecklistFilter.expiring: S.filterExpiring,
  };

  @override
  void didUpdateWidget(ChecklistScreen old) {
    super.didUpdateWidget(old);
    if (old.initialTab != widget.initialTab) _tab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(visibleItemsProvider);
    final lead = ref.watch(settingsProvider).value?.leadDays ?? 30;

    return Scaffold(
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
              tooltip: S.addItem,
              onPressed: () => context.push('/item/new'),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const PageTitle(S.checklistTitle),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 0, label: Text(S.segList), icon: Icon(Icons.checklist_rounded)),
                    ButtonSegment(value: 1, label: Text(S.segReplace), icon: Icon(Icons.event_repeat_outlined)),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                ),
              ),
              const SizedBox(height: Gap.s),
            ]),
          ),
          Expanded(
            child: _tab == 1
                ? const ExpiryList()
                : items.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, _) => Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text(S.errorGeneric),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => ref.invalidate(allItemsProvider),
                          child: const Text(S.retry),
                        ),
                      ]),
                    ),
                    data: (all) => _body(context, all, lead),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _body(BuildContext context, List<Item> all, int lead) {
    final shown = filterItems(all,
        filter: _filter, query: _query, now: DateTime.now(), leadDays: lead);
    final byCat = <String, List<Item>>{};
    for (final i in shown) {
      byCat.putIfAbsent(i.category, () => []).add(i);
    }
    final cats = byCat.keys.toList()..sort(compareCategories);
    final done = all.where((i) => i.inHouse).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
      children: [
        const PlanBanner(),
        _ProgressCard(done: done, total: all.length),
        const _NoodpakketLocation(),
        const SizedBox(height: Gap.m),
        TextField(
          decoration: const InputDecoration(
            hintText: S.searchHint,
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: Gap.s),
        Wrap(
          spacing: 8,
          runSpacing: 0,
          children: [
            for (final f in ChecklistFilter.values)
              ChoiceChip(
                label: Text(_labels[f]!),
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
              ),
          ],
        ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.all(Gap.xl),
            child: Center(
              child: Text(all.isEmpty ? S.emptyList : S.emptyFilter, textAlign: TextAlign.center),
            ),
          ),
        for (final c in cats) ...[
          _CategoryHeader(
            id: c,
            name: categoryName(c),
            done: all.where((i) => i.category == c && i.inHouse).length,
            total: all.where((i) => i.category == c).length,
          ),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (var n = 0; n < byCat[c]!.length; n++) ...[
                if (n > 0) const Divider(indent: 64, endIndent: 16),
                _ItemTile(item: byCat[c]![n], leadDays: lead),
              ],
            ]),
          ),
        ],
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.done, required this.total});
  final int done, total;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final value = total == 0 ? 0.0 : done / total;
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Row(children: [
        ProgressRing(
          value: value,
          size: 64,
          stroke: 8,
          child: Text('${(value * 100).round()}%', style: t.textTheme.titleSmall),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Semantics(
            label: S.progressTotal(done, total),
            child: ExcludeSemantics(
              child: Text(S.progressTotal(done, total), style: t.textTheme.titleMedium),
            ),
          ),
        ),
      ]),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.id, required this.name, required this.done, required this.total});
  final String id, name;
  final int done, total;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final complete = total > 0 && done == total;
    return Padding(
      padding: const EdgeInsets.only(top: Gap.l, bottom: Gap.s),
      child: Semantics(
        header: true,
        label: '$name, ${S.progressCategory(done, total)}',
        child: ExcludeSemantics(
          child: Row(children: [
            IconBadge(categoryIcon(id), size: 32, tint: checklistTint(id)),
            const SizedBox(width: 10),
            Expanded(child: Text(name, style: t.textTheme.titleMedium)),
            if (complete)
              Icon(Icons.check_circle_rounded, size: 20, color: t.colorScheme.secondary)
            else
              Text(S.progressCategory(done, total),
                  style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}

/// Toont waar het noodpakket ligt, als dat in "Mijn noodplan" is ingevuld.
class _NoodpakketLocation extends ConsumerWidget {
  const _NoodpakketLocation();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final where = ref.watch(planProvider).value?.locationText(PlanKeys.noodpakket) ?? '';
    if (where.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 4),
      child: Row(children: [
        const Icon(Icons.place_outlined, size: 18),
        const SizedBox(width: 6),
        Expanded(child: Text(S.planNoodpakketAt(where))),
      ]),
    );
  }
}

class _ItemTile extends ConsumerWidget {
  const _ItemTile({required this.item, required this.leadDays});
  final Item item;
  final int leadDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final status = statusFor(dueDate(item), DateTime.now(), leadDays);
    final flagged = status == ExpiryStatus.soon || status == ExpiryStatus.expired;
    void toggle() => ref.read(itemRepositoryProvider).setInHouse(item.id, !item.inHouse);

    return InkWell(
      onTap: () => context.push('/item/${item.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        child: Row(children: [
          Semantics(
            label: S.itemSemantics(item.name, item.inHouse, quantityText(item)),
            excludeSemantics: true,
            checked: item.inHouse,
            onTap: toggle,
            child: Transform.scale(
              scale: 1.25,
              child: Checkbox(
                value: item.inHouse,
                onChanged: (v) =>
                    ref.read(itemRepositoryProvider).setInHouse(item.id, v ?? false),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  item.name,
                  style: t.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: item.inHouse ? t.colorScheme.onSurfaceVariant : null,
                  ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(quantityText(item), style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                    if (flagged) ExpiryChip(status: status, due: dueDate(item)!),
                  ],
                ),
              ]),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: t.colorScheme.onSurfaceVariant),
        ]),
      ),
    );
  }
}
