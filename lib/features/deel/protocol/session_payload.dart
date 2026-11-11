import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Limieten voor delen tussen toestellen. Alles wat de ontvanger binnenkrijgt
/// wordt als onbetrouwbaar behandeld; deze grenzen zijn vooraf bekend en
/// worden in de app getoond.
class ShareLimits {
  ShareLimits._();

  /// Frame op de lijn: eenmalig geheim en handshake zijn klein; data in stukken.
  static const maxFrameBytes = 64 * 1024;
  static const chunkBytes = 32 * 1024;

  static const maxManifestBytes = 40 * 1024;
  static const maxDocuments = 50;
  static const maxPagesPerDocument = 30;
  static const maxPageBytes = 25 * 1024 * 1024;
  static const maxTotalBytes = 150 * 1024 * 1024;
  static const maxPlanBytes = 6 * 1024 * 1024;
  static const maxTextLength = 200;
  static const maxNoteLength = 2000;

  static const connectWindow = Duration(minutes: 2);
  static const handshakeTimeout = Duration(seconds: 10);
  static const idleTimeout = Duration(seconds: 30);
  static const maxFailedAttempts = 3;
}

/// De inhoud van de QR-code: alleen wat nodig is om te verbinden.
/// Geen plan- of documentgegevens. Formaat (past later ook in een
/// https-URL na een #): `nlnp1;<ip>;<poort>;<sessie>;<geheim>`.
class SessionPayload {
  const SessionPayload({
    required this.host,
    required this.port,
    required this.sessionId,
    required this.secret,
  });

  static const version = 1;

  final String host;
  final int port;

  /// 8 bytes, bindt de handshake aan deze sessie.
  final Uint8List sessionId;

  /// 32 bytes, eenmalig, nooit opgeslagen.
  final Uint8List secret;

  static String _b64(List<int> b) => base64Url.encode(b).replaceAll('=', '');
  static Uint8List _unb64(String s) => Uint8List.fromList(base64Url.decode(base64Url.normalize(s)));

  String encode() => 'nlnp$version;$host;$port;${_b64(sessionId)};${_b64(secret)}';

  /// Prologue voor de handshake: koppelt de sessie aan het protocol.
  Uint8List get prologue => Uint8List.fromList([...utf8.encode('nl-noodpakket/deel/v$version/'), ...sessionId]);

  static SessionPayload? tryParse(String s) {
    final parts = s.trim().split(';');
    if (parts.length != 5 || parts[0] != 'nlnp$version') return null;
    final port = int.tryParse(parts[2]);
    if (port == null || port < 1 || port > 65535) return null;
    final host = parts[1];
    if (!_isPrivateIPv4(host)) return null;
    try {
      final sid = _unb64(parts[3]);
      final secret = _unb64(parts[4]);
      if (sid.length != 8 || secret.length != 32) return null;
      return SessionPayload(host: host, port: port, sessionId: sid, secret: secret);
    } catch (_) {
      return null;
    }
  }

  static SessionPayload create({required String host, required int port, Random? random}) {
    final r = random ?? Random.secure();
    Uint8List bytes(int n) => Uint8List.fromList([for (var i = 0; i < n; i++) r.nextInt(256)]);
    return SessionPayload(host: host, port: port, sessionId: bytes(8), secret: bytes(32));
  }
}

/// Alleen lokale (privé) IPv4-adressen zijn toegestaan als verbindingsdoel:
/// een gemanipuleerde QR kan de app zo niet naar een server op internet sturen.
/// Loopback is bedoeld voor tests.
bool _isPrivateIPv4(String host) {
  final p = host.split('.');
  if (p.length != 4) return false;
  final n = [for (final x in p) int.tryParse(x)];
  if (n.any((x) => x == null || x < 0 || x > 255)) return false;
  final a = n[0]!, b = n[1]!;
  return a == 10 || (a == 172 && b >= 16 && b <= 31) || (a == 192 && b == 168) || (a == 169 && b == 254) || a == 127;
}

bool isPrivateIPv4(String host) => _isPrivateIPv4(host);
