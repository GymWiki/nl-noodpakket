import 'dart:convert';

import '../../../domain/expiry.dart';

/// Sleutels in de lokale instellingen-tabel (geen aparte tabel, dus geen migratie).
class DashKeys {
  DashKeys._();
  static const later = 'dash_later'; // JSON: {suggestieId: 'yyyy-mm-dd'} verborgen tot
  static const dismissed = 'dash_dismissed'; // JSON: [suggestieId]
  static const nlAlertDone = 'nlalert_done'; // 'yyyy-mm-dd'
  static const maintDone = 'maint_done'; // JSON: {routineId: 'yyyy-mm-dd'}
  static const maintAnchor = 'maint_anchor'; // 'yyyy-mm-dd': eerste keer dat het dashboard is gezien
  static const maintRemind = 'maint_remind'; // JSON: [routineId] met herinnering aan
}

String dayString(DateTime d) {
  final x = dateOnly(d);
  return '${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
}

DateTime? _day(Object? v) => v is String ? DateTime.tryParse(v) : null;

Map<String, DateTime> _dayMap(String? raw) {
  if (raw == null) return const {};
  try {
    final m = jsonDecode(raw) as Map;
    return {
      for (final e in m.entries)
        if (_day(e.value) != null) e.key as String: _day(e.value)!,
    };
  } catch (_) {
    return const {};
  }
}

Set<String> _set(String? raw) {
  if (raw == null) return const {};
  try {
    return {for (final e in jsonDecode(raw) as List) e as String};
  } catch (_) {
    return const {};
  }
}

String encodeDayMap(Map<String, DateTime> m) =>
    jsonEncode({for (final e in m.entries) e.key: dayString(e.value)});

String encodeSet(Set<String> s) => jsonEncode(s.toList()..sort());

/// Wat de gebruiker op het dashboard heeft ingesteld; alles lokaal.
class DashPrefs {
  const DashPrefs({
    this.later = const {},
    this.dismissed = const {},
    this.nlAlertDone,
    this.maintDone = const {},
    this.maintAnchor,
    this.maintRemind = const {},
  });

  final Map<String, DateTime> later;
  final Set<String> dismissed;
  final DateTime? nlAlertDone;
  final Map<String, DateTime> maintDone;
  final DateTime? maintAnchor;
  final Set<String> maintRemind;

  factory DashPrefs.fromRaw(Map<String, String> m) => DashPrefs(
        later: _dayMap(m[DashKeys.later]),
        dismissed: _set(m[DashKeys.dismissed]),
        nlAlertDone: _day(m[DashKeys.nlAlertDone]),
        maintDone: _dayMap(m[DashKeys.maintDone]),
        maintAnchor: _day(m[DashKeys.maintAnchor]),
        maintRemind: _set(m[DashKeys.maintRemind]),
      );
}
