import 'package:mijnnoodpakket/features/review/review_config.dart';
import 'package:mijnnoodpakket/features/review/review_controller.dart';
import 'package:mijnnoodpakket/features/review/review_launcher.dart';
import 'package:mijnnoodpakket/features/review/review_models.dart';
import 'package:mijnnoodpakket/features/review/review_store.dart';

/// Een klok die je zelf verzet.
class TestClock {
  TestClock(this.now);
  DateTime now;
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}

/// Opslag in het geheugen; telt de schrijfacties en kan falen.
class MemoryReviewStore implements ReviewStore {
  MemoryReviewStore([this.history = const ReviewHistory()]);
  ReviewHistory history;
  int saves = 0;
  bool failSave = false;

  @override
  Future<ReviewHistory> load() async => history;

  @override
  Future<void> save(ReviewHistory h) async {
    if (failSave) throw StateError('opslag mislukt');
    saves++;
    history = h;
  }
}

/// De systeemprompt: noteert wat er gebeurt, toont zelf niets.
class FakeReviewLauncher implements ReviewLauncher {
  bool available = true;
  bool throwOnAvailable = false;
  bool throwOnRequest = false;
  final calls = <String>[];

  int get requests => calls.where((c) => c == 'requestReview').length;

  @override
  Future<bool> isAvailable() async {
    calls.add('isAvailable');
    if (throwOnAvailable) throw StateError('niet beschikbaar');
    return available;
  }

  @override
  Future<void> requestReview() async {
    calls.add('requestReview');
    if (throwOnRequest) throw StateError('systeem weigert');
  }
}

/// Alles op orde, behalve het succesmoment: 10 dagen geleden gestart en 6 sessies.
ReviewHistory seasoned(DateTime now) => ReviewHistory(firstLaunch: now.subtract(const Duration(days: 10)), sessions: 6);

ReviewController buildController({
  required TestClock clock,
  required MemoryReviewStore store,
  required FakeReviewLauncher launcher,
  String Function()? version,
  ReviewConfig config = reviewConfig,
}) =>
    ReviewController(
      store: store,
      launcher: launcher,
      clock: clock.call,
      appVersion: () async => (version ?? () => '2.0.0')(),
      config: config,
    );
