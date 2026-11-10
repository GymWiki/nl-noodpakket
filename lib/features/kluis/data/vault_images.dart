import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Resultaat van het verwerken van een afbeelding.
class ProcessedImage {
  const ProcessedImage({required this.main, required this.thumb, required this.mime});
  final Uint8List main, thumb;
  final String mime;
}

const maxSide = 2400; // leesbaar voor documenten, toch beperkte bestandsgrootte
const thumbSide = 320;
const mainQuality = 85;
const thumbQuality = 70;

/// Comprimeert een afbeelding (JPEG/PNG) en maakt een miniatuur. Leesbaarheid
/// gaat voor bestandsgrootte: lange zijde maximaal 2400 px, JPEG-kwaliteit 85.
/// Geeft null terug als het formaat niet te decoderen is (bijv. HEIC op Android).
Future<ProcessedImage?> processImage(Uint8List bytes) =>
    Isolate.run(() => processImageSync(bytes));

ProcessedImage? processImageSync(Uint8List bytes) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    return null;
  }
  if (decoded == null) return null;
  var im = img.bakeOrientation(decoded);
  if (im.hasAlpha) {
    // Plat slaan op wit, anders wordt transparantie zwart in een JPEG.
    final bg = img.Image(width: im.width, height: im.height, numChannels: 3);
    img.fill(bg, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(bg, im);
    im = bg;
  }
  final main = _fit(im, maxSide);
  final thumb = _fit(im, thumbSide);
  return ProcessedImage(
    main: Uint8List.fromList(img.encodeJpg(main, quality: mainQuality)),
    thumb: Uint8List.fromList(img.encodeJpg(thumb, quality: thumbQuality)),
    mime: 'image/jpeg',
  );
}

img.Image _fit(img.Image im, int side) {
  final longest = im.width > im.height ? im.width : im.height;
  if (longest <= side) return im;
  return im.width >= im.height
      ? img.copyResize(im, width: side, interpolation: img.Interpolation.average)
      : img.copyResize(im, height: side, interpolation: img.Interpolation.average);
}

/// Herkent het bestandstype aan de eerste bytes (niet aan de extensie).
String? sniffMime(Uint8List b) {
  if (b.length >= 4 && b[0] == 0x25 && b[1] == 0x50 && b[2] == 0x44 && b[3] == 0x46) {
    return 'application/pdf';
  }
  if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) return 'image/jpeg';
  if (b.length >= 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) {
    return 'image/png';
  }
  if (b.length >= 12 &&
      String.fromCharCodes(b.sublist(4, 8)) == 'ftyp' &&
      ['heic', 'heix', 'hevc', 'mif1', 'heif'].contains(String.fromCharCodes(b.sublist(8, 12)))) {
    return 'image/heic';
  }
  return null;
}
