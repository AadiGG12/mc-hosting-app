import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../data/auth_models.dart';

abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final User user;
  final String token;
  AuthAuthenticated(this.user, this.token);
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(AuthInitial()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    state = AuthLoading();
    final token = await _repo.getToken();
    final user = await _repo.getUser();
    if (token != null && user != null) {
      state = AuthAuthenticated(user, token);
    } else {
      state = AuthUnauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthLoading();
    try {
      final res = await _repo.login(email, password);
      final token = res['access_token'];
      final user = User.fromJson(res['user']);
      await _repo.saveToken(token);
      await _repo.saveUser(user);
      state = AuthAuthenticated(user, token);
    } catch (e) {
      state = AuthError(e.toString());
      state = AuthUnauthenticated();
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = AuthUnauthenticated();
  }
}

final authRepositoryProvider = Provider((ref) => AuthRepository());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

final currentUserProvider = Provider<User?>((ref) {
  final state = ref.watch(authProvider);
  if (state is AuthAuthenticated) return state.user;
  return null;
});

final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isAdmin ?? false;
});
