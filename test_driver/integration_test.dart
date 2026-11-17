import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Driver voor `flutter drive`: schrijft elke screenshot naar $STORE_RAW_DIR (standaard store/raw/unknown).
Future<void> main() async {
  final dir = Platform.environment['STORE_RAW_DIR'] ?? 'store/raw/unknown';
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final f = File('$dir/$name.png');
      f.parent.createSync(recursive: true);
      f.writeAsBytesSync(bytes);
      stdout.writeln('screenshot opgeslagen: ${f.path} (${bytes.length} bytes)');
      return true;
    },
  );
}
