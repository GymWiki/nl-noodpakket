/// Alle drempels voor het (subtiele) verzoek om een beoordeling, op één plek. Pas hier aan; de rest van de code
/// leest alleen deze waarden. Het verzoek zelf is altijd de systeemprompt van de winkel (nooit een eigen dialoog).
class ReviewConfig {
  const ReviewConfig({
    this.minDaysSinceFirstLaunch = 5,
    this.minSessions = 4,
    this.minDaysBetweenRequests = 120,
    this.maxRequestsInWindow = 2,
    this.windowDays = 365,
    this.calmDelay = const Duration(seconds: 4),
    this.successFreshWindow = const Duration(minutes: 30),
  });

  /// De app is minstens zoveel dagen geleden voor het eerst gestart.
  final int minDaysSinceFirstLaunch;

  /// Minstens zoveel sessies (koude starts van de app).
  final int minSessions;

  /// Minstens zoveel dagen sinds het vorige verzoek.
  final int minDaysBetweenRequests;

  /// Het aantal verzoeken in de laatste [windowDays] dagen moet kleiner zijn dan dit.
  final int maxRequestsInWindow;
  final int windowDays;

  /// Wachttijd op een rustig scherm voordat we vragen (de gebruiker is dan al even terug op het dashboard).
  final Duration calmDelay;

  /// Hoe lang een succesmoment "net voorgekomen" telt. Het wordt alleen in het geheugen bijgehouden: sluit de app
  /// eerder, dan vervalt het.
  final Duration successFreshWindow;
}

/// De waarden die de app gebruikt.
const reviewConfig = ReviewConfig();

/// Sleutel in de instellingentabel (lokaal, Drift) waar de beoordelingsgeschiedenis staat.
const reviewHistoryKey = 'review_history';
