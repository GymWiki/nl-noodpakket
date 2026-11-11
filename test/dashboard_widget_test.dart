import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/app.dart';
import 'package:mijnnoodpakket/core/format.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/core/providers.dart';
import 'package:mijnnoodpakket/data/repositories/settings_repository.dart';
import 'package:mijnnoodpakket/domain/expiry.dart';
import 'package:mijnnoodpakket/domain/models.dart';
import 'package:mijnnoodpakket/features/dashboard/dashboard_cards.dart';
import 'package:mijnnoodpakket/features/dashboard/dashboard_providers.dart';
import 'package:mijnnoodpakket/features/dashboard/dashboard_screen.dart';
import 'package:mijnnoodpakket/features/dashboard/domain/readiness.dart';
import 'package:mijnnoodpakket/features/dashboard/domain/maintenance.dart';
import 'package:mijnnoodpakket/features/dashboard/domain/seasonal.dart';
import 'package:mijnnoodpakket/features/dashboard/domain/suggestions.dart';
import 'package:mijnnoodpakket/features/kluis/data/vault_controller.dart';
import 'package:mijnnoodpakket/features/more/more_screen.dart';
import 'package:mijnnoodpakket/features/more/my_plan_screen.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_models.dart';
import 'package:mijnnoodpakket/features/noodplan/plan_providers.dart';

Item item(
  String id, {
  Coverage coverage = Coverage.none,
  ItemPriority priority = ItemPriority.aanvullend,
  bool inHouse = false,
  double? have,
  DateTime? expiry,
}) =>
    Item(
      id: id,
      isCustom: false,
      hidden: false,
      name: id,
      category: Cat.other,
      why: '',
      unit: 'stuks',
      recommended: 1,
      inHouse: inHouse,
      quantityHave: have,
      expiryDate: expiry,
      priority: priority,
      coverage: coverage,
    );

final now = DateTime(2026, 11, 11, 12);

List<Override> overrides(List<Item> items,
        {AppSettings settings = const AppSettings(onboarded: true), DateTime? at, bool vault = false}) =>
    [
      allItemsProvider.overrideWithValue(AsyncValue.data(items)),
      visibleItemsProvider.overrideWithValue(AsyncValue.data(items)),
      settingsProvider.overrideWith((ref) => Stream.value(settings)),
      planProvider.overrideWith((ref) => Stream.value(const Plan())),
      vaultHasDocsProvider.overrideWith((ref) => Stream.value(vault)),
      vaultDocCountProvider.overrideWith((ref) => Stream.value(vault ? 2 : null)),
      dashNowProvider.overrideWithValue(at ?? now),
    ];

Widget wrap(Widget child, List<Override> o, {double scale = 1}) => ProviderScope(
      overrides: o,
      child: MaterialApp(
        locale: const Locale('nl', 'NL'),
        supportedLocales: const [Locale('nl', 'NL')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (c, w) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: w!,
        ),
        home: child,
      ),
    );

Future<void> tall(WidgetTester t, {double w = 400, double h = 3000}) async {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

DashboardData data({
  bool hasItems = true,
  List<Item> items = const [],
  DateTime? at,
}) {
  final d = at ?? now;
  return DashboardData(
    hasItems: hasItems,
    readiness: computeReadiness(items, const Household(), d),
    suggestions: const [],
    expiring: const [],
    seasonal: seasonalFor(d),
    maintenanceDue: const [],
    simpleStart: false,
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('nl_NL'));

  final full = [
    item('water', coverage: Coverage.water, inHouse: true, have: 9, priority: ItemPriority.kritiek),
    item('food', coverage: Coverage.food, inHouse: true, have: 9, priority: ItemPriority.kritiek),
    item('radio', inHouse: true, priority: ItemPriority.kritiek),
    item('torch', priority: ItemPriority.kritiek),
    item('old', coverage: Coverage.food, inHouse: true, have: 3, expiry: DateTime(2026, 11, 1)),
    item('soon', inHouse: true, expiry: DateTime(2026, 11, 25)),
  ];

  group('kaartenregistry', () {
    test('noodbalk en paraatheid zijn er altijd', () {
      final ids = visibleCards(data(hasItems: false)).map((c) => c.id);
      expect(ids, containsAll(['emergency', 'readiness']));
      expect(ids, isNot(contains('next')));
      expect(ids, isNot(contains('allgood')));
      expect(ids, isNot(contains('expiring')));
      expect(ids, isNot(contains('seasonal')));
      expect(ids, isNot(contains('maintenance')));
    });

    test('volgorde op prioriteit; noodbalk eerst', () {
      final ids = visibleCards(data()).map((c) => c.id).toList();
      expect(ids.first, 'emergency');
      expect(ids.indexOf('readiness'), lessThan(ids.indexOf('planvault')));
    });

    test('maximaal zes kaarten naast de noodbalk; laagste prioriteit valt af', () {
      final all = [
        for (var i = 0; i < 9; i++)
          DashCard(id: 'c$i', priority: i + 1, isVisible: (_) => true, build: (_) => const SizedBox()),
        DashCard(id: 'bar', priority: 0, slim: true, isVisible: (_) => true, build: (_) => const SizedBox()),
      ];
      final v = visibleCards(data(), registry: all);
      expect(v.length, maxDashCards + 1);
      expect(v.map((c) => c.id), isNot(contains('c8')));
      expect(v.first.id, 'bar');
    });

    test('echte registry blijft binnen het maximum', () {
      final d = DashboardData(
        hasItems: true,
        readiness: computeReadiness(full, const Household(), now),
        suggestions: const [Suggestion(id: 'x', kind: SuggestionKind.household, route: '/')],
        expiring: [(item: full[4], due: DateTime(2026, 11, 1), status: ExpiryStatus.expired)],
        seasonal: seasonalFor(DateTime(2026, 12, 3)),
        maintenanceDue: const [Routine('rookmelder', 1)],
        simpleStart: false,
      );
      expect(visibleCards(d).where((c) => !c.slim).length, lessThanOrEqualTo(maxDashCards));
    });

    test('seizoenskaart alleen in het seizoen', () {
      expect(visibleCards(data(at: DateTime(2026, 11, 11))).map((c) => c.id), isNot(contains('seasonal')));
      expect(visibleCards(data(at: DateTime(2026, 12, 3))).map((c) => c.id), contains('seasonal'));
      expect(visibleCards(data(at: DateTime(2027, 1, 20))).map((c) => c.id), contains('seasonal'));
    });
  });

  group('startscherm', () {
    testWidgets('volledige data: alle belangrijke kaarten', (t) async {
      await tall(t);
      await t.pumpWidget(wrap(const DashboardScreen(), overrides(full, vault: true)));
      await t.pumpAndSettle();
      expect(find.text(S.dashCall112), findsOneWidget);
      expect(find.text(S.homeFirstHour), findsOneWidget);
      expect(find.text(S.dashReadyTitle), findsOneWidget);
      // 9 liter en 9 maaltijden voor 1 persoon = 3 dagen.
      expect(find.text(S.dashReadyDays('3')), findsOneWidget);
      expect(find.text(S.dashReadyGoal), findsOneWidget);
      expect(find.text(S.dashReadyHow), findsOneWidget);
      expect(find.text(S.dashReadyEstimate), findsOneWidget);
      expect(find.text(S.dashNextTitle), findsOneWidget);
      expect(find.text(S.dashExpiringTitle), findsOneWidget);
      expect(find.text(S.dashPlanCard), findsOneWidget);
      expect(find.text(S.dashVaultCard), findsOneWidget);
      expect(find.text(S.vaultFreeCounter(2)), findsOneWidget);
      expect(find.text(S.dashRemindHint), findsOneWidget);
      expect(find.text(S.dashHouseholdTitle), findsOneWidget);
      expect(find.text(S.dashExpiredOn(fmtDate(DateTime(2026, 11, 1)))), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('lege staat: vriendelijk, geen rode "0 dagen"', (t) async {
      await tall(t);
      await t.pumpWidget(wrap(const DashboardScreen(), overrides(const [])));
      await t.pumpAndSettle();
      expect(find.text(S.dashReadyEmpty), findsOneWidget);
      expect(find.text(S.dashReadyEmptySub), findsOneWidget);
      expect(find.textContaining('0 van de 3'), findsNothing);
      expect(find.text(S.dashReadyHow), findsNothing);
      expect(find.text(S.dashAllGoodLine), findsNothing);
    });

    testWidgets('één kaart: alleen water ingevuld geeft een duidelijke volgende stap', (t) async {
      await tall(t);
      final only = [item('water', coverage: Coverage.water, inHouse: true, have: 3)];
      await t.pumpWidget(wrap(const DashboardScreen(), overrides(only, vault: true)));
      await t.pumpAndSettle();
      // 3 liter voor 1 persoon = 1 dag.
      expect(find.text(S.dashReadyDays('1')), findsOneWidget);
      expect(find.text(S.dashSugWaterFewT('1')), findsOneWidget);
      expect(find.text(S.dashExpiringTitle), findsNothing);
    });

    testWidgets('alles op orde: korte regel in plaats van suggesties', (t) async {
      await tall(t);
      final ok = [
        item('water', coverage: Coverage.water, inHouse: true, have: 9),
        item('food', coverage: Coverage.food, inHouse: true, have: 9),
      ];
      final o = overrides(ok,
          vault: true,
          settings: const AppSettings(onboarded: true, raw: {
            'nlalert_done': '2026-11-01',
            'maint_anchor': '2026-11-01',
            'dash_dismissed': '["plan"]',
          }));
      await t.pumpWidget(wrap(const DashboardScreen(), o));
      await t.pumpAndSettle();
      expect(find.text(S.dashAllGoodLine), findsOneWidget);
      expect(find.text(S.dashNextTitle), findsNothing);
    });

    testWidgets('"Hoe is dit berekend?" opent uitleg met de aannames', (t) async {
      await tall(t);
      await t.pumpWidget(wrap(const DashboardScreen(), overrides(full, vault: true)));
      await t.pumpAndSettle();
      await t.tap(find.text(S.dashReadyHow));
      await t.pumpAndSettle();
      expect(find.text(S.dashHowTitle), findsOneWidget);
      expect(find.textContaining('3 liter per persoon per dag'), findsOneWidget);
      expect(find.text(S.dashHowExcluded(1)), findsOneWidget);
    });

    testWidgets('200% tekstgrootte: geen overflow', (t) async {
      await tall(t, w: 360, h: 800);
      await t.pumpWidget(wrap(const DashboardScreen(), overrides(full, vault: true), scale: 2));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      // ook onderaan de lijst
      await t.drag(find.byType(ListView), const Offset(0, -3000));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('200% tekstgrootte in de lege staat en de Eenvoudige start', (t) async {
      await tall(t, w: 360, h: 800);
      await t.pumpWidget(wrap(const DashboardScreen(), overrides(const []), scale: 2));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.pumpWidget(wrap(const SimpleStart(), overrides(const []), scale: 2));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('Semantics: 112, paraatheid en kaarten hebben een label', (t) async {
      final h = t.ensureSemantics();
      await tall(t);
      await t.pumpWidget(wrap(const DashboardScreen(), overrides(full, vault: true)));
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('^${S.dashCall112}')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('ongeveer 3 van de 3')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('^${S.dashPlanCard}[.]')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^${S.dashHouseholdTitle}')), findsOneWidget);
      h.dispose();
    });

    testWidgets('Eenvoudige start: vier grote knoppen', (t) async {
      await tall(t);
      final o = overrides(full, settings: const AppSettings(onboarded: true, simpleStart: true));
      await t.pumpWidget(wrap(const DashboardScreen(), o));
      await t.pumpAndSettle();
      for (final s in [S.navChecklist, S.navWiki, S.navPlan, S.dashCall112]) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
      expect(find.text(S.dashReadyTitle), findsNothing);
    });
  });

  group('navigatie', () {
    Future<GoRouter> boot(WidgetTester t, {AppSettings? settings}) async {
      await tall(t, w: 400, h: 900);
      late GoRouter router;
      await t.pumpWidget(ProviderScope(
        overrides: overrides(full, settings: settings ?? const AppSettings(onboarded: true)),
        child: Consumer(builder: (c, ref, _) {
          router = ref.watch(routerProvider);
          return MaterialApp.router(
            routerConfig: router,
            locale: const Locale('nl', 'NL'),
            supportedLocales: const [Locale('nl', 'NL')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
          );
        }),
      ));
      await t.pumpAndSettle();
      return router;
    }

    testWidgets('Start is de standaardroute na het opstarten', (t) async {
      final r = await boot(t);
      expect(r.routeInformationProvider.value.uri.path, '/start');
      expect(find.text(S.dashReadyTitle), findsOneWidget);
    });

    testWidgets('vijf tabs in de juiste volgorde', (t) async {
      await boot(t);
      final bar = t.widget<NavigationBar>(find.byType(NavigationBar));
      final labels = bar.destinations.map((d) => (d as NavigationDestination).label).toList();
      expect(labels, [S.navHome, S.navChecklist, S.navWiki, S.navPlan, S.navMore]);
    });

    testWidgets('tabs openen hun scherm', (t) async {
      final r = await boot(t);
      await t.tap(find.text(S.navPlan).last);
      await t.pumpAndSettle();
      expect(r.routeInformationProvider.value.uri.path, '/mijn-plan');
      expect(find.byType(MyPlanScreen), findsOneWidget);
      expect(find.text(S.vaultTitle), findsOneWidget);
      await t.tap(find.text(S.navMore).last);
      await t.pumpAndSettle();
      expect(find.text(S.infoTitle), findsOneWidget);
      expect(find.text(S.settingsTitle), findsOneWidget);
    });

    testWidgets('diepe links blijven werken', (t) async {
      final r = await boot(t);
      r.go('/checklist?tab=vervangen');
      await t.pumpAndSettle();
      expect(r.routeInformationProvider.value.uri.toString(), '/checklist?tab=vervangen');
      r.go('/start/nl-alert');
      await t.pumpAndSettle();
      expect(find.text(S.nlTitle), findsWidgets);
      r.go('/start/onderhoud');
      await t.pumpAndSettle();
      expect(find.text(S.maintRookmelder), findsOneWidget);
      r.go('/plan');
      await t.pumpAndSettle();
      expect(r.routeInformationProvider.value.uri.path, '/plan');
    });

    testWidgets('niet onboarded: naar onboarding, niet naar Start', (t) async {
      final r = await boot(t, settings: const AppSettings());
      expect(r.routeInformationProvider.value.uri.path, '/onboarding');
    });
  });

  testWidgets('Meer: onderhoud, informatie en instellingen (noodplan en kluis staan bij Mijn plan)', (t) async {
    await t.pumpWidget(wrap(const MoreScreen(), const []));
    await t.pumpAndSettle();
    for (final s in [S.maintTitle, S.infoTitle, S.settingsTitle]) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
    expect(find.text(S.vaultTitle), findsNothing);
  });
}
