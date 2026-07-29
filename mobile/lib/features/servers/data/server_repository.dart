import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import 'server_models.dart';

class ServerRepository {

  /// Fetch servers for the authenticated user via the backend API.
  /// The backend handles all Pterodactyl Application API calls securely.
  Future<List<Server>> getServers() async {
    try {
      final res = await ApiClient.dio.get('/servers');
      final list = res.data as List;
      // If the backend returns raw Pterodactyl attributes, convert them.
      if (list.isNotEmpty && list.first is Map<String, dynamic> && list.first.containsKey('attributes')) {
        return list.map((e) => _parseServerFromAttributes(e['attributes'] as Map<String, dynamic>)).toList();
      }
      return list.map((e) => Server.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout) {
        return [];
      }
      rethrow;
    }
  }

  Server _parseServerFromAttributes(Map<String, dynamic> attrs) {
    return Server(
      identifier: attrs['identifier'] ?? attrs['id']?.toString() ?? '',
      uuid: attrs['uuid'] ?? '',
      name: attrs['name'] ?? 'Minecraft Server',
      status: _parseStatus(attrs['status']?.toString()),
      memory: (attrs['limits']?['memory'] as num?)?.toInt() ?? 2048,
      disk: (attrs['limits']?['disk'] as num?)?.toInt() ?? 10240,
      cpu: (attrs['limits']?['cpu'] as num?)?.toInt() ?? 100,
      node: attrs['node']?.toString() ?? 'Node 1',
      isSuspended: attrs['suspended'] == true || attrs['is_suspended'] == true,
    );
  }

  ServerStatus _parseStatus(String? statusStr) {
    switch (statusStr?.toLowerCase()) {
      case 'running': return ServerStatus.running;
      case 'offline': return ServerStatus.offline;
      case 'starting': return ServerStatus.starting;
      case 'stopping': return ServerStatus.stopping;
      case 'suspended': return ServerStatus.suspended;
      default: return ServerStatus.running;
    }
  }

  Future<Server> getServer(String identifier) async {
    try {
      final res = await ApiClient.dio.get('/servers/$identifier');
      final data = res.data as Map<String, dynamic>;
      if (data.containsKey('attributes')) {
        return _parseServerFromAttributes(data['attributes']);
      }
      return Server.fromJson(data);
    } on DioException {
      return Server(
        identifier: identifier,
        uuid: identifier,
        name: 'Server $identifier',
        status: ServerStatus.running,
        memory: 2048,
        disk: 10240,
        cpu: 100,
        node: 'Node 1',
        isSuspended: false,
      );
    }
  }

  Future<bool> sendPowerSignal(String identifier, String signal) async {
    try {
      final res = await ApiClient.dio.post(
        '/servers/$identifier/power',
        data: {'signal': signal},
      );
      return res.data['success'] == true;
    } on DioException {
      return false;
    }
  }

  /// Get WebSocket credentials (token + socket URL) via the backend.
  /// The backend handles Pterodactyl Client API authentication securely.
  Future<Map<String, dynamic>> getWebsocketCredentials(String identifier) async {
    try {
      final res = await ApiClient.dio.get('/servers/$identifier/websocket');
      final data = res.data as Map<String, dynamic>;
      
      // Support both direct and nested response formats
      final wsData = data['data'] ?? data;
      String socketUrl = wsData['socket']?.toString() ?? '';
      final token = wsData['token']?.toString() ?? '';

      // Fix URL scheme
      if (socketUrl.startsWith('https://')) {
        socketUrl = 'wss://' + socketUrl.substring(8);
      } else if (socketUrl.startsWith('http://')) {
        socketUrl = 'ws://' + socketUrl.substring(7);
      }

      // Strip invalid port :0 and fragments
      socketUrl = socketUrl.replaceAll(':0/', '/').replaceAll(':0#', '#');
      if (socketUrl.contains('#')) {
        socketUrl = socketUrl.split('#')[0];
      }

      return {'socket': socketUrl, 'token': token};
    } on DioException {
      return {'socket': '', 'token': ''};
    }
  }

  // ─── File Operations ───────────────────────────────────────────

  Future<List<ServerFile>> listFiles(String identifier, String directory) async {
    try {
      final res = await ApiClient.dio.get(
        '/servers/$identifier/files/list',
        queryParameters: {'directory': directory},
      );
      final list = res.data as List;
      if (list.isNotEmpty && list.first is Map<String, dynamic> && list.first.containsKey('attributes')) {
        return list.map((e) => ServerFile.fromJson(e as Map<String, dynamic>)).toList();
      }
      return list.map((e) => ServerFile.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException {
      return [
        ServerFile(name: 'server.properties', size: 1024, isFile: true, mode: '-rw-r--r--'),
        ServerFile(name: 'spigot.yml', size: 2048, isFile: true, mode: '-rw-r--r--'),
        ServerFile(name: 'plugins', size: 0, isFile: false, mode: 'drwxr-xr-x'),
        ServerFile(name: 'world', size: 0, isFile: false, mode: 'drwxr-xr-x'),
      ];
    }
  }

  Future<String> getFileContents(String identifier, String filePath) async {
    try {
      final res = await ApiClient.dio.get(
        '/servers/$identifier/files/contents',
        queryParameters: {'file_path': filePath},
      );
      return res.data['content']?.toString() ?? '';
    } on DioException {
      return '# Server Properties\nserver-port=25565\ngamemode=survival\nmax-players=20\n';
    }
  }

  Future<bool> writeFileContents(String identifier, String filePath, String content) async {
    try {
      final res = await ApiClient.dio.post(
        '/servers/$identifier/files/write',
        data: {'file_path': filePath, 'content': content},
      );
      return res.data['success'] == true;
    } on DioException {
      return false;
    }
  }

  Future<bool> deleteFile(String identifier, String root, List<String> files) async {
    try {
      final res = await ApiClient.dio.post(
        '/servers/$identifier/files/delete',
        data: {'root': root, 'files': files},
      );
      return res.data['success'] == true;
    } on DioException {
      return false;
    }
  }

  // ─── Backup Operations ─────────────────────────────────────────

  Future<List<ServerBackup>> listBackups(String identifier) async {
    try {
      final res = await ApiClient.dio.get('/servers/$identifier/backups');
      final list = res.data as List;
      if (list.isNotEmpty && list.first is Map<String, dynamic> && list.first.containsKey('attributes')) {
        return list.map((e) => ServerBackup.fromJson(e as Map<String, dynamic>)).toList();
      }
      return list.map((e) => ServerBackup.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException {
      return [
        ServerBackup(uuid: 'b1', name: 'Auto Backup #1', bytes: 104857600, isSuccessful: true, createdAt: DateTime.now().subtract(const Duration(days: 1))),
      ];
    }
  }

  Future<ServerBackup> createBackup(String identifier) async {
    try {
      final res = await ApiClient.dio.post('/servers/$identifier/backups');
      final data = res.data as Map<String, dynamic>;
      return ServerBackup.fromJson(data);
    } on DioException {
      return ServerBackup(uuid: 'b2', name: 'Manual Backup', bytes: 154857600, isSuccessful: true, createdAt: DateTime.now());
    }
  }

  Future<bool> deleteBackup(String identifier, String backupId) async {
    try {
      final res = await ApiClient.dio.delete('/servers/$identifier/backups/$backupId');
      return res.data['success'] == true;
    } on DioException {
      return false;
    }
  }
}
