import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized Stale-While-Revalidate (SWR) cache service.
/// Provides instant in-memory lookups backed by persistent disk storage.
class CacheService {
  static final Map<String, dynamic> _memoryCache = {};

  /// Recursively convert any Map to `Map<String, dynamic>`
  static dynamic _deepSanitize(dynamic value) {
    if (value is Map) {
      return value.map<String, dynamic>(
        (key, val) => MapEntry(key.toString(), _deepSanitize(val)),
      );
    } else if (value is List) {
      return value.map((e) => _deepSanitize(e)).toList();
    }
    return value;
  }

  /// Pre-warm in-memory cache with persisted keys during app launch.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('cached_') || key.startsWith('study_plan_')) {
          final raw = prefs.getString(key);
          if (raw != null && raw.isNotEmpty) {
            try {
              final decoded = jsonDecode(raw);
              _memoryCache[key] = _deepSanitize(decoded);
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }

  /// Retrieve cached JSON data (checking memory first, then disk).
  static Future<T?> get<T>(String key) async {
    if (_memoryCache.containsKey(key)) {
      return getSync<T>(key);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = _deepSanitize(jsonDecode(raw));
        _memoryCache[key] = decoded;
        if (decoded is Map) {
          try {
            return Map<String, dynamic>.from(decoded) as T?;
          } catch (_) {}
        }
        try {
          return decoded as T?;
        } catch (_) {
          return null;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Immediate synchronous in-memory read (0ms).
  static T? getSync<T>(String key) {
    if (_memoryCache.containsKey(key)) {
      final val = _memoryCache[key];
      if (val is Map) {
        try {
          return Map<String, dynamic>.from(val) as T?;
        } catch (_) {}
      }
      try {
        return val as T?;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Save data to memory and persist asynchronously to disk.
  static Future<void> set(String key, dynamic value) async {
    final sanitized = _deepSanitize(value);
    _memoryCache[key] = sanitized;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(sanitized));
    } catch (_) {}
  }

  /// Clear specific cache key.
  static Future<void> remove(String key) async {
    _memoryCache.remove(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }

  /// Clear all user-specific cache keys upon logout.
  static Future<void> clearUserCache() async {
    final userKeys = [
      'cached_student_stats_v1',
      'cached_student_profile_v1',
      'cached_student_assignments_v1',
      'cached_student_doubts_v1',
      'cached_teacher_stats_v1',
      'cached_teacher_doubts_v1',
      'cached_teacher_chat_v1',
      'cached_teacher_ai_messages_v1',
      'study_plan_cached_v1',
    ];
    for (final k in userKeys) {
      await remove(k);
    }
  }
}
