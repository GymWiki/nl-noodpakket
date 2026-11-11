import 'dart:convert';

import '../../../core/l10n/strings.dart';
import 'plan_models.dart';

/// Bestandsformaat voor het delen van een noodplan tussen app-gebruikers.
const planFileApp = 'nl-noodpakket-plan';
const planFileSchemaVersion = 1;

/// Welke onderdelen er in het gedeelde document komen. Zorg en foto's staan
/// standaard uit.
class ShareOptions {
  const ShareOptions({
    this.persons = true,
    this.contacts = true,
    this.places = true,
    this.agreements = true,
    this.home = true,
    this.care = false,
    this.photos = false,
  });

  final bool persons, contacts, places, agreements, home, care, photos;

  ShareOptions copyWith({
    bool? persons,
    bool? contacts,
    bool? places,
    bool? agreements,
    bool? home,
    bool? care,
    bool? photos,
  }) =>
      ShareOptions(
        persons: persons ?? this.persons,
        contacts: contacts ?? this.contacts,
        places: places ?? this.places,
        agreements: agreements ?? this.agreements,
        home: home ?? this.home,
        care: care ?? this.care,
        photos: photos ?? this.photos,
      );
}

String contactRoleLabel(String role) => switch (role) {
      PlanKeys.roleOutside => S.planRoleOutside,
      PlanKeys.roleEmergency => S.planRoleEmergency,
      PlanKeys.roleNeighbour => S.planRoleNeighbour,
      PlanKeys.roleDoctor => S.planRoleDoctor,
      PlanKeys.roleSchool => S.planRoleSchool,
      PlanKeys.roleVet => S.planRoleVet,
      _ => role,
    };

String placeLabel(String kind) => switch (kind) {
      PlanKeys.placeHome => S.planPlaceHome,
      PlanKeys.placeNeighbourhood => S.planPlaceNeighbourhood,
      PlanKeys.placeOutside => S.planPlaceOutside,
      _ => kind,
    };

String agreementLabel(String key) => switch (key) {
      PlanKeys.checkin => S.planAgrCheckin,
      PlanKeys.kids => S.planAgrKids,
      PlanKeys.pets => S.planAgrPets,
      PlanKeys.vulnerable => S.planAgrVulnerable,
      PlanKeys.noteLeft => S.planAgrNoteLeft,
      PlanKeys.infoSource => S.planAgrInfoSource,
      PlanKeys.otherAgreements => S.planAgrOther,
      PlanKeys.helpMe => S.planNbHelpMe,
      PlanKeys.iHelp => S.planNbIHelp,
      PlanKeys.neighbourDeals => S.planNbDeals,
      _ => key,
    };

String locationLabel(String key) => switch (key) {
      PlanKeys.noodpakket => S.planLocNoodpakket,
      PlanKeys.firstAid => S.planLocFirstAid,
      PlanKeys.radio => S.planLocRadio,
      PlanKeys.flashlight => S.planLocFlashlight,
      PlanKeys.meterkast => S.planLocMeterkast,
      PlanKeys.waterMain => S.planLocWater,
      PlanKeys.gasMain => S.planLocGas,
      PlanKeys.powerMain => S.planLocPower,
      PlanKeys.smokeDetectors => S.planLocSmoke,
      PlanKeys.escapeRoutes => S.planLocEscape,
      PlanKeys.shelter => S.planLocShelter,
      _ => key,
    };

String ageGroupLabel(String g) => switch (g) {
      'child' => S.planAgeChild,
      'baby' => S.planAgeBaby,
      'senior' => S.planAgeSenior,
      _ => S.planAgeAdult,
    };

// ---------------------------------------------------------------- tekst

/// Korte tekstsamenvatting, handig voor een berichtenapp.
String planSummaryText(Plan p, ShareOptions o, DateTime now) {
  final b = StringBuffer();
  final name = p.householdName.trim();
  b.writeln(name.isEmpty ? S.planDocTitleNoName : S.planDocTitle(name));
  b.writeln(S.planDocDate(_date(now)));
  b.writeln(S.planDoc112);
  void section(String title, List<String> lines) {
    if (lines.isEmpty) return;
    b
      ..writeln()
      ..writeln(title);
    lines.forEach(b.writeln);
  }

  if (o.contacts) {
    section(S.planDocContacts, [
      for (final c in p.contacts)
        if (c.phone.trim().isNotEmpty || c.name.trim().isNotEmpty)
          '- ${contactRoleLabel(c.role)}: ${[c.name.trim(), if (c.relation.trim().isNotEmpty) '(${c.relation.trim()})', c.phone.trim()].where((s) => s.isNotEmpty).join(' ')}',
    ]);
  }
  if (o.places) {
    section(S.planDocPlaces, [
      for (final k in PlanKeys.placeKinds)
        if (!(p.place(k)?.isEmpty ?? true))
          '- ${placeLabel(k)}: ${[p.place(k)!.address.trim(), p.place(k)!.notes.trim()].where((s) => s.isNotEmpty).join(', ')}',
    ]);
  }
  if (o.agreements) {
    section(S.planDocAgreements, [
      for (final k in [...PlanKeys.agreementKeys, ...PlanKeys.neighbourKeys])
        if (p.agreement(k).isNotEmpty) '- ${agreementLabel(k)}: ${p.agreement(k)}',
    ]);
  }
  if (o.home) {
    section(S.planDocHome, [
      for (final k in PlanKeys.homeKeys)
        if (p.locationText(k).isNotEmpty) '- ${locationLabel(k)}: ${p.locationText(k)}',
    ]);
  }
  if (o.persons) {
    section(S.planDocPersons, [
      for (final m in p.members)
        if (m.name.trim().isNotEmpty)
          '- ${m.name.trim()}${m.isPet ? ' (${S.planPetLabel})' : ' (${ageGroupLabel(m.ageGroup)})'}${m.needsHelp ? ', ${S.planNeedsHelpShort}' : ''}',
    ]);
  }
  if (o.care) {
    section(S.planDocCare, [
      if (p.medication.trim().isNotEmpty) '- ${S.planCareMedication}: ${p.medication.trim()}',
      if (p.devices.trim().isNotEmpty) '- ${S.planCareDevices}: ${p.devices.trim()}',
      if (p.allergies.trim().isNotEmpty) '- ${S.planCareAllergies}: ${p.allergies.trim()}',
      if (p.caregiving.trim().isNotEmpty) '- ${S.planCareCaregiving}: ${p.caregiving.trim()}',
    ]);
  }
  b
    ..writeln()
    ..writeln(S.planDocFooter);
  return b.toString().trimRight();
}

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

// ----------------------------------------------------------------- bestand

/// Zet het plan om naar JSON. [photos] (sleutel -> base64) wordt alleen
/// opgenomen als [ShareOptions.photos] aan staat.
String planToJsonString(
  Plan p,
  ShareOptions o, {
  required DateTime now,
  Map<String, String> photos = const {},
  String? planId,
  int? version,
  String? sender,
}) {
  final map = <String, Object?>{
    'app': planFileApp,
    'schemaVersion': planFileSchemaVersion,
    'exportedAt': now.toIso8601String(),
    // Alleen bij delen tussen toestellen: zo herkent de ontvanger een nieuwe versie van hetzelfde plan.
    'planId': ?planId,
    'version': ?version,
    'sender': ?sender,
    'householdName': p.householdName,
    if (o.persons)
      'members': [
        for (final m in p.members)
          {
            'name': m.name,
            'pet': m.isPet,
            'ageGroup': m.ageGroup,
            'needsHelp': m.needsHelp,
            'notes': m.notes,
          },
      ],
    if (o.contacts)
      'contacts': [
        for (final c in p.contacts)
          {'role': c.role, 'name': c.name, 'relation': c.relation, 'phone': c.phone},
      ],
    if (o.places)
      'places': [
        for (final e in p.places.values)
          if (!e.isEmpty) {'kind': e.kind, 'address': e.address, 'notes': e.notes},
      ],
    if (o.agreements)
      'agreements': {
        for (final e in p.agreements.entries)
          if (e.value.trim().isNotEmpty) e.key: e.value,
      },
    if (o.home)
      'locations': [
        for (final l in p.locations.values)
          if (!l.isEmpty)
            {
              'key': l.key,
              'body': l.body,
              if (o.photos && photos[l.key] != null) 'photo': photos[l.key],
            },
      ],
    if (o.care)
      'care': {
        'medication': p.medication,
        'devices': p.devices,
        'allergies': p.allergies,
        'caregiving': p.caregiving,
        'documents': p.documents,
      },
  };
  return const JsonEncoder.withIndent('  ').convert(map);
}

enum PlanFileError { invalid, tooNew }

class PlanFileException implements Exception {
  const PlanFileException(this.error);
  final PlanFileError error;
  @override
  String toString() => 'PlanFileException($error)';
}

/// Resultaat van het inlezen van een gedeeld bestand.
class ParsedPlanFile {
  const ParsedPlanFile({
    required this.plan,
    required this.photos,
    required this.exportedAt,
    this.planId = '',
    this.version = 0,
    this.sender = '',
  });
  final String planId, sender;
  final int version;
  final Plan plan;
  /// sleutel -> base64 (alleen als het bestand foto's bevat)
  final Map<String, String> photos;
  final DateTime? exportedAt;

  int get memberCount => plan.members.length;
  int get contactCount => plan.contacts.length;
}

ParsedPlanFile parsePlanFile(String source) {
  final Object? j;
  try {
    j = jsonDecode(source);
  } catch (_) {
    throw const PlanFileException(PlanFileError.invalid);
  }
  if (j is! Map<String, dynamic> || j['app'] != planFileApp) {
    throw const PlanFileException(PlanFileError.invalid);
  }
  final version = j['schemaVersion'];
  if (version is! int) throw const PlanFileException(PlanFileError.invalid);
  if (version > planFileSchemaVersion) throw const PlanFileException(PlanFileError.tooNew);
  if (version < 1) throw const PlanFileException(PlanFileError.invalid);

  try {
    String s(Object? v) => v is String ? v : '';
    final photos = <String, String>{};
    final locations = <String, PlanLocation>{};
    for (final l in (j['locations'] as List? ?? const [])) {
      final m = l as Map<String, dynamic>;
      final key = s(m['key']);
      if (key.isEmpty) continue;
      locations[key] = PlanLocation(key: key, body: s(m['body']));
      if (m['photo'] is String) photos[key] = m['photo'] as String;
    }
    final care = (j['care'] as Map<String, dynamic>?) ?? const {};
    final plan = Plan(
      householdName: s(j['householdName']),
      members: [
        for (final m in (j['members'] as List? ?? const []))
          PlanMember(
            name: s((m as Map)['name']),
            isPet: m['pet'] == true,
            ageGroup: s(m['ageGroup']).isEmpty ? 'adult' : s(m['ageGroup']),
            needsHelp: m['needsHelp'] == true,
            notes: s(m['notes']),
          ),
      ],
      contacts: [
        for (final c in (j['contacts'] as List? ?? const []))
          PlanContact(
            role: s((c as Map)['role']).isEmpty ? PlanKeys.roleEmergency : s(c['role']),
            name: s(c['name']),
            relation: s(c['relation']),
            phone: s(c['phone']),
          ),
      ],
      places: {
        for (final e in (j['places'] as List? ?? const []))
          s((e as Map)['kind']): PlanPlace(
              kind: s(e['kind']), address: s(e['address']), notes: s(e['notes'])),
      }..remove(''),
      agreements: {
        for (final e in ((j['agreements'] as Map<String, dynamic>?) ?? const {}).entries)
          e.key: s(e.value),
      },
      locations: locations,
      medication: s(care['medication']),
      devices: s(care['devices']),
      allergies: s(care['allergies']),
      caregiving: s(care['caregiving']),
      documents: s(care['documents']),
    );
    return ParsedPlanFile(
      plan: plan,
      photos: photos,
      exportedAt: DateTime.tryParse(s(j['exportedAt'])),
      planId: s(j['planId']),
      version: j['version'] is int ? j['version'] as int : 0,
      sender: s(j['sender']),
    );
  } on PlanFileException {
    rethrow;
  } catch (_) {
    throw const PlanFileException(PlanFileError.invalid);
  }
}

/// Voegt een binnengekomen plan samen met het eigen plan: eigen invulling blijft
/// staan, ontbrekende onderdelen worden aangevuld, nieuwe mensen en contacten
/// worden toegevoegd (geen dubbelen).
Plan mergePlans(Plan own, Plan incoming) {
  bool sameMember(PlanMember a, PlanMember b) =>
      a.name.trim().toLowerCase() == b.name.trim().toLowerCase() && a.isPet == b.isPet;
  bool sameContact(PlanContact a, PlanContact b) =>
      a.role == b.role &&
      (a.phone.trim().isNotEmpty && a.phone.trim() == b.phone.trim() ||
          a.name.trim().toLowerCase() == b.name.trim().toLowerCase());

  final members = [...own.members];
  for (final m in incoming.members) {
    if (m.name.trim().isEmpty || members.any((e) => sameMember(e, m))) continue;
    members.add(m);
  }
  final contacts = [...own.contacts];
  for (final c in incoming.contacts) {
    if (contacts.any((e) => sameContact(e, c))) continue;
    contacts.add(c);
  }
  final places = {...own.places};
  incoming.places.forEach((k, v) {
    if (places[k]?.isEmpty ?? true) places[k] = v;
  });
  final agreements = {...own.agreements};
  incoming.agreements.forEach((k, v) {
    if ((agreements[k] ?? '').trim().isEmpty) agreements[k] = v;
  });
  final locations = {...own.locations};
  incoming.locations.forEach((k, v) {
    if (locations[k]?.isEmpty ?? true) locations[k] = v;
  });
  String keep(String a, String b) => a.trim().isNotEmpty ? a : b;
  return Plan(
    householdName: keep(own.householdName, incoming.householdName),
    members: members,
    contacts: contacts,
    places: places,
    agreements: agreements,
    locations: locations,
    medication: keep(own.medication, incoming.medication),
    devices: keep(own.devices, incoming.devices),
    allergies: keep(own.allergies, incoming.allergies),
    caregiving: keep(own.caregiving, incoming.caregiving),
    documents: keep(own.documents, incoming.documents),
    skipped: own.skipped,
    wizardStep: own.wizardStep,
    sharedVersion: own.sharedVersion,
    createdAt: own.createdAt,
    updatedAt: own.updatedAt,
    lastSharedAt: own.lastSharedAt,
    lastConfirmedAt: own.lastConfirmedAt,
  );
}
