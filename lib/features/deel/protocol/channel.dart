import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'noise.dart';
import 'session_payload.dart';

class ShareException implements Exception {
  const ShareException(this.code, [this.detail = '']);
  final ShareError code;
  final String detail;
  @override
  String toString() => 'ShareException($code, $detail)';
}

enum ShareError {
  timeout,
  closed,
  badFrame,
  badHandshake,
  badMessage,
  tooLarge,
  hashMismatch,
  denied,
  unsupported,
  aborted,
}

/// Leest en schrijft frames met een 4-byte lengtekop (big endian) op een socket.
class FrameChannel {
  FrameChannel(this._socket) {
    _sub = _socket.listen(_onData, onError: (_) => _fail(), onDone: _fail, cancelOnError: true);
  }

  final Socket _socket;
  late final StreamSubscription<Uint8List> _sub;
  final _buf = BytesBuilder(copy: false);
  final _frames = Queue<Uint8List>();
  Completer<void>? _waiter;
  bool _closed = false;
  ShareError? _error;

  void _onData(Uint8List data) {
    _buf.add(data);
    while (true) {
      final bytes = _buf.toBytes();
      if (bytes.length < 4) {
        _keep(bytes);
        break;
      }
      final len = ByteData.sublistView(bytes).getUint32(0, Endian.big);
      if (len > ShareLimits.maxFrameBytes) {
        _error = ShareError.badFrame;
        _fail();
        return;
      }
      if (bytes.length < 4 + len) {
        _keep(bytes);
        break;
      }
      _frames.add(Uint8List.sublistView(bytes, 4, 4 + len));
      _keep(Uint8List.sublistView(bytes, 4 + len));
    }
    _wake();
  }

  void _keep(Uint8List rest) {
    _buf.clear();
    if (rest.isNotEmpty) _buf.add(Uint8List.fromList(rest));
  }

  void _fail() {
    _closed = true;
    _wake();
  }

  void _wake() {
    final w = _waiter;
    _waiter = null;
    if (w != null && !w.isCompleted) w.complete();
  }

  Future<Uint8List> read(Duration timeout) async {
    final deadline = DateTime.now().add(timeout);
    while (_frames.isEmpty) {
      if (_closed) throw ShareException(_error ?? ShareError.closed);
      final left = deadline.difference(DateTime.now());
      if (left <= Duration.zero) throw const ShareException(ShareError.timeout);
      _waiter = Completer<void>();
      await _waiter!.future.timeout(left, onTimeout: () {});
    }
    return _frames.removeFirst();
  }

  void write(List<int> frame) {
    if (_closed) throw const ShareException(ShareError.closed);
    if (frame.length > ShareLimits.maxFrameBytes) throw const ShareException(ShareError.tooLarge);
    final h = ByteData(4)..setUint32(0, frame.length, Endian.big);
    _socket.add(h.buffer.asUint8List());
    _socket.add(frame);
  }

  Future<void> close() async {
    _closed = true;
    _wake();
    try {
      await _sub.cancel();
      await _socket.flush();
      await _socket.close().timeout(const Duration(seconds: 1));
    } catch (_) {}
    try {
      _socket.destroy();
    } catch (_) {}
  }
}

/// Berichttypen na de handshake (versleuteld; 1 byte type + inhoud).
class Msg {
  Msg._();
  static const hello = 1;
  static const decision = 2;
  static const manifest = 3;
  static const select = 4;
  static const ack = 5;
  static const done = 6;
  static const abort = 7;
  static const blobBegin = 16;
  static const blobChunk = 17;
  static const blobEnd = 18;
}

/// Versleutelde laag boven [FrameChannel]: elk frame is AEAD met een teller.
class SecureChannel {
  SecureChannel(this._ch, this._t);
  final FrameChannel _ch;
  final NoiseTransport _t;

  String? _code;
  Future<String> get code async => _code ??= await _t.verificationCode();

  Future<void> send(int type, [List<int> body = const []]) async {
    final plain = Uint8List.fromList([type, ...body]);
    _ch.write(await _t.send.encrypt(const [], plain));
  }

  Future<void> sendJson(int type, Object json) => send(type, utf8.encode(jsonEncode(json)));

  Future<(int, Uint8List)> recv(Duration timeout) async {
    final frame = await _ch.read(timeout);
    final Uint8List plain;
    try {
      plain = await _t.receive.decrypt(const [], frame);
    } on NoiseException {
      throw const ShareException(ShareError.badFrame, 'ontsleutelen mislukt');
    }
    if (plain.isEmpty) throw const ShareException(ShareError.badMessage);
    return (plain[0], Uint8List.sublistView(plain, 1));
  }

  Map<String, dynamic> parseJson(Uint8List body, {int maxBytes = ShareLimits.maxManifestBytes}) {
    if (body.length > maxBytes) throw const ShareException(ShareError.tooLarge);
    try {
      final j = jsonDecode(utf8.decode(body));
      if (j is! Map<String, dynamic>) throw const FormatException();
      return j;
    } catch (_) {
      throw const ShareException(ShareError.badMessage);
    }
  }

  Future<void> close() => _ch.close();
}
