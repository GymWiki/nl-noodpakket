import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/core/providers.dart';
import 'package:mijnnoodpakket/core/theme.dart';
import 'package:mijnnoodpakket/data/db/database.dart';
import 'package:mijnnoodpakket/data/repositories/settings_repository.dart';
import 'package:mijnnoodpakket/domain/models.dart';
import 'package:mijnnoodpakket/features/checklist/checklist_screen.dart';
import 'package:mijnnoodpakket/features/dashboard/dashboard_screen.dart';
import 'package:mijnnoodpakket/features/more/more_screen.dart';
import 'package:mijnnoodpakket/features/more/my_plan_screen.dart';
import 'package:mijnnoodpakket/features/rampenzender/rampenzender_strings.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_overview_screen.dart';

import 'package:mijnnoodpakket/features/noodhacks/hacks_providers.dart';
import 'package:mijnnoodpakket/features/pro/pro_providers.dart';
import 'package:mijnnoodpakket/features/rampenzender/rampenzender_providers.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_models.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_providers.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_detail_screen.dart';

import 'dashboard_widget_test.dart' show item, overrides, tall;

/// Rustig ontwerp: alles blijft bereikbaar en veiligheid blijft zichtbaar.
/// Dashboard-overrides plus alle bronnen die anders een echte database zouden openen.
List<Override> calmOverrides({AppSettings settings = const AppSettings(onboarded: true)}) => [
      ...overrides(full, settings: settings),
      databaseProvider.overrideWith((ref) {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        ref.onDispose(db.close);
        return db;
      }),
      wikiProvider.overrideWith((ref) async => _wiki),
      wikiFavoritesProvider.overrideWith((ref) => Stream.value(const <String>{})),
      hacksFavoritesProvider.overrideWith((ref) => Stream.value(const <String>{})),
      hacksMaterialsProvider.overrideWith((ref) => Stream.value(const <String>{})),
      radioPrefsProvider.overrideWithValue(const RadioPrefs()),
      proUnlockedProvider.overrideWithValue(false),
    ];

final _wiki = WikiData.parse(File('assets/wiki/noodgevallen.json').readAsStringSync());

final full = [
  item('water', coverage: Coverage.water, inHouse: true, have: 9, priority: ItemPriority.kritiek),
  item('food', coverage: Coverage.food, inHouse: true, have: 9, priority: ItemPriority.kritiek),
  item('radio', inHouse: true, priority: ItemPriority.kritiek),
  item('torch'),
];

/// Begrensd wachten: schermen met een echte database of animatie komen nooit "tot rust".
Future<void> soft(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    // Echte tijd voor het laden van assets, daarna de klok van de test verder.
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await t.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('nl_NL'));

  // -------------------------------------------------------------------------
  // Bereikbaarheid: elke bestaande functie, vanaf het tabblad waar hij staat,
  // in maximaal twee tikken. Doelschermen zijn stubs die hun route tonen.
  // -------------------------------------------------------------------------
  group('bereikbaarheid (max. 2 tikken vanaf het tabblad)', () {
    const stubs = [
      '/plan', '/plan/gesprek', '/kluis', '/instellingen', '/instellingen/verborgen', '/info',
      '/start/onderhoud', '/start/suggesties', '/hacks', '/hacks/pakket-op', '/hacks/in-huis',
      '/rampenzender', '/rampenzender/kies', '/delen', '/delen/scan', '/item/new',
    ];

    Future<void> pumpTab(WidgetTester t, Widget tab) async {
      await tall(t, w: 400, h: 2600);
      final router = GoRouter(initialLocation: '/tab', routes: [
        GoRoute(path: '/tab', builder: (_, _) => tab),
        for (final p in stubs) GoRoute(path: p, builder: (_, st) => Scaffold(body: Text('STUB ${st.uri}'))),
        GoRoute(path: '/wiki/:id', builder: (_, st) => Scaffold(body: Text('STUB ${st.uri}'))),
      ]);
      await t.pumpWidget(ProviderScope(
        overrides: calmOverrides(),
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('nl', 'NL'),
          supportedLocales: const [Locale('nl', 'NL')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
      ));
      await soft(t);
    }

    Finder tapTarget(String s) => find.text(s).hitTestable().first;

    // (tabblad, functie, tikken, verwachte route)
    final cases = <(String, Widget Function(), String, List<String>, String)>[
      ('Start', () => const DashboardScreen(), 'Eerste uur', [S.homeFirstHour], '/wiki/eerste-uur'),
      ('Start', () => const DashboardScreen(), 'Noodplan', [S.dashPlanCard], '/plan'),
      ('Start', () => const DashboardScreen(), 'Kluis', [S.dashVaultCard], '/kluis'),
      ('Start', () => const DashboardScreen(), 'Huishouden', [S.dashHouseholdTitle], '/instellingen'),
      ('Noodgevallen', () => const WikiOverviewScreen(), 'Eerste-uur kaart', ['Eerste-uur kaart'], '/wiki/eerste-uur'),
      ('Noodgevallen', () => const WikiOverviewScreen(), 'Mijn pakket is op', [S.hacksIntroOut], '/hacks/pakket-op'),
      ('Noodgevallen', () => const WikiOverviewScreen(), 'Noodhacks', [S.hacksTitle], '/hacks'),
      ('Noodgevallen', () => const WikiOverviewScreen(), 'Rampenzender', [RZ.entryTitle], '/rampenzender'),
      ('Noodgevallen', () => const WikiOverviewScreen(), 'Een situatie', ['Uitval van voorzieningen', 'Stroomstoring'], '/wiki/stroomstoring'),
      ('Mijn plan', () => const MyPlanScreen(), 'Noodplan', [S.planTitle], '/plan'),
      ('Mijn plan', () => const MyPlanScreen(), 'Praat erover', [S.planTalk], '/plan/gesprek'),
      ('Mijn plan', () => const MyPlanScreen(), 'Kluis', [S.vaultTitle], '/kluis'),
      ('Mijn plan', () => const MyPlanScreen(), 'Plan delen', [S.deelTitle, S.deelSheetShare], '/delen'),
      ('Mijn plan', () => const MyPlanScreen(), 'Plan scannen', [S.deelTitle, S.scanTitle], '/delen/scan'),
      ('Meer', () => const MoreScreen(), 'Onderhoud', [S.maintTitle], '/start/onderhoud'),
      ('Meer', () => const MoreScreen(), 'Informatie', [S.infoTitle], '/info'),
      ('Meer', () => const MoreScreen(), 'Instellingen', [S.settingsTitle], '/instellingen'),
    ];

    for (final c in cases) {
      testWidgets('${c.$1}: ${c.$3} in ${c.$4.length} tik(ken)', (t) async {
        expect(c.$4.length, lessThanOrEqualTo(2));
        await pumpTab(t, c.$2());
        for (final label in c.$4) {
          await t.ensureVisible(tapTarget(label));
          await t.tap(tapTarget(label));
          await soft(t);
        }
        expect(find.text('STUB ${c.$5}'), findsOneWidget, reason: 'na ${c.$4}');
      });
    }

    testWidgets('Pakket: toevoegen in 1 tik en Vervangen in 1 tik', (t) async {
      await pumpTab(t, const ChecklistScreen());
      await t.tap(find.text(S.segReplace));
      await soft(t);
      expect(find.text(S.replaceEmpty), findsWidgets);
      await t.tap(find.text(S.segList));
      await soft(t);
      await t.tap(find.byTooltip(S.addItem));
      await soft(t);
      expect(find.text('STUB /item/new'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Veiligheid blijft zichtbaar, ook op de smalste breedte en bij 200% tekst.
  // -------------------------------------------------------------------------
  group('veiligheid blijft zichtbaar', () {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Start: 112 en Eerste uur (schaal $scale)', (t) async {
        await tall(t, w: 320, h: 3000);
        await t.pumpWidget(_wrap(const DashboardScreen(), calmOverrides(), scale: scale));
        await soft(t);
        expect(find.text(S.dashCall112), findsOneWidget);
        expect(find.text(S.homeFirstHour), findsOneWidget);
      });

      testWidgets('Noodgevallen: 112, regel en Eerste-uur kaart (schaal $scale)', (t) async {
        await tall(t, w: 320, h: 3000);
        await t.pumpWidget(_wrap(const WikiOverviewScreen(), calmOverrides(), scale: scale));
        await soft(t);
        expect(find.text(S.wikiCall112), findsOneWidget);
        expect(find.text(S.wikiRule), findsOneWidget);
        expect(find.text('Eerste-uur kaart'), findsOneWidget);
      });
    }

    testWidgets('Noodgevallen-detail: "Nu doen" en "Bel 112 als" staan open, zonder uitklappen', (t) async {
      await tall(t, w: 360, h: 3000);
      await t.pumpWidget(_wrap(const WikiDetailScreen(id: 'brand-in-huis'), calmOverrides()));
      await soft(t);
      expect(find.text(S.wikiNow), findsOneWidget);
      expect(find.text(S.wikiCall112If), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Geen overflow: hoofdschermen op 320, 360 en 411 dp, schaal 1.0 en 2.0, licht en donker.
  // -------------------------------------------------------------------------
  group('geen overflow', () {
    final screens = <String, Widget Function()>{
      'Start': () => const DashboardScreen(),
      'Pakket': () => const ChecklistScreen(),
      'Noodgevallen': () => const WikiOverviewScreen(),
      'Mijn plan': () => const MyPlanScreen(),
      'Meer': () => const MoreScreen(),
    };
    for (final e in screens.entries) {
      for (final w in [320.0, 360.0, 411.0]) {
        for (final scale in [1.0, 2.0]) {
          for (final dark in [false, true]) {
            testWidgets('${e.key} ${w.toInt()}dp schaal $scale ${dark ? 'donker' : 'licht'}', (t) async {
              await tall(t, w: w, h: 2400);
              await t.pumpWidget(_wrap(e.value(), calmOverrides(), scale: scale, dark: dark));
              await soft(t);
              expect(t.takeException(), isNull);
            });
          }
        }
      }
    }
  });
}

Widget _wrap(Widget child, List<Override> o, {double scale = 1, bool dark = false}) => ProviderScope(
      overrides: o,
      child: MaterialApp(
        theme: buildTheme(dark ? Brightness.dark : Brightness.light),
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
