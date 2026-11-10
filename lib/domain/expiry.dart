import 'models.dart';

enum ExpiryStatus { none, ok, soon, expired }

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Maanden optellen met afkapping op het einde van de maand (31 jan + 1 mnd = 28/29 feb).
DateTime addMonths(DateTime d, int months) {
  final total = d.month - 1 + months;
  final y = d.year + total ~/ 12;
  final m = total % 12 + 1;
  final last = DateTime(y, m + 1, 0).day;
  return DateTime(y, m, d.day > last ? last : d.day);
}

/// Vervangdatum: de houdbaarheidsdatum, anders laatste controle + interval.
DateTime? dueDate(Item i) {
  if (i.expiryDate != null) return dateOnly(i.expiryDate!);
  if (i.intervalMonths != null && i.lastChecked != null) {
    return addMonths(dateOnly(i.lastChecked!), i.intervalMonths!);
  }
  return null;
}

ExpiryStatus statusFor(DateTime? due, DateTime now, int leadDays) {
  if (due == null) return ExpiryStatus.none;
  final today = dateOnly(now);
  if (due.isBefore(today)) return ExpiryStatus.expired;
  if (due.difference(today).inDays <= leadDays) return ExpiryStatus.soon;
  return ExpiryStatus.ok;
}

/// Tijdstip (09:00) waarop de herinnering voor [due] moet afgaan.
/// Is dat moment al voorbij maar is het item nog niet verlopen, dan
/// wordt het morgen 09:00. Verlopen items krijgen geen nieuwe melding.
DateTime? reminderTime(DateTime due, DateTime now, int leadDays) {
  final today = dateOnly(now);
  if (due.isBefore(today)) return null;
  var t = DateTime(due.year, due.month, due.day - leadDays, 9);
  if (!t.isAfter(now)) {
    t = DateTime(today.year, today.month, today.day + 1, 9);
    if (dateOnly(t).isAfter(due)) return null;
  }
  return t;
}
