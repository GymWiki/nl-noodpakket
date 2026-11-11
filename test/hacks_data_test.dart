import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mijnnoodpakket/data/seed/seed_items.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_models.dart';
import 'package:mijnnoodpakket/features/wiki/wiki_models.dart';

HackData load() => HackData.parse(File('assets/wiki/noodhacks.json').readAsStringSync());
final wiki = WikiData.parse(File('assets/wiki/noodgevallen.json').readAsStringSync());

Set<String> get wikiIds => {wiki.eersteUur.id, for (final e in wiki.emergencies) e.id};
final checklistIds = {for (final s in seedItems) s.id};

void main() {
  test('noodhacks-JSON: schema, unieke id\'s, stappen, materialen, checklist- en wiki-id\'s kloppen', () {
    final d = load();
    expect(validateHacks(d, checklistIds: checklistIds, wikiIds: wikiIds), isEmpty);
  });

  test('elke hack heeft bron, bronType en controledatum; nooit-hacks hebben een reden en een alternatief', () {
    final d = load();
    for (final h in d.hacks) {
      expect(h.bronnen, isNotEmpty, reason: h.id);
      expect(h.lastReviewed.year, greaterThanOrEqualTo(2026), reason: h.id);
      if (h.label == HackLabel.nooit) {
        expect(h.reden.trim(), isNotEmpty, reason: h.id);
        expect(h.alternatiefIds, isNotEmpty, reason: '${h.id} wijst geen veilig alternatief aan');
        expect(h.categorie, 'mythes');
      }
    }
    expect(d.hacks.where((h) => h.label == HackLabel.nooit), isNotEmpty);
  });

  test('alle categorieën bevatten hacks en elk materiaal wordt gebruikt', () {
    final d = load();
    for (final c in d.categories) {
      expect(d.hacks.any((h) => h.categorie == c.id), isTrue, reason: c.id);
    }
    final used = {for (final h in d.hacks) ...h.materialen};
    for (final m in d.materials) {
      expect(used.contains(m.id), isTrue, reason: 'ongebruikt materiaal ${m.id}');
    }
  });

  group('veiligheidsinhoud', () {
    final d = load();
    String text(String id) {
      final h = d.byId(id)!;
      return [h.intro, ...h.stappen, ...h.waarschuwingen].join(' ');
    }

    test('koken: 3 minuten (strengste Nederlandse lezing)', () {
      expect(text('water-koken'), contains('3 minuten'));
    });

    test('bleek: alleen onparfumeerd, 5% tot 9%, 30 minuten, koken is veiliger, geen rekenhulp', () {
      final t = text('water-ontsmetten-bleek');
      expect(t, contains('5% tot 9%'));
      expect(t, contains('30 minuten'));
      expect(t, contains('onparfumeerde'));
      expect(t, contains('Koken is veiliger'));
      expect(d.byId('water-ontsmetten-bleek')!.label, HackLabel.letop);
      expect(d.byId('water-ontsmetten-bleek')!.alternatiefIds, contains('water-koken'));
    });

    test('binnen branden: barbecue en campingstoof staan als nooit-hack', () {
      final h = d.byId('mythe-barbecue-binnen')!;
      expect(h.label, HackLabel.nooit);
      expect(h.reden, contains('koolmonoxide'));
    });

    test('alleen onderbouwde onderwerpen: geen hooikist, generator, kaarsenkachel of noodtoilet', () {
      final all = d.hacks.map((h) => '${h.titel} ${h.stappen.join(' ')} ${h.intro}').join(' ').toLowerCase();
      for (final banned in ['hooikist', 'generator', 'terracotta', 'noodtoilet', 'kattenbak', 'zaagsel', 'ors']) {
        expect(RegExp('\\b$banned\\b').hasMatch(all), isFalse, reason: banned);
      }
    });
  });

  group('wat heb ik in huis', () {
    final d = load();

    test('zonder materialen: alleen hacks zonder materiaal zijn direct mogelijk', () {
      final m = matchHacks(d.hacks, {});
      expect(m.where((x) => x.possible).every((x) => x.hack.materialen.isEmpty), isTrue);
      expect(m.any((x) => x.hack.id == 'eten-zonder-koken' && x.possible), isTrue);
    });

    test('nooit-hacks komen niet in de resultaten', () {
      final m = matchHacks(d.hacks, {for (final x in d.materials) x.id});
      expect(m.any((x) => x.hack.label == HackLabel.nooit), isFalse);
      expect(m.every((x) => x.possible), isTrue);
    });

    test('ontbrekend materiaal wordt gemeld; mogelijke hacks staan bovenaan', () {
      final m = matchHacks(d.hacks, {'pan'});
      final koken = m.firstWhere((x) => x.hack.id == 'water-koken');
      expect(koken.possible, isFalse);
      expect(koken.missing, ['kookbron']);
      final firstImpossible = m.indexWhere((x) => !x.possible);
      expect(m.sublist(firstImpossible).any((x) => x.possible), isFalse);
    });

    test('met pan en kookbron is koken mogelijk; veilig gaat voor let op bij gelijke tellers', () {
      final m = matchHacks(d.hacks, {'pan', 'kookbron', 'bleek', 'flessen'});
      expect(m.firstWhere((x) => x.hack.id == 'water-koken').possible, isTrue);
      final ids = m.where((x) => x.possible).map((x) => x.hack.label.index).toList();
      // binnen dezelfde "ontbrekend"-groep: label-volgorde stijgend
      expect(ids.first, HackLabel.veilig.index);
    });
  });

  group('zoeken en filters', () {
    final d = load();
    test('op titel en trefwoord (accent- en hoofdletterongevoelig)', () {
      expect(searchHacks(d.hacks, query: 'BLEEK').map((h) => h.id), contains('water-ontsmetten-bleek'));
      expect(searchHacks(d.hacks, query: 'knackebrod'), isEmpty); // trefwoorden bevatten het niet
      expect(searchHacks(d.hacks, query: 'koolmonoxide').map((h) => h.id), contains('mythe-barbecue-binnen'));
      expect(searchHacks(d.hacks, query: 'zzz'), isEmpty);
    });
    test('filter op label en categorie', () {
      final nooit = searchHacks(d.hacks, label: HackLabel.nooit);
      expect(nooit.every((h) => h.label == HackLabel.nooit), isTrue);
      final water = searchHacks(d.hacks, categorie: 'water', label: HackLabel.veilig);
      expect(water.every((h) => h.categorie == 'water' && h.label == HackLabel.veilig), isTrue);
      expect(water, isNotEmpty);
    });
  });

  test('koppelingen: noodgevallen en checklist-items vinden hacks', () {
    final d = load();
    expect(d.forEmergency('uitval-water').map((h) => h.id), containsAll(['water-vinden', 'water-koken']));
    expect(d.forEmergency('stroomstoring').map((h) => h.id), contains('koelkast-stroomuitval'));
    expect(d.forItem('water'), isNotEmpty);
    expect(d.forItem('stove').map((h) => h.id), contains('buiten-koken'));
    expect(d.forItem('bestaat_niet'), isEmpty);
  });

  test('validatie vangt fouten', () {
    HackData with0(Hack h) {
      final d = load();
      return HackData(categories: d.categories, materials: d.materials, hacks: [h]);
    }

    Hack base({String id = 'x', HackLabel label = HackLabel.veilig, String reden = '', List<String> stappen = const ['Doe iets.'], List<String> mats = const [], String url = 'https://example.nl'}) =>
        Hack(
          id: id, categorie: 'water', titel: 't', label: label, intro: 'i', materialen: mats,
          stappen: stappen, waarschuwingen: const [], reden: reden, alternatiefIds: const [],
          bronnen: [HackSource(naam: 'n', url: url)], bronType: 'officieel',
          lastReviewed: DateTime(2026, 11, 11), trefwoorden: const [],
          gerelateerdeNoodgevallen: const [], gerelateerdeChecklistItemIds: const [],
        );

    String errs(Hack h) => validateHacks(with0(h), checklistIds: checklistIds, wikiIds: wikiIds).join('|');
    expect(errs(base(stappen: [])), contains('minimaal 1 stap'));
    expect(errs(base(mats: ['bestaat_niet'])), contains('onbekend materiaal'));
    expect(errs(base(label: HackLabel.nooit)), contains('reden'));
    expect(errs(base(url: 'http://example.nl')), contains('ongeldige url'));
    expect(() => HackData.parse('{"schemaVersion": 9}'), throwsFormatException);
  });
}
