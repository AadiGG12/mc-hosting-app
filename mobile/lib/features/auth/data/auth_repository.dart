import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api_client.dart';
import 'auth_models.dart';

class AuthRepository {
  final storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Login via Backend API — this keeps the Pterodactyl Application API key
      // server-side and never exposes it to the mobile app.
      final response = await ApiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      // Save credentials for Pterodactyl Client API calls (WebSocket, etc.)
      await storage.write(key: 'user_email', value: email);
      await storage.write(key: 'user_password', value: password);
      return response.data;
    } on DioException catch (e) {
      // Provide user-friendly error messages
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Cannot connect to the server. Please check your internet connection.');
      }
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid email or password. Please check your Pterodactyl credentials.');
      }
      rethrow;
    }
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
    await storage.delete(key: 'user_email');
    await storage.delete(key: 'user_password');
  }
}
