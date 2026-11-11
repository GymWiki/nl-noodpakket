import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'channel.dart';
import 'noise.dart';
import 'session_payload.dart';
import 'transfer_models.dart';

sealed class SenderEvent {
  const SenderEvent();
}

/// Een toestel heeft verbonden en de handshake is geslaagd. De gebruiker moet
/// de code vergelijken en [ShareSenderSession.approve] of [deny] kiezen.
class SenderPeer extends SenderEvent {
  const SenderPeer(this.code, this.deviceName);
  final String code, deviceName;
}

class SenderProgress extends SenderEvent {
  const SenderProgress(this.doneBytes, this.totalBytes);
  final int doneBytes, totalBytes;
}

class SenderFinished extends SenderEvent {
  const SenderFinished({required this.planSent, required this.documents});
  final bool planSent;
  final int documents;
}

class SenderFailed extends SenderEvent {
  const SenderFailed(this.error);
  final ShareError error;
}

class SenderExpired extends SenderEvent {
  const SenderExpired();
}

class SenderCancelled extends SenderEvent {
  const SenderCancelled();
}

Future<String> sha256Hex(List<int> data) async {
  final h = await Sha256().hash(data);
  return h.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Tijdelijke server op het toestel van de afzender. Actief zolang het
/// QR-scherm open is; één verbinding, daarna sluit de server direct.
class ShareSenderSession {
  ShareSenderSession._(this._offer, this._server, this.payload, this._window, this._idle);

  final ShareOffer _offer;
  final ServerSocket _server;
  final SessionPayload payload;
  final Duration _window, _idle;

  final _events = StreamController<SenderEvent>.broadcast();
  Stream<SenderEvent> get events => _events.stream;

  Timer? _expiry;
  bool _handling = false, _ended = false;
  int _failedAttempts = 0;
  SecureChannel? _channel;
  final _decision = Completer<bool>();

  /// Wat in de QR-code staat.
  String get qrData => payload.encode();
  DateTime? expiresAt;

  static Future<ShareSenderSession> start({
    required ShareOffer offer,
    required InternetAddress address,
    Duration window = ShareLimits.connectWindow,
    Duration idle = ShareLimits.idleTimeout,
    Random? random,
  }) async {
    // Alleen op de gekozen lokale interface, willekeurige poort.
    final server = await ServerSocket.bind(address, 0, shared: false);
    final payload = SessionPayload.create(host: address.address, port: server.port, random: random);
    final s = ShareSenderSession._(offer, server, payload, window, idle);
    s.expiresAt = DateTime.now().add(window);
    server.listen(s._onConnection, onError: (_) {}, cancelOnError: false);
    s._expiry = Timer(window, () {
      if (!s._ended && s._channel == null) s._end(const SenderExpired());
    });
    return s;
  }

  void _onConnection(Socket socket) {
    if (_ended || _handling) {
      socket.destroy(); // één verbinding tegelijk
      return;
    }
    _handling = true;
    unawaited(_run(socket));
  }

  Future<void> _run(Socket socket) async {
    final ch = FrameChannel(socket);
    try {
      final hs = NoiseHandshake.responder(payload.secret, payload.prologue);
      try {
        final m1 = await ch.read(ShareLimits.handshakeTimeout);
        await hs.readMessage1(m1);
        ch.write(await hs.writeMessage2());
      } on NoiseException {
        // Fout geheim of vervalste verbinding: sessie meteen sluiten.
        await ch.close();
        return _end(const SenderFailed(ShareError.badHandshake));
      } on ShareException {
        await ch.close();
        _handling = false;
        if (++_failedAttempts >= ShareLimits.maxFailedAttempts) {
          _end(const SenderFailed(ShareError.badHandshake));
        }
        return;
      }
      final t = await hs.finish();
      final sc = SecureChannel(ch, t);
      _channel = sc;
      _expiry?.cancel();
      // Geen nieuwe verbindingen meer.
      await _server.close();

      final (type, body) = await sc.recv(ShareLimits.handshakeTimeout);
      if (type != Msg.hello) throw const ShareException(ShareError.badMessage);
      final name = friendlyDeviceName((sc.parseJson(body)['name'] as String?) ?? '');
      _events.add(SenderPeer(await sc.code, name.isEmpty ? '?' : name));

      final ok = await _decision.future.timeout(_window, onTimeout: () => false);
      await sc.sendJson(Msg.decision, {'ok': ok});
      if (!ok) {
        await sc.close();
        return _end(const SenderFailed(ShareError.denied));
      }
      await _transfer(sc);
    } on ShareException catch (e) {
      _end(SenderFailed(e.code));
    } catch (_) {
      _end(const SenderFailed(ShareError.closed));
    } finally {
      await ch.close();
    }
  }

  Future<void> _transfer(SecureChannel sc) async {
    final planBytes = _offer.planJson == null ? Uint8List(0) : Uint8List.fromList(utf8.encode(_offer.planJson!));
    final manifest = Manifest(
      senderName: friendlyDeviceName(_offer.senderName),
      planId: _offer.planId,
      planVersion: _offer.planVersion,
      planUpdatedAt: _offer.planUpdatedAt,
      planSections: _offer.planSections,
      planBytes: planBytes.length,
      planHash: planBytes.isEmpty ? '' : await sha256Hex(planBytes),
      planSectionHashes: _offer.planSectionHashes,
      docs: [
        for (final d in _offer.docs)
          ManifestDoc(
            id: d.id,
            title: d.title,
            typeId: d.typeId,
            owner: d.owner,
            expiry: d.expiry,
            pageSizes: [for (final p in d.pages) p.size],
            pageHashes: [for (final p in d.pages) p.sha256],
          ),
      ],
    );
    final mj = jsonEncode(manifest.toJson());
    if (utf8.encode(mj).length > ShareLimits.maxManifestBytes) throw const ShareException(ShareError.tooLarge);
    await sc.send(Msg.manifest, utf8.encode(mj));

    // De ontvanger bekijkt het voorbeeld en kiest; dat mag even duren.
    final (t, b) = await sc.recv(const Duration(minutes: 5));
    if (t == Msg.abort) throw const ShareException(ShareError.aborted);
    if (t != Msg.select) throw const ShareException(ShareError.badMessage);
    final sel = sc.parseJson(b);
    final wantPlan = sel['plan'] == true && planBytes.isNotEmpty;
    final wantIds = <String>{if (sel['docs'] is List) for (final x in sel['docs'] as List) if (x is String) x};
    final docs = [for (final d in _offer.docs) if (wantIds.contains(d.id)) d];

    final total = (wantPlan ? planBytes.length : 0) + docs.fold<int>(0, (a, d) => a + d.totalBytes);
    var done = 0;
    _events.add(SenderProgress(0, total));

    Future<void> sendBlob(String kind, String id, int index, Uint8List bytes, String hash) async {
      await sc.sendJson(Msg.blobBegin, {'kind': kind, 'id': id, 'index': index, 'size': bytes.length, 'sha': hash});
      for (var o = 0; o < bytes.length; o += ShareLimits.chunkBytes) {
        final end = min(o + ShareLimits.chunkBytes, bytes.length);
        await sc.send(Msg.blobChunk, Uint8List.sublistView(bytes, o, end));
        done += end - o;
        _events.add(SenderProgress(done, total));
      }
      await sc.send(Msg.blobEnd);
    }

    Future<void> expectAck(String id) async {
      final (at, ab) = await sc.recv(_idle);
      if (at == Msg.abort) throw const ShareException(ShareError.aborted);
      if (at != Msg.ack) throw const ShareException(ShareError.badMessage);
      final j = sc.parseJson(ab);
      if (j['id'] != id || j['ok'] != true) throw const ShareException(ShareError.aborted);
    }

    if (wantPlan) {
      await sendBlob('plan', 'plan', 0, planBytes, manifest.planHash);
      await expectAck('plan');
    }
    for (final d in docs) {
      for (var i = 0; i < d.pages.length; i++) {
        final bytes = await d.pages[i].read();
        if (bytes.length != d.pages[i].size) throw const ShareException(ShareError.hashMismatch);
        await sendBlob('page', d.id, i, bytes, d.pages[i].sha256);
      }
      await expectAck(d.id);
    }
    await sc.send(Msg.done);
    // Wacht op de bevestiging van de ontvanger, zodat het laatste bericht zeker aankomt.
    try {
      await sc.recv(_idle);
    } catch (_) {}
    _end(SenderFinished(planSent: wantPlan, documents: docs.length));
  }

  /// De afzender tikt "Toestaan" na het vergelijken van de code.
  void approve() {
    if (!_decision.isCompleted) _decision.complete(true);
  }

  void deny() {
    if (!_decision.isCompleted) _decision.complete(false);
  }

  Future<void> cancel() async {
    if (_ended) return;
    try {
      await _channel?.send(Msg.abort);
    } catch (_) {}
    _end(const SenderCancelled());
  }

  void _end(SenderEvent last) {
    if (_ended) return;
    _ended = true;
    _expiry?.cancel();
    if (!_decision.isCompleted) _decision.complete(false);
    unawaited(_server.close().catchError((Object _) => _server));
    unawaited(_channel?.close());
    _events.add(last);
    unawaited(_events.close());
  }
}
