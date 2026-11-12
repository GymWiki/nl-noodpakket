import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, FontLoader;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mijnnoodpakket/app.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/core/theme.dart';

void main() {
  setUpAll(() async {
    // Echte letter (Ahem is veel te breed voor een meetbare test).
    final l = FontLoader('Roboto');
    for (final f in ['Regular', 'Bold']) {
      l.addFont(Future.value(ByteData.view(File('assets/fonts/Roboto-$f.ttf').readAsBytesSync().buffer)));
    }
    await l.load();
  });
  final labels = [S.navHome, S.navChecklist, S.navEmergencies, S.navPlan, S.navMore];
  final full = [S.navHome, S.navChecklist, S.navWiki, S.navPlan, S.navMore];

  Future<void> pump(WidgetTester t, double w, double scale, {bool dark = false, int sel = 2}) async {
    t.view.physicalSize = Size(w, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      theme: dark ? buildTheme(Brightness.dark) : buildTheme(Brightness.light),
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(bottomNavigationBar: NoodNavBar(selectedIndex: sel, onSelected: (_) {})),
    ));
    await t.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    for (final w in [320.0, 360.0, 411.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets('labels op één regel: ${w.toInt()}dp, schaal $scale, ${dark ? 'donker' : 'licht'}', (t) async {
          await pump(t, w, scale, dark: dark);
          expect(t.takeException(), isNull);
          for (final l in labels) {
            final p = t.renderObject<RenderParagraph>(find.text(l));
            expect(p.didExceedMaxLines, isFalse, reason: '$l breekt/kapt af');
            expect(p.maxLines, 1);
            expect(p.softWrap, isFalse);
          }
        });
      }
    }
  }

  testWidgets('Semantics: tabs hebben de volledige namen', (t) async {
    final h = t.ensureSemantics();
    await pump(t, 360, 1.0);
    for (final f in full) {
      expect(find.bySemanticsLabel(RegExp(f)), findsWidgets, reason: f);
    }
    expect(find.byTooltip(S.navWiki), findsOneWidget);
    h.dispose();
  });

  testWidgets('actieve tab verdringt niets: alle vijf labels zichtbaar bij elke selectie', (t) async {
    for (var i = 0; i < 5; i++) {
      await pump(t, 320, 2.0, sel: i); // geklemd op navMaxTextScale
      for (final l in labels) {
        expect(t.renderObject<RenderParagraph>(find.text(l)).didExceedMaxLines, isFalse);
      }
    }
  });
}
