import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/today_workout.dart';
import '../providers/today_workout_provider.dart';
import '../repositories/nutrition_repository.dart';
import '../repositories/hydration_repository.dart';
import '../../utils/tz.dart';
import 'api_client.dart';

/// Pre-fetches all home screen data via the /home/bootstrap endpoint
/// during the splash → home transition so the home screen renders instantly.
///
/// Call [prefetch] as a fire-and-forget from the router redirect.
/// It populates in-memory caches so providers start with data, not loading.
class BootstrapPrefetchService {
  static bool _hasPrefetched = false;
  static Future<void>? _activePrefetch;

  /// SharedPreferences key prefix for the persisted /home/bootstrap blob.
  /// The full key is scoped to BOTH the user_id and the LOCAL calendar date
  /// (see [_blobKey]) so a stale blob from yesterday — or from another signed
  /// -in account — can never seed today's Home tiles.
  static const String _blobKeyPrefix = 'home_bootstrap';

  /// Parsed nutrition/hydration sub-maps stashed by [hydrateFromDiskBlob].
  ///
  /// `hydrateFromDiskBlob` runs pre-first-frame from `PrewarmerBoot.hydrateAll`
  /// where there is no Riverpod `Ref`, so the nutrition/hydration notifiers
  /// (which need a notifier instance) cannot be seeded there. We seed the
  /// workout cache immediately (its API is static) and stash the rest; the
  /// next [prefetch] call — which DOES have a `Ref` and still runs before
  /// Home's first frame (router redirect) — drains the stash via
  /// [_drainDiskStash] ahead of the network round-trip.
  static Map<String, dynamic>? _stashedNutrition;
  static Map<String, dynamic>? _stashedHydration;
  static bool _diskStashConsumed = false;

  /// Build the user+local-date scoped SharedPreferences key for the blob.
  /// Uses [Tz.localDate] (device IANA tz) — never UTC — so crossing midnight
  /// or travelling to a new timezone yields a fresh, correct key (A12b).
  static String _blobKey(String userId) =>
      '$_blobKeyPrefix:$userId:${Tz.localDate()}';

  /// Locate the persisted blob for today from an already-open
  /// [SharedPreferences] instance. `PrewarmerBoot.hydrateAll` runs pre-auth
  /// and has no `user_id`, so we match on the `home_bootstrap:<uid>:<date>`
  /// key whose date suffix equals today's LOCAL date. Returns null when no
  /// blob for today exists (cold install, or yesterday's blob only).
  static String? readDiskBlob(SharedPreferences prefs) {
    final todaySuffix = ':${Tz.localDate()}';
    for (final k in prefs.getKeys()) {
      if (k.startsWith('$_blobKeyPrefix:') && k.endsWith(todaySuffix)) {
        return prefs.getString(k);
      }
    }
    return null;
  }

  /// Fire-and-forget prefetch. Safe to call multiple times (deduped).
  static void prefetch(Ref ref) {
    // Even when a network prefetch already ran/failed, still drain any disk
    // stash so Home shows yesterday-free cached data instantly.
    _drainDiskStash(ref);
    if (_hasPrefetched || _activePrefetch != null) return;
    _activePrefetch = _doPrefetch(ref).whenComplete(() {
      _activePrefetch = null;
    });
  }

  /// Wait for prefetch to complete (with timeout).
  /// Returns true if data was loaded, false if timed out or failed.
  static Future<bool> waitForPrefetch({Duration timeout = const Duration(seconds: 2)}) async {
    if (_hasPrefetched) return true;
    if (_activePrefetch == null) return false;
    try {
      await _activePrefetch!.timeout(timeout, onTimeout: () {});
      return _hasPrefetched;
    } catch (_) {
      return false;
    }
  }

  /// Reset on logout so next login prefetches fresh data.
  static void reset() {
    _hasPrefetched = false;
    _activePrefetch = null;
    _stashedNutrition = null;
    _stashedHydration = null;
    _diskStashConsumed = false;
  }

  /// Pre-hydrate the in-memory home caches from a persisted /home/bootstrap
  /// blob (called by `PrewarmerBoot.hydrateAll` before the first frame).
  ///
  /// [raw] is the raw JSON string read from SharedPreferences (or null if no
  /// blob persisted). The blob is a versioned envelope:
  ///   `{"v": 1, "local_date": "YYYY-MM-DD", "data": {<bootstrap payload>}}`
  ///
  /// Behaviour:
  ///  • Workout is seeded immediately — its cache API (`preSeedCache`) is
  ///    static, so no `Ref` is needed. A workout may legitimately be "today"
  ///    or "next" (future-dated), so we accept it within a 24h window — i.e.
  ///    we seed it regardless of the blob date as long as the blob is recent.
  ///  • Nutrition/hydration are date-sensitive (today's macros/water). They
  ///    are only stashed for [_drainDiskStash] when `local_date == today`.
  ///  • A schema-version mismatch or malformed JSON is dropped silently —
  ///    never crash boot over a cache blob.
  static void hydrateFromDiskBlob(String? raw) {
    if (raw == null || raw.isEmpty) return;
    try {
      final envelope = jsonDecode(raw);
      if (envelope is! Map<String, dynamic>) return;
      // Versioned envelope — drop on schema mismatch instead of crashing.
      if (envelope['v'] != 1) {
        debugPrint('⏸️ [Bootstrap] Disk blob schema mismatch (v=${envelope['v']}) — dropping');
        return;
      }
      final data = envelope['data'];
      if (data is! Map<String, dynamic>) return;
      final blobDate = envelope['local_date'] as String?;
      final isToday = blobDate == Tz.localDate();

      // (A12d) Partial bootstrap tolerance — each domain is seeded only when
      // present; missing domains fall through to their own loaders.

      // Workout: static cache, safe to seed pre-frame. The blob's workout may
      // be today's or a future "next workout"; a stale-by-one-day blob is
      // still acceptable for the workout tile (24h window) so we seed it even
      // when isToday is false, as long as the blob exists at all.
      if (data.containsKey('today_workout')) {
        _preSeedWorkout(data['today_workout']);
      }

      // Nutrition + hydration are strictly today-scoped. Only stash them when
      // the blob is for today's local date — yesterday's macros rendered as
      // today's would be a correctness bug.
      if (isToday) {
        final n = data['nutrition_summary'];
        if (n is Map<String, dynamic>) _stashedNutrition = n;
        final h = data['hydration'];
        if (h is Map<String, dynamic>) _stashedHydration = h;
      } else if (blobDate != null) {
        debugPrint('⏸️ [Bootstrap] Disk blob is stale ($blobDate ≠ ${Tz.localDate()}) — nutrition/hydration skipped');
      }
      debugPrint('⚡ [Bootstrap] Pre-hydrated from disk blob (isToday=$isToday)');
    } catch (e) {
      debugPrint('⚠️ [Bootstrap] hydrateFromDiskBlob failed: $e');
    }
  }

  /// Seed the nutrition/hydration notifiers from the stash captured by
  /// [hydrateFromDiskBlob]. Called from [prefetch] (which has a `Ref`).
  /// Idempotent — drains at most once per process.
  static void _drainDiskStash(Ref ref) {
    if (_diskStashConsumed) return;
    _diskStashConsumed = true;
    if (_stashedNutrition != null) {
      _preSeedNutrition(ref, _stashedNutrition);
    }
    if (_stashedHydration != null) {
      _preSeedHydration(ref, _stashedHydration);
    }
    _stashedNutrition = null;
    _stashedHydration = null;
  }

  /// Write the raw /home/bootstrap payload to SharedPreferences under a
  /// user+local-date scoped key, in a versioned envelope. Best-effort:
  /// a disk write failure is logged, never thrown (it only costs a slower
  /// next cold start).
  static Future<void> _persistBlob(String userId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _blobKey(userId);
      final envelope = jsonEncode({
        'v': 1,
        'local_date': Tz.localDate(),
        'cached_at': DateTime.now().toIso8601String(),
        'data': data,
      });
      await prefs.setString(key, envelope);
      // Sweep any prior-day blobs for this user so SharedPreferences doesn't
      // accumulate one stale envelope per day forever.
      final prefix = '$_blobKeyPrefix:$userId:';
      for (final k in prefs.getKeys()) {
        if (k.startsWith(prefix) && k != key) {
          await prefs.remove(k);
        }
      }
      debugPrint('💾 [Bootstrap] Persisted blob to $key');
    } catch (e) {
      debugPrint('⚠️ [Bootstrap] _persistBlob failed: $e');
    }
  }

  static Future<void> _doPrefetch(Ref ref) async {
    try {
      // Auth gate: ensure Supabase session is resolved before prefetching.
      // Without this, prefetch can fire before auth restore completes and
      // poison user-scoped caches with null user_id → leaks to next sign-in.
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentSession == null) {
        try {
          await supabase.auth.onAuthStateChange
              .firstWhere((e) => e.session != null)
              .timeout(const Duration(seconds: 2));
        } on TimeoutException {
          debugPrint('⏸️ [Bootstrap] Auth session did not resolve in 2s — skipping prefetch');
          return;
        }
      }
      final uid = supabase.auth.currentUser?.id;
      if (uid == null || uid.isEmpty) {
        debugPrint('⏸️ [Bootstrap] No user_id in session — skipping prefetch');
        return;
      }

      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) return;

      debugPrint('⚡ [Bootstrap] Prefetching home data for $uid...');
      final stopwatch = Stopwatch()..start();

      // Single API call for all home screen data
      // Uses apiClient.get() which handles auth headers and base URL correctly
      final response = await apiClient.get(
        '/home/bootstrap',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode != 200 || response.data == null) return;

      final data = response.data as Map<String, dynamic>;

      // Pre-seed today workout cache
      _preSeedWorkout(data['today_workout']);

      // Pre-seed nutrition data
      _preSeedNutrition(ref, data['nutrition_summary']);

      // Pre-seed hydration data
      _preSeedHydration(ref, data['hydration']);

      // Persist the raw blob to disk so the NEXT cold start can pre-hydrate
      // Home before the first frame (see [hydrateFromDiskBlob]). Wrapped in a
      // versioned, local-date-stamped envelope. Fire-and-forget — never block
      // the prefetch on disk I/O.
      // ignore: unawaited_futures
      _persistBlob(uid, data);

      _hasPrefetched = true;
      stopwatch.stop();
      debugPrint('⚡ [Bootstrap] Prefetch complete in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      debugPrint('⚠️ [Bootstrap] Prefetch failed: $e');
    }
  }

  /// Pre-seed today workout from bootstrap workout summary.
  /// The bootstrap WorkoutSummary fields match TodayWorkoutSummary.fromJson() keys.
  static void _preSeedWorkout(dynamic workoutData) {
    try {
      if (workoutData != null) {
        final workoutMap = workoutData as Map<String, dynamic>;
        final isToday = workoutMap['is_today'] == true;
        final summary = TodayWorkoutSummary(
          id: workoutMap['id'] as String? ?? '',
          name: workoutMap['name'] as String? ?? 'Workout',
          type: workoutMap['type'] as String? ?? 'strength',
          difficulty: workoutMap['difficulty'] as String? ?? 'medium',
          durationMinutes: workoutMap['duration_minutes'] as int? ?? 45,
          exerciseCount: workoutMap['exercise_count'] as int? ?? 0,
          primaryMuscles: (workoutMap['primary_muscles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [],
          scheduledDate: workoutMap['scheduled_date'] as String? ?? '',
          isToday: isToday,
          isCompleted: workoutMap['is_completed'] as bool? ?? false,
          generationMethod: workoutMap['generation_method'] as String?,
        );
        final todayWorkoutResponse = TodayWorkoutResponse(
          hasWorkoutToday: isToday,
          todayWorkout: isToday ? summary : null,
          nextWorkout: !isToday ? summary : null,
        );
        TodayWorkoutNotifier.preSeedCache(todayWorkoutResponse);
      } else {
        // No workout — pre-seed empty response so provider doesn't show loading
        TodayWorkoutNotifier.preSeedCache(const TodayWorkoutResponse(
          hasWorkoutToday: false,
        ));
      }
    } catch (e) {
      debugPrint('⚠️ [Bootstrap] Workout pre-seed failed: $e');
    }
  }

  /// Pre-seed nutrition summary from bootstrap data.
  static void _preSeedNutrition(Ref ref, dynamic nutritionData) {
    if (nutritionData == null) return;
    try {
      final m = nutritionData as Map<String, dynamic>;
      ref.read(nutritionProvider.notifier).preSeedFromBootstrap(
        calories: (m['calories'] as num?)?.toInt() ?? 0,
        targetCalories: (m['target_calories'] as num?)?.toInt(),
        protein: (m['protein'] as num?)?.toDouble() ?? 0.0,
        carbs: (m['carbs'] as num?)?.toDouble() ?? 0.0,
        fat: (m['fat'] as num?)?.toDouble() ?? 0.0,
        targetProtein: (m['target_protein'] as num?)?.toDouble(),
        targetCarbs: (m['target_carbs'] as num?)?.toDouble(),
        targetFat: (m['target_fat'] as num?)?.toDouble(),
      );
    } catch (e) {
      debugPrint('⚠️ [Bootstrap] Nutrition pre-seed failed: $e');
    }
  }

  /// Pre-seed hydration data from bootstrap data.
  static void _preSeedHydration(Ref ref, dynamic hydrationData) {
    if (hydrationData == null) return;
    try {
      final m = hydrationData as Map<String, dynamic>;
      ref.read(hydrationProvider.notifier).preSeedFromBootstrap(
        currentMl: (m['current_ml'] as num?)?.toInt() ?? 0,
        targetMl: (m['target_ml'] as num?)?.toInt() ?? 2500,
      );
    } catch (e) {
      debugPrint('⚠️ [Bootstrap] Hydration pre-seed failed: $e');
    }
  }
}
