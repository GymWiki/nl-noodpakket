// Store-screenshots (Google Play en App Store). Eén deterministische test per scherm.
// Draaien: zie README ("Store-screenshots maken") of tool/screenshots/android.ps1.
//
//   flutter drive --driver=test_driver/integration_test.dart --target=integration_test/store_screenshots_test.dart -d <apparaat>
//
// Fixture: verzonnen gezin, vaste tijd, Pro uit, plugins stil (zie integration_test/store/fixture.dart).
// Er gaat niets van deze map mee in de release-build.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/app.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/features/deel/deel_services.dart';
import 'package:mijnnoodpakket/features/deel/ui/share_setup_screen.dart';

import 'store/fixture.dart';

/// Haalt de systeemmarges weg, zodat de app het hele canvas vult en er geen leeg vlak voor de statusbalk
/// of navigatiebalk in de screenshot staat (die staan niet in het Flutter-beeld, maar de marges wel).
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
  var converted = false;

  setUpAll(() async {
    await initializeDateFormatting('nl_NL');
  });

  Future<void> wait(WidgetTester t, [int ms = 1800]) async {
    for (var i = 0; i < ms ~/ 300; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
  }

  /// Start de app met de fixture, laat [navigate] naar het scherm gaan en maakt de screenshot.
  Future<void> screen(
    WidgetTester t,
    String name,
    Future<void> Function(GoRouter router, WidgetTester t) navigate, {
    bool pro = false,
  }) async {
    mockPlatformChannels(TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger);
    if (!converted && defaultTargetPlatform == TargetPlatform.android) {
      await binding.convertFlutterSurfaceToImage();
      converted = true;
    }
    await t.pumpWidget(ProviderScope(
      overrides: await storeOverrides(pro: pro),
      child: const _FullBleed(child: NoodpakketApp()),
    ));
    await wait(t);
    final container = ProviderScope.containerOf(t.element(find.byType(NoodpakketApp)));
    await navigate(container.read(routerProvider), t);
    await wait(t);
    await binding.takeScreenshot(name);
  }

  testWidgets('01 Start met Paraatheid', (t) => screen(t, '01_start', (r, t) async => r.go('/start')));

  testWidgets('02 Pakket', (t) => screen(t, '02_pakket', (r, t) async => r.go('/checklist')));

  testWidgets('03 Wat nu? Stappenplan Stroomstoring', (t) => screen(t, '03_stroomstoring', (r, t) async {
        r.go('/wiki/stroomstoring/stappen');
        await wait(t);
        // Stap 2 laten zien, zodat het stappenplan "in gebruik" is (Apple 2.3.3).
        await t.tap(find.text(S.wikiNext));
        await wait(t, 600);
      }));

  testWidgets('04 Mijn noodplan', (t) => screen(t, '04_noodplan', (r, t) async => r.go('/plan')));

  testWidgets('05 Delen via QR', (t) => screen(t, '05_delen_qr', (r, t) async {
        r.go('/mijn-plan');
        await wait(t, 600);
        r.push('/delen/qr', extra: const ShareLaunch(DeelDraft()));
        await wait(t, 3000);
      }));

  testWidgets('06 Documentenkluis', (t) => screen(t, '06_kluis', (r, t) async => r.go('/kluis')));

  testWidgets('07 Rampenzender', (t) => screen(t, '07_rampenzender', (r, t) async => r.go('/rampenzender')));

  testWidgets('08 Noodhacks (Pro-aanduiding)', (t) => screen(t, '08_noodhacks', (r, t) async => r.go('/hacks')));
}
