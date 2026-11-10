import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;

import '../../domain/models.dart';
import '../db/database.dart';

class AppSettings {
  const AppSettings({
    this.household = const Household(),
    this.onboarded = false,
    this.leadDays = 30,
    this.semiAnnual = false,
    this.themeMode = ThemeMode.system,
    this.permissionAsked = false,
  });

  final Household household;
  final bool onboarded, semiAnnual, permissionAsked;
  final int leadDays;
  final ThemeMode themeMode;

  AppSettings copyWith({
    Household? household,
    bool? onboarded,
    int? leadDays,
    bool? semiAnnual,
    ThemeMode? themeMode,
    bool? permissionAsked,
  }) =>
      AppSettings(
        household: household ?? this.household,
        onboarded: onboarded ?? this.onboarded,
        leadDays: leadDays ?? this.leadDays,
        semiAnnual: semiAnnual ?? this.semiAnnual,
        themeMode: themeMode ?? this.themeMode,
        permissionAsked: permissionAsked ?? this.permissionAsked,
      );

  Map<String, String> toMap() => {
        'household': jsonEncode(household.toJson()),
        'onboarded': '$onboarded',
        'leadDays': '$leadDays',
        'semiAnnual': '$semiAnnual',
        'themeMode': themeMode.name,
        'permissionAsked': '$permissionAsked',
      };

  factory AppSettings.fromMap(Map<String, String> m) {
    Household h = const Household();
    try {
      h = Household.fromJson(
          Map<String, Object?>.from(jsonDecode(m['household'] ?? '{}') as Map));
    } catch (_) {}
    return AppSettings(
      household: h,
      onboarded: m['onboarded'] == 'true',
      leadDays: int.tryParse(m['leadDays'] ?? '') ?? 30,
      semiAnnual: m['semiAnnual'] == 'true',
      themeMode: ThemeMode.values.asNameMap()[m['themeMode']] ?? ThemeMode.system,
      permissionAsked: m['permissionAsked'] == 'true',
    );
  }
}

class SettingsRepository {
  SettingsRepository(this._db);
  final AppDatabase _db;

  Map<String, String> _toMap(List<SettingRow> rows) =>
      {for (final r in rows) r.key: r.value};

  Stream<AppSettings> watch() => _db
      .select(_db.settingRows)
      .watch()
      .map((rows) => AppSettings.fromMap(_toMap(rows)));

  Future<AppSettings> load() async =>
      AppSettings.fromMap(_toMap(await _db.select(_db.settingRows).get()));

  Future<void> save(AppSettings s) => _db.batch((b) {
        b.insertAllOnConflictUpdate(_db.settingRows, [
          for (final e in s.toMap().entries)
            SettingRowsCompanion.insert(key: e.key, value: e.value),
        ]);
      });
}
