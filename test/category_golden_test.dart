import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, FontLoader;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/core/providers.dart';
import 'package:mijnnoodpakket/core/theme.dart';
import 'package:mijnnoodpakket/domain/models.dart';
import 'package:mijnnoodpakket/features/more/more_screen.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_models.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_providers.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_models.dart';
import 'package:mijnnoodpakket/features/noodplan/plan_providers.dart';
import 'package:mijnnoodpakket/features/pro/pro_providers.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_detail_screen.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_models.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_overview_screen.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_providers.dart';

import 'fake_purchase.dart';

final wiki = WikiData.parse(File('assets/wiki/noodgevallen.json').readAsStringSync());
final hacks = HackData.parse(File('assets/wiki/noodhacks.json').readAsStringSync());

/// Kleurenblindheidssimulaties (Machado e.a., volledige afwezigheid van het L- of M-kegeltype).
const protanopia = <double>[
  0.567, 0.433, 0, 0, 0, //
  0.558, 0.442, 0, 0, 0,
  0, 0.242, 0.758, 0, 0,
  0, 0, 0, 1, 0,
];
const deuteranopia = <double>[
  0.625, 0.375, 0, 0, 0, //
  0.700, 0.300, 0, 0, 0,
  0, 0.300, 0.700, 0, 0,
  0, 0, 0, 1, 0,
];

final List<Override> _overrides = [
  wikiProvider.overrideWith((ref) async => wiki),
  wikiFavoritesProvider.overrideWith((ref) => Stream.value(<String>{})),
  planProvider.overrideWith((ref) => Stream.value(const Plan())),
  allItemsProvider.overrideWithValue(const AsyncValue.data(<Item>[])),
  hacksProvider.overrideWith((ref) async => hacks),
  proUnlockedProvider.overrideWithValue(true),
  purchaseServiceProvider.overrideWithValue(FakePurchaseService()),
];

Future<void> show(
  WidgetTester t,
  Widget screen, {
  required Brightness brightness,
  double scale = 1,
  List<double>? filter,
  Size size = const Size(400, 900),
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(ProviderScope(
    overrides: _overrides,
    child: RepaintBoundary(
      key: const ValueKey('shot'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        locale: const Locale('nl', 'NL'),
        supportedLocales: const [Locale('nl', 'NL')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (c, child) {
          Widget w = MediaQuery(
            data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          );
          if (filter != null) w = ColorFiltered(colorFilter: ColorFilter.matrix(filter), child: w);
          return w;
        },
        home: screen,
      ),
    ),
  ));
  await t.pumpAndSettle();
}

Future<void> golden(WidgetTester t, String name) =>
    expectLater(find.byKey(const ValueKey('shot')), matchesGoldenFile('goldens/$name.png'));

void main() {
  setUpAll(() async {
    await initializeDateFormatting('nl_NL');
    // Echte lettertypen en pictogrammen, anders tekent de test blokjes (Ahem) in plaats van tekst.
    Future<void> load(String family, List<String> paths) async {
      final loader = FontLoader(family);
      var any = false;
      for (final path in paths) {
        final f = File(path);
        if (f.existsSync()) {
          loader.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
          any = true;
        }
      }
      if (any) await loader.load();
    }

    await load('Roboto', ['assets/fonts/Roboto-Regular.ttf', 'assets/fonts/Roboto-Bold.ttf']);
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root != null) {
      await load('MaterialIcons', ['$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf']);
    }
  });

  for (final b in Brightness.values) {
    group('categoriekleuren (${b.name})', () {
      testWidgets('Meer', (t) async {
        await show(t, const MoreScreen(), brightness: b, size: const Size(400, 520));
        expect(t.takeException(), isNull);
        await golden(t, 'meer_${b.name}');
      });

      testWidgets('Noodgevallen', (t) async {
        await show(t, const WikiOverviewScreen(), brightness: b, size: const Size(400, 1500));
        expect(t.takeException(), isNull);
        // "n situaties" in plaats van een kaal aantal
        expect(find.text(S.wikiSituations(wiki.emergencies.where((e) => e.categorie == wiki.categories.first.id).length)),
            findsOneWidget);
        await golden(t, 'noodgevallen_${b.name}');
      });

      testWidgets('Noodgeval-detail', (t) async {
        await show(t, const WikiDetailScreen(id: 'stroomstoring'), brightness: b, size: const Size(400, 700));
        expect(t.takeException(), isNull);
        await golden(t, 'detail_${b.name}');
      });
    });
  }

  group('tekstschaal 200%', () {
    for (final b in Brightness.values) {
      testWidgets('Meer en Noodgevallen zonder overflow (${b.name})', (t) async {
        await show(t, const MoreScreen(), brightness: b, scale: 2, size: const Size(360, 1000));
        expect(t.takeException(), isNull);
        await golden(t, 'meer_200_${b.name}');
        await show(t, const WikiOverviewScreen(), brightness: b, scale: 2, size: const Size(360, 3200));
        expect(t.takeException(), isNull);
        await golden(t, 'noodgevallen_200_${b.name}');
      });
    }
  });

  group('kleurenblindheid: categorieen blijven herkenbaar aan icoon en tekst', () {
    for (final f in {'protanopie': protanopia, 'deuteranopie': deuteranopia}.entries) {
      testWidgets(f.key, (t) async {
        await show(t, const WikiOverviewScreen(),
            brightness: Brightness.light, filter: f.value, size: const Size(400, 1500));
        expect(t.takeException(), isNull);
        // Elke categorie heeft titel, aantal en een eigen icoon, los van kleur.
        for (final c in wiki.categories) {
          expect(find.text(c.titel), findsOneWidget, reason: c.id);
        }
        await golden(t, 'noodgevallen_${f.key}');
        await show(t, const MoreScreen(), brightness: Brightness.light, filter: f.value, size: const Size(400, 520));
        await golden(t, 'meer_${f.key}');
      });
    }

    test('de iconen van de wiki-categorieen zijn onderling verschillend', () {
      final icons = wiki.categories.map((c) => c.icoon).toList();
      expect(icons.toSet().length, icons.length);
    });
  });
}
