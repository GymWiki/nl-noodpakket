// Controleert dat er geen demodata of testcode in een release-APK of -AAB zit.
//   flutter build apk --release
//   dart run tool/screenshots/check_release.dart build/app/outputs/flutter-apk/app-release.apk
//   (of een .aab: dart run tool/screenshots/check_release.dart build/app/outputs/bundle/release/app-release.aab)
//
// Zoekt in alle bestanden van het archief naar markeringen die alleen in testcode of demodata voorkomen.
// Faalt (exitcode 1) als er iets wordt gevonden.
import 'dart:convert';
import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:archive/archive.dart';

/// Let op: "Familie De Vries" staat hier niet in; het is ook de voorbeeldtekst in het invulveld voor de huishoudnaam.
const markers = <String>[
  'integration_test',
  'IntegrationTestWidgetsFlutterBinding',
  'flutter_driver',
  'demo_data',
  'storeOverrides',
  'mockPlatformChannels',
  'FakePurchaseService',
  '(voorbeeld)',
  'Buurvrouw Fleur',
  'Oma Els',
  '06-12345678',
  'android.test.purchased',
  'android.test.canceled',
];

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Gebruik: dart run tool/screenshots/check_release.dart <app-release.apk|aab>');
    exit(2);
  }
  final file = File(args[0]);
  if (!file.existsSync()) {
    stderr.writeln('Bestand bestaat niet: ${args[0]}');
    exit(2);
  }
  final archive = ZipDecoder().decodeBytes(file.readAsBytesSync());
  final found = <String>[];
  var scanned = 0;
  for (final f in archive.files) {
    if (!f.isFile) continue;
    final bytes = f.content as List<int>;
    scanned++;
    // Latin-1 houdt alle bytes behouden; de markeringen zijn ASCII/UTF-8 zonder bijzondere tekens.
    final text = latin1.decode(bytes, allowInvalid: true);
    for (final m in markers) {
      if (text.contains(latin1.decode(utf8.encode(m)))) found.add('${f.name}: $m');
    }
  }
  stdout.writeln('${args[0]}: $scanned bestanden gecontroleerd op ${markers.length} markeringen.');
  if (found.isNotEmpty) {
    stderr.writeln('GEVONDEN (hoort niet in een release):');
    for (final x in found) {
      stderr.writeln(' - $x');
    }
    exit(1);
  }
  stdout.writeln('Schoon: geen demodata, testcode, debug-overrides of testproduct-id\'s gevonden.');
}
