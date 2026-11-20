import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/core/providers.dart';
import 'package:mijnnoodpakket/data/repositories/settings_repository.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_providers.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_widgets.dart';
import 'package:mijnnoodpakket/features/pro/pro_providers.dart';

import 'fake_purchase.dart';
import 'paywall_variants_test.dart' show hacksData;

/// Veiligheidsinformatie is altijd gratis en zonder paywall. Dit bewijst het in gedrag, hack voor hack.
void main() {
  setUpAll(() => initializeDateFormatting('nl_NL'));

  test('de data heeft mythes, "Doe dit nooit"-hacks en proefhacks om te controleren', () {
    expect(hacksData.hacks.where((h) => h.categorie == 'mythes'), isNotEmpty);
    expect(hacksData.hacks.where((h) => h.freePreview), isNotEmpty);
    expect(hacksData.hacks.where((h) => !h.isFree), isNotEmpty);
  });

  testWidgets('elke gratis hack opent zonder paywall; elke Pro-hack opent de paywall (zonder Pro)', (t) async {
    t.view.physicalSize = const Size(1080, 2200);
    t.view.devicePixelRatio = 2.75;
    addTearDown(t.view.reset);
    var free = 0, pro = 0;
    for (final h in hacksData.hacks) {
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, _) => Scaffold(body: SingleChildScrollView(child: HackTile(hack: h)))),
        GoRoute(path: '/hacks/:id', builder: (_, s) => Scaffold(body: Text('detail ${s.pathParameters['id']}'))),
      ]);
      await t.pumpWidget(ProviderScope(
        overrides: [
          proUnlockedProvider.overrideWithValue(false),
          purchaseServiceProvider.overrideWithValue(FakePurchaseService()),
          hacksProvider.overrideWith((ref) => hacksData),
          settingsProvider.overrideWith((ref) => Stream.value(const AppSettings())),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('nl', 'NL'),
          supportedLocales: const [Locale('nl', 'NL')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
      ));
      await t.pumpAndSettle();
      await t.tap(find.byType(ListTile));
      await t.pumpAndSettle();
      final paywall = find.byKey(const Key('paywall-not-now'));
      if (h.isFree) {
        free++;
        expect(find.text('detail ${h.id}'), findsOneWidget, reason: '${h.id} is gratis');
        expect(paywall, findsNothing, reason: '${h.id} is gratis en mag nooit een paywall tonen');
        expect(find.byKey(const Key('pro-hint')), findsNothing, reason: h.id);
      } else {
        pro++;
        expect(paywall, findsOneWidget, reason: '${h.id} is Pro');
        expect(find.text('detail ${h.id}'), findsNothing, reason: h.id);
      }
    }
    // Mythes, "Doe dit nooit" en de proefhacks zijn echt langs gekomen.
    expect(free, hacksData.hacks.where((h) => h.isFree).length);
    expect(pro, hacksData.hacks.where((h) => !h.isFree).length);
    expect(free, greaterThan(2));
  });
}
