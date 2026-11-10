import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/l10n/strings.dart';
import '../../domain/expiry.dart';

/// Rustige badge; alleen "verlopen" gebruikt de alarmkleur.
class ExpiryChip extends StatelessWidget {
  const ExpiryChip({super.key, required this.status, required this.due});
  final ExpiryStatus status;
  final DateTime due;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final expired = status == ExpiryStatus.expired;
    final days = due.difference(dateOnly(DateTime.now())).inDays;
    final text = expired
        ? S.expiredAgo(-days)
        : days == 0
            ? S.dueToday
            : S.dueIn(days);
    return Semantics(
      label: '${expired ? S.expired : S.sectionSoon}: $text, ${fmtDate(due)}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: expired ? c.errorContainer : c.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: expired ? c.onErrorContainer : c.onTertiaryContainer,
          ),
        ),
      ),
    );
  }
}
