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

// ---- Mijn noodplan (schemaversie 2) ----

class PlanMembers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withDefault(const Constant(''))();
  /// person | pet
  TextColumn get kind => text().withDefault(const Constant('person'))();
  /// adult | senior | child | baby (alleen voor personen)
  TextColumn get ageGroup => text().withDefault(const Constant('adult'))();
  BoolColumn get needsHelp => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

class PlanContacts extends Table {
  IntColumn get id => integer().autoIncrement()();
  /// outside_region | emergency | neighbour | doctor | school | vet
  TextColumn get role => text()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get relation => text().withDefault(const Constant(''))();
  TextColumn get phone => text().withDefault(const Constant(''))();
}

class PlanPlaces extends Table {
  /// home_outside | neighbourhood | outside_region
  TextColumn get kind => text()();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {kind};
}

class PlanAgreements extends Table {
  TextColumn get key => text()();
  TextColumn get body => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {key};
}

class PlanLocations extends Table {
  TextColumn get key => text()();
  TextColumn get body => text().withDefault(const Constant(''))();
  /// Pad naar een lokaal opgeslagen foto (verlaat het toestel nooit zonder delen).
  TextColumn get photoPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Eén rij (id = 1) met metadata en de optionele zorg-onderdelen.
class PlanMeta extends Table {
  IntColumn get id => integer()();
  TextColumn get householdName => text().withDefault(const Constant(''))();
  TextColumn get medication => text().withDefault(const Constant(''))();
  TextColumn get devices => text().withDefault(const Constant(''))();
  TextColumn get allergies => text().withDefault(const Constant(''))();
  TextColumn get caregiving => text().withDefault(const Constant(''))();
  TextColumn get documents => text().withDefault(const Constant(''))();
  /// JSON-lijst met overgeslagen onderdelen.
  TextColumn get skipped => text().withDefault(const Constant('[]'))();
  IntColumn get wizardStep => integer().withDefault(const Constant(0))();
  IntColumn get sharedVersion => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get lastSharedAt => dateTime().nullable()();
  DateTimeColumn get lastConfirmedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  ItemRows,
  SettingRows,
  PlanMembers,
  PlanContacts,
  PlanPlaces,
  PlanAgreements,
  PlanLocations,
  PlanMeta,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());
  AppDatabase.forTesting(super.executor);

  /// Verhoog bij elke schemawijziging en voeg een stap toe in [migration].
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2: Mijn noodplan. Bestaande tabellen blijven onaangeroerd.
          if (from < 2) {
            await m.createTable(planMembers);
            await m.createTable(planContacts);
            await m.createTable(planPlaces);
            await m.createTable(planAgreements);
            await m.createTable(planLocations);
            await m.createTable(planMeta);
          }
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
