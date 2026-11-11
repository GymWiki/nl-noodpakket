import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/core/notifications/notification_service.dart';
import 'package:mijnnoodpakket/core/providers.dart';
import 'package:mijnnoodpakket/data/db/database.dart';
import 'package:mijnnoodpakket/data/repositories/settings_repository.dart';
import 'package:mijnnoodpakket/domain/models.dart';
import 'package:mijnnoodpakket/features/dashboard/dashboard_cards.dart';
import 'package:mijnnoodpakket/features/dashboard/dashboard_providers.dart';
import 'package:mijnnoodpakket/features/expiry/reminder_items.dart';
import 'package:mijnnoodpakket/features/kluis/data/vault_controller.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_models.dart';
import 'package:mijnnoodpakket/features/noodplan/plan_providers.dart';
import 'package:mijnnoodpakket/features/pro/pro_providers.dart';
import 'package:mijnnoodpakket/features/pro/pro_ui.dart';

import 'fake_purchase.dart';

class FakeNotifications implements NotificationService {
  int permissionAsks = 0;
  bool grant = true;

  @override
  Future<bool> requestPermission() async {
    permissionAsks++;
    return grant;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Widget host(List<Override> o, Widget child) => ProviderScope(
      overrides: o,
      child: MaterialApp(
        locale: const Locale('nl', 'NL'),
        supportedLocales: const [Locale('nl', 'NL')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  setUpAll(() => initializeDateFormatting('nl_NL'));

  group('schakelaar "Herinner mij vóór het verloopt"', () {
    late AppDatabase db;
    late FakeNotifications notif;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      notif = FakeNotifications();
    });
    tearDown(() => db.close());

    Widget switchTile() => Consumer(builder: (context, ref, _) {
          final pro = ref.watch(proUnlockedProvider);
          final on = ref.watch(reminderItemsProvider).contains('x');
          return SwitchListTile(
            title: const Text(S.remindSwitch),
            subtitle: Text(on && !pro ? S.remindProOnly : (pro ? S.remindSwitchSub : S.remindProOnlySub)),
            value: on,
            onChanged: (v) => toggleItemReminder(context, ref, 'x', v),
          );
        });

    List<Override> base({required bool pro, Set<String> ids = const {}}) => [
          databaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(notif),
          purchaseServiceProvider.overrideWithValue(FakePurchaseService()),
          proUnlockedProvider.overrideWithValue(pro),
          reminderItemsProvider.overrideWithValue(ids),
        ];

    testWidgets('zonder Pro: rustige uitleg; aanzetten opent de paywall en slaat niets op', (t) async {
      t.view.physicalSize = const Size(800, 3000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(host(base(pro: false), switchTile()));
      expect(find.text(S.remindProOnlySub), findsOneWidget);
      await t.tap(find.byType(Switch));
      await t.pumpAndSettle();
      expect(find.text(S.paywallTitle), findsOneWidget);
      expect(notif.permissionAsks, 0); // geen meldingspermissie zonder Pro
      final stored = await t.runAsync(() => SettingsRepository(db).getRaw(remindItemsKey));
      expect(stored, isNull);
    });

    testWidgets('met Pro: aanzetten bewaart de keuze en vraagt dan pas om meldingen', (t) async {
      await t.pumpWidget(host(base(pro: true), switchTile()));
      expect(find.text(S.remindSwitchSub), findsOneWidget);
      expect(notif.permissionAsks, 0); // nog niets gevraagd bij het openen
      await t.runAsync(() async {
        await t.tap(find.byType(Switch));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await t.pumpAndSettle();
      expect(notif.permissionAsks, 1);
      final stored = await t.runAsync(() => SettingsRepository(db).getRaw(remindItemsKey));
      expect(stored, '["x"]');
      expect(find.text(S.paywallTitle), findsNothing);
    });

    testWidgets('uitzetten kan altijd, ook zonder Pro, en vraagt niets', (t) async {
      await t.pumpWidget(host(base(pro: false, ids: {'x'}), switchTile()));
      expect(find.text(S.remindProOnly), findsOneWidget); // Pro weg: keuze bewaard, uitleg zichtbaar
      await t.runAsync(() async {
        await t.tap(find.byType(Switch));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      final stored = await t.runAsync(() => SettingsRepository(db).getRaw(remindItemsKey));
      expect(stored, '[]');
      expect(find.text(S.paywallTitle), findsNothing);
      expect(notif.permissionAsks, 0);
    });
  });

  group('dashboardregel "Wil je een herinnering?"', () {
    Item due(String id) => Item(
          id: id,
          isCustom: false,
          hidden: false,
          name: id,
          category: Cat.other,
          why: '',
          unit: 'stuks',
          recommended: 1,
          inHouse: true,
          expiryDate: DateTime(2026, 11, 20),
        );

    Future<void> pumpCard(WidgetTester t, {required bool pro, bool dismissed = false}) async {
      t.view.physicalSize = const Size(800, 3000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final items = [due('a')];
      await t.pumpWidget(host([
        allItemsProvider.overrideWithValue(AsyncValue.data(items)),
        visibleItemsProvider.overrideWithValue(AsyncValue.data(items)),
        settingsProvider.overrideWith((ref) => Stream.value(AppSettings(
              onboarded: true,
              raw: {if (dismissed) proHintDismissedKey: 'true'},
            ))),
        planProvider.overrideWith((ref) => Stream.value(const Plan())),
        vaultHasDocsProvider.overrideWith((ref) => Stream.value(false)),
        vaultDocCountProvider.overrideWith((ref) => Stream.value(null)),
        dashNowProvider.overrideWithValue(DateTime(2026, 11, 11, 12)),
        proUnlockedProvider.overrideWithValue(pro),
        purchaseServiceProvider.overrideWithValue(FakePurchaseService()),
      ], const ExpiringCard()));
      await t.pumpAndSettle();
    }

    testWidgets('zonder Pro: het overzicht werkt en er is één rustige regel met "Niet nu"', (t) async {
      await pumpCard(t, pro: false);
      expect(find.text(S.dashExpiringTitle), findsOneWidget);
      expect(find.text('a'), findsOneWidget); // overzicht is gratis
      expect(find.text(S.dashRemindHint), findsOneWidget);
      expect(find.text(S.paywallNotNow), findsOneWidget);
      expect(find.text(S.paywallTitle), findsNothing); // niet modaal bij opstarten
    });

    testWidgets('tik op de regel opent de paywall', (t) async {
      await pumpCard(t, pro: false);
      await t.tap(find.text(S.dashRemindHint));
      await t.pumpAndSettle();
      expect(find.text(S.paywallTitle), findsOneWidget);
    });

    testWidgets('met Pro is de regel weg', (t) async {
      await pumpCard(t, pro: true);
      expect(find.text(S.dashRemindHint), findsNothing);
    });

    testWidgets('na "Niet nu" is de regel weg', (t) async {
      await pumpCard(t, pro: false, dismissed: true);
      expect(find.text(S.dashRemindHint), findsNothing);
    });
  });

  testWidgets('instellingen: Pro-blok met "Aankoop herstellen", ook met Pro', (t) async {
    for (final pro in [false, true]) {
      await t.pumpWidget(host([
        proUnlockedProvider.overrideWithValue(pro),
        purchaseServiceProvider.overrideWithValue(FakePurchaseService()),
      ], const ProSettingsSection()));
      expect(find.text(S.proName), findsOneWidget);
      expect(find.text(S.paywallRestore), findsOneWidget);
      expect(find.text(pro ? S.proSettingsOn : S.proSettingsOff), findsOneWidget);
      expect(find.text(S.proSettingsMore), pro ? findsNothing : findsOneWidget);
    }
  });
}
