import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mijnnoodpakket/features/kluis/data/vault_images.dart';
import 'package:mijnnoodpakket/features/kluis/ui/vault_share.dart';

void main() {
  testWidgets('watermerk: geeft een leesbare JPEG met dezelfde afmetingen, anders dan het origineel', (t) async {
    final im = img.Image(width: 400, height: 260);
    img.fill(im, color: img.ColorRgb8(255, 255, 255));
    final original = Uint8List.fromList(img.encodeJpg(im, quality: 90));

    final marked = await t.runAsync(() => applyWatermark(original, 'Huurovereenkomst 10-11-2026'));
    expect(marked, isNotNull);
    expect(sniffMime(marked!), 'image/jpeg');
    final out = img.decodeJpg(marked)!;
    expect(out.width, 400);
    expect(out.height, 260);
    // een witte afbeelding is niet meer egaal wit: er staat tekst op
    var nonWhite = 0;
    for (final p in out) {
      if (p.r < 240 || p.g < 240 || p.b < 240) nonWhite++;
    }
    expect(nonWhite, greaterThan(200));
    final originalDecoded = img.decodeJpg(original)!;
    var origNonWhite = 0;
    for (final p in originalDecoded) {
      if (p.r < 240) origNonWhite++;
    }
    expect(origNonWhite, 0);
  });

  test('afbeeldingen: bestandstype wordt aan de inhoud herkend, niet aan de extensie', () {
    expect(sniffMime(Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D])), 'application/pdf');
    expect(sniffMime(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])), 'image/jpeg');
    expect(sniffMime(Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])), 'image/png');
    expect(sniffMime(Uint8List.fromList([0, 0, 0, 24, 0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63])), 'image/heic');
    expect(sniffMime(Uint8List.fromList([1, 2, 3])), isNull);
    expect(sniffMime(Uint8List(0)), isNull);
  });
}
