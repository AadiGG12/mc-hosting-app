import 'package:dio/dio.dart';
import '../../../core/constants.dart';
import 'admin_models.dart';

class AdminRepository {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: Constants.panelUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Authorization': 'Bearer ptla_I4w35cvG1UEYzBRX7yQ4cKPHs4HZpz3NSqfZsgn7HCF',
      'Accept': 'application/json',
    },
  ));

  Future<List<AdminUser>> getUsers({int page = 1}) async {
    try {
      final res = await _dio.get('/api/application/users', queryParameters: {'page': page});
      final data = res.data['data'] as List?;
      if (data == null) return [];
      return data.map((e) => AdminUser.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<AdminServer>> getServers({int page = 1}) async {
    try {
      final res = await _dio.get('/api/application/servers', queryParameters: {'page': page});
      final data = res.data['data'] as List?;
      if (data == null) return [];
      return data.map((e) => AdminServer.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<AdminNode>> getNodes() async {
    try {
      final res = await _dio.get('/api/application/nodes');
      final data = res.data['data'] as List?;
      if (data == null) return [];
      return data.map((e) => AdminNode.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<AdminNest>> getNests() async {
    try {
      final res = await _dio.get('/api/application/nests');
      final data = res.data['data'] as List?;
      if (data == null) return [];
      return data.map((e) => AdminNest.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> suspendServer(int serverId) async {
    try {
      await _dio.post('/api/application/servers/$serverId/suspend');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unsuspendServer(int serverId) async {
    try {
      await _dio.post('/api/application/servers/$serverId/unsuspend');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteServer(int serverId) async {
    try {
      await _dio.delete('/api/application/servers/$serverId');
      return true;
    } catch (_) {
      return false;
    }
  }
}
