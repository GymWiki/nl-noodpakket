import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mijnnoodpakket/core/config/store_urls.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/core/theme.dart';
import 'package:mijnnoodpakket/features/info/info_screen.dart';
import 'package:mijnnoodpakket/features/review/review_providers.dart';
import 'package:mijnnoodpakket/features/review/store_review_opener.dart';

import 'review_fakes.dart';

/// Nepopener: geeft een vaste uitkomst en telt de aanroepen.
class _Opener implements StoreReviewOpener {
  _Opener(this.result);
  final StoreReviewResult result;
  int calls = 0;

  @override
  Future<StoreReviewResult> open() async {
    calls++;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  Future<(_Opener, FakeReviewLauncher)> pumpInfo(WidgetTester t, StoreReviewResult result) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 2.75;
    addTearDown(t.view.reset);
    final opener = _Opener(result);
    final launcher = FakeReviewLauncher();
    await t.pumpWidget(ProviderScope(
      overrides: [
        storeReviewOpenerProvider.overrideWithValue(opener),
        reviewLauncherProvider.overrideWithValue(launcher),
      ],
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        locale: const Locale('nl', 'NL'),
        supportedLocales: const [Locale('nl', 'NL')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const InfoScreen(),
      ),
    ));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text(S.reviewRowTitle), 300);
    return (opener, launcher);
  }

  group('de rij "Beoordeel NL-Noodpakket" onder Meer > Informatie', () {
    testWidgets('bestaat, met de rustige regel en zonder beloning of vraag om een goede beoordeling', (t) async {
      await pumpInfo(t, StoreReviewResult.opened);
      expect(find.text('Beoordeel NL-Noodpakket'), findsOneWidget);
      expect(find.text('Je beoordeling helpt andere mensen de app te vinden.'), findsOneWidget);
      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
    });

    testWidgets('tikken opent de winkelpagina en roept nooit de systeemprompt aan', (t) async {
      final (opener, launcher) = await pumpInfo(t, StoreReviewResult.opened);
      await t.tap(find.text(S.reviewRowTitle));
      await t.pumpAndSettle();
      expect(opener.calls, 1);
      expect(find.byType(SnackBar), findsNothing, reason: 'gelukt: geen melding nodig');
      expect(launcher.calls, isEmpty, reason: 'geen knop die de systeem-API aanroept');
    });

    testWidgets('geen internet: een rustige melding', (t) async {
      final (opener, launcher) = await pumpInfo(t, StoreReviewResult.offline);
      await t.tap(find.text(S.reviewRowTitle));
      await t.pumpAndSettle();
      expect(opener.calls, 1);
      expect(find.text('Geen internet. Probeer het later opnieuw.'), findsOneWidget);
      expect(launcher.calls, isEmpty);
    });

    testWidgets('niet te openen: een rustige melding en geen crash', (t) async {
      await pumpInfo(t, StoreReviewResult.failed);
      await t.tap(find.text(S.reviewRowTitle));
      await t.pumpAndSettle();
      expect(find.text(S.reviewOpenError), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('het tikdoel is minstens 48 dp', (t) async {
      await pumpInfo(t, StoreReviewResult.opened);
      final row = find.ancestor(of: find.text(S.reviewRowTitle), matching: find.byType(InkWell)).first;
      expect(t.getSize(row).height, greaterThanOrEqualTo(48));
    });
  });

  group('StoreReviewOpener (de echte logica met nepbrowser en nepnetwerk)', () {
    Future<(StoreReviewResult, List<Uri>, List<String>)> run({
      required TargetPlatform platform,
      bool online = true,
      bool startOk = true,
      bool startThrows = false,
    }) async {
      final started = <Uri>[];
      final checked = <String>[];
      final opener = StoreReviewOpener(
        platform: platform,
        reachable: (host) async {
          checked.add(host);
          return online;
        },
        start: (uri) async {
          started.add(uri);
          if (startThrows) throw StateError('geen browser');
          return startOk;
        },
      );
      return (await opener.open(), started, checked);
    }

    test('iOS opent de echte App Store-pagina met action=write-review', () async {
      final (r, started, checked) = await run(platform: TargetPlatform.iOS);
      expect(r, StoreReviewResult.opened);
      expect(started.single.toString(), 'https://apps.apple.com/nl/app/nl-noodpakket/id6757681584?action=write-review');
      expect(started.single.queryParameters['action'], 'write-review');
      expect(checked, ['apps.apple.com']);
    });

    test('Android opent de Play Store-pagina op basis van het pakket-id', () async {
      final (r, started, checked) = await run(platform: TargetPlatform.android);
      expect(r, StoreReviewResult.opened);
      expect(started.single.toString(), 'https://play.google.com/store/apps/details?id=com.mycompany.mijnnoodpakket');
      expect(checked, ['play.google.com']);
    });

    test('geen internet: er wordt niets geopend en het resultaat is "offline"', () async {
      for (final p in [TargetPlatform.iOS, TargetPlatform.android]) {
        final (r, started, _) = await run(platform: p, online: false);
        expect(r, StoreReviewResult.offline);
        expect(started, isEmpty);
      }
    });

    test('openen mislukt (false of een fout): "failed", nooit een uitzondering', () async {
      expect((await run(platform: TargetPlatform.iOS, startOk: false)).$1, StoreReviewResult.failed);
      expect((await run(platform: TargetPlatform.android, startThrows: true)).$1, StoreReviewResult.failed);
    });
  });

  group('winkel-URL\'s (lib/core/config/store_urls.dart)', () {
    test('de App Store-URL gebruikt het Apple ID en de Nederlandse winkel', () {
      expect(appStoreId, '6757681584');
      expect(appStoreUrl, 'https://apps.apple.com/nl/app/nl-noodpakket/id6757681584');
      expect(appStoreReviewUrl, '$appStoreUrl?action=write-review');
    });

    test('het Android-pakket-id in de URL is gelijk aan de applicationId van de app', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      final id = RegExp(r'applicationId\s*=\s*"([^"]+)"').firstMatch(gradle)!.group(1);
      expect(androidPackageId, id);
      expect(playStoreUrl, 'https://play.google.com/store/apps/details?id=$id');
    });

    test('https, geen www, en de open TODO\'s staan zichtbaar in het bestand', () {
      for (final u in [appStoreUrl, appStoreReviewUrl, playStoreUrl]) {
        expect(u, startsWith('https://'));
        expect(Uri.parse(u).host.startsWith('www.'), isFalse);
      }
      final src = File('lib/core/config/store_urls.dart').readAsStringSync();
      expect('TODO'.allMatches(src).length, greaterThanOrEqualTo(2));
      expect(src, contains('Play-pagina bestaat nog niet'));
    });
  });
}
