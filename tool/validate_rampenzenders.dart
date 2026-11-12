// Controleert assets/radio/rampenzenders.json.
//   dart run tool/validate_rampenzenders.dart
// Sluit af met exitcode 1 bij fouten, zodat het ook in CI of een pre-commit-hook past.
import 'dart:convert';
import 'dart:io';

import 'package:mijnnoodpakket/features/rampenzender/data/rampenzender_validation.dart';

void main(List<String> args) {
  final path = args.isNotEmpty ? args.first : 'assets/radio/rampenzenders.json';
  final j = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final errors = validateRampenzenders(j);
  if (errors.isEmpty) {
    final t = (j['transmissions'] as List).length;
    stdout.writeln('OK: ${(j['broadcasters'] as List).length} omroepen, $t gebieden, ${(j['regions'] as List).length} gemeenten.');
    return;
  }
  stderr.writeln('${errors.length} fout(en) in $path:');
  for (final e in errors) {
    stderr.writeln(' - $e');
  }
  exit(1);
}
