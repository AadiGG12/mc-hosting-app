import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/server_repository.dart';
import '../data/server_models.dart';

final serverRepoProvider = Provider((ref) => ServerRepository());

final serversProvider = FutureProvider<List<Server>>((ref) {
  return ref.read(serverRepoProvider).getServers();
});

final serverProvider = FutureProvider.family<Server, String>((ref, id) {
  return ref.read(serverRepoProvider).getServer(id);
});
