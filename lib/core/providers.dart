import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/repositories/item_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../domain/models.dart';
import 'notifications/notification_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final itemRepositoryProvider =
    Provider((ref) => ItemRepository(ref.watch(databaseProvider)));
final settingsRepositoryProvider =
    Provider((ref) => SettingsRepository(ref.watch(databaseProvider)));
final notificationServiceProvider = Provider((ref) => NotificationService());

final settingsProvider = StreamProvider<AppSettings>(
    (ref) => ref.watch(settingsRepositoryProvider).watch());

final _householdProvider = Provider<Household>((ref) =>
    ref.watch(settingsProvider.select((s) => s.value?.household)) ??
    const Household());

final _rowsProvider = StreamProvider(
    (ref) => ref.watch(itemRepositoryProvider).watchRows());

/// Alle items (inclusief verborgen) voor dit huishouden.
final allItemsProvider = Provider<AsyncValue<List<Item>>>((ref) {
  final h = ref.watch(_householdProvider);
  return ref.watch(_rowsProvider).whenData((rows) => assembleItems(rows, h));
});

/// Zichtbare items (verborgen weggelaten).
final visibleItemsProvider = Provider<AsyncValue<List<Item>>>((ref) =>
    ref.watch(allItemsProvider).whenData(
        (l) => l.where((i) => !i.hidden).toList(growable: false)));
