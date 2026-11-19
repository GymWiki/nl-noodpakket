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
import 'package:mijnnoodpakket/features/items/item_form_screen.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_providers.dart';
import 'package:mijnnoodpakket/features/pro/pro_hint.dart';
import 'package:mijnnoodpakket/features/pro/pro_providers.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_providers.dart';

import 'fake_purchase.dart';
import 'paywall_variants_test.dart' show hacksData;

class _Repo implements ItemRepository {
  @override
  String newCustomId() => 'custom_test';
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Houdt bij wat er blijvend wordt opgeslagen ("Niet meer tonen").
class _Settings implements SettingsRepository {
  final saved = <String, String>{};
  @override
  Future<void> setRaw(String key, String value) async => saved[key] = value;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Item _item(String id) => Item(
      id: id,
      isCustom: true,
      hidden: false,
      name: 'Voorbeeld',
      category: Cat.other,
      why: '',
      unit: 'stuks',
      recommended: 1,
      inHouse: true,
      expiryDate: DateTime(2027, 6, 1),
    );

void main() {
  setUpAll(() => initializeDateFormatting('nl_NL'));

  late _Settings settingsRepo;
  late GoRouter router;

  Future<void> openForm(
    WidgetTester t,
    String id, {
    bool pro = false,
    Map<String, String> raw = const {},
    bool keepScope = false,
  }) async {
    t.view.physicalSize = const Size(800, 3000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    settingsRepo = _Settings();
    if (!keepScope) {
      router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('home'))),
        GoRoute(path: '/item/:id', builder: (_, s) => ItemFormScreen(itemId: s.pathParameters['id']!)),
      ]);
      await t.pumpWidget(ProviderScope(
        overrides: <Override>[
          allItemsProvider.overrideWithValue(AsyncValue.data([_item('bestaand')])),
          settingsProvider.overrideWith((ref) => Stream.value(AppSettings(raw: raw))),
          itemRepositoryProvider.overrideWithValue(_Repo()),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          wikiProvider.overrideWith((ref) async => throw StateError('geen wiki in deze test')),
          hacksProvider.overrideWith((ref) => hacksData),
          proUnlockedProvider.overrideWithValue(pro),
          purchaseServiceProvider.overrideWithValue(FakePurchaseService()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('nl', 'NL'),
          supportedLocales: const [Locale('nl', 'NL')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
      ));
    }
    router.push('/item/$id');
    await t.pumpAndSettle();
  }

  /// De gebruiker kiest zelf een houdbaarheidsdatum.
  Future<void> pickDate(WidgetTester t) async {
    await t.tap(find.text(S.fieldExpiry));
    await t.pumpAndSettle();
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
  }

  final hint = find.byKey(const Key('pro-hint'));

  testWidgets('geen hint bij het openen: alleen na een bewuste actie van de gebruiker', (t) async {
    await openForm(t, 'new');
    expect(hint, findsNothing);
    expect(find.byKey(const Key('paywall-not-now')), findsNothing);
  });

  testWidgets('direct na het invullen van een houdbaarheidsdatum: één rustige, niet-modale rij', (t) async {
    await openForm(t, 'new');
    await pickDate(t);
    expect(hint, findsOneWidget);
    expect(find.text(S.proHintReminder), findsOneWidget);
    expect(find.byKey(const Key('pro-hint-close')), findsOneWidget);
    expect(find.text(S.proHintHide), findsOneWidget);
    expect(find.byKey(const Key('paywall-not-now')), findsNothing); // geen modale paywall
    // Het formulier blijft gewoon bruikbaar.
    expect(find.text(S.save), findsOneWidget);
  });

  testWidgets('tikdoelen zijn minstens 48 dp', (t) async {
    await openForm(t, 'new');
    await pickDate(t);
    // Het tikvlak van de tekst is de InkWell eromheen, niet de tekst zelf.
    final textTarget = find.ancestor(of: find.text(S.proHintReminder), matching: find.byType(InkWell)).first;
    for (final f in [find.byKey(const Key('pro-hint-close')), find.byKey(const Key('pro-hint-hide')), textTarget]) {
      expect(t.getSize(f).height, greaterThanOrEqualTo(48), reason: '$f');
    }
    expect(t.getSize(find.byKey(const Key('pro-hint-close'))).width, greaterThanOrEqualTo(48));
  });

  testWidgets('tik op de tekst opent de paywall met de herinneringen-variant', (t) async {
    await openForm(t, 'new');
    await pickDate(t);
    await t.tap(find.text(S.proHintReminder));
    await t.pumpAndSettle();
    expect(find.text(S.paywallRemindTitle), findsOneWidget);
  });

  testWidgets('het kruisje verbergt de hint alleen nu en slaat niets op', (t) async {
    await openForm(t, 'new');
    await pickDate(t);
    await t.tap(find.byKey(const Key('pro-hint-close')));
    await t.pumpAndSettle();
    expect(hint, findsNothing);
    expect(settingsRepo.saved, isEmpty);
  });

  testWidgets('"Niet meer tonen" bewaart de keuze blijvend', (t) async {
    await openForm(t, 'new');
    await pickDate(t);
    await t.tap(find.text(S.proHintHide));
    await t.pumpAndSettle();
    expect(hint, findsNothing);
    expect(settingsRepo.saved[proHintsHiddenKey], '["${ProHint.reminderAfterDate.id}"]');
  });

  testWidgets('een blijvend verborgen hint komt niet terug', (t) async {
    await openForm(t, 'new', raw: {proHintsHiddenKey: '["${ProHint.reminderAfterDate.id}"]'});
    await pickDate(t);
    expect(hint, findsNothing);
  });

  testWidgets('wie de oude dashboardregel al wegklikte, krijgt deze hint niet', (t) async {
    await openForm(t, 'new', raw: {proHintDismissedKey: 'true'});
    await pickDate(t);
    expect(hint, findsNothing);
  });

  testWidgets('maximaal één hint per sessie: een tweede formulier krijgt hem niet meer', (t) async {
    await openForm(t, 'new');
    await pickDate(t);
    expect(hint, findsOneWidget);
    router.pop();
    await t.pumpAndSettle();
    await openForm(t, 'new', keepScope: true);
    await pickDate(t);
    expect(hint, findsNothing);
  });

  testWidgets('met Pro verschijnt er geen hint', (t) async {
    await openForm(t, 'new', pro: true);
    await pickDate(t);
    expect(hint, findsNothing);
  });

  testWidgets('een bestaand item heeft al de schakelaar: geen extra hint', (t) async {
    await openForm(t, 'bestaand');
    await pickDate(t);
    expect(hint, findsNothing);
    expect(find.text(S.remindSwitch), findsOneWidget);
  });
}
