import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/l10n/strings.dart';
import '../../core/providers.dart';
import '../../domain/expiry.dart';
import '../../domain/models.dart';
import 'expiry_chip.dart';

class ExpiryScreen extends ConsumerWidget {
  const ExpiryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(visibleItemsProvider);
    final lead = ref.watch(settingsProvider).value?.leadDays ?? 30;
    return Scaffold(
      appBar: AppBar(title: const Text(S.replaceTitle)),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text(S.errorGeneric)),
        data: (all) {
          final now = DateTime.now();
          final due = [
            for (final i in all)
              if (dueDate(i) != null) (i, dueDate(i)!),
          ]..sort((a, b) => a.$2.compareTo(b.$2));
          if (due.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(S.replaceEmpty, textAlign: TextAlign.center),
              ),
            );
          }
          String section(DateTime d) => switch (statusFor(d, now, lead)) {
                ExpiryStatus.expired => S.sectionExpired,
                ExpiryStatus.soon => S.sectionSoon,
                _ => S.sectionLater,
              };
          final children = <Widget>[];
          String? last;
          for (final (item, d) in due) {
            final s = section(d);
            if (s != last) {
              children.add(Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 4),
                child: Semantics(
                  header: true,
                  child: Text(s, style: Theme.of(context).textTheme.titleMedium),
                ),
              ));
              last = s;
            }
            children.add(_DueTile(
                item: item, due: d, status: statusFor(d, now, lead)));
          }
          return ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: children);
        },
      ),
    );
  }
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
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 8,
      title: Text(item.name),
      subtitle: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(fmtDate(due)),
          if (flagged) ExpiryChip(status: status, due: due),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/item/${item.id}'),
    );
  }
}
