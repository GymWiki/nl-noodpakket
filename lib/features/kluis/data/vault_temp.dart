import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'vault_files.dart';

/// Schrijft [bytes] tijdelijk als bestand (alleen voor delen, waar een bestand
/// onvermijdelijk is) in een app-privémap, voert [action] uit en overschrijft
/// en verwijdert het bestand daarna altijd, ook bij een fout.
Future<T> withTempPlaintext<T>(
  Directory dir,
  Uint8List bytes,
  String extension,
  Future<T> Function(File file) action,
) async {
  if (!dir.existsSync()) dir.createSync(recursive: true);
  final file = File(p.join(dir.path, '${const Uuid().v4()}.$extension'));
  try {
    await file.writeAsBytes(bytes, flush: true);
    return await action(file);
  } finally {
    await wipeFile(file);
  }
}

/// Ruimt restanten op (bijv. na een onderbroken deelactie of een crash).
Future<void> cleanTempDir(Directory dir) async {
  if (!dir.existsSync()) return;
  for (final e in dir.listSync(recursive: true)) {
    if (e is File) await wipeFile(e);
  }
}
