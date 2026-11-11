import 'dart:convert';

import '../../../data/repositories/settings_repository.dart';
import '../domain/shared_plan_logic.dart';

/// Bewaart plannen die met mij zijn gedeeld, lokaal in de instellingentabel
/// (geen schemawijziging). Alleen-lezen voor de gebruiker; bijwerken gebeurt
/// door opnieuw te scannen.
class SharedPlanStore {
  SharedPlanStore(this._repo);
  final SettingsRepository _repo;

  static const maxPlans = 20;
  static const _index = 'shared_plans';
  static String _key(String id) => 'shared_plan:$id';

  List<Map<String, dynamic>> _decodeIndex(String? raw) {
    if (raw == null) return const [];
    try {
      return [for (final e in jsonDecode(raw) as List) if (e is Map<String, dynamic>) e];
    } catch (_) {
      return const [];
    }
  }

  Future<List<SharedPlan>> _load(String? rawIndex) async {
    final out = <SharedPlan>[];
    for (final m in _decodeIndex(rawIndex)) {
      final id = m['planId'];
      if (id is! String) continue;
      final json = await _repo.getRaw(_key(id));
      if (json == null) continue;
      final p = SharedPlan.fromMeta(m, json);
      if (p != null) out.add(p);
    }
    out.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return out;
  }

  Stream<List<SharedPlan>> watch() => _repo.watchRaw(_index).asyncMap(_load);

  Future<List<SharedPlan>> list() async => _load(await _repo.getRaw(_index));

  Future<SharedPlan?> get(String planId) async {
    for (final p in await list()) {
      if (p.planId == planId) return p;
    }
    return null;
  }

  /// Slaat op of vervangt (zelfde planId). Eerst de inhoud, dan de index, zodat
  /// een onderbreking nooit een verwijzing zonder inhoud achterlaat.
  Future<void> save(SharedPlan plan) async {
    final existing = await list();
    final others = [for (final p in existing) if (p.planId != plan.planId) p];
    final all = [plan, ...others]..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    final keep = all.take(maxPlans).toList();
    await _repo.setRaw(_key(plan.planId), plan.json);
    await _repo.setRaw(_index, jsonEncode([for (final p in keep) p.metaJson()]));
    for (final dropped in all.skip(maxPlans)) {
      await _repo.deleteRaw(_key(dropped.planId));
    }
  }

  Future<void> remove(String planId) async {
    final others = [for (final p in await list()) if (p.planId != planId) p];
    await _repo.setRaw(_index, jsonEncode([for (final p in others) p.metaJson()]));
    await _repo.deleteRaw(_key(planId));
  }
}

/// Lokale regel "Laatst gedeeld op (datum) met (toestel), wat". Nooit inhoud.
class ShareLog {
  const ShareLog({required this.at, required this.device, required this.what});
  final DateTime at;
  final String device;

  /// Bijvoorbeeld "plan" of "plan en 2 documenten": alleen aantallen en soorten.
  final String what;

  static const key = 'deel_laatst';

  String encode() => jsonEncode({'at': at.toIso8601String(), 'device': device, 'what': what});

  static ShareLog? decode(String? raw) {
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final at = DateTime.tryParse('${m['at']}');
      if (at == null) return null;
      return ShareLog(at: at, device: '${m['device']}', what: '${m['what']}');
    } catch (_) {
      return null;
    }
  }
}
