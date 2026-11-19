import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/core/format.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/core/providers.dart';
import 'package:mijnnoodpakket/core/theme.dart';
import 'package:mijnnoodpakket/data/repositories/settings_repository.dart';
import 'package:mijnnoodpakket/domain/models.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_models.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_providers.dart';
import 'package:mijnnoodpakket/features/pro/paywall_config.dart';
import 'package:mijnnoodpakket/features/pro/pro_providers.dart';
import 'package:mijnnoodpakket/features/pro/pro_ui.dart';

import 'fake_purchase.dart';

final hacksData = HackData.parse(File('assets/wiki/noodhacks.json').readAsStringSync());

Item item(String id, String name, {DateTime? expiry, DateTime? lastChecked, int? interval, bool hidden = false}) => Item(
      id: id,
      isCustom: false,
      hidden: hidden,
      name: name,
      category: Cat.other,
      why: '',
      unit: 'stuks',
      recommended: 1,
      inHouse: true,
      expiryDate: expiry,
      lastChecked: lastChecked,
      intervalMonths: interval,
    );

/// Opent de paywall zoals in de app: via een bewuste tik.
Future<FakePurchaseService> pumpPaywall(
  WidgetTester t,
  PaywallRequest request, {
  List<Item> items = const [],
  int lead = 30,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool reduceMotion = false,
  bool pro = false,
  FakePurchaseService? fake,
  String store = 'Google',
  List<Override> extra = const [],
  Override? proOverride,
  List<PaywallResult>? results,
}) async {
  t.view.physicalSize = const Size(1080, 2200);
  t.view.devicePixelRatio = 2.75; // ca. 392 x 800 dp
  addTearDown(t.view.reset);
  final svc = fake ?? FakePurchaseService();
  await t.pumpWidget(ProviderScope(
    overrides: [
      purchaseServiceProvider.overrideWithValue(svc),
      proOverride ?? proUnlockedProvider.overrideWithValue(pro),
      hacksProvider.overrideWith((ref) => hacksData),
      allItemsProvider.overrideWithValue(AsyncValue.data(items)),
      settingsProvider.overrideWith((ref) => Stream.value(AppSettings(leadDays: lead))),
      storeNameProvider.overrideWithValue(store),
      ...extra,
    ],
    child: MaterialApp(
      theme: buildTheme(brightness),
      locale: const Locale('nl', 'NL'),
      supportedLocales: const [Locale('nl', 'NL')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(textScale), disableAnimations: reduceMotion),
        child: child!,
      ),
      home: Builder(
        builder: (c) => Scaffold(
          body: Center(child: TextButton(onPressed: () => showPaywall(c, request: request).then((r) => results?.add(r)), child: const Text('open'))),
        ),
      ),
    ),
  ));
  await t.tap(find.text('open'));
  await t.pumpAndSettle();
  return svc;
}

/// Een Pro-hack met minstens twee andere hacks in dezelfde categorie.
Hack proHackWithSiblings() => hacksData.hacks.firstWhere(
    (h) => !h.isFree && hacksData.hacks.where((o) => o.categorie == h.categorie && o.id != h.id).length >= 2);

void main() {
  setUpAll(() => initializeDateFormatting('nl_NL'));

  group('variant noodhacks', () {
    testWidgets('kop, subregel en echte, dynamische waarden uit noodhacks.json', (t) async {
      final h = proHackWithSiblings();
      await pumpPaywall(t, PaywallRequest.hack(h.id));
      expect(find.text('Alle noodhacks, ook als je pakket op is'), findsOneWidget);
      expect(find.text('Praktische oplossingen met spullen uit huis, tuin en keuken, stap voor stap.'), findsOneWidget);
      // Aantal komt uit de data, niet uit de code.
      expect(find.text(S.paywallHackCount(hacksData.hacks.length)), findsOneWidget);
      expect(find.text(S.paywallHackSearch), findsOneWidget);
      // Categorie van de aangetikte hack met 2 tot 3 echte titels uit dezelfde categorie.
      final cat = hacksData.categories.firstWhere((c) => c.id == h.categorie);
      expect(find.text(S.paywallHackCategory(cat.titel)), findsOneWidget);
      final same = hacksData.hacks.where((o) => o.categorie == h.categorie && o.id != h.id).map((o) => o.titel).toSet();
      final shown = [for (final o in same) if (find.text('• $o').evaluate().isNotEmpty) o];
      expect(shown.length, inInclusiveRange(2, 3));
      expect(find.text('• ${h.titel}'), findsNothing); // de aangetikte hack zelf telt niet mee
      expect(find.text(S.paywallHackSafetyFree), findsOneWidget);
    });

    testWidgets('het aantal volgt de data (niet hardcoded)', (t) async {
      expect(hacksData.hacks.length, isNot(0));
      final src = File('lib/features/pro/paywall_config.dart').readAsStringSync() +
          File('lib/features/pro/paywall_sheet.dart').readAsStringSync();
      expect(src.contains(RegExp(r'\b25\b')), isFalse);
    });
  });

  group('variant vervangherinneringen', () {
    final exp = DateTime(2026, 12, 1);

    testWidgets('toont het eigen item met echte datum en het aantal dagen vooraf', (t) async {
      await pumpPaywall(t, const PaywallRequest.reminders(),
          items: [item('a', 'Waterflessen', expiry: exp)], lead: 14);
      expect(find.text('Laat de app je herinneren'), findsOneWidget);
      expect(find.text(S.paywallRemindExpiry('Waterflessen', fmtDate(exp), '14 dagen van tevoren')), findsOneWidget);
    });

    testWidgets('het item waarvoor je de herinnering zet, gaat voor het eerstvolgende item', (t) async {
      await pumpPaywall(t, const PaywallRequest.reminders(itemId: 'b'), items: [
        item('a', 'Waterflessen', expiry: DateTime(2026, 11, 25)),
        item('b', 'Batterijen', expiry: exp),
      ]);
      expect(find.textContaining('Batterijen'), findsOneWidget);
      expect(find.textContaining('Waterflessen'), findsNothing);
    });

    testWidgets('zonder itemId: het eerstvolgende echte item met een datum', (t) async {
      final soon = DateTime.now().add(const Duration(days: 20));
      await pumpPaywall(t, const PaywallRequest.reminders(), items: [
        item('a', 'Zaklamp', expiry: DateTime.now().add(const Duration(days: 400))),
        item('b', 'Waterfilter', expiry: soon),
        item('c', 'Verborgen', expiry: DateTime.now().add(const Duration(days: 5)), hidden: true),
        item('d', 'Zonder datum'),
      ]);
      expect(find.textContaining('Waterfilter'), findsOneWidget);
      expect(find.textContaining('Zaklamp'), findsNothing);
      expect(find.textContaining('Verborgen'), findsNothing);
    });

    testWidgets('vervangdatum zonder houdbaarheid krijgt een eerlijke zin', (t) async {
      await pumpPaywall(t, const PaywallRequest.reminders(), items: [
        item('a', 'Rookmelder', lastChecked: DateTime.now(), interval: 12),
      ]);
      expect(find.textContaining('te vervangen op'), findsOneWidget);
      expect(find.textContaining('houdbaar tot'), findsNothing);
    });

    for (final (label, items) in [
      ('geen items', <Item>[]),
      ('alleen items zonder datum', [item('a', 'Zonder datum')]),
      ('alleen verlopen items', [item('a', 'Oud', expiry: DateTime(2020, 1, 1))]),
    ]) {
      testWidgets('ontbrekend item ($label): neutrale zin zonder voorbeeld', (t) async {
        await pumpPaywall(t, const PaywallRequest.reminders(), items: items);
        expect(find.text(S.paywallRemindNeutral), findsOneWidget);
        expect(find.textContaining('Bijvoorbeeld'), findsNothing);
        expect(find.textContaining('dagen van tevoren'), findsNothing);
      });
    }

    testWidgets('praktisch en zonder angst', (t) async {
      await pumpPaywall(t, const PaywallRequest.reminders());
      expect(find.text(S.paywallRemindOnDevice), findsOneWidget);
      expect(find.textContaining('ramp', findRichText: true), findsNothing);
    });
  });

  group('variant kluis', () {
    for (final n in [3, 5]) {
      testWidgets('toont "$n van 3" en dat bestaande documenten blijven', (t) async {
        await pumpPaywall(t, PaywallRequest.vault(vaultCount: n));
        expect(find.text('Meer ruimte in je kluis'), findsOneWidget);
        expect(find.text('Je hebt $n van 3 gratis documenten gebruikt'), findsOneWidget);
        expect(find.text('Je bestaande documenten blijven altijd van jou en bruikbaar.'), findsOneWidget);
        expect(find.text(S.paywallVaultUnlimited), findsOneWidget);
      });
    }
  });

  group('variant algemeen (Instellingen)', () {
    testWidgets('algemene inhoud: de drie Pro-onderdelen', (t) async {
      await pumpPaywall(t, const PaywallRequest.general());
      expect(find.text(S.paywallTitle), findsOneWidget);
      for (final s in [S.paywallGeneralHacks, S.paywallGeneralReminders, S.paywallGeneralVault]) {
        expect(find.text(s), findsOneWidget);
      }
    });
  });

  group('gedeelde sheet', () {
    testWidgets('sluitknop rechtsboven, "Niet nu" en koopknop: aanwezig, zichtbaar, minstens 48 dp', (t) async {
      await pumpPaywall(t, const PaywallRequest.general());
      for (final k in ['paywall-close', 'paywall-not-now', 'paywall-buy', 'paywall-restore']) {
        final f = find.byKey(Key(k));
        expect(f, findsOneWidget, reason: k);
        final size = t.getSize(f);
        expect(size.width, greaterThanOrEqualTo(48), reason: k);
        expect(size.height, greaterThanOrEqualTo(48), reason: k);
        expect(t.getRect(f).bottom, lessThanOrEqualTo(800), reason: '$k valt binnen het scherm');
      }
      // "Niet nu" is even groot en even zichtbaar als de koopknop.
      expect(t.getSize(find.byKey(const Key('paywall-not-now'))), t.getSize(find.byKey(const Key('paywall-buy'))));
      // De sluitknop staat rechtsboven.
      final close = t.getRect(find.byKey(const Key('paywall-close')));
      expect(close.right, greaterThan(392 - 32));
      expect(close.top, lessThan(200));
    });

    testWidgets('het kruisje blijft zichtbaar als je naar beneden scrolt, ook bij 200% tekst', (t) async {
      await pumpPaywall(t, const PaywallRequest.general(), textScale: 2);
      await t.scrollUntilVisible(find.text(S.paywallSupport), 300, scrollable: find.byType(Scrollable).last);
      final r = t.getRect(find.byKey(const Key('paywall-close')));
      expect(r.top, greaterThanOrEqualTo(0));
      expect(r.top, lessThan(200));
      expect(r.height, greaterThanOrEqualTo(48));
    });

    testWidgets('het kruisje sluit het blad', (t) async {
      await pumpPaywall(t, const PaywallRequest.general());
      await t.tap(find.byKey(const Key('paywall-close')));
      await t.pumpAndSettle();
      expect(find.text(S.paywallTitle), findsNothing);
    });

    testWidgets('"Niet nu" sluit het blad', (t) async {
      await pumpPaywall(t, const PaywallRequest.general());
      await t.tap(find.byKey(const Key('paywall-not-now')));
      await t.pumpAndSettle();
      expect(find.text(S.paywallTitle), findsNothing);
    });

    testWidgets('één aanbod: primaire knop met prijs uit de winkel, geen plankeuze', (t) async {
      await pumpPaywall(t, const PaywallRequest.general(), fake: FakePurchaseService(price: '€ 4,29'));
      expect(find.text('Ontgrendel Pro voor € 4,29'), findsOneWidget);
      expect(find.text('Eenmalig, geen abonnement'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('winkelzin noemt Apple of Google, en Family Sharing alleen met de configvlag op Apple', (t) async {
      await pumpPaywall(t, const PaywallRequest.general(), store: 'Apple');
      expect(find.text(S.paywallStoreNote('Apple')), findsOneWidget);
      expect(find.text(S.paywallFamilySharing), findsNothing);
    });

    testWidgets('Family Sharing staat er alleen als de vlag aan staat (en dan alleen bij Apple)', (t) async {
      final on = paywallConfigProvider.overrideWithValue(const PaywallConfig(rows: {}, familySharing: true));
      await pumpPaywall(t, const PaywallRequest.general(), store: 'Apple', extra: [on]);
      expect(find.text(S.paywallFamilySharing), findsOneWidget);
    });

    testWidgets('Family Sharing met vlag aan maar op Google: niet genoemd', (t) async {
      final on = paywallConfigProvider.overrideWithValue(const PaywallConfig(rows: {}, familySharing: true));
      await pumpPaywall(t, const PaywallRequest.general(), store: 'Google', extra: [on]);
      expect(find.text(S.paywallFamilySharing), findsNothing);
    });

    testWidgets('het gratis-blok noemt de echte lijst en het aantal proefhacks uit de data', (t) async {
      await pumpPaywall(t, const PaywallRequest.general());
      final trial = hacksData.hacks.where((h) => h.freePreview).length;
      expect(trial, 2);
      for (final s in [
        S.paywallFreeChecklist,
        S.paywallFreeGuides,
        S.paywallFreeFirstHour,
        S.paywallFreePlan,
        S.paywallFreeVault,
        S.paywallFreeMyths('twee'),
      ]) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
    });

    testWidgets('PaywallConfig bepaalt de volgorde van de rijen', (t) async {
      final flipped = paywallConfigProvider.overrideWithValue(const PaywallConfig(rows: {
        PaywallContext.general: [PaywallRowKind.generalVault, PaywallRowKind.generalHacks],
      }, showFreeBlock: false));
      await pumpPaywall(t, const PaywallRequest.general(), extra: [flipped]);
      expect(t.getTopLeft(find.text(S.paywallGeneralVault)).dy, lessThan(t.getTopLeft(find.text(S.paywallGeneralHacks)).dy));
      expect(find.text(S.paywallGeneralReminders), findsNothing);
      expect(find.text(S.paywallFreeTitle), findsNothing);
    });
  });

  for (final b in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      for (final (name, req) in [
        ('algemeen', const PaywallRequest.general()),
        ('noodhacks', PaywallRequest.hack(proHackWithSiblings().id)),
        ('herinneringen', const PaywallRequest.reminders()),
        ('kluis', const PaywallRequest.vault(vaultCount: 3)),
      ]) {
        testWidgets('$name, ${b.name}, tekstschaal ${(scale * 100).round()}%: geen overflow, alles bereikbaar', (t) async {
          await pumpPaywall(t, req, brightness: b, textScale: scale);
          expect(t.takeException(), isNull);
          // Scroll naar het einde: het gratis-blok en de ondersteunende zin zijn bereikbaar.
          await t.scrollUntilVisible(find.text(S.paywallSupport), 300, scrollable: find.byType(Scrollable).last);
          expect(find.text(S.paywallSupport), findsOneWidget);
          // De knoppen blijven bereikbaar en minstens 48 dp.
          for (final k in ['paywall-close', 'paywall-not-now', 'paywall-buy']) {
            await t.ensureVisible(find.byKey(Key(k)));
            expect(t.getSize(find.byKey(Key(k))).height, greaterThanOrEqualTo(48), reason: k);
          }
        });
      }
    }
  }

  testWidgets('reduce-motion: het blad verschijnt en sluit zonder animatie', (t) async {
    await pumpPaywall(t, const PaywallRequest.general(), reduceMotion: true);
    expect(find.text(S.paywallTitle), findsOneWidget);
    await t.tap(find.byKey(const Key('paywall-close')));
    await t.pump(); // één frame: geen uitschuifbeweging
    await t.pump();
    expect(find.text(S.paywallTitle), findsNothing);
  });
}
