import '../../../core/api_client.dart';
import 'server_models.dart';

class ServerRepository {
  Future<List<Server>> getServers() async {
    final res = await ApiClient.dio.get('/servers');
    final list = res.data as List;
    return list.map((e) => Server.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Server> getServer(String identifier) async {
    final res = await ApiClient.dio.get('/servers/$identifier');
    return Server.fromJson(res.data as Map<String, dynamic>);
  }

  Future<bool> sendPowerSignal(String identifier, String signal) async {
    final res = await ApiClient.dio.post(
      '/servers/$identifier/power',
      data: {'signal': signal},
    );
    return res.data['success'] == true;
  }

  Future<Map<String, dynamic>> getWebsocketCredentials(String identifier) async {
    final res = await ApiClient.dio.get('/servers/$identifier/websocket');
    return res.data as Map<String, dynamic>;
  }

  Future<List<ServerFile>> listFiles(String identifier, String directory) async {
    final res = await ApiClient.dio.get(
      '/servers/$identifier/files/list',
      queryParameters: {'directory': directory},
    );
    final list = res.data as List;
    return list.map((e) => ServerFile.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> getFileContents(String identifier, String filePath) async {
    final res = await ApiClient.dio.get(
      '/servers/$identifier/files/contents',
      queryParameters: {'file_path': filePath},
    );
    return res.data['content']?.toString() ?? '';
  }

  Future<bool> writeFileContents(String identifier, String filePath, String content) async {
    final res = await ApiClient.dio.post(
      '/servers/$identifier/files/write',
      data: {
        'file_path': filePath,
        'content': content,
      },
    );
    return res.data['success'] == true;
  }

  Future<bool> deleteFile(String identifier, String root, List<String> files) async {
    final res = await ApiClient.dio.post(
      '/servers/$identifier/files/delete',
      data: {
        'root': root,
        'files': files,
      },
    );
    return res.data['success'] == true;
  }

  Future<List<ServerBackup>> listBackups(String identifier) async {
    final res = await ApiClient.dio.get('/servers/$identifier/backups');
    final list = res.data as List;
    return list.map((e) => ServerBackup.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ServerBackup> createBackup(String identifier) async {
    final res = await ApiClient.dio.post('/servers/$identifier/backups');
    return ServerBackup.fromJson(res.data as Map<String, dynamic>);
  }

  Future<bool> deleteBackup(String identifier, String backupId) async {
    final res = await ApiClient.dio.delete('/servers/$identifier/backups/$backupId');
    return res.data['success'] == true;
  }
}
