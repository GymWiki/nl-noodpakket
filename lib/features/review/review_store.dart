import '../../data/repositories/settings_repository.dart';
import 'review_config.dart';
import 'review_models.dart';

/// Lokale opslag van de beoordelingsgeschiedenis. Een interface, zodat tests een geheugenversie kunnen gebruiken.
abstract class ReviewStore {
  Future<ReviewHistory> load();
  Future<void> save(ReviewHistory history);
}

/// Bewaart de geschiedenis in de instellingentabel van de lokale Drift-database. Er gaat niets naar een server.
class SettingsReviewStore implements ReviewStore {
  SettingsReviewStore(this._repo);
  final SettingsRepository _repo;

  @override
  Future<ReviewHistory> load() async => ReviewHistory.decode(await _repo.getRaw(reviewHistoryKey));

  @override
  Future<void> save(ReviewHistory history) => _repo.setRaw(reviewHistoryKey, history.encode());
}
