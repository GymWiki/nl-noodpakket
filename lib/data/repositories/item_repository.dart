import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/expiry.dart';
import '../../domain/models.dart';
import '../../domain/quantity.dart';
import '../db/database.dart';
import '../seed/seed_items.dart';


/// Voegt seed-data, opgeslagen staat en huishouden samen tot [Item]s.
/// Standaarditems die niet relevant zijn voor het huishouden vallen weg.
List<Item> assembleItems(List<ItemRow> rows, Household h) {
  final byId = {for (final r in rows) r.id: r};
  final out = <Item>[];
  for (final s in seedItems) {
    if (!isRelevant(s, h)) continue;
    final r = byId[s.id];
    out.add(Item(
      id: s.id,
      isCustom: false,
      hidden: r?.hidden ?? false,
      name: s.name,
      category: s.category,
      why: s.why,
      unit: s.unit,
      recommended: recommendedQuantity(s, h),
      inHouse: r?.inHouse ?? false,
      quantityHave: r?.quantityHave,
      quantityOverride: r?.quantityOverride,
      expiryDate: r?.expiryDate,
      intervalMonths: r?.intervalMonths,
      lastChecked: r?.lastChecked,
      notes: r?.notes ?? '',
      shelfAdvice: s.shelfAdvice,
      suggestedIntervalMonths: s.intervalMonths,
    ));
  }
  for (final r in rows.where((r) => r.isCustom)) {
    out.add(Item(
      id: r.id,
      isCustom: true,
      hidden: false,
      name: r.name ?? '',
      category: r.categoryId ?? Cat.other,
      why: r.why ?? '',
      unit: r.unit ?? 'stuks',
      recommended: 1,
      inHouse: r.inHouse,
      quantityHave: r.quantityHave,
      quantityOverride: r.quantityOverride,
      expiryDate: r.expiryDate,
      intervalMonths: r.intervalMonths,
      lastChecked: r.lastChecked,
      notes: r.notes,
    ));
  }
  return out;
}

/// Gebruikersinvoer uit het itemformulier.
class ItemEdit {
  const ItemEdit({
    required this.inHouse,
    this.quantityHave,
    this.quantityOverride,
    this.expiryDate,
    this.intervalMonths,
    this.lastChecked,
    this.notes = '',
    this.name,
    this.category,
    this.unit,
    this.why,
  });
  final bool inHouse;
  final double? quantityHave, quantityOverride;
  final DateTime? expiryDate, lastChecked;
  final int? intervalMonths;
  final String notes;
  final String? name, category, unit, why; // alleen eigen items
}

class ItemRepository {
  ItemRepository(this._db);
  final AppDatabase _db;

  Stream<List<ItemRow>> watchRows() => _db.select(_db.itemRows).watch();
  Future<List<ItemRow>> rows() => _db.select(_db.itemRows).get();

  Future<void> setInHouse(String id, bool v) => _db
      .into(_db.itemRows)
      .insertOnConflictUpdate(ItemRowsCompanion(id: Value(id), inHouse: Value(v)));

  Future<void> setHidden(String id, bool v) => _db
      .into(_db.itemRows)
      .insertOnConflictUpdate(ItemRowsCompanion(id: Value(id), hidden: Value(v)));

  Future<void> markChecked(String id, DateTime now) =>
      _db.into(_db.itemRows).insertOnConflictUpdate(ItemRowsCompanion(
          id: Value(id), lastChecked: Value(dateOnly(now))));

  Future<void> save(String id, ItemEdit e, {required bool custom}) =>
      _db.into(_db.itemRows).insertOnConflictUpdate(ItemRowsCompanion(
            id: Value(id),
            isCustom: Value(custom),
            inHouse: Value(e.inHouse),
            quantityHave: Value(e.quantityHave),
            quantityOverride: Value(e.quantityOverride),
            expiryDate: Value(e.expiryDate),
            intervalMonths: Value(e.intervalMonths),
            lastChecked: Value(e.lastChecked),
            notes: Value(e.notes),
            name: custom ? Value(e.name) : const Value.absent(),
            categoryId: custom ? Value(e.category) : const Value.absent(),
            unit: custom ? Value(e.unit) : const Value.absent(),
            why: custom ? Value(e.why) : const Value.absent(),
          ));

  String newCustomId() => 'custom_${DateTime.now().microsecondsSinceEpoch}';

  Future<void> deleteCustom(String id) => (_db.delete(_db.itemRows)
        ..where((r) => r.id.equals(id) & r.isCustom.equals(true)))
      .go();

  /// Standaardlijst herstellen: verborgen items terug, aanpassingen aan
  /// standaarditems gewist. Eigen items blijven behouden.
  Future<void> restoreDefaults() => (_db.delete(_db.itemRows)
        ..where((r) => r.isCustom.equals(false)))
      .go();

  Future<void> resetAll() async {
    await _db.delete(_db.itemRows).go();
    await _db.delete(_db.settingRows).go();
  }

  // ---- Back-up ----

  static const _backupVersion = 1;

  Future<String> exportJson() async {
    final items = await _db.select(_db.itemRows).get();
    final settings = await _db.select(_db.settingRows).get();
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'nl-noodpakket',
      'version': _backupVersion,
      'items': [for (final r in items) r.toJson(serializer: _ser)],
      'settings': {for (final s in settings) s.key: s.value},
    });
  }

  static final _ser = driftRuntimeOptions.defaultSerializer;

  /// Vervangt alle data. Gooit [FormatException] bij een ongeldig bestand;
  /// in dat geval blijft de bestaande data ongewijzigd.
  Future<void> importJson(String json) async {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('geen geldige JSON');
    }
    if (data['app'] != 'nl-noodpakket' || data['items'] is! List) {
      throw const FormatException('geen back-up van deze app');
    }
    final items = [
      for (final j in data['items'] as List)
        ItemRow.fromJson(Map<String, dynamic>.from(j as Map), serializer: _ser),
    ];
    final settings = Map<String, dynamic>.from(data['settings'] as Map? ?? {});
    await _db.transaction(() async {
      await _db.delete(_db.itemRows).go();
      await _db.delete(_db.settingRows).go();
      await _db.batch((b) {
        b.insertAll(_db.itemRows, items);
        b.insertAll(_db.settingRows, [
          for (final e in settings.entries)
            SettingRow(key: e.key, value: '${e.value}'),
        ]);
      });
    });
  }
}
