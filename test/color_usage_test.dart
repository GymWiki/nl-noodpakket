import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/core/calm.dart';
import 'package:mijnnoodpakket/core/theme/category_palette.dart';
import 'package:mijnnoodpakket/core/ui.dart';
import 'package:mijnnoodpakket/features/dashboard/dashboard_cards.dart';
import 'package:mijnnoodpakket/features/kluis/ui/vault_link.dart';
import 'package:mijnnoodpakket/features/more/more_screen.dart';
import 'package:mijnnoodpakket/features/more/my_plan_screen.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_links.dart';
import 'package:mijnnoodpakket/features/noodplan/ui/plan_wiki_block.dart';

import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/features/dashboard/dashboard_screen.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_models.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_overview_screen.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_providers.dart';
import 'package:mijnnoodpakket/features/rampenzender/rampenzender_strings.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_overview_screen.dart';

import 'calm_test.dart' show calmOverrides;
import 'dashboard_widget_test.dart' show overrides, wrap, tall;

/// Dezelfde functie heeft overal dezelfde tint: Mijn plan, Meer, dashboardkaarten en wiki-blokken.
void main() {
  setUpAll(() => initializeDateFormatting('nl_NL'));

  Set<CategoryTint?> tintsOf(WidgetTester t) => {
        for (final w in t.widgetList<IconBadge>(find.byType(IconBadge))) w.tint,
      };

  testWidgets('Mijn plan: elke rij een eigen tint volgens het palet', (t) async {
    await tall(t, w: 360, h: 1500);
    await t.pumpWidget(wrap(const MyPlanScreen(), overrides(const [])));
    await t.pumpAndSettle();
    final rows = t.widgetList<StatusRow>(find.byType(StatusRow)).toList();
    expect(rows.map((r) => r.tint), [
      menuTint(MenuItemKind.plan),
      menuTint(MenuItemKind.talk),
      menuTint(MenuItemKind.vault),
      menuTint(MenuItemKind.share),
    ]);
    expect(rows.map((r) => r.tint).toSet().length, rows.length, reason: 'sibling-rijen met dezelfde tint');
  });

  testWidgets('Meer: elke rij een eigen tint; alleen Instellingen is neutraal', (t) async {
    await tall(t, w: 360, h: 1000);
    await t.pumpWidget(wrap(const MoreScreen(), overrides(const [])));
    await t.pumpAndSettle();
    final rows = t.widgetList<StatusRow>(find.byType(StatusRow)).toList();
    expect(rows.map((r) => r.tint), [
      menuTint(MenuItemKind.maintenance),
      menuTint(MenuItemKind.info),
      menuTint(MenuItemKind.settings),
    ]);
    expect(rows.map((r) => r.tint).toSet().length, rows.length);
    expect(rows.where((r) => r.tint!.neutral).length, 1);
  });

  testWidgets('dashboard: Noodplan en Kluis gebruiken dezelfde tint als in Mijn plan', (t) async {
    await tall(t, w: 360, h: 900);
    await t.pumpWidget(wrap(const Scaffold(body: PlanVaultRow()), overrides(const [])));
    await t.pumpAndSettle();
    final rows = t.widgetList<StatusRow>(find.byType(StatusRow)).toList();
    expect(rows.map((r) => r.tint), [menuTint(MenuItemKind.plan), menuTint(MenuItemKind.vault)]);
  });

  testWidgets('wiki-blok "Jouw afspraken": bolletje in de tint van het noodplan', (t) async {
    await tall(t, w: 360, h: 1200);
    final id = planLinks.keys.first;
    await t.pumpWidget(wrap(Scaffold(body: SingleChildScrollView(child: PlanWikiBlock(emergencyId: id))), overrides(const [])));
    await t.pumpAndSettle();
    expect(tintsOf(t), {menuTint(MenuItemKind.plan)});
  });

  testWidgets('kluislink in de wiki: bolletje in de tint van de kluis', (t) async {
    await tall(t, w: 360, h: 600);
    await t.pumpWidget(wrap(const Scaffold(body: VaultLinkTile()), overrides(const [])));
    await t.pumpAndSettle();
    expect(tintsOf(t), {menuTint(MenuItemKind.vault)});
  });

  CategoryTint? rowTint(WidgetTester t, String title) =>
      t.widgetList<StatusRow>(find.byType(StatusRow)).firstWhere((r) => r.title == title).tint;

  testWidgets('Noodgevallen, Extra hulp: vier ingangen met vier verschillende tinten volgens het palet', (t) async {
    await tall(t, w: 360, h: 3000);
    await t.pumpWidget(wrap(const WikiOverviewScreen(), calmOverrides()));
    for (var i = 0; i < 6; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
      await t.pump(const Duration(milliseconds: 250));
    }
    final got = [
      rowTint(t, S.hacksIntroOut),
      rowTint(t, S.hacksTitle),
      rowTint(t, RZ.entryTitle),
      rowTint(t, S.wikiPdfCard),
    ];
    expect(got, [
      menuTint(MenuItemKind.packetOut),
      menuTint(MenuItemKind.hacks),
      menuTint(MenuItemKind.radio),
      menuTint(MenuItemKind.meterkast),
    ]);
    expect(got.toSet().length, 4, reason: 'twee ingangen met dezelfde tint');
  });

  testWidgets('Noodhacks: de twee actierijen hebben een eigen tint', (t) async {
    await tall(t, w: 360, h: 3000);
    final o = [
      ...calmOverrides(),
      hacksProvider.overrideWith((ref) async => HackData.parse(File('assets/wiki/noodhacks.json').readAsStringSync())),
    ];
    await t.pumpWidget(wrap(const HacksOverviewScreen(), o));
    for (var i = 0; i < 6; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
      await t.pump(const Duration(milliseconds: 250));
    }
    expect(rowTint(t, S.hacksIntroOut), menuTint(MenuItemKind.packetOut));
    expect(rowTint(t, S.hacksHave), menuTint(MenuItemKind.hacksHave));
    expect(rowTint(t, S.hacksIntroOut), isNot(rowTint(t, S.hacksHave)));
    // Dezelfde functie, dezelfde tint als in Noodgevallen: "Mijn pakket is op".
    expect(rowTint(t, S.hacksIntroOut), menuTint(MenuItemKind.packetOut));
  });

  testWidgets('Start, Meer overzicht: Noodplan, Kluis en Huishouden zijn verschillend en gelijk aan elders', (t) async {
    await tall(t, w: 360, h: 3000);
    await t.pumpWidget(wrap(const DashboardScreen(), calmOverrides()));
    await t.pumpAndSettle();
    final got = [rowTint(t, S.dashPlanCard), rowTint(t, S.dashVaultCard), rowTint(t, S.dashHouseholdTitle)];
    expect(got, [menuTint(MenuItemKind.plan), menuTint(MenuItemKind.vault), menuTint(MenuItemKind.household)]);
    expect(got.toSet().length, 3);
  });
}
