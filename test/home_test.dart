import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/core/providers.dart';
import 'package:mijnnoodpakket/data/repositories/settings_repository.dart';
import 'package:mijnnoodpakket/domain/models.dart';
import 'package:mijnnoodpakket/features/home/home_screen.dart';
import 'package:mijnnoodpakket/features/kluis/data/vault_controller.dart';
import 'package:mijnnoodpakket/features/more/more_screen.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_models.dart';
import 'package:mijnnoodpakket/features/noodplan/plan_providers.dart';

Item item(String id, String cat, {bool inHouse = false, DateTime? expiry}) => Item(
      id: id,
      isCustom: false,
      hidden: false,
      name: id,
      category: cat,
      why: '',
      unit: 'stuks',
      recommended: 1,
      inHouse: inHouse,
      expiryDate: expiry,
    );

void main() {
  setUpAll(() => initializeDateFormatting('nl_NL'));
  final now = DateTime(2026, 11, 10);

  group('volgende stappen', () {
    final items = [
      item('a', Cat.water, inHouse: true),
      item('b', Cat.water),
      item('c', Cat.light),
      item('d', Cat.light),
      item('e', Cat.info, inHouse: true),
    ];

    test('plan eerst, dan de zwakste categorie, dan de kluis; maximaal 3', () {
      final s = nextSteps(items: items, leadDays: 30, planStarted: false, vaultHasDocs: false, now: now);
      expect(s.map((e) => e.kind), ['plan', 'category', 'vault']);
      expect(s[1].title, S.homeStepCategory('Licht en warmte')); // 0 van 2 is het laagst
      expect(s[1].sub, S.homeStepCategorySub(0, 2));
    });

    test('bijna verlopen items krijgen een eigen stap naar het tabblad Vervangen', () {
      final withExpiring = [...items, item('x', Cat.health, inHouse: true, expiry: DateTime(2026, 11, 20))];
      final s = nextSteps(items: withExpiring, leadDays: 30, planStarted: true, vaultHasDocs: true, now: now);
      expect(s.first.kind, 'expiring');
      expect(s.first.route, '/checklist?tab=vervangen');
      expect(s.first.title, S.homeStepExpiring(1));
    });

    test('alles klaar: geen stappen', () {
      final done = [item('a', Cat.water, inHouse: true)];
      expect(nextSteps(items: done, leadDays: 30, planStarted: true, vaultHasDocs: true, now: now), isEmpty);
    });

    test('lege lijst crasht niet', () {
      expect(nextSteps(items: const [], leadDays: 30, planStarted: true, vaultHasDocs: true, now: now), isEmpty);
    });
  });

  Widget app(Widget home, List<Override> overrides) => ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          home: home,
          locale: const Locale('nl', 'NL'),
          supportedLocales: const [Locale('nl', 'NL')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
      );

  testWidgets('startscherm: voortgang, 112, eerste uur en suggesties', (t) async {
    t.view.physicalSize = const Size(800, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app(const HomeScreen(), [
      visibleItemsProvider.overrideWithValue(AsyncValue.data([
        item('a', Cat.water, inHouse: true),
        item('b', Cat.water),
      ])),
      settingsProvider.overrideWith((ref) => Stream.value(const AppSettings())),
      planProvider.overrideWith((ref) => Stream.value(const Plan())),
      vaultHasDocsProvider.overrideWith((ref) => Stream.value(false)),
    ]));
    await t.pumpAndSettle();
    expect(find.text(S.homeTitle), findsOneWidget);
    expect(find.text(S.progressTotal(1, 2)), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text(S.wikiCall112), findsOneWidget);
    expect(find.text(S.homeFirstHour), findsOneWidget);
    expect(find.text(S.homeStepPlan), findsOneWidget);
    expect(find.text(S.homeStepVault), findsOneWidget);
    expect(find.text(S.disclaimer), findsOneWidget);
  });

  testWidgets('Meer: noodplan, kluis, informatie en instellingen', (t) async {
    await t.pumpWidget(app(const MoreScreen(), const []));
    await t.pumpAndSettle();
    for (final s in [S.planTitle, S.vaultTitle, S.infoTitle, S.settingsTitle]) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
  });
}
