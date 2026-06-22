import 'dart:async';
import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io' show Platform;
import 'dart:math' show min, pow;
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart'
    show Sentry, Breadcrumb, SentryLevel;
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import '../repositories/auth_repository.dart' show authStateProvider;
import '../../core/providers/wearable_provider.dart';
import '../local/database.dart';
import '../local/database_provider.dart';
import '../models/workout.dart';
import '../repositories/workout_repository.dart';
import '../services/data_cache_service.dart';
import '../services/connectivity_service.dart';
import '../services/wearable_service.dart';
import '../../services/workout_generation_orchestrator.dart';

/// Tracks poll count for exponential backoff
/// Prevents excessive API calls when generation is failing
int _generationPollCount = 0;

/// Maximum number of polls before giving up
/// ~2 minutes with exponential backoff: 2s, 4s, 8s, 16s, 30s, 30s...
const int _maxGenerationPolls = 30;

/// Calculate backoff seconds with exponential growth, capped at 30s
int _getBackoffSeconds() {
  // 2s, 4s, 8s, 16s, 30s (capped)
  return min(30, 2 * pow(2, min(_generationPollCount, 4)).toInt());
}

/// In-memory cache for instant display on provider recreation
/// This survives provider invalidation and prevents loading flash
TodayWorkoutResponse? _inMemoryCache;

/// Tracks the most recent time the retry CTA fired. Used to debounce
/// double-taps of the retry button so we don't launch two generation jobs
/// back-to-back. Survives provider invalidation (top-level static).
DateTime? _lastRetryFiredAt;

/// Tracks when the current generation polling cycle started. Used by the
/// 3-minute hard ceiling so a stuck `is_generating=true` on the backend
/// can't keep the UI spinning forever even if the poll cap is misconfigured.
DateTime? _generationStartedAt;

/// Provider for today's workout data with cache-first pattern
///
/// Features:
/// - Cache-first: Shows cached data instantly, fetches fresh in background
/// - In-memory cache: Survives provider invalidation, prevents loading flash
/// - Silent updates: UI updates automatically when fresh data arrives
/// - Auto-polls when is_generating is true (JIT generation in progress)
/// - Exponential backoff to prevent excessive API calls
/// - Auto-syncs to WearOS watch when workout is available (Android only)
// Tracks which user_id the static `_inMemoryCache` and generation flags
// belong to. On real user_id change we wipe them so the new user doesn't
// inherit the previous user's "Generating workout…" state or workout data.
String? _todayCacheOwnerUserId;

final todayWorkoutProvider =
    StateNotifierProvider<TodayWorkoutNotifier, AsyncValue<TodayWorkoutResponse?>>((ref) {
  // Watch the user_id specifically so the notifier is recreated cleanly on
  // sign-out → sign-in (different account or same). Watching the whole
  // AuthState would churn on every token refresh. The notifier itself reads
  // user_id from the live Supabase session inside `_currentUserId()` — the
  // .select here is what triggers the rebuild boundary on user change.
  final userId = ref.watch(authStateProvider.select((s) => s.user?.id));
  if (userId != null && userId != _todayCacheOwnerUserId) {
    // PLAN §3C — real user-id change. Reset everything that survives
    // notifier disposal, otherwise the new user inherits the prior user's
    // generation flags and gets stuck polling forever.
    _todayCacheOwnerUserId = userId;
    _inMemoryCache = null;
    TodayWorkoutNotifier._isAutoGenerating = false;
    TodayWorkoutNotifier._hasTriggeredGeneration = false;
    TodayWorkoutNotifier._generationTimedOut = false;
    TodayWorkoutNotifier._lastGenerationFailure = null;
  }
  return TodayWorkoutNotifier(ref);
});

/// State notifier for today's workout with cache-first pattern
class TodayWorkoutNotifier extends StateNotifier<AsyncValue<TodayWorkoutResponse?>> {
  final Ref _ref;
  Timer? _pollingTimer;
  Timer? _backgroundGenPollTimer;
  Timer? _backgroundGenTimeout;
  bool _isRefreshing = false;
  bool _disposed = false;

  /// STATIC: Tracks if auto-generation is in progress
  /// Static so it survives provider invalidation (prevents duplicate /generate-stream calls)
  static bool _isAutoGenerating = false;

  /// STATIC: Tracks if generation has already been triggered for current cycle
  /// Prevents poll-triggered re-generation (every 15s poll re-calling /generate-stream)
  static bool _hasTriggeredGeneration = false;

  /// STATIC: Cooldown tracking for failed generation attempts
  /// Static so it survives provider invalidation (prevents 429 spam after failure)
  static DateTime? _lastGenerationFailure;
  static const Duration _generationCooldown = Duration(seconds: 30);

  /// STATIC: Tracks if generation timed out — prevents auto-re-trigger loop
  /// When true, the "Generate Workout" button is shown instead of auto-triggering
  static bool _generationTimedOut = false;

  /// A2 circuit breaker: count consecutive timeout-class failures. Resets on
  /// any successful response. When the count exceeds _circuitOpenThreshold
  /// we stop auto-retrying and surface a "Tap to retry" empty state — this
  /// prevents the 100-request 25 s loop seen in Sentry FITWIZ-FLUTTER-97
  /// when the backend or connectivity layer is degraded.
  int _consecutiveTimeoutFailures = 0;
  bool _circuitOpen = false;
  static const int _circuitOpenThreshold = 3;

  TodayWorkoutNotifier(this._ref)
      : super(
          // Start with in-memory cache if available (instant, no loading flash)
          // Otherwise start with loading state
          _inMemoryCache != null
              ? AsyncValue.data(_inMemoryCache)
              : const AsyncValue.loading(),
        ) {
    // Only load if we don't have in-memory cache
    // This prevents unnecessary loading state when provider is invalidated
    if (_inMemoryCache != null) {
      debugPrint('⚡ [TodayWorkout] Using in-memory cache (instant)');
      // Still fetch fresh data in background silently
      _fetchFromApi(showLoading: false);
    } else {
      // No in-memory cache — try persistent cache first (shows stale data instantly
      // instead of a loading spinner, then silently refreshes from API).
      // This is especially important after cold app start (e.g. opening app in morning)
      // where the Render backend may take 10-30s to warm up.
      _loadWithCacheFirst();
    }
    _startStuckStateWatchdog();
  }

  Timer? _watchdog;

  /// Watchdog (plan §3D): if after 5s we're still showing the cold-start
  /// loading shimmer OR a stale response with everything null and we're
  /// not currently fetching, force a fresh fetch. Catches edge cases where
  /// `_fetchFromApi` gets disposed mid-request and the next provider
  /// instance never re-fires its own fetch.
  void _startStuckStateWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer(const Duration(seconds: 5), () {
      if (_disposed || _isRefreshing) return;
      final v = state.valueOrNull;
      final stuck = state.isLoading ||
          (v != null && v.todayWorkout == null && v.nextWorkout == null && !v.isGenerating);
      if (stuck && _currentUserId() != null) {
        debugPrint('🐶 [TodayWorkout] Watchdog fired — state stuck, forcing refresh');
        // §12 — surface stuck-state events as a Sentry breadcrumb so we can
        // correlate them in session replays without spamming exceptions.
        try {
          Sentry.addBreadcrumb(Breadcrumb(
            category: 'state.stuck',
            message: 'today_workout watchdog fired',
            level: SentryLevel.warning,
          ));
        } catch (_) {
          // Sentry may not be initialized in test/debug paths — ignore.
        }
        _fetchFromApi(showLoading: true);
      }
    });
  }

  /// Safely update state only if not disposed
  void _safeSetState(AsyncValue<TodayWorkoutResponse?> newState) {
    if (!_disposed && mounted) {
      state = newState;
    }
  }

  /// Read the current user_id straight from Supabase's live auth session.
  /// Used to scope SharedPreferences cache keys per-user — see DataCacheService.
  /// Reads from `currentUser` (not a cached field) per the JWT-expiry rule in
  /// project memory: stale captured ids silently lose data to the wrong slot.
  String? _currentUserId() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  /// Load data with cache-first pattern — cache read and API fetch race in
  /// PARALLEL:
  /// 1. Fire the API fetch immediately (don't queue it behind the disk read)
  /// 2. Paint stale cache the instant it's available, if the API hasn't
  ///    already delivered fresh data
  /// 3. The API result then overwrites silently when it returns
  ///
  /// Previously the SharedPreferences + Drift read sat IN FRONT of the
  /// network call (`await _loadFromCache()` then `await _fetchFromApi()`),
  /// so on a cold start the `/today` request didn't even leave the device
  /// until the cold disk read finished — its latency was added directly to
  /// the hero's loading-skeleton time. Racing them removes that from the
  /// critical path.
  Future<void> _loadWithCacheFirst() async {
    // Step 1: fire the API fetch immediately, in parallel with the disk read.
    final apiFuture = _fetchFromApi(showLoading: false);

    // Step 2: paint stale cached data as soon as it's read — but only if the
    // API hasn't already delivered fresh data (never clobber fresh w/ stale).
    final cachedData = await _loadFromCache();
    if (cachedData != null && !state.hasValue) {
      debugPrint('⚡ [TodayWorkout] Loaded from cache instantly');
      _safeSetState(AsyncValue.data(cachedData));
    }

    // Step 3: await the fetch so callers (refresh paths) still sequence.
    await apiFuture;
  }

  /// Load cached workout data from persistent storage
  /// Tries SharedPreferences first, then falls back to Drift local DB
  /// Also updates in-memory cache for future instant access
  Future<TodayWorkoutResponse?> _loadFromCache() async {
    // Layer 1: Try SharedPreferences (fastest, has full TodayWorkoutResponse)
    try {
      final cached = await DataCacheService.instance.getCached(
        DataCacheService.todayWorkoutKey,
        userId: _currentUserId(),
      );
      if (cached != null) {
        final response = TodayWorkoutResponse.fromJson(cached);
        _inMemoryCache = response;
        debugPrint('⚡ [TodayWorkout] Loaded from SharedPreferences cache');
        return response;
      }
    } catch (e) {
      debugPrint('⚠️ [TodayWorkout] SharedPreferences cache parse error: $e');
    }

    // Layer 2: Fallback to Drift local DB (has individual workouts)
    try {
      final db = _ref.read(appDatabaseProvider);
      final repository = _ref.read(workoutRepositoryProvider);
      final userId = await repository.getCurrentUserId();
      if (userId != null) {
        final todayStr = _todayDateString();
        final localWorkouts = await db.workoutDao.getWorkoutsForDateRange(
          userId, todayStr, todayStr,
        );
        if (localWorkouts.isNotEmpty) {
          final summary = _cachedWorkoutToSummary(localWorkouts.first);
          final response = TodayWorkoutResponse(
            hasWorkoutToday: true,
            todayWorkout: summary,
          );
          _inMemoryCache = response;
          debugPrint('⚡ [TodayWorkout] Loaded from Drift local DB fallback');
          return response;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [TodayWorkout] Drift cache fallback error: $e');
    }

    return null;
  }

  /// Normalize response: clear isGenerating when real displayable content exists.
  /// Prevents stale isGenerating flag from blocking cache writes or UI updates.
  /// Extracted for reuse in both _fetchFromApi and background polling paths.
  TodayWorkoutResponse _normalizeResponse(TodayWorkoutResponse response) {
    if (response.hasDisplayableContent && response.isGenerating) {
      // Safety: if the workout is a generation placeholder (name="Generating...",
      // 0 exercises), do NOT treat it as real content — let isGenerating stay true
      // so polling continues until the real workout is ready.
      final isPlaceholder = response.todayWorkout?.name == 'Generating...' &&
          (response.todayWorkout?.exerciseCount ?? 0) == 0;
      if (!isPlaceholder) {
        debugPrint('🔄 [TodayWorkout] Normalized: cleared isGenerating (real content exists)');
        return TodayWorkoutResponse(
          hasWorkoutToday: response.hasWorkoutToday,
          todayWorkout: response.todayWorkout,
          nextWorkout: response.nextWorkout,
          daysUntilNext: response.daysUntilNext,
          restDayMessage: response.restDayMessage,
          completedToday: response.completedToday,
          completedWorkout: response.completedWorkout,
          extraTodayWorkouts: response.extraTodayWorkouts,
          isGenerating: false,
          generationMessage: null,
          needsGeneration: response.needsGeneration,
          nextWorkoutDate: response.nextWorkoutDate,
          gymProfileId: response.gymProfileId,
        );
      }
    }
    return response;
  }

  /// Save workout data to cache (in-memory, SharedPreferences, and Drift)
  Future<void> _saveToCache(TodayWorkoutResponse response) async {
    // Don't cache if generating AND there's no real displayable content
    // (placeholder-only transient state shouldn't be persisted)
    if (response.isGenerating && !response.hasDisplayableContent) return;

    // PLAN §3E: refuse to overwrite a populated in-memory cache with a
    // null-on-everything response. An empty "today" + empty "next" is "no
    // data right now from this fetch" — keep the prior cached good data so
    // the user doesn't fall back to "No workout yet" while the next fetch
    // races to refill.
    if (response.todayWorkout == null &&
        response.nextWorkout == null &&
        !response.isGenerating &&
        _inMemoryCache != null &&
        (_inMemoryCache!.todayWorkout != null ||
            _inMemoryCache!.nextWorkout != null)) {
      debugPrint('🛡️ [TodayWorkout] Refused to overwrite cached workout with empty response');
      return;
    }

    // Update in-memory cache FIRST (instant for next provider recreation)
    _inMemoryCache = response;

    // Save to SharedPreferences (full response with TTL)
    try {
      await DataCacheService.instance.cache(
        DataCacheService.todayWorkoutKey,
        response.toJson(),
        userId: _currentUserId(),
      );
    } catch (e) {
      debugPrint('⚠️ [TodayWorkout] Cache save error: $e');
    }

    // Save individual workouts to Drift for offline/restart fallback
    try {
      final db = _ref.read(appDatabaseProvider);
      final repository = _ref.read(workoutRepositoryProvider);
      final userId = await repository.getCurrentUserId();
      if (userId != null) {
        if (response.todayWorkout != null) {
          await db.workoutDao.upsertWorkout(
            _summaryToCompanion(response.todayWorkout!, userId),
          );
        }
        if (response.nextWorkout != null) {
          await db.workoutDao.upsertWorkout(
            _summaryToCompanion(response.nextWorkout!, userId),
          );
        }
        for (final extra in response.extraTodayWorkouts) {
          await db.workoutDao.upsertWorkout(
            _summaryToCompanion(extra, userId),
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ [TodayWorkout] Drift cache save error: $e');
    }
  }

  /// Convert TodayWorkoutSummary to CachedWorkoutsCompanion for Drift upsert
  CachedWorkoutsCompanion _summaryToCompanion(TodayWorkoutSummary summary, String userId) {
    return CachedWorkoutsCompanion(
      id: Value(summary.id),
      userId: Value(userId),
      name: Value(summary.name),
      type: Value(summary.type),
      difficulty: Value(summary.difficulty),
      scheduledDate: Value(summary.scheduledDate),
      isCompleted: Value(summary.isCompleted),
      exercisesJson: Value(jsonEncode(summary.exercises.map((e) => e.toJson()).toList())),
      durationMinutes: Value(summary.durationMinutes),
      generationMethod: Value(summary.generationMethod),
      cachedAt: Value(DateTime.now()),
      syncStatus: const Value('synced'),
    );
  }

  /// Convert CachedWorkout (Drift row) to TodayWorkoutSummary
  TodayWorkoutSummary _cachedWorkoutToSummary(CachedWorkout cached) {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    List<dynamic> exercisesList = [];
    try {
      exercisesList = (jsonDecode(cached.exercisesJson) as List<dynamic>?) ?? [];
    } catch (_) {}

    return TodayWorkoutSummary.fromJson({
      'id': cached.id,
      'name': cached.name ?? 'Workout',
      'type': cached.type ?? 'strength',
      'difficulty': cached.difficulty ?? 'medium',
      'duration_minutes': cached.durationMinutes ?? 45,
      'exercise_count': exercisesList.length,
      'primary_muscles': <String>[],
      'scheduled_date': cached.scheduledDate ?? todayStr,
      'is_today': cached.scheduledDate == todayStr,
      'is_completed': cached.isCompleted,
      'exercises': exercisesList,
      'generation_method': cached.generationMethod,
    });
  }

  /// Get today's date string in YYYY-MM-DD format
  String _todayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Fetch fresh data from API
  Future<void> _fetchFromApi({bool showLoading = false}) async {
    if (_isRefreshing || _disposed) return;
    // A2 circuit breaker — refuse to fetch if too many consecutive timeouts.
    // Reset only on explicit user refresh (see refresh() / forceRefresh()).
    if (_circuitOpen) {
      debugPrint('🔌 [TodayWorkout] circuit open — refusing auto-retry');
      return;
    }
    _isRefreshing = true;

    final apiSw = Stopwatch()..start();
    try {
      if (showLoading) {
        debugPrint('⏱️ [startup] /today fetch showing spinner (cold cache miss)');
        _safeSetState(const AsyncValue.loading());
      }

      // Early exit if disposed during async gap
      if (_disposed) return;

      final repository = _ref.read(workoutRepositoryProvider);
      var response = await repository.getTodayWorkout();
      debugPrint('⏱️ [startup] /today fetch returned in ${apiSw.elapsedMilliseconds}ms (showLoading=$showLoading)');

      // B5 OFFLINE WIRING — the cloud `/today` call (getTodayWorkout) catches
      // its own errors and returns null when the device is offline. If we're
      // offline AND there's nothing in the disk/in-memory cache for today
      // either, fall back to the on-device orchestrator so the user still
      // gets a workout with no connection. Per no-silent-fallback rules,
      // getOfflineWorkout THROWS on an empty library / zero-result generation,
      // and we surface that as an error state rather than swallowing it.
      if (response == null && !_disposed) {
        final isOnline = _ref.read(isOnlineProvider);
        // "Disk cache had nothing for today" == we have no displayable cached
        // content. _loadWithCacheFirst races the disk read into `state`/
        // `_inMemoryCache`, so both being empty means the cache miss is real.
        final cachedHasContent = (_inMemoryCache?.hasDisplayableContent ??
                false) ||
            (state.valueOrNull?.hasDisplayableContent ?? false);
        if (!isOnline && !cachedHasContent) {
          final offline = await _tryOfflineWorkout();
          if (offline == null) {
            // Offline generation failed and already surfaced an error state
            // (empty library / over-constrained / zero-result). Stop here —
            // do NOT fall through to the empty-state / needs-generation paths
            // which would clobber the actionable error with "No workout yet".
            return;
          }
          response = offline;
        }
      }

      // §8d — a fresh response carrying real content must clear any stale
      // poll-cap sentinel set by a previous cycle. copyWith can't null the
      // field (uses `??`), so rebuild explicitly when needed.
      if (response != null &&
          response.lastGenerationError != null &&
          (response.todayWorkout != null || response.nextWorkout != null)) {
        response = TodayWorkoutResponse(
          hasWorkoutToday: response.hasWorkoutToday,
          todayWorkout: response.todayWorkout,
          nextWorkout: response.nextWorkout,
          daysUntilNext: response.daysUntilNext,
          restDayMessage: response.restDayMessage,
          completedToday: response.completedToday,
          completedWorkout: response.completedWorkout,
          extraTodayWorkouts: response.extraTodayWorkouts,
          isGenerating: response.isGenerating,
          generationMessage: response.generationMessage,
          needsGeneration: response.needsGeneration,
          nextWorkoutDate: response.nextWorkoutDate,
          gymProfileId: response.gymProfileId,
          // lastGenerationError intentionally omitted — clears the sentinel.
        );
      }

      // §17b — successful response with workout content means the generation
      // cycle is over (either succeeded or we got cached content). Reset
      // the hard-ceiling timer so a future cycle starts fresh.
      if (response != null &&
          (response.todayWorkout != null || response.nextWorkout != null)) {
        _generationStartedAt = null;
      }

      // Handle generation polling (skip if background gen poll is already active to avoid dual timers)
      if (response?.isGenerating == true && _backgroundGenPollTimer == null) {
        _handleGenerationPolling();
      } else if (response?.isGenerating != true) {
        _cancelPolling();
        if (_generationPollCount > 0) {
          debugPrint('✅ [Generation] Complete after $_generationPollCount polls');
        }
        _generationPollCount = 0;
        _generationStartedAt = null;
      }

      // Handle auto-generation trigger.
      // GATE: never auto-generate while the user is still mid-onboarding (before
      // coach-selection sets onboarding_completed). The heavy /generate-stream
      // call would otherwise saturate the backend during the /personal-info save,
      // making that PUT take ~8s. `onboarding_completed` flips true at
      // coach-selection and the router only routes to /home once onboarding is
      // done — so being at home implies this is true and home generation is
      // unaffected. Gen still runs through the post-coach funnel to pre-warm home.
      final onboardingComplete =
          _ref.read(authStateProvider).user?.onboardingCompleted ?? false;
      if (response?.needsGeneration == true &&
          !onboardingComplete) {
        debugPrint('⏸️ [Auto-Gen] Skipped — user still onboarding '
            '(onboarding_completed=false)');
      } else if (response?.needsGeneration == true &&
          response?.nextWorkoutDate != null) {
        final hasAnyWorkout = response!.todayWorkout != null || response.nextWorkout != null;

        // Cooldown gate: if we recently failed (especially on 429), don't
        // hammer the backend on every /today poll. Without this gate, the
        // _hasTriggeredGeneration flag was the only block, but the backoff
        // timer in _triggerAutoGeneration would still re-fire after 10s
        // even though the rate window is 60s — producing the observed
        // 429-every-10s cascade in production logs (2026-05-10T03:05Z).
        final recentFailure = _lastGenerationFailure;
        final inCooldown = recentFailure != null &&
            DateTime.now().difference(recentFailure) < _generationCooldown;

        if (!hasAnyWorkout && !_hasTriggeredGeneration && !_generationTimedOut && !inCooldown) {
          // No workouts at all - show generating UI and trigger streaming gen
          // Only trigger ONCE per cycle to prevent poll-triggered re-generation spam
          debugPrint('🚀 [Auto-Gen] No workouts exist, triggering generation for date=${response.nextWorkoutDate} (profile=${response.gymProfileId})');
          _hasTriggeredGeneration = true;
          _triggerAutoGeneration(response.nextWorkoutDate!, gymProfileId: response.gymProfileId);
          _startBackgroundGenerationPolling();

          response = TodayWorkoutResponse(
            hasWorkoutToday: response.hasWorkoutToday,
            todayWorkout: response.todayWorkout,
            nextWorkout: response.nextWorkout,
            daysUntilNext: response.daysUntilNext,
            restDayMessage: response.restDayMessage,
            completedToday: response.completedToday,
            completedWorkout: response.completedWorkout,
            extraTodayWorkouts: response.extraTodayWorkouts,
            isGenerating: true,
            generationMessage: 'Generating your workout...',
            needsGeneration: false,
            nextWorkoutDate: response.nextWorkoutDate,
            gymProfileId: response.gymProfileId,
          );
        } else if (!hasAnyWorkout && _hasTriggeredGeneration && !_generationTimedOut) {
          // Already triggered generation - just show generating UI without re-triggering
          debugPrint('⏳ [Auto-Gen] Generation already triggered, waiting for completion');
          response = TodayWorkoutResponse(
            hasWorkoutToday: response.hasWorkoutToday,
            todayWorkout: response.todayWorkout,
            nextWorkout: response.nextWorkout,
            daysUntilNext: response.daysUntilNext,
            restDayMessage: response.restDayMessage,
            completedToday: response.completedToday,
            completedWorkout: response.completedWorkout,
            extraTodayWorkouts: response.extraTodayWorkouts,
            isGenerating: true,
            generationMessage: 'Generating your workout...',
            needsGeneration: false,
            nextWorkoutDate: response.nextWorkoutDate,
            gymProfileId: response.gymProfileId,
          );
        } else if (!hasAnyWorkout && _generationTimedOut) {
          // Generation timed out — don't auto-trigger, let user see Generate button
          debugPrint('⏰ [Auto-Gen] Generation timed out previously, showing manual generate button');
          // Let the response pass through as-is (needsGeneration=true, isGenerating=false)
          // The UI will show the GenerateWorkoutPlaceholder with "GENERATE WORKOUT" button
        } else if (!hasAnyWorkout && inCooldown) {
          // We're inside the post-failure cooldown — render the "Generating…"
          // hero card so the user sees activity, but DO NOT trigger another
          // request. The next /today poll outside the cooldown window will
          // pick up generation.
          final secsLeft = _generationCooldown.inSeconds -
              DateTime.now().difference(recentFailure).inSeconds;
          debugPrint('⏸️ [Auto-Gen] In cooldown, ${secsLeft}s remaining before next attempt');
          response = TodayWorkoutResponse(
            hasWorkoutToday: response.hasWorkoutToday,
            todayWorkout: response.todayWorkout,
            nextWorkout: response.nextWorkout,
            daysUntilNext: response.daysUntilNext,
            restDayMessage: response.restDayMessage,
            completedToday: response.completedToday,
            completedWorkout: response.completedWorkout,
            extraTodayWorkouts: response.extraTodayWorkouts,
            isGenerating: true,
            generationMessage: 'Hold on a moment — retrying shortly…',
            needsGeneration: false,
            nextWorkoutDate: response.nextWorkoutDate,
            gymProfileId: response.gymProfileId,
          );
        } else {
          // Workouts exist - backend background tasks handle remaining dates silently
          debugPrint('✅ [Auto-Gen] Workouts already exist, letting backend handle remaining generation silently');
        }
      }

      // Normalize: clear isGenerating when real displayable content exists
      if (response != null) {
        response = _normalizeResponse(response);
      }

      // Handle empty state polling
      if (response?.todayWorkout == null &&
          response?.nextWorkout == null &&
          response?.completedToday != true &&
          response?.isGenerating != true &&
          response?.needsGeneration != true) {
        _scheduleEmptyStateRefresh();
      }

      // Sync to watch (Android only)
      if (Platform.isAndroid && response?.todayWorkout != null && !response!.isGenerating) {
        _syncWorkoutToWatch(response.todayWorkout!);
      }

      // Update state with fresh data (only if not disposed)
      if (!_disposed) {
        _safeSetState(AsyncValue.data(response));
      }

      // Save to cache for next app open
      if (response != null) {
        await _saveToCache(response);
      }
      // A2: any successful response resets the timeout counter.
      _consecutiveTimeoutFailures = 0;
    } catch (e, stack) {
      debugPrint('❌ [TodayWorkout] API error: $e');
      // A2 — classify timeout-ish failures so we can short-circuit. Dio's
      // DioException with type connectionTimeout/receiveTimeout/sendTimeout
      // is the common shape; we also bucket the connectivity-flap pattern
      // (SocketException, HandshakeException) as "timeout-like" since
      // they cascade into the same 25s wait + retry loop in production.
      final eStr = e.toString();
      final isTimeoutLike = eStr.contains('TimeoutException') ||
          eStr.contains('Timeout') ||
          eStr.contains('SocketException') ||
          eStr.contains('Connection closed') ||
          eStr.contains('Connection reset') ||
          eStr.contains('connectionTimeout') ||
          eStr.contains('receiveTimeout') ||
          eStr.contains('sendTimeout');
      if (isTimeoutLike) {
        _consecutiveTimeoutFailures += 1;
        if (_consecutiveTimeoutFailures >= _circuitOpenThreshold) {
          _circuitOpen = true;
          debugPrint('🔌 [TodayWorkout] circuit open — '
              '$_consecutiveTimeoutFailures consecutive timeouts. Auto-retry stopped.');
          _cancelPolling();
        }
      }
      // Only set error state if we don't have cached data and not disposed
      if (!_disposed && !state.hasValue) {
        _safeSetState(AsyncValue.error(e, stack));
      }
    } finally {
      _isRefreshing = false;
      // §11 — re-arm the watchdog after every completed fetch (success or
      // error) so subsequent stuck-state windows still get caught. The
      // watchdog cancels its prior timer on each call so this is idempotent.
      if (!_disposed) {
        _startStuckStateWatchdog();
      }
    }
  }

  /// B5 OFFLINE WIRING — on-device fallback when the cloud `/today` flow
  /// returned null while OFFLINE and nothing was cached for today.
  ///
  /// Routes through the already-shipped
  /// [WorkoutGenerationOrchestrator.getOfflineWorkout], which serves a
  /// pre-cached server workout if one was downloaded for today, else builds a
  /// rule-based workout on-device from the bundled exercise library. The
  /// generated workout is mapped into a [TodayWorkoutResponse] and saved to
  /// cache (so a subsequent provider rebuild paints it instantly).
  ///
  /// Returns the [TodayWorkoutResponse] on success. On failure (empty library /
  /// over-constrained / zero-result — getOfflineWorkout THROWS in those cases),
  /// this SURFACES the descriptive error to the UI via an error state and
  /// returns null. We never swallow the error or fabricate an empty workout.
  Future<TodayWorkoutResponse?> _tryOfflineWorkout() async {
    final userId = _currentUserId();
    if (userId == null) {
      debugPrint('⚠️ [TodayWorkout] Offline fallback skipped — no user id');
      return null;
    }

    debugPrint('📴 [TodayWorkout] Offline + no cached workout — trying on-device generation');
    try {
      final orchestrator = _ref.read(workoutGenerationOrchestratorProvider);
      // splitType: the orchestrator's rule-based generator falls back to
      // 'full_body' for unknown splits, and full_body is the safest universal
      // template for an offline fallback (no equipment/movement assumptions).
      final workout = await orchestrator.getOfflineWorkout(
        userId: userId,
        splitType: 'full_body',
        scheduledDate: _todayDateString(),
      );

      final summary = _offlineWorkoutToSummary(workout);
      final response = TodayWorkoutResponse(
        hasWorkoutToday: true,
        todayWorkout: summary,
      );

      // Persist so the next provider build / app open paints instantly.
      await _saveToCache(response);
      debugPrint('✅ [TodayWorkout] Offline workout ready (${summary.exerciseCount} exercises)');
      return response;
    } catch (e, stack) {
      // No-silent-fallback: surface the orchestrator's descriptive message
      // (empty library / over-constrained) as an error state for the UI.
      debugPrint('❌ [TodayWorkout] Offline generation failed: $e');
      if (!_disposed) {
        _safeSetState(AsyncValue.error(e, stack));
      }
      return null;
    }
  }

  /// Map an offline-generated [Workout] into a [TodayWorkoutSummary] for the
  /// today state. Mirrors the field mapping used by [_cachedWorkoutToSummary].
  TodayWorkoutSummary _offlineWorkoutToSummary(Workout workout) {
    final todayStr = _todayDateString();
    final scheduled = workout.scheduledDate ?? todayStr;
    return TodayWorkoutSummary(
      id: workout.id ?? '',
      name: workout.name ?? 'Workout',
      type: workout.type ?? 'strength',
      difficulty: workout.difficulty ?? 'medium',
      durationMinutes: workout.durationMinutes ?? 45,
      exerciseCount: workout.exerciseCount,
      primaryMuscles: workout.primaryMuscles,
      scheduledDate: scheduled,
      isToday: scheduled.length >= 10 && scheduled.substring(0, 10) == todayStr,
      isCompleted: workout.isCompleted ?? false,
      exercises: workout.exercises,
      generationMethod: workout.generationMethod,
    );
  }

  /// Handle generation polling with exponential backoff
  void _handleGenerationPolling() {
    if (_disposed) return;

    // §17b — stamp the start of this generation cycle the first time we
    // enter polling so the 3-minute hard ceiling has a reference point.
    _generationStartedAt ??= DateTime.now();

    // §17b — hard ceiling: regardless of poll-cap state, if we've been
    // polling for more than 3 minutes total, force the sentinel path so
    // the user is never stranded by a misconfigured cap or a stuck
    // backend `is_generating=true`.
    final startedAt = _generationStartedAt;
    if (startedAt != null &&
        DateTime.now().difference(startedAt) > const Duration(minutes: 3)) {
      debugPrint('⏰ [Generation] 3-minute hard ceiling reached, stopping polling');
      _generationPollCount = 0;
      _generationStartedAt = null;
      final current = state.valueOrNull;
      if (current != null && !_disposed) {
        _safeSetState(AsyncValue.data(current.copyWith(
          isGenerating: false,
          lastGenerationError:
              'Generation took longer than expected. Tap to retry.',
        )));
      }
      _generationTimedOut = true;
      _cancelPolling();
      return;
    }

    if (_generationPollCount < _maxGenerationPolls) {
      _generationPollCount++;
      final backoffSeconds = _getBackoffSeconds();
      debugPrint('🔄 [Generation] Poll #$_generationPollCount, next in ${backoffSeconds}s');

      _pollingTimer?.cancel();
      _pollingTimer = Timer(Duration(seconds: backoffSeconds), () {
        if (!_disposed) {
          _fetchFromApi();
        }
      });
    } else {
      debugPrint('❌ [Generation] Max polls ($_maxGenerationPolls) reached. Stopping auto-refresh.');
      _generationPollCount = 0;
      _generationStartedAt = null;
      // PLAN §4: surface the polling exhaustion as a retry sentinel on the
      // current response so the hero card can render a tappable retry CTA
      // instead of silently sliding to "No workout yet".
      final current = state.valueOrNull;
      if (current != null && !_disposed) {
        _safeSetState(AsyncValue.data(current.copyWith(
          isGenerating: false,
          lastGenerationError:
              'Generation took longer than expected. Tap to retry.',
        )));
      }
      _generationTimedOut = true;
    }
  }

  /// Cancel any active polling
  void _cancelPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Schedule refresh for empty state
  void _scheduleEmptyStateRefresh() {
    if (_disposed) return;

    _pollingTimer?.cancel();
    _pollingTimer = Timer(const Duration(seconds: 3), () {
      if (!_disposed) {
        _fetchFromApi();
      }
    });
  }

  /// Start polling for background-generated workout (Fix 2)
  ///
  /// When the backend signals needs_generation=true, it also starts generating
  /// the workout in a background task. This method polls every 5 seconds until
  /// the workout appears, with a 2-minute safety timeout.
  void _startBackgroundGenerationPolling() {
    if (_disposed) return;

    // Cancel any existing poll timers (including generation polling to avoid dual timers)
    _backgroundGenPollTimer?.cancel();
    _backgroundGenTimeout?.cancel();
    _cancelPolling();

    debugPrint('[TodayWorkout] Starting background generation polling (every 15s, 3min timeout)');

    _backgroundGenPollTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (_disposed) {
        _backgroundGenPollTimer?.cancel();
        return;
      }

      debugPrint('[TodayWorkout] Background gen poll: checking for generated workout...');

      // Directly fetch from the API (bypass the auto-generation logic by checking result)
      try {
        final repository = _ref.read(workoutRepositoryProvider);
        final response = await repository.getTodayWorkout();

        if (response != null && !_disposed) {
          final hasWorkout = response.todayWorkout != null || response.nextWorkout != null;
          if (hasWorkout) {
            // Backend generated the workout! Show it immediately.
            debugPrint('✅ [TodayWorkout] Backend generated workout, displaying');
            _stopBackgroundGenerationPolling();
            _hasTriggeredGeneration = false;
            _generationTimedOut = false;
            // Normalize before caching (clears stale isGenerating flag)
            final normalized = _normalizeResponse(response);
            _safeSetState(AsyncValue.data(normalized));
            await _saveToCache(normalized);
          }
          // If no workout yet, the streaming auto-retry is still running — just wait
        }
      } catch (e) {
        debugPrint('⚠️ [TodayWorkout] Poll error: $e');
      }
    });

    // Safety timeout: 3 minutes gives auto-retry (3 attempts with backoff) time to complete.
    // If STILL no workout after 3 min, clear the spinner so the user isn't stuck.
    _backgroundGenTimeout = Timer(const Duration(minutes: 3), () {
      if (!_disposed) {
        debugPrint('⏰ [TodayWorkout] Background generation timed out (3min), recovering');
        _stopBackgroundGenerationPolling();

        _generationTimedOut = true;
        _hasTriggeredGeneration = false;
        _isAutoGenerating = false;

        // Clear the stuck isGenerating state so the user sees Generate button
        final current = state.valueOrNull;
        if (current != null && current.isGenerating) {
          _safeSetState(AsyncValue.data(TodayWorkoutResponse(
            hasWorkoutToday: current.hasWorkoutToday,
            todayWorkout: current.todayWorkout,
            nextWorkout: current.nextWorkout,
            daysUntilNext: current.daysUntilNext,
            restDayMessage: current.restDayMessage,
            completedToday: current.completedToday,
            completedWorkout: current.completedWorkout,
            extraTodayWorkouts: current.extraTodayWorkouts,
            isGenerating: false,
            generationMessage: null,
            needsGeneration: true,
            nextWorkoutDate: current.nextWorkoutDate,
            gymProfileId: current.gymProfileId,
          )));
        }
      }
    });
  }

  /// Stop background generation polling
  void _stopBackgroundGenerationPolling() {
    _backgroundGenPollTimer?.cancel();
    _backgroundGenPollTimer = null;
    _backgroundGenTimeout?.cancel();
    _backgroundGenTimeout = null;
  }

  /// Public method to force refresh from API
  ///
  /// A2: user-initiated refresh ALWAYS resets the circuit breaker so a
  /// degraded connection can recover on user pull-to-refresh / connectivity
  /// recovery without requiring an app restart.
  Future<void> refresh() async {
    if (_circuitOpen) {
      debugPrint('🔌 [TodayWorkout] closing circuit (user refresh)');
      _circuitOpen = false;
      _consecutiveTimeoutFailures = 0;
    }
    await _fetchFromApi(showLoading: false);
  }

  /// Synchronously evict a workout (by id) from the current `state` and the
  /// in-memory cache, before any network refresh. Used by the Replace flow:
  /// after `WorkoutsNotifier.replaceInCache(oldId, newWorkout)` updates the
  /// all-workouts cache, this removes the old workout from the today/extra
  /// fields here so the hero carousel doesn't render BOTH the new replacement
  /// (from workoutsProvider) AND the stale old one (from todayWorkoutProvider)
  /// during the 1–2s gap before `_fetchFromApi` returns.
  ///
  /// Why: the carousel merges from two providers and dedupes by id. Replace
  /// gives the new workout a new id, so both pass dedup, both share the same
  /// scheduled_date, and `_findAllWorkoutsForDate` returns both. Evicting
  /// synchronously closes that visual race.
  void evictWorkoutById(String oldId) {
    final current = state.valueOrNull;
    if (current == null) return;
    bool changed = false;
    final newToday = (current.todayWorkout?.id == oldId)
        ? null
        : current.todayWorkout;
    if (newToday != current.todayWorkout) changed = true;
    final newNext = (current.nextWorkout?.id == oldId)
        ? null
        : current.nextWorkout;
    if (newNext != current.nextWorkout) changed = true;
    final newCompleted = (current.completedWorkout?.id == oldId)
        ? null
        : current.completedWorkout;
    if (newCompleted != current.completedWorkout) changed = true;
    final filteredExtras = current.extraTodayWorkouts
        .where((w) => w.id != oldId)
        .toList(growable: false);
    if (filteredExtras.length != current.extraTodayWorkouts.length) {
      changed = true;
    }
    if (!changed) return;
    final updated = TodayWorkoutResponse(
      hasWorkoutToday: newToday != null,
      todayWorkout: newToday,
      nextWorkout: newNext,
      daysUntilNext: current.daysUntilNext,
      restDayMessage: current.restDayMessage,
      completedToday: current.completedToday,
      completedWorkout: newCompleted,
      extraTodayWorkouts: filteredExtras,
      isGenerating: current.isGenerating,
      generationMessage: current.generationMessage,
      needsGeneration: current.needsGeneration,
      nextWorkoutDate: current.nextWorkoutDate,
      gymProfileId: current.gymProfileId,
    );
    _inMemoryCache = updated;
    _safeSetState(AsyncValue.data(updated));
    debugPrint('⚡ [TodayWorkout] Evicted $oldId from state (Replace flow)');
  }

  /// Invalidate cache and refresh silently (no loading flash)
  /// Keeps _inMemoryCache intact so stale data shows while refreshing
  Future<void> invalidateAndRefresh() async {
    // Keep _inMemoryCache intact — show stale data while refreshing silently
    _hasTriggeredGeneration = false;
    _generationTimedOut = false;
    await DataCacheService.instance.invalidate(
      DataCacheService.todayWorkoutKey,
      userId: _currentUserId(),
    );
    await _fetchFromApi(showLoading: false); // silent refresh, no loading flash
  }

  /// Reset generation state (called on gym profile switch)
  /// Must be called BEFORE invalidating the provider so the new instance
  /// can trigger generation for the new profile without being blocked by stale flags.
  static void resetGenerationState() {
    _isAutoGenerating = false;
    _hasTriggeredGeneration = false;
    _lastGenerationFailure = null;
    _generationTimedOut = false;
    _inMemoryCache = null;
    // §8a — stamp the retry-fired time so a double-tap of the retry CTA
    // within the next 3s short-circuits before launching a second job.
    _lastRetryFiredAt = DateTime.now();
    debugPrint('🔄 [TodayWorkout] Generation state reset (profile switch)');
  }

  /// §8a — exposed to the UI so the retry CTA can debounce double-taps.
  /// Returns true if a retry fired within [window] (default 3s).
  static bool retryFiredRecently({Duration window = const Duration(seconds: 3)}) {
    final t = _lastRetryFiredAt;
    if (t == null) return false;
    return DateTime.now().difference(t) < window;
  }

  /// §8c — exposed to the UI so the retry CTA can show a cooldown countdown
  /// instead of silently swallowing the tap. Returns 0 if not in cooldown.
  static int generationCooldownSecondsLeft() {
    final t = _lastGenerationFailure;
    if (t == null) return 0;
    final remaining =
        _generationCooldown.inSeconds - DateTime.now().difference(t).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Clear all caches (called on logout)
  static void clearCache() {
    _inMemoryCache = null;
    _hasTriggeredGeneration = false;
    _isAutoGenerating = false;
    _generationTimedOut = false;
    debugPrint('🧹 [TodayWorkout] In-memory cache cleared');
  }

  /// Pre-seed the in-memory cache from bootstrap data so the provider
  /// starts with data instead of loading state on first construction.
  static void preSeedCache(TodayWorkoutResponse data) {
    _inMemoryCache = data;
    debugPrint('⚡ [TodayWorkout] Pre-seeded from bootstrap');
  }

  @override
  void dispose() {
    _disposed = true;
    _watchdog?.cancel();
    _cancelPolling();
    _stopBackgroundGenerationPolling();
    super.dispose();
  }

  // =====================================================
  // Auto-generation and watch sync (same as before)
  // =====================================================

  /// Maximum auto-retry attempts for generation before giving up
  static const int _maxAutoRetries = 3;

  void _triggerAutoGeneration(String scheduledDate, {String? gymProfileId, int attempt = 1}) {
    if (_isAutoGenerating || _disposed) {
      debugPrint('⏳ [Auto-Gen] Already generating or disposed, skipping request');
      return;
    }

    if (attempt > _maxAutoRetries) {
      debugPrint('❌ [Auto-Gen] Max retries ($_maxAutoRetries) exhausted');
      _generationTimedOut = true;
      _hasTriggeredGeneration = false;
      // Clear stuck isGenerating state so user sees Generate button
      final current = state.valueOrNull;
      if (current != null && current.isGenerating) {
        _safeSetState(AsyncValue.data(TodayWorkoutResponse(
          hasWorkoutToday: current.hasWorkoutToday,
          todayWorkout: current.todayWorkout,
          nextWorkout: current.nextWorkout,
          daysUntilNext: current.daysUntilNext,
          restDayMessage: current.restDayMessage,
          completedToday: current.completedToday,
          completedWorkout: current.completedWorkout,
          extraTodayWorkouts: current.extraTodayWorkouts,
          isGenerating: false,
          generationMessage: null,
          needsGeneration: true,
          nextWorkoutDate: current.nextWorkoutDate,
          gymProfileId: current.gymProfileId,
        )));
      }
      return;
    }

    _isAutoGenerating = true;
    _generationTimedOut = false;
    debugPrint('🔄 [Auto-Gen] Attempt $attempt/$_maxAutoRetries for date: $scheduledDate');

    Future(() async {
      try {
        if (_disposed) return;

        final repository = _ref.read(workoutRepositoryProvider);
        final userId = await repository.getCurrentUserId();
        if (userId == null) {
          debugPrint('❌ [Auto-Gen] No user ID available');
          return;
        }

        if (_disposed) return;

        bool completed = false;
        await for (final progress in repository.generateWorkoutStreaming(
          userId: userId,
          scheduledDate: scheduledDate,
          gymProfileId: gymProfileId,
        ).timeout(const Duration(seconds: 120), onTimeout: (sink) {
          debugPrint('⏰ [Auto-Gen] Streaming timed out after 120s (attempt $attempt)');
          sink.close();
        })) {
          if (_disposed) {
            debugPrint('⚠️ [Auto-Gen] Disposed during generation, stopping');
            break;
          }

          debugPrint('🔄 [Auto-Gen] Progress: ${progress.status} - ${progress.message}');

          if (progress.status == WorkoutGenerationStatus.completed) {
            debugPrint('✅ [Auto-Gen] Workout generated successfully!');
            completed = true;
            _lastGenerationFailure = null;
            _hasTriggeredGeneration = false;
            _generationTimedOut = false;
            _stopBackgroundGenerationPolling();
            if (!_disposed) refresh();
            break;
          }

          if (progress.status == WorkoutGenerationStatus.error) {
            debugPrint('❌ [Auto-Gen] Generation error (attempt $attempt): ${progress.message} (code=${progress.errorCode})');
            _lastGenerationFailure = DateTime.now();
            // Reset _hasTriggeredGeneration so the cooldown gate (in _fetchFromApi)
            // owns the retry decision instead of having two flags fight.
            _hasTriggeredGeneration = false;

            // RATE_LIMITED: backend tells us to wait ~60s. Don't even schedule
            // the inner backoff timer — the next /today poll will respect
            // _lastGenerationFailure + _generationCooldown and retry then.
            if (progress.errorCode == 'RATE_LIMITED') {
              debugPrint('⏸️ [Auto-Gen] RATE_LIMITED — stopping retry chain. Next /today poll outside cooldown will retry.');
              completed = false;
              _isAutoGenerating = false;
              return; // skip backoff timer entirely
            }
            break;
          }
        }

        // If failed (non-rate-limited), auto-retry after backoff
        if (!completed && !_disposed) {
          debugPrint('⚠️ [Auto-Gen] Attempt $attempt failed, scheduling retry');
          _isAutoGenerating = false;
          // Backoff: 10s, 20s, 30s
          final delaySec = min(30, 10 * attempt);
          Timer(Duration(seconds: delaySec), () {
            if (_disposed) return;
            // Re-check cooldown before re-firing — the user might have logged
            // a manual workout in the interim, or another auto-gen completed.
            final lastFail = _lastGenerationFailure;
            if (lastFail != null &&
                DateTime.now().difference(lastFail) < _generationCooldown) {
              debugPrint('⏸️ [Auto-Gen] Backoff timer fired but still in cooldown — skipping retry.');
              return;
            }
            _triggerAutoGeneration(scheduledDate,
                gymProfileId: gymProfileId, attempt: attempt + 1);
          });
          return; // Skip the finally _isAutoGenerating=false (already reset above)
        }
      } catch (e) {
        debugPrint('❌ [Auto-Gen] Error (attempt $attempt): $e');
        _lastGenerationFailure = DateTime.now();
        // Auto-retry after backoff
        if (!_disposed && attempt < _maxAutoRetries) {
          _isAutoGenerating = false;
          final delaySec = min(30, 10 * attempt);
          debugPrint('🔄 [Auto-Gen] Retrying in ${delaySec}s...');
          Timer(Duration(seconds: delaySec), () {
            if (!_disposed) {
              _triggerAutoGeneration(scheduledDate,
                  gymProfileId: gymProfileId, attempt: attempt + 1);
            }
          });
          return;
        }
      } finally {
        _isAutoGenerating = false;
      }
    });
  }

  void _syncWorkoutToWatch(TodayWorkoutSummary workout) {
    Future(() async {
      try {
        await _cacheWorkoutForWatch(workout);

        final wearableSync = _ref.read(wearableSyncProvider);
        await wearableSync.refreshConnection();
        if (!wearableSync.isConnected) {
          debugPrint('⌚ [Watch] Not connected, workout cached for later');
          return;
        }

        final watchWorkout = WearableService.instance.createWorkoutForWatch(
          id: workout.id,
          name: workout.name,
          type: workout.type,
          exercises: workout.exercises.map((e) => {
            'id': e.id,
            'name': e.name,
            'targetSets': e.sets,
            'targetReps': e.reps.toString(),
            'targetWeightKg': e.weight,
            'restSeconds': e.restSeconds ?? 60,
            'videoUrl': e.videoUrl,
            'thumbnailUrl': e.gifUrl,
          }).toList(),
          estimatedDuration: workout.durationMinutes,
          targetMuscleGroups: workout.primaryMuscles,
          scheduledDate: workout.scheduledDate,
        );

        await wearableSync.syncWorkoutToWatch(watchWorkout);
      } catch (e) {
        debugPrint('⚠️ [Watch] Error syncing workout: $e');
      }
    });
  }

  Future<void> _cacheWorkoutForWatch(TodayWorkoutSummary workout) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workoutData = {
        'workout': {
          'id': workout.id,
          'name': workout.name,
          'type': workout.type,
          'estimated_duration': workout.durationMinutes,
          'target_muscles': workout.primaryMuscles,
          'exercises': workout.exercises.map((e) => {
            'id': e.id,
            'name': e.name,
            'sets': e.sets,
            'reps': e.reps,
            'weight_kg': e.weight,
            'rest_seconds': e.restSeconds ?? 60,
            'video_url': e.videoUrl,
            'thumbnail_url': e.gifUrl,
          }).toList(),
        },
        'date': workout.scheduledDate,
      };

      await prefs.setString('today_workout_cache', jsonEncode(workoutData));
      debugPrint('💾 [Watch] Workout cached for watch sync');
    } catch (e) {
      debugPrint('⚠️ [Watch] Error caching workout: $e');
    }
  }
}

/// Family of today/upcoming workout fetches keyed by `daysOffset` from today.
///
/// `daysOffset: 0` → today (semantically identical to the legacy
/// `todayWorkoutProvider`'s top-of-state today workout).
/// `daysOffset: 1` → tomorrow.
///
/// Uses the standalone `getWorkoutsByDate` repo path (no caching / no
/// generation polling) so it's safe to spin up on demand for the workout
/// card's wind-down mode without touching today's state machine.
///
/// Returns null when the date has no scheduled workout, the user isn't
/// authenticated, or the network call fails.
final todayWorkoutFamilyProvider = FutureProvider.autoDispose
    .family<TodayWorkoutSummary?, int>((ref, daysOffset) async {
  // daysOffset == 0 — reuse the live today provider's data so we don't
  // double-fetch /today (which carries generation state we mustn't churn).
  if (daysOffset == 0) {
    final today = ref.watch(todayWorkoutProvider).valueOrNull;
    return today?.todayWorkout ?? today?.nextWorkout;
  }
  try {
    final repository = ref.read(workoutRepositoryProvider);
    final userId = await repository.getCurrentUserId();
    if (userId == null) return null;
    final target = DateTime.now().add(Duration(days: daysOffset));
    final dateStr =
        '${target.year}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}';
    // Fetch a small window via the existing workouts list endpoint and pick
    // the first workout whose scheduledDate matches. Keeps the family
    // implementation independent of any tomorrow-specific backend route.
    final workouts = await repository.getWorkouts(userId);
    Workout? match;
    for (final w in workouts) {
      if (w.scheduledDate == null) continue;
      final ds = w.scheduledDate!.split('T').first;
      if (ds == dateStr) {
        match = w;
        break;
      }
    }
    if (match == null) return null;
    return TodayWorkoutSummary.fromJson({
      'id': match.id,
      'name': match.name ?? 'Workout',
      'type': match.type ?? 'strength',
      'difficulty': match.difficulty ?? 'medium',
      'duration_minutes':
          match.durationMinutes ?? match.estimatedDurationMinutes ?? 45,
      'exercise_count': match.exercises.length,
      'primary_muscles': <String>[],
      'scheduled_date': dateStr,
      'is_today': daysOffset == 0,
      'is_completed': match.isCompleted ?? false,
      'exercises': match.exercises.map((e) => e.toJson()).toList(),
      'generation_method': match.generationMethod,
    });
  } catch (e) {
    debugPrint('⚠️ [TodayWorkoutFamily] daysOffset=$daysOffset error: $e');
    return null;
  }
});

/// Tomorrow's scheduled workout — convenience alias.
final tomorrowWorkoutProvider = todayWorkoutFamilyProvider(1);

/// Provider to track if the quick start was used
/// This helps with analytics and can be used to show different UI states
final quickStartUsedProvider = StateProvider<bool>((ref) => false);

/// Provider to force refresh of today's workout data
/// Call ref.invalidate(todayWorkoutRefreshProvider) to trigger a refresh
final todayWorkoutRefreshProvider = Provider<void>((ref) {
  // Watching this will trigger refresh
  ref.watch(todayWorkoutProvider);
});
