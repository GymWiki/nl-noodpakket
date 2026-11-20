import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../tool/screenshots/png_meta.dart';
import '../tool/screenshots/validate.dart';

/// Minimale PNG-bytes met alleen signatuur + IHDR + IDAT + IEND; genoeg voor [parseInfo] (leest alleen de header).
/// colorType: 2 = RGB (24-bit), 6 = RGBA (met alfa).
Uint8List png(int w, int h, {int colorType = 2}) {
  final b = BytesBuilder();
  void chunk(String type, List<int> data) {
    final len = ByteData(4)..setUint32(0, data.length);
    b.add(len.buffer.asUint8List());
    b.add(type.codeUnits);
    b.add(data);
    b.add([0, 0, 0, 0]); // crc wordt niet gelezen
  }

  b.add([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  final ihdr = ByteData(13)
    ..setUint32(0, w)
    ..setUint32(4, h)
    ..setUint8(8, 8)
    ..setUint8(9, colorType);
  chunk('IHDR', ihdr.buffer.asUint8List());
  chunk('IDAT', [0]);
  chunk('IEND', []);
  return b.toBytes();
}

List<String> check(Spec s, int w, int h, {int colorType = 2}) => imageProblems(s, parseInfo(png(w, h, colorType: colorType))!, 'x.png');

final cfg = jsonDecode(File('tool/screenshots/store_sizes.json').readAsStringSync()) as Map<String, dynamic>;
Spec spec(String dirEnd, {bool onlyEnabled = true}) => [
      ...specsFromConfig(cfg, 'appstore', onlyEnabled: onlyEnabled),
      ...specsFromConfig(cfg, 'play', onlyEnabled: onlyEnabled),
    ].firstWhere((s) => s.dir.endsWith(dirEnd));

/// Een echte PNG-metadata-keten (met CRC's) voor de strenge App Store-controle.
Uint8List strictPng({int colorType = 2, bool srgb = true, int? dpi = 72}) {
  var b = png(1206, 2622, colorType: colorType);
  b = Uint8List.fromList(b);
  if (srgb || dpi != null) {
    final x = withSrgbAndDpi(b, dpi: dpi ?? 72);
    return dpi == null || !srgb ? _strip(x, srgb: srgb, dpi: dpi) : x;
  }
  return b;
}

Uint8List _strip(Uint8List b, {required bool srgb, required int? dpi}) {
  // Haalt chunks weg door de bytes opnieuw op te bouwen zonder die chunk.
  final d = ByteData.sublistView(b);
  final out = BytesBuilder()..add(b.sublist(0, 33));
  for (var o = 33; o + 8 <= b.length;) {
    final len = d.getUint32(o);
    final type = String.fromCharCodes(b.sublist(o + 4, o + 8));
    final end = o + 12 + len;
    if (!((type == 'sRGB' && !srgb) || (type == 'pHYs' && dpi == null))) out.add(b.sublist(o, end));
    o = end;
  }
  return out.toBytes();
}

void main() {
  final appStoreIphone = spec('iphone-6.3'), appStoreIpad = spec('ipad-13'), playPhone = spec('play/phone');
  final iphone61 = spec('iphone-6.1');

  group('App Store iPhone 6.3" (primair)', () {
    test('exact 1206x2622 slaagt (geen 2:1-regel)', () => expect(check(appStoreIphone, 1206, 2622), isEmpty));
    test('de oude maat ca. 1186x2576 en 1320x2868 falen', () {
      expect(check(appStoreIphone, 1186, 2576), isNotEmpty);
      expect(check(appStoreIphone, 1320, 2868), isNotEmpty);
    });
    test('de maat van de 6.1-set (1179x2556) faalt hier: exact per map', () => expect(check(appStoreIphone, 1179, 2556), isNotEmpty));
    test('liggend 2622x1206 faalt (de set is staand)', () => expect(check(appStoreIphone, 2622, 1206), isNotEmpty));
    test('PNG met alfa faalt', () => expect(check(appStoreIphone, 1206, 2622, colorType: 6), anyElement(contains('alfa'))));
  });

  group('App Store iPhone 6.1"', () {
    test('exact 1179x2556 slaagt', () => expect(check(iphone61, 1179, 2556), isEmpty));
    test('1206x2622 faalt hier', () => expect(check(iphone61, 1206, 2622), isNotEmpty));
  });

  group('App Store iPhone 6.9" (uitgeschakeld, configureerbaar)', () {
    test('staat in het configbestand maar is uit', () {
      expect(specsFromConfig(cfg, 'appstore').any((s) => s.dir.endsWith('iphone-6.9')), isFalse);
      final s = spec('iphone-6.9', onlyEnabled: false);
      expect(check(s, 1320, 2868), isEmpty);
      expect(check(s, 1260, 2736), isEmpty);
    });
  });

  group('App Store iPad 13"', () {
    test('2064x2752 en 2048x2732 slagen', () {
      expect(check(appStoreIpad, 2064, 2752), isEmpty);
      expect(check(appStoreIpad, 2048, 2732), isEmpty);
    });
    test('iPhone-formaat faalt', () => expect(check(appStoreIpad, 1320, 2868), isNotEmpty));
    test('PNG met alfa faalt', () => expect(check(appStoreIpad, 2064, 2752, colorType: 6), anyElement(contains('alfa'))));
  });

  group('Google Play telefoon', () {
    test('1080x1920 slaagt', () => expect(check(playPhone, 1080, 1920), isEmpty));
    test('1320x2868 faalt op de 2:1-regel', () => expect(check(playPhone, 1320, 2868), anyElement(contains('2x de korte zijde'))));
    test('1080x2400 faalt op de 2:1-regel', () => expect(check(playPhone, 1080, 2400), anyElement(contains('2x de korte zijde'))));
    test('exact 2:1 (1080x2160) slaagt', () => expect(check(playPhone, 1080, 2160), isEmpty));
    test('zijde onder 320 of boven 3840 faalt', () {
      expect(check(playPhone, 319, 600), isNotEmpty);
      expect(check(playPhone, 1080, 3841), isNotEmpty);
      expect(check(playPhone, 320, 640), isEmpty);
      expect(check(playPhone, 2160, 3840), isEmpty);
    });
    test('PNG met alfa faalt', () => expect(check(playPhone, 1080, 1920, colorType: 6), anyElement(contains('alfa'))));
  });

  group('PNG-eisen van de App Store (RGB, sRGB, 72 dpi)', () {
    test('met sRGB en 72 dpi slaagt', () => expect(pngProblems(strictPng(), 'x.png'), isEmpty));
    test('zonder sRGB faalt', () => expect(pngProblems(strictPng(srgb: false), 'x.png'), anyElement(contains('sRGB'))));
    test('zonder dpi-informatie faalt', () => expect(pngProblems(strictPng(dpi: null), 'x.png'), anyElement(contains('pHYs'))));
    test('144 dpi faalt', () => expect(pngProblems(strictPng(dpi: 144), 'x.png'), anyElement(contains('144'))));
    test('RGBA (alfa) faalt', () {
      final p = pngProblems(strictPng(colorType: 6), 'x.png');
      expect(p, anyElement(contains('alfa')));
      expect(p, anyElement(contains('8-bit RGB')));
    });
    test('geen PNG faalt', () => expect(pngProblems([0xff, 0xd8, 0xff, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 'x.jpg'), isNotEmpty));
    test('withSrgbAndDpi geeft geldige chunks (CRC) en 72 dpi', () {
      final m = readPngMeta(withSrgbAndDpi(png(10, 10)))!;
      expect(m.hasSrgb, isTrue);
      expect(m.dpiX, closeTo(72, 0.1));
      expect(crc32('IEND'.codeUnits), 0xAE426082); // bekende CRC van een lege IEND-chunk
    });
    test('volgorde en aantal staan vast in de config', () {
      expect(((cfg['png'] as Map)['volgorde'] as List).length, 8);
      expect(((cfg['png'] as Map)['dpi']), 72);
    });
  });

  test('parseInfo herkent alfa (colorType 6) en geen alfa (2)', () {
    expect(parseInfo(png(10, 10, colorType: 6))!.hasAlpha, isTrue);
    expect(parseInfo(png(10, 10))!.hasAlpha, isFalse);
  });
}
