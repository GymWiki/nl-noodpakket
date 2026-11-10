/// Domeinmodellen van de documentenkluis (los van de opslag).
library;

import '../../../core/l10n/strings.dart';

const vaultMetaVersion = 1;

class VaultType {
  const VaultType({required this.id, required this.label, this.identity = false, this.builtin = true});
  final String id, label;

  /// Identiteitsdocument: bij delen wordt een watermerk en BSN-tip aangeboden.
  final bool identity;
  final bool builtin;

  Map<String, Object?> toJson() => {'id': id, 'label': label, 'identity': identity};
  factory VaultType.fromJson(Map<String, dynamic> j) => VaultType(
        id: j['id'] as String,
        label: j['label'] as String,
        identity: j['identity'] == true,
        builtin: false,
      );
}

/// Voorgestelde types (labels staan hier als data; eigen types komen erbij).
const builtinTypes = <VaultType>[
  VaultType(id: 'passport', label: S.vaultTypePassport, identity: true),
  VaultType(id: 'idcard', label: S.vaultTypeIdCard, identity: true),
  VaultType(id: 'driving', label: S.vaultTypeDriving, identity: true),
  VaultType(id: 'residence', label: S.vaultTypeResidence, identity: true),
  VaultType(id: 'health_ins', label: S.vaultTypeHealthIns),
  VaultType(id: 'policy_home', label: S.vaultTypePolicyHome),
  VaultType(id: 'policy_car', label: S.vaultTypePolicyCar),
  VaultType(id: 'policy_liability', label: S.vaultTypePolicyLiability),
  VaultType(id: 'medication', label: S.vaultTypeMedication),
  VaultType(id: 'medical', label: S.vaultTypeMedical),
  VaultType(id: 'gp_pharmacy', label: S.vaultTypeGp),
  VaultType(id: 'pet', label: S.vaultTypePet),
  VaultType(id: 'ownership', label: S.vaultTypeOwnership),
  VaultType(id: 'other', label: S.vaultTypeOther),
];

class VaultPage {
  const VaultPage({required this.fileId, this.thumbId, required this.mime});
  final String fileId;
  final String? thumbId;

  /// image/jpeg, image/png, image/heic of application/pdf
  final String mime;

  bool get isPdf => mime == 'application/pdf';

  Map<String, Object?> toJson() => {'f': fileId, if (thumbId != null) 't': thumbId, 'm': mime};
  factory VaultPage.fromJson(Map<String, dynamic> j) =>
      VaultPage(fileId: j['f'] as String, thumbId: j['t'] as String?, mime: j['m'] as String);
}

class VaultDocument {
  const VaultDocument({
    required this.id,
    required this.title,
    required this.typeId,
    this.owner = '',
    this.expiry,
    this.note = '',
    this.pages = const [],
    this.emergency = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id, title, typeId, owner, note;
  final DateTime? expiry;
  final List<VaultPage> pages;

  /// Staat in de "Noodmap" (eerst nodig bij evacuatie).
  final bool emergency;
  final DateTime createdAt, updatedAt;

  VaultDocument copyWith({
    String? title,
    String? typeId,
    String? owner,
    DateTime? expiry,
    bool clearExpiry = false,
    String? note,
    List<VaultPage>? pages,
    bool? emergency,
    DateTime? updatedAt,
  }) =>
      VaultDocument(
        id: id,
        title: title ?? this.title,
        typeId: typeId ?? this.typeId,
        owner: owner ?? this.owner,
        expiry: clearExpiry ? null : (expiry ?? this.expiry),
        note: note ?? this.note,
        pages: pages ?? this.pages,
        emergency: emergency ?? this.emergency,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'type': typeId,
        'owner': owner,
        if (expiry != null) 'expiry': expiry!.toIso8601String(),
        'note': note,
        'pages': [for (final p in pages) p.toJson()],
        'emergency': emergency,
        'created': createdAt.toIso8601String(),
        'updated': updatedAt.toIso8601String(),
      };

  factory VaultDocument.fromJson(Map<String, dynamic> j) => VaultDocument(
        id: j['id'] as String,
        title: j['title'] as String,
        typeId: j['type'] as String,
        owner: (j['owner'] as String?) ?? '',
        expiry: j['expiry'] == null ? null : DateTime.parse(j['expiry'] as String),
        note: (j['note'] as String?) ?? '',
        pages: [
          for (final p in (j['pages'] as List? ?? const []))
            VaultPage.fromJson(Map<String, dynamic>.from(p as Map)),
        ],
        emergency: j['emergency'] == true,
        createdAt: DateTime.parse(j['created'] as String),
        updatedAt: DateTime.parse(j['updated'] as String),
      );
}

/// Alle gegevens die versleuteld in één blob staan.
class VaultMeta {
  const VaultMeta({this.documents = const [], this.customTypes = const []});
  final List<VaultDocument> documents;
  final List<VaultType> customTypes;

  List<VaultType> get allTypes => [...builtinTypes, ...customTypes];

  VaultType? typeOf(String id) {
    for (final t in allTypes) {
      if (t.id == id) return t;
    }
    return null;
  }

  VaultMeta copyWith({List<VaultDocument>? documents, List<VaultType>? customTypes}) =>
      VaultMeta(documents: documents ?? this.documents, customTypes: customTypes ?? this.customTypes);

  /// Alle bestanden (pagina's en miniaturen) die bij de documenten horen.
  Set<String> get allFileIds => {
        for (final d in documents)
          for (final p in d.pages) ...[p.fileId, ?p.thumbId],
      };

  Map<String, Object?> toJson() => {
        'v': vaultMetaVersion,
        'docs': [for (final d in documents) d.toJson()],
        'types': [for (final t in customTypes) t.toJson()],
      };

  /// Gooit [FormatException] bij een te nieuwe of beschadigde structuur.
  factory VaultMeta.fromJson(Map<String, dynamic> j) {
    final v = j['v'];
    if (v is! int || v < 1) throw const FormatException('ongeldige versie');
    if (v > vaultMetaVersion) throw const FormatException('te nieuw');
    return VaultMeta(
      documents: [
        for (final d in (j['docs'] as List? ?? const []))
          VaultDocument.fromJson(Map<String, dynamic>.from(d as Map)),
      ],
      customTypes: [
        for (final t in (j['types'] as List? ?? const []))
          VaultType.fromJson(Map<String, dynamic>.from(t as Map)),
      ],
    );
  }
}

/// Verloopstatus van een document (alleen "verlopen" krijgt een alarmkleur).
enum DocExpiry { none, ok, soon, expired }

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

DocExpiry docExpiryStatus(VaultDocument d, DateTime now, {int soonDays = 90}) {
  if (d.expiry == null) return DocExpiry.none;
  final today = _day(now);
  final e = _day(d.expiry!);
  if (e.isBefore(today)) return DocExpiry.expired;
  if (e.difference(today).inDays <= soonDays) return DocExpiry.soon;
  return DocExpiry.ok;
}

/// Tijdstippen (10:00) waarop een neutrale herinnering moet afgaan. Alleen
/// momenten in de toekomst; [leadDays] is bijv. [90, 30].
List<DateTime> expiryReminderTimes(
  Iterable<VaultDocument> docs,
  List<int> leadDays,
  DateTime now,
) {
  final out = <DateTime>{};
  for (final d in docs) {
    final e = d.expiry;
    if (e == null) continue;
    for (final lead in leadDays) {
      final t = DateTime(e.year, e.month, e.day - lead, 10);
      if (t.isAfter(now)) out.add(t);
    }
  }
  final list = out.toList()..sort();
  return list;
}
