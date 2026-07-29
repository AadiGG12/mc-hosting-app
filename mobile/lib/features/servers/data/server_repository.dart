import '../../../core/api_client.dart';
import 'server_models.dart';

class ServerRepository {
  Future<List<Server>> getServers() async {
    final res = await ApiClient.dio.get('/servers'); // Using backend proxy
    return (res.data as List).map((e) => Server.fromJson(e)).toList();
  }
  
  Future<Server> getServer(String id) async {
    final res = await ApiClient.dio.get('/servers/$id');
    return Server.fromJson(res.data);
  }
}
