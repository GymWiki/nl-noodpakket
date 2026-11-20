import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show ByteData, FontLoader;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/core/providers.dart';
import 'package:mijnnoodpakket/core/theme.dart';
import 'package:mijnnoodpakket/data/repositories/settings_repository.dart';
import 'package:mijnnoodpakket/domain/models.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_providers.dart';
import 'package:mijnnoodpakket/features/pro/pro_providers.dart';
import 'package:mijnnoodpakket/features/pro/pro_ui.dart';

import 'fake_purchase.dart';
import 'font_check.dart';
import 'paywall_variants_test.dart' show hacksData, proHackWithSiblings;

/// Hulpmiddel (geen controle): schrijft screenshots van de drie paywall-varianten, licht en donker, naar de map in
/// `PAYWALL_SHOTS_DIR`. Zonder die variabele doet de test niets.
///
///   PAYWALL_SHOTS_DIR=docs/paywall FLUTTER_ROOT=$(dirname $(dirname $(which flutter))) \
///     flutter test test/tool_paywall_shots_test.dart
///
/// De prijs, het item en de hack zijn demo-waarden voor de afbeelding; in de app komt de prijs uit de winkel.
void main() {
  final dir = Platform.environment['PAYWALL_SHOTS_DIR'];

  setUpAll(() async {
    await initializeDateFormatting('nl_NL');
    Future<void> load(String family, List<String> paths) async {
      final l = FontLoader(family);
      var any = false;
      for (final p in paths) {
        final f = File(p);
        if (f.existsSync()) {
          l.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
          any = true;
        }
      }
      if (any) await l.load();
    }

    await load('Roboto', ['assets/fonts/Roboto-Regular.ttf', 'assets/fonts/Roboto-Bold.ttf']);
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root != null) {
      const dir = 'bin/cache/artifacts/material_fonts';
      await load('MaterialIcons', ['$root/$dir/MaterialIcons-Regular.otf', '$root/$dir/materialicons-regular.otf']);
    }
  });

  final item = Item(
    id: 'demo',
    isCustom: false,
    hidden: false,
    name: 'Blikken soep',
    category: Cat.other,
    why: '',
    unit: 'stuks',
    recommended: 1,
    inHouse: true,
    expiryDate: DateTime(2027, 3, 14),
  );

  final variants = <String, PaywallRequest>{
    'noodhacks': PaywallRequest.hack(proHackWithSiblings().id),
    'herinneringen': const PaywallRequest.reminders(itemId: 'demo'),
    'kluis': const PaywallRequest.vault(vaultCount: 3),
  };

  for (final v in variants.entries) {
    for (final b in Brightness.values) {
      testWidgets('${v.key} ${b == Brightness.light ? 'licht' : 'donker'}', (t) async {
        if (dir == null) return;
        t.view.physicalSize = const Size(360 * 2, 780 * 2);
        t.view.devicePixelRatio = 2;
        addTearDown(t.view.reset);
        final key = GlobalKey();
        await t.pumpWidget(RepaintBoundary(
          key: key,
          child: ProviderScope(
            overrides: [
              purchaseServiceProvider.overrideWithValue(FakePurchaseService(price: '€ 3,99')),
              proUnlockedProvider.overrideWithValue(false),
              hacksProvider.overrideWith((ref) => hacksData),
              allItemsProvider.overrideWithValue(AsyncValue.data([item])),
              settingsProvider.overrideWith((ref) => Stream.value(const AppSettings(leadDays: 30))),
              storeNameProvider.overrideWithValue('Apple'),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildTheme(b),
              locale: const Locale('nl', 'NL'),
              supportedLocales: const [Locale('nl', 'NL')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: Builder(
                builder: (c) => Scaffold(
                  body: Center(child: TextButton(onPressed: () => showPaywall(c, request: v.value), child: const Text('open'))),
                ),
              ),
            ),
          ),
        ));
        await t.tap(find.text('open'));
        await t.pumpAndSettle();
        // Geen screenshot met lege vierkantjes: zonder echt geladen iconen en lettertypen mislukt de test.
        final problems = await t.runAsync(fontProblems);
        expect(problems, isEmpty, reason: problems?.join('\n'));
        expect(iconTreeProblems(t.widgetList<Icon>(find.byType(Icon))), isEmpty);
        final name = '${v.key}_${b == Brightness.light ? 'licht' : 'donker'}.png';
        await t.runAsync(() async {
          final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          Directory(dir).createSync(recursive: true);
          File('$dir/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      });
    }
  }
}
