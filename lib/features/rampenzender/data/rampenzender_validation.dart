// Zuivere Dart (geen Flutter): wordt gebruikt door tool/validate_rampenzenders.dart en door de tests.

final _dabChannel = RegExp(r'^(5|6|7|8|9|10|11|12|13)[A-F]$');
final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');
final _gmCode = RegExp(r'^GM\d{4}$');
final _vrCode = RegExp(r'^VR\d{2}$');

const fmMin = 87.5, fmMax = 108.0;

/// Geeft een lijst met fouten terug; leeg betekent: de dataset is geldig.
List<String> validateRampenzenders(Map<String, dynamic> j) {
  final e = <String>[];
  void err(String s) => e.add(s);

  if (j['schemaVersion'] is! int) err('schemaVersion ontbreekt of is geen getal');
  if (!_isoDate.hasMatch('${j['generatedAt']}')) err('generatedAt is geen datum (JJJJ-MM-DD)');

  List<Map<String, dynamic>> list(String k) {
    final v = j[k];
    if (v is! List || v.isEmpty) {
      err('$k ontbreekt of is leeg');
      return const [];
    }
    return [for (final x in v) Map<String, dynamic>.from(x as Map)];
  }

  Set<String> uniqueIds(String k, List<Map<String, dynamic>> items, String idKey) {
    final ids = <String>{};
    for (final x in items) {
      final id = '${x[idKey]}';
      if (id.isEmpty || id == 'null') err('$k: item zonder $idKey');
      if (!ids.add(id)) err('$k: dubbele $idKey "$id"');
    }
    return ids;
  }

  final sources = list('sources');
  final sourceIds = uniqueIds('sources', sources, 'id');
  for (final s in sources) {
    if (!'${s['url']}'.startsWith('https://')) err('bron ${s['id']}: url moet https zijn');
    if ('${s['title']}'.isEmpty || '${s['publisher']}'.isEmpty) err('bron ${s['id']}: titel of uitgever ontbreekt');
  }

  final vrs = list('veiligheidsregios');
  final vrIds = uniqueIds('veiligheidsregios', vrs, 'id');
  for (final v in vrs) {
    if (!_vrCode.hasMatch('${v['id']}')) err('veiligheidsregio-id "${v['id']}" heeft een ongeldig formaat');
  }

  final bs = list('broadcasters');
  final bIds = uniqueIds('broadcasters', bs, 'id');
  final coveredVr = <String, String>{};
  for (final b in bs) {
    final id = '${b['id']}';
    if (b['type'] != 'regionaal' && b['type'] != 'landelijk') err('omroep $id: type moet regionaal of landelijk zijn');
    if (!'${b['website']}'.startsWith('https://')) err('omroep $id: website moet https zijn');
    if (!_isoDate.hasMatch('${b['lastReviewed']}')) err('omroep $id: lastReviewed ontbreekt');
    for (final s in (b['sourceIds'] as List? ?? const [])) {
      if (!sourceIds.contains(s)) err('omroep $id: onbekende bron $s');
    }
    final vr = (b['rampenzenderVoor'] as List? ?? const []).cast<String>();
    if (b['type'] == 'regionaal' && vr.isEmpty) err('omroep $id: regionale omroep zonder veiligheidsregio');
    for (final v in vr) {
      if (!vrIds.contains(v)) err('omroep $id: onbekende veiligheidsregio $v');
      final prev = coveredVr[v];
      if (prev != null) err('veiligheidsregio $v heeft twee omroepen: $prev en $id');
      coveredVr[v] = id;
    }
  }
  for (final v in vrIds) {
    if (!coveredVr.containsKey(v)) err('veiligheidsregio $v heeft geen rampenzender-omroep');
  }

  final ts = list('transmissions');
  final tIds = uniqueIds('transmissions', ts, 'id');
  final areasOf = <String, Set<String>>{};
  final withData = <String>{};
  for (final t in ts) {
    final id = '${t['id']}';
    final bId = '${t['broadcasterId']}';
    if (!bIds.contains(bId)) err('zending $id: onbekende omroep $bId');
    areasOf.putIfAbsent(bId, () => {}).add(id);
    if ('${t['area']}'.trim().isEmpty) err('zending $id: area ontbreekt');
    final fm = (t['fmMHz'] as List? ?? const []);
    for (final f in fm) {
      if (f is! num || f < fmMin || f > fmMax) err('zending $id: FM-frequentie $f valt buiten $fmMin tot $fmMax MHz');
    }
    if (fm.toSet().length != fm.length) err('zending $id: dubbele FM-frequentie');
    final dab = t['dab'];
    if (dab != null) {
      final ch = '${(dab as Map)['channel']}';
      if (!_dabChannel.hasMatch(ch)) err('zending $id: ongeldig DAB+-kanaal "$ch" (verwacht 5A tot 13F)');
    }
    if (fm.isEmpty && dab == null) err('zending $id: geen FM en geen DAB+');
    if (fm.isEmpty) {
      if ('${t['notes']}'.isEmpty) err('zending $id: zonder FM is een toelichting verplicht');
    } else {
      withData.add(bId);
    }
    final src = (t['sourceIds'] as List? ?? const []);
    if (src.isEmpty) err('zending $id: minstens één bron nodig');
    for (final s in src) {
      if (!sourceIds.contains(s)) err('zending $id: onbekende bron $s');
    }
    if (!_isoDate.hasMatch('${t['lastReviewed']}')) err('zending $id: lastReviewed ontbreekt of is geen datum');
    if (t['verification'] != 'meerdere-bronnen' && t['verification'] != 'enkele-bron') {
      err('zending $id: verification moet meerdere-bronnen of enkele-bron zijn');
    }
    if (t['verification'] == 'meerdere-bronnen' && src.length < 2) {
      err('zending $id: meerdere-bronnen vraagt minstens twee bronnen');
    }
  }
  // DAB-kanaal moet per omroep gelijk zijn.
  final dabOf = <String, String>{};
  for (final t in ts) {
    final dab = t['dab'];
    if (dab == null) continue;
    final b = '${t['broadcasterId']}';
    final ch = '${(dab as Map)['channel']}';
    final prev = dabOf.putIfAbsent(b, () => ch);
    if (prev != ch) err('omroep $b heeft meer dan één DAB+-kanaal ($prev en $ch)');
  }
  for (final b in bs) {
    if (!areasOf.containsKey(b['id'])) err('omroep ${b['id']} heeft geen gegevens');
  }

  final regions = list('regions');
  final gmIds = uniqueIds('regions', regions, 'gm');
  if (regions.length < 300) err('te weinig gemeenten (${regions.length})');
  for (final r in regions) {
    final gm = '${r['gm']}';
    if (!_gmCode.hasMatch(gm)) err('gemeente-id "$gm" heeft een ongeldig formaat');
    if ('${r['name']}'.isEmpty) err('gemeente $gm zonder naam');
    final vr = '${r['vr']}';
    if (!vrIds.contains(vr)) err('gemeente $gm: onbekende veiligheidsregio $vr');
    final bId = '${r['broadcasterId']}';
    if (!bIds.contains(bId)) {
      err('gemeente $gm: onbekende omroep $bId');
      continue;
    }
    if (coveredVr[vr] != bId) err('gemeente $gm: omroep $bId past niet bij veiligheidsregio $vr (${coveredVr[vr]})');
    if (!withData.contains(bId)) err('gemeente $gm: omroep $bId heeft geen FM-gegevens en geen "geen data"-markering');
    final ids = r['areaIds'];
    if (ids != null) {
      if (ids is! List || ids.isEmpty) err('gemeente $gm: areaIds moet null of een niet-lege lijst zijn');
      for (final a in (ids as List)) {
        if (!tIds.contains(a)) {
          err('gemeente $gm: onbekend gebied $a');
        } else if (!areasOf[bId]!.contains(a)) {
          err('gemeente $gm: gebied $a hoort niet bij omroep $bId');
        }
      }
    }
  }
  if (gmIds.length != regions.length) err('dubbele gemeenten');
  return e;
}
