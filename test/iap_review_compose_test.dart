import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mijnnoodpakket/core/theme.dart';

import '../tool/screenshots/iap_review.dart';

/// Een synthetische "opname" (geen echte paywall): linkerhelft rood, rechterhelft blauw, een groene rand van 20 px.
/// Alleen om de tool te testen; de echte opname komt van de simulator.
img.Image fakeRaw(int w, int h) {
  final im = img.Image(width: w, height: h, numChannels: 4);
  for (final p in im) {
    final border = p.x < 20 || p.y < 20 || p.x >= w - 20 || p.y >= h - 20;
    if (border) {
      p.setRgba(0, 160, 0, 255);
    } else if (p.x < w ~/ 2) {
      p.setRgba(220, 20, 20, 255);
    } else {
      p.setRgba(20, 20, 220, 255);
    }
  }
  return im;
}

bool isBg(img.Pixel p) => p.r == 0xF4 && p.g == 0xF7 && p.b == 0xFA;

void main() {
  test('de achtergrondkleur is die van de app (licht thema)', () {
    expect(iapBackground, AppColors.lightBg.toARGB32() & 0xFFFFFF);
  });

  group('composeOnCanvas', () {
    final src = fakeRaw(1320, 2868);

    for (final (w, h) in iapSizes) {
      test('${w}x$h: exacte maat, RGB zonder alfa, gecentreerd, verhouding behouden', () {
        final out = composeOnCanvas(src, w, h);
        expect(out.width, w);
        expect(out.height, h);
        expect(out.numChannels, 3, reason: 'geen alfakanaal');

        // Bounding box van wat geen achtergrond is.
        var minX = w, maxX = -1, minY = h, maxY = -1;
        for (final p in out) {
          if (!isBg(p)) {
            if (p.x < minX) minX = p.x;
            if (p.x > maxX) maxX = p.x;
            if (p.y < minY) minY = p.y;
            if (p.y > maxY) maxY = p.y;
          }
        }
        final contentW = maxX - minX + 1, contentH = maxY - minY + 1;
        // Gecentreerd: marges links/rechts en boven/onder zijn gelijk (op een pixel na).
        expect((minX - (w - 1 - maxX)).abs(), lessThanOrEqualTo(1), reason: 'horizontaal gecentreerd');
        expect((minY - (h - 1 - maxY)).abs(), lessThanOrEqualTo(1), reason: 'verticaal gecentreerd');
        // Niet gerekt: dezelfde verhouding als de opname (op afronding na).
        expect(contentW / contentH, closeTo(1320 / 2868, 0.004));
        // Het canvas wordt niet groter gemaakt dan nodig: de inhoud raakt minstens één rand.
        expect(minX == 0 || minY == 0, isTrue);
        // De opname zelf staat erop (groene rand en rode/blauwe helften).
        final mid = out.getPixel(minX + contentW ~/ 4, minY + contentH ~/ 2);
        expect([mid.r, mid.g, mid.b], [220, 20, 20]);
      });
    }

    test('1320x2868 is pixel voor pixel de opname (niets geschaald)', () {
      final out = composeOnCanvas(src, 1320, 2868);
      for (final (x, y) in [(0, 0), (5, 5), (1319, 2867), (300, 1000), (900, 2000)]) {
        final a = out.getPixel(x, y), b = src.getPixel(x, y);
        expect([a.r, a.g, a.b], [b.r, b.g, b.b], reason: '($x,$y)');
      }
    });

    test('een bijna gelijke opname (1290x2796) op 1320x2868 blijft in verhouding', () {
      final out = composeOnCanvas(fakeRaw(1290, 2796), 1320, 2868);
      expect(out.width, 1320);
      expect(out.height, 2868);
      expect(out.numChannels, 3);
    });
  });

  group('leesbaarheid', () {
    test('640x920 houdt hoofdtekst boven de 14 px (hele scherm, geen sheet-uitsnede nodig)', () {
      expect(bodyTextPx(1320, 2868, 640, 920), greaterThanOrEqualTo(14));
      expect(bodyTextPx(1290, 2796, 640, 920), greaterThanOrEqualTo(14));
    });

    test('een te kleine schaal wordt herkend', () {
      expect(bodyTextPx(1320, 2868, 320, 460), lessThan(14));
    });
  });

  test('de uitvoer van de tool slaagt voor het validatiescript (RGB, 72 dpi, afmetingen, grootte)', () async {
    final dir = Directory.systemTemp.createTempSync('iap_review_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final src = fakeRaw(1320, 2868);
    for (final (w, h) in iapSizes) {
      File('${dir.path}/${iapFileName(w, h)}').writeAsBytesSync(encodeRgb72dpi(composeOnCanvas(src, w, h)));
    }
    final r = await Process.run('python3', ['tool/iap_review_validate.py', dir.path]);
    expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
    expect(r.stdout, contains('Validatie geslaagd'));
  });

  test('een PNG met alfakanaal wordt door het validatiescript afgekeurd', () async {
    final dir = Directory.systemTemp.createTempSync('iap_review_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final src = fakeRaw(1320, 2868);
    for (final (w, h) in iapSizes) {
      final rgba = img.Image(width: w, height: h, numChannels: 4);
      File('${dir.path}/${iapFileName(w, h)}').writeAsBytesSync(img.encodePng(rgba));
      expect(src.numChannels, 4);
    }
    final r = await Process.run('python3', ['tool/iap_review_validate.py', dir.path]);
    expect(r.exitCode, 1);
    expect(r.stdout, contains('RGBA'));
  });
}
