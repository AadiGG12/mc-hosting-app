import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/plans_repository.dart';
import '../data/plan_models.dart';
import '../data/plans_websocket_service.dart';

final plansRepoProvider = Provider((ref) => PlansRepository());

/// Auto-refreshing plans provider connected to the real-time WebSocket.
///
/// Watches [planUpdateSignalProvider] — whenever the WebSocket pushes a
/// plan change, this provider re-fetches the plan list so every customer
/// device automatically sees the update without manual refresh.
final plansProvider = FutureProvider<List<Plan>>((ref) async {
  // 1. Watch the signal provider so changes trigger re-evaluation
  ref.watch(planUpdateSignalProvider);

  // 2. Start the WebSocket connection (first time only)
  final wsService = ref.read(planWebSocketServiceProvider);
  if (!wsService.isConnected) {
    wsService.connect();
  }

  // 3. Fetch the latest plans from the backend
  return ref.read(plansRepoProvider).getPlans();
});

final planProvider = FutureProvider.family<Plan, String>((ref, slug) async {
  return ref.read(plansRepoProvider).getPlan(slug);
});
