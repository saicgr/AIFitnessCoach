import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

/// Persistent cache for exercise image URLs.
/// URLs are permanent (public S3/CDN) so cache entries never expire.
class ImageUrlCache {
  static const String _cacheKey = 'exercise_image_urls';

  // Perf fix 2.4: cap in-memory cache to prevent unbounded growth
  static const int _maxCacheEntries = 500;

  // In-memory cache for fast access during session
  static Map<String, String>? _memoryCache;

  /// Initialize cache from SharedPreferences on app start.
  /// URLs are permanent (no expiration) so cached entries are valid indefinitely.
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        _memoryCache = Map<String, String>.from(json.decode(cached));
        return;
      } catch (_) {
        // Invalid cache, will be cleared
      }
    }
    _memoryCache = {};
  }

  /// Get a cached URL for an exercise name
  static String? get(String exerciseName) {
    if (_memoryCache == null) return null;
    final key = exerciseName.toLowerCase();
    return _memoryCache![key];
  }

  /// Store a URL in cache
  static Future<void> set(String exerciseName, String url) async {
    _memoryCache ??= {};
    final key = exerciseName.toLowerCase();
    _memoryCache![key] = url;

    // Perf fix 2.4: FIFO eviction when cache exceeds max size
    _evictIfNeeded();

    // Persist to SharedPreferences (debounced - only save every 10 entries)
    if (_memoryCache!.length % 10 == 0) {
      await _persistCache();
    }
  }

  /// Store multiple URLs at once (more efficient)
  static Future<void> setAll(Map<String, String> urls) async {
    _memoryCache ??= {};
    for (final entry in urls.entries) {
      final key = entry.key.toLowerCase();
      _memoryCache![key] = entry.value;
    }
    // Perf fix 2.4: FIFO eviction when cache exceeds max size
    _evictIfNeeded();
    await _persistCache();
  }

  /// Evict oldest entries when cache exceeds max size (FIFO)
  static void _evictIfNeeded() {
    if (_memoryCache == null || _memoryCache!.length <= _maxCacheEntries) return;
    final keysToRemove =
        _memoryCache!.keys.take(_memoryCache!.length - _maxCacheEntries + 50).toList();
    for (final key in keysToRemove) {
      _memoryCache!.remove(key);
    }
  }

  /// Persist cache to SharedPreferences
  static Future<void> _persistCache() async {
    if (_memoryCache == null || _memoryCache!.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, json.encode(_memoryCache));
  }

  /// Batch pre-fetch image URLs for multiple exercises in a single API call.
  /// Calls POST /exercise-images/batch and caches all results.
  static Future<void> batchPreFetch(
    List<String> names,
    ApiClient apiClient,
  ) async {
    if (names.isEmpty) return;

    // Filter out names already in cache
    final uncachedNames =
        names.where((name) => get(name) == null).toList();
    if (uncachedNames.isEmpty) return;

    try {
      final response = await apiClient.post(
        '/exercise-images/batch',
        data: {'names': uncachedNames.take(100).toList()},
      );

      if (response.statusCode == 200 && response.data != null) {
        final rawUrls = response.data['urls'] as Map?;
        if (rawUrls != null && rawUrls.isNotEmpty) {
          final urls = rawUrls.map<String, String>(
            (key, value) => MapEntry(key.toString(), value.toString()),
          );
          await setAll(urls);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Batch image pre-fetch failed: $e');
    }
  }

  /// Clear all cached URLs (call when presigned URLs might have expired)
  static Future<void> clear() async {
    _memoryCache = {};

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }

  /// Check if cache has any entries
  static bool get isEmpty => _memoryCache?.isEmpty ?? true;

  /// Get cache size
  static int get size => _memoryCache?.length ?? 0;
}
