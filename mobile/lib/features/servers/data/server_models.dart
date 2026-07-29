enum ServerStatus { running, offline, starting, stopping, suspended, unknown }

class Server {
  final String identifier;
  final String uuid;
  final String name;
  final ServerStatus status;
  final int memory; // MB
  final int disk;   // MB
  final int cpu;    // Percent
  final String node;
  final bool isSuspended;

  Server({
    required this.identifier,
    required this.uuid,
    required this.name,
    required this.status,
    required this.memory,
    required this.disk,
    required this.cpu,
    required this.node,
    required this.isSuspended,
  });

  factory Server.fromJson(Map<String, dynamic> json) {
    ServerStatus parseStatus(String? statusStr) {
      switch (statusStr?.toLowerCase()) {
        case 'running':
          return ServerStatus.running;
        case 'offline':
          return ServerStatus.offline;
        case 'starting':
          return ServerStatus.starting;
        case 'stopping':
          return ServerStatus.stopping;
        case 'suspended':
          return ServerStatus.suspended;
        default:
          return ServerStatus.running; // Default to running for active servers
      }
    }

    return Server(
      identifier: json['identifier'] ?? json['id']?.toString() ?? '',
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? 'Minecraft Server',
      status: parseStatus(json['status']?.toString()),
      memory: (json['memory'] as num?)?.toInt() ?? 2048,
      disk: (json['disk'] as num?)?.toInt() ?? 10240,
      cpu: (json['cpu'] as num?)?.toInt() ?? 100,
      node: json['node'] ?? 'Node 1',
      isSuspended: json['is_suspended'] == true,
    );
  }
}

class ServerFile {
  final String name;
  final int size;
  final bool isFile;
  final String mode;
  final DateTime? modifiedAt;

  ServerFile({
    required this.name,
    required this.size,
    required this.isFile,
    required this.mode,
    this.modifiedAt,
  });

  factory ServerFile.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] ?? json;
    return ServerFile(
      name: attrs['name'] ?? '',
      size: (attrs['size'] as num?)?.toInt() ?? 0,
      isFile: attrs['is_file'] ?? (attrs['mode'] != null && !attrs['mode'].toString().startsWith('d')),
      mode: attrs['mode'] ?? '-rw-r--r--',
      modifiedAt: attrs['modified_at'] != null ? DateTime.tryParse(attrs['modified_at'].toString()) : null,
    );
  }
}

class ServerBackup {
  final String uuid;
  final String name;
  final int bytes;
  final bool isSuccessful;
  final DateTime? createdAt;

  ServerBackup({
    required this.uuid,
    required this.name,
    required this.bytes,
    required this.isSuccessful,
    this.createdAt,
  });

  factory ServerBackup.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] ?? json;
    return ServerBackup(
      uuid: attrs['uuid'] ?? json['uuid'] ?? '',
      name: attrs['name'] ?? 'Backup',
      bytes: (attrs['bytes'] as num?)?.toInt() ?? 0,
      isSuccessful: attrs['is_successful'] ?? true,
      createdAt: attrs['created_at'] != null ? DateTime.tryParse(attrs['created_at'].toString()) : null,
    );
  }
}
