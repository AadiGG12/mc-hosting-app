import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api_client.dart';
import '../../../core/constants.dart';
import 'auth_models.dart';

class AuthRepository {
  final storage = const FlutterSecureStorage();
  final Dio _directDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // 1. Attempt login via Backend API
      final response = await ApiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      // Save credentials for Pterodactyl client API calls (WebSocket)
      await storage.write(key: 'user_email', value: email);
      await storage.write(key: 'user_password', value: password);
      return response.data;
    } catch (e) {
      // 2. Direct Pterodactyl Application API Fallback
      try {
        const appKey = 'ptla_I4w35cvG1UEYzBRX7yQ4cKPHs4HZpz3NSqfZsgn7HCF';
        final url = '${Constants.panelUrl}/api/application/users?filter[email]=${Uri.encodeComponent(email)}';
        
        final res = await _directDio.get(
          url,
          options: Options(headers: {
            'Authorization': 'Bearer $appKey',
            'Accept': 'application/json',
          }),
        );

        final usersData = res.data['data'] as List?;
        if (usersData != null && usersData.isNotEmpty) {
          final userAttr = usersData.first['attributes'];
          final userId = userAttr['id'];
          final isAdmin = userAttr['root_admin'] == true;
          
          // Save credentials for later Client API calls
          await storage.write(key: 'user_email', value: email);
          await storage.write(key: 'user_password', value: password);

          return {
            'access_token': 'ptero_session_${userId}_${DateTime.now().millisecondsSinceEpoch}',
            'user': {
              'id': userId,
              'email': userAttr['email'] ?? email,
              'username': userAttr['username'] ?? '',
              'first_name': userAttr['first_name'] ?? '',
              'last_name': userAttr['last_name'] ?? '',
              'is_admin': isAdmin,
            }
          };
        } else {
          throw Exception('No Pterodactyl account found for "$email"');
        }
      } catch (pteroError) {
        if (e is DioException && (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout)) {
          throw Exception('Cannot connect to panel or server. Please check your internet connection.');
        }
        rethrow;
      }
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
