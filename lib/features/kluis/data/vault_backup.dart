import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../crypto/vault_crypto.dart';
import '../domain/vault_models.dart';
import 'vault_images.dart' show maxFileBytes;
import 'vault_session.dart';

/// Versleutelde back-up van de hele kluis (.noodkluis).
///
/// Formaat:
///   "NKLUIS01" (8 bytes) | headerLen (4, big endian) | header (JSON) | records...
///   record = len (4, big endian) | AES-256-GCM-blob (nonce | ciphertext | tag)
/// De sleutel komt uit het back-upwachtwoord via Argon2id (parameters + salt staan
/// in de header). Elk record heeft een eigen nonce en wordt geauthenticeerd met
/// de header en zijn volgnummer als aanvullende data (AAD); daardoor worden
/// omwisselen, weglaten en afkappen gedetecteerd. Laatste record = "END" met het aantal.
const _magic = 'NKLUIS01';
const backupFormatVersion = 1;

enum BackupError { invalid, tooNew, wrongPasswordOrCorrupt }

class BackupException implements Exception {
  const BackupException(this.error);
  final BackupError error;
  @override
  String toString() => 'BackupException($error)';
}

List<int> _aad(Uint8List header, int index) => [
      ...utf8.encode('noodkluis-export:v1:'),
      ...header,
      (index >> 24) & 0xFF,
      (index >> 16) & 0xFF,
      (index >> 8) & 0xFF,
      index & 0xFF,
    ];

Uint8List _u32(int v) =>
    Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.big);

/// Schrijft de back-up van een ontgrendelde kluis naar [out]. Bij een fout wordt
/// [out] verwijderd (geen half geschreven bestand).
Future<void> writeBackup({
  required VaultSession session,
  required VaultMeta meta,
  required String password,
  required File out,
  KdfParams kdf = KdfParams.export,
  bool deriveInIsolate = true,
  DateTime? now,
}) async {
  final salt = randomBytes(16);
  final key = await deriveKeyFromSecret(password, salt, kdf, inIsolate: deriveInIsolate);
  final header = Uint8List.fromList(utf8.encode(jsonEncode({
    'v': backupFormatVersion,
    'kdf': kdf.toJson(),
    'salt': base64Encode(salt),
    'cipher': 'aes-256-gcm',
    'created': (now ?? DateTime.now()).toIso8601String(),
  })));
  final tmp = File('${out.path}.part');
  final sink = tmp.openWrite();
  try {
    sink
      ..add(utf8.encode(_magic))
      ..add(_u32(header.length))
      ..add(header);
    var index = 0;
    Future<void> record(Uint8List plain) async {
      final blob = await seal(key, plain, aad: _aad(header, index++));
      sink
        ..add(_u32(blob.length))
        ..add(blob);
    }

    final ids = meta.allFileIds.toList();
    await record(Uint8List.fromList(utf8.encode(jsonEncode({'meta': meta.toJson(), 'files': ids.length}))));
    for (final id in ids) {
      final data = await session.readFile(id);
      final rec = Uint8List(36 + data.length);
      rec.setRange(0, 36, utf8.encode(id.padRight(36)));
      rec.setRange(36, rec.length, data);
      await record(rec);
      zero(data);
      zero(rec);
    }
    await record(Uint8List.fromList(utf8.encode(jsonEncode({'end': true, 'records': index}))));
    await sink.flush();
    await sink.close();
    if (out.existsSync()) out.deleteSync();
    await tmp.rename(out.path);
  } catch (_) {
    try {
      await sink.close();
    } catch (_) {}
    if (tmp.existsSync()) tmp.deleteSync();
    rethrow;
  } finally {
    zero(key);
  }
}

/// Een geopende back-up: toont eerst een voorbeeld (aantal documenten) en kan
/// daarna worden toegepast.
class BackupReader {
  BackupReader._(this._file, this._header, this._key, this.meta, this._expectedFiles, this._offset);
  final File _file;
  final Uint8List _header;
  final Uint8List _key;
  final VaultMeta meta;
  final int _expectedFiles;
  final int _offset;

  int get documentCount => meta.documents.length;

  /// Opent en controleert de back-up (wachtwoord, formaat, versie).
  static Future<BackupReader> read(
    File file,
    String password, {
    bool deriveInIsolate = true,
  }) async {
    final raf = await file.open();
    try {
      final head = await raf.read(12);
      if (head.length < 12 || utf8.decode(head.sublist(0, 8), allowMalformed: true) != _magic) {
        throw const BackupException(BackupError.invalid);
      }
      final hLen = head.buffer.asByteData(head.offsetInBytes).getUint32(8, Endian.big);
      if (hLen <= 0 || hLen > 4096) throw const BackupException(BackupError.invalid);
      final header = await raf.read(hLen);
      if (header.length != hLen) throw const BackupException(BackupError.invalid);

      late final Map<String, dynamic> h;
      try {
        h = jsonDecode(utf8.decode(header)) as Map<String, dynamic>;
      } catch (_) {
        throw const BackupException(BackupError.invalid);
      }
      final v = h['v'];
      if (v is! int || v < 1) throw const BackupException(BackupError.invalid);
      if (v > backupFormatVersion) throw const BackupException(BackupError.tooNew);
      if (h['cipher'] != 'aes-256-gcm') throw const BackupException(BackupError.invalid);

      late final KdfParams kdf;
      late final Uint8List salt;
      try {
        kdf = KdfParams.fromJson(Map<String, dynamic>.from(h['kdf'] as Map));
        salt = base64Decode(h['salt'] as String);
      } catch (_) {
        throw const BackupException(BackupError.invalid);
      }
      final key = await deriveKeyFromSecret(password, salt, kdf, inIsolate: deriveInIsolate);

      final first = await _readRecord(raf, key, header, 0);
      if (first == null) {
        zero(key);
        throw const BackupException(BackupError.wrongPasswordOrCorrupt);
      }
      try {
        final m = jsonDecode(utf8.decode(first)) as Map<String, dynamic>;
        final meta = VaultMeta.fromJson(Map<String, dynamic>.from(m['meta'] as Map));
        return BackupReader._(file, Uint8List.fromList(header), key, meta,
            (m['files'] as num).toInt(), await raf.position());
      } on FormatException catch (e) {
        zero(key);
        throw BackupException(e.message.contains('nieuw') ? BackupError.tooNew : BackupError.invalid);
      } catch (_) {
        zero(key);
        throw const BackupException(BackupError.invalid);
      }
    } finally {
      await raf.close();
    }
  }

  /// Leest één record; null bij authenticatiefout of afgekapt bestand.
  static Future<Uint8List?> _readRecord(
      RandomAccessFile raf, Uint8List key, Uint8List header, int index) async {
    final lenBytes = await raf.read(4);
    if (lenBytes.length < 4) return null;
    final len = lenBytes.buffer.asByteData(lenBytes.offsetInBytes).getUint32(0, Endian.big);
    if (len < nonceLength + tagLength || len > maxFileBytes + 1024) return null;
    final blob = await raf.read(len);
    if (blob.length != len) return null;
    try {
      return await open(key, Uint8List.fromList(blob), aad: _aad(header, index));
    } on VaultAuthException {
      return null;
    }
  }

  /// Schrijft de bestanden van de back-up versleuteld in [session] (met
  /// behoud van hun id's) en geeft de bijbehorende metadata terug. Controleert
  /// dat alle records aanwezig en ongewijzigd zijn; bij een fout worden alle
  /// nieuw geschreven bestanden weer verwijderd.
  Future<VaultMeta> importFiles(VaultSession session, {Set<String> skipDocIds = const {}}) async {
    final wanted = <String>{
      for (final d in meta.documents)
        if (!skipDocIds.contains(d.id))
          for (final p in d.pages) ...[p.fileId, ?p.thumbId],
    };
    final raf = await _file.open();
    final created = <String>[];
    try {
      await raf.setPosition(_offset);
      var index = 1;
      var seen = 0;
      while (true) {
        final rec = await _readRecord(raf, _key, _header, index++);
        if (rec == null) throw const BackupException(BackupError.wrongPasswordOrCorrupt);
        if (rec.length >= 36 && seen < _expectedFiles) {
          final id = utf8.decode(rec.sublist(0, 36)).trim();
          final data = Uint8List.sublistView(rec, 36);
          if (wanted.contains(id)) {
            await session.putFileWithId(id, data);
            created.add(id);
          }
          seen++;
          zero(rec);
          continue;
        }
        // Eindrecord: moet het juiste aantal bevatten.
        try {
          final e = jsonDecode(utf8.decode(rec)) as Map<String, dynamic>;
          if (e['end'] != true || e['records'] != index - 1 || seen != _expectedFiles) {
            throw const BackupException(BackupError.wrongPasswordOrCorrupt);
          }
        } on BackupException {
          rethrow;
        } catch (_) {
          throw const BackupException(BackupError.wrongPasswordOrCorrupt);
        }
        break;
      }
      for (final id in wanted) {
        if (!created.contains(id)) {
          throw const BackupException(BackupError.wrongPasswordOrCorrupt);
        }
      }
      return meta;
    } catch (_) {
      for (final id in created) {
        await session.deleteFile(id);
      }
      rethrow;
    } finally {
      await raf.close();
    }
  }

  void dispose() => zero(_key);
}
