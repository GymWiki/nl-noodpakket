import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/core/providers.dart';
import 'package:mijnnoodpakket/data/db/database.dart';
import 'package:mijnnoodpakket/domain/models.dart';
import 'package:mijnnoodpakket/features/expiry/reminder_items.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_models.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_widgets.dart';
import 'package:mijnnoodpakket/features/pro/pro_models.dart';
import 'package:mijnnoodpakket/features/pro/pro_providers.dart';
import 'package:mijnnoodpakket/features/pro/pro_ui.dart';
import 'package:mijnnoodpakket/features/pro/purchase_service.dart';

import 'fake_purchase.dart';

Item item(String id, {DateTime? expiry, bool hidden = false}) => Item(
      id: id,
      isCustom: false,
      hidden: hidden,
      name: id,
      category: Cat.other,
      why: '',
      unit: 'stuks',
      recommended: 1,
      inHouse: true,
      expiryDate: expiry,
    );

void main() {
  setUpAll(() => initializeDateFormatting('nl_NL'));

  group('catalogus', () {
    test('Pro ontgrendelt precies drie dingen en alles daarbuiten is gratis', () {
      expect(ProFeature.values, [ProFeature.hacks, ProFeature.replacementReminders, ProFeature.vaultUnlimited]);
      for (final f in ProFeature.values) {
        expect(ProCatalog.requiresPro(f), isTrue);
        expect(ProCatalog.isAllowed(f, pro: false), isFalse);
        expect(ProCatalog.isAllowed(f, pro: true), isTrue);
      }
      expect(ProCatalog.productId, 'pro_unlock');
    });

    test('kluislimiet: 3 gratis, de 4e geblokkeerd, met Pro onbeperkt', () {
      expect(vaultFreeLimit, 3);
      for (final n in [0, 1, 2]) {
        expect(canAddVaultDocument(count: n, pro: false), isTrue, reason: '$n');
      }
      expect(canAddVaultDocument(count: 3, pro: false), isFalse);
      expect(canAddVaultDocument(count: 12, pro: false), isFalse); // bestaande data blijft, nieuw niet
      expect(canAddVaultDocument(count: 3, pro: true), isTrue);
      expect(canAddVaultDocument(count: 99, pro: true), isTrue);
    });
  });

  group('entitlement', () {
    final day1 = DateTime(2026, 11, 11, 9), day2 = DateTime(2026, 11, 12, 9);

    test('standaard gratis; grant en herstel zetten Pro aan', () {
      expect(const Entitlement().unlocked, isFalse);
      expect(const Entitlement().grant().unlocked, isTrue);
      expect(const Entitlement().applyRestore(reachable: true, owns: true, now: day1).unlocked, isTrue);
    });

    test('cache: bewaren en terugzetten', () {
      final e = Entitlement.fromRaw(const Entitlement(unlocked: true, emptyDays: ['2026-11-11']).toRaw());
      expect(e.unlocked, isTrue);
      expect(e.emptyDays, ['2026-11-11']);
      expect(Entitlement.fromRaw(const {}).unlocked, isFalse);
      expect(Entitlement.fromRaw({Entitlement.keyEmpty: '{kapot'}).emptyDays, isEmpty);
    });

    test('offline of onbereikbare store haalt niets weg', () {
      const e = Entitlement(unlocked: true);
      expect(e.applyRestore(reachable: false, owns: false, now: day1).unlocked, isTrue);
    });

    test('terugbetaling: pas na twee verschillende dagen zonder aankoop', () {
      var e = const Entitlement(unlocked: true);
      e = e.applyRestore(reachable: true, owns: false, now: day1);
      expect(e.unlocked, isTrue);
      e = e.applyRestore(reachable: true, owns: false, now: day1.add(const Duration(hours: 3)));
      expect(e.unlocked, isTrue); // zelfde dag telt niet dubbel
      e = e.applyRestore(reachable: true, owns: false, now: day2);
      expect(e.unlocked, isFalse);
    });

    test('een geslaagde controle wist de eerdere lege dagen', () {
      var e = const Entitlement(unlocked: true);
      e = e.applyRestore(reachable: true, owns: false, now: day1);
      e = e.applyRestore(reachable: true, owns: true, now: day2);
      expect(e.unlocked, isTrue);
      expect(e.emptyDays, isEmpty);
    });

    test('gratis gebruiker blijft gratis zonder aankoop', () {
      final e = const Entitlement().applyRestore(reachable: true, owns: false, now: day1);
      expect(e.unlocked, isFalse);
    });
  });

  group('noodhacks: wat is gratis', () {
    late HackData data;
    setUpAll(() {
      data = HackData.parse(File('assets/wiki/noodhacks.json').readAsStringSync());
    });

    test('precies twee proefhacks: Water koken en voedsel bewaren zonder koeling', () {
      final preview = data.hacks.where((h) => h.freePreview).map((h) => h.id).toSet();
      expect(preview, {'water-koken', 'koelkast-stroomuitval'});
    });

    test('alle mythes en proefhacks zijn gratis; de rest is Pro', () {
      for (final h in data.hacks) {
        final free = h.categorie == 'mythes' || h.freePreview;
        expect(h.isFree, free, reason: h.id);
        expect(hackLocked(h, pro: false), !free, reason: h.id);
        expect(hackLocked(h, pro: true), isFalse, reason: h.id);
      }
      expect(data.hacks.where((h) => h.label == HackLabel.nooit).every((h) => h.isFree), isTrue);
      expect(data.hacks.where((h) => !h.isFree).isNotEmpty, isTrue);
    });
  });

  group('vervangherinneringen', () {
    final dated = item('a', expiry: DateTime(2027, 1, 1));
    final list = [dated, item('b', expiry: DateTime(2027, 2, 1)), item('c'), item('d', expiry: DateTime(2027, 3, 1), hidden: true)];

    test('zonder Pro wordt niets ingepland, ook al staat de keuze aan', () {
      expect(itemsToRemind(list, {'a', 'b'}, pro: false), isEmpty);
    });

    test('met Pro alleen items met schakelaar, datum en niet verborgen', () {
      expect(itemsToRemind(list, {'a', 'c', 'd'}, pro: true).map((i) => i.id), ['a']);
    });

    test('keuze blijft bewaard bij verlies van Pro en werkt weer na herstel', () {
      final ids = {'a', 'b'};
      expect(itemsToRemind(list, ids, pro: true).length, 2);
      expect(itemsToRemind(list, ids, pro: false), isEmpty);
      expect(itemsToRemind(list, ids, pro: true).length, 2);
    });

    test('datumwijziging verandert de lijst en dus het plan', () {
      final moved = item('a', expiry: DateTime(2027, 6, 1));
      expect(itemsToRemind([moved], {'a'}, pro: true).single.expiryDate, DateTime(2027, 6, 1));
      expect(itemsToRemind([item('a')], {'a'}, pro: true), isEmpty); // datum gewist: geen melding meer
    });

    test('opgeslagen waarde wordt veilig gelezen', () {
      expect(parseRemindItems('["x","y"]'), {'x', 'y'});
      expect(parseRemindItems('kapot'), isEmpty);
      expect(parseRemindItems(null), isEmpty);
    });
  });

  group('ProController met nepstore', () {
    late AppDatabase db;
    late FakePurchaseService fake;
    late ProviderContainer c;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      fake = FakePurchaseService();
      c = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        purchaseServiceProvider.overrideWithValue(fake),
      ]);
      c.listen(settingsProvider, (_, _) {});
      await c.read(settingsProvider.future);
      c.read(proControllerProvider); // luisteraar starten
    });

    tearDown(() async {
      c.dispose();
      await db.close();
    });

    Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

    test('start gratis; prijs komt uit de store', () async {
      expect(c.read(proUnlockedProvider), isFalse);
      await c.read(proControllerProvider.notifier).loadPrice();
      expect(c.read(proControllerProvider).price, '€ 3,99');
    });

    test('aankoop ontgrendelt Pro en blijft in de lokale cache', () async {
      await c.read(proControllerProvider.notifier).buy();
      expect(fake.buyCalls, 1);
      fake.emit(PurchaseOutcome.purchased);
      await settle();
      expect(c.read(proUnlockedProvider), isTrue);
      expect(c.read(proControllerProvider).message, ProMessage.thanks);
      // nieuwe sessie op dezelfde opslag: nog steeds Pro (cache)
      final c2 = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        purchaseServiceProvider.overrideWithValue(FakePurchaseService()),
      ]);
      addTearDown(c2.dispose);
      c2.listen(settingsProvider, (_, _) {});
      await c2.read(settingsProvider.future);
      expect(c2.read(proUnlockedProvider), isTrue);
    });

    test('annuleren ontgrendelt niets', () async {
      fake.emit(PurchaseOutcome.cancelled);
      await settle();
      expect(c.read(proUnlockedProvider), isFalse);
      expect(c.read(proControllerProvider).message, ProMessage.cancelled);
    });

    test('herstellen met aankoop zet Pro aan; zonder aankoop meldt dat netjes', () async {
      final ctl = c.read(proControllerProvider.notifier);
      await ctl.restore();
      expect(c.read(proUnlockedProvider), isFalse);
      expect(c.read(proControllerProvider).message, ProMessage.nothingToRestore);
      fake.owns = true;
      await ctl.restore();
      await settle();
      expect(c.read(proUnlockedProvider), isTrue);
      expect(c.read(proControllerProvider).message, ProMessage.restored);
    });

    test('store niet bereikbaar: melding, en Pro blijft zoals het was', () async {
      final ctl = c.read(proControllerProvider.notifier);
      fake.owns = true;
      await ctl.restore();
      await settle();
      fake.reachable = false;
      fake.owns = false;
      await ctl.restore();
      await settle();
      expect(c.read(proUnlockedProvider), isTrue);
      expect(c.read(proControllerProvider).message, ProMessage.unavailable);
    });

    test('stille controle toont geen melding en één lege uitkomst haalt Pro niet weg', () async {
      final ctl = c.read(proControllerProvider.notifier);
      fake.owns = true;
      await ctl.restore();
      await settle();
      ctl.clearMessage();
      fake.owns = false;
      await ctl.restore(silent: true);
      await settle();
      expect(c.read(proUnlockedProvider), isTrue);
      expect(c.read(proControllerProvider).message, ProMessage.none);
    });

    test('koop niet beschikbaar geeft een rustige melding', () async {
      fake.canBuy = false;
      await c.read(proControllerProvider.notifier).buy();
      expect(c.read(proControllerProvider).message, ProMessage.unavailable);
      expect(c.read(proControllerProvider).busy, isFalse);
    });
  });

  group('paywall', () {
    Future<FakePurchaseService> open(WidgetTester t, {FakePurchaseService? fake, bool pro = false}) async {
      t.view.physicalSize = const Size(800, 3000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final svc = fake ?? FakePurchaseService();
      final List<Override> o = [
        purchaseServiceProvider.overrideWithValue(svc),
        proUnlockedProvider.overrideWithValue(pro),
      ];
      await t.pumpWidget(ProviderScope(
        overrides: o,
        child: MaterialApp(
          locale: const Locale('nl', 'NL'),
          supportedLocales: const [Locale('nl', 'NL')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
            builder: (c) => Scaffold(body: Center(child: TextButton(onPressed: () => showPaywall(c), child: const Text('open')))),
          ),
        ),
      ));
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      return svc;
    }

    testWidgets('tekst: wat je erbij krijgt en wat gratis blijft', (t) async {
      await open(t);
      // "Dit blijft gratis" is inklapbaar (rustiger); klap uit om de lijst te lezen.
      await t.tap(find.text(S.paywallFreeTitle));
      await t.pumpAndSettle();
      for (final s in [
        S.paywallGetTitle,
        S.paywallGet1,
        S.paywallGet2,
        S.paywallGet3,
        S.paywallFreeTitle,
        S.paywallFree1,
        S.paywallFree2,
        S.paywallFree3,
        S.paywallFree4,
        S.paywallFree5,
        S.paywallNoSub,
        S.paywallHelp,
        S.paywallRestore,
        S.paywallNotNow,
      ]) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
    });

    testWidgets('prijs komt uit de store, nooit hardcoded', (t) async {
      await open(t, fake: FakePurchaseService(price: '\$4.49'));
      expect(find.text(S.paywallUnlock('\$4.49')), findsOneWidget);
      expect(find.textContaining('3,99'), findsNothing);
    });

    testWidgets('zonder prijs uit de store: knop zonder bedrag en uitleg', (t) async {
      await open(t, fake: FakePurchaseService(price: null));
      expect(find.text(S.paywallUnlockNoPrice), findsOneWidget);
      expect(find.text(S.paywallPriceLoading), findsOneWidget);
    });

    testWidgets('geen druk: geen aftellers, schaarste of vooraf gekozen opties', (t) async {
      await open(t);
      for (final w in ['nog maar', 'laatste kans', 'alleen vandaag', 'beperkte tijd', 'korting', 'aanbieding']) {
        expect(find.textContaining(w, findRichText: true), findsNothing, reason: w);
      }
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(Radio), findsNothing);
    });

    testWidgets('kopen roept de store aan, herstellen is beschikbaar; "Niet nu" sluit zonder gevolgen', (t) async {
      final svc = await open(t);
      await t.tap(find.text(S.paywallUnlock('€ 3,99')));
      await t.pump();
      expect(svc.buyCalls, 1);
      svc.emit(PurchaseOutcome.cancelled); // de store meldt annulering; knoppen zijn weer actief
      await t.pump();
      // Herstellen is altijd beschikbaar (de werking staat in de controller-tests).
      expect(t.widget<TextButton>(find.widgetWithText(TextButton, S.paywallRestore)).onPressed, isNotNull);
      await t.tap(find.text(S.paywallNotNow));
      await t.pumpAndSettle();
      expect(find.text(S.paywallTitle), findsNothing);
    });
  });
}
