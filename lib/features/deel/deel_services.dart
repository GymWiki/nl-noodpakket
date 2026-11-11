import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../kluis/data/vault_controller.dart';
import '../kluis/domain/vault_models.dart';
import '../noodplan/domain/plan_share.dart';
import 'domain/shared_plan_logic.dart';
import 'protocol/receiver.dart';
import 'protocol/sender.dart';
import 'protocol/session_payload.dart';
import 'protocol/transfer_models.dart';

// ------------------------------------------------------------------ authenticatie

enum ShareAuthResult { ok, failed, unavailable }

/// Elke keer opnieuw biometrie, met de toestelcode als alternatief. Niet gecachet.
abstract class ShareAuth {
  Future<ShareAuthResult> authenticate(String reason);
}

class LocalShareAuth implements ShareAuth {
  LocalShareAuth([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();
  final LocalAuthentication _auth;

  @override
  Future<ShareAuthResult> authenticate(String reason) async {
    try {
      if (!await _auth.isDeviceSupported()) return ShareAuthResult.unavailable;
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false, // toestelcode mag als er geen biometrie is
        persistAcrossBackgrounding: false,
      );
      return ok ? ShareAuthResult.ok : ShareAuthResult.failed;
    } catch (_) {
      return ShareAuthResult.failed;
    }
  }
}

final shareAuthProvider = Provider<ShareAuth>((ref) => LocalShareAuth());

// ------------------------------------------------------------------ lokaal adres

/// Zoekt het lokale (privé) IPv4-adres van wifi of hotspot. Geeft null als er
/// geen lokaal netwerk is; mobiele data en VPN-tunnels tellen niet mee.
abstract class LocalAddressFinder {
  Future<InternetAddress?> find();
}

class SystemAddressFinder implements LocalAddressFinder {
  static const _skip = ['rmnet', 'ccmni', 'pdp_ip', 'tun', 'utun', 'ipsec', 'ppp', 'dummy', 'lo', 'docker', 'veth'];

  @override
  Future<InternetAddress?> find() async {
    try {
      final ifs = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
      InternetAddress? best;
      var bestScore = -1;
      for (final i in ifs) {
        final name = i.name.toLowerCase();
        if (_skip.any(name.startsWith)) continue;
        for (final a in i.addresses) {
          if (!isPrivateIPv4(a.address) || a.address.startsWith('169.254.') || a.address.startsWith('127.')) continue;
          // wifi (wlan, en) en hotspot (ap, swlan, bridge) hebben de voorkeur
          final score = ['wlan', 'en', 'ap', 'swlan', 'bridge', 'eth'].any(name.startsWith) ? 2 : 1;
          if (score > bestScore) {
            best = a;
            bestScore = score;
          }
        }
      }
      return best;
    } catch (_) {
      return null;
    }
  }
}

final addressFinderProvider = Provider<LocalAddressFinder>((ref) => SystemAddressFinder());

// ------------------------------------------------------------------ scanner

typedef ScannerBuilder = Widget Function(BuildContext context, void Function(String code) onCode);

Widget defaultScannerBuilder(BuildContext context, void Function(String code) onCode) {
  return _CameraScanner(onCode: onCode);
}

class _CameraScanner extends StatefulWidget {
  const _CameraScanner({required this.onCode});
  final void Function(String code) onCode;

  @override
  State<_CameraScanner> createState() => _CameraScannerState();
}

class _CameraScannerState extends State<_CameraScanner> {
  // Camera pas starten als dit scherm opent (cameratoestemming bij het tikken op de knop).
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode], detectionSpeed: DetectionSpeed.noDuplicates);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          for (final b in capture.barcodes) {
            final v = b.rawValue;
            if (v != null) {
              widget.onCode(v);
              break;
            }
          }
        },
        errorBuilder: (context, error) => Center(child: Text(error.errorCode.name)),
      );
}

final qrScannerBuilderProvider = Provider<ScannerBuilder>((ref) => defaultScannerBuilder);

// ------------------------------------------------------------------ sessies (vervangbaar in tests)

typedef SenderStarter = Future<ShareSenderSession> Function(ShareOffer offer, InternetAddress address);
final senderStarterProvider = Provider<SenderStarter>(
    (ref) => (offer, address) => ShareSenderSession.start(offer: offer, address: address));

typedef ReceiverConnector = Future<ShareReceiverSession> Function(
  SessionPayload payload, {
  required String deviceName,
  required PlanSink onPlan,
  required DocumentSink onDocument,
});
final receiverConnectorProvider = Provider<ReceiverConnector>((ref) => (payload, {required deviceName, required onPlan, required onDocument}) =>
    ShareReceiverSession.connect(payload, deviceName: deviceName, onPlan: onPlan, onDocument: onDocument));

// ------------------------------------------------------------------ keuze van de afzender

class DeelDraft {
  const DeelDraft({
    this.options = const ShareOptions(),
    this.docIds = const {},
    this.name = '',
  });
  final ShareOptions options;
  final Set<String> docIds;
  final String name;

  DeelDraft copyWith({ShareOptions? options, Set<String>? docIds, String? name}) =>
      DeelDraft(options: options ?? this.options, docIds: docIds ?? this.docIds, name: name ?? this.name);

  bool get anythingPlan =>
      options.persons || options.contacts || options.places || options.agreements || options.home || options.care;
}

class DeelDraftNotifier extends Notifier<DeelDraft> {
  @override
  DeelDraft build() => const DeelDraft();
  void setOptions(ShareOptions o) => state = state.copyWith(options: o);
  void setName(String n) => state = state.copyWith(name: n);
  void setDocs(Set<String> ids) => state = state.copyWith(docIds: ids);
  void reset() => state = DeelDraft(name: state.name);
}

final deelDraftProvider = NotifierProvider<DeelDraftNotifier, DeelDraft>(DeelDraftNotifier.new);

// ------------------------------------------------------------------ aanbod samenstellen

class ShareOfferException implements Exception {
  const ShareOfferException(this.message);
  final String message;
}

/// Zet de keuze om in een aanbod. Kluisdocumenten worden alleen in het geheugen
/// ontsleuteld (voor grootte en hash) en pas bij het versturen opnieuw gelezen.
Future<ShareOffer> buildOffer({
  required PlanRepository repo,
  required VaultState vault,
  required VaultController ctl,
  required DeelDraft draft,
}) async {
  final name = draft.name.trim().isEmpty ? '' : draft.name.trim();

  String? planJson;
  var planId = '', planVersion = 0;
  DateTime? updated;
  var sections = <String>[];
  var hashes = <String, String>{};
  if (draft.anythingPlan) {
    final plan = await repo.load();
    if (plan.hasContent) {
      final id = await repo.identity();
      final photos = draft.options.photos ? await repo.photosBase64(plan) : const <String, String>{};
      planId = id.planId.isEmpty ? 'plan' : id.planId;
      planVersion = id.version;
      updated = plan.updatedAt;
      planJson = planToJsonString(
        plan,
        draft.options,
        now: DateTime.now(),
        photos: photos,
        planId: planId,
        version: planVersion,
        sender: name,
      );
      if (utf8.encode(planJson).length > ShareLimits.maxPlanBytes) {
        throw const ShareOfferException('plan te groot');
      }
      final shared = parsePlanFile(planJson).plan;
      sections = sectionsOf(shared);
      hashes = await sectionHashes(shared);
    }
  }

  final docs = <OfferedDocument>[];
  if (draft.docIds.isNotEmpty) {
    if (!vault.unlocked) throw const ShareOfferException('kluis vergrendeld');
    var total = 0;
    for (final d in vault.meta.documents.where((d) => draft.docIds.contains(d.id)).take(ShareLimits.maxDocuments)) {
      final pages = <OfferedPage>[];
      for (final p in d.pages) {
        final bytes = await ctl.readFile(p.fileId);
        total += bytes.length;
        if (bytes.length > ShareLimits.maxPageBytes || total > ShareLimits.maxTotalBytes) {
          throw const ShareOfferException('te groot');
        }
        final fileId = p.fileId;
        pages.add(OfferedPage(
          size: bytes.length,
          sha256: await sha256Hex(bytes),
          read: () => ctl.readFile(fileId),
        ));
      }
      if (pages.isEmpty || pages.length > ShareLimits.maxPagesPerDocument) continue;
      docs.add(OfferedDocument(
        id: d.id,
        title: d.title,
        typeId: d.typeId,
        owner: d.owner,
        expiry: d.expiry,
        pages: pages,
      ));
    }
  }
  if (planJson == null && docs.isEmpty) throw const ShareOfferException('niets te delen');

  return ShareOffer(
    senderName: name,
    planJson: planJson,
    planId: planId,
    planVersion: planVersion,
    planUpdatedAt: updated,
    planSections: sections,
    planSectionHashes: hashes,
    docs: docs,
  );
}

/// Naam van dit toestel zoals de ander die ziet (zelf in te stellen bij het delen).
Future<String> deviceLabel(SettingsRepository settings) async {
  final saved = await settings.getRaw('deel_naam');
  if (saved != null && saved.trim().isNotEmpty) return saved.trim();
  return Platform.isIOS ? 'iPhone of iPad' : 'Android-toestel';
}

/// Slaat een ontvangen document op in de eigen kluis: direct versleuteld met de
/// eigen kluissleutel, nooit leesbaar op schijf. Geen kluislimiet bij ontvangen
/// (net als bij het terugzetten van een back-up).
Future<void> storeReceivedDocument(VaultState vault, VaultController ctl, ReceivedDocument d) async {
  if (!vault.unlocked) throw StateError('kluis vergrendeld');
  await ctl.addDocument(NewDocument(
    title: d.meta.title.isEmpty ? 'Document' : d.meta.title,
    typeId: receiverTypeId(vault.meta, d.meta.typeId),
    owner: d.meta.owner,
    expiry: d.meta.expiry,
    pages: [for (final b in d.pages) NewPage(b)],
  ));
}

/// Vindt het kluistype dat bij de ontvanger bestaat; anders "overig".
String receiverTypeId(VaultMeta meta, String wanted) => meta.typeOf(wanted) != null ? wanted : 'other';

Uint8List noBytes() => Uint8List(0);
