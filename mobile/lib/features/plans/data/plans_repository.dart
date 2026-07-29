import '../../../core/api_client.dart';
import 'plan_models.dart';

class PlansRepository {
  Future<List<Plan>> getPlans() async {
    final res = await ApiClient.dio.get('/plans');
    return (res.data as List).map((e) => Plan.fromJson(e)).toList();
  }

  Future<Plan> getPlan(String slug) async {
    final res = await ApiClient.dio.get('/plans/$slug');
    return Plan.fromJson(res.data);
  }
}
