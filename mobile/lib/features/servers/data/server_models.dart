enum ServerStatus { running, offline, starting, stopping, unknown }

class Server {
  final String identifier;
  final String name;
  final ServerStatus status;
  
  Server({required this.identifier, required this.name, required this.status});

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      identifier: json['identifier'] ?? '',
      name: json['name'] ?? '',
      status: ServerStatus.unknown, // Need real status endpoint
    );
  }
}
