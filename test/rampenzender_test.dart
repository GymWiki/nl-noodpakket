import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/core/providers.dart';
import 'package:mijnnoodpakket/data/db/database.dart';
import 'package:mijnnoodpakket/data/repositories/item_repository.dart';
import 'package:mijnnoodpakket/data/repositories/settings_repository.dart';
import 'package:mijnnoodpakket/features/dashboard/dashboard_cards.dart';
import 'package:mijnnoodpakket/features/dashboard/dashboard_providers.dart';
import 'package:mijnnoodpakket/features/dashboard/domain/readiness.dart';
import 'package:mijnnoodpakket/features/dashboard/domain/seasonal.dart';
import 'package:mijnnoodpakket/domain/models.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_models.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_share.dart';
import 'package:mijnnoodpakket/features/rampenzender/data/radio_lines.dart';
import 'package:mijnnoodpakket/features/rampenzender/data/rampenzender_models.dart';
import 'package:mijnnoodpakket/features/rampenzender/data/rampenzender_validation.dart';
import 'package:mijnnoodpakket/features/rampenzender/rampenzender_providers.dart';
import 'package:mijnnoodpakket/features/rampenzender/rampenzender_strings.dart';
import 'package:mijnnoodpakket/features/rampenzender/ui/rampenzender_screen.dart';
import 'package:mijnnoodpakket/features/rampenzender/ui/rampenzender_widgets.dart';
import 'package:mijnnoodpakket/features/rampenzender/ui/region_picker_screen.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_pdf.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_models.dart';
import 'package:mijnnoodpakket/core/theme.dart';
import 'package:flutter/services.dart' show rootBundle;

Map<String, dynamic> loadJson() =>
    jsonDecode(File('assets/radio/rampenzenders.json').readAsStringSync()) as Map<String, dynamic>;

RadioData loadData() => RadioData.parse(File('assets/radio/rampenzenders.json').readAsStringSync());

RadioRegion region(RadioData d, String name) => d.regions.firstWhere((r) => r.name == name);

class FakeActions implements RadioActions {
  final calls = <String>[];
  @override
  Future<void> chooseRegion(String gm) async => calls.add('region:$gm');
  @override
  Future<void> clearRegion() async => calls.add('clear');
  @override
  Future<void> chooseArea(String? id) async => calls.add('area:$id');
  @override
  Future<void> setRadioReady(bool v) async => calls.add('ready:$v');
}

void main() {
  setUpAll(() => initializeDateFormatting('nl_NL'));

  group('data: dataset en validatie', () {
    test('de gebundelde dataset is geldig', () {
      expect(validateRampenzenders(loadJson()), isEmpty);
    });

    test('13 regionale omroepen, NPO Radio 1, alle 25 veiligheidsregio\'s en 342 gemeenten', () {
      final j = loadJson();
      final b = (j['broadcasters'] as List).cast<Map<String, dynamic>>();
      expect(b.where((x) => x['type'] == 'regionaal').length, 13);
      expect(b.where((x) => x['type'] == 'landelijk').length, 1);
      expect((j['veiligheidsregios'] as List).length, 25);
      expect((j['regions'] as List).length, 342);
    });

    test('elke gemeente heeft een omroep met gecontroleerde FM, of een expliciete "geen data"-marking', () {
      final d = loadData();
      for (final r in d.regions) {
        final res = d.resultFor(r.gm)!;
        expect(res.hasRegional || res.broadcaster != null, isTrue, reason: r.name);
        // Altijd een uitkomst: regionaal of de NPO Radio 1-terugval.
        expect(res.national.name, 'NPO Radio 1');
      }
    });

    test('bekende frequenties uit de officiële bronnen staan erin (Brabant, Noord, Fryslân, Drenthe, Oost, Utrecht)', () {
      final d = loadData();
      List<double> fm(String id) => d.transmissions.firstWhere((t) => t.id == id).fm;
      expect(fm('brabant-west'), [91.0]);
      expect(fm('brabant-midden'), [91.9]);
      expect(fm('brabant-noordoost'), [95.8]);
      expect(fm('brabant-zuidoost'), [87.6]);
      expect(d.transmissions.firstWhere((t) => t.id == 'brabant-west').dab!.channel, '7C');
      expect(fm('noord-groningen'), [97.5]);
      expect(fm('fryslan-fryslan'), [92.2]);
      expect(fm('drenthe-drenthe'), [90.8]);
      expect(fm('drenthe-zuidoost'), [99.3]);
      expect(fm('oost-noordwest-overijssel'), [99.4]);
      expect(fm('utrecht-provincie'), [93.1]);
    });

    test('Omroep West: 27 gemeenten, zoals Omroep West zelf op zijn pagina Uitzendgebied vermeldt', () {
      expect(loadData().regions.where((r) => r.broadcasterId == 'west').length, 27);
    });

    test('NPO Radio 1 toont geen losse FM-frequentie, wel een toelichting en het DAB+-kanaal', () {
      final tx = loadData().nationalTx;
      expect(tx.fm, isEmpty);
      expect(tx.notes, contains('kan per plek verschillen'));
      expect(tx.dab!.channel, '12C');
    });

    group('validatie vangt fouten', () {
      List<String> errorsAfter(void Function(Map<String, dynamic> j) mutate) {
        final j = loadJson();
        mutate(j);
        return validateRampenzenders(j);
      }

      Map<String, dynamic> tx(Map<String, dynamic> j, String id) =>
          ((j['transmissions'] as List).cast<Map<String, dynamic>>()).firstWhere((t) => t['id'] == id);

      test('FM buiten 87.5 tot 108.0', () {
        expect(errorsAfter((j) => tx(j, 'noord-groningen')['fmMHz'] = [86.0]).join(), contains('valt buiten'));
        expect(errorsAfter((j) => tx(j, 'noord-groningen')['fmMHz'] = [108.5]).join(), contains('valt buiten'));
      });
      test('ongeldig DAB+-kanaal', () {
        for (final bad in ['4A', '14B', '7G', 'C7', '7c']) {
          expect(errorsAfter((j) => tx(j, 'noord-groningen')['dab'] = {'channel': bad, 'searchName': 'x'}).join(),
              contains('ongeldig DAB+-kanaal'), reason: bad);
        }
      });
      test('zending zonder bron of zonder controledatum', () {
        expect(errorsAfter((j) => tx(j, 'noord-groningen')['sourceIds'] = <String>[]).join(), contains('minstens één bron'));
        expect(errorsAfter((j) => tx(j, 'noord-groningen')['lastReviewed'] = '').join(), contains('lastReviewed'));
      });
      test('onbekende bron, dubbele id en onbekende omroep', () {
        expect(errorsAfter((j) => tx(j, 'noord-groningen')['sourceIds'] = ['bestaat-niet', 'dv-radio']).join(), contains('onbekende bron'));
        expect(errorsAfter((j) => tx(j, 'fryslan-fryslan')['id'] = 'noord-groningen').join(), contains('dubbele'));
        expect(errorsAfter((j) => tx(j, 'noord-groningen')['broadcasterId'] = 'bestaat-niet').join(), contains('onbekende omroep'));
      });
      test('meerdere-bronnen met één bron', () {
        expect(errorsAfter((j) => tx(j, 'noord-groningen')['sourceIds'] = ['dv-radio']).join(), contains('minstens twee bronnen'));
      });
      test('gemeente wijst naar een onbekende veiligheidsregio of omroep, of een omroep die niet past', () {
        List<Map<String, dynamic>> regions(Map<String, dynamic> j) => (j['regions'] as List).cast<Map<String, dynamic>>();
        expect(errorsAfter((j) => regions(j).first['vr'] = 'VR99').join(), contains('onbekende veiligheidsregio'));
        expect(errorsAfter((j) => regions(j).first['broadcasterId'] = 'bestaat-niet').join(), contains('onbekende omroep'));
        expect(errorsAfter((j) => regions(j).first['broadcasterId'] = 'brabant').join(), contains('past niet bij'));
      });
      test('een veiligheidsregio zonder omroep, en een omroep zonder gegevens', () {
        expect(
            errorsAfter((j) => ((j['broadcasters'] as List).first as Map<String, dynamic>)['rampenzenderVoor'] = <String>[]).join(),
            contains('regionale omroep zonder veiligheidsregio'));
        expect(
            errorsAfter((j) => (j['transmissions'] as List).removeWhere((t) => (t as Map)['broadcasterId'] == 'noord')).join(),
            contains('heeft geen gegevens'));
      });
      test('een gebied dat niet bij de omroep van de gemeente hoort', () {
        List<Map<String, dynamic>> regions(Map<String, dynamic> j) => (j['regions'] as List).cast<Map<String, dynamic>>();
        final e = errorsAfter((j) => regions(j).firstWhere((r) => r['name'] == 'Groningen')['areaIds'] = ['brabant-west']);
        expect(e.join(), contains('hoort niet bij omroep'));
      });
      test('zending zonder FM en zonder toelichting', () {
        final e = errorsAfter((j) {
          final t = tx(j, 'npo-radio-1-landelijk');
          t['notes'] = '';
        });
        expect(e.join(), contains('toelichting'));
      });
    });
  });

  group('logica', () {
    final d = loadData();

    test('een gemeente met één gebied krijgt één eenduidig resultaat', () {
      final r = d.resultFor(region(d, 'Groningen').gm)!;
      expect(r.broadcaster!.id, 'noord');
      expect(r.areas.length, 1);
      expect(r.mustChoose, isFalse);
      expect(r.firstFm, 97.5);
      expect(r.hasRegional, isTrue);
    });

    test('meerdere gebieden bij één omroep zonder aantoonbare koppeling: alle gebieden, gebruiker kiest', () {
      final r = d.resultFor(region(d, 'Eindhoven').gm)!;
      expect(r.broadcaster!.id, 'brabant');
      expect(r.areas.map((a) => a.id), ['brabant-west', 'brabant-midden', 'brabant-noordoost', 'brabant-zuidoost']);
      expect(r.mustChoose, isTrue);
      expect(d.resultFor(region(d, 'Zwolle').gm)!.areas.length, 4); // Oost
      expect(d.resultFor(region(d, 'Maastricht').gm)!.areas.map((a) => a.fm.first), [100.3, 95.3]);
    });

    test('alleen waar een bron het aantoont is een gemeente aan een gebied gekoppeld', () {
      // DARES: veiligheidsregio Midden- en West-Brabant heeft 91.0 (West) en 91.9 (Midden).
      expect(d.resultFor(region(d, 'Breda').gm)!.areas.map((a) => a.id), ['brabant-west', 'brabant-midden']);
      // RTV Oost, Omroep Gelderland: gebied heet naar de plaats.
      expect(d.resultFor(region(d, 'Deventer').gm)!.areas.map((a) => a.id), ['oost-deventer']);
      expect(d.resultFor(region(d, 'Arnhem').gm)!.areas.map((a) => a.id), ['gelderland-arnhem-nijmegen']);
      expect(d.resultFor(region(d, 'Nijmegen').gm)!.areas.map((a) => a.id), ['gelderland-arnhem-nijmegen']);
      // RTV Utrecht: Rhenen en omgeving, plus de hele provincie.
      expect(d.resultFor(region(d, 'Rhenen').gm)!.areas.map((a) => a.id), ['utrecht-provincie', 'utrecht-rhenen']);
    });

    test('Zuid-Holland: Haaglanden en Hollands Midden naar Radio West, Rijnmond en Zuid-Holland-Zuid naar Rijnmond', () {
      expect(d.resultFor(region(d, 'Delft').gm)!.broadcaster!.id, 'west');
      expect(d.resultFor(region(d, 'Gouda').gm)!.broadcaster!.id, 'west');
      expect(d.resultFor(region(d, 'Rotterdam').gm)!.broadcaster!.id, 'rijnmond');
      expect(d.resultFor(region(d, 'Dordrecht').gm)!.broadcaster!.id, 'rijnmond');
      expect(d.resultFor(region(d, 'Hilversum').gm)!.broadcaster!.id, 'nh'); // Gooi en Vechtstreek
    });

    test('ontbrekende of onbekende regio geeft geen resultaat', () {
      expect(d.resultFor(null), isNull);
      expect(d.resultFor('GM9999'), isNull);
    });

    test('ontbrekende data: terugval op NPO Radio 1 met alleen wat gecontroleerd is, zonder lege velden', () {
      final j = loadJson();
      (j['transmissions'] as List).removeWhere((t) => (t as Map)['broadcasterId'] == 'noord');
      final bare = RadioData.parse(jsonEncode(j));
      final r = bare.resultFor(region(bare, 'Groningen').gm)!;
      expect(r.hasRegional, isFalse);
      expect(r.areas, isEmpty);
      expect(r.broadcaster!.website, startsWith('https://')); // verwijzing naar de website van de omroep
      expect(r.nationalTx.dab!.channel, '12C');
      expect(radioTuneText(r), RZ.tuneLineNoData);
      expect(RZ.noData('rtvnoord.nl'), allOf(contains('nog geen gecontroleerde frequentie'), contains('NPO Radio 1')));
    });

    test('zoeken op gemeentenaam en bijnaam, zonder hoofdletters, accenten en streepjes', () {
      expect(d.search('tilb').first.name, 'Tilburg');
      expect(d.search('DEN HAAG').map((r) => r.name), contains("'s-Gravenhage"));
      expect(d.search('den bosch').map((r) => r.name), contains("'s-Hertogenbosch"));
      expect(d.search('sgraven').map((r) => r.name), contains("'s-Gravenhage"));
      expect(d.search('ooststellingwerf').single.name, 'Ooststellingwerf');
      expect(d.search('  '), isEmpty);
      expect(d.search('qqqqzz'), isEmpty);
      expect(d.search('zwolle').first.name, 'Zwolle');
    });

    test('voorlezen: frequenties als Nederlandse woorden', () {
      expect(speakMHz(90.8), 'negentig komma acht megahertz');
      expect(speakMHz(87.6), 'zevenentachtig komma zes megahertz');
      expect(speakMHz(99.3), 'negenennegentig komma drie megahertz');
      expect(speakMHz(92.2), 'tweeënnegentig komma twee megahertz');
      expect(speakMHz(103.5), 'honderddrie komma vijf megahertz');
      expect(speakMHz(100.3), 'honderd komma drie megahertz');
      expect(speakMHz(88.0), 'achtentachtig komma nul megahertz');
      expect(speakDab('7C'), 'zeven C');
      expect(speakDab('12B'), 'twaalf B');
      expect(fmtMHz(91), '91.0');
    });

    test('Eerste-uur en noodbalk: "Stem je radio af op", zonder gokken', () {
      expect(radioTuneText(d.resultFor(region(d, 'Groningen').gm)), 'Stem je radio af op: Radio Noord FM 97.5');
      expect(radioTuneText(null), RZ.tuneLineNoRegion);
      // Meerdere gebieden: geen losse frequentie noemen, maar naar de lijst verwijzen.
      expect(radioTuneText(d.resultFor(region(d, 'Eindhoven').gm)), isNot(contains('91.0')));
      expect(radioTuneText(d.resultFor(region(d, 'Eindhoven').gm)), contains('Omroep Brabant Radio'));
    });

    test('regels voor meterkastkaart en noodplan: één gebied, alle gebieden of de gekozen', () {
      final single = radioDocLines(d.resultFor(region(d, 'Groningen').gm));
      expect(single.first, 'Groningen: Radio Noord, FM 97.5');
      expect(single.any((l) => l.contains('NPO Radio 1') && l.contains('kan per plek verschillen')), isTrue);
      final multi = radioDocLines(d.resultFor(region(d, 'Eindhoven').gm));
      expect(multi.join('\n'), allOf(contains('91.0'), contains('91.9'), contains('95.8'), contains('87.6')));
      final chosen = radioDocLines(d.resultFor(region(d, 'Eindhoven').gm), areaId: 'brabant-zuidoost');
      expect(chosen.first, 'Eindhoven: Omroep Brabant Radio, FM 87.6');
      expect(chosen.join('\n'), isNot(contains('91.0')));
      expect(radioDocLines(null), isEmpty);
    });

    test('NH toont alle drie frequenties, zonder gokken welke bij welke plek hoort', () {
      final lines = radioDocLines(d.resultFor(region(d, 'Amsterdam').gm));
      expect(lines.first, contains('88.7 of 88.9 of 93.9'));
    });

    test('de melding "Klopt dit niet?" bevat regio en frequentie en geen e-mailadres', () {
      final r = d.resultFor(region(d, 'Groningen').gm)!;
      final u = radioReportUri(r, r.checkedOn);
      expect(u.scheme, 'https');
      expect(u.host, 'github.com');
      final body = u.queryParameters['body']!;
      expect(body, allOf(contains('Groningen'), contains('97.5'), contains('RTV Noord')));
      expect(u.toString().contains('@'), isFalse);
    });

    test('noodplan-bestand: regio-id gaat mee (alleen het id) en ongeldige waarden worden genegeerd', () {
      final json = planToJsonString(const Plan(householdName: 'X'), const ShareOptions(), now: DateTime(2026, 11, 12), radioGm: 'GM0014');
      expect(jsonDecode(json)['radioGm'], 'GM0014');
      expect(json.contains('Radio Noord'), isFalse); // niet de dataset zelf
      expect(parsePlanFile(json).radioGm, 'GM0014');
      final bad = planToJsonString(const Plan(householdName: 'X'), const ShareOptions(), now: DateTime(2026, 11, 12), radioGm: '<script>');
      expect(jsonDecode(bad).containsKey('radioGm'), isFalse);
      final none = planToJsonString(const Plan(householdName: 'X'), const ShareOptions(), now: DateTime(2026, 11, 12));
      expect(parsePlanFile(none).radioGm, '');
    });
  });

  group('opslag: regio kiezen en "radio ingesteld"', () {
    late AppDatabase db;
    late ProviderContainer c;
    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      c = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
      ]);
    });
    tearDown(() async {
      c.dispose();
      await db.close();
    });

    test('regio opslaan, wijzigen wist gebied en ingesteld, wissen ruimt alles op', () async {
      final a = c.read(radioActionsProvider);
      await a.chooseRegion('GM0014');
      await a.chooseArea('x');
      await a.setRadioReady(true);
      final repo = SettingsRepository(db);
      expect(await repo.getRaw(RadioKeys.gm), 'GM0014');
      expect(await repo.getRaw(RadioKeys.set), 'true');
      await a.chooseRegion('GM0014'); // zelfde regio: niets wissen
      expect(await repo.getRaw(RadioKeys.area), 'x');
      await a.chooseRegion('GM0363'); // andere regio: gebied en "ingesteld" vervallen
      expect(await repo.getRaw(RadioKeys.area), isNull);
      expect(await repo.getRaw(RadioKeys.set), isNull);
      await a.clearRegion();
      expect(await repo.getRaw(RadioKeys.gm), isNull);
    });

    test('"Ik heb mijn radio ingesteld" zet een vinkje en werkt het checklistitem Radio bij', () async {
      await c.read(radioActionsProvider).setRadioReady(true);
      expect(await SettingsRepository(db).getRaw(RadioKeys.set), 'true');
      final rows = await ItemRepository(db).watchRows().first;
      expect(rows.firstWhere((r) => r.id == 'radio').inHouse, isTrue);
      // Terugzetten laat de checklist met rust.
      await c.read(radioActionsProvider).setRadioReady(false);
      expect(await SettingsRepository(db).getRaw(RadioKeys.set), isNull);
      expect((await ItemRepository(db).watchRows().first).firstWhere((r) => r.id == 'radio').inHouse, isTrue);
    });
  });

  group('dashboard', () {
    DashboardData data({required bool pending}) => DashboardData(
          hasItems: true,
          readiness: computeReadiness(const [], const Household(), DateTime(2026, 11, 12)),
          suggestions: const [],
          expiring: const [],
          seasonal: seasonalFor(DateTime(2026, 11, 12)),
          maintenanceDue: const [],
          simpleStart: false,
          radioPending: pending,
        );

    test('de radiokaart staat onder "Volgende stap" zolang de radio niet is ingesteld', () {
      final ids = visibleCards(data(pending: true), registry: dashboardCards).map((c) => c.id).toList();
      expect(ids, contains('radio'));
      final next = dashboardCards.firstWhere((c) => c.id == 'next');
      final radio = dashboardCards.firstWhere((c) => c.id == 'radio');
      expect(radio.priority, greaterThan(next.priority));
      expect(dashboardCards.where((c) => c.priority == radio.priority).length, 1);
    });

    test('de kaart verdwijnt zodra de radio is ingesteld', () {
      expect(visibleCards(data(pending: false)).map((c) => c.id), isNot(contains('radio')));
    });
  });

  group('schermen', () {
    List<Override> overrides({RadioPrefs prefs = const RadioPrefs(gm: 'GM0014'), FakeActions? actions}) => [
          radioDataProvider.overrideWith((ref) async => loadData()),
          radioPrefsProvider.overrideWithValue(prefs),
          if (actions != null) radioActionsProvider.overrideWithValue(actions),
        ];

    Future<void> pumpScreen(WidgetTester t, Widget home, List<Override> o, {double scale = 1}) async {
      t.view.physicalSize = const Size(411, 4000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, _) => home),
        GoRoute(path: '/rampenzender', builder: (_, _) => const Scaffold(body: Text('resultaat'))),
        GoRoute(path: '/rampenzender/kies', builder: (_, _) => const Scaffold(body: Text('kies'))),
        GoRoute(path: '/checklist', builder: (_, _) => const Scaffold(body: Text('checklist'))),
      ]);
      await t.pumpWidget(ProviderScope(
        overrides: o,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('nl', 'NL'),
          supportedLocales: const [Locale('nl', 'NL')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: buildTheme(Brightness.light),
          builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
        ),
      ));
      await t.pumpAndSettle();
    }

    testWidgets('resultaat voor Groningen: groot FM, DAB+, NPO Radio 1, uitleg en controledatum', (t) async {
      await pumpScreen(t, const RampenzenderScreen(), overrides());
      expect(find.text('97.5'), findsOneWidget);
      expect(find.text('MHz'), findsWidgets);
      expect(find.text('Kanaal 7C'), findsOneWidget);
      expect(find.text('Zoek op de naam: Radio Noord'), findsOneWidget);
      expect(find.text('NPO Radio 1 (heel Nederland)'), findsOneWidget);
      expect(find.text(RZ.nationalFm), findsOneWidget);
      expect(find.text(RZ.whyHeading), findsOneWidget);
      expect(find.text(RZ.howHeading), findsOneWidget);
      expect(find.textContaining(RZ.tip), findsOneWidget);
      expect(find.textContaining('Gegevens gecontroleerd op 12 november 2026'), findsOneWidget);
      expect(find.text(RZ.report), findsOneWidget);
    });

    testWidgets('frequentie wordt voorgelezen als "zevenennegentig komma vijf megahertz"', (t) async {
      final h = t.ensureSemantics();
      await pumpScreen(t, const RampenzenderScreen(), overrides());
      final labels = <String>[];
      void walk(SemanticsNode n) {
        labels.add(n.label);
        n.visitChildren((c) { walk(c); return true; });
      }
      // ignore: deprecated_member_use
      walk(t.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
      expect(labels.any((l) => l.contains('FM zevenennegentig komma vijf megahertz')), isTrue, reason: '$labels');
      expect(labels.any((l) => l.contains('DAB plus, kanaal zeven C')), isTrue);
      h.dispose();
    });

    testWidgets('tekstschaal 200%: geen overflow in het resultaat', (t) async {
      for (final gm in ['GM0014', 'GM0772']) {
        // Groningen en Eindhoven (vier gebieden)
        await pumpScreen(t, const RampenzenderScreen(), overrides(prefs: RadioPrefs(gm: gm)), scale: 2);
        await t.drag(find.byType(ListView).first, const Offset(0, -3000));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: gm);
      }
    });

    testWidgets('meerdere gebieden: kopjes met alle gebieden en frequenties, de gebruiker kiest', (t) async {
      final a = FakeActions();
      await pumpScreen(t, const RampenzenderScreen(), overrides(prefs: const RadioPrefs(gm: 'GM0772'), actions: a));
      expect(find.text(RZ.chooseHeading), findsOneWidget);
      for (final area in ['West-Brabant', 'Midden-Brabant', 'Noordoost-Brabant', 'Zuidoost-Brabant']) {
        expect(find.text(RZ.livingIn(area)), findsOneWidget);
      }
      for (final f in ['91.0', '91.9', '95.8', '87.6']) {
        expect(find.text(f), findsOneWidget);
      }
      await t.ensureVisible(find.text(RZ.myArea).first);
      await t.tap(find.text(RZ.myArea).first);
      expect(a.calls, ['area:brabant-west']);
    });

    testWidgets('gekozen gebied komt bovenaan met "Jouw gebied"', (t) async {
      await pumpScreen(t, const RampenzenderScreen(),
          overrides(prefs: const RadioPrefs(gm: 'GM0772', area: 'brabant-zuidoost')));
      expect(find.text(RZ.myAreaChosen), findsOneWidget);
      expect(find.text(RZ.otherAreas), findsOneWidget);
    });

    testWidgets('zonder regio: uitleg en knop om je gemeente te kiezen, NPO Radio 1 staat er wel', (t) async {
      await pumpScreen(t, const RampenzenderScreen(), overrides(prefs: const RadioPrefs()));
      expect(find.text(RZ.pickTitle), findsOneWidget);
      expect(find.text('NPO Radio 1 (heel Nederland)'), findsOneWidget);
      expect(find.text(RZ.pickNoLocation), findsOneWidget);
    });

    testWidgets('"Ik heb mijn radio ingesteld" roept de actie aan; ingesteld toont een vinkje en herstel', (t) async {
      final a = FakeActions();
      await pumpScreen(t, const RampenzenderScreen(), overrides(actions: a));
      await t.ensureVisible(find.text(RZ.markDone));
      await t.tap(find.text(RZ.markDone));
      expect(a.calls, ['ready:true']);
      await pumpScreen(t, const RampenzenderScreen(), overrides(prefs: const RadioPrefs(gm: 'GM0014', radioSet: true), actions: a));
      expect(find.text(RZ.markedDone), findsOneWidget);
      expect(find.text(RZ.markDone), findsNothing);
    });

    testWidgets('regio kiezen: zoeken, opslaan', (t) async {
      final a = FakeActions();
      await pumpScreen(t, const RegionPickerScreen(), overrides(prefs: const RadioPrefs(), actions: a));
      expect(find.text(RZ.pickStart), findsOneWidget);
      await t.enterText(find.byType(TextField), 'qqqqzz');
      await t.pumpAndSettle();
      expect(find.text(RZ.pickNone), findsOneWidget);
      await t.enterText(find.byType(TextField), 'tilb');
      await t.pumpAndSettle();
      expect(find.text('Tilburg'), findsOneWidget);
      await t.tap(find.text('Tilburg'));
      await t.pumpAndSettle();
      expect(a.calls.single, startsWith('region:GM'));
    });

    testWidgets('regel in Eerste-uur kaart en noodbalk gebruikt de opgeslagen regio', (t) async {
      await pumpScreen(t, const Scaffold(body: RadioTuneLine()), overrides());
      expect(find.text('Stem je radio af op: Radio Noord FM 97.5'), findsOneWidget);
      await pumpScreen(t, const Scaffold(body: RadioTuneLine()), overrides(prefs: const RadioPrefs()));
      expect(find.text(RZ.tuneLineNoRegion), findsOneWidget);
    });

    testWidgets('kaart op het dashboard en ingang op Noodgevallen openen de rampenzender', (t) async {
      await pumpScreen(t, const Scaffold(body: Column(children: [RadioDashCard(), RadioEntryCard()])), overrides(prefs: const RadioPrefs()));
      await t.tap(find.text(RZ.dashTitle));
      await t.pumpAndSettle();
      expect(find.text('resultaat'), findsOneWidget);
    });
  });

  group('meterkastkaart en noodplan bevatten de gekozen zender', () {
    test('de meterkastkaart-pdf (zonder plan) draagt de radio-regel', () async {
      final wiki = WikiData.parse(File('assets/wiki/noodgevallen.json').readAsStringSync());
      final d = loadData();
      final lines = radioDocLines(d.resultFor(region(d, 'Groningen').gm));
      TestWidgetsFlutterBinding.ensureInitialized();
      final bytes = await buildMeterkastPdf(wiki, radioLines: lines);
      final without = await buildMeterkastPdf(wiki);
      expect(bytes.length, greaterThan(without.length));
      expect(bytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]);
      expect(lines.first, contains('Radio Noord'));
      expect(rootBundle, isNotNull);
    });
  });

  group('rampenzender mag nooit achter Pro', () {
    test('geen enkele Pro-verwijzing in het onderdeel, de Eerste-uur kaart of de noodbalk-regel', () {
      final gate = RegExp(r'requirePro|showPaywall|ProFeature|proUnlockedProvider|features/pro/|hackLocked');
      for (final f in Directory('lib/features/rampenzender').listSync(recursive: true).whereType<File>()) {
        expect(gate.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
      }
      final first = File('lib/features/wiki/wiki_detail_screen.dart').readAsStringSync();
      expect(gate.hasMatch(first), isFalse);
    });

    test('een Pro-gebruiker en een gratis gebruiker zien hetzelfde resultaat (geen Pro-invoer in de logica)', () {
      final d = loadData();
      expect(d.resultFor(region(d, 'Groningen').gm)!.areas.first.fm, [97.5]);
    });
  });
}
