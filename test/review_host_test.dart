import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mijnnoodpakket/core/providers.dart';
import 'package:mijnnoodpakket/data/repositories/settings_repository.dart';
import 'package:mijnnoodpakket/domain/models.dart';
import 'package:mijnnoodpakket/features/dashboard/dashboard_providers.dart';
import 'package:mijnnoodpakket/features/dashboard/domain/readiness.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_models.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_progress.dart';
import 'package:mijnnoodpakket/features/noodplan/plan_providers.dart';
import 'package:mijnnoodpakket/features/review/review_config.dart';
import 'package:mijnnoodpakket/features/review/review_controller.dart';
import 'package:mijnnoodpakket/features/review/review_host.dart';
import 'package:mijnnoodpakket/features/review/review_models.dart';
import 'package:mijnnoodpakket/features/review/review_overlay.dart';
import 'package:mijnnoodpakket/features/review/review_providers.dart';

import 'review_fakes.dart';

class _Days extends Notifier<double> {
  _Days(this.start);
  final double start;
  @override
  double build() => start;
  void set(double v) => state = v;
}

class _Flag extends Notifier<bool> {
  _Flag(this.start);
  final bool start;
  @override
  bool build() => start;
  void set(bool v) => state = v;
}

Readiness readiness(double days) => Readiness(
      persons: 2,
      waterLiters: 0,
      waterDays: days,
      foodMeals: 0,
      foodDays: days,
      days: days,
      hasInput: true,
      needsQuantities: false,
      excluded: 0,
      completeness: 0.5,
    );

PlanProgress progress(bool complete) => PlanProgress({
      for (final s in PlanSection.values) s: complete ? SectionStatus.done : SectionStatus.empty,
    });

void main() {
  late TestClock clock;
  late MemoryReviewStore store;
  late FakeReviewLauncher launcher;
  late ReviewController ctl;
  late ReviewOverlayObserver overlay;
  late ValueNotifier<String> loc;
  late NotifierProvider<_Days, double> daysProvider;
  late NotifierProvider<_Flag, bool> planDoneProvider;

  final calmDelay = reviewConfig.calmDelay;

  Future<ProviderContainer> pumpHost(
    WidgetTester t, {
    String location = '/start',
    double startDays = 1,
    bool startPlanDone = false,
    bool dataLoaded = true,
  }) async {
    clock = TestClock(DateTime(2026, 11, 20, 12));
    store = MemoryReviewStore(seasoned(clock.now));
    launcher = FakeReviewLauncher();
    ctl = buildController(clock: clock, store: store, launcher: launcher);
    overlay = ReviewOverlayObserver();
    loc = ValueNotifier(location);
    daysProvider = NotifierProvider<_Days, double>(() => _Days(startDays));
    planDoneProvider = NotifierProvider<_Flag, bool>(() => _Flag(startPlanDone));
    final overrides = <Override>[
      reviewControllerProvider.overrideWithValue(ctl),
      reviewOverlayObserverProvider.overrideWithValue(overlay),
      readinessProvider.overrideWith((ref) => readiness(ref.watch(daysProvider))),
      planProgressProvider.overrideWith((ref) => progress(ref.watch(planDoneProvider))),
      allItemsProvider.overrideWithValue(dataLoaded ? const AsyncValue.data(<Item>[]) : const AsyncValue.loading()),
      settingsProvider.overrideWith((ref) => Stream.value(const AppSettings())),
      planProvider.overrideWith((ref) => Stream.value(const Plan())),
    ];
    await t.pumpWidget(ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: ReviewHost(routeChanges: loc, location: () => loc.value, child: const Scaffold(body: Text('dashboard'))),
      ),
    ));
    await t.pump(); // streams leveren hun eerste waarde
    await t.pump();
    return ProviderScope.containerOf(t.element(find.byType(ReviewHost)));
  }

  testWidgets('elke start van de app telt één sessie en onthoudt de eerste start', (t) async {
    await pumpHost(t);
    expect(store.history.sessions, 7); // 6 uit de fixture + deze start
    expect(store.history.firstLaunch, clock.now.subtract(const Duration(days: 10)));
  });

  group('timing: alleen op een rustig scherm, met vertraging, op de voorgrond', () {
    testWidgets('na een succesmoment op het dashboard: pas na de vertraging, dan precies één verzoek', (t) async {
      await pumpHost(t);
      await ctl.successOccurred(SuccessMoment.planShared);
      await t.pump(calmDelay - const Duration(seconds: 1));
      expect(launcher.requests, 0, reason: 'nog niet: een paar seconden vertraging');
      await t.pump(const Duration(seconds: 2));
      expect(launcher.requests, 1);
      await t.pump(const Duration(seconds: 30));
      expect(launcher.requests, 1, reason: 'één keer, niet herhaald');
      expect(store.history.requests, hasLength(1));
    });

    testWidgets('een korte vertraging van enkele seconden is ingesteld', (t) async {
      expect(calmDelay.inSeconds, inInclusiveRange(2, 10));
    });

    testWidgets('midden in een taak (ander scherm): niet vragen; terug op het dashboard: wel, na de vertraging', (t) async {
      await pumpHost(t, location: '/plan/wizard');
      await ctl.successOccurred(SuccessMoment.planComplete);
      await t.pump(const Duration(seconds: 60));
      expect(launcher.requests, 0);
      loc.value = '/start';
      await t.pump(calmDelay - const Duration(seconds: 1));
      expect(launcher.requests, 0);
      await t.pump(const Duration(seconds: 2));
      expect(launcher.requests, 1);
    });

    testWidgets('verlaat de gebruiker het dashboard tijdens de wachttijd, dan stopt de teller', (t) async {
      await pumpHost(t);
      await ctl.successOccurred(SuccessMoment.planShared);
      await t.pump(const Duration(seconds: 2));
      loc.value = '/checklist';
      await t.pump(const Duration(seconds: 30));
      expect(launcher.requests, 0);
      loc.value = '/start'; // terug: de teller begint opnieuw
      await t.pump(calmDelay + const Duration(seconds: 1));
      expect(launcher.requests, 1);
    });

    testWidgets('een dialoog of blad (ook de paywall of het bevestigingsscherm) onderbreekt: niet vragen tot het dicht is', (t) async {
      await pumpHost(t);
      overlay.open.value = 1; // een blad staat open
      await ctl.successOccurred(SuccessMoment.planShared);
      await t.pump(const Duration(seconds: 60));
      expect(launcher.requests, 0);
      overlay.open.value = 0;
      await t.pump(calmDelay + const Duration(seconds: 1));
      expect(launcher.requests, 1);
    });

    testWidgets('app op de achtergrond: niet vragen; weer op de voorgrond: wel, na de vertraging', (t) async {
      await pumpHost(t);
      await ctl.successOccurred(SuccessMoment.planShared);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump(const Duration(seconds: 60));
      expect(launcher.requests, 0);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump(calmDelay - const Duration(seconds: 1));
      expect(launcher.requests, 0);
      await t.pump(const Duration(seconds: 2));
      expect(launcher.requests, 1);
    });

    testWidgets('wordt de app tijdens de wachttijd naar de achtergrond gebracht, dan komt er geen verzoek', (t) async {
      await pumpHost(t);
      await ctl.successOccurred(SuccessMoment.planShared);
      await t.pump(const Duration(seconds: 2));
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await t.pump(const Duration(seconds: 30));
      expect(launcher.requests, 0);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
  });

  group('nooit vragen in een uitgesloten context', () {
    const excluded = <String, String>{
      '/noodmodus': 'noodmodus',
      '/wiki/stroomstoring/stappen': 'noodgeval-stappenplan, stap-voor-stap',
      '/hacks/water-koken/stappen': 'hack-stappenplan, stap-voor-stap',
      '/wiki/stroomstoring': 'wiki',
      '/noodgevallen': 'wiki-overzicht met de Eerste-uur kaart',
      '/hacks/pakket-op': 'Eerste-uur kaart',
      '/kluis': 'kluis',
      '/kluis/toevoegen': 'document toevoegen',
      '/kluis/doc/abc': 'document bekijken',
      '/delen/documenten': 'documenten delen',
      '/plan/wizard': 'midden in een taak',
      '/start/suggesties': 'subscherm van het dashboard',
    };

    for (final e in excluded.entries) {
      testWidgets('${e.key} (${e.value})', (t) async {
        await pumpHost(t, location: e.key);
        await ctl.successOccurred(SuccessMoment.planShared);
        await t.pump(const Duration(minutes: 5));
        expect(launcher.requests, 0);
        expect(launcher.calls, isEmpty, reason: 'zelfs de beschikbaarheidscontrole gebeurt hier niet');
      });
    }

    testWidgets('paywall of bevestigingsscherm van een aankoop (een blad boven het dashboard)', (t) async {
      await pumpHost(t, location: '/start');
      overlay.open.value = 1;
      await ctl.successOccurred(SuccessMoment.planShared);
      await t.pump(const Duration(minutes: 5));
      expect(launcher.requests, 0);
    });
  });

  group('succesmomenten', () {
    testWidgets('de Paraatheid haalt voor het eerst 3 dagen of meer', (t) async {
      final c = await pumpHost(t, startDays: 1.2);
      c.read(daysProvider.notifier).set(3.1);
      await t.pump();
      expect(ctl.hasFreshMoment, isTrue);
      await t.pump(calmDelay + const Duration(seconds: 1));
      expect(launcher.requests, 1);
      expect(store.history.usedMoments, {'readiness_3_days'});
    });

    testWidgets('wie het doel al had bij het laden, krijgt daar geen verzoek voor (alleen een echte overgang telt)', (t) async {
      await pumpHost(t, startDays: 3.4);
      expect(ctl.hasFreshMoment, isFalse);
      await t.pump(const Duration(minutes: 1));
      expect(launcher.requests, 0);
    });

    testWidgets('onder de 3 dagen blijft een gewone wijziging zonder gevolg', (t) async {
      final c = await pumpHost(t, startDays: 1);
      c.read(daysProvider.notifier).set(2.9);
      await t.pump();
      expect(ctl.hasFreshMoment, isFalse);
    });

    testWidgets('het noodplan is volledig ingevuld', (t) async {
      final c = await pumpHost(t);
      c.read(planDoneProvider.notifier).set(true);
      await t.pump();
      expect(ctl.hasFreshMoment, isTrue);
      await t.pump(calmDelay + const Duration(seconds: 1));
      expect(launcher.requests, 1);
      expect(store.history.usedMoments, {'plan_complete'});
    });

    testWidgets('een noodplan dat al volledig was bij het laden telt niet als succes', (t) async {
      await pumpHost(t, startPlanDone: true);
      expect(ctl.hasFreshMoment, isFalse);
    });

    testWidgets('het noodplan is gedeeld (pdf, tekst of QR): een melding vanuit het deelscherm is genoeg', (t) async {
      await pumpHost(t);
      await ctl.successOccurred(SuccessMoment.planShared);
      expect(ctl.hasFreshMoment, isTrue);
      await t.pump(calmDelay + const Duration(seconds: 1));
      expect(launcher.requests, 1);
      expect(store.history.usedMoments, {'plan_shared'});
    });

    testWidgets('zolang de gegevens nog laden, tellen overgangen niet mee', (t) async {
      final c = await pumpHost(t, startDays: 1, dataLoaded: false);
      c.read(daysProvider.notifier).set(3.5);
      await t.pump();
      expect(ctl.hasFreshMoment, isFalse);
    });

    testWidgets('alle drie de momenten kunnen niet meer dan één verzoek per periode opleveren (het beleid blijft gelden)', (t) async {
      final c = await pumpHost(t, startDays: 1);
      c.read(daysProvider.notifier).set(3.2);
      await t.pump(calmDelay + const Duration(seconds: 1));
      expect(launcher.requests, 1);
      c.read(planDoneProvider.notifier).set(true);
      await ctl.successOccurred(SuccessMoment.planShared);
      await t.pump(calmDelay + const Duration(seconds: 5));
      expect(launcher.requests, 1, reason: 'te kort geleden en dezelfde appversie');
    });
  });

  testWidgets('geen openstaande timers na het sluiten van de app', (t) async {
    await pumpHost(t);
    await ctl.successOccurred(SuccessMoment.planShared);
    await t.pump(const Duration(seconds: 1));
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 30));
    expect(launcher.requests, 0);
  });
}
