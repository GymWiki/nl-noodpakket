import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../../noodplan/domain/plan_models.dart';
import '../../noodplan/domain/plan_share.dart';

/// Secties van een plan zoals ze in het voorbeeld en de updatemelding genoemd worden.
class ShareSection {
  ShareSection._();
  static const persons = 'persons';
  static const contacts = 'contacts';
  static const places = 'places';
  static const agreements = 'agreements';
  static const home = 'home';
  static const care = 'care';
  static const all = [persons, contacts, places, agreements, home, care];
}

enum VersionRelation { newer, same, older }

/// Hoger = bijwerken, gelijk of lager = al up-to-date.
VersionRelation compareVersions({required int existing, required int incoming}) {
  if (incoming > existing) return VersionRelation.newer;
  if (incoming == existing) return VersionRelation.same;
  return VersionRelation.older;
}

/// Welke secties zijn aanwezig in een plan (voor het voorbeeldscherm).
List<String> sectionsOf(Plan p) => [
      if (p.members.any((m) => m.name.trim().isNotEmpty)) ShareSection.persons,
      if (p.contacts.isNotEmpty) ShareSection.contacts,
      if (p.places.values.any((e) => !e.isEmpty)) ShareSection.places,
      if (p.agreements.values.any((a) => a.trim().isNotEmpty)) ShareSection.agreements,
      if (p.locations.values.any((l) => !l.isEmpty)) ShareSection.home,
      if (p.hasCare) ShareSection.care,
    ];

String _canon(Object? o) => jsonEncode(o);

Map<String, String> _fingerprints(Plan p) => {
      ShareSection.persons: _canon([
        for (final m in p.members) [m.name, m.isPet, m.ageGroup, m.needsHelp, m.notes],
      ]),
      ShareSection.contacts: _canon([
        for (final c in p.contacts) [c.role, c.name, c.relation, c.phone],
      ]),
      ShareSection.places: _canon({
        for (final k in (p.places.keys.toList()..sort())) k: [p.places[k]!.address, p.places[k]!.notes],
      }),
      ShareSection.agreements: _canon({
        for (final k in (p.agreements.keys.toList()..sort())) k: p.agreements[k]!.trim(),
      }),
      ShareSection.home: _canon({
        for (final k in (p.locations.keys.toList()..sort())) k: p.locations[k]!.body.trim(),
      }),
      ShareSection.care: _canon([p.medication, p.devices, p.allergies, p.caregiving, p.documents]),
    };

/// Korte hash per sectie. De afzender stuurt die mee in het manifest, zodat de ontvanger
/// vóór het binnenhalen al ziet welke secties veranderd zijn.
Future<Map<String, String>> sectionHashes(Plan p) async {
  final out = <String, String>{};
  final sha = Sha256();
  for (final e in _fingerprints(p).entries) {
    final h = await sha.hash(utf8.encode(e.value));
    out[e.key] = h.bytes.take(8).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
  return out;
}

/// Secties waarvan de hash verschilt (nieuwe of gewijzigde secties).
List<String> changedSectionsByHash(Map<String, String> old, Map<String, String> next) =>
    [for (final s in ShareSection.all) if (old[s] != next[s]) s];

/// Secties die tussen twee versies zijn gewijzigd (voor "Nieuwe versie, dit is veranderd").
List<String> changedSections(Plan old, Plan next) {
  final a = _fingerprints(old), b = _fingerprints(next);
  return [for (final s in ShareSection.all) if (a[s] != b[s]) s];
}

/// Een plan dat met mij is gedeeld (alleen-lezen).
class SharedPlan {
  const SharedPlan({
    required this.planId,
    required this.fromName,
    required this.version,
    required this.receivedAt,
    required this.json,
    this.updatedAt,
    this.sections = const [],
    this.hashes = const {},
  });

  final Map<String, String> hashes;
  final String planId, fromName, json;
  final int version;
  final DateTime receivedAt;
  final DateTime? updatedAt;
  final List<String> sections;

  ParsedPlanFile get parsed => parsePlanFile(json);
  Plan get plan => parsed.plan;

  Map<String, Object?> metaJson() => {
        'planId': planId,
        'from': fromName,
        'version': version,
        'receivedAt': receivedAt.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        'sections': sections,
        'hashes': hashes,
      };

  static SharedPlan? fromMeta(Map<String, dynamic> m, String json) {
    final id = m['planId'];
    final received = DateTime.tryParse('${m['receivedAt']}');
    if (id is! String || id.isEmpty || received == null) return null;
    return SharedPlan(
      planId: id,
      fromName: m['from'] is String ? m['from'] as String : '',
      version: m['version'] is int ? m['version'] as int : 0,
      receivedAt: received,
      updatedAt: DateTime.tryParse('${m['updatedAt']}'),
      sections: m['sections'] is List ? [for (final s in m['sections'] as List) '$s'] : const [],
      hashes: m['hashes'] is Map ? {for (final e in (m['hashes'] as Map).entries) '${e.key}': '${e.value}'} : const {},
      json: json,
    );
  }
}
