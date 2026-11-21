import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../integration_test/store/demo_data.dart';

/// Bewaakt twee dingen rond de store-screenshots:
///  1. de demodata bevat geen echte persoonsgegevens-patronen;
///  2. er komt geen demo- of testcode, debug-override of testproduct-id in `lib/` (en dus niet in de release-build).
void main() {
  rampenzenderScreenshotChecks();

  test('demodata: verzonnen gezin, voorbeeldnummers, voorbeeldtitels, geen persoonsgegevens-patronen', () {
    expect(demoDataProblems(), isEmpty);
    expect(demoFamilyName, 'Familie De Vries');
    expect(demoVaultDocs.every((d) => d.title.endsWith('(voorbeeld)')), isTrue);
  });

  test('de controle slaat aan op echte gegevens (negatieve test van de patronen)', () {
    final emailish = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');
    expect(emailish.hasMatch('jan@example.com'), isTrue);
    expect(RegExp(r'\b\d{4}\s?[A-Z]{2}\b').hasMatch('1234 AB'), isTrue);
    expect(RegExp(r'^(06-|0\d{2}-)(12345678|23456789|1234567|2345678)$').hasMatch('06-98765432'), isFalse);
  });

  test('lib/ bevat geen demo-, fixture- of testcode', () {
    // Let op: "Familie De Vries" staat bewust niet in deze lijst; het is ook de voorbeeldtekst in het invulveld
    // voor de huishoudnaam (planHhNameHint) en dus gewone app-inhoud.
    const forbidden = [
      'integration_test',
      'demo_data',
      'store/fixture',
      'storeOverrides',
      'storeNow',
      'mockPlatformChannels',
      'FakePurchaseService',
      '(voorbeeld)',
      'android.test.purchased',
      'android.test.canceled',
    ];
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final t = f.readAsStringSync();
      for (final w in forbidden) {
        if (t.contains(w)) hits.add('${f.path}: $w');
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('integration_test en flutter_driver staan alleen onder dev_dependencies', () {
    final lines = File('pubspec.yaml').readAsLinesSync();
    final devAt = lines.indexWhere((l) => l.startsWith('dev_dependencies:'));
    expect(devAt, greaterThan(0));
    for (final pkg in ['integration_test', 'flutter_driver']) {
      final at = lines.indexWhere((l) => l.startsWith('  $pkg:'));
      expect(at, greaterThan(devAt), reason: '$pkg hoort onder dev_dependencies');
    }
  });

  test('de store-uitvoer staat in .gitignore (grote ruwe en bewerkte afbeeldingen)', () {
    final g = File('.gitignore');
    expect(g.existsSync(), isTrue);
    expect(g.readAsStringSync(), contains('store/raw/'));
  });
}

/// De Rampenzender-screenshot toont een frequentie en een DAB+-kanaal. Een foute waarde in een screenshot is erger dan
/// geen waarde. Deze test legt vast welke regio de screenshot gebruikt, welke waarden de dataset daarvoor geeft en dat de
/// dataset ze als "meerdere bronnen" markeert. Hij kan NIET zeggen dat de bronnen zelf kloppen: dat vraagt een controle
/// tegen de live pagina van de omroep (zie README, "Inhoud controleren").
void rampenzenderScreenshotChecks() {
  test('Rampenzender-screenshot: waarden komen uit de dataset en zijn door meerdere bronnen bevestigd', () {
    final fixture = File('integration_test/store/fixture.dart').readAsStringSync();
    expect(fixture, contains("setRaw(RadioKeys.gm, 'GM0518')"));
    final json = jsonDecode(File('assets/radio/rampenzenders.json').readAsStringSync()) as Map<String, dynamic>;
    final region = (json['regions'] as List).cast<Map<String, dynamic>>().firstWhere((r) => r['gm'] == 'GM0518');
    expect(region['name'], "'s-Gravenhage");
    final areaId = (region['areaIds'] as List).single as String;
    final area = (json['transmissions'] as List).cast<Map<String, dynamic>>().firstWhere((t) => t['id'] == areaId);
    expect(area['fmMHz'], [89.3], reason: 'getoond: 89.3 MHz');
    expect((area['dab'] as Map)['channel'], '5B', reason: 'getoond: DAB+ kanaal 5B');
    expect(area['verification'], 'meerdere-bronnen');
    expect((area['sourceIds'] as List).length, greaterThanOrEqualTo(2));
    expect(area['lastReviewed'], isNotNull);
  });
}
