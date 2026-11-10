import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/l10n/strings.dart';
import '../../core/providers.dart';
import '../../domain/expiry.dart';
import '../../domain/models.dart';
import '../expiry/expiry_chip.dart';
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

class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key});

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  ChecklistFilter _filter = ChecklistFilter.all;
  String _query = '';

  static const _labels = {
    ChecklistFilter.all: S.filterAll,
    ChecklistFilter.needed: S.filterNeeded,
    ChecklistFilter.inHouse: S.filterInHouse,
    ChecklistFilter.expiring: S.filterExpiring,
  };

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(visibleItemsProvider);
    final lead = ref.watch(settingsProvider).value?.leadDays ?? 30;

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.checklistTitle),
        actions: [
          IconButton(
            tooltip: S.vaultTitle,
            icon: const Icon(Icons.lock_outline),
            onPressed: () => context.push('/kluis'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/item/new'),
        icon: const Icon(Icons.add),
        label: const Text(S.addItem),
      ),
      body: items.when(
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        const PlanBanner(),
        _ProgressCard(done: done, total: all.length),
        const _NoodpakketLocation(),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            hintText: S.searchHint,
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final f in ChecklistFilter.values)
              ChoiceChip(
                label: Text(_labels[f]!),
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(all.isEmpty ? S.emptyList : S.emptyFilter,
                  textAlign: TextAlign.center),
            ),
          ),
        for (final c in cats) ...[
          _CategoryHeader(
            name: categoryName(c),
            done: all.where((i) => i.category == c && i.inHouse).length,
            total: all.where((i) => i.category == c).length,
          ),
          for (final i in byCat[c]!) _ItemTile(item: i, leadDays: lead),
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
    final value = total == 0 ? 0.0 : done / total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: S.progressTotal(done, total),
              child: ExcludeSemantics(
                child: Text(S.progressTotal(done, total),
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: value,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader(
      {required this.name, required this.done, required this.total});
  final String name;
  final int done, total;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Semantics(
        header: true,
        label: '$name, ${S.progressCategory(done, total)}',
        child: ExcludeSemantics(
          child: Row(children: [
            Expanded(child: Text(name, style: t.textTheme.titleMedium)),
            Text(S.progressCategory(done, total),
                style: t.textTheme.bodyMedium
                    ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}

class _ItemTile extends ConsumerWidget {
  const _ItemTile({required this.item, required this.leadDays});
  final Item item;
  final int leadDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = statusFor(dueDate(item), DateTime.now(), leadDays);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 8,
      leading: Semantics(
        label: S.itemSemantics(item.name, item.inHouse, quantityText(item)),
        excludeSemantics: true,
        checked: item.inHouse,
        onTap: () =>
            ref.read(itemRepositoryProvider).setInHouse(item.id, !item.inHouse),
        child: Transform.scale(
          scale: 1.2,
          child: Checkbox(
            value: item.inHouse,
            onChanged: (v) =>
                ref.read(itemRepositoryProvider).setInHouse(item.id, v ?? false),
          ),
        ),
      ),
      title: Text(item.name),
      subtitle: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(quantityText(item)),
          if (status == ExpiryStatus.soon || status == ExpiryStatus.expired)
            ExpiryChip(status: status, due: dueDate(item)!),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/item/${item.id}'),
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
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Row(children: [
        const Icon(Icons.place_outlined, size: 18),
        const SizedBox(width: 6),
        Expanded(child: Text(S.planNoodpakketAt(where))),
      ]),
    );
  }
}
