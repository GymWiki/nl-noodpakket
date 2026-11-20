import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/core/providers.dart';
import 'package:mijnnoodpakket/data/repositories/settings_repository.dart';
import 'package:mijnnoodpakket/features/pro/pro_models.dart';
import 'package:mijnnoodpakket/features/pro/pro_providers.dart';
import 'package:mijnnoodpakket/features/pro/pro_ui.dart';
import 'package:mijnnoodpakket/features/pro/purchase_service.dart';

import 'fake_purchase.dart';
import 'paywall_variants_test.dart' show hacksData, pumpPaywall, proHackWithSiblings;

/// Bron van waarheid voor "Pro aan" in deze tests; de nepstore zet hem om via de echte controller.
class _Flag extends Notifier<bool> {
  @override
  bool build() => false;
  void on() => state = true;
}

final _flag = NotifierProvider<_Flag, bool>(_Flag.new);

class _Repo implements SettingsRepository {
  _Repo(this.onSet);
  final void Function(String, String) onSet;
  @override
  Future<void> setRaw(String key, String value) async => onSet(key, value);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Winkel die nooit antwoordt op de prijs.
class _SilentStore extends FakePurchaseService {
  @override
  Future<String?> loadPrice() => Completer<String?>().future;
}

void main() {
  setUpAll(() => initializeDateFormatting('nl_NL'));

  late ProviderContainer container;

  /// Opent de paywall met de echte ProController; een aankoop zet Pro aan via de opslag.
  Future<FakePurchaseService> open(
    WidgetTester t,
    PaywallRequest request, {
    FakePurchaseService? fake,
    List<PaywallResult>? results,
  }) async {
    final svc = fake ?? FakePurchaseService();
    await pumpPaywall(
      t,
      request,
      fake: svc,
      results: results,
      proOverride: proUnlockedProvider.overrideWith((ref) => ref.watch(_flag)),
      extra: [
        settingsRepositoryProvider.overrideWithValue(_Repo((k, v) {
          if (k == Entitlement.keyUnlocked && v == 'true') container.read(_flag.notifier).on();
        })),
      ],
    );
    container = ProviderScope.containerOf(t.element(find.byType(Scaffold).first));
    return svc;
  }

  final all = [
    S.proMsgThanks,
    S.proMsgRestored,
    S.proMsgNothing,
    S.proMsgPending,
    S.proMsgUnavailable,
    S.proMsgError,
  ];

  void expectNoMessage(WidgetTester t) {
    for (final m in all) {
      expect(find.text(m), findsNothing, reason: m);
    }
  }

  group('na de aankoop', () {
    final actions = <(String, PaywallRequest, String)>[
      ('noodhacks', PaywallRequest.hack(proHackWithSiblings().id), S.proDoneActionHack),
      ('herinneringen met item', const PaywallRequest.reminders(itemId: 'x'), S.proDoneActionReminders),
      ('herinneringen zonder item', const PaywallRequest.reminders(), S.proDoneActionBack),
      ('kluis', const PaywallRequest.vault(vaultCount: 3), S.proDoneActionVault),
      ('algemeen', const PaywallRequest.general(), S.proDoneActionHacks),
    ];

    for (final (name, req, label) in actions) {
      testWidgets('$name: rustige bevestiging met één directe actie "$label"', (t) async {
        final results = <PaywallResult>[];
        final svc = await open(t, req, results: results);
        await t.tap(find.byKey(const Key('paywall-buy')));
        await t.pump();
        svc.emit(PurchaseOutcome.purchased);
        await t.pumpAndSettle();
        expect(find.text(S.proDoneTitle), findsOneWidget);
        expect(find.text(S.proDoneSub), findsOneWidget);
        expect(find.text(label), findsOneWidget);
        // De aanbieding is weg; er is niets meer te kopen.
        expect(find.byKey(const Key('paywall-buy')), findsNothing);
        await t.tap(find.byKey(const Key('paywall-done-action')));
        await t.pumpAndSettle();
        expect(results, [PaywallResult.action]);
      });
    }

    testWidgets('sluiten kan ook zonder de actie, en geeft dan "dismissed"', (t) async {
      final results = <PaywallResult>[];
      final svc = await open(t, const PaywallRequest.general(), results: results);
      await t.tap(find.byKey(const Key('paywall-buy')));
      await t.pump();
      svc.emit(PurchaseOutcome.purchased);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('paywall-close')));
      await t.pumpAndSettle();
      expect(results, [PaywallResult.dismissed]);
    });

    testWidgets('herstellen met een gevonden aankoop toont "hersteld"', (t) async {
      await open(t, const PaywallRequest.general(), fake: FakePurchaseService(owns: true));
      await t.tap(find.byKey(const Key('paywall-restore')));
      await t.pumpAndSettle();
      expect(find.text(S.proDoneRestoredTitle), findsOneWidget);
    });

    testWidgets('nooit een vraag om een review, in of direct na de paywall', (t) async {
      final svc = await open(t, const PaywallRequest.general());
      final ask = RegExp('review|beoordeel|waardeer|sterren|app store|play store', caseSensitive: false);
      expect(find.textContaining(ask), findsNothing);
      await t.tap(find.byKey(const Key('paywall-buy')));
      await t.pump();
      svc.emit(PurchaseOutcome.purchased);
      await t.pumpAndSettle();
      expect(find.textContaining(ask), findsNothing);
    });
  });

  group('foutafhandeling', () {
    testWidgets('winkel antwoordt niet: eerst "Prijs ophalen...", daarna een rustige melding; sluiten werkt altijd', (t) async {
      await open(t, const PaywallRequest.general(), fake: _SilentStore());
      expect(find.text(S.paywallPriceLoading), findsOneWidget);
      expect(t.widget<FilledButton>(find.byKey(const Key('paywall-buy'))).onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsNothing); // geen spinner
      await t.pump(const Duration(seconds: 9)); // time-out: geen eeuwig laden
      expect(find.text(S.proMsgUnavailable), findsOneWidget);
      expect(find.text(S.paywallUnlockNoPrice), findsOneWidget);
      expect(find.byKey(const Key('paywall-retry')), findsOneWidget);
      await t.tap(find.byKey(const Key('paywall-close')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('paywall-not-now')), findsNothing);
    });

    testWidgets('producten niet geladen: melding, "Probeer opnieuw" haalt de prijs alsnog op', (t) async {
      final svc = await open(t, const PaywallRequest.general(), fake: FakePurchaseService(price: null));
      expect(find.text(S.proMsgUnavailable), findsOneWidget);
      expect(t.widget<FilledButton>(find.byKey(const Key('paywall-buy'))).onPressed, isNull);
      svc.price = '€ 3,99';
      await t.tap(find.byKey(const Key('paywall-retry')));
      await t.pumpAndSettle();
      expect(find.text(S.paywallUnlock('€ 3,99')), findsOneWidget);
      expect(find.text(S.proMsgUnavailable), findsNothing);
    });

    testWidgets('geannuleerd: stil terug, zonder melding, en kopen kan weer', (t) async {
      final svc = await open(t, const PaywallRequest.general());
      await t.tap(find.byKey(const Key('paywall-buy')));
      await t.pump();
      svc.emit(PurchaseOutcome.cancelled);
      await t.pumpAndSettle();
      expectNoMessage(t);
      expect(find.byKey(const Key('paywall-not-now')), findsOneWidget); // blad blijft gewoon staan
      expect(t.widget<FilledButton>(find.byKey(const Key('paywall-buy'))).onPressed, isNotNull);
    });

    testWidgets('in behandeling: duidelijke uitleg en niets geblokkeerd', (t) async {
      final svc = await open(t, const PaywallRequest.general());
      await t.tap(find.byKey(const Key('paywall-buy')));
      await t.pump();
      svc.emit(PurchaseOutcome.pending);
      await t.pumpAndSettle();
      expect(find.text(S.proMsgPending), findsOneWidget);
      expect(find.textContaining('blijven gebruiken'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Sluiten, "Niet nu" en herstellen blijven werken.
      expect(t.widget<TextButton>(find.byKey(const Key('paywall-not-now'))).onPressed, isNotNull);
      expect(t.widget<TextButton>(find.byKey(const Key('paywall-restore'))).onPressed, isNotNull);
      await t.ensureVisible(find.byKey(const Key('paywall-not-now')));
      await t.tap(find.byKey(const Key('paywall-not-now')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('paywall-buy')), findsNothing);
    });

    testWidgets('mislukt: één heldere regel en "Probeer opnieuw" start de aankoop opnieuw', (t) async {
      final svc = await open(t, const PaywallRequest.general());
      await t.tap(find.byKey(const Key('paywall-buy')));
      await t.pump();
      svc.emit(PurchaseOutcome.error);
      await t.pumpAndSettle();
      expect(find.text(S.proMsgError), findsOneWidget);
      await t.tap(find.byKey(const Key('paywall-retry')));
      await t.pump();
      expect(svc.buyCalls, 2);
      svc.emit(PurchaseOutcome.cancelled);
      await t.pumpAndSettle();
    });

    testWidgets('winkel kan de aankoop niet starten: rustige melding, sheet blijft bruikbaar', (t) async {
      final svc = await open(t, const PaywallRequest.general(), fake: FakePurchaseService(canBuy: false));
      await t.tap(find.byKey(const Key('paywall-buy')));
      await t.pumpAndSettle();
      expect(svc.buyCalls, 1);
      expect(find.text(S.proMsgUnavailable), findsOneWidget);
      expect(find.byKey(const Key('paywall-retry')), findsOneWidget);
    });

    testWidgets('herstellen zonder gevonden aankoop: eerlijke melding', (t) async {
      await open(t, const PaywallRequest.general(), fake: FakePurchaseService(owns: false));
      await t.tap(find.byKey(const Key('paywall-restore')));
      await t.pumpAndSettle();
      expect(find.text(S.proMsgNothing), findsOneWidget);
      expect(find.byKey(const Key('paywall-buy')), findsOneWidget);
    });

    testWidgets('herstellen terwijl de winkel niet bereikbaar is: melding, geen vastzittende staat', (t) async {
      await open(t, const PaywallRequest.general(), fake: FakePurchaseService(reachable: false));
      await t.tap(find.byKey(const Key('paywall-restore')));
      await t.pumpAndSettle();
      expect(find.text(S.proMsgUnavailable), findsOneWidget);
      expect(t.widget<TextButton>(find.byKey(const Key('paywall-restore'))).onPressed, isNotNull);
    });

    testWidgets('winkel meldt niets na de start: de knoppen komen na een tijd vanzelf vrij', (t) async {
      await open(t, const PaywallRequest.general());
      await t.tap(find.byKey(const Key('paywall-buy')));
      await t.pump();
      expect(find.text(S.paywallWaiting), findsOneWidget);
      expect(t.widget<FilledButton>(find.byKey(const Key('paywall-buy'))).onPressed, isNull);
      await t.pump(ProController.busyTimeout + const Duration(seconds: 1));
      expect(find.text(S.paywallWaiting), findsNothing);
      expect(t.widget<FilledButton>(find.byKey(const Key('paywall-buy'))).onPressed, isNotNull);
    });

    testWidgets('de rest van de app blijft bruikbaar: de sheet is sluitbaar in elke staat', (t) async {
      for (final o in [PurchaseOutcome.error, PurchaseOutcome.pending, PurchaseOutcome.cancelled]) {
        final svc = await open(t, const PaywallRequest.general());
        await t.tap(find.byKey(const Key('paywall-buy')));
        await t.pump();
        svc.emit(o);
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('paywall-close')));
        await t.pumpAndSettle();
        expect(find.byKey(const Key('paywall-not-now')), findsNothing, reason: '$o');
      }
    });
  });

  test('de hackdata voor de tests is niet leeg', () => expect(hacksData.hacks, isNotEmpty));
}
