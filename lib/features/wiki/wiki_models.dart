import 'dart:convert';

/// Ondersteunde schemaversie van assets/wiki/noodgevallen.json.
const wikiSchemaVersion = 1;

class WikiSource {
  const WikiSource({required this.naam, required this.url});
  final String naam, url;
}

class WikiContact {
  const WikiContact({required this.label, required this.nummer});
  final String label, nummer;
}

class WikiCategory {
  const WikiCategory({required this.id, required this.titel, required this.icoon});
  final String id, titel, icoon;
}

class WikiEmergency {
  const WikiEmergency({
    required this.id,
    required this.categorie,
    required this.titel,
    required this.icoon,
    required this.trefwoorden,
    required this.intro,
    required this.stappenNu,
    required this.stappenDaarna,
    required this.bel112Als,
    required this.voorbereidenItemIds,
    required this.contacten,
    required this.bronnen,
    required this.lastReviewed,
  });

  final String id, categorie, titel, icoon, intro;
  final List<String> trefwoorden, stappenNu, stappenDaarna, bel112Als;
  final List<String> voorbereidenItemIds;
  final List<WikiContact> contacten;
  final List<WikiSource> bronnen;
  final DateTime lastReviewed;

  /// Alle stappen in volgorde: eerst "Nu doen", dan "Daarna".
  List<String> get alleStappen => [...stappenNu, ...stappenDaarna];

  static List<String> _strings(Map<String, dynamic> j, String key) {
    final v = j[key];
    if (v is! List) throw FormatException('veld "$key" ontbreekt of is geen lijst');
    return [for (final e in v) e.toString()];
  }

  static String _str(Map<String, dynamic> j, String key) {
    final v = j[key];
    if (v is! String) throw FormatException('veld "$key" ontbreekt');
    return v;
  }

  factory WikiEmergency.fromJson(Map<String, dynamic> j) => WikiEmergency(
        id: _str(j, 'id'),
        categorie: _str(j, 'categorie'),
        titel: _str(j, 'titel'),
        icoon: _str(j, 'icoon'),
        intro: _str(j, 'intro'),
        trefwoorden: _strings(j, 'trefwoorden'),
        stappenNu: _strings(j, 'stappenNu'),
        stappenDaarna: _strings(j, 'stappenDaarna'),
        bel112Als: _strings(j, 'bel112Als'),
        voorbereidenItemIds: _strings(j, 'voorbereidenItemIds'),
        contacten: [
          for (final c in (j['contacten'] as List? ?? const []))
            WikiContact(
                label: _str(c as Map<String, dynamic>, 'label'),
                nummer: _str(c, 'nummer')),
        ],
        bronnen: [
          for (final b in (j['bronnen'] as List? ?? const []))
            WikiSource(
                naam: _str(b as Map<String, dynamic>, 'naam'),
                url: _str(b, 'url')),
        ],
        lastReviewed: DateTime.tryParse(_str(j, 'lastReviewed')) ??
            (throw const FormatException('lastReviewed is geen datum')),
      );
}

class WikiData {
  const WikiData({
    required this.schemaVersion,
    required this.categories,
    required this.eersteUur,
    required this.emergencies,
  });

  final int schemaVersion;
  final List<WikiCategory> categories;
  final WikiEmergency eersteUur;
  final List<WikiEmergency> emergencies;

  WikiEmergency? byId(String id) {
    if (id == eersteUur.id) return eersteUur;
    for (final e in emergencies) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Noodgevallen waarbij dit checklist-item handig is.
  List<WikiEmergency> forItem(String itemId) => [
        for (final e in emergencies)
          if (e.voorbereidenItemIds.contains(itemId)) e,
      ];

  factory WikiData.parse(String source) {
    final j = jsonDecode(source);
    if (j is! Map<String, dynamic>) {
      throw const FormatException('wiki-bestand is geen object');
    }
    final version = j['schemaVersion'];
    if (version != wikiSchemaVersion) {
      throw FormatException('onbekende schemaversie: $version');
    }
    return WikiData(
      schemaVersion: version as int,
      categories: [
        for (final c in (j['categories'] as List))
          WikiCategory(
            id: (c as Map<String, dynamic>)['id'] as String,
            titel: c['titel'] as String,
            icoon: c['icoon'] as String,
          ),
      ],
      eersteUur: WikiEmergency.fromJson(j['eersteUur'] as Map<String, dynamic>),
      emergencies: [
        for (final e in (j['noodgevallen'] as List))
          WikiEmergency.fromJson(e as Map<String, dynamic>),
      ],
    );
  }
}

/// Inhoudelijke controle van de wiki-data; geeft een lijst fouten (leeg = ok).
List<String> validateWiki(WikiData d, Set<String> checklistItemIds) {
  final errors = <String>[];
  final ids = <String>{};
  final catIds = {for (final c in d.categories) c.id};
  if (catIds.length != d.categories.length) errors.add('dubbele categorie-id');

  for (final e in [d.eersteUur, ...d.emergencies]) {
    final p = '[${e.id}]';
    if (e.id.trim().isEmpty) errors.add('$p lege id');
    if (!ids.add(e.id)) errors.add('$p dubbele id');
    if (e.titel.trim().isEmpty) errors.add('$p lege titel');
    if (e.intro.trim().isEmpty) errors.add('$p lege intro');
    if (e.icoon.trim().isEmpty) errors.add('$p leeg icoon');
    if (e.stappenNu.isEmpty) errors.add('$p minimaal 1 stap in stappenNu');
    if ([...e.stappenNu, ...e.stappenDaarna].any((s) => s.trim().isEmpty)) {
      errors.add('$p lege stap');
    }
    if (e != d.eersteUur && !catIds.contains(e.categorie)) {
      errors.add('$p onbekende categorie ${e.categorie}');
    }
    if (e.bronnen.isEmpty) errors.add('$p geen bronnen');
    for (final b in e.bronnen) {
      final u = Uri.tryParse(b.url);
      if (u == null || u.scheme != 'https' || u.host.isEmpty) {
        errors.add('$p ongeldige bron-url ${b.url}');
      }
    }
    for (final id in e.voorbereidenItemIds) {
      if (!checklistItemIds.contains(id)) {
        errors.add('$p voorbereidenItemId "$id" bestaat niet in de checklist');
      }
    }
    for (final c in e.contacten) {
      if (!RegExp(r'^[0-9+\- ]{3,20}$').hasMatch(c.nummer)) {
        errors.add('$p ongeldig nummer ${c.nummer}');
      }
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

/// Zoekt op titel en trefwoorden; lege zoekterm geeft alles terug.
List<WikiEmergency> searchEmergencies(List<WikiEmergency> all, String query) {
  final q = _fold(query.trim());
  if (q.isEmpty) return all;
  return [
    for (final e in all)
      if (_fold(e.titel).contains(q) || e.trefwoorden.any((k) => _fold(k).contains(q)))
        e,
  ];
}
