import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Eén rij per item waarvan de gebruiker iets heeft aangepast, plus alle
/// eigen items. Standaarditems zonder rij hebben de standaardstaat.
class ItemRows extends Table {
  TextColumn get id => text()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();
  // Alleen voor eigen items:
  TextColumn get name => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get why => text().nullable()();
  TextColumn get unit => text().nullable()();
  // Staat:
  BoolColumn get inHouse => boolean().withDefault(const Constant(false))();
  RealColumn get quantityHave => real().nullable()();
  RealColumn get quantityOverride => real().nullable()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  IntColumn get intervalMonths => integer().nullable()();
  DateTimeColumn get lastChecked => dateTime().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sleutel/waarde-instellingen (huishouden, notificaties, thema, ...).
class SettingRows extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [ItemRows, SettingRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());
  AppDatabase.forTesting(super.executor);

  /// Verhoog bij elke schemawijziging en voeg een stap toe in [migration].
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Toekomstige migraties, bijvoorbeeld:
          // if (from < 2) await m.addColumn(itemRows, itemRows.newColumn);
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

LazyDatabase _open() => LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      return NativeDatabase.createInBackground(
        File(p.join(dir.path, 'noodpakket.sqlite')),
      );
    });
