// Bouwt assets/radio/rampenzenders.json uit
//   - tool/rampenzenders_curated.json  (met de hand gecontroleerde bronnen en frequenties)
//   - tool/data/cbs_gebieden_2026.json (CBS-tabel 86247NED: gemeente, provincie, veiligheidsregio)
//
// Gebruik:
//   dart run tool/generate_rampenzenders.dart                 # gebruikt de opgeslagen CBS-momentopname
//   dart run tool/generate_rampenzenders.dart --refresh-cbs   # haalt de CBS-tabel opnieuw op
//
// Zie tool/README_rampenzenders.md voor het vernieuwen van de data.
import 'dart:convert';
import 'dart:io';

import 'package:mijnnoodpakket/features/rampenzender/data/rampenzender_validation.dart';

const _cbsUrl =
    'https://opendata.cbs.nl/ODataApi/odata/86247NED/TypedDataSet?\$format=json&\$select=Code_1,Naam_2,Code_28,Naam_29,Code_48,Naam_49';
const _cbsFile = 'tool/data/cbs_gebieden_2026.json';

Future<void> main(List<String> args) async {
  if (args.contains('--refresh-cbs')) {
    final c = HttpClient();
    final r = await (await c.getUrl(Uri.parse(_cbsUrl))).close();
    if (r.statusCode != 200) {
      stderr.writeln('CBS gaf status ${r.statusCode}');
      exit(1);
    }
    final body = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
    final rows = [
      for (final x in body['value'] as List)
        {for (final e in (x as Map).entries) e.key: e.value is String ? (e.value as String).trim() : e.value}
    ];
    File(_cbsFile).writeAsStringSync(const JsonEncoder.withIndent(' ').convert(rows));
    stdout.writeln('CBS-momentopname vernieuwd: ${rows.length} gemeenten');
  }

  final cur = jsonDecode(File('tool/rampenzenders_curated.json').readAsStringSync()) as Map<String, dynamic>;
  final cbs = (jsonDecode(File(_cbsFile).readAsStringSync()) as List).cast<Map<String, dynamic>>();
  final reviewed = cur['reviewed'] as String;

  final vrName = <String, String>{};
  for (final r in cbs) {
    vrName['${r['Code_48']}'] = '${r['Naam_49']}';
  }
  final vrs = [
    for (final k in vrName.keys.toList()..sort()) {'id': k, 'name': vrName[k]}
  ];

  final broadcasters = <Map<String, dynamic>>[];
  final vrToBroadcaster = <String, String>{};
  for (final b in (cur['broadcasters'] as List).cast<Map<String, dynamic>>()) {
    for (final v in (b['vr'] as List)) {
      vrToBroadcaster[v as String] = b['id'] as String;
    }
    broadcasters.add({
      'id': b['id'],
      'name': b['name'],
      'stationName': b['stationName'],
      'type': 'regionaal',
      'website': b['website'],
      'rampenzenderVoor': b['vr'],
      'lastReviewed': reviewed,
      'sourceIds': b['sourceIds'],
    });
  }
  final nat = cur['national'] as Map<String, dynamic>;
  broadcasters.add({
    'id': nat['id'],
    'name': nat['name'],
    'stationName': nat['name'],
    'type': 'landelijk',
    'website': nat['website'],
    'rampenzenderVoor': <String>[],
    'lastReviewed': reviewed,
    'sourceIds': (nat['transmission'] as Map)['sourceIds'],
  });

  final transmissions = <Map<String, dynamic>>[];
  for (final t in (cur['transmissions'] as List).cast<Map<String, dynamic>>()) {
    transmissions.add({...t, 'lastReviewed': reviewed});
  }
  final nt = Map<String, dynamic>.from(nat['transmission'] as Map);
  transmissions.add({...nt, 'broadcasterId': nat['id'], 'lastReviewed': reviewed});

  final links = cur['areaLinks'] as Map<String, dynamic>;
  final vrLinks = (links['vr'] as Map).cast<String, dynamic>();
  final gmLinks = (links['gm'] as Map).cast<String, dynamic>();
  final single = (links['singleArea'] as List).cast<String>();
  final aliases = (cur['aliases'] as Map).cast<String, dynamic>();

  String areaOfSingle(String b) =>
      transmissions.firstWhere((t) => t['broadcasterId'] == b)['id'] as String;

  final regions = <Map<String, dynamic>>[];
  for (final r in cbs) {
    final gm = '${r['Code_1']}';
    final vr = '${r['Code_48']}';
    final b = vrToBroadcaster[vr];
    if (b == null) {
      stderr.writeln('Veiligheidsregio $vr heeft geen omroep in tool/rampenzenders_curated.json');
      exit(1);
    }
    List<String>? areas;
    if (gmLinks.containsKey(gm)) {
      areas = (gmLinks[gm] as List).cast<String>();
    } else if (vrLinks.containsKey(vr)) {
      areas = (vrLinks[vr] as List).cast<String>();
    } else if (single.contains(b)) {
      areas = [areaOfSingle(b)];
    }
    final name = '${r['Naam_2']}';
    regions.add({
      'gm': gm,
      'name': name,
      if (aliases.containsKey(name)) 'aliases': aliases[name],
      'vr': vr,
      'province': '${r['Naam_29']}',
      'broadcasterId': b,
      'areaIds': areas,
    });
  }
  regions.sort((a, b) => (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase()));

  final out = {
    'schemaVersion': 1,
    'generatedAt': reviewed,
    'sources': cur['sources'],
    'veiligheidsregios': vrs,
    'broadcasters': broadcasters,
    'transmissions': transmissions,
    'regions': regions,
  };

  final errors = validateRampenzenders(out);
  if (errors.isNotEmpty) {
    stderr.writeln('De gegenereerde dataset is ongeldig:');
    for (final e in errors) {
      stderr.writeln(' - $e');
    }
    exit(1);
  }
  Directory('assets/radio').createSync(recursive: true);
  File('assets/radio/rampenzenders.json')
      .writeAsStringSync('${const JsonEncoder.withIndent(' ').convert(out)}\n');
  stdout.writeln('assets/radio/rampenzenders.json geschreven: '
      '${broadcasters.length} omroepen, ${transmissions.length} gebieden, ${regions.length} gemeenten.');
}
