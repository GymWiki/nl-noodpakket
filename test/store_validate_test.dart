import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

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

void main() {
  group('App Store iPhone 6.9"', () {
    test('1320x2868 slaagt (geen 2:1-regel)', () => expect(check(appStoreIphone, 1320, 2868), isEmpty));
    test('1290x2796 en 1260x2736 slagen', () {
      expect(check(appStoreIphone, 1290, 2796), isEmpty);
      expect(check(appStoreIphone, 1260, 2736), isEmpty);
    });
    test('1080x1920 faalt (geen toegestaan formaat)', () => expect(check(appStoreIphone, 1080, 1920), isNotEmpty));
    test('liggend 2868x1320 faalt (alleen portret)', () => expect(check(appStoreIphone, 2868, 1320), isNotEmpty));
    test('PNG met alfa faalt', () => expect(check(appStoreIphone, 1320, 2868, colorType: 6), anyElement(contains('alfa'))));
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

  test('parseInfo herkent alfa (colorType 6) en geen alfa (2)', () {
    expect(parseInfo(png(10, 10, colorType: 6))!.hasAlpha, isTrue);
    expect(parseInfo(png(10, 10))!.hasAlpha, isFalse);
  });
}
