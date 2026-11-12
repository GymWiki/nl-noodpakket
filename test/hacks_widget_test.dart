import 'dart:io';

import 'package:mijnnoodpakket/features/rampenzender/rampenzender_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/features/pro/pro_providers.dart';
import 'fake_purchase.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/features/noodhacks/hack_detail_screen.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_have_screen.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_links.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_models.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_out_screen.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_overview_screen.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_providers.dart';

import 'dart:async';

final data = HackData.parse(File('assets/wiki/noodhacks.json').readAsStringSync());

class FakePrefs implements HacksPrefs {
  Set<String> materials = {};
  final favs = <String>[];
  final _c = StreamController<Set<String>>.broadcast();

  Stream<Set<String>> stream() {
    late StreamController<Set<String>> sc;
    StreamSubscription<Set<String>>? sub;
    sc = StreamController<Set<String>>(
      onListen: () {
        sc.add(materials);
        sub = _c.stream.listen(sc.add);
      },
      onCancel: () => sub?.cancel(),
    );
    return sc.stream;
  }

  @override
  Future<void> setMaterials(Set<String> ids) async {
    materials = ids;
    _c.add(ids);
  }

  @override
  Future<void> toggleFavorite(String id, Set<String> current) async => favs.add(id);
  Future<void> close() => _c.close();
}

Future<FakePrefs> pump(WidgetTester t, String start, {Set<String> owned = const {}, bool pro = true}) async {
  t.view.physicalSize = const Size(800, 3600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final prefs = FakePrefs()..materials = owned;
  addTearDown(prefs.close);
  final router = GoRouter(initialLocation: start, routes: [
    GoRoute(path: '/hacks', builder: (_, _) => const HacksOverviewScreen(), routes: [
      GoRoute(path: 'pakket-op', builder: (_, _) => const HacksOutScreen()),
      GoRoute(path: 'in-huis', builder: (_, _) => const HacksHaveScreen()),
      GoRoute(path: ':id', builder: (_, st) => HackDetailScreen(id: st.pathParameters['id']!), routes: [
        GoRoute(path: 'stappen', builder: (_, st) => HackStepsScreen(id: st.pathParameters['id']!)),
      ]),
    ]),
    GoRoute(path: '/wiki/:id', builder: (_, st) => Scaffold(body: Text('wiki ${st.pathParameters['id']}'))),
    GoRoute(path: '/links', builder: (_, _) => const Scaffold(body: SingleChildScrollView(child: Column(children: [
      HacksForEmergency(emergencyId: 'uitval-water'),
    ])))),
  ]);
  final List<Override> overrides = [
    hacksProvider.overrideWith((ref) async => data),
    hacksMaterialsProvider.overrideWith((ref) => prefs.stream()),
    hacksFavoritesProvider.overrideWith((ref) => Stream.value(<String>{})),
    hacksPrefsProvider.overrideWithValue(prefs),
    proUnlockedProvider.overrideWithValue(pro),
    radioPrefsProvider.overrideWithValue(const RadioPrefs()),
    purchaseServiceProvider.overrideWithValue(FakePurchaseService()),
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
  return prefs;
}

void main() {
  setUpAll(() => initializeDateFormatting('nl_NL'));

  group('zonder Pro', () {
    testWidgets('overzicht en zoeken werken; Pro-hacks hebben een rustig Pro-label', (t) async {
      await pump(t, '/hacks', pro: false);
      expect(find.text(S.hacksDisclaimer), findsOneWidget);
      expect(find.text('Water ontsmetten met chloorbleek'), findsOneWidget); // titel zichtbaar
      expect(find.text(S.proBadge), findsWidgets);
      await t.enterText(find.byType(TextField), 'koolmonoxide');
      await t.pumpAndSettle();
      expect(find.text('Binnen koken of verwarmen met een barbecue of campingstoof'), findsOneWidget);
    });

    testWidgets('tik op een Pro-hack opent de paywall en navigeert niet', (t) async {
      await pump(t, '/hacks', pro: false);
      await t.tap(find.text('Water ontsmetten met chloorbleek'));
      await t.pumpAndSettle();
      expect(find.text(S.paywallTitle), findsOneWidget);
      expect(find.text(S.hacksDisclaimer), findsOneWidget); // nog op het overzicht
      await t.tap(find.text(S.paywallNotNow));
      await t.pumpAndSettle();
      expect(find.text(S.paywallTitle), findsNothing);
    });

    testWidgets('proefhacks en mythes openen volledig, ook zonder Pro', (t) async {
      for (final id in ['water-koken', 'koelkast-stroomuitval', 'mythe-barbecue-binnen']) {
        await pump(t, '/hacks/$id', pro: false);
        final h = data.byId(id)!;
        expect(find.text(S.paywallTitle), findsNothing, reason: id);
        expect(find.text(S.hackProHint), findsNothing, reason: id);
        expect(find.text(h.titel), findsWidgets, reason: id);
        if (h.categorie != 'mythes') expect(find.text(S.hacksStart), findsOneWidget, reason: id);
      }
    });

    testWidgets('directe link naar een Pro-hack toont geen details, wel een uitnodiging', (t) async {
      await pump(t, '/hacks/water-ontsmetten-bleek', pro: false);
      expect(find.text(S.hackProHint), findsOneWidget);
      expect(find.text(S.hacksStart), findsNothing);
      await t.tap(find.text(S.hackProOnly));
      await t.pumpAndSettle();
      expect(find.text(S.paywallTitle), findsOneWidget);
    });

    testWidgets('directe link naar het stappenplan van een Pro-hack is vergrendeld', (t) async {
      await pump(t, '/hacks/water-ontsmetten-bleek/stappen', pro: false);
      expect(find.text(S.hackProHint), findsOneWidget);
    });

    testWidgets('"Wat heb ik in huis?" toont resultaten als titels; details alleen met Pro', (t) async {
      await pump(t, '/hacks/in-huis', pro: false, owned: {'pan', 'kookbron'});
      expect(find.text('Water koken'), findsWidgets);
      await t.tap(find.text('Eten zonder te koken'));
      await t.pumpAndSettle();
      expect(find.text(S.paywallTitle), findsOneWidget);
    });

    testWidgets('met Pro opent dezelfde hack gewoon', (t) async {
      await pump(t, '/hacks', pro: true);
      expect(find.text(S.proBadge), findsNothing);
      await t.tap(find.text('Water ontsmetten met chloorbleek'));
      await t.pumpAndSettle();
      expect(find.text(S.paywallTitle), findsNothing);
    });
  });

  group('overzicht', () {
    testWidgets('toont disclaimer, ingangen, categorieën en labels met icoon en tekst', (t) async {
      await pump(t, '/hacks');
      expect(find.text(S.hacksDisclaimer), findsOneWidget);
      expect(find.text(S.hacksIntroOut), findsOneWidget);
      expect(find.text(S.hacksHave), findsOneWidget);
      for (final c in data.categories) {
        expect(find.text(c.titel), findsOneWidget, reason: c.id);
      }
      // een label bestaat altijd uit icoon + tekst
      expect(find.text(S.hacksLabelNever), findsWidgets);
      expect(find.byIcon(Icons.block_rounded), findsWidgets);
      expect(find.text(S.hacksLabelSafe), findsWidgets);
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
    });

    testWidgets('zoeken op trefwoord', (t) async {
      await pump(t, '/hacks');
      await t.enterText(find.byType(TextField), 'koolmonoxide');
      await t.pumpAndSettle();
      expect(find.text('Binnen koken of verwarmen met een barbecue of campingstoof'), findsOneWidget);
      expect(find.text('Water koken'), findsNothing);
      await t.enterText(find.byType(TextField), 'zzzzz');
      await t.pumpAndSettle();
      expect(find.text(S.hacksNoResults), findsOneWidget);
    });

    testWidgets('filter op label Doe dit nooit toont alleen mythes', (t) async {
      await pump(t, '/hacks');
      await t.tap(find.widgetWithText(ChoiceChip, S.hacksLabelNever));
      await t.pumpAndSettle();
      expect(find.text('Water koken'), findsNothing);
      expect(find.text('Zacht ontdooid eten opnieuw invriezen'), findsOneWidget);
    });
  });

  group('detail', () {
    testWidgets('veilige hack: label, materialen, stappen, bron en controledatum', (t) async {
      await pump(t, '/hacks/water-koken');
      expect(find.text(S.hacksLabelSafe), findsOneWidget);
      expect(find.text(S.hacksNeed), findsOneWidget);
      expect(find.text(S.hacksSteps), findsOneWidget);
      expect(find.text('Laat het 3 minuten koken.'), findsOneWidget);
      expect(find.text(S.hacksStart), findsOneWidget);
      // Bronnen zijn inklapbaar (rustiger): klap uit.
      await t.ensureVisible(find.text(S.hacksSources));
      await t.tap(find.text(S.hacksSources));
      await t.pumpAndSettle();
      expect(find.textContaining('Laatst gecontroleerd'), findsOneWidget);
      expect(find.text(S.hacksSourceOfficial), findsOneWidget);
    });

    testWidgets('bleek: Let op-label, waarschuwingen, koken-is-veiliger en veilig alternatief', (t) async {
      await pump(t, '/hacks/water-ontsmetten-bleek');
      // "Let op" is zowel het label als de kop van de waarschuwingen
      expect(find.text(S.hacksLabelCaution), findsNWidgets(2));
      expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
      expect(find.text('Water koken'), findsOneWidget); // alternatief
      // Bronnen zijn inklapbaar (rustiger): klap uit.
      await t.ensureVisible(find.text(S.hacksSources));
      await t.tap(find.text(S.hacksSources));
      await t.pumpAndSettle();
      expect(find.text(S.hacksSourceGeneral), findsOneWidget);
    });

    testWidgets('mythe: toont waarom niet en wat je in plaats daarvan doet', (t) async {
      await pump(t, '/hacks/mythe-barbecue-binnen');
      expect(find.text(S.hacksLabelNever), findsOneWidget);
      expect(find.text(S.hacksWhyNot), findsOneWidget);
      expect(find.textContaining('koolmonoxide'), findsWidgets);
      expect(find.text(S.hacksInstead), findsWidgets);
      expect(find.text(S.hacksStart), findsNothing); // geen stappenplan voor een mythe
    });

    testWidgets('onbekende hack: nette melding', (t) async {
      await pump(t, '/hacks/bestaat-niet');
      expect(find.text(S.hacksNotFound), findsOneWidget);
    });

    testWidgets('stappenplan: waarschuwingen eerst, dan één stap per scherm', (t) async {
      await pump(t, '/hacks/water-ontsmetten-bleek/stappen');
      expect(find.text(S.hacksReadFirst), findsOneWidget);
      await t.tap(find.text(S.wikiNext));
      await t.pumpAndSettle();
      expect(find.text(S.planStepOf(1, data.byId('water-ontsmetten-bleek')!.stappen.length)), findsOneWidget);
      await t.tap(find.text(S.wikiPrev));
      await t.pumpAndSettle();
      expect(find.text(S.hacksReadFirst), findsOneWidget);
      // lijstweergave
      await t.tap(find.byTooltip(S.hacksStepsList));
      await t.pumpAndSettle();
      expect(find.textContaining('1. Kijk op het etiket'), findsOneWidget);
    });
  });

  group('wat heb ik in huis', () {
    testWidgets('zonder keuze staan alleen hacks zonder materiaal bij "Dit kan nu"', (t) async {
      await pump(t, '/hacks/in-huis');
      expect(find.text(S.hacksHavePossible), findsOneWidget);
      expect(find.text('Eten zonder te koken'), findsOneWidget);
      expect(find.text('Water koken'), findsOneWidget); // staat bij "Bijna"
      expect(find.textContaining('Je mist:'), findsWidgets);
      expect(find.text(S.hacksLabelNever), findsNothing, reason: 'mythes horen hier niet');
    });

    testWidgets('chips kiezen verplaatst een hack naar "Dit kan nu"', (t) async {
      final prefs = await pump(t, '/hacks/in-huis');
      await t.tap(find.widgetWithText(FilterChip, 'Pan met deksel'));
      await t.pumpAndSettle();
      expect(find.textContaining('Je mist: Campingbrander of barbecue (buiten)'), findsWidgets);
      await t.tap(find.widgetWithText(FilterChip, 'Campingbrander of barbecue (buiten)'));
      await t.pumpAndSettle();
      expect(prefs.materials, {'pan', 'kookbron'});
      // "Water koken" vraagt niets meer
      final tile = find.ancestor(of: find.text('Water koken'), matching: find.byType(ListTile));
      expect(find.descendant(of: tile, matching: find.textContaining('Je mist')), findsNothing);
    });

    testWidgets('opgeslagen keuze wordt getoond en kan gewist worden', (t) async {
      final prefs = await pump(t, '/hacks/in-huis', owned: {'bleek'});
      final chip = t.widget<FilterChip>(find.widgetWithText(FilterChip, 'Gewone chloorbleek (onparfumeerd)'));
      expect(chip.selected, isTrue);
      await t.tap(find.text(S.hacksHaveClear));
      await t.pumpAndSettle();
      expect(prefs.materials, isEmpty);
    });
  });

  group('mijn pakket is op', () {
    testWidgets('prioriteitsvolgorde: water, warmte, hygiëne, eten, hulp zoeken', (t) async {
      await pump(t, '/hacks/pakket-op');
      final y = {
        for (final s in [S.hacksOut1, S.hacksOut2, S.hacksOut3, S.hacksOut4, S.hacksOut5])
          s: t.getTopLeft(find.text(s)).dy,
      };
      final order = y.keys.toList();
      for (var i = 1; i < order.length; i++) {
        expect(y[order[i]]! > y[order[i - 1]]!, isTrue, reason: '${order[i]} hoort onder ${order[i - 1]}');
      }
      expect(find.text('Water vinden als de kraan droog is'), findsOneWidget);
      expect(find.text(S.hacksOutHelp.first), findsOneWidget);
    });

    testWidgets('elke stap linkt naar een bestaande hack', (t) async {
      await pump(t, '/hacks/pakket-op');
      await t.tap(find.text('Water koken'));
      await t.pumpAndSettle();
      expect(find.text('Laat het 3 minuten koken.'), findsOneWidget);
    });
  });

  testWidgets('koppelingen: het noodgevalblok toont passende hacks', (t) async {
    await pump(t, '/links');
    expect(find.text(S.hacksRelatedBlock), findsOneWidget);
    expect(find.text('Water vinden als de kraan droog is'), findsOneWidget);
  });
}
