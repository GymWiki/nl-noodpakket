// Reviewscreenshot voor de in-app aankoop `pro_unlock` (App Store Connect > de aankoop > App Review Information).
// Een echte opname van de paywall (variant Noodhacks) op de iOS-simulator, niet uit een widget- of golden-test.
//
//   STORE_RAW_DIR=store/raw/iap-review flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/iap_review_test.dart -d <iphone-simulator>
//
// De test loopt de route van een reviewer: tab "Wat nu?", sectie "Extra hulp", rij "Noodhacks", een hack met de
// Pro-aanduiding. Er is niets aangepast in de UI. Alleen de gegevens zijn demodata (zie integration_test/store/fixture.dart:
// verzonnen gezin, Pro uit, store-mock met een prijs, geen echte persoonsgegevens). Voordat de opname wordt gemaakt,
// controleert de test dat de iconen en lettertypen echt zijn geladen; anders mislukt hij in plaats van vierkantjes te tonen.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/app.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_overview_screen.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_widgets.dart';
import 'package:mijnnoodpakket/features/pro/paywall_sheet.dart';
import 'package:mijnnoodpakket/features/pro/pro_providers.dart';
import 'package:mijnnoodpakket/features/pro/pro_ui.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_overview_screen.dart';

import '../test/font_check.dart';
import 'store/fixture.dart';

/// Zelfde als in store_screenshots_test.dart: systeemmarges weg, zodat de app het hele canvas vult.
class _FullBleed extends StatelessWidget {
  const _FullBleed({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(
        padding: EdgeInsets.zero,
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        systemGestureInsets: EdgeInsets.zero,
        textScaler: TextScaler.noScaling,
        platformBrightness: Brightness.light,
        disableAnimations: true,
      ),
      child: child,
    );
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('nl_NL');
    // Alleen voor een dry-run met `flutter test` (geen toestel): de SDK-lettertypen laden. Op de simulator niet nodig.
    if (Platform.environment['IAP_REVIEW_LOAD_SDK_FONTS'] == 'true') await loadAppFontsForTests();
  });

  // Dry-run met `flutter test` (geen toestel): daar loopt geen echte I/O tijdens pump, dus geven we tussendoor echte tijd.
  final dryRun = Platform.environment['IAP_REVIEW_NO_SCREENSHOT'] == 'true';

  Future<void> wait(WidgetTester t, [int ms = 1800]) async {
    for (var i = 0; i < ms ~/ 300; i++) {
      await t.pump(const Duration(milliseconds: 300));
      if (dryRun) await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    }
  }

  testWidgets('Pro-aankoop: paywall, variant Noodhacks', (t) async {
    mockPlatformChannels(TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger);
    await t.pumpWidget(ProviderScope(
      overrides: await storeOverrides(pro: false),
      child: const _FullBleed(child: NoodpakketApp()),
    ));
    await wait(t);
    final container = ProviderScope.containerOf(t.element(find.byType(NoodpakketApp)));

    // De lijst van het scherm waar we nu op staan (er staan meer schermen in de boom, ook onder een gepusht scherm).
    Finder listOf(Type screen) => find.descendant(of: find.byType(screen), matching: find.byType(Scrollable)).first;

    // Scrollt tot [target] gebouwd is (lijsten bouwen lazy) en zichtbaar is. `first` pas gebruiken als er iets is.
    Future<void> scrollTo(Finder target, Type screen) async {
      for (var i = 0; i < 40 && target.evaluate().isEmpty; i++) {
        await t.drag(listOf(screen), const Offset(0, -300));
        await wait(t, 300);
      }
      expect(target, findsWidgets, reason: 'niet gevonden na scrollen');
      await t.ensureVisible(target.first);
      await wait(t, 300);
    }

    // 1. Tab "Wat nu?"
    await t.tap(find.text(S.navEmergencies));
    await wait(t, 1200);
    expect(find.byType(WikiOverviewScreen), findsOneWidget);

    // 2. Sectie "Extra hulp", rij "Noodhacks"
    await scrollTo(find.text(S.wikiMoreHelp), WikiOverviewScreen);
    await scrollTo(find.text(S.hacksTitle), WikiOverviewScreen);
    await t.tap(find.text(S.hacksTitle).first);
    await wait(t, 1200);
    expect(find.byType(HacksOverviewScreen), findsOneWidget);

    // 3. Een hack met de Pro-aanduiding
    final proTile = find.ancestor(of: find.byType(ProBadge), matching: find.byType(HackTile));
    await scrollTo(proTile, HacksOverviewScreen);
    await t.tap(proTile.first);
    await wait(t, 1500);

    // De paywall staat er, zoals een reviewer hem ziet.
    expect(find.byType(PaywallSheet), findsOneWidget);
    expect(find.text(S.paywallHacksTitle), findsOneWidget);
    expect(find.text(S.paywallUnlock('€ 3,99')), findsOneWidget, reason: 'prijs uit de store-mock');
    final store = container.read(storeNameProvider);
    if (defaultTargetPlatform == TargetPlatform.iOS) expect(store, 'Apple');
    expect(find.text(S.paywallStoreNote(store)), findsOneWidget);
    expect(find.text(S.paywallRestore), findsOneWidget);
    expect(find.text(S.paywallNotNow), findsOneWidget);

    // Alle iconen en lettertypen zijn echt gerenderd: geen lege vierkantjes.
    final icons = t.widgetList<Icon>(find.descendant(of: find.byType(PaywallSheet), matching: find.byType(Icon))).toList();
    expect(iconTreeProblems(icons), isEmpty);
    final problems = await fontProblems();
    expect(problems, isEmpty, reason: problems.join('\n'));

    // Alleen voor een dry-run zonder toestel (geen screenshot-ondersteuning): IAP_REVIEW_NO_SCREENSHOT=true.
    if (dryRun) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      await binding.convertFlutterSurfaceToImage();
      await t.pump(const Duration(milliseconds: 400));
    }
    await binding.takeScreenshot('pro_unlock_review');
  });
}
