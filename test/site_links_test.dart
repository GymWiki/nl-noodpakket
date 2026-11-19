import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mijnnoodpakket/core/config/site_urls.dart';
import 'package:mijnnoodpakket/core/dialer.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/core/legal.dart';
import 'package:mijnnoodpakket/features/info/info_screen.dart';

Future<void> _pumpInfo(WidgetTester t, {double textScale = 1}) async {
  t.view.physicalSize = const Size(800, 7000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    locale: const Locale('nl', 'NL'),
    supportedLocales: const [Locale('nl', 'NL')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: const InfoScreen(),
  ));
  await t.pumpAndSettle();
}

void main() {
  tearDown(() => siteUrlStarter = startExternalUrl);

  group('website-URL\'s (lib/core/config/site_urls.dart)', () {
    test('conventie: https, hoofddomein zonder www, paden zonder slash aan het eind', () {
      expect(siteBaseUrl, startsWith('https://'));
      expect(siteBaseUrl.endsWith('/'), isFalse);
      expect(Uri.parse(siteBaseUrl).host.startsWith('www.'), isFalse);
      const paths = [
        SitePaths.privacy,
        SitePaths.contact,
        SitePaths.terms,
        SitePaths.sources,
        SitePaths.faq,
        SitePaths.changes,
      ];
      for (final p in paths) {
        expect(p, startsWith('/'));
        expect(p.endsWith('/'), isFalse, reason: p);
      }
      expect(SitePaths.home, '/');
      expect(siteUrl(SitePaths.home), '$siteBaseUrl/');
    });
  });

  group('Informatie: Over en juridisch', () {
    testWidgets('alle links bestaan, zijn altijd zichtbaar en openen de juiste pagina', (t) async {
      final opened = <String>[];
      siteUrlStarter = (uri) async {
        opened.add(uri.toString());
        return true;
      };
      await _pumpInfo(t);
      final expected = {
        S.legalPrivacy: privacyUrl,
        S.legalTerms: termsUrl,
        S.legalSupport: supportUrl,
        S.legalSources: sourcesUrl,
        S.legalWebsite: websiteUrl,
      };
      for (final e in expected.entries) {
        expect(find.text(e.key), findsOneWidget, reason: e.key);
        await t.tap(find.text(e.key));
        await t.pump();
      }
      expect(opened, expected.values.toList());
      expect(find.text(S.legalNeedsInternet), findsNothing);
    });

    testWidgets('een link die niet opent toont een rustige melding', (t) async {
      siteUrlStarter = (_) async => false;
      await _pumpInfo(t);
      await t.tap(find.text(S.legalPrivacy));
      await t.pump();
      expect(find.text(S.legalNeedsInternet), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('een fout bij het openen laat de app niet crashen', (t) async {
      siteUrlStarter = (_) async => throw Exception('geen browser');
      await _pumpInfo(t);
      await t.tap(find.text(S.legalSupport));
      await t.pump();
      expect(find.text(S.legalNeedsInternet), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('tikdoelen zijn minstens 48 dp en de pagina blijft heel bij tekstschaal 200%', (t) async {
      await _pumpInfo(t, textScale: 2);
      for (final label in [S.legalPrivacy, S.legalTerms, S.legalSupport, S.legalSources, S.legalWebsite]) {
        final tile = find.ancestor(of: find.text(label), matching: find.byType(ListTile));
        expect(tile, findsOneWidget, reason: label);
        expect(t.getSize(tile).height, greaterThanOrEqualTo(48), reason: label);
      }
      expect(t.takeException(), isNull);
    });

    testWidgets('elke link heeft een Semantics-label dat zegt dat hij in de browser opent', (t) async {
      final handle = t.ensureSemantics();
      await _pumpInfo(t);
      for (final label in [S.legalPrivacy, S.legalTerms, S.legalSupport, S.legalSources, S.legalWebsite]) {
        expect(find.bySemanticsLabel('$label. ${S.legalOpensHint}'), findsOneWidget, reason: label);
      }
      handle.dispose();
    });
  });
}
