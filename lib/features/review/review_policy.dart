import 'review_config.dart';
import 'review_models.dart';

/// Waar de gebruiker is. Alleen [calm] mag een verzoek krijgen; al het andere is uitgesloten.
enum ReviewContext {
  /// Het dashboard ("Start"), zonder dialoog of blad erbovenop.
  calm,

  /// De noodmodus. Bestaat nog niet als scherm in de app; staat hier voor als hij komt.
  emergencyMode,

  /// Een stappenplan bij een noodgeval of een hack, en de stap-voor-stap modus.
  emergencyGuide,

  /// De noodgevallen-wiki (overzicht en detail), waar de Eerste-uur kaart ook staat.
  wiki,

  /// De Eerste-uur kaart ("Mijn pakket is op").
  firstHourCard,

  /// De kluis, ook het toevoegen of bekijken van een document.
  vault,

  /// Er staat een dialoog, blad of venster open dat de gebruiker onderbreekt. Dat geldt ook voor de paywall en het
  /// bevestigingsscherm van een aankoop (die zijn een bottom sheet).
  interrupted,

  /// Elk ander scherm: midden in een taak.
  other,
}

/// Bepaalt de context uit de route en of er een dialoog of blad openstaat. Zuiver, dus testbaar.
ReviewContext reviewContextFor(String location, {bool overlayOpen = false}) {
  if (overlayOpen) return ReviewContext.interrupted;
  final path = Uri.tryParse(location)?.path ?? location;
  final seg = path.split('/').where((s) => s.isNotEmpty).toList();
  if (seg.isEmpty) return ReviewContext.other;
  if (seg.first == 'noodmodus') return ReviewContext.emergencyMode;
  if (seg.contains('stappen')) return ReviewContext.emergencyGuide;
  if (seg.first == 'wiki' || seg.first == 'noodgevallen') return ReviewContext.wiki;
  if (seg.first == 'hacks' && seg.length >= 2 && seg[1] == 'pakket-op') return ReviewContext.firstHourCard;
  if (seg.first == 'kluis' || (seg.first == 'delen' && seg.length >= 2 && seg[1] == 'documenten')) {
    return ReviewContext.vault;
  }
  if (seg.length == 1 && seg.first == 'start') return ReviewContext.calm;
  return ReviewContext.other;
}

/// Waarom een verzoek niet mag. Meerdere redenen tegelijk zijn mogelijk.
enum ReviewBlock {
  tooEarly,
  tooFewSessions,
  noSuccessMoment,
  tooSoonAfterLast,
  tooManyRequests,
  versionAlreadyAsked,
  systemUnavailable,
  excludedContext,
}

class ReviewDecision {
  const ReviewDecision(this.blocks);
  final Set<ReviewBlock> blocks;
  bool get allowed => blocks.isEmpty;
}

/// Bepaalt of een verzoek om een beoordeling is toegestaan. Pure Dart, geen UI, geen I/O.
/// Alle voorwaarden moeten tegelijk gelden.
class ReviewPromptPolicy {
  const ReviewPromptPolicy([this.config = reviewConfig]);
  final ReviewConfig config;

  ReviewDecision evaluate({
    required DateTime now,
    required ReviewHistory history,
    required String appVersion,
    required bool freshSuccessMoment,
    required bool systemAvailable,
    required ReviewContext context,
  }) {
    final blocks = <ReviewBlock>{};
    final first = history.firstLaunch;
    if (first == null || now.difference(first) < Duration(days: config.minDaysSinceFirstLaunch)) {
      blocks.add(ReviewBlock.tooEarly);
    }
    if (history.sessions < config.minSessions) blocks.add(ReviewBlock.tooFewSessions);
    if (!freshSuccessMoment) blocks.add(ReviewBlock.noSuccessMoment);
    final last = history.lastRequest;
    if (last != null && now.difference(last) < Duration(days: config.minDaysBetweenRequests)) {
      blocks.add(ReviewBlock.tooSoonAfterLast);
    }
    if (history.requestsWithin(now, config.windowDays) >= config.maxRequestsInWindow) {
      blocks.add(ReviewBlock.tooManyRequests);
    }
    if (history.versions.contains(appVersion)) blocks.add(ReviewBlock.versionAlreadyAsked);
    if (!systemAvailable) blocks.add(ReviewBlock.systemUnavailable);
    if (context != ReviewContext.calm) blocks.add(ReviewBlock.excludedContext);
    return ReviewDecision(blocks);
  }
}
