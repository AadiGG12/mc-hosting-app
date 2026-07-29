import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

class ApiClient {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static final Dio dio = Dio(BaseOptions(
    baseUrl: Constants.backendUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ))..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final customUrl = await _storage.read(key: 'custom_api_url');
        if (customUrl != null && customUrl.isNotEmpty) {
          options.baseUrl = customUrl;
        }
        
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        return handler.next(e);
      },
    ),
  );

  static Future<void> setBaseUrl(String url) async {
    final cleanUrl = url.trim().replaceAll(RegExp(r'/$'), '');
    await _storage.write(key: 'custom_api_url', value: cleanUrl);
    dio.options.baseUrl = cleanUrl;
  }

  static Future<String> getBaseUrl() async {
    final saved = await _storage.read(key: 'custom_api_url');
    return saved ?? Constants.backendUrl;
  }
}
