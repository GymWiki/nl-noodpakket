import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/providers.dart';
import 'review_controller.dart';
import 'review_launcher.dart';
import 'review_overlay.dart';
import 'review_store.dart';

final reviewStoreProvider = Provider<ReviewStore>((ref) => SettingsReviewStore(ref.read(settingsRepositoryProvider)));

final reviewLauncherProvider = Provider<ReviewLauncher>((ref) => InAppReviewLauncher());

/// De klok: apart, zodat tests de tijd kunnen vastzetten.
final reviewClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// De appversie (zonder buildnummer): "voor deze versie is al gevraagd".
final reviewAppVersionProvider = Provider<Future<String> Function()>((ref) {
  String? cached;
  return () async => cached ??= (await PackageInfo.fromPlatform()).version;
});

final reviewOverlayObserverProvider = Provider<ReviewOverlayObserver>((ref) => ReviewOverlayObserver());

final reviewControllerProvider = Provider<ReviewController>((ref) {
  final c = ReviewController(
    store: ref.read(reviewStoreProvider),
    launcher: ref.read(reviewLauncherProvider),
    clock: ref.read(reviewClockProvider),
    appVersion: ref.read(reviewAppVersionProvider),
  );
  ref.onDispose(c.dispose);
  return c;
});
