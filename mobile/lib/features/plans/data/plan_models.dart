class Plan {
  final String id;
  final String name;
  final String slug;
  final String description;
  final double priceMonthly;
  final String currency;
  final int ramMb;
  final int cpuPercent;
  final int storageGb;
  final int maxPlayers;
  final int databaseLimit;
  final int backupLimit;
  final List<String> features;
  final bool isFeatured;
  final int sortOrder;

  Plan({
    required this.id, required this.name, required this.slug, required this.description,
    required this.priceMonthly, required this.currency, required this.ramMb, required this.cpuPercent,
    required this.storageGb, required this.maxPlayers, required this.databaseLimit,
    required this.backupLimit, required this.features, required this.isFeatured, required this.sortOrder,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      priceMonthly: (json['price_monthly'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'INR',
      ramMb: json['ram_mb'] ?? 0,
      cpuPercent: json['cpu_percent'] ?? 0,
      storageGb: json['storage_gb'] ?? 0,
      maxPlayers: json['max_players'] ?? 0,
      databaseLimit: json['database_limit'] ?? 0,
      backupLimit: json['backup_limit'] ?? 0,
      features: List<String>.from(json['features'] ?? []),
      isFeatured: json['is_featured'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
    );
  }
}
