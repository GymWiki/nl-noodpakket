import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/features/deel/deel_providers.dart';
import 'package:mijnnoodpakket/features/deel/domain/shared_plan_logic.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/core/providers.dart';
import 'package:mijnnoodpakket/data/repositories/plan_repository.dart';
import 'package:mijnnoodpakket/data/repositories/settings_repository.dart';
import 'package:mijnnoodpakket/domain/models.dart';
import 'package:mijnnoodpakket/features/kluis/data/vault_controller.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_links.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_models.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_reminder.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_share.dart';
import 'package:mijnnoodpakket/features/noodplan/plan_providers.dart';
import 'package:mijnnoodpakket/features/noodplan/ui/plan_overview_screen.dart';
import 'package:mijnnoodpakket/features/noodplan/ui/plan_pdf.dart';
import 'package:mijnnoodpakket/features/noodplan/ui/plan_share_screen.dart';
import 'package:mijnnoodpakket/features/noodplan/ui/plan_talk_screen.dart';
import 'package:mijnnoodpakket/features/noodplan/ui/plan_wizard_screen.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_detail_screen.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_models.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_providers.dart';

/// Eenvoudige in-memory vervanger van PlanRepository (geen database nodig).
class FakePlanRepo implements PlanRepository {
  FakePlanRepo([this.plan = const Plan()]);
  Plan plan;
  final _c = StreamController<Plan>.broadcast();
  final skippedCalls = <PlanSection>[];
  final steps = <int>[];
  var _nextId = 1;

  /// Geeft meteen het huidige plan en daarna elke wijziging (zonder race).
  Stream<Plan> stream() {
    late StreamController<Plan> sc;
    StreamSubscription<Plan>? sub;
    sc = StreamController<Plan>(
      onListen: () {
        sc.add(plan);
        sub = _c.stream.listen(sc.add);
      },
      onCancel: () => sub?.cancel(),
    );
    return sc.stream;
  }

  Future<void> close() => _c.close();

  void _set(Plan p) {
    plan = p;
    _c.add(p);
  }

  Plan _copy({
    String? householdName,
    List<PlanMember>? members,
    List<PlanContact>? contacts,
    Map<String, PlanPlace>? places,
    Map<String, String>? agreements,
    Map<String, PlanLocation>? locations,
    Set<PlanSection>? skipped,
    int? wizardStep,
    String? devices,
  }) =>
      Plan(
        householdName: householdName ?? plan.householdName,
        members: members ?? plan.members,
        contacts: contacts ?? plan.contacts,
        places: places ?? plan.places,
        agreements: agreements ?? plan.agreements,
        locations: locations ?? plan.locations,
        medication: plan.medication,
        devices: devices ?? plan.devices,
        allergies: plan.allergies,
        caregiving: plan.caregiving,
        documents: plan.documents,
        skipped: skipped ?? plan.skipped,
        wizardStep: wizardStep ?? plan.wizardStep,
        sharedVersion: plan.sharedVersion,
        updatedAt: plan.updatedAt,
        lastSharedAt: plan.lastSharedAt,
      );

  @override
  Future<Plan> load() async => plan;
  @override
  Future<void> setHouseholdName(String name) async => _set(_copy(householdName: name));
  @override
  Future<int> addMember(PlanMember m) async {
    final id = _nextId++;
    _set(_copy(members: [...plan.members, PlanMember(id: id, name: m.name, isPet: m.isPet, ageGroup: m.ageGroup, needsHelp: m.needsHelp)]));
    return id;
  }

  @override
  Future<void> updateMember(PlanMember m) async =>
      _set(_copy(members: [for (final e in plan.members) e.id == m.id ? m : e]));
  @override
  Future<void> deleteMember(int id) async =>
      _set(_copy(members: [for (final e in plan.members) if (e.id != id) e]));
  @override
  Future<void> prefillMembers(Household h,
      {required String Function(String ageGroup, int n) personName, required String petName}) async {
    if (plan.members.isNotEmpty) return;
    final list = <PlanMember>[
      for (var i = 1; i <= h.adults; i++) PlanMember(id: _nextId++, name: personName('adult', i)),
      for (var i = 1; i <= h.children; i++)
        PlanMember(id: _nextId++, name: personName('child', i), ageGroup: 'child'),
    ];
    _set(_copy(members: list));
  }

  @override
  Future<int> addContact(PlanContact c) async {
    final id = _nextId++;
    _set(_copy(contacts: [
      ...plan.contacts,
      PlanContact(id: id, role: c.role, name: c.name, relation: c.relation, phone: c.phone),
    ]));
    return id;
  }

  @override
  Future<void> deleteContact(int id) async =>
      _set(_copy(contacts: [for (final e in plan.contacts) if (e.id != id) e]));
  @override
  Future<void> setPlace(String kind, {String? address, String? notes}) async => _set(_copy(places: {
        ...plan.places,
        kind: PlanPlace(
            kind: kind,
            address: address ?? plan.places[kind]?.address ?? '',
            notes: notes ?? plan.places[kind]?.notes ?? ''),
      }));
  @override
  Future<void> setAgreement(String key, String body) async =>
      _set(_copy(agreements: {...plan.agreements, key: body}));
  @override
  Future<void> setLocation(String key, String body) async =>
      _set(_copy(locations: {...plan.locations, key: PlanLocation(key: key, body: body)}));
  @override
  Future<void> setCare({String? medication, String? devices, String? allergies, String? caregiving, String? documents}) async =>
      _set(_copy(devices: devices));
  @override
  Future<void> setSkipped(PlanSection s, bool skipped, Set<PlanSection> current) async {
    skippedCalls.add(s);
    _set(_copy(skipped: {...current, s}));
  }

  @override
  Future<void> setWizardStep(int step) async => steps.add(step);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

final wiki = WikiData.parse(File('assets/wiki/noodgevallen.json').readAsStringSync());

Future<FakePlanRepo> pumpApp(
  WidgetTester t, {
  required String start,
  Plan plan = const Plan(),
  AppSettings settings = const AppSettings(household: Household(adults: 2, children: 1)),
  FakePlanRepo? repo,
}) async {
  t.view.physicalSize = const Size(800, 3200);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final r = repo ?? FakePlanRepo(plan);
  addTearDown(r.close);
  final router = GoRouter(initialLocation: '/start', routes: [
    GoRoute(
      path: '/start',
      builder: (c, _) => Scaffold(
        body: Center(child: FilledButton(onPressed: () => c.push(start), child: const Text('open'))),
      ),
    ),
    GoRoute(path: '/plan', builder: (_, _) => const PlanOverviewScreen()),
    GoRoute(
      path: '/plan/wizard',
      builder: (_, st) => PlanWizardScreen(
          section: PlanSection.values.asNameMap()[st.uri.queryParameters['s']]),
    ),
    GoRoute(path: '/plan/delen', builder: (_, _) => const PlanShareScreen()),
    GoRoute(path: '/plan/gesprek', builder: (_, _) => const PlanTalkScreen()),
    GoRoute(path: '/wiki/:id', builder: (_, st) => WikiDetailScreen(id: st.pathParameters['id']!)),
    GoRoute(path: '/item/:id', builder: (_, st) => Scaffold(body: Text('item ${st.pathParameters['id']}'))),
  ]);
  final List<Override> overrides = [
    planRepositoryProvider.overrideWithValue(r),
    planProvider.overrideWith((ref) => r.stream()),
    sharedPlansProvider.overrideWith((ref) => Stream.value(const <SharedPlan>[])),
    settingsProvider.overrideWith((ref) => Stream.value(settings)),
    wikiProvider.overrideWith((ref) async => wiki),
    wikiFavoritesProvider.overrideWith((ref) => Stream.value(<String>{})),
    vaultHasDocsProvider.overrideWith((ref) => Stream.value(false)),
    allItemsProviderOverride(),
  ];
  await t.pumpWidget(ProviderScope(
    overrides: overrides,
    // Net als in de echte app wordt de instellingen-stream altijd beluisterd.
    child: Consumer(builder: (context, ref, _) {
      ref.watch(settingsProvider);
      return MaterialApp.router(
        routerConfig: router,
        locale: const Locale('nl', 'NL'),
        supportedLocales: const [Locale('nl', 'NL')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      );
    }),
  ));
  await t.pumpAndSettle();
  await t.tap(find.text('open'));
  await t.pumpAndSettle();
  return r;
}

Override allItemsProviderOverride() =>
    allItemsProvider.overrideWithValue(const AsyncValue.data(<Item>[]));

void main() {
  setUpAll(() => initializeDateFormatting('nl_NL'));

  group('wizard', () {
    testWidgets('vult het huishouden voor uit de instellingen en toont voortgang', (t) async {
      await pumpApp(t, start: '/plan/wizard');
      expect(find.text(S.planStepOf(1, 8)), findsOneWidget);
      expect(find.text('Volwassene 1'), findsOneWidget);
      expect(find.text('Volwassene 2'), findsOneWidget);
      expect(find.text('Kind 1'), findsOneWidget);
      expect(find.text(S.planHhPrefilled), findsOneWidget);
    });

    testWidgets('typen wordt automatisch opgeslagen (met korte vertraging)', (t) async {
      final repo = await pumpApp(t, start: '/plan/wizard');
      await t.enterText(find.widgetWithText(TextField, S.planHhName), 'Familie Test');
      await t.pump(const Duration(milliseconds: 700));
      expect(repo.plan.householdName, 'Familie Test');
    });

    testWidgets('niets kwijt bij snel doorklikken: opslaan bij verlaten van het onderdeel', (t) async {
      final repo = await pumpApp(t, start: '/plan/wizard?s=agreements');
      await t.enterText(find.widgetWithText(TextField, S.planAgrCheckin), 'Elk uur een sms');
      // meteen door, zonder te wachten op de vertraging
      await t.tap(find.text(S.planNextStep));
      await t.pumpAndSettle();
      expect(repo.plan.agreement(PlanKeys.checkin), 'Elk uur een sms');
    });

    testWidgets('suggestie-chip vult de afspraak in', (t) async {
      final repo = await pumpApp(t, start: '/plan/wizard?s=agreements');
      await t.tap(find.text(S.planSugCheckin.first));
      await t.pump(const Duration(milliseconds: 700));
      expect(repo.plan.agreement(PlanKeys.checkin), S.planSugCheckin.first);
    });

    testWidgets('overslaan: onderdeel wordt overgeslagen en volgend onderdeel opent', (t) async {
      final repo = await pumpApp(t, start: '/plan/wizard?s=care');
      await t.tap(find.text(S.planSkip));
      await t.pumpAndSettle();
      expect(repo.skippedCalls, [PlanSection.care]);
      expect(find.text(S.planStepOf(7, 8)), findsOneWidget);
      expect(repo.steps.last, 6);
    });

    testWidgets('later afmaken sluit de wizard en onthoudt de stap', (t) async {
      final repo = await pumpApp(t, start: '/plan/wizard?s=home');
      await t.tap(find.text(S.planLater));
      await t.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
      // de stap wordt bij navigeren opgeslagen
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await t.tap(find.text(S.planNextStep));
      await t.pumpAndSettle();
      expect(repo.steps, contains(5));
    });

    testWidgets('contact toevoegen via handmatig invullen', (t) async {
      final repo = await pumpApp(t, start: '/plan/wizard?s=contacts');
      await t.tap(find.text(S.planAdd).first);
      await t.pumpAndSettle();
      await t.enterText(find.widgetWithText(TextField, S.planContactName), 'Oma');
      await t.enterText(find.widgetWithText(TextField, S.planContactPhone), '0612345678');
      await t.tap(find.text(S.planSaveDialog));
      await t.pumpAndSettle();
      expect(repo.plan.contacts.single.role, PlanKeys.roleOutside);
      expect(repo.plan.contacts.single.phone, '0612345678');
      expect(find.text('Oma'), findsOneWidget);
    });

    testWidgets('contactdialoog vraagt om naam of nummer', (t) async {
      final repo = await pumpApp(t, start: '/plan/wizard?s=contacts');
      await t.tap(find.text(S.planAdd).first);
      await t.pumpAndSettle();
      await t.tap(find.text(S.planSaveDialog));
      await t.pumpAndSettle();
      expect(find.text(S.planContactNumberOrName), findsOneWidget);
      expect(repo.plan.contacts, isEmpty);
    });

    testWidgets('half ingevuld plan blijft bruikbaar: samenvatting toont statussen', (t) async {
      await pumpApp(t, start: '/plan/wizard?s=neighbours', plan: Plan(
        members: const [PlanMember(name: 'A')],
        agreements: const {PlanKeys.checkin: 'x'},
      ));
      await t.tap(find.text(S.planFinish));
      await t.pumpAndSettle();
      expect(find.text(S.planStepOf(8, 8)), findsOneWidget);
      expect(find.text(S.planStatusDone), findsWidgets);
      expect(find.text(S.planStatusPartial), findsWidgets);
      expect(find.text(S.planStoredLocal), findsOneWidget);
    });

    testWidgets('lege samenvatting is rustig, geen fout', (t) async {
      await pumpApp(t, start: '/plan/wizard?s=neighbours', settings: const AppSettings());
      await t.tap(find.text(S.planFinish));
      await t.pumpAndSettle();
      expect(find.text(S.planSummaryEmpty), findsOneWidget);
    });
  });

  group('overzicht', () {
    testWidgets('toont voortgang en gewijzigd-sinds-delen melding', (t) async {
      await pumpApp(t, start: '/plan', plan: Plan(
        members: const [PlanMember(name: 'A')],
        updatedAt: DateTime(2026, 3, 1),
        lastSharedAt: DateTime(2026, 2, 1),
      ));
      expect(find.text(S.planCardSub(1, 7)), findsOneWidget);
      expect(find.text(S.planChangedSinceShare), findsOneWidget);
      expect(find.text(S.planContinue), findsOneWidget);
    });

    testWidgets('leeg plan: uitnodigende start, geen waarschuwing', (t) async {
      await pumpApp(t, start: '/plan');
      expect(find.text(S.planStartPlan), findsOneWidget);
      expect(find.text(S.planChangedSinceShare), findsNothing);
    });

    testWidgets('banner', (t) async {
      t.view.physicalSize = const Size(800, 3200);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final r = FakePlanRepo();
      await t.pumpWidget(ProviderScope(
        overrides: [
          planProvider.overrideWith((ref) => r.stream()),
          sharedPlansProvider.overrideWith((ref) => Stream.value(const <SharedPlan>[])),
          settingsProvider.overrideWith((ref) => Stream.value(const AppSettings())),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Column(children: [PlanBanner()])),
        ),
      ));
      await t.pumpAndSettle();
      expect(find.text(S.planBannerText), findsOneWidget);
    });

    testWidgets('banner verdwijnt als weggeklikt of als er een plan is', (t) async {
      final r = FakePlanRepo(const Plan(householdName: 'X'));
      await t.pumpWidget(ProviderScope(
        overrides: [
          planProvider.overrideWith((ref) => r.stream()),
          sharedPlansProvider.overrideWith((ref) => Stream.value(const <SharedPlan>[])),
          settingsProvider.overrideWith((ref) => Stream.value(const AppSettings())),
        ],
        child: const MaterialApp(home: Scaffold(body: PlanBanner())),
      ));
      await t.pumpAndSettle();
      expect(find.text(S.planBannerText), findsNothing);
      await t.pumpWidget(ProviderScope(
        overrides: [
          planProvider.overrideWith((ref) => FakePlanRepo().stream()),
          sharedPlansProvider.overrideWith((ref) => Stream.value(const <SharedPlan>[])),
          settingsProvider.overrideWith(
              (ref) => Stream.value(const AppSettings(planBannerDismissed: true))),
        ],
        child: const MaterialApp(home: Scaffold(body: PlanBanner())),
      ));
      await t.pumpAndSettle();
      expect(find.text(S.planBannerText), findsNothing);
    });
  });

  group('delen', () {
    final filled = Plan(
      householdName: 'Familie X',
      members: const [PlanMember(name: 'Anna')],
      contacts: const [PlanContact(role: PlanKeys.roleOutside, name: 'Oma', phone: '0611111111')],
      medication: 'Anna: bloeddrukmedicatie',
    );

    testWidgets('zorg en foto\'s staan standaard uit; waarschuwing is zichtbaar', (t) async {
      await pumpApp(t, start: '/plan/delen', plan: filled);
      expect(find.text(S.planShareWarn), findsOneWidget);
      final care = t.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, S.planSecCare));
      final photos = t.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, S.planSharePhotos));
      expect(care.value, isFalse);
      expect(photos.value, isFalse);
      expect(find.textContaining('bloeddruk'), findsNothing);
      expect(find.textContaining('0611111111'), findsOneWidget);
    });

    testWidgets('zorg aanzetten toont medische info in het voorbeeld, uitzetten van contacten verbergt nummers', (t) async {
      await pumpApp(t, start: '/plan/delen', plan: filled);
      await t.tap(find.widgetWithText(SwitchListTile, S.planSecCare));
      await t.pumpAndSettle();
      expect(find.textContaining('bloeddruk'), findsOneWidget);
      await t.tap(find.widgetWithText(SwitchListTile, S.planSecContacts));
      await t.pumpAndSettle();
      expect(find.textContaining('0611111111'), findsNothing);
    });

    testWidgets('delen is uitgeschakeld bij een leeg plan', (t) async {
      await pumpApp(t, start: '/plan/delen');
      final b = t.widget<ButtonStyleButton>(find.ancestor(
          of: find.text(S.planSharePdf), matching: find.bySubtype<ButtonStyleButton>()));
      expect(b.onPressed, isNull);
    });
  });

  group('wiki: Jouw afspraken', () {
    testWidgets('toont ingevulde afspraken uit het plan', (t) async {
      await pumpApp(t, start: '/wiki/gaslucht', plan: Plan(locations: const {
        PlanKeys.meterkast: PlanLocation(key: PlanKeys.meterkast, body: 'Naast de voordeur'),
        PlanKeys.gasMain: PlanLocation(key: PlanKeys.gasMain, body: 'Onder de trap'),
      }));
      expect(find.text(S.planWikiBlock), findsOneWidget);
      expect(find.text('Naast de voordeur'), findsOneWidget);
      expect(find.text('Onder de trap'), findsOneWidget);
      expect(find.text(S.planWikiEdit), findsOneWidget);
    });

    testWidgets('leeg deel: knop "Vul dit in" opent de wizard bij het juiste onderdeel', (t) async {
      await pumpApp(t, start: '/wiki/gaslucht');
      expect(find.text(S.planWikiEmpty), findsWidgets);
      await t.tap(find.text(S.planWikiFill));
      await t.pumpAndSettle();
      expect(find.text(S.planStepOf(5, 8)), findsOneWidget); // Thuis
    });

    testWidgets('noodgevallen zonder koppeling tonen geen blok', (t) async {
      await pumpApp(t, start: '/wiki/brandwond');
      expect(find.text(S.planWikiBlock), findsNothing);
    });

    test('alle koppelingen verwijzen naar bestaande noodgevallen', () {
      // import hier om circulaire testimport te vermijden
      final ids = {for (final e in wiki.emergencies) e.id, wiki.eersteUur.id};
      for (final k in planLinks.keys) {
        expect(ids, contains(k), reason: k);
      }
    });
  });

  group('gesprekskaarten', () {
    testWidgets('antwoord komt direct op de juiste plek in het plan', (t) async {
      final repo = await pumpApp(t, start: '/plan/gesprek');
      await t.tap(find.text(S.planTalkStart));
      await t.pumpAndSettle();
      expect(find.text(S.planTalkQ1), findsOneWidget);
      expect(find.text(S.planTalkSavedTo(S.planAgrKids)), findsOneWidget);
      await t.enterText(find.byType(TextField), 'Oma haalt ze op');
      await t.tap(find.text(S.planNextStep));
      await t.pumpAndSettle();
      expect(repo.plan.agreement(PlanKeys.kids), 'Oma haalt ze op');
      expect(find.text(S.planTalkQ2), findsOneWidget);
      // vraag 2 gaat naar de verzamelplek in de buurt
      await t.enterText(find.byType(TextField), 'Speeltuin');
      await t.tap(find.text(S.planNextStep));
      await t.pumpAndSettle();
      expect(repo.plan.place(PlanKeys.placeNeighbourhood)!.address, 'Speeltuin');
    });

    test('elke gesprekskaart heeft een vraag en een bestemming', () {
      expect(talkCards.length, 9);
      for (final c in talkCards) {
        expect(c.question.trim(), isNotEmpty);
        expect(c.target.label(), isNotEmpty);
      }
    });
  });

  group('pdf', () {
    test('leeg plan geeft toch een geldige, niet-lege pdf', () async {
      final bytes = await buildPlanPdf(const Plan(), const ShareOptions(),
          wiki: wiki, now: DateTime(2026, 11, 10), version: 1);
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('gevuld plan met alle onderdelen levert een pdf op', () async {
      final bytes = await buildPlanPdf(
        Plan(
          householdName: 'Familie Ëlst',
          members: const [PlanMember(name: 'Anna'), PlanMember(name: 'Bello', isPet: true)],
          contacts: const [PlanContact(role: PlanKeys.roleOutside, name: 'Oma', phone: '0611111111')],
          agreements: const {PlanKeys.checkin: 'Elk heel uur een sms'},
          locations: const {PlanKeys.meterkast: PlanLocation(key: PlanKeys.meterkast, body: 'Gang')},
          medication: 'x',
        ),
        const ShareOptions(care: true),
        wiki: wiki,
        now: DateTime(2026, 11, 10),
        version: 3,
      );
      expect(bytes.length, greaterThan(2000));
    });
  });

  group('herinnering', () {
    final now = DateTime(2026, 11, 10, 12);
    test('6 maanden na laatste bevestiging, 10:00', () {
      final p = Plan(householdName: 'x', lastConfirmedAt: DateTime(2026, 11, 1));
      expect(planReminderTime(p, now), DateTime(2027, 5, 1, 10));
    });
    test('zonder bevestiging: 6 maanden na laatste wijziging', () {
      final p = Plan(householdName: 'x', updatedAt: DateTime(2026, 10, 15));
      expect(planReminderTime(p, now), DateTime(2027, 4, 15, 10));
    });
    test('achterstallig: morgen 10:00; leeg plan: geen herinnering', () {
      final old = Plan(householdName: 'x', lastConfirmedAt: DateTime(2025, 1, 1));
      expect(planReminderTime(old, now), DateTime(2026, 11, 11, 10));
      expect(planReminderTime(const Plan(), now), isNull);
    });
  });
}
