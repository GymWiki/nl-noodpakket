import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// Bestanden van de kluis op schijf. Bestandsnamen van versleutelde data zijn
/// willekeurige UUID's zonder extensie; er staat nooit leesbare inhoud op schijf.
class VaultFiles {
  VaultFiles(this.root);
  final Directory root;

  File get header => File(p.join(root.path, 'vault.json'));
  File get lockState => File(p.join(root.path, 'state.json'));
  File get meta => File(p.join(root.path, 'meta'));
  Directory get data => Directory(p.join(root.path, 'd'));

  Future<void> ensure() async {
    if (!root.existsSync()) root.createSync(recursive: true);
    if (!data.existsSync()) data.createSync(recursive: true);
  }

  File fileFor(String id) {
    // id is een UUID; weiger alles wat een pad zou kunnen ontsnappen.
    if (!RegExp(r'^[A-Za-z0-9\-]{8,64}$').hasMatch(id)) {
      throw ArgumentError('ongeldige bestands-id');
    }
    return File(p.join(data.path, id));
  }

  /// Schrijft atomair: eerst naar een tijdelijk bestand, dan hernoemen. Een
  /// onderbroken schrijfactie laat dus nooit een half bestand achter als echt bestand.
  Future<void> writeAtomic(File target, List<int> bytes) async {
    await ensure();
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(target.path);
  }

  Future<Uint8List?> readBytes(File f) async => f.existsSync() ? f.readAsBytes() : null;

  /// Verwijdert achtergebleven tijdelijke bestanden (na een onderbroken actie).
  Future<void> cleanTemp() async {
    if (!root.existsSync()) return;
    for (final e in root.listSync(recursive: true)) {
      if (e is File && e.path.endsWith('.tmp')) {
        await wipeFile(e);
      }
    }
  }

  /// Verwijdert alles, inclusief gegevens en sleutelkoppen.
  Future<void> deleteAll() async {
    if (!root.existsSync()) return;
    for (final e in root.listSync(recursive: true)) {
      if (e is File) await wipeFile(e);
    }
    root.deleteSync(recursive: true);
  }
}

/// Overschrijft een bestand met nullen en verwijdert het. Op flashgeheugen is
/// overschrijven geen garantie (wear leveling), maar het beperkt restanten.
Future<void> wipeFile(File f) async {
  try {
    if (!f.existsSync()) return;
    final len = f.lengthSync();
    if (len > 0 && len < 256 * 1024 * 1024) {
      final raf = await f.open(mode: FileMode.writeOnly);
      try {
        const chunk = 64 * 1024;
        final zeros = Uint8List(chunk);
        var left = len;
        while (left > 0) {
          final n = left < chunk ? left : chunk;
          await raf.writeFrom(zeros, 0, n);
          left -= n;
        }
        await raf.flush();
      } finally {
        await raf.close();
      }
    }
    f.deleteSync();
  } catch (_) {
    try {
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }
}
