import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../noodplan/domain/plan_models.dart';
import '../noodplan/plan_providers.dart';
import 'data/shared_plan_store.dart';
import 'domain/shared_plan_logic.dart';

final sharedPlanStoreProvider =
    Provider((ref) => SharedPlanStore(ref.watch(settingsRepositoryProvider)));

/// Plannen die met mij zijn gedeeld, nieuwste eerst.
final sharedPlansProvider =
    StreamProvider<List<SharedPlan>>((ref) => ref.watch(sharedPlanStoreProvider).watch());

final lastSharedProvider = StreamProvider<ShareLog?>((ref) =>
    ref.watch(settingsRepositoryProvider).watchRaw(ShareLog.key).map(ShareLog.decode));

/// Het plan dat de app gebruikt voor afspraken, de wiki-blokken en de pdf's:
/// het eigen plan als dat iets bevat, anders het laatst gedeelde plan.
class EffectivePlan {
  const EffectivePlan(this.plan, {this.fromName});
  final Plan plan;

  /// Gevuld als het plan van iemand anders is ("van Anna").
  final String? fromName;
  bool get isShared => fromName != null;
}

final effectivePlanProvider = Provider<EffectivePlan>((ref) {
  final own = ref.watch(planProvider).value ?? const Plan();
  if (own.hasContent) return EffectivePlan(own);
  final shared = ref.watch(sharedPlansProvider).value ?? const [];
  if (shared.isEmpty) return EffectivePlan(own);
  try {
    return EffectivePlan(shared.first.plan, fromName: shared.first.fromName.isEmpty ? '?' : shared.first.fromName);
  } catch (_) {
    return EffectivePlan(own);
  }
});
