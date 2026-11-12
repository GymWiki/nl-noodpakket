import '../rampenzender_strings.dart';
import 'rampenzender_models.dart';

/// Regels voor de meterkastkaart en het noodplan-document ("Radio"-regel).
/// Zuivere functie: geen gokwerk. Zonder eenduidig gebied staan alle gebieden erin.
List<String> radioDocLines(RadioResult? res, {String? areaId}) {
  if (res == null) return const [];
  final out = <String>[];
  final b = res.broadcaster;
  if (b != null && res.hasRegional) {
    final chosen = areaId == null ? null : res.areas.where((a) => a.id == areaId).firstOrNull;
    final areas = chosen != null ? [chosen] : res.areas;
    String fm(Transmission t) => t.fm.map(fmtMHz).join(' of ');
    if (areas.length == 1) {
      out.add(RZ.planRadioLine(res.region.name, b.stationName, fm(areas.first)));
    } else {
      out.add('${res.region.name}: ${b.stationName}, FM per gebied');
      for (final a in areas) {
        out.add('${a.area}: ${fm(a)}');
      }
    }
    final dab = areas.first.dab;
    if (dab != null) out.add('${RZ.dabLabel} ${RZ.dabChannel(dab.channel)} (${dab.searchName})');
  } else {
    out.add(RZ.tuneLineNoData);
  }
  final n = res.nationalTx;
  out.add('${res.national.name}: ${RZ.nationalFm}${n.dab == null ? '' : ' ${RZ.dabLabel} ${RZ.dabChannel(n.dab!.channel)}.'}');
  return out;
}
