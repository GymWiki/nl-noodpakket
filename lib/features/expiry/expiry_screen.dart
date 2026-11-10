import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/l10n/strings.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../domain/expiry.dart';
import '../../domain/models.dart';
import 'expiry_chip.dart';

/// Lijst "Binnenkort vervangen", gesorteerd op datum. Wordt getoond in het
/// tabblad Pakket (segment "Vervangen") en als losstaand scherm.
class ExpiryList extends ConsumerWidget {
  const ExpiryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(visibleItemsProvider);
    final lead = ref.watch(settingsProvider).value?.leadDays ?? 30;
    final t = Theme.of(context);
    return items.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text(S.errorGeneric)),
      data: (all) {
        final now = DateTime.now();
        final due = [
          for (final i in all)
            if (dueDate(i) != null) (i, dueDate(i)!),
        ]..sort((a, b) => a.$2.compareTo(b.$2));
        if (due.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(Gap.xl),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const IconBadge(Icons.event_available_outlined, size: 64),
                const SizedBox(height: Gap.m),
                Text(S.replaceEmpty, textAlign: TextAlign.center, style: t.textTheme.bodyLarge),
              ]),
            ),
          );
        }
        String section(DateTime d) => switch (statusFor(d, now, lead)) {
              ExpiryStatus.expired => S.sectionExpired,
              ExpiryStatus.soon => S.sectionSoon,
              _ => S.sectionLater,
            };
        final groups = <String, List<(Item, DateTime)>>{};
        for (final e in due) {
          groups.putIfAbsent(section(e.$2), () => []).add(e);
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            for (final g in groups.entries) ...[
              SectionHeader(g.key),
              SoftCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  for (var i = 0; i < g.value.length; i++) ...[
                    if (i > 0) const Divider(indent: 16, endIndent: 16),
                    _DueTile(
                      item: g.value[i].$1,
                      due: g.value[i].$2,
                      status: statusFor(g.value[i].$2, now, lead),
                    ),
                  ],
                ]),
              ),
            ],
          ],
        );
      },
    );
  }
}

class ExpiryScreen extends StatelessWidget {
  const ExpiryScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(S.replaceTitle)),
        body: const ExpiryList(),
      );
}

class _DueTile extends StatelessWidget {
  const _DueTile({required this.item, required this.due, required this.status});
  final Item item;
  final DateTime due;
  final ExpiryStatus status;

  @override
  Widget build(BuildContext context) {
    final flagged = status == ExpiryStatus.soon || status == ExpiryStatus.expired;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(item.name),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(fmtDate(due)),
            if (flagged) ExpiryChip(status: status, due: due),
          ],
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push('/item/${item.id}'),
    );
  }
}
