import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/core/legal.dart';
import 'package:mijnnoodpakket/features/info/info_screen.dart';

void main() {
  group('juridische pagina\'s (GitHub Pages)', () {
    test('de links wijzen naar https en naar bestaande pagina\'s in docs/', () {
      expect(privacyUrl, startsWith('https://'));
      expect(termsUrl, startsWith('https://'));
      for (final u in [privacyUrl, termsUrl]) {
        expect(u.startsWith(legalBaseUrl), isTrue);
        final file = File('docs/${u.split('/').last}');
        expect(file.existsSync(), isTrue, reason: file.path);
      }
      expect(File('docs/index.html').existsSync(), isTrue);
      expect(File('docs/.nojekyll').existsSync(), isTrue);
    });

    test('het privacybeleid noemt elke toestemming uit het Android-manifest', () {
      final policy = File('docs/privacy.html').readAsStringSync().toLowerCase();
      final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      const words = {
        'POST_NOTIFICATIONS': 'meldingen',
        'USE_BIOMETRIC': 'biometrie',
        'CAMERA': 'camera',
        'READ_CONTACTS': 'contacten',
      };
      for (final e in words.entries) {
        expect(manifest.contains(e.key), isTrue, reason: 'manifest mist ${e.key}');
        expect(policy.contains(e.value), isTrue, reason: 'beleid noemt ${e.value} niet');
      }
    });

    test('het privacybeleid belooft niets wat de app niet doet: geen analytics-pakketten', () {
      final pubspec = File('pubspec.yaml').readAsStringSync().toLowerCase();
      for (final bad in ['firebase', 'analytics', 'sentry', 'crashlytics', 'admob', 'facebook', 'appsflyer', 'mixpanel']) {
        expect(pubspec.contains(bad), isFalse, reason: bad);
      }
    });

    test('pagina\'s hebben de disclaimer, taal nl en geen verwijzing naar een persoonlijk e-mailadres', () {
      for (final f in ['index', 'privacy', 'terms']) {
        final s = File('docs/$f.html').readAsStringSync();
        expect(s.contains('lang="nl"'), isTrue, reason: f);
        expect(s.contains('vertegenwoordigt de Nederlandse overheid niet'), isTrue, reason: f);
        expect(RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+').hasMatch(s), isFalse, reason: '$f bevat een e-mailadres');
      }
    });
  });

  testWidgets('Informatie: privacybeleid, voorwaarden en licenties zijn te bereiken', (t) async {
    t.view.physicalSize = const Size(800, 3600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(
      locale: Locale('nl', 'NL'),
      supportedLocales: [Locale('nl', 'NL')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: InfoScreen(),
    ));
    await t.pumpAndSettle();
    expect(find.text(S.legalTitle), findsOneWidget);
    expect(find.text(S.legalPrivacy), findsOneWidget);
    expect(find.text(S.legalTerms), findsOneWidget);
    expect(find.text(S.legalLicenses), findsOneWidget);
    await t.tap(find.text(S.legalLicenses));
    await t.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  group('inhoud na de audit', () {
    final hacks = File('assets/wiki/noodhacks.json').readAsStringSync();
    final wiki = File('assets/wiki/noodgevallen.json').readAsStringSync();

    test('koelkast: geen ongedekte uren; alleen drempels van het Voedingscentrum', () {
      final i = hacks.indexOf('"id": "koelkast-stroomuitval"');
      final block = hacks.substring(i, hacks.indexOf('"id":', i + 20));
      for (final bad in ['4 uur koel', '48 uur', 'Tot ongeveer 4 uur', 'halfvolle']) {
        expect(block.contains(bad), isFalse, reason: bad);
      }
      expect(block.contains('10 °C'), isTrue);
      expect(block.contains('15 °C'), isTrue);
    });

    test('DigiHulplijn wordt beschreven zoals Denk Vooruit dat doet', () {
      expect(wiki.contains('0800-1508'), isTrue);
      expect(wiki.contains('online oplichting of hacking'), isFalse);
      expect(wiki.contains('inloggen in twee stappen'), isTrue);
    });

    test('brandwond: 10 minuten, zoals de Brandweer zegt (niet "minimaal")', () {
      expect(wiki.contains('minimaal 10 minuten'), isFalse);
      expect(wiki.contains('Koel de brandwond 10 minuten'), isTrue);
    });
  });

  test('release-bundel: bouw faalt zonder upload-sleutel in plaats van debug-signing', () {
    final g = File('android/app/build.gradle.kts').readAsStringSync();
    expect(g.contains('GradleException'), isTrue);
    expect(g.contains('key.properties ontbreekt'), isTrue);
  });

  test('iOS: privacymanifest zonder tracking is aanwezig en in het Xcode-project opgenomen', () {
    final m = File('ios/Runner/PrivacyInfo.xcprivacy').readAsStringSync();
    expect(m.contains('NSPrivacyTracking'), isTrue);
    expect(RegExp(r'NSPrivacyTracking</key>\s*<false/>').hasMatch(m), isTrue);
    final p = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect('PrivacyInfo.xcprivacy in Resources'.allMatches(p).length, greaterThanOrEqualTo(2));
  });
}
