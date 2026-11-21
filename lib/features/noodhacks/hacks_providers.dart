import 'dart:convert';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'hacks_models.dart';

const hacksAsset = 'assets/wiki/noodhacks.json';

/// Gebundelde noodhacks; geen netwerk nodig. Conceptplannen (status draft) zijn er alleen in een debug-build.
final hacksProvider = FutureProvider<HackData>((ref) async {
  // De vlag wordt vóór de eerste await gelezen: een provider mag na een await niet meer watchen.
  final release = ref.watch(hacksReleaseModeProvider);
  return HackData.parse(await rootBundle.loadString(hacksAsset)).visible(release: release);
});

/// Test-haak: in een release-build zijn conceptplannen onzichtbaar.
final hacksReleaseModeProvider = Provider<bool>((ref) => kReleaseMode);

const _materialsKey = 'hacks_materials';
const _favsKey = 'hacks_favorites';

Set<String> _decode(String? s) {
  if (s == null) return {};
  try {
    return {for (final e in jsonDecode(s) as List) e.toString()};
  } catch (_) {
    return {};
  }
}

/// Lokaal bewaarde keuzes: welke materialen heb je, en favorieten.
class HacksPrefs {
  HacksPrefs(this._ref);
  final Ref _ref;

  Future<void> setMaterials(Set<String> ids) => _ref
      .read(settingsRepositoryProvider)
      .setRaw(_materialsKey, jsonEncode(ids.toList()..sort()));

  Future<void> toggleFavorite(String id, Set<String> current) {
    final next = {...current};
    if (!next.remove(id)) next.add(id);
    return _ref.read(settingsRepositoryProvider).setRaw(_favsKey, jsonEncode(next.toList()..sort()));
  }
}

final hacksPrefsProvider = Provider((ref) => HacksPrefs(ref));

final hacksMaterialsProvider = StreamProvider<Set<String>>(
    (ref) => ref.watch(settingsRepositoryProvider).watchRaw(_materialsKey).map(_decode));

final hacksFavoritesProvider = StreamProvider<Set<String>>(
    (ref) => ref.watch(settingsRepositoryProvider).watchRaw(_favsKey).map(_decode));

IconData hackCategoryIcon(String name) => switch (name) {
      'water' => Icons.water_drop_outlined,
      'cook' => Icons.outdoor_grill_outlined,
      'food' => Icons.kitchen_outlined,
      'warm' => Icons.local_fire_department_outlined,
      'hygiene' => Icons.clean_hands_outlined,
      'energy' => Icons.bolt_outlined,
      'myth' => Icons.block_rounded,
      'hulp' => Icons.phone_in_talk_outlined,
      'eerste-hulp' => Icons.medical_services_outlined,
      'veiligheid' => Icons.health_and_safety_outlined,
      _ => Icons.tips_and_updates_outlined,
    };

/// Icoon per categorie-id uit noodhacks.json.
IconData hackCategoryIconById(String id) => hackCategoryIcon(switch (id) {
      'koken' => 'cook',
      'eten' => 'food',
      'warmte' => 'warm',
      'energie' => 'energy',
      'mythes' => 'myth',
      _ => id,
    });

IconData hackMaterialIcon(String name) => switch (name) {
      'bottle' => Icons.local_drink_outlined,
      'cloth' => Icons.dry_cleaning_outlined,
      'pot' => Icons.soup_kitchen_outlined,
      'burner' => Icons.outdoor_grill_outlined,
      'bleach' => Icons.science_outlined,
      'tablet' => Icons.medication_outlined,
      'freezer' => Icons.ac_unit,
      'blanket' => Icons.bed_outlined,
      'hands' => Icons.clean_hands_outlined,
      'flashlight' => Icons.flashlight_on_outlined,
      'radio' => Icons.radio_outlined,
      'powerbank' => Icons.battery_charging_full_outlined,
      _ => Icons.inventory_2_outlined,
    };
