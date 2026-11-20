import 'package:flutter_test/flutter_test.dart';
import 'package:mijnnoodpakket/features/review/review_config.dart';
import 'package:mijnnoodpakket/features/review/review_controller.dart';
import 'package:mijnnoodpakket/features/review/review_models.dart';
import 'package:mijnnoodpakket/features/review/review_policy.dart';

import 'review_fakes.dart';

void main() {
  late TestClock clock;
  late MemoryReviewStore store;
  late FakeReviewLauncher launcher;

  setUp(() {
    clock = TestClock(DateTime(2026, 11, 20, 12));
    store = MemoryReviewStore(seasoned(clock.now));
    launcher = FakeReviewLauncher();
  });

  ReviewController make({String Function()? version, ReviewConfig config = reviewConfig}) =>
      buildController(clock: clock, store: store, launcher: launcher, version: version, config: config);

  group('sessies en eerste start (alleen lokaal)', () {
    test('de eerste start wordt onthouden en elke start telt een sessie', () async {
      store.history = const ReviewHistory();
      final c = make();
      await c.onAppStart();
      expect(store.history.firstLaunch, clock.now);
      expect(store.history.sessions, 1);
      clock.advance(const Duration(days: 3));
      await make().onAppStart();
      expect(store.history.firstLaunch, DateTime(2026, 11, 20, 12), reason: 'de eerste start verandert niet');
      expect(store.history.sessions, 2);
    });

    test('opslag die faalt gooit niets', () async {
      store.failSave = true;
      await make().onAppStart();
    });
  });

  group('het verzoek', () {
    test('na een succesmoment op een rustig scherm: de systeemprompt wordt gevraagd en alles wordt lokaal vastgelegd', () async {
      final c = make();
      await c.successOccurred(SuccessMoment.planShared);
      expect(c.hasFreshMoment, isTrue);
      final r = await c.maybeRequest(ReviewContext.calm);
      expect(r.outcome, ReviewOutcome.requested);
      expect(launcher.requests, 1);
      expect(store.history.requests, [clock.now]);
      expect(store.history.versions, ['2.0.0']);
      expect(store.history.usedMoments, {'plan_shared'});
      expect(c.hasFreshMoment, isFalse);
    });

    test('eerst wordt gecontroleerd of de API beschikbaar is, dan pas gevraagd', () async {
      final c = make();
      await c.successOccurred(SuccessMoment.planComplete);
      await c.maybeRequest(ReviewContext.calm);
      expect(launcher.calls, ['isAvailable', 'requestReview']);
    });

    test('zonder succesmoment gebeurt er niets, ook op een rustig scherm', () async {
      final r = await make().maybeRequest(ReviewContext.calm);
      expect(r.outcome, ReviewOutcome.noMoment);
      expect(launcher.calls, isEmpty);
    });

    test('een succesmoment dat te oud is, telt niet meer ("net voorgekomen")', () async {
      final c = make();
      await c.successOccurred(SuccessMoment.planShared);
      clock.advance(reviewConfig.successFreshWindow + const Duration(minutes: 1));
      expect(c.hasFreshMoment, isFalse);
      expect((await c.maybeRequest(ReviewContext.calm)).outcome, ReviewOutcome.noMoment);
      expect(launcher.requests, 0);
    });

    test('het verzoek wordt ook geregistreerd als het systeem niets toont of weigert; nooit een fout naar buiten', () async {
      launcher.throwOnRequest = true;
      final c = make();
      await c.successOccurred(SuccessMoment.planShared);
      final r = await c.maybeRequest(ReviewContext.calm);
      expect(r.outcome, ReviewOutcome.requested);
      expect(store.history.requests, hasLength(1));
    });

    test('is de API niet beschikbaar (of gooit hij): geen verzoek, geen registratie, geen fout', () async {
      for (final mode in ['false', 'throws']) {
        store = MemoryReviewStore(seasoned(clock.now));
        launcher = FakeReviewLauncher()
          ..available = mode != 'false'
          ..throwOnAvailable = mode == 'throws';
        final c = make();
        await c.successOccurred(SuccessMoment.planShared);
        final r = await c.maybeRequest(ReviewContext.calm);
        expect(r.outcome, ReviewOutcome.blocked, reason: mode);
        expect(r.blocks, contains(ReviewBlock.systemUnavailable));
        expect(launcher.requests, 0);
        expect(store.history.requests, isEmpty);
      }
    });

    test('opslag die faalt bij het registreren gooit niets', () async {
      final c = make();
      await c.successOccurred(SuccessMoment.planShared);
      store.failSave = true;
      final r = await c.maybeRequest(ReviewContext.calm);
      expect(r.outcome, ReviewOutcome.requested);
    });

    test('twee gelijktijdige pogingen leveren één verzoek op', () async {
      final c = make();
      await c.successOccurred(SuccessMoment.planShared);
      final both = await Future.wait([c.maybeRequest(ReviewContext.calm), c.maybeRequest(ReviewContext.calm)]);
      expect(both.where((r) => r.outcome == ReviewOutcome.requested), hasLength(1));
      expect(launcher.requests, 1);
    });
  });

  group('beleid via de controller', () {
    for (final (name, history, block) in <(String, ReviewHistory Function(DateTime), ReviewBlock)>[
      ('te vroeg', (n) => ReviewHistory(firstLaunch: n.subtract(const Duration(days: 2)), sessions: 6), ReviewBlock.tooEarly),
      ('te weinig sessies', (n) => ReviewHistory(firstLaunch: n.subtract(const Duration(days: 10)), sessions: 2), ReviewBlock.tooFewSessions),
      (
        'te kort geleden',
        (n) => ReviewHistory(firstLaunch: n.subtract(const Duration(days: 300)), sessions: 6, requests: [n.subtract(const Duration(days: 30))]),
        ReviewBlock.tooSoonAfterLast,
      ),
      (
        'te vaak',
        (n) => ReviewHistory(
              firstLaunch: n.subtract(const Duration(days: 400)),
              sessions: 6,
              requests: [n.subtract(const Duration(days: 150)), n.subtract(const Duration(days: 300))],
            ),
        ReviewBlock.tooManyRequests,
      ),
      (
        'zelfde versie',
        (n) => ReviewHistory(firstLaunch: n.subtract(const Duration(days: 10)), sessions: 6, versions: ['2.0.0']),
        ReviewBlock.versionAlreadyAsked,
      ),
    ]) {
      test('$name: geen verzoek', () async {
        store = MemoryReviewStore(history(clock.now));
        final c = make();
        await c.successOccurred(SuccessMoment.planShared);
        final r = await c.maybeRequest(ReviewContext.calm);
        expect(r.outcome, ReviewOutcome.blocked);
        expect(r.blocks, contains(block));
        expect(launcher.requests, 0);
        expect(store.history.requests.length, history(clock.now).requests.length, reason: 'niets nieuws geregistreerd');
      });
    }
  });

  group('uitgesloten contexten', () {
    test('in geen enkele uitgesloten context wordt gevraagd, en het moment blijft staan voor een rustiger moment', () async {
      final c = make();
      await c.successOccurred(SuccessMoment.planShared);
      for (final ctx in ReviewContext.values.where((x) => x != ReviewContext.calm)) {
        final r = await c.maybeRequest(ctx);
        expect(r.outcome, ReviewOutcome.blocked, reason: '$ctx');
        expect(r.blocks, {ReviewBlock.excludedContext}, reason: '$ctx');
      }
      expect(launcher.requests, 0);
      expect(c.hasFreshMoment, isTrue);
      // Terug op het dashboard mag het wel.
      expect((await c.maybeRequest(ReviewContext.calm)).outcome, ReviewOutcome.requested);
      expect(launcher.requests, 1);
    });
  });

  group('succesmomenten: elk maar één keer als aanleiding', () {
    // Ontspannen drempels, zodat alleen de regel "een moment één keer" nog bepaalt of er gevraagd wordt.
    const lax = ReviewConfig(minDaysBetweenRequests: 0, maxRequestsInWindow: 99);

    for (final m in SuccessMoment.values) {
      test('${m.id}: na een verzoek telt dit moment niet nog eens als aanleiding', () async {
        var version = '1.0.0';
        final c = make(config: lax, version: () => version);
        await c.successOccurred(m);
        expect((await c.maybeRequest(ReviewContext.calm)).outcome, ReviewOutcome.requested);
        // Zelfde moment komt opnieuw voor (nieuwe appversie, dus alleen de momentregel blokkeert).
        version = '1.1.0';
        await c.successOccurred(m);
        expect(c.hasFreshMoment, isFalse);
        expect((await c.maybeRequest(ReviewContext.calm)).outcome, ReviewOutcome.noMoment);
        expect(launcher.requests, 1);
        // Ook niet na een herstart van de app (het staat in de lokale opslag).
        final again = make(config: lax, version: () => version);
        await again.successOccurred(m);
        expect(again.hasFreshMoment, isFalse);
      });
    }

    test('een ander moment mag wel, zodra het beleid het toestaat', () async {
      var version = '1.0.0';
      final c = make(config: lax, version: () => version);
      await c.successOccurred(SuccessMoment.readiness3Days);
      await c.maybeRequest(ReviewContext.calm);
      version = '1.1.0';
      await c.successOccurred(SuccessMoment.planShared);
      expect(c.hasFreshMoment, isTrue);
      expect((await c.maybeRequest(ReviewContext.calm)).outcome, ReviewOutcome.requested);
    });

    test('standaard blijft een moment beschikbaar als het beleid het nog blokkeerde (te vroeg), en telt het later wel', () async {
      store = MemoryReviewStore(ReviewHistory(firstLaunch: clock.now.subtract(const Duration(days: 1)), sessions: 1));
      final c = make();
      await c.successOccurred(SuccessMoment.planShared);
      expect((await c.maybeRequest(ReviewContext.calm)).outcome, ReviewOutcome.blocked);
      expect(store.history.usedMoments, isEmpty, reason: 'nog niet gebruikt: er is niets gevraagd');
      // Twee weken later: dezelfde actie (opnieuw delen) is weer een aanleiding.
      clock.advance(const Duration(days: 14));
      for (var i = 0; i < 7; i++) {
        await c.onAppStart(); // sessies tellen zoals de app dat doet
      }
      await c.successOccurred(SuccessMoment.planShared);
      expect((await c.maybeRequest(ReviewContext.calm)).outcome, ReviewOutcome.requested);
    });

    test('met spendMomentWhenBlocked telt een moment meteen als gebruikt (strenger)', () async {
      store = MemoryReviewStore(ReviewHistory(firstLaunch: clock.now.subtract(const Duration(days: 1)), sessions: 1));
      final c = make(config: const ReviewConfig(spendMomentWhenBlocked: true));
      await c.successOccurred(SuccessMoment.planShared);
      expect(store.history.usedMoments, {'plan_shared'});
      await c.maybeRequest(ReviewContext.calm);
      clock.advance(const Duration(days: 14));
      for (var i = 0; i < 7; i++) {
        await c.onAppStart();
      }
      await c.successOccurred(SuccessMoment.planShared);
      expect(c.hasFreshMoment, isFalse);
    });
  });
}
