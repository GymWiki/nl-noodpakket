import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Cryptografische bouwstenen van de documentenkluis. Alleen gevestigde
/// primitieven uit het pakket `cryptography` (AES-256-GCM, Argon2id, HKDF-SHA256);
/// er is geen eigen crypto geschreven.

const keyLength = 32; // 256 bit
const nonceLength = 12; // 96 bit voor AES-GCM
const tagLength = 16; // 128 bit GCM-tag

/// Gooit bij een verkeerde sleutel of gemanipuleerde data. Bevat bewust geen details.
class VaultAuthException implements Exception {
  const VaultAuthException();
  @override
  String toString() => 'VaultAuthException';
}

final _aes = AesGcm.with256bits();
final _rng = Random.secure();

/// Cryptografisch veilige willekeurige bytes.
Uint8List randomBytes(int n) {
  final out = Uint8List(n);
  for (var i = 0; i < n; i++) {
    out[i] = _rng.nextInt(256);
  }
  return out;
}

/// Overschrijft een buffer met nullen (best effort in Dart).
void zero(Uint8List? b) {
  if (b == null) return;
  b.fillRange(0, b.length, 0);
}

/// Versleutelt [plain] met AES-256-GCM en een uniek willekeurig nonce.
/// Uitvoer: nonce (12) || ciphertext || tag (16). [aad] wordt meegeauthenticeerd,
/// maar niet opgeslagen (bindt data aan context, bijv. de bestandsnaam).
Future<Uint8List> seal(Uint8List key, Uint8List plain, {List<int> aad = const []}) async {
  final nonce = randomBytes(nonceLength);
  final box = await _aes.encrypt(plain, secretKey: SecretKey(key), nonce: nonce, aad: aad);
  final out = Uint8List(nonceLength + box.cipherText.length + tagLength);
  out.setRange(0, nonceLength, nonce);
  out.setRange(nonceLength, nonceLength + box.cipherText.length, box.cipherText);
  out.setRange(out.length - tagLength, out.length, box.mac.bytes);
  return out;
}

/// Tegenhanger van [seal]. Gooit [VaultAuthException] bij een verkeerde sleutel,
/// andere [aad] of gewijzigde/afgekapte data.
Future<Uint8List> open(Uint8List key, Uint8List blob, {List<int> aad = const []}) async {
  if (blob.length < nonceLength + tagLength) throw const VaultAuthException();
  try {
    final nonce = blob.sublist(0, nonceLength);
    final ct = blob.sublist(nonceLength, blob.length - tagLength);
    final mac = Mac(blob.sublist(blob.length - tagLength));
    final plain = await _aes.decrypt(
      SecretBox(ct, nonce: nonce, mac: mac),
      secretKey: SecretKey(key),
      aad: aad,
    );
    return Uint8List.fromList(plain);
  } on SecretBoxAuthenticationError {
    throw const VaultAuthException();
  } on ArgumentError {
    throw const VaultAuthException();
  }
}

/// Parameters voor Argon2id. Worden naast de gewrapte sleutel opgeslagen,
/// zodat ze later verhoogd kunnen worden.
class KdfParams {
  const KdfParams({required this.memoryKiB, required this.iterations, this.parallelism = 1});

  /// Kluis-PIN: OWASP-minimum voor Argon2id (19 MiB, 2 iteraties, 1 lane).
  static const pin = KdfParams(memoryKiB: 19456, iterations: 2);

  /// Back-upwachtwoord: zwaarder, want het bestand verlaat het toestel.
  static const export = KdfParams(memoryKiB: 32768, iterations: 3);

  /// Alleen voor tests.
  static const test = KdfParams(memoryKiB: 64, iterations: 1);

  final int memoryKiB, iterations, parallelism;

  Map<String, Object?> toJson() =>
      {'alg': 'argon2id', 'm': memoryKiB, 't': iterations, 'p': parallelism};

  factory KdfParams.fromJson(Map<String, dynamic> j) {
    if (j['alg'] != 'argon2id') throw const FormatException('onbekend kdf');
    final m = j['m'], t = j['t'], p = j['p'];
    if (m is! int || t is! int || p is! int || m < 8 || t < 1 || p < 1 || m > 1048576) {
      throw const FormatException('ongeldige kdf-parameters');
    }
    return KdfParams(memoryKiB: m, iterations: t, parallelism: p);
  }
}

/// Leidt een 256-bit sleutel af uit een PIN of wachtwoord met Argon2id.
/// Draait in een aparte isolate, zodat de interface niet blokkeert.
Future<Uint8List> deriveKeyFromSecret(
  String secret,
  Uint8List salt,
  KdfParams params, {
  bool inIsolate = true,
}) async {
  final bytes = Uint8List.fromList(utf8.encode(secret));
  try {
    if (!inIsolate) return await _argon2(bytes, salt, params);
    return await Isolate.run(() => _argon2(bytes, salt, params));
  } finally {
    zero(bytes);
  }
}

Future<Uint8List> _argon2(Uint8List secret, Uint8List salt, KdfParams p) async {
  final kdf = Argon2id(
    memory: p.memoryKiB,
    parallelism: p.parallelism,
    iterations: p.iterations,
    hashLength: keyLength,
  );
  final key = await kdf.deriveKey(secretKey: SecretKey(secret), nonce: salt);
  return Uint8List.fromList(await key.extractBytes());
}

/// HKDF-SHA256 voor sleutels uit een secret met hoge entropie (herstelcode).
Future<Uint8List> deriveKeyHkdf(Uint8List secret, Uint8List salt, String info) async {
  final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: keyLength);
  final key = await hkdf.deriveKey(
    secretKey: SecretKey(secret),
    nonce: salt,
    info: utf8.encode(info),
  );
  return Uint8List.fromList(await key.extractBytes());
}

// ------------------------------------------------------------ herstelcode

const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'; // base32, geen 0/1/8/9
const recoveryCodeBytes = 20; // 160 bit entropie -> 32 tekens

/// Genereert een herstelcode (32 base32-tekens, getoond in groepen van 4).
String generateRecoveryCode() => _base32(randomBytes(recoveryCodeBytes));

String _base32(Uint8List data) {
  final sb = StringBuffer();
  var buffer = 0, bits = 0;
  for (final b in data) {
    buffer = (buffer << 8) | b;
    bits += 8;
    while (bits >= 5) {
      sb.write(_alphabet[(buffer >> (bits - 5)) & 31]);
      bits -= 5;
    }
  }
  if (bits > 0) sb.write(_alphabet[(buffer << (5 - bits)) & 31]);
  return sb.toString();
}

String formatRecoveryCode(String code) {
  final c = code.replaceAll(RegExp(r'[^A-Za-z2-7]'), '').toUpperCase();
  return [for (var i = 0; i < c.length; i += 4) c.substring(i, min(i + 4, c.length))].join(' ');
}

/// Normaliseert invoer van de gebruiker (spaties/streepjes/kleine letters).
String normalizeRecoveryCode(String input) =>
    input.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();

bool isValidRecoveryCode(String input) {
  final c = normalizeRecoveryCode(input);
  return c.length == 32 && RegExp(r'^[A-Z2-7]+$').hasMatch(c);
}
