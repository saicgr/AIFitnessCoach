import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Generic data cache service using SharedPreferences with TTL support
///
/// Provides cache-first pattern for API data:
/// 1. Load cached data instantly (if not expired)
/// 2. Fetch fresh data in background
/// 3. Update cache when fresh data arrives
class DataCacheService {
  static DataCacheService? _instance;
  static SharedPreferences? _prefs;

  // Cache keys
  static const String todayWorkoutKey = 'cache_today_workout';
  static const String workoutListKey = 'cache_workout_list';
  static const String gymProfilesKey = 'cache_gym_profiles';
  static const String userProfileKey = 'cache_user_profile';
  static const String xpDataKey = 'cache_xp_data';
  static const String xpStreakKey = 'cache_xp_streak';
  static const String trophySummaryKey = 'cache_trophy_summary';
  static const String bodyMeasurementsKey = 'cache_body_measurements';

  // First-paint tab data — cache-first so each tab paints last-known content
  // instantly on a cold start, then silently revalidates. Mirrors the proven
  // todayWorkout/workoutList pattern.
  static const String timelineKey = 'cache_timeline';
  static const String hydrationKey = 'cache_hydration';
  static const String consistencyKey = 'cache_consistency';
  static const String dailyActivityKey = 'cache_daily_activity';
  static const String coachInsightKey = 'cache_coach_insight';
  static const String nutritionDailyKey = 'cache_nutrition_daily';
  // "Ask Coach" conversation list — paints instantly on open, then silently
  // revalidates. NOT tz-sensitive (sessions aren't a "today" surface).
  static const String chatSessionsKey = 'cache_chat_sessions';
  // Combined Health hub history (35-day daily-activity window). Backs the Home
  // metric deck (steps streak / zone minutes) AND the Combined Health screen.
  // tz-sensitive: the most-recent day is "today", so a calendar rollover must
  // invalidate it even before the TTL fires.
  static const String combinedHealthKey = 'cache_combined_health';

  /// Shared prefix for all below-the-fold stat aggregates (nutrition stats
  /// strip, workout stats section). Any key starting with this picks up
  /// [_statsTtlMs] without needing a per-key override entry — call sites just
  /// build `'${DataCacheService.statsKeyPrefix}nutrition_weekly'` etc.
  static const String statsKeyPrefix = 'cache_stats_';

  // TTL durations in milliseconds
  static const int _userProfileTtlMs = 30 * 60 * 1000; // 30 minutes
  static const int _defaultTtlMs = 60 * 60 * 1000; // 1 hour
  static const int _todayWorkoutTtlMs = 24 * 60 * 60 * 1000; // 24 hours — survives overnight
  static const int _workoutListTtlMs = 24 * 60 * 60 * 1000; // 24 hours — carousel needs week-wide data instantly on cold start
  static const int _xpDataTtlMs = 12 * 60 * 60 * 1000; // 12 hours
  static const int _trophyTtlMs = 12 * 60 * 60 * 1000; // 12 hours
  static const int _gymProfilesTtlMs = 24 * 60 * 60 * 1000; // 24 hours — gyms rarely change; revalidate silently in background
  static const int _firstPaintTtlMs = 24 * 60 * 60 * 1000; // 24 hours — first-paint tab data survives overnight
  static const int _dailyActivityTtlMs = 6 * 60 * 60 * 1000; // 6 hours — step count drifts intraday; refresh sooner
  static const int _statsTtlMs = 12 * 60 * 60 * 1000; // 12 hours — stat aggregates change slowly

  /// Keys whose envelopes must also match the user's local wall-clock date.
  /// Used to defend against timezone rollover (e.g. LAX → JFK flight) where
  /// "today" changes per the user's clock but the TTL hasn't fired yet.
  /// All of these are "today"-scoped surfaces, so a calendar rollover must
  /// invalidate them even before the TTL elapses.
  static const Set<String> _tzSensitiveKeys = {
    todayWorkoutKey,
    timelineKey,
    hydrationKey,
    dailyActivityKey,
    coachInsightKey,
    nutritionDailyKey,
    combinedHealthKey,
  };

  /// Counter for unscoped writes — incremented every time `_scopedKey` falls
  /// back to the legacy global slot (no userId provided). Surfaces regressions
  /// where a new call site forgets to thread the user_id. Read via
  /// [unscopedWriteCount]; consider wiring to Sentry as a tag/breadcrumb.
  // TODO: wire [unscopedWriteCount] into Sentry as a tag or app-start breadcrumb
  static int _unscopedWriteCount = 0;

  /// How many times a fallback-to-global-key write/read has occurred this
  /// process. Non-zero indicates at least one caller is missing user scoping.
  static int get unscopedWriteCount => _unscopedWriteCount;

  /// Per-key TTL overrides
  static const Map<String, int> _ttlOverrides = {
    userProfileKey: _userProfileTtlMs,
    todayWorkoutKey: _todayWorkoutTtlMs,
    workoutListKey: _workoutListTtlMs,
    xpDataKey: _xpDataTtlMs,
    xpStreakKey: _xpDataTtlMs,
    trophySummaryKey: _trophyTtlMs,
    gymProfilesKey: _gymProfilesTtlMs,
    timelineKey: _firstPaintTtlMs,
    hydrationKey: _firstPaintTtlMs,
    consistencyKey: _statsTtlMs,
    dailyActivityKey: _dailyActivityTtlMs,
    coachInsightKey: _statsTtlMs,
    nutritionDailyKey: _firstPaintTtlMs,
    chatSessionsKey: _firstPaintTtlMs, // 24h — survives overnight reopens; always revalidated
    combinedHealthKey: _dailyActivityTtlMs, // 6h — step/zone data drifts intraday
  };

  DataCacheService._();

  static DataCacheService get instance {
    _instance ??= DataCacheService._();
    return _instance!;
  }

  /// Initialize the cache service. Also runs a one-shot migration that deletes
  /// the legacy unscoped global cache keys so cross-account residue from
  /// before user-scoping was introduced is flushed exactly once per install.
  /// Idempotent — re-running is a no-op (keys already gone).
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    const migrationFlag = 'cache_v2_user_scoped_migration_complete';
    if (_prefs!.getBool(migrationFlag) != true) {
      const legacyKeys = [
        todayWorkoutKey,
        workoutListKey,
        gymProfilesKey,
        userProfileKey,
        xpDataKey,
        xpStreakKey,
        trophySummaryKey,
        bodyMeasurementsKey,
      ];
      for (final k in legacyKeys) {
        await _prefs!.remove(k);
      }
      await _prefs!.setBool(migrationFlag, true);
      debugPrint('💾 [Cache] One-shot migration: wiped ${legacyKeys.length} legacy global keys');
    }
    debugPrint('💾 [Cache] DataCacheService initialized');
  }

  /// Build a user-scoped storage key. When [userId] is non-empty, returns
  /// `<key>:<userId>` so two accounts on the same device never share a slot.
  /// When null/empty, falls back to the legacy global key for backward
  /// compatibility with call sites that haven't been migrated yet — those
  /// emit a debug warning so they can be tracked down. NEVER silently lose
  /// data: the unscoped global path still works, just with a louder log.
  String _scopedKey(String key, String? userId) {
    if (userId == null || userId.isEmpty) {
      _unscopedWriteCount++;
      debugPrint('⚠️ [Cache] $key called with no user_id — using legacy global slot (migrate caller) [unscoped_total=$_unscopedWriteCount]');
      return key;
    }
    return '$key:$userId';
  }

  /// Get SharedPreferences instance
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Get TTL for a given key.
  ///
  /// [key] arrives already user-scoped (`<base>:<userId>`), so strip the
  /// suffix before looking up the override — otherwise EVERY per-user entry
  /// misses the override map and silently falls back to the 1h default (this
  /// was a latent bug: today-workout/workout-list never actually got their
  /// 24h "survives overnight" TTL on a real per-user install). Keys under the
  /// shared stats prefix pick up [_statsTtlMs] without an override entry.
  int _getTtl(String key) {
    final base = key.contains(':') ? key.substring(0, key.indexOf(':')) : key;
    final override = _ttlOverrides[base];
    if (override != null) return override;
    if (base.startsWith(statsKeyPrefix)) return _statsTtlMs;
    return _defaultTtlMs;
  }

  /// Today's date in the user's wall-clock timezone, as 'yyyy-MM-dd'.
  /// Stamped onto every envelope so TZ-sensitive keys can detect rollover
  /// independent of the TTL clock.
  String _todayLocalDate() => DateFormat('yyyy-MM-dd').format(DateTime.now().toLocal());

  /// Wrap data in a TTL envelope. `localDate` records the user's wall-clock
  /// date at write time so TZ-sensitive keys (see [_tzSensitiveKeys]) can
  /// invalidate on calendar rollover even before TTL elapses.
  Map<String, dynamic> _wrapWithTtl(dynamic data) => {
        'data': data,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
        'localDate': _todayLocalDate(),
      };

  /// Check if cached data is still valid. Rejects when:
  /// - envelope missing `cachedAt`
  /// - age is negative (clock skew / device clock moved backwards — defends
  ///   against tampering and prevents future-dated entries from being
  ///   considered fresh forever)
  /// - age exceeds the per-key TTL
  /// - key is TZ-sensitive AND envelope's `localDate` no longer matches the
  ///   user's current wall-clock date (timezone rollover, e.g. LAX → JFK).
  ///   Missing `localDate` on legacy envelopes is tolerated — new writes will
  ///   populate it and natural turnover backfills the field.
  bool _isValid(Map<String, dynamic> envelope, String key) {
    final cachedAt = envelope['cachedAt'] as int?;
    if (cachedAt == null) return false;
    final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
    if (age < 0) return false; // clock went backwards — treat as invalid
    if (age >= _getTtl(key)) return false;

    // TZ-sensitive check: strip any `:userId` suffix to compare against the
    // base key name in [_tzSensitiveKeys].
    final baseKey = key.contains(':') ? key.substring(0, key.indexOf(':')) : key;
    if (_tzSensitiveKeys.contains(baseKey)) {
      final localDate = envelope['localDate'] as String?;
      if (localDate != null && localDate != _todayLocalDate()) {
        return false;
      }
    }
    return true;
  }

  /// Cache JSON data with a key. Pass [userId] to user-scope the storage
  /// slot — STRONGLY RECOMMENDED for any per-user data. When null, the legacy
  /// global slot is used (logged as a warning).
  Future<void> cache(String key, Map<String, dynamic> data, {String? userId}) async {
    try {
      final p = await prefs;
      final scopedKey = _scopedKey(key, userId);
      final envelope = _wrapWithTtl(data);
      final jsonString = jsonEncode(envelope);
      await p.setString(scopedKey, jsonString);
      debugPrint('💾 [Cache] Saved: $scopedKey (${jsonString.length} chars)');
    } catch (e) {
      debugPrint('❌ [Cache] Error saving $key: $e');
    }
  }

  /// Cache a list of JSON objects. Same userId rules as [cache].
  Future<void> cacheList(String key, List<Map<String, dynamic>> data, {String? userId}) async {
    try {
      final p = await prefs;
      final scopedKey = _scopedKey(key, userId);
      final envelope = _wrapWithTtl(data);
      final jsonString = jsonEncode(envelope);
      await p.setString(scopedKey, jsonString);
      debugPrint('💾 [Cache] Saved list: $scopedKey (${data.length} items)');
    } catch (e) {
      debugPrint('❌ [Cache] Error saving list $key: $e');
    }
  }

  /// Get cached JSON data (returns null if expired or missing). Same userId
  /// rules as [cache].
  ///
  /// When [returnExpiredOnMiss] is true an *expired* entry is returned anyway
  /// (and kept on disk) instead of yielding null — so a caller can paint
  /// stale-but-useful data instantly while it refreshes, rather than render
  /// an empty screen / spinner.
  Future<Map<String, dynamic>?> getCached(String key,
      {String? userId, bool returnExpiredOnMiss = false}) async {
    try {
      final p = await prefs;
      key = _scopedKey(key, userId);
      final jsonString = p.getString(key);
      if (jsonString == null) {
        debugPrint('📭 [Cache] Miss: $key');
        return null;
      }
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        // Check if this is a TTL envelope (has 'data' and 'cachedAt')
        if (decoded.containsKey('cachedAt') && decoded.containsKey('data')) {
          if (!_isValid(decoded, key)) {
            if (returnExpiredOnMiss) {
              debugPrint('⏰ [Cache] Expired — returned stale (caller opted in): $key');
              return decoded['data'] as Map<String, dynamic>;
            }
            debugPrint('⏰ [Cache] Expired: $key');
            await p.remove(key);
            return null;
          }
          debugPrint('✅ [Cache] Hit: $key');
          return decoded['data'] as Map<String, dynamic>;
        }
        // Legacy entry without TTL envelope — treat as valid but wrap on next write
        debugPrint('✅ [Cache] Hit (legacy): $key');
        return decoded;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Cache] Error reading $key: $e');
      return null;
    }
  }

  /// Get cached list of JSON objects (returns null if expired or missing).
  /// Same userId rules as [cache]. See [getCached] for [returnExpiredOnMiss].
  Future<List<Map<String, dynamic>>?> getCachedList(String key,
      {String? userId, bool returnExpiredOnMiss = false}) async {
    try {
      final p = await prefs;
      key = _scopedKey(key, userId);
      final jsonString = p.getString(key);
      if (jsonString == null) {
        debugPrint('📭 [Cache] Miss: $key');
        return null;
      }
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic> &&
          decoded.containsKey('cachedAt') &&
          decoded.containsKey('data')) {
        // TTL envelope
        if (!_isValid(decoded, key)) {
          if (returnExpiredOnMiss) {
            debugPrint('⏰ [Cache] Expired — returned stale (caller opted in): $key');
            return (decoded['data'] as List).cast<Map<String, dynamic>>();
          }
          debugPrint('⏰ [Cache] Expired: $key');
          await p.remove(key);
          return null;
        }
        debugPrint('✅ [Cache] Hit: $key');
        final list = decoded['data'] as List;
        return list.cast<Map<String, dynamic>>();
      }
      // Legacy entry without TTL envelope
      if (decoded is List) {
        debugPrint('✅ [Cache] Hit (legacy): $key');
        return decoded.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Cache] Error reading list $key: $e');
      return null;
    }
  }

  /// Invalidate (remove) cached data for a key. Same userId rules as [cache].
  Future<void> invalidate(String key, {String? userId}) async {
    try {
      final p = await prefs;
      final scopedKey = _scopedKey(key, userId);
      await p.remove(scopedKey);
      debugPrint('🗑️ [Cache] Invalidated: $scopedKey');
    } catch (e) {
      debugPrint('❌ [Cache] Error invalidating $key: $e');
    }
  }

  /// Clear all cached data (on logout). Wipes BOTH the legacy global keys and
  /// every user-scoped slot (`<key>:<anything>`) on this device, regardless of
  /// which user owned them. Safe because logout means nobody owns the data
  /// anymore. Caller doesn't need to know any user_ids.
  Future<void> clearAll() async {
    try {
      final p = await prefs;
      const baseKeys = [
        todayWorkoutKey,
        workoutListKey,
        gymProfilesKey,
        userProfileKey,
        xpDataKey,
        xpStreakKey,
        trophySummaryKey,
        bodyMeasurementsKey,
        timelineKey,
        hydrationKey,
        consistencyKey,
        dailyActivityKey,
        coachInsightKey,
        nutritionDailyKey,
        combinedHealthKey,
      ];
      // Remove the legacy unscoped form, plus every `<base>:<userId>` slot,
      // plus every stat-aggregate slot (shared `cache_stats_` prefix).
      final allKeys = p.getKeys();
      var removed = 0;
      for (final k in allKeys) {
        if (k == statsKeyPrefix.substring(0, statsKeyPrefix.length - 1) ||
            k.startsWith(statsKeyPrefix)) {
          await p.remove(k);
          removed++;
          continue;
        }
        for (final base in baseKeys) {
          if (k == base || k.startsWith('$base:')) {
            await p.remove(k);
            removed++;
            break;
          }
        }
      }
      debugPrint('🧹 [Cache] Cleared $removed cached entries (all users on this device)');
    } catch (e) {
      debugPrint('❌ [Cache] Error clearing cache: $e');
    }
  }

  /// Check if a key has cached data (does not check TTL). Same userId rules
  /// as [cache].
  Future<bool> hasCached(String key, {String? userId}) async {
    final p = await prefs;
    return p.containsKey(_scopedKey(key, userId));
  }
}
