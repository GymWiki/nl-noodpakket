import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'data/rampenzender_models.dart';

const radioAsset = 'assets/radio/rampenzenders.json';

/// Gebundelde data; geen netwerk nodig.
final radioDataProvider =
    FutureProvider<RadioData>((ref) async => RadioData.parse(await rootBundle.loadString(radioAsset)));

/// Instellingen van de gebruiker, opgeslagen in de bestaande instellingentabel.
class RadioKeys {
  static const gm = 'radio_gm';
  static const area = 'radio_area';
  static const set = 'radio_set';
}

class RadioPrefs {
  const RadioPrefs({this.gm, this.area, this.radioSet = false});
  final String? gm, area;
  final bool radioSet;
}

final radioPrefsProvider = Provider<RadioPrefs>((ref) {
  final raw = ref.watch(settingsProvider.select((s) => s.value?.raw)) ?? const <String, String>{};
  String? v(String k) => (raw[k] == null || raw[k]!.isEmpty) ? null : raw[k];
  return RadioPrefs(gm: v(RadioKeys.gm), area: v(RadioKeys.area), radioSet: raw[RadioKeys.set] == 'true');
});

/// Resultaat voor de opgeslagen regio, of null zolang er geen regio is gekozen.
final radioResultProvider = Provider<RadioResult?>((ref) {
  final d = ref.watch(radioDataProvider).value;
  final p = ref.watch(radioPrefsProvider);
  return d?.resultFor(p.gm);
});

class RadioActions {
  RadioActions(this._ref);
  final Ref _ref;

  Future<void> chooseRegion(String gm) async {
    final repo = _ref.read(settingsRepositoryProvider);
    if (_ref.read(radioPrefsProvider).gm != gm) {
      await repo.deleteRaw(RadioKeys.area);
      await repo.deleteRaw(RadioKeys.set);
    }
    await repo.setRaw(RadioKeys.gm, gm);
  }

  Future<void> clearRegion() async {
    final repo = _ref.read(settingsRepositoryProvider);
    await repo.deleteRaw(RadioKeys.gm);
    await repo.deleteRaw(RadioKeys.area);
    await repo.deleteRaw(RadioKeys.set);
  }

  Future<void> chooseArea(String? id) => id == null
      ? _ref.read(settingsRepositoryProvider).deleteRaw(RadioKeys.area)
      : _ref.read(settingsRepositoryProvider).setRaw(RadioKeys.area, id);

  Future<void> setRadioReady(bool v) => v
      ? _ref.read(settingsRepositoryProvider).setRaw(RadioKeys.set, 'true')
      : _ref.read(settingsRepositoryProvider).deleteRaw(RadioKeys.set);
}

final radioActionsProvider = Provider((ref) => RadioActions(ref));
