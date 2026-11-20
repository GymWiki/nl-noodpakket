import 'package:flutter/foundation.dart';

import 'review_config.dart';
import 'review_launcher.dart';
import 'review_models.dart';
import 'review_policy.dart';
import 'review_store.dart';

enum ReviewOutcome {
  /// Er was geen vers succesmoment.
  noMoment,

  /// Het beleid blokkeert (zie [ReviewResult.blocks]); er is niets gevraagd.
  blocked,

  /// Het verzoek is gedaan en lokaal geregistreerd. Het systeem beslist of er iets te zien is.
  requested,
}

class ReviewResult {
  const ReviewResult(this.outcome, [this.blocks = const {}, this.moment]);
  final ReviewOutcome outcome;
  final Set<ReviewBlock> blocks;
  final SuccessMoment? moment;
}

/// Houdt de geschiedenis bij en voert het verzoek uit. Pure Dart met geïnjecteerde klok, opslag en systeem-API,
/// dus volledig testbaar. De UI (zie review_host.dart) beslist alleen WANNEER er gevraagd mag worden.
class ReviewController {
  ReviewController({
    required this.store,
    required this.launcher,
    required this.clock,
    required this.appVersion,
    this.config = reviewConfig,
    ReviewPromptPolicy? policy,
  }) : policy = policy ?? ReviewPromptPolicy(config);

  final ReviewStore store;
  final ReviewLauncher launcher;
  final DateTime Function() clock;
  final Future<String> Function() appVersion;
  final ReviewConfig config;
  final ReviewPromptPolicy policy;

  /// Verandert als er een succesmoment bij komt, zodat de host de timing opnieuw kan beoordelen.
  final ValueNotifier<int> changes = ValueNotifier(0);

  ReviewHistory? _history;
  ({SuccessMoment moment, DateTime at})? _pending;
  bool _requesting = false;

  Future<ReviewHistory> _load() async => _history ??= await store.load();

  Future<void> _save(ReviewHistory h) async {
    _history = h;
    try {
      await store.save(h);
    } catch (_) {
      // Opslaan mislukt: we vragen liever niets dan te vaak.
    }
  }

  Future<ReviewHistory> history() => _load();

  /// Eén keer per koude start: onthoudt de eerste start en telt de sessie.
  Future<void> onAppStart() async {
    final h = await _load();
    await _save(h.copyWith(firstLaunch: h.firstLaunch ?? clock(), sessions: h.sessions + 1));
  }

  /// Een succesmoment is net voorgekomen. Het wordt alleen in het geheugen bewaard (vervalt na
  /// [ReviewConfig.successFreshWindow] of als de app sluit) en kan alleen een aanleiding zijn als het nog niet eerder
  /// een verzoek heeft veroorzaakt.
  Future<void> successOccurred(SuccessMoment moment) async {
    final h = await _load();
    if (h.usedMoments.contains(moment.id)) return;
    _pending = (moment: moment, at: clock());
    if (config.spendMomentWhenBlocked) await _save(h.copyWith(usedMoments: {...h.usedMoments, moment.id}));
    changes.value++;
  }

  /// Is er een succesmoment dat nog "net voorgekomen" telt?
  bool get hasFreshMoment {
    final p = _pending;
    if (p == null) return false;
    if (clock().difference(p.at) > config.successFreshWindow) {
      _pending = null;
      return false;
    }
    return true;
  }

  /// Probeert het verzoek te doen, op het moment dat de host weet dat de gebruiker op een rustig scherm zit.
  /// Toont nooit een foutmelding: elke fout van het systeem wordt stil genegeerd.
  Future<ReviewResult> maybeRequest(ReviewContext context) async {
    if (_requesting || !hasFreshMoment) return const ReviewResult(ReviewOutcome.noMoment);
    _requesting = true;
    try {
      final moment = _pending!.moment;
      // Controleer eerst of de API beschikbaar is (op Android: Play Store en Play-services).
      var available = false;
      try {
        available = await launcher.isAvailable();
      } catch (_) {}
      final h = await _load();
      final decision = policy.evaluate(
        now: clock(),
        history: h,
        appVersion: await appVersion(),
        freshSuccessMoment: true,
        systemAvailable: available,
        context: context,
      );
      if (!decision.allowed) {
        // Alleen een verkeerd scherm: het moment blijft staan voor een rustiger moment. Elke andere reden: het
        // moment is voorbij (en telt als gebruikt als de config dat wil).
        if (decision.blocks.any((b) => b != ReviewBlock.excludedContext)) {
          _pending = null;
          if (config.spendMomentWhenBlocked) {
            final cur = await _load();
            await _save(cur.copyWith(usedMoments: {...cur.usedMoments, moment.id}));
          }
        }
        return ReviewResult(ReviewOutcome.blocked, decision.blocks, moment);
      }

      // Eerst registreren, dan vragen: het systeem beslist zelf of er iets te zien is, en meldt dat niet terug.
      final now = clock();
      final version = await appVersion();
      await _save(h.copyWith(
        requests: [...h.requests, now],
        versions: h.versions.contains(version) ? h.versions : [...h.versions, version],
        usedMoments: {...h.usedMoments, moment.id},
      ));
      _pending = null;
      try {
        await launcher.requestReview();
      } catch (_) {
        // Nooit een foutmelding aan de gebruiker.
      }
      return ReviewResult(ReviewOutcome.requested, const {}, moment);
    } finally {
      _requesting = false;
    }
  }

  void dispose() => changes.dispose();
}
