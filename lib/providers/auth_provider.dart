import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import '../services/cache_service.dart';
import 'ui_provider.dart';
import 'dart:convert';

class AuthState {
  final Map<String, dynamic>? user;
  final bool isLoading;
  final bool isHydrated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.isHydrated = false,
  });

  AuthState copyWith({
    Map<String, dynamic>? user,
    bool? isLoading,
    bool? isHydrated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isHydrated: isHydrated ?? this.isHydrated,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(() => hydrate());
    return AuthState();
  }

  Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userString = prefs.getString('user');
    
    // Simulate RN's small retry on Fast Refresh delay
    if (token != null && userString == null) {
      await Future.delayed(const Duration(milliseconds: 150));
      // Force SharedPreferences to re-read from disk to mirror RN's AsyncStorage bridge
      await prefs.reload(); 
    }

    final finalUserString = prefs.getString('user');

    if (token != null && finalUserString != null) {
      state = state.copyWith(
        user: jsonDecode(finalUserString),
        isHydrated: true,
      );
    } else {
      state = state.copyWith(isHydrated: true);
    }
  }

  Future<void> login(String email, String password, String role) async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/api/auth/mobile-login', data: {
        'email': email,
        'password': password,
        'role': role,
      });

      final data = response.data;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('user', jsonEncode(data['user']));

      state = state.copyWith(user: data['user'], isLoading: false);
      
      if (data['user']['role'] == 'TEACHER') {
        ref.read(uiProvider.notifier).setViewMode('teacher');
      }
    } on DioException {
      state = state.copyWith(isLoading: false);
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password, String role) async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = ref.read(dioProvider);
      
      // Register
      await dio.post('/api/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });

      // Login immediately after
      final response = await dio.post('/api/auth/mobile-login', data: {
        'email': email,
        'password': password,
        'role': role,
      });

      final data = response.data;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('user', jsonEncode(data['user']));

      state = state.copyWith(user: data['user'], isLoading: false);
    } on DioException {
      state = state.copyWith(isLoading: false);
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    await CacheService.clearUserCache();
    state = AuthState(isHydrated: true);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
