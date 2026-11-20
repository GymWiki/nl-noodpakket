// Voorcontrole voor een iOS-build (draait vóór `flutter build ipa`): faalt met een duidelijke melding bij
// veelvoorkomende uploadfouten. Draaien vanuit de projectmap, na `flutter pub get`:
//   dart run tool/ios_preflight.dart
//
// Controleert:
//  - deployment target: Podfile, project.pbxproj en AppFrameworkInfo.plist zijn gelijk en niet lager dan het
//    hoogste minimum van de plugins (uit hun .podspec/Package.swift) en niet lager dan 15.0;
//  - bundle-id en versie-instellingen;
//  - Info.plist: gebruiksteksten voor camera, Face ID, contacten, foto's en lokaal netwerk;
//  - PrivacyInfo.xcprivacy aanwezig, zonder tracking, en opgenomen in het Xcode-project;
//  - app-icoon: geen alpha, 1024 x 1024 aanwezig, alle bestanden uit Contents.json bestaan; launch screen aanwezig;
//  - exportcompliance: meldt (zonder te falen) of ITSAppUsesNonExemptEncryption is gezet.
import 'dart:convert';
import 'dart:io';

const expectedBundleId = 'com.mycompany.mijnnoodpakket';
const absoluteMinimum = 15.0; // Apple: vanaf april 2027 minimaal iOS 15.0 voor uploads

final problems = <String>[];
void fail(String msg) => problems.add(msg);
void info(String msg) => stdout.writeln(msg);

String read(String path) {
  final f = File(path);
  if (!f.existsSync()) {
    fail('ontbreekt: $path');
    return '';
  }
  return f.readAsStringSync();
}

double? ver(String s) => double.tryParse(s);

void main() {
  // --- Deployment target -------------------------------------------------------------------------
  final podfile = read('ios/Podfile');
  final pbx = read('ios/Runner.xcodeproj/project.pbxproj');
  final frameworkInfo = read('ios/Flutter/AppFrameworkInfo.plist');

  final podPlatform = RegExp(r"^\s*platform :ios,\s*'([\d.]+)'", multiLine: true).firstMatch(podfile)?.group(1);
  if (podPlatform == null) fail("ios/Podfile heeft geen regel `platform :ios, 'X.Y'` (CocoaPods valt dan terug op 13.0)");

  final pbxTargets = RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = ([\d.]+);').allMatches(pbx).map((m) => m.group(1)!).toSet();
  if (pbxTargets.isEmpty) fail('project.pbxproj heeft geen IPHONEOS_DEPLOYMENT_TARGET');
  final minOs = RegExp(r'<key>MinimumOSVersion</key>\s*<string>([\d.]+)</string>').firstMatch(frameworkInfo)?.group(1);
  if (minOs == null) fail('AppFrameworkInfo.plist heeft geen MinimumOSVersion');

  final all = {
    if (podPlatform != null) 'Podfile': {podPlatform},
    'project.pbxproj': pbxTargets,
    if (minOs != null) 'AppFrameworkInfo.plist': {minOs},
  };
  final distinct = {for (final v in all.values) ...v};
  if (distinct.length > 1) fail('deployment target is niet overal gelijk: $all');

  // Hoogste minimum van de plugins, uit hun podspec of Package.swift (iOS-regels, niet macOS).
  var pluginMax = 0.0;
  var pluginMaxName = '';
  final cfgFile = File('.dart_tool/package_config.json');
  if (!cfgFile.existsSync()) {
    fail('.dart_tool/package_config.json ontbreekt: draai eerst `flutter pub get`');
  } else {
    final cfg = jsonDecode(cfgFile.readAsStringSync()) as Map<String, dynamic>;
    final base = Directory('.dart_tool').absolute.uri;
    for (final p in cfg['packages'] as List<dynamic>) {
      final uri = base.resolve(p['rootUri'] as String);
      final root = Directory.fromUri(uri);
      for (final sub in ['ios', 'darwin']) {
        final d = Directory('${root.path}/$sub');
        if (!d.existsSync()) continue;
        for (final e in d.listSync(recursive: true, followLinks: false)) {
          if (e is! File) continue;
          final n = e.path.replaceAll('\\', '/');
          final isSpec = n.endsWith('.podspec');
          if (!isSpec && !n.endsWith('Package.swift')) continue;
          final t = e.readAsStringSync();
          final found = <double>[
            for (final m in RegExp(r'''ios\.deployment_target\s*=\s*['"]([\d.]+)['"]''').allMatches(t)) ?ver(m.group(1)!),
            for (final m in RegExp(r'''s\.platform\s*=\s*:ios,\s*['"]([\d.]+)['"]''').allMatches(t)) ?ver(m.group(1)!),
            for (final m in RegExp(r'''deployment_target\s*=\s*['"]([\d.]+)['"]''').allMatches(t))
              if (!t.contains('osx.deployment_target')) ?ver(m.group(1)!),
            for (final m in RegExp(r'''\.iOS\(\s*["']?([\d.]+)["']?\s*\)''').allMatches(t)) ?ver(m.group(1)!),
          ];
          for (final v in found) {
            if (v > pluginMax) {
              pluginMax = v;
              pluginMaxName = p['name'] as String;
            }
          }
        }
      }
    }
  }
  final target = ver(distinct.isEmpty ? '' : distinct.first) ?? 0;
  final required = pluginMax > absoluteMinimum ? pluginMax : absoluteMinimum;
  if (target < required) {
    fail('deployment target $target is lager dan nodig ($required'
        '${pluginMax >= absoluteMinimum ? ', door plugin $pluginMaxName' : ''})');
  }
  info('Deployment target: $target (hoogste plugin-minimum: $pluginMax door $pluginMaxName)');

  // --- Bundle-id en versie -----------------------------------------------------------------------
  final bundleIds = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);').allMatches(pbx).map((m) => m.group(1)!.trim()).toSet();
  if (!bundleIds.contains(expectedBundleId)) fail('bundle-id $expectedBundleId staat niet in het project: $bundleIds');
  final infoPlist = read('ios/Runner/Info.plist');
  for (final key in ['CFBundleShortVersionString', 'CFBundleVersion']) {
    if (!RegExp('<key>$key</key>\\s*<string>\\\$\\(FLUTTER_BUILD_(NAME|NUMBER)\\)</string>').hasMatch(infoPlist)) {
      fail('Info.plist: $key hoort uit Flutter te komen (\$(FLUTTER_BUILD_NAME/NUMBER)), zodat --build-number werkt');
    }
  }

  // --- Info.plist: gebruiksteksten ---------------------------------------------------------------
  const usage = {
    'NSCameraUsageDescription': 'camera (mobile_scanner, image_picker, cunning_document_scanner)',
    'NSFaceIDUsageDescription': 'Face ID (local_auth)',
    'NSContactsUsageDescription': 'contacten (flutter_contacts)',
    'NSPhotoLibraryUsageDescription': "foto's (image_picker)",
    'NSLocalNetworkUsageDescription': 'lokaal netwerk (delen via QR)',
  };
  for (final e in usage.entries) {
    final m = RegExp('<key>${e.key}</key>\\s*<string>([^<]*)</string>').firstMatch(infoPlist);
    if (m == null || m.group(1)!.trim().length < 20) {
      fail('Info.plist mist een bruikbare ${e.key} voor ${e.value}');
    }
  }

  // --- Privacymanifest ---------------------------------------------------------------------------
  final privacy = read('ios/Runner/PrivacyInfo.xcprivacy');
  if (privacy.isNotEmpty) {
    if (!RegExp(r'NSPrivacyTracking</key>\s*<false/>').hasMatch(privacy)) fail('PrivacyInfo.xcprivacy: NSPrivacyTracking moet false zijn');
    if (!pbx.contains('PrivacyInfo.xcprivacy in Resources')) fail('PrivacyInfo.xcprivacy zit niet in de Resources van het Xcode-project');
  }

  // --- Icoon en launch screen --------------------------------------------------------------------
  final iconDir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
  final contents = File('${iconDir.path}/Contents.json');
  if (!contents.existsSync()) {
    fail('AppIcon.appiconset/Contents.json ontbreekt');
  } else {
    final images = (jsonDecode(contents.readAsStringSync())['images'] as List<dynamic>).cast<Map<String, dynamic>>();
    var has1024 = false;
    for (final img in images) {
      final fn = img['filename'] as String?;
      if (fn == null) continue;
      final f = File('${iconDir.path}/$fn');
      if (!f.existsSync()) {
        fail('icoon in Contents.json bestaat niet: $fn');
        continue;
      }
      final b = f.readAsBytesSync();
      final isPng = b.length > 33 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4e && b[3] == 0x47;
      if (!isPng) {
        fail('$fn is geen PNG');
        continue;
      }
      int u32(int o) => (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];
      final w = u32(16), h = u32(20), colorType = b[25];
      var hasTrns = false;
      for (var o = 33; o + 8 < b.length;) {
        final len = u32(o);
        final type = String.fromCharCodes(b.sublist(o + 4, o + 8));
        if (type == 'tRNS') hasTrns = true;
        if (type == 'IDAT') break;
        o += 12 + len;
      }
      if (colorType == 4 || colorType == 6 || hasTrns) fail('$fn heeft een alfakanaal (transparantie): App Store weigert dat');
      if (w == 1024 && h == 1024) has1024 = true;
    }
    if (!has1024) fail('geen 1024 x 1024 app-icoon in AppIcon.appiconset');
  }
  if (!File('ios/Runner/Base.lproj/LaunchScreen.storyboard').existsSync()) fail('LaunchScreen.storyboard ontbreekt');

  // --- Exportcompliance (alleen melden) ----------------------------------------------------------
  final enc = RegExp(r'<key>ITSAppUsesNonExemptEncryption</key>\s*<(true|false)/>').firstMatch(infoPlist)?.group(1);
  info(enc == null
      ? 'Exportcompliance: ITSAppUsesNonExemptEncryption is niet gezet; App Store Connect vraagt de exportvragen bij elke upload.'
      : 'Exportcompliance: ITSAppUsesNonExemptEncryption = $enc.');

  if (problems.isNotEmpty) {
    stderr.writeln('\nVoorcontrole iOS: ${problems.length} probleem(en):');
    for (final p in problems) {
      stderr.writeln(' - $p');
    }
    exit(1);
  }
  info('Voorcontrole iOS: alles in orde.');
}
