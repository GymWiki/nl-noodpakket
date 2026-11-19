// Valideert de store-uitvoer in store/out/ tegen de eisen van Google Play en de App Store.
//   dart run tool/screenshots/validate.dart            (controleert alle sets die bestaan; Play-telefoon is verplicht)
//   dart run tool/screenshots/validate.dart --require-ios --require-ipad
//   dart run tool/screenshots/validate.dart --only=ios,ipad --require-ios   (alleen de App Store-sets)
//
// Controleert per bestand: afmetingen, bestandstype (PNG of JPEG), kleurmodus (geen alfakanaal), bestandsgrootte
// en per set het aantal en de aanwezigheid van 01 t/m 08. Faalt (exitcode 1) bij een afwijking.
//
// Regels per winkel en uitvoermap (ze verschillen bewust):
//   Google Play (store/out/play/phone): 320 tot 3840 px per zijde, lange zijde hooguit 2x de korte (2:1), geen alfa,
//     JPEG of 24-bit PNG; bij voorkeur 1080x1920. Feature graphic exact 1024x500 zonder alfa.
//   App Store iPhone 6.9" (store/out/appstore/iphone-6.9): exact 1260x2736, 1290x2796 of 1320x2868 (portret), zonder alfa.
//     Geen verhoudingsregel: 1320x2868 (ca. 2,17:1) is door Apple geaccepteerd en mag dus niet op 2:1 falen.
//   App Store iPad 13" (store/out/appstore/ipad-13): exact 2064x2752 of 2048x2732, zonder alfa. Ook geen 2:1-regel.
//
// Bronnen:
//   App Store Connect Help, "Screenshot specifications" (developer.apple.com/help/app-store-connect/reference/
//     screenshot-specifications/), opgehaald op 2026-11-19. LET OP: de iPhone- en iPad-secties vielen buiten het
//     verbatim opgehaalde deel; de waarden 1320x2868 (iPhone), 2064x2752 en 2048x2732 (iPad), png/jpg/jpeg, "geen
//     alfakanalen of transparantie", 1 tot 10 screenshots en het ontbreken van een verhoudingsregel komen uit een
//     samenvatting. 1260x2736 en 1290x2796 komen uit de opdracht en zijn niet uit de bron bevestigd.
//   Play Console Help, "Add preview assets" (support.google.com/googleplay/android-developer/answer/9866151):
//     op 2026-11-19 NIET opgehaald (host geblokkeerd in de sandbox). De Play-regels hierboven komen uit de opdracht
//     van de eigenaar en zijn nog niet door ons tegen de pagina gecontroleerd. Controleer dit handmatig.
import 'dart:io';
import 'dart:typed_data';

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
  });
  final String name, dir;
  final List<List<int>>? sizes; // exact toegestane [breedte, hoogte]; null = bereik via minSide/maxSide
  final int? minSide, maxSide; // per zijde, in px
  final double? maxRatio; // lange zijde / korte zijde; alleen Google Play
  final List<int>? preferred; // gewenst formaat; afwijking is alleen een opmerking
  final int min, max;
  final bool requireAll;
}

const playPhone = Spec('Google Play telefoon', 'store/out/play/phone',
    minSide: 320, maxSide: 3840, maxRatio: 2, preferred: [1080, 1920], min: 2, max: 8);
const appStoreIphone = Spec('App Store iPhone 6.9"', 'store/out/appstore/iphone-6.9',
    sizes: [[1260, 2736], [1290, 2796], [1320, 2868]], min: 1, max: 10);
const appStoreIpad = Spec('App Store iPad 13"', 'store/out/appstore/ipad-13',
    sizes: [[2064, 2752], [2048, 2732]], min: 1, max: 10);

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

class Info {
  Info(this.format, this.width, this.height, this.hasAlpha, this.bytes);
  final String format;
  final int width, height, bytes;
  final bool hasAlpha;
}

Info? readInfo(File f) => parseInfo(f.readAsBytesSync());

Info? parseInfo(List<int> b) {
  if (b.length > 33 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4e && b[3] == 0x47) {
    final d = ByteData.sublistView(Uint8List.fromList(b));
    final w = d.getUint32(16), h = d.getUint32(20), colorType = b[25];
    var trns = false;
    for (var o = 33; o + 8 < b.length;) {
      final len = d.getUint32(o);
      final type = String.fromCharCodes(b.sublist(o + 4, o + 8));
      if (type == 'tRNS') trns = true;
      if (type == 'IDAT' || type == 'IEND') break;
      o += 12 + len;
    }
    return Info('PNG', w, h, colorType == 4 || colorType == 6 || trns, b.length);
  }
  if (b.length > 4 && b[0] == 0xff && b[1] == 0xd8) {
    var o = 2;
    while (o + 9 < b.length) {
      if (b[o] != 0xff) {
        o++;
        continue;
      }
      final m = b[o + 1];
      if (m >= 0xc0 && m <= 0xcf && m != 0xc4 && m != 0xc8 && m != 0xcc) {
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
  if (on('play')) {
    checkSet(playPhone, required: true);
    checkSingle('Google Play feature graphic', 'store/out/play/feature-graphic/feature-graphic.png', 1024, 500, alpha: false);
    checkSingle('Google Play app-icoon', 'store/out/play/icon/icon-512.png', 512, 512, alpha: true, maxBytes: 1024 * 1024);
  }
  if (on('ios')) checkSet(appStoreIphone, required: reqIos);
  if (on('ipad')) checkSet(appStoreIpad, required: reqIpad);
  if (failures.isNotEmpty) {
    stderr.writeln('\nValidatie mislukt: ${failures.length} afwijking(en).');
    exit(1);
  }
  stdout.writeln('\nValidatie geslaagd.');
}
