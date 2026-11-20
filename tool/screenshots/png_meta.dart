// PNG-metadata voor de store-screenshots: lezen (validate.dart) en schrijven (compose_test.dart).
// Zuiver Dart zonder Flutter, zodat beide er gebruik van kunnen maken.
//
// App Store Connect wil RGB zonder alfa. Wij leggen daarnaast vast: sRGB (een sRGB-chunk) en 72 dpi (pHYs, 2835 px per meter).
import 'dart:typed_data';

/// 72 dpi in pixels per meter (72 / 0,0254 = 2834,6; afgerond 2835).
const pixelsPerMeter72dpi = 2835;

final _crcTable = () {
  final t = List<int>.filled(256, 0);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    t[n] = c;
  }
  return t;
}();

int crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

Uint8List _chunk(String type, List<int> data) {
  final body = <int>[...type.codeUnits, ...data];
  final out = ByteData(12 + data.length);
  out.setUint32(0, data.length);
  for (var i = 0; i < body.length; i++) {
    out.setUint8(4 + i, body[i]);
  }
  out.setUint32(8 + data.length, crc32(body));
  return out.buffer.asUint8List();
}

class PngMeta {
  const PngMeta({
    required this.width,
    required this.height,
    required this.bitDepth,
    required this.colorType,
    required this.hasTransparency,
    required this.hasSrgb,
    required this.dpiX,
    required this.dpiY,
    required this.bytes,
  });
  final int width, height, bitDepth, colorType, bytes;

  /// Alfakanaal (kleurtype 4 of 6) of een tRNS-chunk.
  final bool hasTransparency;

  /// sRGB-chunk, of een iCCP-profiel waarvan de naam "sRGB" bevat.
  final bool hasSrgb;

  /// Dichtheid in dpi; null als er geen pHYs-chunk is of die niet in meters is.
  final double? dpiX, dpiY;

  /// Kleurtype 2 = RGB (24-bit bij 8 bit per kanaal).
  bool get isRgb8 => colorType == 2 && bitDepth == 8;
}

/// Leest de metadata; null als [b] geen PNG is.
PngMeta? readPngMeta(List<int> b) {
  if (b.length < 33 || b[0] != 0x89 || b[1] != 0x50 || b[2] != 0x4e || b[3] != 0x47) return null;
  final d = ByteData.sublistView(Uint8List.fromList(b));
  final w = d.getUint32(16), h = d.getUint32(20), depth = b[24], colorType = b[25];
  var trns = false, srgb = false;
  double? dx, dy;
  for (var o = 33; o + 8 <= b.length;) {
    final len = d.getUint32(o);
    final type = String.fromCharCodes(b.sublist(o + 4, o + 8));
    if (type == 'tRNS') trns = true;
    if (type == 'sRGB') srgb = true;
    if (type == 'iCCP') {
      final end = o + 8 + len > b.length ? b.length : o + 8 + len;
      if (String.fromCharCodes(b.sublist(o + 8, end).takeWhile((x) => x != 0)).contains('sRGB')) srgb = true;
    }
    if (type == 'pHYs' && len == 9 && d.getUint8(o + 16) == 1) {
      dx = d.getUint32(o + 8) * 0.0254;
      dy = d.getUint32(o + 12) * 0.0254;
    }
    if (type == 'IDAT' || type == 'IEND') break;
    o += 12 + len;
  }
  return PngMeta(
    width: w,
    height: h,
    bitDepth: depth,
    colorType: colorType,
    hasTransparency: colorType == 4 || colorType == 6 || trns,
    hasSrgb: srgb,
    dpiX: dx,
    dpiY: dy,
    bytes: b.length,
  );
}

/// Zet een sRGB-chunk (waarneming "perceptual") en een pHYs-chunk ([dpi]) direct na de IHDR en haalt bestaande
/// sRGB-, gAMA-, cHRM-, iCCP- en pHYs-chunks weg, zodat de uitvoer eenduidig is.
Uint8List withSrgbAndDpi(List<int> png, {int dpi = 72}) {
  final d = ByteData.sublistView(Uint8List.fromList(png));
  final ppm = (dpi / 0.0254).round();
  final phys = ByteData(9)
    ..setUint32(0, ppm)
    ..setUint32(4, ppm)
    ..setUint8(8, 1);
  final out = BytesBuilder()..add(png.sublist(0, 33)); // handtekening + IHDR (8 + 25)
  out.add(_chunk('sRGB', [0]));
  out.add(_chunk('pHYs', phys.buffer.asUint8List()));
  for (var o = 33; o + 8 <= png.length;) {
    final len = d.getUint32(o);
    final type = String.fromCharCodes(png.sublist(o + 4, o + 8));
    final end = o + 12 + len;
    if (!const {'sRGB', 'gAMA', 'cHRM', 'iCCP', 'pHYs'}.contains(type)) out.add(png.sublist(o, end));
    o = end;
  }
  return out.toBytes();
}
