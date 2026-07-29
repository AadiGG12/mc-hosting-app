class AdminUser {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final bool rootAdmin;
  final bool useTotp;
  final String createdAt;

  AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.rootAdmin,
    required this.useTotp,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] ?? json;
    return AdminUser(
      id: attrs['id'] ?? 0,
      username: attrs['username'] ?? '',
      email: attrs['email'] ?? '',
      firstName: attrs['first_name'] ?? '',
      lastName: attrs['last_name'] ?? '',
      rootAdmin: attrs['root_admin'] == true,
      useTotp: attrs['2fa'] == true || attrs['use_totp'] == true,
      createdAt: attrs['created_at']?.toString() ?? '',
    );
  }
}

class AdminServer {
  final int id;
  final String uuid;
  final String identifier;
  final String name;
  final int ownerId;
  final int nodeId;
  final bool isSuspended;
  final int memory;
  final int disk;
  final int cpu;

  AdminServer({
    required this.id,
    required this.uuid,
    required this.identifier,
    required this.name,
    required this.ownerId,
    required this.nodeId,
    required this.isSuspended,
    required this.memory,
    required this.disk,
    required this.cpu,
  });

  factory AdminServer.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] ?? json;
    final limits = attrs['limits'] ?? {};
    return AdminServer(
      id: attrs['id'] ?? 0,
      uuid: attrs['uuid'] ?? '',
      identifier: attrs['identifier'] ?? attrs['id']?.toString() ?? '',
      name: attrs['name'] ?? 'Server',
      ownerId: attrs['user'] ?? attrs['owner_id'] ?? 0,
      nodeId: attrs['node'] ?? attrs['node_id'] ?? 0,
      isSuspended: attrs['suspended'] == true || attrs['is_suspended'] == true,
      memory: (limits['memory'] as num?)?.toInt() ?? 2048,
      disk: (limits['disk'] as num?)?.toInt() ?? 10240,
      cpu: (limits['cpu'] as num?)?.toInt() ?? 100,
    );
  }
}

class AdminNode {
  final int id;
  final String name;
  final String fqdn;
  final int locationId;
  final int memory;
  final int disk;
  final bool public;

  AdminNode({
    required this.id,
    required this.name,
    required this.fqdn,
    required this.locationId,
    required this.memory,
    required this.disk,
    required this.public,
  });

  factory AdminNode.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] ?? json;
    return AdminNode(
      id: attrs['id'] ?? 0,
      name: attrs['name'] ?? '',
      fqdn: attrs['fqdn'] ?? '',
      locationId: attrs['location_id'] ?? 0,
      memory: (attrs['memory'] as num?)?.toInt() ?? 0,
      disk: (attrs['disk'] as num?)?.toInt() ?? 0,
      public: attrs['public'] == true,
    );
  }
}

class AdminNest {
  final int id;
  final String name;
  final String author;
  final String description;

  AdminNest({
    required this.id,
    required this.name,
    required this.author,
    required this.description,
  });

  factory AdminNest.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] ?? json;
    return AdminNest(
      id: attrs['id'] ?? 0,
      name: attrs['name'] ?? '',
      author: attrs['author'] ?? '',
      description: attrs['description'] ?? '',
    );
  }
}
