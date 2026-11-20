import 'dart:convert';

/// De enige aanleidingen voor een verzoek. Elk moment telt maar één keer per toestel als aanleiding.
enum SuccessMoment {
  /// De Paraatheid haalt voor het eerst 3 dagen of meer.
  readiness3Days('readiness_3_days'),

  /// Het noodplan is volledig ingevuld.
  planComplete('plan_complete'),

  /// Het noodplan is met succes gedeeld (pdf, tekst, bestand of QR).
  planShared('plan_shared');

  const SuccessMoment(this.id);
  final String id;
}

/// Wat we lokaal bewaren, en niets anders: de datum van de eerste start, het aantal sessies, de tijdstippen van eerdere
/// verzoeken, de appversies waarvoor is gevraagd, en welke succesmomenten al als aanleiding hebben gediend.
/// Geen identifiers, geen inhoud van de gebruiker. Verlaat het toestel nooit.
class ReviewHistory {
  const ReviewHistory({
    this.firstLaunch,
    this.sessions = 0,
    this.requests = const [],
    this.versions = const [],
    this.usedMoments = const {},
  });

  final DateTime? firstLaunch;
  final int sessions;
  final List<DateTime> requests;
  final List<String> versions;
  final Set<String> usedMoments;

  DateTime? get lastRequest => requests.isEmpty ? null : requests.reduce((a, b) => a.isAfter(b) ? a : b);

  int requestsWithin(DateTime now, int days) =>
      requests.where((r) => !r.isAfter(now) && now.difference(r) < Duration(days: days)).length;

  ReviewHistory copyWith({
    DateTime? firstLaunch,
    int? sessions,
    List<DateTime>? requests,
    List<String>? versions,
    Set<String>? usedMoments,
  }) =>
      ReviewHistory(
        firstLaunch: firstLaunch ?? this.firstLaunch,
        sessions: sessions ?? this.sessions,
        requests: requests ?? this.requests,
        versions: versions ?? this.versions,
        usedMoments: usedMoments ?? this.usedMoments,
      );

  String encode() => jsonEncode({
        'firstLaunch': firstLaunch?.toUtc().toIso8601String(),
        'sessions': sessions,
        'requests': [for (final r in requests) r.toUtc().toIso8601String()],
        'versions': versions,
        'moments': usedMoments.toList()..sort(),
      });

  /// Tolerant: kapotte of ontbrekende gegevens geven een lege geschiedenis (we vragen dan liever niets).
  factory ReviewHistory.decode(String? raw) {
    if (raw == null || raw.isEmpty) return const ReviewHistory();
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return ReviewHistory(
        firstLaunch: m['firstLaunch'] == null ? null : DateTime.parse(m['firstLaunch'] as String).toLocal(),
        sessions: (m['sessions'] as num?)?.toInt() ?? 0,
        requests: [for (final r in (m['requests'] as List? ?? const [])) DateTime.parse(r as String).toLocal()],
        versions: [for (final v in (m['versions'] as List? ?? const [])) v as String],
        usedMoments: {for (final v in (m['moments'] as List? ?? const [])) v as String},
      );
    } catch (_) {
      return const ReviewHistory();
    }
  }
}
