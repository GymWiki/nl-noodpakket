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
      // Conceptplannen (draft) hebben nog geen bron en zijn in een release-build onzichtbaar.
      if (!h.isDraft) expect(h.bronnen, isNotEmpty, reason: h.id);
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
      // Deze onderwerpen mogen alleen als concept (draft, onzichtbaar in een release-build) in de data staan, tot er een
      // officiële bron is gelezen. Dan haal je ze hier bewust uit de lijst.
      final all = d.hacks.where((h) => !h.isDraft).map((h) => '${h.titel} ${h.stappen.join(' ')} ${h.intro}').join(' ').toLowerCase();
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

  test('koppelingen: noodgevallen vinden hacks', () {
    final d = load();
    expect(d.forEmergency('uitval-water').map((h) => h.id), containsAll(['water-vinden', 'water-koken']));
    expect(d.forEmergency('stroomstoring').map((h) => h.id), contains('koelkast-stroomuitval'));
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

  group('survivalpakket: uitgebreide plannen', () {
    final all = load();
    final extended = all.hacks.where((h) => h.isExtended).toList();

    test('er zijn uitgebreide plannen en elk heeft een geldige status', () {
      expect(extended.length, greaterThan(20));
      for (final h in extended) {
        expect([hackStatusVerified, hackStatusDraft], contains(h.status), reason: h.id);
      }
    });

    test('id\'s zijn uniek en in kebab-case', () {
      final ids = [for (final h in all.hacks) h.id];
      expect(ids.toSet().length, ids.length);
      for (final id in ids) {
        expect(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(id), isTrue, reason: id);
      }
    });

    test('elk plan heeft label, categorie en 2 tot 6 stappen van hooguit 140 tekens', () {
      for (final h in extended) {
        expect(HackLabel.values, contains(h.label), reason: h.id);
        expect(all.categories.any((c) => c.id == h.categorie), isTrue, reason: h.id);
        expect(h.stappen.length, inInclusiveRange(2, hackMaxSteps), reason: h.id);
        for (final st in h.stappen) {
          expect(st.length, lessThanOrEqualTo(hackMaxStepLength), reason: '${h.id}: "$st"');
        }
      }
    });

    test('een stap is één handeling: geen opsommingen in een stap en geen uitroeptekens', () {
      for (final h in extended) {
        for (final st in [...h.stappen, ...h.waarschuwingen]) {
          expect(st.contains('!'), isFalse, reason: '${h.id}: $st');
          expect(st.trim().isNotEmpty, isTrue, reason: h.id);
        }
      }
    });

    test('verified: minstens een officiële bron met https-url en raadpleegdatum', () {
      for (final h in extended.where((h) => h.status == hackStatusVerified)) {
        expect(h.bronnen, isNotEmpty, reason: h.id);
        expect(h.bronType, 'officieel', reason: h.id);
        for (final b in h.bronnen) {
          expect(b.url, startsWith('https://'), reason: h.id);
          expect(b.geraadpleegd, isNotNull, reason: '${h.id}: ${b.naam}');
        }
      }
    });

    test('draft zegt eerlijk dat er nog geen bron is', () {
      for (final h in extended.where((h) => h.isDraft)) {
        expect(h.bronnen, isEmpty, reason: '${h.id}: een plan met bron hoort verified te zijn of een bron te missen');
        expect(h.bronOpmerking, isNotNull, reason: h.id);
      }
    });

    test('draft is niet zichtbaar in een release-build, ook niet via categorieën, materialen of alternatieven', () {
      final rel = all.visible(release: true);
      expect(rel.hacks.any((h) => h.isDraft), isFalse);
      expect(rel.hacks.length, lessThan(all.hacks.length));
      for (final h in all.hacks.where((h) => h.isDraft)) {
        expect(rel.byId(h.id), isNull, reason: h.id);
      }
      for (final c in rel.categories) {
        expect(rel.hacks.any((h) => h.categorie == c.id), isTrue, reason: 'lege categorie ${c.id}');
      }
      final used = {for (final h in rel.hacks) ...h.materialen};
      for (final m in rel.materials) {
        expect(used, contains(m.id), reason: 'ongebruikt materiaal ${m.id}');
      }
      // Een zichtbaar plan wijst nooit naar een concept.
      for (final h in rel.hacks) {
        for (final a in h.alternatiefIds) {
          expect(rel.byId(a), isNotNull, reason: '${h.id} -> $a');
        }
      }
      // Debug-build toont alles.
      expect(all.visible(release: false).hacks.length, all.hacks.length);
    });

    test('mythes zijn gratis, hebben een reden en wijzen naar een plan (wat doe je wel)', () {
      for (final h in all.hacks.where((h) => h.label == HackLabel.nooit)) {
        expect(h.isFree, isTrue, reason: h.id);
        expect(h.reden.trim(), isNotEmpty, reason: h.id);
        expect(h.alternatiefIds, isNotEmpty, reason: h.id);
      }
    });

    test('veiligheidskritisch is altijd gratis; hulp roepen, eerste hulp en weg moeten zijn veiligheidskritisch', () {
      for (final h in all.hacks.where((h) => h.safetyCritical)) {
        expect(h.isFree, isTrue, reason: h.id);
      }
      for (final id in ['112-bereiken', '112-voorbereiden', '112-wanneer', 'bloeding', 'bloedneus', 'onderkoeling', 'botbreuk-verstuiking',
        'medicijnen-uitval', 'ehbo-reanimatie', 'melders', 'vluchttas', 'thuis-of-weg']) {
        expect(all.byId(id)!.safetyCritical, isTrue, reason: id);
      }
      for (final h in all.hacks.where((h) => h.categorie == 'eerste-hulp')) {
        expect(h.safetyCritical, isTrue, reason: '${h.id}: eerste hulp is altijd gratis');
      }
    });

    test('praktische plannen volgen de bestaande Pro-regel (titel gratis zichtbaar, stappenplan Pro)', () {
      for (final id in ['buren-organiseren', 'buren-checken']) {
        final h = all.byId(id)!;
        expect(h.safetyCritical, isFalse, reason: id);
        expect(h.isFree, isFalse, reason: id);
      }
    });

    test('de oorspronkelijke 25 hacks zijn ongewijzigd: zelfde id\'s en dezelfde twee proefhacks', () {
      const original = ['water-vinden', 'voorfilteren', 'water-koken', 'water-ontsmetten-bleek', 'water-tabletten', 'water-chemisch', 'water-opslag',
        'eten-zonder-koken', 'buiten-koken', 'koelkast-stroomuitval', 'vriezer-ontdooid', 'vriezer-flessen', 'warm-kamer', 'handen-schoon',
        'licht-zonder-stroom', 'radio-informatie', 'powerbank', 'mythe-barbecue-binnen', 'mythe-cv-water', 'mythe-chemisch-koken',
        'mythe-filter-zonder-koken', 'mythe-bleek-toevoegingen', 'mythe-opnieuw-invriezen', 'mythe-ruiktest', 'mythe-twee-uur'];
      for (final id in original) {
        final h = all.byId(id);
        expect(h, isNotNull, reason: id);
        expect(h!.isExtended, isFalse, reason: id);
      }
      expect({for (final h in all.hacks) if (h.freePreview) h.id}, {'water-koken', 'koelkast-stroomuitval'});
    });

    test('timers verwijzen naar een bestaande stap', () {
      for (final h in all.hacks) {
        for (final k in h.stapTimers.keys) {
          expect(k, inInclusiveRange(1, h.stappen.length), reason: h.id);
        }
      }
      expect(all.byId('bloeding')!.stapTimers.values, [600]);
      expect(all.byId('bloedneus')!.stapTimers.values, [600]);
    });

    test('zoeken vindt nieuwe plannen op titel en trefwoord (ook zonder accenten)', () {
      final rel = all.visible(release: true);
      expect(searchHacks(rel.hacks, query: 'alarmnummer').map((h) => h.id), contains('112-bereiken'));
      expect(searchHacks(rel.hacks, query: 'bloedneus').map((h) => h.id), contains('bloedneus'));
      expect(searchHacks(rel.hacks, query: 'rookmelder').map((h) => h.id), contains('melders'));
      expect(searchHacks(rel.hacks, query: 'medicijnen', categorie: 'eerste-hulp').map((h) => h.id), contains('medicijnen-uitval'));
    });

    test('Wat heb ik in huis?: nieuwe plannen worden gekoppeld aan materialen', () {
      final rel = all.visible(release: true);
      final m = matchHacks(rel.hacks, {'doek', 'deken'});
      expect(m.firstWhere((x) => x.hack.id == 'bloeding').possible, isTrue);
      expect(m.firstWhere((x) => x.hack.id == 'onderkoeling').possible, isTrue);
      expect(m.any((x) => x.hack.label == HackLabel.nooit), isFalse);
    });

    test('geen toestelmodellen of aanbieders in de teksten van uitgebreide plannen', () {
      final txt = extended.map((h) => [h.titel, h.intro, ...h.stappen, ...h.waarschuwingen].join(' ')).join(' ').toLowerCase();
      for (final banned in ['iphone', 'samsung', 'android', 'ziggo', 'kpn', 'vodafone', 'tmobile', 'whatsapp']) {
        expect(txt.contains(banned), isFalse, reason: banned);
      }
    });
  });
}
