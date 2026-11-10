import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mijnnoodpakket/data/db/database.dart';
import 'package:mijnnoodpakket/data/repositories/item_repository.dart';
import 'package:mijnnoodpakket/data/repositories/settings_repository.dart';
import 'package:mijnnoodpakket/domain/models.dart';

void main() {
  late AppDatabase db;
  late ItemRepository repo;
  late SettingsRepository settings;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ItemRepository(db);
    settings = SettingsRepository(db);
  });
  tearDown(() => db.close());

  test('export en import geven dezelfde data terug', () async {
    await settings.save(const AppSettings(
        household: Household(adults: 2, pets: 1), onboarded: true, leadDays: 14));
    await repo.setInHouse('water', true);
    await repo.save(
      'custom_1',
      ItemEdit(
          inHouse: true,
          expiryDate: DateTime(2027, 3, 1),
          name: 'Thermoskan',
          category: 'Eigen',
          unit: 'stuks'),
      custom: true,
    );
    final json = await repo.exportJson();

    await repo.resetAll();
    expect(await repo.rows(), isEmpty);

    await repo.importJson(json);
    final items = assembleItems(await repo.rows(), const Household(adults: 2));
    expect(items.firstWhere((i) => i.id == 'water').inHouse, isTrue);
    final custom = items.firstWhere((i) => i.id == 'custom_1');
    expect(custom.name, 'Thermoskan');
    expect(custom.category, 'Eigen');
    expect(custom.expiryDate, DateTime(2027, 3, 1));
    final s = await settings.load();
    expect(s.household.adults, 2);
    expect(s.leadDays, 14);
    expect(s.onboarded, isTrue);
  });

  test('ongeldige import laat bestaande data intact', () async {
    await repo.setInHouse('water', true);
    expect(() => repo.importJson('geen json'), throwsFormatException);
    expect(() => repo.importJson('{"app":"andere","items":[]}'),
        throwsFormatException);
    expect((await repo.rows()).single.id, 'water');
  });

  test('standaardlijst herstellen behoudt eigen items', () async {
    await repo.setHidden('water', true);
    await repo.save('custom_1', const ItemEdit(inHouse: false, name: 'Eigen'),
        custom: true);
    await repo.restoreDefaults();
    final items = assembleItems(await repo.rows(), const Household());
    expect(items.firstWhere((i) => i.id == 'water').hidden, isFalse);
    expect(items.any((i) => i.id == 'custom_1'), isTrue);
  });

  test('standaarditem verbergen en eigen item verwijderen', () async {
    await repo.setHidden('radio', true);
    await repo.save('custom_1', const ItemEdit(inHouse: false, name: 'Eigen'),
        custom: true);
    await repo.deleteCustom('custom_1');
    await repo.deleteCustom('radio'); // standaarditem: mag niet gewist worden
    final items = assembleItems(await repo.rows(), const Household());
    expect(items.any((i) => i.id == 'custom_1'), isFalse);
    expect(items.firstWhere((i) => i.id == 'radio').hidden, isTrue);
  });
}
