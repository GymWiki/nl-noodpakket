import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mijnnoodpakket/data/seed/seed_items.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_models.dart';

WikiData load() =>
    WikiData.parse(File('assets/wiki/noodgevallen.json').readAsStringSync());

void main() {
  final seedIds = {for (final s in seedItems) s.id};

  test('wiki-JSON: schema, unieke id\'s, stappen, bronnen en checklist-ids kloppen', () {
    final d = load();
    expect(d.schemaVersion, wikiSchemaVersion);
    expect(validateWiki(d, seedIds), isEmpty);
  });

  test('elk noodgeval heeft een controledatum en minstens één stap', () {
    final d = load();
    for (final e in [d.eersteUur, ...d.emergencies]) {
      expect(e.stappenNu, isNotEmpty, reason: e.id);
      expect(e.lastReviewed.year, greaterThanOrEqualTo(2026), reason: e.id);
    }
    expect(d.emergencies.length, greaterThanOrEqualTo(20));
  });

  test('alleen 112 en nummers uit de bronnen: bekende lijst', () {
    final numbers = {
      for (final e in load().emergencies)
        for (final c in e.contacten) c.nummer,
    };
    expect(numbers, {'0800-9009', '0800-1508', '0900-0904', '0900-8844', '0800-7000'});
  });

  group('validateWiki vangt fouten', () {
    WikiEmergency mk({
      String id = 'x',
      String categorie = 'voorzieningen',
      List<String> stappen = const ['Doe iets.'],
      List<String> items = const [],
      String url = 'https://example.nl/',
    }) =>
        WikiEmergency(
          id: id,
          categorie: categorie,
          titel: 't',
          icoon: 'bolt',
          trefwoorden: const [],
          intro: 'i',
          stappenNu: stappen,
          stappenDaarna: const [],
          bel112Als: const [],
          voorbereidenItemIds: items,
          contacten: const [],
          bronnen: [WikiSource(naam: 'n', url: url)],
          lastReviewed: DateTime(2026, 11, 10),
        );

    WikiData wrap(List<WikiEmergency> l) {
      final base = load();
      return WikiData(
          schemaVersion: 1,
          categories: base.categories,
          eersteUur: base.eersteUur,
          emergencies: l);
    }

    test('dubbele id', () {
      expect(validateWiki(wrap([mk(), mk()]), seedIds).join(), contains('dubbele id'));
    });
    test('geen stappen', () {
      expect(validateWiki(wrap([mk(stappen: [])]), seedIds).join(),
          contains('minimaal 1 stap'));
    });
    test('onbekend checklist-item', () {
      expect(validateWiki(wrap([mk(items: ['bestaat_niet'])]), seedIds).join(),
          contains('bestaat niet'));
    });
    test('onbekende categorie en onveilige url', () {
      final e = validateWiki(
          wrap([mk(categorie: 'nope', url: 'http://example.nl')]), seedIds);
      expect(e.join(), contains('onbekende categorie'));
      expect(e.join(), contains('ongeldige bron-url'));
    });
    test('onbekende schemaversie wordt geweigerd', () {
      expect(() => WikiData.parse('{"schemaVersion": 99}'), throwsFormatException);
    });
  });

  group('zoeken', () {
    final all = load().emergencies;
    test('op titel', () {
      expect(searchEmergencies(all, 'storm').map((e) => e.id), contains('storm'));
    });
    test('op trefwoord, hoofdletter- en accentongevoelig', () {
      expect(searchEmergencies(all, 'BLACKOUT').map((e) => e.id), ['stroomstoring']);
      expect(searchEmergencies(all, 'hygiene').map((e) => e.id), contains('infectieziekte'));
    });
    test('dagelijkse zoektermen vinden iets', () {
      for (final q in ['stroom', 'water', 'brand', 'gas', 'hitte']) {
        expect(searchEmergencies(all, q), isNotEmpty, reason: q);
      }
    });
    test('geen resultaat en lege zoekterm', () {
      expect(searchEmergencies(all, 'zzzzz'), isEmpty);
      expect(searchEmergencies(all, '  '), hasLength(all.length));
    });
  });
}
