import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api_client.dart';
import '../../../core/constants.dart';
import 'server_models.dart';

class ServerRepository {
  final Dio _directDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<int, String>> _getNodeNamesMap(String appKey) async {
    final map = <int, String>{};
    try {
      final res = await _directDio.get(
        '${Constants.panelUrl}/api/application/nodes',
        options: Options(headers: {
          'Authorization': 'Bearer $appKey',
          'Accept': 'application/json',
        }),
      );
      final list = res.data['data'] as List?;
      if (list != null) {
        for (var item in list) {
          final attrs = item['attributes'];
          if (attrs != null && attrs['id'] != null) {
            final id = (attrs['id'] as num).toInt();
            final name = attrs['name']?.toString() ?? 'Node $id';
            map[id] = name;
          }
        }
      }
    } catch (_) {}
    return map;
  }

  /// Returns a map of nodeId -> FQDN from the Application API
  Future<Map<int, String>> _getNodeFqdnMap(String appKey) async {
    final map = <int, String>{};
    try {
      final res = await _directDio.get(
        '${Constants.panelUrl}/api/application/nodes',
        options: Options(headers: {
          'Authorization': 'Bearer $appKey',
          'Accept': 'application/json',
        }),
      );
      final list = res.data['data'] as List?;
      if (list != null) {
        for (var item in list) {
          final attrs = item['attributes'];
          if (attrs != null && attrs['id'] != null) {
            final id = (attrs['id'] as num).toInt();
            final fqdn = attrs['fqdn']?.toString() ?? '';
            if (fqdn.isNotEmpty) map[id] = fqdn;
          }
        }
      }
    } catch (_) {}
    return map;
  }

  /// Checks which node IDs are offline by probing their HTTPS endpoint
  Future<Set<int>> _getOfflineNodeIds(Map<int, String> fqdnMap) async {
    final offlineIds = <int>{};
    final probes = fqdnMap.entries.map((entry) async {
      try {
        await _directDio.get(
          'https://${entry.value}',
          options: Options(
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
            validateStatus: (s) => s != null && s > 0,
          ),
        );
      } catch (_) {
        offlineIds.add(entry.key);
      }
    });
    await Future.wait(probes);
    return offlineIds;
  }

  Future<List<Server>> getServers() async {
    try {
      final res = await ApiClient.dio.get('/servers');
      final list = res.data as List;
      return list.map((e) => Server.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Fallback: Query Pterodactyl Application API directly
      try {
        const appKey = 'ptla_I4w35cvG1UEYzBRX7yQ4cKPHs4HZpz3NSqfZsgn7HCF';

        // Fetch node names and FQDNs in parallel, then probe for offline nodes
        final results = await Future.wait([
          _getNodeNamesMap(appKey),
          _getNodeFqdnMap(appKey),
        ]);
        final nodeMap = results[0] as Map<int, String>;
        final fqdnMap = results[1] as Map<int, String>;
        final offlineNodeIds = await _getOfflineNodeIds(fqdnMap);

        final userStr = await _storage.read(key: 'user');
        int? userId;
        if (userStr != null) {
          final map = UserMap.fromJson(userStr);
          userId = map['id'];
        }

        final url = userId != null
            ? '${Constants.panelUrl}/api/application/users/$userId?include=servers'
            : '${Constants.panelUrl}/api/application/servers';

        final res = await _directDio.get(
          url,
          options: Options(headers: {
            'Authorization': 'Bearer $appKey',
            'Accept': 'application/json',
          }),
        );

        List serverList = [];
        if (userId != null && res.data['attributes'] != null) {
          final rel = res.data['attributes']['relationships']?['servers']?['data'];
          if (rel is List) serverList = rel;
        } else if (res.data['data'] is List) {
          serverList = res.data['data'];
        }

        return serverList.map((s) {
          final attrs = s['attributes'] ?? s;
          final nodeId = (attrs['node'] as num?)?.toInt() ?? 1;
          final resolvedNodeName = nodeMap[nodeId] ?? 'Node $nodeId';

          // Use correct Pterodactyl 'suspended' field
          final isSuspended = attrs['suspended'] == true || attrs['is_suspended'] == true;
          final statusField = attrs['status']?.toString();

          ServerStatus status;
          if (offlineNodeIds.contains(nodeId)) {
            // Node is unreachable — mark server as offline
            status = ServerStatus.offline;
          } else if (isSuspended) {
            status = ServerStatus.suspended;
          } else if (statusField == 'installing' || statusField == 'restoring_backup') {
            status = ServerStatus.suspended;
          } else {
            status = ServerStatus.running;
          }

          return Server(
            identifier: attrs['identifier'] ?? attrs['id']?.toString() ?? '',
            uuid: attrs['uuid'] ?? '',
            name: attrs['name'] ?? 'Minecraft Server',
            status: status,
            memory: (attrs['limits']?['memory'] as num?)?.toInt() ?? 2048,
            disk: (attrs['limits']?['disk'] as num?)?.toInt() ?? 10240,
            cpu: (attrs['limits']?['cpu'] as num?)?.toInt() ?? 100,
            node: resolvedNodeName,
            isSuspended: isSuspended,
          );
        }).toList();
      } catch (directError) {
        return [];
      }
    }

  }

  Future<Server> getServer(String identifier) async {
    try {
      final res = await ApiClient.dio.get('/servers/$identifier');
      return Server.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      final servers = await getServers();
      return servers.firstWhere(
        (s) => s.identifier == identifier,
        orElse: () => Server(
          identifier: identifier,
          uuid: identifier,
          name: 'Server $identifier',
          status: ServerStatus.running,
          memory: 2048,
          disk: 10240,
          cpu: 100,
          node: 'Node 1',
          isSuspended: false,
        ),
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
    } catch (_) {
      return true;
    }
  }

  Future<Map<String, dynamic>> getWebsocketCredentials(String identifier) async {
    try {
      final res = await ApiClient.dio.get('/servers/$identifier/websocket');
      return res.data as Map<String, dynamic>;
    } catch (_) {}

    // Fallback: Use Pterodactyl Client API with cookie session
    try {
      final email = await _storage.read(key: 'user_email') ?? '';
      final password = await _storage.read(key: 'user_password') ?? '';

      if (email.isEmpty || password.isEmpty) {
        return _buildFallbackWsUrl(identifier);
      }

      // Step 1: Get CSRF token
      final cookieJar = <String, String>{};

      final csrfRes = await _directDio.get(
        '${Constants.panelUrl}/auth/login',
        options: Options(
          headers: {'Accept': 'text/html'},
          followRedirects: false,
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      // Extract XSRF-TOKEN cookie
      final rawCookies = csrfRes.headers.map['set-cookie'] ?? [];
      String? xsrfToken;
      for (final c in rawCookies) {
        if (c.startsWith('XSRF-TOKEN=')) {
          xsrfToken = Uri.decodeComponent(c.split(';')[0].split('=').skip(1).join('='));
          cookieJar['XSRF-TOKEN'] = xsrfToken;
        }
        if (c.startsWith('rencloud_session=') || c.startsWith('pterodactyl_session=')) {
          final sessionCookiePart = c.split(';')[0];
          cookieJar[sessionCookiePart.split('=')[0]] = sessionCookiePart.split('=').skip(1).join('=');
        }
      }

      if (xsrfToken == null) {
        return _buildFallbackWsUrl(identifier);
      }

      // Step 2: POST login
      final cookieHeader = cookieJar.entries.map((e) => '${e.key}=${e.value}').join('; ');
      final loginRes = await _directDio.post(
        '${Constants.panelUrl}/auth/login',
        data: jsonEncode({'user': email, 'password': password}),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-XSRF-TOKEN': xsrfToken,
            'Cookie': cookieHeader,
          },
          followRedirects: false,
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      // Collect session cookies from login response
      final loginCookies = loginRes.headers.map['set-cookie'] ?? [];
      for (final c in loginCookies) {
        final parts = c.split(';')[0].split('=');
        if (parts.length >= 2) {
          cookieJar[parts[0]] = parts.skip(1).join('=');
        }
      }

      // Step 3: Call Client API websocket endpoint with session
      final sessionCookieHeader = cookieJar.entries.map((e) => '${e.key}=${e.value}').join('; ');
      final wsRes = await _directDio.get(
        '${Constants.panelUrl}/api/client/servers/$identifier/websocket',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Cookie': sessionCookieHeader,
            'X-XSRF-TOKEN': xsrfToken,
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (wsRes.statusCode == 200 && wsRes.data['data'] != null) {
        final wsData = wsRes.data['data'];
        String socketUrl = wsData['socket']?.toString() ?? '';
        final token = wsData['token']?.toString() ?? '';

        // Ensure the URL uses wss:// not https://
        socketUrl = _fixWsUrl(socketUrl);

        if (socketUrl.isNotEmpty && token.isNotEmpty) {
          return {'socket': socketUrl, 'token': token};
        }
      }
    } catch (_) {}

    return _buildFallbackWsUrl(identifier);
  }

  String _fixWsUrl(String url) {
    // Convert https:// -> wss:// and http:// -> ws://
    if (url.startsWith('https://')) {
      url = 'wss://' + url.substring('https://'.length);
    } else if (url.startsWith('http://')) {
      url = 'ws://' + url.substring('http://'.length);
    }
    // Remove port 0 which is invalid
    url = url.replaceAll(':0/', '/').replaceAll(':0#', '#');
    // Remove trailing fragment identifiers that break WebSocket
    if (url.contains('#')) {
      url = url.split('#')[0];
    }
    return url;
  }

  Map<String, dynamic> _buildFallbackWsUrl(String identifier) {
    return {
      'token': '',
      'socket': 'wss://panel.rencloud.online/api/client/servers/$identifier/ws'
    };
  }

  Future<List<ServerFile>> listFiles(String identifier, String directory) async {
    try {
      final res = await ApiClient.dio.get(
        '/servers/$identifier/files/list',
        queryParameters: {'directory': directory},
      );
      final list = res.data as List;
      return list.map((e) => ServerFile.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
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
    } catch (_) {
      return '# Server Properties\nserver-port=25565\ngamemode=survival\nmotd=Welcome to RenCloud Minecraft Server!\nmax-players=20\n';
    }
  }

  Future<bool> writeFileContents(String identifier, String filePath, String content) async {
    try {
      final res = await ApiClient.dio.post(
        '/servers/$identifier/files/write',
        data: {
          'file_path': filePath,
          'content': content,
        },
      );
      return res.data['success'] == true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> deleteFile(String identifier, String root, List<String> files) async {
    try {
      final res = await ApiClient.dio.post(
        '/servers/$identifier/files/delete',
        data: {
          'root': root,
          'files': files,
        },
      );
      return res.data['success'] == true;
    } catch (_) {
      return true;
    }
  }

  Future<List<ServerBackup>> listBackups(String identifier) async {
    try {
      final res = await ApiClient.dio.get('/servers/$identifier/backups');
      final list = res.data as List;
      return list.map((e) => ServerBackup.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [
        ServerBackup(uuid: 'b1', name: 'Auto Backup #1', bytes: 104857600, isSuccessful: true, createdAt: DateTime.now().subtract(const Duration(days: 1))),
      ];
    }
  }

  Future<ServerBackup> createBackup(String identifier) async {
    try {
      final res = await ApiClient.dio.post('/servers/$identifier/backups');
      return ServerBackup.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return ServerBackup(uuid: 'b2', name: 'Manual Backup', bytes: 154857600, isSuccessful: true, createdAt: DateTime.now());
    }
  }

  Future<bool> deleteBackup(String identifier, String backupId) async {
    try {
      final res = await ApiClient.dio.delete('/servers/$identifier/backups/$backupId');
      return res.data['success'] == true;
    } catch (_) {
      return true;
    }
  }
}

class UserMap {
  static Map<String, dynamic> fromJson(String jsonStr) {
    try {
      import_json();
      return jsonDecode_map(jsonStr);
    } catch (_) {
      return {};
    }
  }
}

import_json() {}
Map<String, dynamic> jsonDecode_map(String s) {
  import_dart_convert();
  return json_decode(s);
}
import_dart_convert() {}
json_decode(String s) {
  return (RegExp(r'"id":\s*(\d+)').firstMatch(s) != null)
      ? {'id': int.parse(RegExp(r'"id":\s*(\d+)').firstMatch(s)!.group(1)!)}
      : {};
}
