import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/core/providers.dart';
import 'package:mijnnoodpakket/data/repositories/item_repository.dart';
import 'package:mijnnoodpakket/data/repositories/settings_repository.dart';
import 'package:mijnnoodpakket/domain/models.dart';
import 'package:mijnnoodpakket/features/checklist/checklist_screen.dart';
import 'package:mijnnoodpakket/features/items/item_form_screen.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_models.dart';
import 'package:mijnnoodpakket/features/noodplan/plan_providers.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_providers.dart';

class FakeRepo implements ItemRepository {
  final inHouseCalls = <(String, bool)>[];
  final saved = <(String, ItemEdit, bool)>[];

  @override
  Future<void> setInHouse(String id, bool v) async => inHouseCalls.add((id, v));
  @override
  Future<void> save(String id, ItemEdit e, {required bool custom}) async =>
      saved.add((id, e, custom));
  @override
  String newCustomId() => 'custom_test';
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Item mk(String id, String name, String cat, {bool inHouse = false, DateTime? expiry}) =>
    Item(
      id: id,
      isCustom: false,
      hidden: false,
      name: name,
      category: cat,
      why: 'Uitleg bij $name',
      unit: 'stuks',
      recommended: 2,
      inHouse: inHouse,
      expiryDate: expiry,
    );

Widget wrap(Widget child, List<Override> overrides, {GoRouter? router}) =>
    ProviderScope(
      overrides: overrides,
      child: router != null
          ? MaterialApp.router(
              routerConfig: router,
              locale: const Locale('nl', 'NL'),
              supportedLocales: const [Locale('nl', 'NL')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
            )
          : MaterialApp(
              home: child,
              locale: const Locale('nl', 'NL'),
              supportedLocales: const [Locale('nl', 'NL')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
            ),
    );

/// Hoog scherm: de nieuwe opmaak heeft meer witruimte, dus meer lijst buiten beeld.
void tall(WidgetTester t) {
  t.view.physicalSize = const Size(800, 2600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  setUpAll(() => initializeDateFormatting('nl_NL'));

  group('checklist', () {
    final items = [
      mk('a', 'Zaklamp', Cat.light, inHouse: true),
      mk('b', 'Radio', Cat.info),
      mk('c', 'Drinkwater', Cat.water,
          expiry: DateTime.now().add(const Duration(days: 5))),
    ];

    List<Override> overrides(FakeRepo repo) => [
          visibleItemsProvider.overrideWithValue(AsyncValue.data(items)),
          settingsProvider.overrideWith(
              (ref) => Stream.value(const AppSettings(planBannerDismissed: true))),
          itemRepositoryProvider.overrideWithValue(repo),
          planProvider.overrideWith((ref) => Stream.value(const Plan())),
        ];

    testWidgets('toont categorieën, items en voortgang', (t) async {
      tall(t);
      await t.pumpWidget(wrap(const ChecklistScreen(), overrides(FakeRepo())));
      await t.pumpAndSettle();
      expect(find.text(S.progressTotal(1, 3)), findsOneWidget);
      expect(find.text('Zaklamp'), findsOneWidget);
      expect(find.text(S.catWater), findsOneWidget);
    });

    testWidgets('filter Nog nodig verbergt items die in huis zijn', (t) async {
      tall(t);
      await t.pumpWidget(wrap(const ChecklistScreen(), overrides(FakeRepo())));
      await t.pumpAndSettle();
      await t.tap(find.text(S.filterNeeded));
      await t.pumpAndSettle();
      expect(find.text('Zaklamp'), findsNothing);
      expect(find.text('Radio'), findsOneWidget);
    });

    testWidgets('filter Bijna verlopen en zoeken', (t) async {
      tall(t);
      await t.pumpWidget(wrap(const ChecklistScreen(), overrides(FakeRepo())));
      await t.pumpAndSettle();
      await t.tap(find.text(S.filterExpiring));
      await t.pumpAndSettle();
      expect(find.text('Drinkwater'), findsOneWidget);
      expect(find.text('Radio'), findsNothing);

      await t.tap(find.text(S.filterAll));
      await t.enterText(find.byType(TextField), 'rad');
      await t.pumpAndSettle();
      expect(find.text('Radio'), findsOneWidget);
      expect(find.text('Zaklamp'), findsNothing);
    });

    testWidgets('afvinken roept de repository aan', (t) async {
      final repo = FakeRepo();
      tall(t);
      await t.pumpWidget(wrap(const ChecklistScreen(), overrides(repo)));
      await t.pumpAndSettle();
      await t.tap(find.byType(Checkbox).at(1)); // Radio (tweede in categorie-volgorde: info)
      await t.pump();
      expect(repo.inHouseCalls, isNotEmpty);
    });

    test('filterItems: lege zoekterm en categorie-zoek', () {
      final r = filterItems(items,
          filter: ChecklistFilter.all,
          query: 'licht',
          now: DateTime.now(),
          leadDays: 30);
      expect(r.map((i) => i.id), ['a']); // categorie "Licht en warmte"
    });
  });

  group('itemformulier', () {
    Future<(FakeRepo, GoRouter)> open(WidgetTester t, String id, List<Item> all) async {
      t.view.physicalSize = const Size(800, 3000); // hoog genoeg: hele formulier zichtbaar
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final repo = FakeRepo();
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('home'))),
        GoRoute(
            path: '/item/:id',
            builder: (_, s) => ItemFormScreen(itemId: s.pathParameters['id']!)),
      ]);
      await t.pumpWidget(wrap(const SizedBox(), [
        allItemsProvider.overrideWithValue(AsyncValue.data(all)),
        settingsProvider.overrideWith((ref) => Stream.value(const AppSettings())),
        itemRepositoryProvider.overrideWithValue(repo),
        wikiProvider.overrideWith((ref) async => throw StateError('geen wiki in dit test')),
      ], router: router));
      router.push('/item/$id');
      await t.pumpAndSettle();
      return (repo, router);
    }

    testWidgets('nieuw item: naam is verplicht', (t) async {
      final (repo, _) = await open(t, 'new', const []);
      await t.tap(find.text(S.save));
      await t.pumpAndSettle();
      expect(find.text(S.requiredField), findsOneWidget);
      expect(repo.saved, isEmpty);
    });

    testWidgets('nieuw item: opslaan met naam en aantal', (t) async {
      final (repo, _) = await open(t, 'new', const []);
      await t.enterText(find.widgetWithText(TextFormField, S.fieldName), 'Thermoskan');
      await t.enterText(find.widgetWithText(TextFormField, S.fieldHave), '2,5');
      await t.scrollUntilVisible(find.text(S.save), 200,
          scrollable: find.byType(Scrollable).first);
      await t.tap(find.text(S.save));
      await t.pumpAndSettle();
      expect(repo.saved, hasLength(1));
      final (id, edit, custom) = repo.saved.single;
      expect(id, 'custom_test');
      expect(custom, isTrue);
      expect(edit.name, 'Thermoskan');
      expect(edit.quantityHave, 2.5);
      expect(find.text('home'), findsOneWidget); // scherm gesloten
    });

    testWidgets('itemdetail toont geen "Handig bij" of "Handige hacks" meer', (t) async {
      await open(t, 'radio', [mk('radio', 'Radio', Cat.info), mk('stove', 'Kooktoestel', Cat.light)]);
      expect(find.text(S.whyTitle), findsOneWidget); // de rest van het detail blijft
      expect(find.textContaining('Handig bij'), findsNothing);
      expect(find.textContaining('Handige hacks'), findsNothing);
      expect(find.byType(ActionChip), findsNothing);
    });

    testWidgets('standaarditem: toont uitleg en aanbevolen hoeveelheid', (t) async {
      await open(t, 'a', [mk('a', 'Zaklamp', Cat.light)]);
      expect(find.text('Zaklamp'), findsOneWidget);
      expect(find.text(S.whyTitle), findsOneWidget);
      expect(find.text('Uitleg bij Zaklamp'), findsOneWidget);
      expect(find.text(S.recommendedValue('2', 'stuks')), findsOneWidget);
      expect(find.text(S.hideItem), findsOneWidget);
    });

    testWidgets('ongeldig getal geeft een foutmelding', (t) async {
      final (repo, _) = await open(t, 'a', [mk('a', 'Zaklamp', Cat.light)]);
      await t.enterText(find.widgetWithText(TextFormField, S.fieldHave), 'abc');
      await t.scrollUntilVisible(find.text(S.save), 200,
          scrollable: find.byType(Scrollable).first);
      await t.tap(find.text(S.save));
      await t.pumpAndSettle();
      expect(find.text(S.invalidNumber), findsOneWidget);
      expect(repo.saved, isEmpty);
    });
  });
}
