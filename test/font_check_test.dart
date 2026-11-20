import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/features/pro/paywall_config.dart';

import 'font_check.dart';
import 'paywall_variants_test.dart' show pumpPaywall, proHackWithSiblings;

void main() {
  setUpAll(() => initializeDateFormatting('nl_NL'));

  group('lettertypecontrole', () {
    testWidgets('een lettertype dat niet geladen is, wordt herkend (anders dan een geladen lettertype)', (t) async {
      final r = await t.runAsync(() => fontRenders('NietGeladenFamilie', 'Rg'));
      expect(r, isFalse);
    });

    testWidgets('een geladen lettertype wordt herkend', (t) async {
      await loadFont('FontCheckRoboto', [File('assets/fonts/Roboto-Regular.ttf')]);
      final r = await t.runAsync(() => fontRenders('FontCheckRoboto', 'Rg'));
      expect(r, isTrue);
    });

    testWidgets('het Material Icons-lettertype laden en controleren: geen vierkantjes meer', (t) async {
      final f = materialIconsFile();
      expect(f, isNotNull, reason: 'Material Icons-bestand van de SDK niet gevonden');
      await loadAppFontsForTests();
      final problems = await t.runAsync(fontProblems);
      expect(problems, isEmpty, reason: problems?.join('\n'));
    });
  });

  group('iconen in de widgetboom', () {
    test('een icoon met een ander lettertype of een lege boom wordt afgekeurd', () {
      expect(iconTreeProblems([const Icon(IconData(0xe16a, fontFamily: 'Anders'))]), isNotEmpty);
      expect(iconTreeProblems(const []), isNotEmpty);
      expect(iconTreeProblems([const Icon(Icons.close_rounded)]), isEmpty);
    });

    for (final (name, req) in [
      ('noodhacks', PaywallRequest.hack(proHackWithSiblings().id)),
      ('herinneringen', const PaywallRequest.reminders()),
      ('kluis', const PaywallRequest.vault(vaultCount: 3)),
      ('algemeen', const PaywallRequest.general()),
    ]) {
      testWidgets('de paywall ($name) gebruikt overal het Material Icons-lettertype', (t) async {
        await pumpPaywall(t, req);
        final icons = t.widgetList<Icon>(find.byType(Icon)).toList();
        expect(icons.length, greaterThanOrEqualTo(4), reason: 'sluitknop en rij-iconen');
        expect(iconTreeProblems(icons), isEmpty);
      });
    }
  });
}
