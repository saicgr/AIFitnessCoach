import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Generic data cache service using SharedPreferences
///
/// Provides cache-first pattern for API data:
/// 1. Load cached data instantly
/// 2. Fetch fresh data in background
/// 3. Update cache when fresh data arrives
class DataCacheService {
  static DataCacheService? _instance;
  static SharedPreferences? _prefs;

  // Cache keys
  static const String todayWorkoutKey = 'cache_today_workout';
  static const String gymProfilesKey = 'cache_gym_profiles';
  static const String userProfileKey = 'cache_user_profile';
  static const String xpDataKey = 'cache_xp_data';
  static const String xpStreakKey = 'cache_xp_streak';
  static const String trophySummaryKey = 'cache_trophy_summary';
  static const String bodyMeasurementsKey = 'cache_body_measurements';

  DataCacheService._();

  static DataCacheService get instance {
    _instance ??= DataCacheService._();
    return _instance!;
  }

  /// Initialize the cache service
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    debugPrint('💾 [Cache] DataCacheService initialized');
  }

  /// Get SharedPreferences instance
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Cache JSON data with a key
  Future<void> cache(String key, Map<String, dynamic> data) async {
    try {
      final p = await prefs;
      final jsonString = jsonEncode(data);
      await p.setString(key, jsonString);
      debugPrint('💾 [Cache] Saved: $key (${jsonString.length} chars)');
    } catch (e) {
      debugPrint('❌ [Cache] Error saving $key: $e');
    }
  }

  /// Cache a list of JSON objects
  Future<void> cacheList(String key, List<Map<String, dynamic>> data) async {
    try {
      final p = await prefs;
      final jsonString = jsonEncode(data);
      await p.setString(key, jsonString);
      debugPrint('💾 [Cache] Saved list: $key (${data.length} items)');
    } catch (e) {
      debugPrint('❌ [Cache] Error saving list $key: $e');
    }
  }

  /// Get cached JSON data
  Future<Map<String, dynamic>?> getCached(String key) async {
    try {
      final p = await prefs;
      final jsonString = p.getString(key);
      if (jsonString == null) {
        debugPrint('📭 [Cache] Miss: $key');
        return null;
      }
      debugPrint('✅ [Cache] Hit: $key');
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ [Cache] Error reading $key: $e');
      return null;
    }
  }

  /// Get cached list of JSON objects
  Future<List<Map<String, dynamic>>?> getCachedList(String key) async {
    try {
      final p = await prefs;
      final jsonString = p.getString(key);
      if (jsonString == null) {
        debugPrint('📭 [Cache] Miss: $key');
        return null;
      }
      debugPrint('✅ [Cache] Hit: $key');
      final list = jsonDecode(jsonString) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ [Cache] Error reading list $key: $e');
      return null;
    }
  }

  /// Invalidate (remove) cached data for a key
  Future<void> invalidate(String key) async {
    try {
      final p = await prefs;
      await p.remove(key);
      debugPrint('🗑️ [Cache] Invalidated: $key');
    } catch (e) {
      debugPrint('❌ [Cache] Error invalidating $key: $e');
    }
  }

  /// Clear all cached data (on logout)
  Future<void> clearAll() async {
    try {
      final p = await prefs;
      await p.remove(todayWorkoutKey);
      await p.remove(gymProfilesKey);
      await p.remove(userProfileKey);
      await p.remove(xpDataKey);
      await p.remove(xpStreakKey);
      await p.remove(trophySummaryKey);
      await p.remove(bodyMeasurementsKey);
      debugPrint('🧹 [Cache] Cleared all cached data');
    } catch (e) {
      debugPrint('❌ [Cache] Error clearing cache: $e');
    }
  }

  /// Check if a key has cached data
  Future<bool> hasCached(String key) async {
    final p = await prefs;
    return p.containsKey(key);
  }
}
