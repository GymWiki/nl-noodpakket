import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../crypto/vault_crypto.dart';
import '../domain/vault_models.dart';
import 'vault_files.dart';

/// Een ontgrendelde kluis: houdt de datasleutel alleen in het geheugen en
/// versleutelt/ontsleutelt bestanden en metadata ermee. [close] wist de sleutel.
class VaultSession {
  VaultSession(this.files, Uint8List dataKey) : _key = Uint8List.fromList(dataKey);

  final VaultFiles files;
  Uint8List? _key;
  static const _uuid = Uuid();

  bool get isOpen => _key != null;

  Uint8List get _k {
    final k = _key;
    if (k == null) throw StateError('kluis is vergrendeld');
    return k;
  }

  static final _metaAad = utf8.encode('noodkluis:v1:meta');
  static List<int> _fileAad(String id) => utf8.encode('noodkluis:v1:file:$id');

  Future<VaultMeta> loadMeta() async {
    final blob = await files.readBytes(files.meta);
    if (blob == null) return const VaultMeta();
    final plain = await open(_k, blob, aad: _metaAad);
    try {
      return VaultMeta.fromJson(jsonDecode(utf8.decode(plain)) as Map<String, dynamic>);
    } finally {
      zero(plain);
    }
  }

  Future<void> saveMeta(VaultMeta meta) async {
    final plain = Uint8List.fromList(utf8.encode(jsonEncode(meta.toJson())));
    try {
      await files.writeAtomic(files.meta, await seal(_k, plain, aad: _metaAad));
    } finally {
      zero(plain);
    }
  }

  /// Versleutelt [plain] naar een nieuw bestand met willekeurige naam.
  Future<String> putFile(Uint8List plain) async {
    final id = _uuid.v4();
    await files.writeAtomic(files.fileFor(id), await seal(_k, plain, aad: _fileAad(id)));
    return id;
  }

  /// Schrijft een bestand onder een bestaande id (bij het terugzetten van een back-up).
  Future<void> putFileWithId(String id, Uint8List plain) async =>
      files.writeAtomic(files.fileFor(id), await seal(_k, plain, aad: _fileAad(id)));

  /// Ontsleutelt een bestand in het geheugen. De aanroeper moet de buffer na gebruik
  /// met [zero] wissen.
  Future<Uint8List> readFile(String id) async {
    final blob = await files.readBytes(files.fileFor(id));
    if (blob == null) throw const VaultAuthException();
    return open(_k, blob, aad: _fileAad(id));
  }

  Future<void> deleteFile(String id) => wipeFile(files.fileFor(id));

  /// Verwijdert bestanden die niet meer in de metadata voorkomen (bijv. na een
  /// onderbroken toevoeg-actie). Geeft het aantal verwijderde bestanden terug.
  Future<int> collectGarbage(VaultMeta meta) async {
    if (!files.data.existsSync()) return 0;
    final keep = meta.allFileIds;
    var n = 0;
    for (final e in files.data.listSync()) {
      if (e is! File) continue;
      final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (!keep.contains(name)) {
        await wipeFile(e);
        n++;
      }
    }
    return n;
  }

  String newId() => _uuid.v4();

  /// Kopie van de datasleutel; de aanroeper wist de kopie met [zero].
  Uint8List keyCopy() => Uint8List.fromList(_k);

  void close() {
    zero(_key);
    _key = null;
  }
}
