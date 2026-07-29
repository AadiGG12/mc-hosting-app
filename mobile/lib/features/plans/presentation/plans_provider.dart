import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/plans_repository.dart';
import '../data/plan_models.dart';

final plansRepoProvider = Provider((ref) => PlansRepository());

final plansProvider = FutureProvider<List<Plan>>((ref) async {
  return ref.read(plansRepoProvider).getPlans();
});

final planProvider = FutureProvider.family<Plan, String>((ref, slug) async {
  return ref.read(plansRepoProvider).getPlan(slug);
});
