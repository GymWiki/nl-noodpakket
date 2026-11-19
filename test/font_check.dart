import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, FontLoader;

/// Controle dat een lettertype echt gerenderd wordt. Een lettertype dat niet geladen is, valt stil terug op een ander
/// lettertype of op lege vierkantjes. Hier renderen we dezelfde tekst met het gevraagde lettertype én met een
/// lettertype dat niet bestaat. Zijn de pixels gelijk, dan is het gevraagde lettertype niet geladen.
///
/// In `flutter test` moet de aanroep in `tester.runAsync` staan (er wordt echt gerenderd). In een integratietest op
/// een toestel of simulator kan hij direct worden aangeroepen.
const _missingFamily = 'NoodpakketBestaatNiet';

Future<List<int>> _pixels(String text, String family) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 96, 96), Paint()..color = Colors.white);
  final painter = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontFamily: family, fontSize: 48, color: Colors.black)),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, const Offset(8, 8));
  final image = await recorder.endRecording().toImage(96, 96);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Is [text] te zien in [family], en anders dan het terugvallettertype, en niet leeg?
Future<bool> fontRenders(String family, String text) async {
  final mine = await _pixels(text, family);
  final fallback = await _pixels(text, _missingFamily);
  final blank = await _pixels(' ', family);
  final differs = !_same(mine, fallback);
  final hasInk = !_same(mine, blank);
  return differs && hasInk;
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Het lettertype voor de iconen van de app (Material Icons).
const iconFontFamily = 'MaterialIcons';

/// De app-lettertypen die in de paywall en screenshots zichtbaar zijn.
const appTextFontFamily = 'Roboto';

/// Een icoon waarvan we weten dat het in Material Icons bestaat.
String get probeIconGlyph => String.fromCharCode(Icons.close_rounded.codePoint);

/// Geeft de problemen terug; een lege lijst betekent dat alles echt gerenderd wordt.
Future<List<String>> fontProblems() async => [
      if (!await fontRenders(iconFontFamily, probeIconGlyph))
        'Material Icons-lettertype niet geladen: iconen worden lege vierkantjes',
      if (!await fontRenders(appTextFontFamily, 'Rg'))
        'App-lettertype $appTextFontFamily niet geladen: tekst valt terug op een ander lettertype',
    ];

/// Elk [Icon] in de widgetboom moet het Material Icons-lettertype gebruiken (geen lege vierkantjes door een
/// verkeerd of ontbrekend lettertype). Geeft de afwijkingen terug.
List<String> iconTreeProblems(Iterable<Icon> icons) {
  final out = <String>[];
  var n = 0;
  for (final i in icons) {
    n++;
    final data = i.icon;
    if (data == null) {
      out.add('Icon zonder glyph');
    } else if (data.fontFamily != iconFontFamily) {
      out.add('Icon ${data.codePoint.toRadixString(16)} gebruikt lettertype ${data.fontFamily}, verwacht $iconFontFamily');
    }
  }
  if (n == 0) out.add('geen iconen gevonden in de widgetboom');
  return out;
}

/// Laadt lettertypebestanden onder [family] (voor tests en dry-runs zonder toestel; op een toestel zitten ze in de app).
Future<void> loadFont(String family, List<File> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
  }
  await loader.load();
}

/// Zoekt het Material Icons-bestand van de Flutter SDK.
File? materialIconsFile() {
  final roots = <String>[
    ?Platform.environment['FLUTTER_ROOT'],
    // Vanaf het testproces: <sdk>/bin/cache/artifacts/engine/<platform>/flutter_tester
    for (var d = File(Platform.resolvedExecutable).parent; d.path != d.parent.path; d = d.parent) d.path,
  ];
  for (final r in roots) {
    for (final n in ['MaterialIcons-Regular.otf', 'materialicons-regular.otf']) {
      final f = File('$r/bin/cache/artifacts/material_fonts/$n');
      if (f.existsSync()) return f;
    }
  }
  return null;
}

/// Laadt Material Icons en Roboto uit de SDK en de assets. Alleen voor `flutter test`-runs; niet nodig op een toestel.
Future<void> loadAppFontsForTests() async {
  final icons = materialIconsFile();
  if (icons != null) await loadFont(iconFontFamily, [icons]);
  await loadFont(appTextFontFamily, [File('assets/fonts/Roboto-Regular.ttf'), File('assets/fonts/Roboto-Bold.ttf')]);
}
