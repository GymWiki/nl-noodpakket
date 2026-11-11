import 'dart:typed_data';

import 'channel.dart';
import 'session_payload.dart';

/// Eén pagina van een document, zoals de afzender die aanbiedt.
class OfferedPage {
  const OfferedPage({required this.size, required this.sha256, required this.read});
  final int size;
  final String sha256;

  /// Leest en ontsleutelt de bytes pas op het moment van versturen (alleen in geheugen).
  final Future<Uint8List> Function() read;
}

class OfferedDocument {
  const OfferedDocument({
    required this.id,
    required this.title,
    required this.typeId,
    this.owner = '',
    this.expiry,
    required this.pages,
  });
  final String id, title, typeId, owner;
  final DateTime? expiry;
  final List<OfferedPage> pages;
  int get totalBytes => pages.fold<int>(0, (a, p) => a + p.size);
}

class ShareOffer {
  const ShareOffer({
    required this.senderName,
    this.planJson,
    this.planId = '',
    this.planVersion = 0,
    this.planUpdatedAt,
    this.planSections = const [],
    this.docs = const [],
  });
  final String senderName;

  /// Plan als JSON (planbestandsformaat); null als geen plan wordt gedeeld.
  final String? planJson;
  final String planId;
  final int planVersion;
  final DateTime? planUpdatedAt;
  final List<String> planSections;
  final List<OfferedDocument> docs;
}

class ManifestDoc {
  const ManifestDoc({
    required this.id,
    required this.title,
    required this.typeId,
    required this.owner,
    required this.expiry,
    required this.pageSizes,
    required this.pageHashes,
  });
  final String id, title, typeId, owner;
  final DateTime? expiry;
  final List<int> pageSizes;
  final List<String> pageHashes;
  int get totalBytes => pageSizes.fold<int>(0, (a, b) => a + b);
}

/// Wat de ontvanger te zien krijgt voordat er iets wordt opgeslagen.
class Manifest {
  const Manifest({
    required this.senderName,
    required this.planId,
    required this.planVersion,
    required this.planUpdatedAt,
    required this.planSections,
    required this.planBytes,
    required this.planHash,
    required this.docs,
  });
  static const schema = 1;

  final String senderName, planId, planHash;
  final int planVersion, planBytes;
  final DateTime? planUpdatedAt;
  final List<String> planSections;
  final List<ManifestDoc> docs;

  bool get hasPlan => planBytes > 0;
  int get totalBytes => planBytes + docs.fold<int>(0, (a, d) => a + d.totalBytes);

  Map<String, Object?> toJson() => {
        'schema': schema,
        'sender': senderName,
        'planId': planId,
        'planVersion': planVersion,
        if (planUpdatedAt != null) 'planUpdatedAt': planUpdatedAt!.toUtc().toIso8601String(),
        'planSections': planSections,
        'planBytes': planBytes,
        'planHash': planHash,
        'docs': [
          for (final d in docs)
            {
              'id': d.id,
              'title': d.title,
              'type': d.typeId,
              'owner': d.owner,
              if (d.expiry != null) 'expiry': d.expiry!.toIso8601String(),
              'sizes': d.pageSizes,
              'hashes': d.pageHashes,
            },
        ],
      };

  /// Valideert onbetrouwbare invoer tegen alle limieten.
  static Manifest parse(Map<String, dynamic> j) {
    String text(Object? v, int max) {
      if (v is! String) throw const ShareException(ShareError.badMessage);
      final clean = v.replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), ' ').trim();
      if (clean.length > max) throw const ShareException(ShareError.tooLarge);
      return clean;
    }

    int integer(Object? v, int max) {
      if (v is! int || v < 0 || v > max) throw const ShareException(ShareError.tooLarge);
      return v;
    }

    String id(Object? v) {
      final s = text(v, 64);
      if (!RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(s)) throw const ShareException(ShareError.badMessage);
      return s;
    }

    String hash(Object? v) {
      if (v is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(v)) throw const ShareException(ShareError.badMessage);
      return v;
    }

    final schema = j['schema'];
    if (schema is! int || schema < 1) throw const ShareException(ShareError.badMessage);
    if (schema > Manifest.schema) throw const ShareException(ShareError.unsupported);

    final docsRaw = j['docs'];
    if (docsRaw is! List) throw const ShareException(ShareError.badMessage);
    if (docsRaw.length > ShareLimits.maxDocuments) throw const ShareException(ShareError.tooLarge);

    final docs = <ManifestDoc>[];
    final seen = <String>{};
    for (final raw in docsRaw) {
      if (raw is! Map<String, dynamic>) throw const ShareException(ShareError.badMessage);
      final sizesRaw = raw['sizes'], hashesRaw = raw['hashes'];
      if (sizesRaw is! List || hashesRaw is! List || sizesRaw.length != hashesRaw.length || sizesRaw.isEmpty) {
        throw const ShareException(ShareError.badMessage);
      }
      if (sizesRaw.length > ShareLimits.maxPagesPerDocument) throw const ShareException(ShareError.tooLarge);
      final did = id(raw['id']);
      if (!seen.add(did)) throw const ShareException(ShareError.badMessage);
      docs.add(ManifestDoc(
        id: did,
        title: text(raw['title'], ShareLimits.maxTextLength),
        typeId: text(raw['type'], 64),
        owner: text(raw['owner'] ?? '', ShareLimits.maxTextLength),
        expiry: raw['expiry'] is String ? DateTime.tryParse(raw['expiry'] as String) : null,
        pageSizes: [for (final s in sizesRaw) integer(s, ShareLimits.maxPageBytes)],
        pageHashes: [for (final h in hashesRaw) hash(h)],
      ));
    }

    final planBytes = integer(j['planBytes'] ?? 0, ShareLimits.maxPlanBytes);
    final sections = j['planSections'];
    final m = Manifest(
      senderName: text(j['sender'] ?? '', 40),
      planId: planBytes == 0 ? '' : id(j['planId']),
      planVersion: integer(j['planVersion'] ?? 0, 1 << 30),
      planUpdatedAt: j['planUpdatedAt'] is String ? DateTime.tryParse(j['planUpdatedAt'] as String) : null,
      planSections: sections is List ? [for (final s in sections.take(16)) text(s, 32)] : const [],
      planBytes: planBytes,
      planHash: planBytes == 0 ? '' : hash(j['planHash']),
      docs: docs,
    );
    if (m.totalBytes > ShareLimits.maxTotalBytes) throw const ShareException(ShareError.tooLarge);
    return m;
  }
}

/// Wat de ontvanger kiest om over te nemen.
class ReceiverSelection {
  const ReceiverSelection({this.plan = false, this.docIds = const {}});
  final bool plan;
  final Set<String> docIds;
}

class ReceivedDocument {
  const ReceivedDocument(this.meta, this.pages);
  final ManifestDoc meta;
  final List<Uint8List> pages;
}

String friendlyDeviceName(String raw) {
  final clean = raw.replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), ' ').trim();
  if (clean.isEmpty) return '';
  return clean.length > 40 ? clean.substring(0, 40) : clean;
}
