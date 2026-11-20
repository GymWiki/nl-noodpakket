import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mijnnoodpakket/features/review/review_config.dart';
import 'package:mijnnoodpakket/features/review/review_models.dart';
import 'package:mijnnoodpakket/features/review/review_policy.dart';

final now = DateTime(2026, 11, 20, 12);

/// Alles in orde: 10 dagen geleden gestart, 6 sessies, nooit gevraagd, een vers succesmoment, op het dashboard.
ReviewHistory goodHistory() => ReviewHistory(firstLaunch: now.subtract(const Duration(days: 10)), sessions: 6);

ReviewDecision decide({
  ReviewHistory? history,
  String version = '2.0.0',
  bool fresh = true,
  bool system = true,
  ReviewContext context = ReviewContext.calm,
  ReviewConfig? config,
  DateTime? at,
}) =>
    ReviewPromptPolicy(config ?? reviewConfig).evaluate(
      now: at ?? now,
      history: history ?? goodHistory(),
      appVersion: version,
      freshSuccessMoment: fresh,
      systemAvailable: system,
      context: context,
    );

void main() {
  group('drempels (één configbestand)', () {
    test('de standaardwaarden zijn de afgesproken drempels', () {
      expect(reviewConfig.minDaysSinceFirstLaunch, 5);
      expect(reviewConfig.minSessions, 4);
      expect(reviewConfig.minDaysBetweenRequests, 120);
      expect(reviewConfig.maxRequestsInWindow, 2);
      expect(reviewConfig.windowDays, 365);
      expect(reviewConfig.calmDelay, const Duration(seconds: 4));
    });
  });

  group('ReviewPromptPolicy: alle voorwaarden tegelijk', () {
    test('alles in orde: toegestaan', () {
      final d = decide();
      expect(d.allowed, isTrue);
      expect(d.blocks, isEmpty);
    });

    test('te vroeg: minder dan 5 dagen na de eerste start', () {
      final h = goodHistory().copyWith(firstLaunch: now.subtract(const Duration(days: 4, hours: 23)));
      expect(decide(history: h).blocks, {ReviewBlock.tooEarly});
    });

    test('precies 5 dagen is genoeg', () {
      final h = goodHistory().copyWith(firstLaunch: now.subtract(const Duration(days: 5)));
      expect(decide(history: h).allowed, isTrue);
    });

    test('onbekende eerste start telt als te vroeg', () {
      expect(decide(history: const ReviewHistory(sessions: 9)).blocks, {ReviewBlock.tooEarly});
    });

    test('te weinig sessies: 3 is niet genoeg, 4 wel', () {
      expect(decide(history: goodHistory().copyWith(sessions: 3)).blocks, {ReviewBlock.tooFewSessions});
      expect(decide(history: goodHistory().copyWith(sessions: 4)).allowed, isTrue);
    });

    test('geen vers succesmoment: geen verzoek', () {
      expect(decide(fresh: false).blocks, {ReviewBlock.noSuccessMoment});
    });

    test('te kort geleden: 119 dagen na het vorige verzoek niet, 120 dagen wel', () {
      final prev = now.subtract(const Duration(days: 119));
      expect(decide(history: goodHistory().copyWith(requests: [prev])).blocks, {ReviewBlock.tooSoonAfterLast});
      final ok = now.subtract(const Duration(days: 120));
      expect(decide(history: goodHistory().copyWith(requests: [ok])).allowed, isTrue);
    });

    test('te vaak: twee verzoeken in de laatste 365 dagen blokkeren, één niet', () {
      final one = goodHistory().copyWith(requests: [now.subtract(const Duration(days: 200))]);
      expect(decide(history: one).allowed, isTrue);
      final two = goodHistory().copyWith(requests: [
        now.subtract(const Duration(days: 130)),
        now.subtract(const Duration(days: 300)),
      ]);
      expect(decide(history: two).blocks, {ReviewBlock.tooManyRequests});
    });

    test('verzoeken ouder dan 365 dagen tellen niet meer mee', () {
      final h = goodHistory().copyWith(requests: [
        now.subtract(const Duration(days: 366)),
        now.subtract(const Duration(days: 400)),
        now.subtract(const Duration(days: 500)),
      ]);
      expect(decide(history: h).allowed, isTrue);
    });

    test('zelfde appversie: er is al gevraagd voor deze versie', () {
      final h = goodHistory().copyWith(versions: ['2.0.0']);
      expect(decide(history: h).blocks, {ReviewBlock.versionAlreadyAsked});
      expect(decide(history: h, version: '2.1.0').allowed, isTrue);
    });

    test('het systeem verbiedt het of de API is er niet', () {
      expect(decide(system: false).blocks, {ReviewBlock.systemUnavailable});
    });

    test('meerdere redenen komen tegelijk terug', () {
      final d = decide(history: const ReviewHistory(), fresh: false, system: false, context: ReviewContext.vault);
      expect(d.blocks, {
        ReviewBlock.tooEarly,
        ReviewBlock.tooFewSessions,
        ReviewBlock.noSuccessMoment,
        ReviewBlock.systemUnavailable,
        ReviewBlock.excludedContext,
      });
    });

    test('de drempels komen uit de config: een andere config geeft een ander oordeel', () {
      const strict = ReviewConfig(minSessions: 20, minDaysSinceFirstLaunch: 30);
      expect(decide(config: strict).blocks, {ReviewBlock.tooEarly, ReviewBlock.tooFewSessions});
      const lax = ReviewConfig(minSessions: 1, minDaysSinceFirstLaunch: 0);
      expect(decide(config: lax, history: const ReviewHistory(firstLaunch: null, sessions: 1)).blocks, {ReviewBlock.tooEarly});
    });
  });

  group('uitgesloten contexten', () {
    test('alleen een rustig dashboard mag: elke andere context wordt geblokkeerd', () {
      for (final c in ReviewContext.values) {
        final d = decide(context: c);
        if (c == ReviewContext.calm) {
          expect(d.allowed, isTrue);
        } else {
          expect(d.blocks, {ReviewBlock.excludedContext}, reason: '$c');
        }
      }
    });

    test('noodmodus, noodgeval-stappenplan, stap-voor-stap, Eerste-uur kaart, kluis en onderbreking worden uitgesloten', () {
      for (final c in [
        ReviewContext.emergencyMode,
        ReviewContext.emergencyGuide,
        ReviewContext.wiki,
        ReviewContext.firstHourCard,
        ReviewContext.vault,
        ReviewContext.interrupted,
        ReviewContext.other,
      ]) {
        expect(decide(context: c).allowed, isFalse, reason: '$c');
      }
    });
  });

  group('reviewContextFor (route -> context)', () {
    const table = <String, ReviewContext>{
      '/start': ReviewContext.calm,
      '/start/suggesties': ReviewContext.other,
      '/start/onderhoud': ReviewContext.other,
      '/noodgevallen': ReviewContext.wiki,
      '/wiki/stroomstoring': ReviewContext.wiki,
      '/wiki/stroomstoring/stappen': ReviewContext.emergencyGuide,
      '/hacks/water-koken/stappen': ReviewContext.emergencyGuide,
      '/hacks/pakket-op': ReviewContext.firstHourCard,
      '/hacks': ReviewContext.other,
      '/hacks/in-huis': ReviewContext.other,
      '/kluis': ReviewContext.vault,
      '/kluis/toevoegen': ReviewContext.vault,
      '/kluis/doc/abc': ReviewContext.vault,
      '/kluis/instellingen': ReviewContext.vault,
      '/delen/documenten': ReviewContext.vault,
      '/noodmodus': ReviewContext.emergencyMode,
      '/plan': ReviewContext.other,
      '/plan/wizard': ReviewContext.other,
      '/plan/delen': ReviewContext.other,
      '/delen/qr': ReviewContext.other,
      '/checklist': ReviewContext.other,
      '/item/new': ReviewContext.other,
      '/meer': ReviewContext.other,
      '/info': ReviewContext.other,
      '/instellingen': ReviewContext.other,
      '/': ReviewContext.other,
      '/onboarding': ReviewContext.other,
    };

    for (final e in table.entries) {
      test('${e.key} -> ${e.value.name}', () => expect(reviewContextFor(e.key), e.value));
    }

    test('een openstaande dialoog of blad (ook de paywall en het bevestigingsscherm) maakt elke context onderbrekend', () {
      expect(reviewContextFor('/start', overlayOpen: true), ReviewContext.interrupted);
      expect(reviewContextFor('/hacks/water-vinden', overlayOpen: true), ReviewContext.interrupted);
      expect(decide(context: reviewContextFor('/start', overlayOpen: true)).allowed, isFalse);
    });

    test('query en trailing slash veranderen niets', () {
      expect(reviewContextFor('/start?x=1'), ReviewContext.calm);
      expect(reviewContextFor('/kluis/?a=b'), ReviewContext.vault);
    });
  });

  group('ReviewHistory (alleen lokaal, alleen deze velden)', () {
    test('rondrit zonder verlies', () {
      final h = ReviewHistory(
        firstLaunch: DateTime(2026, 11, 1, 9),
        sessions: 7,
        requests: [DateTime(2026, 11, 10, 9)],
        versions: ['2.0.0'],
        usedMoments: {SuccessMoment.planShared.id},
      );
      final back = ReviewHistory.decode(h.encode());
      expect(back.firstLaunch, h.firstLaunch);
      expect(back.sessions, 7);
      expect(back.requests, h.requests);
      expect(back.versions, ['2.0.0']);
      expect(back.usedMoments, {'plan_shared'});
    });

    test('er wordt niets anders bewaard dan de afgesproken velden (geen identifiers of gebruikersinhoud)', () {
      final m = jsonDecode(goodHistory().encode()) as Map<String, dynamic>;
      expect(m.keys.toSet(), {'firstLaunch', 'sessions', 'requests', 'versions', 'moments'});
    });

    test('kapotte of lege opslag geeft een lege geschiedenis (liever niets vragen)', () {
      for (final raw in [null, '', 'geen json', '{"sessions":"x","requests":[1]}', '[]']) {
        final h = ReviewHistory.decode(raw);
        expect(h.sessions, anyOf(0, isA<int>()));
        expect(h.requests, isEmpty);
      }
      expect(ReviewHistory.decode('geen json').firstLaunch, isNull);
    });

    test('lastRequest en requestsWithin', () {
      final h = ReviewHistory(requests: [now.subtract(const Duration(days: 10)), now.subtract(const Duration(days: 400))]);
      expect(h.lastRequest, now.subtract(const Duration(days: 10)));
      expect(h.requestsWithin(now, 365), 1);
      expect(const ReviewHistory().lastRequest, isNull);
    });

    test('de drie succesmomenten hebben vaste, unieke id\'s', () {
      expect(SuccessMoment.values.map((m) => m.id).toSet().length, 3);
      expect(SuccessMoment.values.map((m) => m.id), ['readiness_3_days', 'plan_complete', 'plan_shared']);
    });
  });
}
