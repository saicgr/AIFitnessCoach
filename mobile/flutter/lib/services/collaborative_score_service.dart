import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';

/// Service that loads population-level exercise popularity scores
/// for collaborative filtering in exercise selection.
///
/// Scores are aggregated from anonymized performance logs:
/// Score = popularity * 0.4 + low_rpe * 0.3 + pr_rate * 0.3
///
/// Data sources (in priority order):
/// 1. In-memory cache (fastest)
/// 2. API refresh (every 4 hours when online)
/// 3. SharedPreferences persisted cache (survives app restart)
/// 4. Bundled JSON asset (fallback when offline + no cached API data)
class CollaborativeScoreService {
  static Map<String, Map<String, Map<String, double>>>? _cache;
  static DateTime? _lastApiRefresh;
  static const _refreshInterval = Duration(hours: 4);
  static const _persistKey = 'collaborative_scores_cache';
  static const _persistTimestampKey = 'collaborative_scores_timestamp';
  static bool _bundledLoaded = false;

  /// Lightweight Dio instance for population-level popularity endpoint.
  /// This avoids requiring FlutterSecureStorage / Riverpod context since
  /// the endpoint returns anonymized aggregate data.
  static Dio? _dio;
  static Dio get _httpClient {
    _dio ??= Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    return _dio!;
  }

  /// Load scores, preferring fresh API data when available.
  /// Falls back to bundled JSON if offline or API fails.
  static Future<Map<String, double>> getScores(
    String muscle,
    String goal,
  ) async {
    await _ensureLoaded();

    // Trigger background refresh if stale
    if (_shouldRefresh()) {
      // Fire-and-forget: don't block on API call
      refreshFromApi(muscle, goal);
    }

    final muscleLower = muscle.toLowerCase();
    final goalLower = goal.toLowerCase();

    final muscleData = _cache?[muscleLower];
    if (muscleData == null) return {};

    return muscleData[goalLower] ?? muscleData['hypertrophy'] ?? {};
  }

  /// Get the collaborative score for a specific exercise.
  static Future<double> getScore(
    String exerciseName,
    String muscle,
    String goal,
  ) async {
    final scores = await getScores(muscle, goal);
    return scores[exerciseName.toLowerCase()] ?? 0.0;
  }

  /// Get all available muscle groups in the dataset.
  static Future<Set<String>> getAvailableMuscles() async {
    await _ensureLoaded();
    return _cache?.keys.toSet() ?? {};
  }

  /// Try to refresh scores from backend API. Non-blocking.
  static Future<void> refreshFromApi(String muscle, String goal) async {
    try {
      final muscleLower = muscle.toLowerCase();
      final goalLower = goal.toLowerCase();

      final response = await _httpClient.get(
        '/exercise-popularity/$muscleLower',
        queryParameters: {'goal': goalLower},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final exercises = data['exercises'] as Map<String, dynamic>?;

        if (exercises != null && exercises.isNotEmpty) {
          // Merge into cache
          _cache ??= {};
          _cache![muscleLower] ??= {};
          _cache![muscleLower]![goalLower] = exercises.map(
            (k, v) => MapEntry(k.toLowerCase(), (v as num).toDouble()),
          );

          _lastApiRefresh = DateTime.now();

          // Persist to SharedPreferences
          await _persistCache();

          debugPrint('[CollabScores] Refreshed $muscleLower/$goalLower '
              'from API (${exercises.length} exercises)');
        }
      }
    } catch (e) {
      debugPrint('[CollabScores] API refresh failed (using cached): $e');
      // Non-fatal: continue with existing cache
    }
  }

  /// Force refresh all cached muscle/goal combinations from API.
  static Future<void> forceRefresh() async {
    if (_cache == null) return;

    for (final muscleEntry in _cache!.entries) {
      for (final goalEntry in muscleEntry.value.entries) {
        await refreshFromApi(muscleEntry.key, goalEntry.key);
      }
    }
  }

  /// Ensure some data is loaded (persisted cache or bundled asset).
  static Future<void> _ensureLoaded() async {
    if (_cache != null) return;

    // Try loading persisted API cache first
    final loaded = await _loadPersistedCache();
    if (loaded) return;

    // Fall back to bundled JSON asset
    await _loadBundled();
  }

  /// Load from SharedPreferences (persisted API responses).
  static Future<bool> _loadPersistedCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_persistKey);
      final timestampMs = prefs.getInt(_persistTimestampKey);

      if (raw == null) return false;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      _cache = _parseCache(data);

      if (timestampMs != null) {
        _lastApiRefresh = DateTime.fromMillisecondsSinceEpoch(timestampMs);
      }

      debugPrint('[CollabScores] Loaded persisted cache '
          '(${_cache!.length} muscles)');
      return true;
    } catch (e) {
      debugPrint('[CollabScores] Failed to load persisted cache: $e');
      return false;
    }
  }

  /// Load from bundled JSON asset.
  static Future<void> _loadBundled() async {
    if (_bundledLoaded && _cache != null) return;

    try {
      final jsonStr = await rootBundle.loadString(
        'assets/data/exercise_popularity.json',
      );
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      _cache = _parseCache(data);
      _bundledLoaded = true;

      debugPrint('[CollabScores] Loaded bundled asset '
          '(${_cache!.length} muscles)');
    } catch (e) {
      debugPrint('[CollabScores] Failed to load bundled asset: $e');
      _cache = {};
    }
  }

  /// Parse raw JSON into typed cache structure.
  static Map<String, Map<String, Map<String, double>>> _parseCache(
    Map<String, dynamic> data,
  ) {
    final result = <String, Map<String, Map<String, double>>>{};
    for (final muscleEntry in data.entries) {
      if (muscleEntry.key.startsWith('_')) continue;
      final goalMap = muscleEntry.value as Map<String, dynamic>;
      final goals = <String, Map<String, double>>{};
      for (final goalEntry in goalMap.entries) {
        final exercises = goalEntry.value as Map<String, dynamic>;
        goals[goalEntry.key] = exercises.map(
          (k, v) => MapEntry(k.toLowerCase(), (v as num).toDouble()),
        );
      }
      result[muscleEntry.key] = goals;
    }
    return result;
  }

  /// Persist current cache to SharedPreferences.
  static Future<void> _persistCache() async {
    if (_cache == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_persistKey, jsonEncode(_cache));
      if (_lastApiRefresh != null) {
        await prefs.setInt(
          _persistTimestampKey,
          _lastApiRefresh!.millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      debugPrint('[CollabScores] Failed to persist cache: $e');
    }
  }

  /// Whether we should trigger a background API refresh.
  static bool _shouldRefresh() {
    if (_lastApiRefresh == null) return true;
    return DateTime.now().difference(_lastApiRefresh!) > _refreshInterval;
  }
}
