import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api_client.dart';
import 'auth_models.dart';

class AuthRepository {
  final storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiClient.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<void> saveToken(String token) async {
    await storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }

  Future<void> saveUser(User user) async {
    await storage.write(key: 'user', value: jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final str = await storage.read(key: 'user');
    if (str != null) {
      return User.fromJson(jsonDecode(str));
    }
    return null;
  }

  Future<void> logout() async {
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'user');
  }
}
