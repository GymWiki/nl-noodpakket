import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/repositories/settings_repository.dart';
import 'wiki_models.dart';

const wikiAsset = 'assets/wiki/noodgevallen.json';

/// Gebundelde wiki-inhoud; geen netwerk nodig.
final wikiProvider = FutureProvider<WikiData>(
    (ref) async => WikiData.parse(await rootBundle.loadString(wikiAsset)));

/// Voortgang in het stappenplan: huidige stap + afgevinkte stappen.
class WikiProgress {
  const WikiProgress({this.current = 0, this.done = const {}});
  final int current;
  final Set<int> done;

  WikiProgress copyWith({int? current, Set<int>? done}) =>
      WikiProgress(current: current ?? this.current, done: done ?? this.done);

  String encode() => jsonEncode({'i': current, 'done': done.toList()..sort()});

  factory WikiProgress.decode(String? s) {
    if (s == null) return const WikiProgress();
    try {
      final j = jsonDecode(s) as Map<String, dynamic>;
      return WikiProgress(
        current: (j['i'] as num?)?.toInt() ?? 0,
        done: {for (final d in (j['done'] as List? ?? const [])) (d as num).toInt()},
      );
    } catch (_) {
      return const WikiProgress();
    }
  }
}

const _favKey = 'wiki_favorites';
String _progressKey(String id) => 'wiki_progress_$id';

/// Lokale opslag van favorieten en stapvoortgang (in de bestaande instellingen-tabel).
class WikiPrefs {
  WikiPrefs(this._repo);
  final SettingsRepository _repo;

  Future<void> toggleFavorite(String id, Set<String> current) {
    final next = {...current};
    if (!next.remove(id)) next.add(id);
    return _repo.setRaw(_favKey, jsonEncode(next.toList()..sort()));
  }

  Future<void> saveProgress(String id, WikiProgress p) =>
      _repo.setRaw(_progressKey(id), p.encode());

  Future<void> resetProgress(String id) => _repo.deleteRaw(_progressKey(id));

  Future<WikiProgress> loadProgress(String id) async =>
      WikiProgress.decode(await _repo.getRaw(_progressKey(id)));
}

final wikiPrefsProvider =
    Provider((ref) => WikiPrefs(ref.watch(settingsRepositoryProvider)));

final wikiFavoritesProvider = StreamProvider<Set<String>>((ref) {
  return ref.watch(settingsRepositoryProvider).watchRaw(_favKey).map((s) {
    if (s == null) return <String>{};
    try {
      return {for (final e in jsonDecode(s) as List) e.toString()};
    } catch (_) {
      return <String>{};
    }
  });
});
