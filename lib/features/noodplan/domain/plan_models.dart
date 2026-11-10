/// Domeinmodellen van "Mijn noodplan" (los van de database-modellen).
library;

/// Vaste sleutels voor afspraken en thuislocaties.
class PlanKeys {
  PlanKeys._();

  // Afspraken (stap 4)
  static const checkin = 'checkin';
  static const kids = 'kids';
  static const pets = 'pets';
  static const vulnerable = 'vulnerable';
  static const noteLeft = 'note_left';
  static const infoSource = 'info_source';
  static const otherAgreements = 'other';
  static const agreementKeys = [
    checkin, kids, pets, vulnerable, noteLeft, infoSource, otherAgreements,
  ];

  // Buren en hulp (stap 7)
  static const helpMe = 'help_me';
  static const iHelp = 'i_help';
  static const neighbourDeals = 'neighbour_deals';
  static const neighbourKeys = [helpMe, iHelp, neighbourDeals];

  // Thuis (stap 5)
  static const noodpakket = 'noodpakket';
  static const firstAid = 'ehbo';
  static const radio = 'radio';
  static const flashlight = 'flashlight';
  static const meterkast = 'meterkast';
  static const waterMain = 'water_main';
  static const gasMain = 'gas_main';
  static const powerMain = 'power_main';
  static const smokeDetectors = 'smoke_detectors';
  static const escapeRoutes = 'escape_routes';
  static const shelter = 'shelter';
  static const homeKeys = [
    noodpakket, firstAid, radio, flashlight, meterkast, waterMain, gasMain,
    powerMain, smokeDetectors, escapeRoutes, shelter,
  ];
  /// Zonder deze is "Thuis" nog niet klaar.
  static const homeCoreKeys = [
    noodpakket, meterkast, waterMain, gasMain, powerMain, escapeRoutes,
  ];

  // Verzamelplekken (stap 3)
  static const placeHome = 'home_outside';
  static const placeNeighbourhood = 'neighbourhood';
  static const placeOutside = 'outside_region';
  static const placeKinds = [placeHome, placeNeighbourhood, placeOutside];

  // Contactrollen (stap 2)
  static const roleOutside = 'outside_region';
  static const roleEmergency = 'emergency';
  static const roleNeighbour = 'neighbour';
  static const roleDoctor = 'doctor';
  static const roleSchool = 'school';
  static const roleVet = 'vet';
  static const contactRoles = [
    roleOutside, roleEmergency, roleNeighbour, roleDoctor, roleSchool, roleVet,
  ];
}

enum PlanSection { household, contacts, places, agreements, home, care, neighbours }

enum SectionStatus { empty, partial, done, skipped }

class PlanMember {
  const PlanMember({
    this.id = 0,
    this.name = '',
    this.isPet = false,
    this.ageGroup = 'adult',
    this.needsHelp = false,
    this.notes = '',
  });
  final int id;
  final String name, ageGroup, notes;
  final bool isPet, needsHelp;

  bool get isChild => !isPet && (ageGroup == 'child' || ageGroup == 'baby');

  PlanMember copyWith({String? name, bool? isPet, String? ageGroup, bool? needsHelp, String? notes}) =>
      PlanMember(
        id: id,
        name: name ?? this.name,
        isPet: isPet ?? this.isPet,
        ageGroup: ageGroup ?? this.ageGroup,
        needsHelp: needsHelp ?? this.needsHelp,
        notes: notes ?? this.notes,
      );
}

class PlanContact {
  const PlanContact({
    this.id = 0,
    required this.role,
    this.name = '',
    this.relation = '',
    this.phone = '',
  });
  final int id;
  final String role, name, relation, phone;

  PlanContact copyWith({String? name, String? relation, String? phone}) => PlanContact(
        id: id,
        role: role,
        name: name ?? this.name,
        relation: relation ?? this.relation,
        phone: phone ?? this.phone,
      );
}

class PlanPlace {
  const PlanPlace({required this.kind, this.address = '', this.notes = ''});
  final String kind, address, notes;
  bool get isEmpty => address.trim().isEmpty && notes.trim().isEmpty;
}

class PlanLocation {
  const PlanLocation({required this.key, this.body = '', this.photoPath});
  final String key, body;
  final String? photoPath;
  bool get isEmpty => body.trim().isEmpty && photoPath == null;
}

class Plan {
  const Plan({
    this.householdName = '',
    this.members = const [],
    this.contacts = const [],
    this.places = const {},
    this.agreements = const {},
    this.locations = const {},
    this.medication = '',
    this.devices = '',
    this.allergies = '',
    this.caregiving = '',
    this.documents = '',
    this.skipped = const {},
    this.wizardStep = 0,
    this.sharedVersion = 0,
    this.createdAt,
    this.updatedAt,
    this.lastSharedAt,
    this.lastConfirmedAt,
  });

  final String householdName, medication, devices, allergies, caregiving, documents;
  final List<PlanMember> members;
  final List<PlanContact> contacts;
  final Map<String, PlanPlace> places;
  final Map<String, String> agreements;
  final Map<String, PlanLocation> locations;
  final Set<PlanSection> skipped;
  final int wizardStep, sharedVersion;
  final DateTime? createdAt, updatedAt, lastSharedAt, lastConfirmedAt;

  List<PlanMember> get people => [for (final m in members) if (!m.isPet) m];
  List<PlanMember> get pets => [for (final m in members) if (m.isPet) m];

  List<PlanContact> contactsOf(String role) =>
      [for (final c in contacts) if (c.role == role) c];

  String agreement(String key) => agreements[key]?.trim() ?? '';
  String locationText(String key) => locations[key]?.body.trim() ?? '';
  PlanPlace? place(String kind) => places[kind];

  bool get hasCare => [medication, devices, allergies, caregiving]
      .any((s) => s.trim().isNotEmpty);

  /// Bevat het plan iets (los van lege standaardrijen)?
  bool get hasContent =>
      members.isNotEmpty ||
      contacts.isNotEmpty ||
      places.values.any((p) => !p.isEmpty) ||
      agreements.values.any((a) => a.trim().isNotEmpty) ||
      locations.values.any((l) => !l.isEmpty) ||
      hasCare ||
      householdName.trim().isNotEmpty ||
      skipped.isNotEmpty;

  /// Gewijzigd sinds het laatst gedeeld is (alleen als er ooit gedeeld is).
  bool get changedSinceShared =>
      lastSharedAt != null && updatedAt != null && updatedAt!.isAfter(lastSharedAt!);
}
