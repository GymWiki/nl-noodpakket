import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/repositories/plan_repository.dart';
import 'domain/plan_models.dart';
import 'domain/plan_progress.dart';

final planRepositoryProvider =
    Provider((ref) => PlanRepository(ref.watch(databaseProvider)));

/// Het huidige noodplan (leeg plan als er nog niets is ingevuld).
final planProvider =
    StreamProvider<Plan>((ref) => ref.watch(planRepositoryProvider).watch());

final planProgressProvider = Provider<PlanProgress>((ref) =>
    planProgress(ref.watch(planProvider).value ?? const Plan()));
