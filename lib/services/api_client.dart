import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

// Use Dart's environment variable injection to mimic process.env.EXPO_PUBLIC_API_URL
final baseUrlProvider = Provider((ref) => 
  const String.fromEnvironment('EXPO_PUBLIC_API_URL', defaultValue: "https://intense-learners.vercel.app")
);

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onResponse: (response, handler) {
      return handler.next(response);
    },
    onError: (DioException e, handler) async {
      if (e.response?.statusCode == 401) {
        // Trigger unauthorized event to clear auth and refresh router
        ref.read(authProvider.notifier).logout();
      }
      return handler.next(e);
    },
  ));

  return dio;
});
