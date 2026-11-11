import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'channel.dart';
import 'noise.dart';
import 'sender.dart' show sha256Hex;
import 'session_payload.dart';
import 'transfer_models.dart';

sealed class ReceiverEvent {
  const ReceiverEvent();
}

/// Handshake geslaagd; vergelijk deze code met die op het toestel van de afzender.
class ReceiverCode extends ReceiverEvent {
  const ReceiverCode(this.code);
  final String code;
}

/// De afzender heeft toegestaan; dit is wat er wordt aangeboden.
class ReceiverManifest extends ReceiverEvent {
  const ReceiverManifest(this.manifest);
  final Manifest manifest;
}

class ReceiverProgress extends ReceiverEvent {
  const ReceiverProgress(this.doneBytes, this.totalBytes);
  final int doneBytes, totalBytes;
}

class ReceiverFinished extends ReceiverEvent {
  const ReceiverFinished({required this.planStored, required this.documents});
  final bool planStored;
  final int documents;
}

class ReceiverFailed extends ReceiverEvent {
  const ReceiverFailed(this.error);
  final ShareError error;
}

typedef PlanSink = Future<void> Function(String planJson, Manifest manifest);
typedef DocumentSink = Future<void> Function(ReceivedDocument doc);

class ShareReceiverSession {
  ShareReceiverSession._(this._payload, this._deviceName, this._onPlan, this._onDocument, this._idle);

  final SessionPayload _payload;
  final String _deviceName;
  final PlanSink _onPlan;
  final DocumentSink _onDocument;
  final Duration _idle;

  final _events = StreamController<ReceiverEvent>.broadcast();
  Stream<ReceiverEvent> get events => _events.stream;

  final _choice = Completer<ReceiverSelection?>();
  SecureChannel? _sc;
  bool _ended = false;

  /// Verbindt met de afzender (de QR-inhoud is al gevalideerd door [SessionPayload.tryParse]).
  /// De sessie loopt op de achtergrond; volg [events].
  static Future<ShareReceiverSession> connect(
    SessionPayload payload, {
    required String deviceName,
    required PlanSink onPlan,
    required DocumentSink onDocument,
    Duration idle = ShareLimits.idleTimeout,
  }) async {
    final s = ShareReceiverSession._(payload, deviceName, onPlan, onDocument, idle);
    unawaited(s._run());
    return s;
  }

  /// De ontvanger kiest wat hij overneemt (of annuleert met null).
  void choose(ReceiverSelection? selection) {
    if (!_choice.isCompleted) _choice.complete(selection);
  }

  Future<void> cancel() async {
    try {
      await _sc?.send(Msg.abort);
    } catch (_) {}
    _end(const ReceiverFailed(ShareError.aborted));
  }

  Future<void> _run() async {
    FrameChannel? ch;
    try {
      final Socket socket;
      try {
        socket = await Socket.connect(_payload.host, _payload.port, timeout: ShareLimits.handshakeTimeout);
      } catch (_) {
        throw const ShareException(ShareError.timeout, 'geen verbinding');
      }
      ch = FrameChannel(socket);
      final hs = NoiseHandshake.initiator(_payload.secret, _payload.prologue);
      ch.write(await hs.writeMessage1());
      try {
        await hs.readMessage2(await ch.read(ShareLimits.handshakeTimeout));
      } on NoiseException {
        throw const ShareException(ShareError.badHandshake);
      } on ShareException catch (e) {
        // Een afzender die direct ophangt, wijst het geheim af.
        throw ShareException(e.code == ShareError.closed ? ShareError.badHandshake : e.code);
      }
      final sc = SecureChannel(ch, await hs.finish());
      _sc = sc;
      await sc.sendJson(Msg.hello, {'name': friendlyDeviceName(_deviceName)});
      _events.add(ReceiverCode(await sc.code));

      // De afzender moet de code eerst goedkeuren.
      final (dt, db) = await sc.recv(ShareLimits.connectWindow + const Duration(seconds: 15));
      if (dt != Msg.decision || sc.parseJson(db)['ok'] != true) throw const ShareException(ShareError.denied);

      final (mt, mb) = await sc.recv(ShareLimits.idleTimeout);
      if (mt != Msg.manifest) throw const ShareException(ShareError.badMessage);
      final manifest = Manifest.parse(sc.parseJson(mb));
      _events.add(ReceiverManifest(manifest));

      final sel = await _choice.future.timeout(const Duration(minutes: 5), onTimeout: () => null);
      if (sel == null) {
        await sc.send(Msg.abort);
        throw const ShareException(ShareError.aborted);
      }
      final wantPlan = sel.plan && manifest.hasPlan;
      final docs = [for (final d in manifest.docs) if (sel.docIds.contains(d.id)) d];
      await sc.sendJson(Msg.select, {'plan': wantPlan, 'docs': [for (final d in docs) d.id]});

      final total = (wantPlan ? manifest.planBytes : 0) + docs.fold<int>(0, (a, d) => a + d.totalBytes);
      var done = 0;
      _events.add(ReceiverProgress(0, total));

      Future<Uint8List> receiveBlob(String kind, String id, int index, int size, String hash) async {
        final (bt, bb) = await sc.recv(_idle);
        if (bt == Msg.abort) throw const ShareException(ShareError.aborted);
        if (bt != Msg.blobBegin) throw const ShareException(ShareError.badMessage);
        final b = sc.parseJson(bb);
        // De afzender mag niets anders sturen dan wat in het manifest stond.
        if (b['kind'] != kind || b['id'] != id || b['index'] != index || b['size'] != size || b['sha'] != hash) {
          throw const ShareException(ShareError.badMessage);
        }
        final out = BytesBuilder(copy: false);
        while (true) {
          final (ct, cb) = await sc.recv(_idle);
          if (ct == Msg.blobEnd) break;
          if (ct != Msg.blobChunk) throw const ShareException(ShareError.badMessage);
          if (out.length + cb.length > size) throw const ShareException(ShareError.tooLarge);
          out.add(Uint8List.fromList(cb));
          done += cb.length;
          _events.add(ReceiverProgress(done, total));
        }
        final bytes = out.toBytes();
        if (bytes.length != size) throw const ShareException(ShareError.hashMismatch);
        if (await sha256Hex(bytes) != hash) throw const ShareException(ShareError.hashMismatch);
        return bytes;
      }

      var planStored = false;
      if (wantPlan) {
        final bytes = await receiveBlob('plan', 'plan', 0, manifest.planBytes, manifest.planHash);
        try {
          await _onPlan(utf8.decode(bytes), manifest);
          planStored = true;
          await sc.sendJson(Msg.ack, {'id': 'plan', 'ok': true});
        } catch (_) {
          await sc.sendJson(Msg.ack, {'id': 'plan', 'ok': false});
          throw const ShareException(ShareError.badMessage, 'plan niet verwerkt');
        }
      }
      var stored = 0;
      for (final d in docs) {
        final pages = <Uint8List>[];
        for (var i = 0; i < d.pageSizes.length; i++) {
          pages.add(await receiveBlob('page', d.id, i, d.pageSizes[i], d.pageHashes[i]));
        }
        try {
          // Pas als het hele document binnen en gecontroleerd is, gaat het naar de kluis.
          await _onDocument(ReceivedDocument(d, pages));
          stored++;
          await sc.sendJson(Msg.ack, {'id': d.id, 'ok': true});
        } catch (_) {
          await sc.sendJson(Msg.ack, {'id': d.id, 'ok': false});
          throw const ShareException(ShareError.aborted, 'document niet opgeslagen');
        }
      }
      final (et, _) = await sc.recv(_idle);
      if (et != Msg.done) throw const ShareException(ShareError.badMessage);
      await sc.send(Msg.done);
      _end(ReceiverFinished(planStored: planStored, documents: stored));
    } on ShareException catch (e) {
      _end(ReceiverFailed(e.code));
    } catch (_) {
      _end(const ReceiverFailed(ShareError.closed));
    } finally {
      await ch?.close();
    }
  }

  void _end(ReceiverEvent last) {
    if (_ended) return;
    _ended = true;
    if (!_choice.isCompleted) _choice.complete(null);
    _events.add(last);
    unawaited(_events.close());
  }
}
