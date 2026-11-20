import 'package:in_app_review/in_app_review.dart';

/// Dunne laag om de systeemprompt van de winkel. Dit is het enige bestand dat `in_app_review` kent.
///
/// iOS: StoreKit `requestReview`. Android: Google Play In-App Review API. De winkel beslist of er iets te zien is
/// (er geldt een quotum) en meldt niet terug of de prompt is getoond. We tonen nooit een eigen dialoog.
abstract class ReviewLauncher {
  /// Is de systeem-API beschikbaar (op Android: Play Store en Play-services aanwezig)?
  Future<bool> isAvailable();

  /// Vraagt het systeem om de beoordelingsprompt te tonen. Mag stil niets doen.
  Future<void> requestReview();
}

class InAppReviewLauncher implements ReviewLauncher {
  InAppReviewLauncher([InAppReview? review]) : _review = review;
  final InAppReview? _review;
  InAppReview get _r => _review ?? InAppReview.instance;

  @override
  Future<bool> isAvailable() => _r.isAvailable();

  @override
  Future<void> requestReview() => _r.requestReview();
}
