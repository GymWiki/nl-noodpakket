import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Noise_NNpsk0_25519_ChaChaPoly_SHA256, volgens Noise Protocol Framework
/// (revisie 34). Eigen primitieven zijn er niet: X25519, ChaCha20-Poly1305,
/// SHA-256 en HMAC komen uit het pakket `cryptography`.
///
/// - psk0: het eenmalige geheim uit de QR-code wordt vóór alles gemengd, dus
///   wie het geheim niet heeft kan de handshake niet afmaken.
/// - NN: beide kanten gebruiken verse tijdelijke sleutels, dus latere
///   onthulling van het QR-geheim ontsleutelt een opgenomen sessie niet
///   (forward secrecy).
const noiseProtocolName = 'Noise_NNpsk0_25519_ChaChaPoly_SHA256';

class NoiseException implements Exception {
  const NoiseException(this.message);
  final String message;
  @override
  String toString() => 'NoiseException($message)';
}

final _sha = Sha256();
final _hmac = Hmac.sha256();
final _aead = Chacha20.poly1305Aead();
final _x25519 = X25519();

Future<Uint8List> _hash(List<int> data) async => Uint8List.fromList((await _sha.hash(data)).bytes);

Future<Uint8List> _hmacOf(List<int> key, List<int> data) async =>
    Uint8List.fromList((await _hmac.calculateMac(data, secretKey: SecretKey(key))).bytes);

/// HKDF zoals Noise die definieert (HMAC-SHA256, 2 of 3 uitvoeren).
Future<List<Uint8List>> _hkdf(List<int> ck, List<int> ikm, int n) async {
  final temp = await _hmacOf(ck, ikm);
  final o1 = await _hmacOf(temp, [1]);
  final o2 = await _hmacOf(temp, [...o1, 2]);
  if (n == 2) return [o1, o2];
  final o3 = await _hmacOf(temp, [...o2, 3]);
  return [o1, o2, o3];
}

Uint8List _nonce(int n) {
  final b = ByteData(12);
  b.setUint64(4, n, Endian.little);
  return b.buffer.asUint8List();
}

/// Versleuteling in één richting met een teller als nonce. Een herhaald,
/// verwisseld of aangepast bericht kan daarom niet worden ontsleuteld.
class CipherState {
  CipherState(this._k);
  Uint8List? _k;
  int _n = 0;

  bool get hasKey => _k != null;

  Future<Uint8List> encrypt(List<int> ad, List<int> plain) async {
    final k = _k;
    if (k == null) return Uint8List.fromList(plain);
    final box = await _aead.encrypt(plain, secretKey: SecretKey(k), nonce: _nonce(_n++), aad: ad);
    return Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);
  }

  Future<Uint8List> decrypt(List<int> ad, List<int> data) async {
    final k = _k;
    if (k == null) return Uint8List.fromList(data);
    if (data.length < 16) throw const NoiseException('te kort');
    final ct = data.sublist(0, data.length - 16);
    final mac = Mac(data.sublist(data.length - 16));
    try {
      final plain = await _aead.decrypt(SecretBox(ct, nonce: _nonce(_n), mac: mac), secretKey: SecretKey(k), aad: ad);
      _n++;
      return Uint8List.fromList(plain);
    } on SecretBoxAuthenticationError {
      throw const NoiseException('ongeldig bericht');
    }
  }
}

/// Resultaat van een geslaagde handshake.
class NoiseTransport {
  NoiseTransport(this.send, this.receive, this.handshakeHash);
  final CipherState send, receive;
  final Uint8List handshakeHash;

  /// Verificatiecode (6 cijfers) die beide toestellen uit het transcript
  /// afleiden. Een tussenpersoon met een andere sleutel krijgt een andere code.
  Future<String> verificationCode() async {
    final d = await _hash([...handshakeHash, ...utf8.encode('nl-noodpakket verificatiecode')]);
    final v = ByteData.sublistView(d).getUint32(0, Endian.big) % 1000000;
    return v.toString().padLeft(6, '0');
  }
}

class NoiseHandshake {
  NoiseHandshake._(this._initiator, this._psk, this._prologue);

  factory NoiseHandshake.initiator(List<int> psk, List<int> prologue) =>
      NoiseHandshake._(true, Uint8List.fromList(psk), Uint8List.fromList(prologue));
  factory NoiseHandshake.responder(List<int> psk, List<int> prologue) =>
      NoiseHandshake._(false, Uint8List.fromList(psk), Uint8List.fromList(prologue));

  final bool _initiator;
  final Uint8List _psk, _prologue;
  late Uint8List _ck, _h;
  final CipherState _cs = CipherState(null);
  SimpleKeyPair? _e;
  Uint8List? _re;
  bool _started = false;

  Future<void> _init() async {
    if (_started) return;
    _started = true;
    final name = utf8.encode(noiseProtocolName);
    _h = name.length <= 32 ? Uint8List.fromList([...name, ...List.filled(32 - name.length, 0)]) : await _hash(name);
    _ck = _h;
    await _mixHash(_prologue);
    // token "psk" (psk0): MixKeyAndHash
    final o = await _hkdf(_ck, _psk, 3);
    _ck = o[0];
    await _mixHash(o[1]);
    _cs._k = o[2];
    _cs._n = 0;
  }

  Future<void> _mixHash(List<int> data) async => _h = await _hash([..._h, ...data]);

  Future<void> _mixKey(List<int> ikm) async {
    final o = await _hkdf(_ck, ikm, 2);
    _ck = o[0];
    _cs._k = o[1];
    _cs._n = 0;
  }

  Future<Uint8List> _encryptAndHash(List<int> plain) async {
    final ct = await _cs.encrypt(_h, plain);
    await _mixHash(ct);
    return ct;
  }

  Future<Uint8List> _decryptAndHash(List<int> ct) async {
    final plain = await _cs.decrypt(_h, ct);
    await _mixHash(ct);
    return plain;
  }

  Future<Uint8List> _dh(SimpleKeyPair kp, List<int> remote) async {
    final shared = await _x25519.sharedSecretKey(keyPair: kp, remotePublicKey: SimplePublicKey(remote, type: KeyPairType.x25519));
    final bytes = Uint8List.fromList(await shared.extractBytes());
    if (bytes.every((b) => b == 0)) throw const NoiseException('ongeldige sleutel');
    return bytes;
  }

  Future<Uint8List> _newEphemeral() async {
    _e = await _x25519.newKeyPair();
    final pub = await _e!.extractPublicKey();
    return Uint8List.fromList(pub.bytes);
  }

  /// Initiator: bericht 1 (psk, e).
  Future<Uint8List> writeMessage1() async {
    if (!_initiator) throw StateError('alleen initiator');
    await _init();
    final epub = await _newEphemeral();
    await _mixHash(epub);
    await _mixKey(epub);
    final payload = await _encryptAndHash(const []);
    return Uint8List.fromList([...epub, ...payload]);
  }

  /// Responder: leest bericht 1.
  Future<void> readMessage1(List<int> msg) async {
    if (_initiator) throw StateError('alleen responder');
    await _init();
    if (msg.length != 32 + 16) throw const NoiseException('verkeerde lengte');
    _re = Uint8List.fromList(msg.sublist(0, 32));
    await _mixHash(_re!);
    await _mixKey(_re!);
    await _decryptAndHash(msg.sublist(32));
  }

  /// Responder: bericht 2 (e, ee).
  Future<Uint8List> writeMessage2() async {
    if (_initiator || _re == null) throw StateError('volgorde');
    final epub = await _newEphemeral();
    await _mixHash(epub);
    await _mixKey(epub);
    await _mixKey(await _dh(_e!, _re!));
    final payload = await _encryptAndHash(const []);
    return Uint8List.fromList([...epub, ...payload]);
  }

  /// Initiator: leest bericht 2.
  Future<void> readMessage2(List<int> msg) async {
    if (!_initiator || _e == null) throw StateError('volgorde');
    if (msg.length != 32 + 16) throw const NoiseException('verkeerde lengte');
    _re = Uint8List.fromList(msg.sublist(0, 32));
    await _mixHash(_re!);
    await _mixKey(_re!);
    await _mixKey(await _dh(_e!, _re!));
    await _decryptAndHash(msg.sublist(32));
  }

  /// Splitst in twee richtingen; wist het tijdelijke sleutelmateriaal.
  Future<NoiseTransport> finish() async {
    final o = await _hkdf(_ck, const [], 2);
    final t = NoiseTransport(
      CipherState(_initiator ? o[0] : o[1]),
      CipherState(_initiator ? o[1] : o[0]),
      Uint8List.fromList(_h),
    );
    _e = null;
    _re = null;
    _ck.fillRange(0, _ck.length, 0);
    _cs._k = null;
    _psk.fillRange(0, _psk.length, 0);
    return t;
  }
}
