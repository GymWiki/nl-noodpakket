// Valideert de store-uitvoer in store/out/ tegen de eisen van Google Play en de App Store.
//   dart run tool/screenshots/validate.dart            (controleert alle sets die bestaan; Play-telefoon is verplicht)
//   dart run tool/screenshots/validate.dart --only=ios,ipad --require-ios --require-ipad   (alleen de App Store-sets)
//   dart run tool/screenshots/validate.dart --only=ios --require-ios     (alle iPhone-sets uit store_sizes.json)
//
// De maten, mappen en regels per set staan in tool/screenshots/store_sizes.json (één bestand, ook voor compose).
// Controleert per bestand: afmetingen (exact een van de toegestane maten), PNG, 8-bit RGB (kleurtype 2), geen alfakanaal,
// sRGB (sRGB-chunk), 72 dpi (pHYs), bestandsgrootte, en per App Store-set precies 8 bestanden met de nummers 01 t/m 08.
// Faalt (exitcode 1) bij een afwijking.
//
// Regels per winkel (ze verschillen bewust):
//   Google Play (store/out/play/phone): 320 tot 3840 px per zijde, lange zijde hooguit 2x de korte (2:1), geen alfa,
//     JPEG of 24-bit PNG; bij voorkeur 1080x1920. Feature graphic exact 1024x500 zonder alfa. De 2:1-regel geldt ALLEEN hier.
//   App Store: exacte maten per set (zie store_sizes.json), geen verhoudingsregel, geen alfa.
//     iphone-6.3 exact 1206x2622; iphone-6.1 exact 1179x2556; ipad-13 2064x2752 of 2048x2732.
//
// Bronnen:
//   App Store Connect Help, "Screenshot specifications"
//     (developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/), opgehaald op
//     2026-11-20. De pagina noemt: "iPhone with Dynamic Island (medium display)" 1179x2556 en 1206x2622 (staand), 2556x1179 en
//     2622x1206 (liggend); "(large display)" 1260x2736, 1290x2796, 1320x2868; iPad 13": 2064x2752 en 2048x2732; png, jpg of
//     jpeg; "Images can't include alpha channels or transparencies"; 1 tot 10 screenshots per maat. De pagina noemt GEEN
//     kleurruimte, dpi of bestandsgrootte en toont geen wijzigingsdatum. De sRGB- en 72 dpi-eis en het aantal van precies 8
//     zijn onze eigen, strengere keuze (opdracht van de eigenaar). De samenvatting van de pagina kwam niet verbatim binnen.
//   Play Console Help, "Add preview assets" (support.google.com/googleplay/android-developer/answer/9866151):
//     NIET opgehaald (host geblokkeerd in de sandbox). De Play-regels komen uit de opdracht van de eigenaar en zijn niet door
//     ons tegen de pagina gecontroleerd. Controleer dit handmatig.
import 'dart:convert';
import 'dart:io';

import 'png_meta.dart';

class Spec {
  const Spec(
    this.name,
    this.dir, {
    this.sizes,
    this.minSide,
    this.maxSide,
    this.maxRatio,
    this.preferred,
    required this.min,
    required this.max,
    this.requireAll = true,
    this.strictPng = false,
  });
  final String name, dir;
  final List<List<int>>? sizes; // exact toegestane [breedte, hoogte]; null = bereik via minSide/maxSide
  final int? minSide, maxSide; // per zijde, in px
  final double? maxRatio; // lange zijde / korte zijde; alleen Google Play
  final List<int>? preferred; // gewenst formaat; afwijking is alleen een opmerking
  final int min, max;
  final bool requireAll;

  /// PNG verplicht, 8-bit RGB, sRGB en 72 dpi (App Store-sets).
  final bool strictPng;
}

/// Leest store_sizes.json en maakt de sets. [store] is "appstore" of "play".
List<Spec> specsFromConfig(Map<String, dynamic> cfg, String store, {bool onlyEnabled = true}) {
  final out = <Spec>[];
  for (final e in (cfg['sets'] as Map).entries) {
    final v = (e.value as Map).cast<String, dynamic>();
    if (v['store'] != store) continue;
    if (onlyEnabled && v['enabled'] != true) continue;
    final accept = [for (final z in (v['accept'] as List? ?? const [])) (z as List).cast<int>()];
    final size = (v['size'] as List).cast<int>();
    out.add(Spec(
      v['label'] as String? ?? e.key,
      v['out'] as String,
      sizes: accept.isEmpty ? null : accept,
      minSide: v['minSide'] as int?,
      maxSide: v['maxSide'] as int?,
      maxRatio: (v['maxRatio'] as num?)?.toDouble(),
      preferred: size,
      min: store == 'appstore' ? 8 : 2,
      max: store == 'appstore' ? 8 : 8,
      strictPng: store == 'appstore',
    ));
  }
  return out;
}

/// Afwijkingen van één afbeelding ten opzichte van de regels van [s]. Leeg = goed. Zuiver (geen I/O), dus testbaar.
List<String> imageProblems(Spec s, Info i, String name) {
  final out = <String>[];
  final sizes = s.sizes;
  if (sizes != null) {
    if (!sizes.any((z) => z[0] == i.width && z[1] == i.height)) {
      out.add('$name is ${i.width}x${i.height}, verwacht ${sizes.map((z) => '${z[0]}x${z[1]}').join(' of ')}');
    }
  } else {
    final lo = s.minSide ?? 0, hi = s.maxSide ?? 1 << 30;
    if (i.width < lo || i.height < lo || i.width > hi || i.height > hi) {
      out.add('$name is ${i.width}x${i.height}, elke zijde moet tussen $lo en $hi px liggen');
    }
  }
  final ratio = s.maxRatio;
  if (ratio != null) {
    final long = i.width > i.height ? i.width : i.height, short = i.width > i.height ? i.height : i.width;
    if (long > ratio * short) out.add('$name: lange zijde meer dan ${ratio.toStringAsFixed(0)}x de korte zijde (${i.width}x${i.height})');
  }
  if (i.hasAlpha) out.add('$name heeft een alfakanaal (transparantie niet toegestaan)');
  if (i.bytes > 8 * 1024 * 1024) out.add('$name is groter dan 8 MB');
  return out;
}

/// Extra eisen voor de App Store-sets: PNG, 8-bit RGB, sRGB, 72 dpi. [bytes] zijn de bestandsbytes. Zuiver, dus testbaar.
List<String> pngProblems(List<int> bytes, String name) {
  final m = readPngMeta(bytes);
  if (m == null) return ['$name is geen PNG (App Store-screenshots moeten PNG zijn)'];
  final out = <String>[];
  if (m.hasTransparency) out.add('$name heeft een alfakanaal of transparantie');
  if (!m.isRgb8) out.add('$name is geen 8-bit RGB (kleurtype ${m.colorType}, ${m.bitDepth} bit); verwacht kleurtype 2, 8 bit');
  if (!m.hasSrgb) out.add('$name heeft geen sRGB-kleurprofiel (sRGB-chunk ontbreekt)');
  final dx = m.dpiX, dy = m.dpiY;
  if (dx == null || dy == null) {
    out.add('$name heeft geen resolutie-informatie (pHYs); verwacht 72 dpi');
  } else if ((dx - 72).abs() > 0.5 || (dy - 72).abs() > 0.5) {
    out.add('$name is ${dx.toStringAsFixed(1)}x${dy.toStringAsFixed(1)} dpi, verwacht 72 dpi');
  }
  return out;
}

class Info {
  Info(this.format, this.width, this.height, this.hasAlpha, this.bytes);
  final String format;
  final int width, height, bytes;
  final bool hasAlpha;
}

Info? readInfo(File f) => parseInfo(f.readAsBytesSync());

Info? parseInfo(List<int> b) {
  final m = readPngMeta(b);
  if (m != null) return Info('PNG', m.width, m.height, m.hasTransparency, b.length);
  if (b.length > 4 && b[0] == 0xff && b[1] == 0xd8) {
    var o = 2;
    while (o + 9 < b.length) {
      if (b[o] != 0xff) {
        o++;
        continue;
      }
      final mk = b[o + 1];
      if (mk >= 0xc0 && mk <= 0xcf && mk != 0xc4 && mk != 0xc8 && mk != 0xcc) {
        final h = (b[o + 5] << 8) | b[o + 6], w = (b[o + 7] << 8) | b[o + 8];
        return Info('JPEG', w, h, false, b.length);
      }
      o += 2 + ((b[o + 2] << 8) | b[o + 3]);
    }
  }
  return null;
}

final failures = <String>[];
void fail(String m) {
  failures.add(m);
  stdout.writeln('  FOUT: $m');
}

void checkSet(Spec s, {required bool required}) {
  final dir = Directory(s.dir);
  stdout.writeln('\n${s.name} (${s.dir})');
  if (!dir.existsSync()) {
    if (required) {
      fail('map ontbreekt: ${s.dir}');
    } else {
      stdout.writeln('  overgeslagen (map bestaat niet)');
    }
    return;
  }
  final files = dir.listSync().whereType<File>().where((f) => RegExp(r'\.(png|jpe?g)$', caseSensitive: false).hasMatch(f.path)).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  if (files.length < s.min || files.length > s.max) fail('${files.length} bestanden, verwacht ${s.min} tot ${s.max}');
  if (s.requireAll) {
    for (var i = 1; i <= 8; i++) {
      final p = i.toString().padLeft(2, '0');
      if (!files.any((f) => f.uri.pathSegments.last.startsWith(p))) fail('bestand $p ontbreekt');
    }
    // Volgorde: de bestandsnamen beginnen met 01 t/m 08 en lopen exact in die volgorde (alfabetisch gesorteerd).
    final prefixes = [for (final f in files) f.uri.pathSegments.last.substring(0, f.uri.pathSegments.last.length < 2 ? f.uri.pathSegments.last.length : 2)];
    final expected = [for (var i = 1; i <= 8; i++) i.toString().padLeft(2, '0')];
    if (s.strictPng && prefixes.join(',') != expected.join(',')) fail('bestanden staan niet in de volgorde 01 t/m 08 (gevonden: ${prefixes.join(', ')})');
  }
  for (final f in files) {
    final name = f.uri.pathSegments.last;
    final i = readInfo(f);
    if (i == null) {
      fail('$name is geen PNG of JPEG');
      continue;
    }
    stdout.writeln('  $name  ${i.format} ${i.width}x${i.height}  ${(i.bytes / 1024).toStringAsFixed(0)} KB  ${i.hasAlpha ? 'MET alfa' : 'zonder alfa'}');
    for (final p in imageProblems(s, i, name)) {
      fail(p);
    }
    if (s.strictPng) {
      for (final p in pngProblems(f.readAsBytesSync(), name)) {
        fail(p);
      }
    }
    final pref = s.preferred;
    if (pref != null && (i.width != pref[0] || i.height != pref[1]) && imageProblems(s, i, name).isEmpty) {
      stdout.writeln('  opmerking: $name is ${i.width}x${i.height}; gewenst is ${pref[0]}x${pref[1]}');
    }
  }
}

void checkSingle(String label, String path, int w, int h, {required bool alpha, int? maxBytes, bool required = true}) {
  stdout.writeln('\n$label ($path)');
  final f = File(path);
  if (!f.existsSync()) {
    if (required) {
      fail('$label ontbreekt: $path');
    } else {
      stdout.writeln('  overgeslagen (bestaat niet)');
    }
    return;
  }
  final i = readInfo(f);
  if (i == null) return fail('$label is geen PNG of JPEG');
  stdout.writeln('  ${i.format} ${i.width}x${i.height}  ${(i.bytes / 1024).toStringAsFixed(0)} KB  ${i.hasAlpha ? 'met alfa' : 'zonder alfa'}');
  if (i.width != w || i.height != h) fail('$label is ${i.width}x${i.height}, verwacht ${w}x$h');
  if (alpha && (!i.hasAlpha || i.format != 'PNG')) fail('$label moet een 32-bit PNG met alfakanaal zijn');
  if (!alpha && i.hasAlpha) fail('$label heeft een alfakanaal (niet toegestaan)');
  if (maxBytes != null && i.bytes > maxBytes) fail('$label is ${(i.bytes / 1024).toStringAsFixed(0)} KB, maximaal ${maxBytes ~/ 1024} KB');
}

void main(List<String> args) {
  final reqIos = args.contains('--require-ios'), reqIpad = args.contains('--require-ipad');
  // --only=play,ios,ipad beperkt de controle (de iOS-workflow heeft geen Play-set). Zonder --only: alles.
  final onlyArg = args.where((a) => a.startsWith('--only=')).map((a) => a.substring(7)).firstOrNull;
  final only = onlyArg?.split(',').toSet();
  bool on(String k) => only == null || only.contains(k);
  final cfgPath = args.where((a) => a.startsWith('--config=')).map((a) => a.substring(9)).firstOrNull ?? 'tool/screenshots/store_sizes.json';
  final cfg = jsonDecode(File(cfgPath).readAsStringSync()) as Map<String, dynamic>;
  if (on('play')) {
    for (final s in specsFromConfig(cfg, 'play')) {
      checkSet(s, required: true);
    }
    final play = cfg['play'] as Map<String, dynamic>;
    final fg = (play['featureGraphic'] as List).cast<int>(), ic = (play['icon'] as List).cast<int>();
    checkSingle('Google Play feature graphic', 'store/out/play/feature-graphic/feature-graphic.png', fg[0], fg[1], alpha: false);
    checkSingle('Google Play app-icoon', 'store/out/play/icon/icon-512.png', ic[0], ic[1], alpha: true, maxBytes: 1024 * 1024);
  }
  for (final s in specsFromConfig(cfg, 'appstore')) {
    final isIpad = s.dir.contains('ipad');
    if (isIpad ? on('ipad') : on('ios')) checkSet(s, required: isIpad ? reqIpad : reqIos && s.dir.contains('iphone-6.3'));
  }
  if (failures.isNotEmpty) {
    stderr.writeln('\nValidatie mislukt: ${failures.length} afwijking(en).');
    exit(1);
  }
  stdout.writeln('\nValidatie geslaagd.');
}
