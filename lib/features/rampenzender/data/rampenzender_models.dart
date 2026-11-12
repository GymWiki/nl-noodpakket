import 'dart:convert';

/// Gebundelde rampenzender-data (assets/radio/rampenzenders.json). Zuiver Dart, geen netwerk.
class RadioSource {
  const RadioSource({required this.id, required this.title, required this.publisher, required this.url});
  final String id, title, publisher, url;
}

class Broadcaster {
  const Broadcaster({
    required this.id,
    required this.name,
    required this.stationName,
    required this.national,
    required this.website,
    required this.lastReviewed,
  });
  final String id, name, stationName, website;
  final bool national;
  final DateTime lastReviewed;
}

class DabInfo {
  const DabInfo({required this.channel, required this.searchName});
  final String channel, searchName;
}

class Transmission {
  const Transmission({
    required this.id,
    required this.broadcasterId,
    required this.area,
    required this.fm,
    required this.dab,
    required this.notes,
    required this.sourceIds,
    required this.lastReviewed,
    required this.singleSource,
  });
  final String id, broadcasterId, area, notes;
  final List<double> fm;
  final DabInfo? dab;
  final List<String> sourceIds;
  final DateTime lastReviewed;
  final bool singleSource;
}

class RadioRegion {
  const RadioRegion({
    required this.gm,
    required this.name,
    required this.aliases,
    required this.vr,
    required this.province,
    required this.broadcasterId,
    required this.areaIds,
  });
  final String gm, name, vr, province, broadcasterId;
  final List<String> aliases;

  /// null = niet aantoonbaar aan één gebied te koppelen: toon alle gebieden van de omroep.
  final List<String>? areaIds;
}

/// Wat de app toont voor één gekozen gemeente.
class RadioResult {
  const RadioResult({
    required this.region,
    required this.broadcaster,
    required this.areas,
    required this.mustChoose,
    required this.national,
    required this.nationalTx,
    required this.checkedOn,
  });
  final RadioRegion region;

  /// De regionale omroep van deze gemeente (ook als er geen gecontroleerde frequentie is).
  final Broadcaster? broadcaster;
  final List<Transmission> areas;

  /// Meer dan één gebied (geen aantoonbare koppeling naar één gebied): de gebruiker kiest zelf.
  final bool mustChoose;
  final Broadcaster national;
  final Transmission nationalTx;
  final DateTime checkedOn;

  bool get hasRegional => broadcaster != null && areas.any((a) => a.fm.isNotEmpty);

  /// Eén vaste frequentie als de koppeling eenduidig is, anders null.
  double? get firstFm => areas.isEmpty || areas.first.fm.isEmpty ? null : areas.first.fm.first;
}

class RadioData {
  RadioData._(this.generatedAt, this.sources, this.broadcasters, this.transmissions, this.regions);

  final DateTime generatedAt;
  final List<RadioSource> sources;
  final List<Broadcaster> broadcasters;
  final List<Transmission> transmissions;
  final List<RadioRegion> regions;

  factory RadioData.parse(String jsonText) {
    final j = jsonDecode(jsonText) as Map<String, dynamic>;
    DateTime d(Object? s) => DateTime.parse('$s');
    List<Map<String, dynamic>> l(String k) =>
        [for (final x in j[k] as List) Map<String, dynamic>.from(x as Map)];
    return RadioData._(
      d(j['generatedAt']),
      [
        for (final s in l('sources'))
          RadioSource(id: '${s['id']}', title: '${s['title']}', publisher: '${s['publisher']}', url: '${s['url']}')
      ],
      [
        for (final b in l('broadcasters'))
          Broadcaster(
            id: '${b['id']}',
            name: '${b['name']}',
            stationName: '${b['stationName']}',
            national: b['type'] == 'landelijk',
            website: '${b['website']}',
            lastReviewed: d(b['lastReviewed']),
          )
      ],
      [
        for (final t in l('transmissions'))
          Transmission(
            id: '${t['id']}',
            broadcasterId: '${t['broadcasterId']}',
            area: '${t['area']}',
            fm: [for (final f in (t['fmMHz'] as List? ?? const [])) (f as num).toDouble()],
            dab: t['dab'] == null
                ? null
                : DabInfo(
                    channel: '${(t['dab'] as Map)['channel']}',
                    searchName: '${(t['dab'] as Map)['searchName']}'),
            notes: '${t['notes'] ?? ''}',
            sourceIds: [for (final s in (t['sourceIds'] as List? ?? const [])) '$s'],
            lastReviewed: d(t['lastReviewed']),
            singleSource: t['verification'] == 'enkele-bron',
          )
      ],
      [
        for (final r in l('regions'))
          RadioRegion(
            gm: '${r['gm']}',
            name: '${r['name']}',
            aliases: [for (final a in (r['aliases'] as List? ?? const [])) '$a'],
            vr: '${r['vr']}',
            province: '${r['province']}',
            broadcasterId: '${r['broadcasterId']}',
            areaIds: r['areaIds'] == null ? null : [for (final a in (r['areaIds'] as List)) '$a'],
          )
      ],
    );
  }

  Broadcaster get national => broadcasters.firstWhere((b) => b.national);
  Transmission get nationalTx => transmissions.firstWhere((t) => t.broadcasterId == national.id);

  RadioRegion? regionByGm(String? gm) {
    if (gm == null) return null;
    for (final r in regions) {
      if (r.gm == gm) return r;
    }
    return null;
  }

  Broadcaster? _b(String id) {
    for (final b in broadcasters) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Resultaat voor een gemeente. Een regio zonder gecontroleerde FM-data valt terug op NPO Radio 1.
  RadioResult? resultFor(String? gm) {
    final r = regionByGm(gm);
    if (r == null) return null;
    final b = _b(r.broadcasterId);
    final all = [for (final t in transmissions) if (t.broadcasterId == r.broadcasterId && t.fm.isNotEmpty) t];
    var areas = r.areaIds == null ? all : [for (final t in all) if (r.areaIds!.contains(t.id)) t];
    if (areas.isEmpty) areas = all;
    final ok = b != null && areas.isNotEmpty;
    final dates = [
      nationalTx.lastReviewed,
      if (ok) ...[for (final a in areas) a.lastReviewed],
    ]..sort();
    return RadioResult(
      region: r,
      broadcaster: b,
      areas: ok ? areas : const [],
      mustChoose: ok && areas.length > 1,
      national: national,
      nationalTx: nationalTx,
      checkedOn: dates.last,
    );
  }

  /// Zoeken op gemeentenaam of bekende bijnaam, zonder hoofdletters, accenten, streepjes en apostrofs.
  List<RadioRegion> search(String query, {int limit = 40}) {
    final q = normalizeSearch(query);
    if (q.isEmpty) return const [];
    final starts = <RadioRegion>[], inside = <RadioRegion>[];
    for (final r in regions) {
      final names = [r.name, ...r.aliases].map(normalizeSearch);
      if (names.any((n) => n.startsWith(q))) {
        starts.add(r);
      } else if (names.any((n) => n.contains(q))) {
        inside.add(r);
      }
    }
    return [...starts, ...inside].take(limit).toList();
  }
}

String normalizeSearch(String s) {
  const from = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyy';
  final b = StringBuffer();
  for (final c in s.toLowerCase().runes) {
    final ch = String.fromCharCode(c);
    final i = from.indexOf(ch);
    if (i >= 0) {
      b.write(to[i]);
    } else if (ch == "'" || ch == '’' || ch == '-') {
      continue;
    } else {
      b.write(ch);
    }
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// "90.8" zoals het op een radio staat.
String fmtMHz(double v) => v.toStringAsFixed(1);

const _ones = [
  'nul', 'een', 'twee', 'drie', 'vier', 'vijf', 'zes', 'zeven', 'acht', 'negen', 'tien', 'elf', 'twaalf',
  'dertien', 'veertien', 'vijftien', 'zestien', 'zeventien', 'achttien', 'negentien'
];
const _tens = ['', '', 'twintig', 'dertig', 'veertig', 'vijftig', 'zestig', 'zeventig', 'tachtig', 'negentig'];

String _below100(int n) {
  if (n < 20) return _ones[n];
  final t = n ~/ 10, o = n % 10;
  if (o == 0) return _tens[t];
  final en = (o == 2 || o == 3) ? 'ën' : 'en';
  return '${_ones[o]}$en${_tens[t]}';
}

/// Nederlandse uitspraak voor 0 tot 199 (genoeg voor FM-frequenties van 87 tot 108).
String dutchNumber(int n) {
  if (n < 100) return _below100(n);
  final rest = n - 100;
  return rest == 0 ? 'honderd' : 'honderd${_below100(rest)}';
}

/// 90.8 wordt "negentig komma acht megahertz": voor schermlezers.
String speakMHz(double v) {
  final s = fmtMHz(v);
  final p = s.split('.');
  return '${dutchNumber(int.parse(p[0]))} komma ${_ones[int.parse(p[1])]} megahertz';
}

/// "7C" wordt "zeven C".
String speakDab(String channel) {
  final m = RegExp(r'^(\d+)([A-F])$').firstMatch(channel);
  if (m == null) return channel;
  return '${_below100(int.parse(m.group(1)!))} ${m.group(2)}';
}
