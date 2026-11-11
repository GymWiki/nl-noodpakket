import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models.dart';
import '../../features/noodplan/domain/plan_models.dart';
import '../../features/noodplan/domain/plan_share.dart';
import '../db/database.dart' hide PlanContact, PlanLocation, PlanMember, PlanPlace;

Future<Directory> _defaultPhotoDir() async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'plan_photos'));
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return dir;
}

const _kPlanId = 'plan_id';
const _kPlanVersion = 'plan_version';

class PlanIdentity {
  const PlanIdentity(this.planId, this.version);
  final String planId;
  final int version;
}

/// Opslag van "Mijn noodplan". Alles lokaal; foto's staan als bestand in de
/// app-map en verlaten het toestel alleen als de gebruiker deelt.
class PlanRepository {
  PlanRepository(this._db, {Future<Directory> Function()? photoDir, DateTime Function()? clock})
      : _photoDir = photoDir ?? _defaultPhotoDir,
        _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final Future<Directory> Function() _photoDir;
  final DateTime Function() _now;

  // ------------------------------------------------------------ lezen

  Future<Plan> load() async {
    final meta = await (_db.select(_db.planMeta)..where((m) => m.id.equals(1))).getSingleOrNull();
    final members = await (_db.select(_db.planMembers)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final contacts = await (_db.select(_db.planContacts)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final places = await _db.select(_db.planPlaces).get();
    final agreements = await _db.select(_db.planAgreements).get();
    final locations = await _db.select(_db.planLocations).get();
    return Plan(
      householdName: meta?.householdName ?? '',
      medication: meta?.medication ?? '',
      devices: meta?.devices ?? '',
      allergies: meta?.allergies ?? '',
      caregiving: meta?.caregiving ?? '',
      documents: meta?.documents ?? '',
      skipped: _decodeSkipped(meta?.skipped),
      wizardStep: meta?.wizardStep ?? 0,
      sharedVersion: meta?.sharedVersion ?? 0,
      createdAt: meta?.createdAt,
      updatedAt: meta?.updatedAt,
      lastSharedAt: meta?.lastSharedAt,
      lastConfirmedAt: meta?.lastConfirmedAt,
      members: [
        for (final m in members)
          PlanMember(
            id: m.id,
            name: m.name,
            isPet: m.kind == 'pet',
            ageGroup: m.ageGroup,
            needsHelp: m.needsHelp,
            notes: m.notes,
          ),
      ],
      contacts: [
        for (final c in contacts)
          PlanContact(id: c.id, role: c.role, name: c.name, relation: c.relation, phone: c.phone),
      ],
      places: {
        for (final e in places) e.kind: PlanPlace(kind: e.kind, address: e.address, notes: e.notes),
      },
      agreements: {for (final a in agreements) a.key: a.body},
      locations: {
        for (final l in locations)
          l.key: PlanLocation(key: l.key, body: l.body, photoPath: l.photoPath),
      },
    );
  }

  Stream<Plan> watch() async* {
    yield await load();
    await for (final _ in _db.tableUpdates(TableUpdateQuery.onAllTables([
      _db.planMembers,
      _db.planContacts,
      _db.planPlaces,
      _db.planAgreements,
      _db.planLocations,
      _db.planMeta,
    ]))) {
      yield await load();
    }
  }

  Set<PlanSection> _decodeSkipped(String? s) {
    if (s == null) return {};
    try {
      final names = (jsonDecode(s) as List).cast<String>();
      return {
        for (final n in names)
          if (PlanSection.values.asNameMap()[n] != null) PlanSection.values.asNameMap()[n]!,
      };
    } catch (_) {
      return {};
    }
  }

  // ---------------------------------------------------------- schrijven

  /// Stabiele id en oplopende versie van het eigen plan, zodat een ontvanger bij
  /// delen een nieuwe versie herkent. Staat in de instellingentabel: geen schemawijziging.
  Future<PlanIdentity> identity() async {
    final id = await _raw(_kPlanId);
    final v = int.tryParse(await _raw(_kPlanVersion) ?? '') ?? 0;
    return PlanIdentity(id ?? '', v);
  }

  Future<String?> _raw(String key) async =>
      (await (_db.select(_db.settingRows)..where((r) => r.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _setRaw(String key, String value) => _db
      .into(_db.settingRows)
      .insertOnConflictUpdate(SettingRowsCompanion.insert(key: key, value: value));

  Future<void> _bumpVersion() async {
    if (await _raw(_kPlanId) == null) await _setRaw(_kPlanId, const Uuid().v4());
    final v = int.tryParse(await _raw(_kPlanVersion) ?? '') ?? 0;
    await _setRaw(_kPlanVersion, '${v + 1}');
  }

  /// Zorgt dat de metadata-rij bestaat en markeert het plan als gewijzigd.
  Future<void> _touch([PlanMetaCompanion? change]) async {
    final now = _now();
    final existing = await (_db.select(_db.planMeta)..where((m) => m.id.equals(1))).getSingleOrNull();
    await _db.into(_db.planMeta).insertOnConflictUpdate(PlanMetaCompanion(
          id: const Value(1),
          createdAt: Value(existing?.createdAt ?? now),
          updatedAt: Value(now),
          householdName: change?.householdName ?? const Value.absent(),
          medication: change?.medication ?? const Value.absent(),
          devices: change?.devices ?? const Value.absent(),
          allergies: change?.allergies ?? const Value.absent(),
          caregiving: change?.caregiving ?? const Value.absent(),
          documents: change?.documents ?? const Value.absent(),
          skipped: change?.skipped ?? const Value.absent(),
        ));
    await _bumpVersion();
  }

  /// Wijzigt metadata zonder het plan als "gewijzigd" te markeren.
  Future<void> _metaOnly(PlanMetaCompanion c) async {
    final existing = await (_db.select(_db.planMeta)..where((m) => m.id.equals(1))).getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.planMeta).insert(c.copyWith(id: const Value(1)));
    } else {
      await (_db.update(_db.planMeta)..where((m) => m.id.equals(1))).write(c);
    }
  }

  Future<void> setHouseholdName(String name) =>
      _touch(PlanMetaCompanion(householdName: Value(name)));

  Future<void> setCare({String? medication, String? devices, String? allergies, String? caregiving, String? documents}) =>
      _touch(PlanMetaCompanion(
        medication: medication == null ? const Value.absent() : Value(medication),
        devices: devices == null ? const Value.absent() : Value(devices),
        allergies: allergies == null ? const Value.absent() : Value(allergies),
        caregiving: caregiving == null ? const Value.absent() : Value(caregiving),
        documents: documents == null ? const Value.absent() : Value(documents),
      ));

  Future<void> setSkipped(PlanSection s, bool skipped, Set<PlanSection> current) {
    final next = {...current};
    skipped ? next.add(s) : next.remove(s);
    return _touch(PlanMetaCompanion(skipped: Value(jsonEncode([for (final e in next) e.name]))));
  }

  Future<void> setWizardStep(int step) => _metaOnly(PlanMetaCompanion(wizardStep: Value(step)));

  Future<void> markShared(int version) => _metaOnly(
      PlanMetaCompanion(lastSharedAt: Value(_now()), sharedVersion: Value(version)));

  Future<void> confirmAll() => _metaOnly(PlanMetaCompanion(lastConfirmedAt: Value(_now())));

  Future<int> addMember(PlanMember m) async {
    final id = await _db.into(_db.planMembers).insert(_memberCompanion(m));
    await _touch();
    return id;
  }

  PlanMembersCompanion _memberCompanion(PlanMember m) => PlanMembersCompanion.insert(
        name: Value(m.name),
        kind: Value(m.isPet ? 'pet' : 'person'),
        ageGroup: Value(m.ageGroup),
        needsHelp: Value(m.needsHelp),
        notes: Value(m.notes),
      );

  Future<void> updateMember(PlanMember m) async {
    await (_db.update(_db.planMembers)..where((t) => t.id.equals(m.id))).write(_memberCompanion(m));
    await _touch();
  }

  Future<void> deleteMember(int id) async {
    await (_db.delete(_db.planMembers)..where((t) => t.id.equals(id))).go();
    await _touch();
  }

  /// Vult het huishouden vooraf in als er nog niemand is.
  Future<void> prefillMembers(Household h, {required String Function(String ageGroup, int n) personName, required String petName}) async {
    final count = await _db.planMembers.count().getSingle();
    if (count > 0) return;
    Future<void> people(String group, int n) async {
      for (var i = 1; i <= n; i++) {
        await _db.into(_db.planMembers).insert(PlanMembersCompanion.insert(
              name: Value(personName(group, i)),
              ageGroup: Value(group),
            ));
      }
    }

    await people('adult', h.adults);
    await people('senior', h.seniors);
    await people('child', h.children);
    await people('baby', h.babies);
    for (var i = 1; i <= h.pets; i++) {
      await _db.into(_db.planMembers).insert(PlanMembersCompanion.insert(
            name: Value(h.pets == 1 ? petName : '$petName $i'),
            kind: const Value('pet'),
          ));
    }
    await _touch();
  }

  PlanContactsCompanion _contactCompanion(PlanContact c) => PlanContactsCompanion.insert(
        role: c.role,
        name: Value(c.name),
        relation: Value(c.relation),
        phone: Value(c.phone),
      );

  Future<int> addContact(PlanContact c) async {
    final id = await _db.into(_db.planContacts).insert(_contactCompanion(c));
    await _touch();
    return id;
  }

  Future<void> updateContact(PlanContact c) async {
    await (_db.update(_db.planContacts)..where((t) => t.id.equals(c.id))).write(_contactCompanion(c));
    await _touch();
  }

  Future<void> deleteContact(int id) async {
    await (_db.delete(_db.planContacts)..where((t) => t.id.equals(id))).go();
    await _touch();
  }

  Future<void> setPlace(String kind, {String? address, String? notes}) async {
    await _db.into(_db.planPlaces).insertOnConflictUpdate(PlanPlacesCompanion(
          kind: Value(kind),
          address: address == null ? const Value.absent() : Value(address),
          notes: notes == null ? const Value.absent() : Value(notes),
        ));
    await _touch();
  }

  Future<void> setAgreement(String key, String body) async {
    await _db.into(_db.planAgreements).insertOnConflictUpdate(
        PlanAgreementsCompanion(key: Value(key), body: Value(body)));
    await _touch();
  }

  Future<void> setLocation(String key, String body) async {
    await _db.into(_db.planLocations).insertOnConflictUpdate(
        PlanLocationsCompanion(key: Value(key), body: Value(body)));
    await _touch();
  }

  /// Slaat bytes van een foto op en koppelt ze aan [key]; vervangt een oude foto.
  Future<void> setLocationPhoto(String key, Uint8List bytes) async {
    final dir = await _photoDir();
    final file = File(p.join(dir.path, '${key}_${_now().microsecondsSinceEpoch}.jpg'));
    await file.writeAsBytes(bytes, flush: true);
    await _deletePhotoOf(key);
    await _db.into(_db.planLocations).insertOnConflictUpdate(
        PlanLocationsCompanion(key: Value(key), photoPath: Value(file.path)));
    await _touch();
  }

  Future<void> removeLocationPhoto(String key) async {
    await _deletePhotoOf(key);
    await (_db.update(_db.planLocations)..where((t) => t.key.equals(key)))
        .write(const PlanLocationsCompanion(photoPath: Value(null)));
    await _touch();
  }

  Future<void> _deletePhotoOf(String key) async {
    final row = await (_db.select(_db.planLocations)..where((t) => t.key.equals(key))).getSingleOrNull();
    final path = row?.photoPath;
    if (path != null) {
      try {
        final f = File(path);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
  }

  /// Wist het hele plan, inclusief foto's.
  Future<void> clear() async {
    final photos = await (_db.select(_db.planLocations)).get();
    for (final l in photos) {
      final path = l.photoPath;
      if (path == null) continue;
      try {
        final f = File(path);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
    for (final t in <TableInfo<Table, dynamic>>[
      _db.planMembers,
      _db.planContacts,
      _db.planPlaces,
      _db.planAgreements,
      _db.planLocations,
      _db.planMeta,
    ]) {
      await _db.delete(t).go();
    }
  }

  /// Foto's van de gekozen locaties als base64 (voor het app-bestand).
  Future<Map<String, String>> photosBase64(Plan plan) async {
    final out = <String, String>{};
    for (final l in plan.locations.values) {
      final path = l.photoPath;
      if (path == null) continue;
      try {
        out[l.key] = base64Encode(await File(path).readAsBytes());
      } catch (_) {}
    }
    return out;
  }

  /// Schrijft [plan] als nieuw plan weg (vervangt alles). [photos] zijn base64-foto's
  /// per locatiesleutel. Eigen fotopaden in [plan] worden overgenomen.
  Future<void> replaceAll(Plan plan, {Map<String, String> photos = const {}, bool keepMeta = true}) async {
    final old = await load();
    final keepPhotos = {
      for (final l in plan.locations.values)
        if (l.photoPath != null) l.key: l.photoPath!,
    };
    await _db.transaction(() async {
      // Verwijder alleen oude foto's die niet meer gebruikt worden.
      for (final l in old.locations.values) {
        final path = l.photoPath;
        if (path != null && !keepPhotos.containsValue(path)) {
          try {
            final f = File(path);
            if (f.existsSync()) f.deleteSync();
          } catch (_) {}
        }
      }
      for (final t in <TableInfo<Table, dynamic>>[
        _db.planMembers,
        _db.planContacts,
        _db.planPlaces,
        _db.planAgreements,
        _db.planLocations,
      ]) {
        await _db.delete(t).go();
      }
      for (final m in plan.members) {
        await _db.into(_db.planMembers).insert(_memberCompanion(m));
      }
      for (final c in plan.contacts) {
        await _db.into(_db.planContacts).insert(_contactCompanion(c));
      }
      for (final e in plan.places.values) {
        await _db.into(_db.planPlaces).insertOnConflictUpdate(PlanPlacesCompanion(
            kind: Value(e.kind), address: Value(e.address), notes: Value(e.notes)));
      }
      for (final e in plan.agreements.entries) {
        await _db.into(_db.planAgreements).insertOnConflictUpdate(
            PlanAgreementsCompanion(key: Value(e.key), body: Value(e.value)));
      }
      final dir = photos.isEmpty ? null : await _photoDir();
      for (final l in plan.locations.values) {
        String? path = l.photoPath;
        if (path == null && photos[l.key] != null && dir != null) {
          try {
            final f = File(p.join(dir.path, '${l.key}_${_now().microsecondsSinceEpoch}.jpg'));
            await f.writeAsBytes(base64Decode(photos[l.key]!), flush: true);
            path = f.path;
          } catch (_) {}
        }
        await _db.into(_db.planLocations).insertOnConflictUpdate(PlanLocationsCompanion(
            key: Value(l.key), body: Value(l.body), photoPath: Value(path)));
      }
      final now = _now();
      await _db.into(_db.planMeta).insertOnConflictUpdate(PlanMetaCompanion(
            id: const Value(1),
            householdName: Value(plan.householdName),
            medication: Value(plan.medication),
            devices: Value(plan.devices),
            allergies: Value(plan.allergies),
            caregiving: Value(plan.caregiving),
            documents: Value(plan.documents),
            skipped: Value(jsonEncode([for (final s in plan.skipped) s.name])),
            wizardStep: Value(keepMeta ? plan.wizardStep : 0),
            sharedVersion: Value(keepMeta ? plan.sharedVersion : 0),
            createdAt: Value(plan.createdAt ?? now),
            updatedAt: Value(now),
            lastSharedAt: Value(keepMeta ? plan.lastSharedAt : null),
            lastConfirmedAt: Value(keepMeta ? plan.lastConfirmedAt : null),
          ));
    });
  }

  // ------------------------------------------------------- volledige back-up

  /// Onderdeel van de algemene back-up (Instellingen); zonder foto's.
  Future<Map<String, Object?>?> backupMap() async {
    final plan = await load();
    if (!plan.hasContent && plan.createdAt == null) return null;
    return {
      'plan': jsonDecode(planToJsonString(plan, const ShareOptions(care: true), now: _now())),
      'meta': {
        'skipped': [for (final s in plan.skipped) s.name],
        'wizardStep': plan.wizardStep,
        'sharedVersion': plan.sharedVersion,
        'createdAt': plan.createdAt?.toIso8601String(),
        'updatedAt': plan.updatedAt?.toIso8601String(),
        'lastSharedAt': plan.lastSharedAt?.toIso8601String(),
        'lastConfirmedAt': plan.lastConfirmedAt?.toIso8601String(),
      },
    };
  }

  Future<void> restoreBackup(Map<String, dynamic>? data) async {
    if (data == null) {
      await clear();
      return;
    }
    final parsed = parsePlanFile(jsonEncode(data['plan']));
    final meta = (data['meta'] as Map<String, dynamic>?) ?? const {};
    DateTime? d(Object? v) => v is String ? DateTime.tryParse(v) : null;
    final base = parsed.plan;
    final plan = Plan(
      householdName: base.householdName,
      members: base.members,
      contacts: base.contacts,
      places: base.places,
      agreements: base.agreements,
      locations: base.locations,
      medication: base.medication,
      devices: base.devices,
      allergies: base.allergies,
      caregiving: base.caregiving,
      documents: base.documents,
      skipped: {
        for (final n in (meta['skipped'] as List? ?? const []))
          if (PlanSection.values.asNameMap()[n] != null) PlanSection.values.asNameMap()[n]!,
      },
      wizardStep: (meta['wizardStep'] as num?)?.toInt() ?? 0,
      sharedVersion: (meta['sharedVersion'] as num?)?.toInt() ?? 0,
      createdAt: d(meta['createdAt']),
      lastSharedAt: d(meta['lastSharedAt']),
      lastConfirmedAt: d(meta['lastConfirmedAt']),
    );
    await replaceAll(plan);
    // Behoud de oorspronkelijke wijzigingsdatum uit de back-up.
    final updated = d(meta['updatedAt']);
    if (updated != null) await _metaOnly(PlanMetaCompanion(updatedAt: Value(updated)));
  }
}
