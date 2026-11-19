// Maakt uit één echte opname van de paywall (integration_test/iap_review_test.dart) de vier bestanden voor het veld
// "Screenshot for review" van de in-app aankoop `pro_unlock` in App Store Connect.
//
//   dart run tool/screenshots/iap_review.dart
//   dart run tool/screenshots/iap_review.dart --in=store/raw/iap-review/pro_unlock_review.png --out=store/out/iap-review
//
// Per maat: de opname wordt zonder te rekken geschaald (verhouding blijft), gecentreerd op een canvas in de effen
// achtergrondkleur van de app (geen transparantie), zonder extra tekst of apparaatframe. Uitvoer: PNG, 8-bit RGB zonder
// alfakanaal, 72 dpi (pHYs). Daarna controleert tool/iap_review_validate.py de bestanden.
//
// Leesbaarheid: de opname komt van een 3x-scherm (iPhone Pro Max, 1320 px breed = 440 pt). Hoofdtekst is 16 pt = 48 px
// op de opname. Na schalen moet hij minstens 14 px zijn; anders stopt het script met een melding (gebruik dan alleen de sheet).
import 'dart:io';

import 'package:image/image.dart' as img;

/// Effen achtergrondkleur van de app (licht thema, `AppColors.lightBg` in lib/core/theme.dart; een test bewaakt dat).
const iapBackground = 0xF4F7FA;

/// De maten die App Store Connect kan vragen, in de volgorde waarin je ze probeert.
const iapSizes = <(int, int)>[(640, 920), (1242, 2208), (1290, 2796), (1320, 2868)];

const rawFileName = 'pro_unlock_review.png';

String iapFileName(int w, int h) => 'pro_unlock_${w}x$h.png';

/// 72 dpi in pixels per meter (72 / 0.0254 = 2834,6, afgerond 2835).
const pixelsPerMeter72dpi = 2835;

/// Zet [src] zonder te rekken op een [w] x [h] canvas in effen [bg] (0xRRGGBB), gecentreerd. Uitvoer is RGB zonder alfa.
img.Image composeOnCanvas(img.Image src, int w, int h, {int bg = iapBackground}) {
  final scale = [w / src.width, h / src.height].reduce((a, b) => a < b ? a : b);
  final newW = (src.width * scale).round().clamp(1, w);
  final newH = (src.height * scale).round().clamp(1, h);
  final resized = (newW == src.width && newH == src.height)
      ? src
      : img.copyResize(
          src,
          width: newW,
          height: newH,
          // Verkleinen: gemiddelde (scherpe tekst zonder moiré); vergroten (hooguit een paar procent): kubisch.
          interpolation: scale < 1 ? img.Interpolation.average : img.Interpolation.cubic,
        );
  final canvas = img.Image(width: w, height: h, numChannels: 3);
  img.fill(canvas, color: img.ColorRgb8((bg >> 16) & 0xFF, (bg >> 8) & 0xFF, bg & 0xFF));
  img.compositeImage(canvas, resized, dstX: (w - newW) ~/ 2, dstY: (h - newH) ~/ 2);
  return canvas;
}

List<int> encodeRgb72dpi(img.Image canvas) => img.PngEncoder(
      pixelDimensions: const img.PngPhysicalPixelDimensions(
        xPxPerUnit: pixelsPerMeter72dpi,
        yPxPerUnit: pixelsPerMeter72dpi,
        unitSpecifier: img.PngPhysicalPixelDimensions.unitMeter,
      ),
    ).encode(canvas);

/// Geschatte hoogte van hoofdtekst (16 pt) in pixels na schalen, bij [dpr] pixels per punt op de opname.
double bodyTextPx(int srcW, int srcH, int w, int h, {double dpr = 3, double bodyPt = 16}) {
  final scale = [w / srcW, h / srcH].reduce((a, b) => a < b ? a : b);
  return bodyPt * dpr * scale;
}

String? _arg(List<String> args, String name) {
  for (final a in args) {
    if (a.startsWith('--$name=')) return a.substring(name.length + 3);
  }
  return null;
}

void main(List<String> args) {
  final input = _arg(args, 'in') ?? 'store/raw/iap-review/$rawFileName';
  final outDir = _arg(args, 'out') ?? 'store/out/iap-review';
  final dpr = double.tryParse(_arg(args, 'dpr') ?? '') ?? 3;
  final minBodyPx = double.tryParse(_arg(args, 'min-body-px') ?? '') ?? 14;

  final file = File(input);
  if (!file.existsSync()) {
    stderr.writeln('FOUT: opname ontbreekt: $input (maak hem met integration_test/iap_review_test.dart)');
    exit(1);
  }
  final src = img.decodePng(file.readAsBytesSync());
  if (src == null) {
    stderr.writeln('FOUT: $input is geen geldige PNG');
    exit(1);
  }
  stdout.writeln('Opname: $input (${src.width}x${src.height})');

  var failed = false;
  Directory(outDir).createSync(recursive: true);
  for (final (w, h) in iapSizes) {
    final px = bodyTextPx(src.width, src.height, w, h, dpr: dpr);
    final ok = px >= minBodyPx;
    stdout.writeln('  ${w}x$h: hoofdtekst na schalen ca. ${px.toStringAsFixed(1)} px ${ok ? '(leesbaar)' : '(TE KLEIN)'}');
    if (!ok) {
      stderr.writeln('FOUT: ${w}x$h: hoofdtekst wordt ${px.toStringAsFixed(1)} px, minimaal $minBodyPx. '
          'Gebruik voor deze maat alleen de inhoud van de sheet in plaats van het hele scherm en meld dat.');
      failed = true;
      continue;
    }
    final out = File('$outDir/${iapFileName(w, h)}')..writeAsBytesSync(encodeRgb72dpi(composeOnCanvas(src, w, h)));
    stdout.writeln('  -> ${out.path} (${(out.lengthSync() / 1024).toStringAsFixed(0)} KB)');
  }
  if (failed) exit(1);
}
