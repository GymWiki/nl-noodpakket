import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show ByteData, FontLoader;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/core/theme.dart';
import 'package:mijnnoodpakket/features/dashboard/dashboard_providers.dart';
import 'package:mijnnoodpakket/features/deel/deel_providers.dart';
import 'package:mijnnoodpakket/features/deel/domain/shared_plan_logic.dart';
import 'package:mijnnoodpakket/features/more/more_screen.dart';
import 'package:mijnnoodpakket/features/more/my_plan_screen.dart';

/// Hulpmiddel (geen controle): schrijft screenshots van Mijn plan en Meer naar de map in
/// `COLOR_SHOTS_DIR`, in licht, donker en met kleurenblindheidssimulatie. Zonder die variabele doet de test niets.
///
///   COLOR_SHOTS_DIR=docs/colors/after flutter test test/tool_color_shots_test.dart
///
/// De simulatie past de Machado-matrices (ernst 1,0) toe op sRGB-waarden; dat is een benadering
/// (de afstandstests in color_distance_test.dart rekenen wel in lineaire RGB).
const _cvd = {
  'deuteranopie': <double>[0.367322, 0.860646, -0.227968, 0, 0, 0.280085, 0.672501, 0.047413, 0, 0, -0.011820, 0.042940, 0.968881, 0, 0, 0, 0, 0, 1, 0],
  'protanopie': <double>[0.152286, 1.052583, -0.204868, 0, 0, 0.114503, 0.786281, 0.099216, 0, 0, -0.003882, -0.048116, 1.051998, 0, 0, 0, 0, 0, 1, 0],
  'tritanopie': <double>[1.255528, -0.076749, -0.178779, 0, 0, -0.078411, 0.930809, 0.147602, 0, 0, 0.004733, 0.691367, 0.303900, 0, 0, 0, 0, 0, 1, 0],
};

void main() {
  final dir = Platform.environment['COLOR_SHOTS_DIR'];

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
    if (root != null) await load('MaterialIcons', ['$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf']);
  });

  final modes = <String, (Brightness, List<double>?)>{
    'licht': (Brightness.light, null),
    'donker': (Brightness.dark, null),
    for (final e in _cvd.entries) e.key: (Brightness.light, e.value),
  };

  for (final screen in {'mijnplan': const MyPlanScreen(), 'meer': const MoreScreen()}.entries) {
    for (final m in modes.entries) {
      testWidgets('${screen.key} ${m.key}', (t) async {
        if (dir == null) return;
        t.view.physicalSize = const Size(360 * 3, 640 * 3);
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.reset);
        final key = GlobalKey();
        await t.pumpWidget(ProviderScope(
          overrides: [
            sharedPlansProvider.overrideWith((ref) => Stream.value(const <SharedPlan>[])),
            planVaultStatusProvider.overrideWithValue(const PlanVaultStatus(
                planStarted: true, planDone: 1, planTotal: 7, planStale: false, vaultHasDocs: false)),
          ],
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildTheme(m.value.$1),
              locale: const Locale('nl', 'NL'),
              supportedLocales: const [Locale('nl', 'NL')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (c, child) => m.value.$2 == null
                  ? child!
                  : ColorFiltered(colorFilter: ColorFilter.matrix(m.value.$2!), child: child!),
              home: screen.value,
            ),
          ),
        ));
        await t.pumpAndSettle();
        await t.runAsync(() async {
          final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final img = await b.toImage(pixelRatio: 1);
          final d = await img.toByteData(format: ui.ImageByteFormat.png);
          Directory(dir).createSync(recursive: true);
          File('$dir/${screen.key}_${m.key}.png').writeAsBytesSync(d!.buffer.asUint8List());
        });
      });
    }
  }
}
