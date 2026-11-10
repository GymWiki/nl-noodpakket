import '../../../domain/expiry.dart';
import 'plan_models.dart';

/// Moment (10:00) van de volgende "Klopt je noodplan nog?"-herinnering:
/// 6 maanden na de laatste bevestiging, anders na de laatste wijziging.
/// Is dat moment al voorbij, dan komt de herinnering morgen om 10:00.
/// Zonder inhoud in het plan is er geen herinnering.
DateTime? planReminderTime(Plan plan, DateTime now) {
  if (!plan.hasContent) return null;
  final base = plan.lastConfirmedAt ?? plan.updatedAt ?? plan.createdAt ?? now;
  final due = addMonths(dateOnly(base), 6);
  final t = DateTime(due.year, due.month, due.day, 10);
  if (t.isAfter(now)) return t;
  final today = dateOnly(now);
  return DateTime(today.year, today.month, today.day + 1, 10);
}
