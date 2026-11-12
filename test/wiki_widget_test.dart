import 'dart:io';

import 'package:mijnnoodpakket/features/rampenzender/rampenzender_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/features/deel/deel_providers.dart';
import 'package:mijnnoodpakket/features/deel/domain/shared_plan_logic.dart';
import 'package:mijnnoodpakket/features/pro/pro_providers.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/core/providers.dart';
import 'package:mijnnoodpakket/domain/models.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_models.dart';
import 'package:mijnnoodpakket/features/noodplan/plan_providers.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_detail_screen.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_models.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_overview_screen.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_pdf.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_providers.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_steps_screen.dart';

class FakePrefs implements WikiPrefs {
  final toggled = <String>[];
  final saved = <String, WikiProgress>{};
  final reset = <String>[];
  WikiProgress initial = const WikiProgress();

  @override
  Future<void> toggleFavorite(String id, Set<String> current) async => toggled.add(id);
  @override
  Future<void> saveProgress(String id, WikiProgress p) async => saved[id] = p;
  @override
  Future<void> resetProgress(String id) async => reset.add(id);
  @override
  Future<WikiProgress> loadProgress(String id) async => initial;
}

final data = WikiData.parse(File('assets/wiki/noodgevallen.json').readAsStringSync());

Item item(String id, {bool inHouse = false}) => Item(
      id: id,
      isCustom: false,
      hidden: false,
      name: 'Item $id',
      category: Cat.info,
      why: '',
      unit: 'stuks',
      recommended: 1,
      inHouse: inHouse,
    );

Future<void> pump(WidgetTester t, FakePrefs prefs, String start,
    {Set<String> favs = const {}}) async {
  t.view.physicalSize = const Size(800, 3000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final router = GoRouter(initialLocation: start, routes: [
    GoRoute(path: '/noodgevallen', builder: (_, _) => const WikiOverviewScreen()),
    GoRoute(
      path: '/wiki/:id',
      builder: (_, s) => WikiDetailScreen(id: s.pathParameters['id']!),
      routes: [
        GoRoute(
            path: 'stappen',
            builder: (_, s) => WikiStepsScreen(id: s.pathParameters['id']!)),
      ],
    ),
    GoRoute(path: '/item/:id', builder: (_, s) => Scaffold(body: Text('item ${s.pathParameters['id']}'))),
  ]);
  final List<Override> overrides = [
    wikiProvider.overrideWith((ref) async => data),
    wikiFavoritesProvider.overrideWith((ref) => Stream.value(favs)),
    wikiPrefsProvider.overrideWithValue(prefs),
    proUnlockedProvider.overrideWithValue(false),
    radioPrefsProvider.overrideWithValue(const RadioPrefs()),
    planProvider.overrideWith((ref) => Stream.value(const Plan())),
    sharedPlansProvider.overrideWith((ref) => Stream.value(const <SharedPlan>[])),
    allItemsProvider.overrideWithValue(
        AsyncValue.data([item('radio', inHouse: true), item('batteries'), item('flashlight')])),
  ];
  await t.pumpWidget(ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('nl', 'NL'),
      supportedLocales: const [Locale('nl', 'NL')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    ),
  ));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('nl_NL'));

  group('overzicht', () {
    testWidgets('toont Bel 112, regel, disclaimer, Eerste-uur kaart en categorieën', (t) async {
      await pump(t, FakePrefs(), '/noodgevallen');
      expect(find.text(S.wikiCall112), findsOneWidget);
      expect(find.text(S.wikiRule), findsOneWidget);
      expect(find.text(S.disclaimer), findsOneWidget);
      expect(find.text('Eerste-uur kaart'), findsOneWidget);
      for (final c in data.categories) {
        expect(find.text(c.titel), findsOneWidget, reason: c.id);
      }
    });

    testWidgets('zoeken op trefwoord toont alleen passende noodgevallen', (t) async {
      await pump(t, FakePrefs(), '/noodgevallen');
      await t.enterText(find.byType(TextField), 'blackout');
      await t.pumpAndSettle();
      expect(find.text('Stroomstoring'), findsOneWidget);
      expect(find.text('Brand in huis'), findsNothing);
      expect(find.text('Eerste-uur kaart'), findsNothing);
    });

    testWidgets('zoeken zonder resultaat toont melding', (t) async {
      await pump(t, FakePrefs(), '/noodgevallen');
      await t.enterText(find.byType(TextField), 'zzzzz');
      await t.pumpAndSettle();
      expect(find.text(S.wikiNoResults), findsOneWidget);
    });

    testWidgets('favoriet pinnen en favorieten bovenaan', (t) async {
      final prefs = FakePrefs();
      await pump(t, prefs, '/noodgevallen', favs: {'gaslucht'});
      expect(find.text(S.wikiFavorites), findsOneWidget);
      await t.enterText(find.byType(TextField), 'storm');
      await t.pumpAndSettle();
      await t.tap(find.byIcon(Icons.star_border_rounded).first);
      await t.pump();
      expect(prefs.toggled, isNotEmpty);
    });

    testWidgets('categorie uitklappen en naar detail navigeren', (t) async {
      await pump(t, FakePrefs(), '/noodgevallen');
      await t.tap(find.text('Uitval van voorzieningen'));
      await t.pumpAndSettle();
      await t.tap(find.text('Stroomstoring'));
      await t.pumpAndSettle();
      expect(find.text(S.wikiNow), findsOneWidget);
    });
  });

  group('detail', () {
    testWidgets('toont secties, voorbereiden-status en bron', (t) async {
      await pump(t, FakePrefs(), '/wiki/stroomstoring');
      expect(find.text(S.wikiNow), findsOneWidget);
      expect(find.text(S.wikiPrepare), findsOneWidget);
      expect(find.textContaining(S.wikiPrepareHave), findsOneWidget); // radio in huis
      expect(find.textContaining(S.wikiPrepareNeed), findsWidgets);
      expect(find.text(S.wikiSources), findsOneWidget);
      expect(find.textContaining('Laatst gecontroleerd'), findsOneWidget);
    });

    testWidgets('tik op voorbereid item gaat naar het checklist-item', (t) async {
      await pump(t, FakePrefs(), '/wiki/stroomstoring');
      await t.tap(find.text('Item radio'));
      await t.pumpAndSettle();
      expect(find.text('item radio'), findsOneWidget);
    });
  });

  group('stap-voor-stap', () {
    final steps = data.byId('stroomstoring')!.alleStappen;

    testWidgets('toont één stap, voortgang en navigeert', (t) async {
      final prefs = FakePrefs();
      await pump(t, prefs, '/wiki/stroomstoring/stappen');
      expect(find.textContaining(S.wikiStepOf(1, steps.length)), findsOneWidget);
      expect(find.text(steps[0]), findsOneWidget);
      expect(find.text(steps[1]), findsNothing);

      await t.tap(find.text(S.wikiNext));
      await t.pumpAndSettle();
      expect(find.text(steps[1]), findsOneWidget);
      expect(prefs.saved['stroomstoring']!.current, 1);

      await t.tap(find.text(S.wikiPrev));
      await t.pumpAndSettle();
      expect(find.text(steps[0]), findsOneWidget);
    });

    testWidgets('vorige is uit bij eerste stap; afvinken wordt bewaard', (t) async {
      final prefs = FakePrefs();
      await pump(t, prefs, '/wiki/stroomstoring/stappen');
      final prev = t.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, S.wikiPrev));
      expect(prev.onPressed, isNull);
      await t.tap(find.byType(Checkbox));
      await t.pump();
      expect(prefs.saved['stroomstoring']!.done, {0});
    });

    testWidgets('hervat op opgeslagen stap', (t) async {
      final prefs = FakePrefs()..initial = const WikiProgress(current: 2, done: {0, 1});
      await pump(t, prefs, '/wiki/stroomstoring/stappen');
      expect(find.text(steps[2]), findsOneWidget);
    });

    testWidgets('lijstweergave toont alle stappen', (t) async {
      await pump(t, FakePrefs(), '/wiki/stroomstoring/stappen');
      await t.tap(find.byTooltip(S.wikiViewList));
      await t.pumpAndSettle();
      for (var i = 0; i < steps.length; i++) {
        expect(find.text('${i + 1}. ${steps[i]}'), findsOneWidget);
      }
    });

    testWidgets('laatste stap toont Klaar', (t) async {
      final prefs = FakePrefs()..initial = WikiProgress(current: steps.length - 1);
      await pump(t, prefs, '/wiki/stroomstoring/stappen');
      expect(find.text(S.wikiFinish), findsOneWidget);
    });
  });

  test('meterkastkaart: PDF wordt gegenereerd', () async {
    final bytes = await buildMeterkastPdf(data);
    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
