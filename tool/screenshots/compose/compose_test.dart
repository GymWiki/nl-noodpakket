// Marketinglaag voor de store-screenshots. Draait als `flutter test`, zodat tekst met het gebundelde
// Roboto-lettertype (met Nederlandse tekens) wordt getekend; het eindresultaat wordt met het
// `image`-pakket als 24-bit PNG zonder alpha opgeslagen.
//
// Zonder omgevingsvariabelen doet dit bestand niets. Voorbeelden:
//   COMPOSE_RAW=store/raw/android COMPOSE_OUT=store/out/play/phone COMPOSE_SIZE=1080x1920 \
//     flutter test tool/screenshots/compose/compose_test.dart
//   COMPOSE_MODE=feature COMPOSE_OUT=store/out/play/feature-graphic flutter test tool/screenshots/compose/compose_test.dart
//   COMPOSE_MODE=icon COMPOSE_OUT=store/out/play/icon flutter test tool/screenshots/compose/compose_test.dart
//
// COMPOSE_STYLE=play|apple regelt het aandeel van het bijschrift. Google Play staat tekst-overlays toe tot
// maximaal 20% van het beeld; de bijschriftband blijft daar ruim onder.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Color _hex(String h) => Color(0xFF000000 | int.parse(h, radix: 16));

Future<ui.Image> _load(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  return (await codec.getNextFrame()).image;
}

/// RGBA uit dart:ui naar een RGB-image (zonder alpha) en opslaan als PNG.
Future<void> _savePng(ui.Image image, String path) async {
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final rgb = img.Image(width: image.width, height: image.height, numChannels: 3);
  final b = data.buffer.asUint8List();
  var i = 0;
  for (final p in rgb) {
    p
      ..r = b[i]
      ..g = b[i + 1]
      ..b = b[i + 2];
    i += 4;
  }
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(rgb));
  stdout.writeln('geschreven: $path (${image.width}x${image.height})');
}

void _text(Canvas c, String text, Offset topLeft, double maxWidth,
    {required double size, required Color color, FontWeight weight = FontWeight.w700, TextAlign align = TextAlign.center, int maxLines = 2}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: weight, color: color, height: 1.18)),
    textAlign: align,
    textDirection: TextDirection.ltr,
    maxLines: maxLines,
  )..layout(maxWidth: maxWidth);
  final dx = align == TextAlign.left ? topLeft.dx : topLeft.dx + (maxWidth - tp.width) / 2;
  tp.paint(c, Offset(dx, topLeft.dy));
}

double _textHeight(String text, double maxWidth, double size) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: FontWeight.w700, height: 1.18)),
    textDirection: TextDirection.ltr,
    maxLines: 2,
  )..layout(maxWidth: maxWidth);
  return tp.height;
}

void main() {
  final env = Platform.environment;
  final mode = env['COMPOSE_MODE'] ?? 'screens';
  final out = env['COMPOSE_OUT'];

  setUpAll(() async {
    final l = FontLoader('Roboto');
    for (final f in ['Regular', 'Bold']) {
      l.addFont(Future.value(ByteData.view(File('assets/fonts/Roboto-$f.ttf').readAsBytesSync().buffer)));
    }
    await l.load();
  });

  testWidgets('compose', (t) async {
    if (out == null) return; // niets doen zonder opdracht
    final cfg = jsonDecode(File(env['COMPOSE_CAPTIONS'] ?? 'tool/screenshots/captions.json').readAsStringSync()) as Map<String, dynamic>;
    final colors = (cfg['kleuren'] as Map).cast<String, String>();
    final bg = _hex(colors['achtergrond']!), fg = _hex(colors['tekst']!), accent = _hex(colors['accent']!);

    await t.runAsync(() async {
      if (mode == 'icon') {
        // Google Play-icoon: 512x512, 32-bit PNG met alfakanaal, maximaal 1024 KB.
        final src = img.decodePng(File('assets/icon/icon.png').readAsBytesSync())!;
        final rgba = img.Image(width: 512, height: 512, numChannels: 4);
        img.compositeImage(rgba, img.copyResize(src, width: 512, height: 512, interpolation: img.Interpolation.cubic));
        File('$out/icon-512.png')
          ..parent.createSync(recursive: true)
          ..writeAsBytesSync(img.encodePng(rgba));
        stdout.writeln('geschreven: $out/icon-512.png (512x512, RGBA)');
        return;
      }

      if (mode == 'feature') {
        const w = 1024, h = 500;
        final rec = ui.PictureRecorder();
        final c = Canvas(rec, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
        c.drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), Paint()..color = bg);
        // Icoon links, tekst rechts.
        final icon = await _load('assets/icon/icon.png');
        const s = 240.0;
        final dst = RRect.fromRectAndRadius(const Rect.fromLTWH(96, (h - s) / 2, s, s), const Radius.circular(54));
        c.save();
        c.clipRRect(dst);
        c.drawImageRect(icon, Rect.fromLTWH(0, 0, icon.width.toDouble(), icon.height.toDouble()), dst.outerRect, Paint()..filterQuality = FilterQuality.high);
        c.restore();
        final f = cfg['featureGraphic'] as Map<String, dynamic>;
        const tx = 96 + s + 56;
        const tw = w - tx - 64.0;
        _text(c, f['naam'] as String, const Offset(tx, 150), tw, size: 64, color: accent, align: TextAlign.left, maxLines: 1);
        final tp = TextPainter(
          text: TextSpan(text: f['slogan'] as String, style: TextStyle(fontFamily: 'Roboto', fontSize: 40, fontWeight: FontWeight.w400, color: fg, height: 1.25)),
          textDirection: TextDirection.ltr,
          maxLines: 3,
        )..layout(maxWidth: tw);
        tp.paint(c, const Offset(tx, 150 + 84));
        await _savePng(await rec.endRecording().toImage(w, h), '$out/feature-graphic.png');
        return;
      }

      // --- Screenshots met bijschrift ------------------------------------------------------------
      final raw = env['COMPOSE_RAW']!;
      final size = (env['COMPOSE_SIZE'] ?? '1080x1920').split('x').map(int.parse).toList();
      final w = size[0], h = size[1];
      final style = env['COMPOSE_STYLE'] ?? 'play';
      final bandFraction = style == 'play' ? 0.165 : 0.17; // Google Play: tekst-overlay ruim onder 20% van het beeld
      final band = h * bandFraction;
      final margin = h * 0.035;
      final files = Directory(raw).listSync().whereType<File>().where((f) => f.path.endsWith('.png')).toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      var made = 0;
      for (final f in files) {
        final name = f.uri.pathSegments.last;
        final key = name.substring(0, 2);
        final caption = cfg[key];
        if (caption is! String || caption.trim().isEmpty) {
          stdout.writeln('overgeslagen (geen bijschrift): $name');
          continue;
        }
        final shot = await _load(f.path);
        final rec = ui.PictureRecorder();
        final c = Canvas(rec, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
        c.drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), Paint()..color = bg);

        // Bijschrift bovenaan, gecentreerd in de band; lettergrootte zo groot dat het in twee regels past.
        final tw = w * 0.86;
        var fs = w * 0.062;
        while (_textHeight(caption, tw, fs) > band * 0.72 && fs > 20) {
          fs -= 1;
        }
        final th = _textHeight(caption, tw, fs);
        _text(c, caption, Offset(w * 0.07, (band - th) / 2 + h * 0.012), tw, size: fs, color: fg);

        // Schermafbeelding eronder, afgeronde hoeken, zachte schaduw, geen apparaatframe.
        final availH = h - band - margin;
        final sc = math.min(availH / shot.height, (w * 0.9) / shot.width);
        final dw = shot.width * sc, dh = shot.height * sc;
        final dst = Rect.fromLTWH((w - dw) / 2, band, dw, dh);
        final r = RRect.fromRectAndRadius(dst, Radius.circular(w * 0.045));
        c.drawRRect(r.shift(Offset(0, h * 0.006)), Paint()..color = const Color(0x22000000)..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.012));
        c.save();
        c.clipRRect(r);
        c.drawImageRect(shot, Rect.fromLTWH(0, 0, shot.width.toDouble(), shot.height.toDouble()), dst, Paint()..filterQuality = FilterQuality.high);
        c.restore();
        c.drawRRect(r, Paint()..style = PaintingStyle.stroke..strokeWidth = math.max(2, w * 0.0025)..color = const Color(0x1A0F1B26));

        await _savePng(await rec.endRecording().toImage(w, h), '$out/${name.replaceAll('.png', '')}.png');
        made++;
      }
      stdout.writeln('klaar: $made screenshots met bijschrift in $out');
    });
  });
}
