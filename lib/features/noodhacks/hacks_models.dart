import 'dart:convert';

const hacksSchemaVersion = 1;

enum HackLabel { veilig, letop, nooit }

HackLabel _label(String s) => switch (s) {
      'veilig' => HackLabel.veilig,
      'letop' => HackLabel.letop,
      'nooit' => HackLabel.nooit,
      _ => throw FormatException('onbekend label: $s'),
    };

class HackSource {
  const HackSource({required this.naam, required this.url});
  final String naam, url;
}

class HackCategory {
  const HackCategory({required this.id, required this.titel, required this.icoon});
  final String id, titel, icoon;
}

class HackMaterial {
  const HackMaterial({required this.id, required this.label, required this.icoon});
  final String id, label, icoon;
}

class Hack {
  const Hack({
    required this.id,
    required this.categorie,
    required this.titel,
    required this.label,
    required this.intro,
    required this.materialen,
    required this.stappen,
    required this.waarschuwingen,
    required this.reden,
    required this.alternatiefIds,
    required this.bronnen,
    required this.bronType,
    required this.lastReviewed,
    required this.trefwoorden,
    required this.gerelateerdeNoodgevallen,
    required this.gerelateerdeChecklistItemIds,
    this.freePreview = false,
  });

  final String id, categorie, titel, intro, reden, bronType;
  final HackLabel label;
  final List<String> materialen, stappen, waarschuwingen, alternatiefIds, trefwoorden;
  final List<String> gerelateerdeNoodgevallen, gerelateerdeChecklistItemIds;
  final List<HackSource> bronnen;
  final DateTime lastReviewed;

  /// Proefhack: volledige inhoud ook zonder Pro.
  final bool freePreview;

  /// Gratis te lezen: proefhacks en alle mythes (waarschuwingen staan nooit achter een betaalmuur).
  bool get isFree => freePreview || categorie == 'mythes' || label == HackLabel.nooit;

  static List<String> _strings(Map<String, dynamic> j, String k) {
    final v = j[k];
    if (v is! List) throw FormatException('veld "$k" ontbreekt');
    return [for (final e in v) e.toString()];
  }

  static String _str(Map<String, dynamic> j, String k) {
    final v = j[k];
    if (v is! String) throw FormatException('veld "$k" ontbreekt');
    return v;
  }

  factory Hack.fromJson(Map<String, dynamic> j) => Hack(
        id: _str(j, 'id'),
        categorie: _str(j, 'categorie'),
        titel: _str(j, 'titel'),
        label: _label(_str(j, 'label')),
        intro: _str(j, 'intro'),
        materialen: _strings(j, 'materialen'),
        stappen: _strings(j, 'stappen'),
        waarschuwingen: _strings(j, 'waarschuwingen'),
        reden: (j['reden'] as String?) ?? '',
        alternatiefIds: _strings(j, 'alternatiefIds'),
        bronnen: [
          for (final b in (j['bronnen'] as List? ?? const []))
            HackSource(naam: _str(b as Map<String, dynamic>, 'naam'), url: _str(b, 'url')),
        ],
        bronType: _str(j, 'bronType'),
        lastReviewed: DateTime.tryParse(_str(j, 'lastReviewed')) ??
            (throw const FormatException('lastReviewed is geen datum')),
        trefwoorden: _strings(j, 'trefwoorden'),
        gerelateerdeNoodgevallen: _strings(j, 'gerelateerdeNoodgevallen'),
        gerelateerdeChecklistItemIds: _strings(j, 'gerelateerdeChecklistItemIds'),
        freePreview: j['freePreview'] == true,
      );
}

class HackData {
  const HackData({
    required this.categories,
    required this.materials,
    required this.hacks,
  });

  final List<HackCategory> categories;
  final List<HackMaterial> materials;
  final List<Hack> hacks;

  Hack? byId(String id) {
    for (final h in hacks) {
      if (h.id == id) return h;
    }
    return null;
  }

  HackMaterial? material(String id) {
    for (final m in materials) {
      if (m.id == id) return m;
    }
    return null;
  }

  List<Hack> forEmergency(String wikiId) => [
        for (final h in hacks)
          if (h.gerelateerdeNoodgevallen.contains(wikiId)) h,
      ];

  List<Hack> forItem(String itemId) => [
        for (final h in hacks)
          if (h.gerelateerdeChecklistItemIds.contains(itemId)) h,
      ];

  factory HackData.parse(String source) {
    final j = jsonDecode(source);
    if (j is! Map<String, dynamic>) throw const FormatException('geen object');
    final v = j['schemaVersion'];
    if (v != hacksSchemaVersion) throw FormatException('onbekende schemaversie: $v');
    return HackData(
      categories: [
        for (final c in (j['categories'] as List))
          HackCategory(
            id: (c as Map<String, dynamic>)['id'] as String,
            titel: c['titel'] as String,
            icoon: c['icoon'] as String,
          ),
      ],
      materials: [
        for (final m in (j['materialen'] as List))
          HackMaterial(
            id: (m as Map<String, dynamic>)['id'] as String,
            label: m['label'] as String,
            icoon: m['icoon'] as String,
          ),
      ],
      hacks: [
        for (final h in (j['hacks'] as List)) Hack.fromJson(h as Map<String, dynamic>),
      ],
    );
  }
}

/// Inhoudelijke controle (leeg = ok). [checklistIds] en [wikiIds] zijn de
/// bestaande id's uit de checklist-seed en de noodgevallen-wiki.
List<String> validateHacks(HackData d, {required Set<String> checklistIds, required Set<String> wikiIds}) {
  final errors = <String>[];
  final ids = <String>{};
  final cats = {for (final c in d.categories) c.id};
  final mats = {for (final m in d.materials) m.id};
  if (cats.length != d.categories.length) errors.add('dubbele categorie');
  if (mats.length != d.materials.length) errors.add('dubbel materiaal');

  for (final h in d.hacks) {
    final p = '[${h.id}]';
    if (!ids.add(h.id)) errors.add('$p dubbele id');
    if (h.titel.trim().isEmpty) errors.add('$p lege titel');
    if (h.intro.trim().isEmpty) errors.add('$p lege intro');
    if (!cats.contains(h.categorie)) errors.add('$p onbekende categorie ${h.categorie}');
    if (h.stappen.isEmpty) errors.add('$p minimaal 1 stap');
    if ([...h.stappen, ...h.waarschuwingen].any((s) => s.trim().isEmpty)) errors.add('$p lege stap of waarschuwing');
    for (final m in h.materialen) {
      if (!mats.contains(m)) errors.add('$p onbekend materiaal $m');
    }
    for (final c in h.gerelateerdeChecklistItemIds) {
      if (!checklistIds.contains(c)) errors.add('$p onbekend checklist-item $c');
    }
    for (final w in h.gerelateerdeNoodgevallen) {
      if (!wikiIds.contains(w)) errors.add('$p onbekend noodgeval $w');
    }
    if (h.label == HackLabel.nooit && h.reden.trim().isEmpty) {
      errors.add('$p een "nooit"-hack heeft een reden nodig');
    }
    if (h.label == HackLabel.nooit && h.categorie != 'mythes') {
      errors.add('$p een "nooit"-hack hoort bij de mythes');
    }
    if (h.bronnen.isEmpty) errors.add('$p geen bron');
    if (h.bronType != 'officieel' && h.bronType != 'algemeen') errors.add('$p ongeldig bronType');
    for (final b in h.bronnen) {
      final u = Uri.tryParse(b.url);
      if (u == null || u.scheme != 'https' || u.host.isEmpty) errors.add('$p ongeldige url ${b.url}');
    }
  }
  final all = {for (final h in d.hacks) h.id};
  for (final h in d.hacks) {
    for (final a in h.alternatiefIds) {
      if (!all.contains(a)) errors.add('[${h.id}] onbekend alternatief $a');
    }
  }
  return errors;
}

String _fold(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[áàâä]'), 'a')
    .replaceAll(RegExp('[íìîï]'), 'i')
    .replaceAll(RegExp('[óòôö]'), 'o')
    .replaceAll(RegExp('[úùûü]'), 'u');

/// Zoekt op titel en trefwoorden, met optioneel filter op label en categorie.
List<Hack> searchHacks(
  List<Hack> all, {
  String query = '',
  HackLabel? label,
  String? categorie,
}) {
  final q = _fold(query.trim());
  return [
    for (final h in all)
      if ((label == null || h.label == label) &&
          (categorie == null || h.categorie == categorie) &&
          (q.isEmpty || _fold(h.titel).contains(q) || h.trefwoorden.any((k) => _fold(k).contains(q))))
        h,
  ];
}

class HackMatch {
  const HackMatch(this.hack, this.missing);
  final Hack hack;

  /// Materiaal-id's die de gebruiker nog mist (leeg = direct te doen).
  final List<String> missing;
  bool get possible => missing.isEmpty;
}

/// "Wat heb ik in huis?": welke hacks kun je doen met deze materialen?
/// "Nooit"-hacks (mythes) komen er nooit in. Volgorde: direct te doen eerst,
/// dan minste ontbrekend; binnen die groep "veilig" voor "let op".
List<HackMatch> matchHacks(List<Hack> hacks, Set<String> owned) {
  final out = [
    for (final h in hacks)
      if (h.label != HackLabel.nooit)
        HackMatch(h, [for (final m in h.materialen) if (!owned.contains(m)) m]),
  ];
  out.sort((a, b) {
    final p = (a.possible ? 0 : 1).compareTo(b.possible ? 0 : 1);
    if (p != 0) return p;
    final m = a.missing.length.compareTo(b.missing.length);
    if (m != 0) return m;
    return a.hack.label.index.compareTo(b.hack.label.index);
  });
  return out;
}
