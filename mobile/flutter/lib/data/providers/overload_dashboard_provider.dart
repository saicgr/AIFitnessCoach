import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../models/exercise_history.dart' show ExerciseHistoryTimeRange;
import '../models/overload_dashboard.dart';
import '../repositories/auth_repository.dart';
import '../services/api_client.dart';
import '../services/data_cache_service.dart';

/// Progressive Overload Dashboard provider.
///
/// Mirrors the architecture of [scoresProvider]: a [StateNotifier] backed by a
/// static in-memory cache (survives provider recreation → no loading flash) and
/// a per-user disk cache via [DataCacheService] (`statsKeyPrefix`, 12h TTL) so a
/// cold start paints the last-known dashboard instantly before any network call.
///
/// Stale-while-revalidate: a watcher gets disk/memory data immediately, and a
/// silent background refresh updates it (memory rule: never pull-to-refresh —
/// instant from cache, refresh silently). Per the project's NO-FALLBACK rule a
/// failed fetch with NO cached data surfaces an [OverloadDashboardState.error]
/// (the screen shows retry) rather than fabricating an empty dashboard.

// ── Static caches (one process-wide slot, flushed on user switch) ──────────

OverloadDashboardState? _inMemoryCache;
String? _cacheOwnerUserId;

/// Disk key. Scoped by time range AND gym so switching either doesn't show the
/// wrong slice. Gym is folded into the suffix; `__all__` when not gym-scoped.
String _diskKey(String timeRange, String? gymProfileId) =>
    '${DataCacheService.statsKeyPrefix}overload_dashboard_'
    '${timeRange}_${gymProfileId ?? '__all__'}';

// ============================================================================
// State
// ============================================================================

class OverloadDashboardState {
  final OverloadDashboard? dashboard;

  /// The time range this [dashboard] was fetched for (so a watcher can tell a
  /// stale slice from the freshly-requested one during a range switch).
  final ExerciseHistoryTimeRange timeRange;

  final bool isLoading;
  final String? error;

  const OverloadDashboardState({
    this.dashboard,
    this.timeRange = ExerciseHistoryTimeRange.twelveWeeks,
    this.isLoading = false,
    this.error,
  });

  OverloadDashboardState copyWith({
    OverloadDashboard? dashboard,
    ExerciseHistoryTimeRange? timeRange,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return OverloadDashboardState(
      dashboard: dashboard ?? this.dashboard,
      timeRange: timeRange ?? this.timeRange,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ============================================================================
// Notifier
// ============================================================================

class OverloadDashboardNotifier extends StateNotifier<OverloadDashboardState> {
  final ApiClient _client;
  String? _currentUserId;

  OverloadDashboardNotifier(this._client)
      : super(_inMemoryCache ?? const OverloadDashboardState());

  /// Clear the static in-memory cache (called on logout / user switch).
  static void clearCache() {
    _inMemoryCache = null;
    debugPrint('🧹 [OverloadDashboard] In-memory cache cleared');
  }

  // In-flight guard: a range switch + an initial load can race; share one
  // request per (uid, range, gym) so we never fire duplicate fetches.
  Future<void>? _inFlight;
  String? _inFlightSig;

  /// Cold-start disk seed for [range]/[gymProfileId]. Paints last-known data
  /// instantly (even expired) before any network call. No-op when memory
  /// already holds this exact slice.
  Future<void> seedFromDisk(
    ExerciseHistoryTimeRange range, {
    String? gymProfileId,
    String? userId,
  }) async {
    final uid = userId ??
        Supabase.instance.client.auth.currentUser?.id ??
        _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    // Already have THIS slice in memory — nothing to seed.
    if (state.dashboard != null && state.timeRange == range) return;

    try {
      final cached = await DataCacheService.instance.getCached(
        _diskKey(range.value, gymProfileId),
        userId: uid,
        returnExpiredOnMiss: true,
      );
      if (cached != null && mounted) {
        state = state.copyWith(
          dashboard: OverloadDashboard.fromJson(cached),
          timeRange: range,
          clearError: true,
        );
        _inMemoryCache = state;
        debugPrint('⚡ [OverloadDashboard] Seeded from disk ($range)');
      }
    } catch (e) {
      debugPrint('⚠️ [OverloadDashboard] Disk seed failed: $e');
    }
  }

  /// Load the dashboard for [range]/[gymProfileId].
  ///
  /// Stale-while-revalidate: this assumes the caller already seeded from disk
  /// (so the user sees something instantly); here we hit the network and
  /// update. Concurrent callers for the same slice share one request. A failed
  /// fetch with NO prior data sets [OverloadDashboardState.error].
  Future<void> load(
    ExerciseHistoryTimeRange range, {
    String? gymProfileId,
    String? userId,
    bool force = false,
  }) {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      // Resolve the id lazily, then re-enter.
      return _client.getUserId().then((resolved) {
        if (resolved == null) {
          if (mounted) {
            state = state.copyWith(
              isLoading: false,
              error: 'Not signed in',
            );
          }
          return Future<void>.value();
        }
        _currentUserId = resolved;
        return load(range,
            gymProfileId: gymProfileId, userId: resolved, force: force);
      });
    }

    _currentUserId = uid;
    final sig = '$uid|${range.value}|${gymProfileId ?? '__all__'}';
    final inFlight = _inFlight;
    if (inFlight != null && _inFlightSig == sig && !force) {
      return inFlight;
    }

    _inFlightSig = sig;
    final future = _doLoad(range, gymProfileId, uid).whenComplete(() {
      if (_inFlightSig == sig) {
        _inFlight = null;
        _inFlightSig = null;
      }
    });
    _inFlight = future;
    return future;
  }

  Future<void> _doLoad(
    ExerciseHistoryTimeRange range,
    String? gymProfileId,
    String uid,
  ) async {
    // Only show the blocking-loading flag when we have nothing to paint for
    // this slice — otherwise the existing (stale) data stays on screen while
    // the refresh runs silently.
    final haveData = state.dashboard != null && state.timeRange == range;
    if (mounted) {
      state = state.copyWith(
        isLoading: !haveData,
        timeRange: range,
        clearError: true,
      );
    }

    try {
      final response = await _client.get(
        '/progress/overload-dashboard',
        queryParameters: {
          'user_id': uid,
          'time_range': range.value,
          if (gymProfileId != null) 'gym_profile_id': gymProfileId,
        },
      );
      final data = response.data;
      if (data is! Map) {
        throw const FormatException('Unexpected dashboard payload shape');
      }
      final dashboard =
          OverloadDashboard.fromJson(data.cast<String, dynamic>());

      if (!mounted) return;
      state = state.copyWith(
        dashboard: dashboard,
        timeRange: range,
        isLoading: false,
        clearError: true,
      );
      _inMemoryCache = state;

      // Write-through to disk for the next cold start.
      await DataCacheService.instance.cache(
        _diskKey(range.value, gymProfileId),
        dashboard.toJson(),
        userId: uid,
      );
      debugPrint('✅ [OverloadDashboard] Loaded ($range)');
    } catch (e) {
      debugPrint('❌ [OverloadDashboard] Load error: $e');
      if (!mounted) return;
      // NO FALLBACK: if we have no data for this slice, surface the error so
      // the screen shows a retry instead of a fabricated empty dashboard.
      state = state.copyWith(
        isLoading: false,
        error: state.dashboard == null
            ? 'Failed to load your overload dashboard. Please try again.'
            : null,
      );
    }
  }

  /// Fetch the enriched per-muscle drill-down. Returns null on error (the sheet
  /// degrades to a plain "couldn't load" message — it is not cached).
  Future<OverloadMuscleDetail?> loadMuscleDetail(
    String muscleGroup, {
    String? gymProfileId,
    String? userId,
  }) async {
    final uid = userId ?? _currentUserId ?? await _client.getUserId();
    if (uid == null) return null;
    try {
      final response = await _client.get(
        '/scores/strength/$muscleGroup',
        queryParameters: {
          'user_id': uid,
          if (gymProfileId != null) 'gym_profile_id': gymProfileId,
        },
      );
      final data = response.data;
      if (data is! Map) return null;
      return OverloadMuscleDetail.fromJson(
        muscleGroup,
        data.cast<String, dynamic>(),
      );
    } catch (e) {
      debugPrint('⚠️ [OverloadDashboard] Muscle detail fetch failed: $e');
      return null;
    }
  }
}

// ============================================================================
// Providers
// ============================================================================

/// The dashboard notifier. Flushes the static caches on a real account switch
/// so a new user never inherits the prior user's overload data.
final overloadDashboardProvider = StateNotifierProvider<
    OverloadDashboardNotifier, OverloadDashboardState>((ref) {
  final client = ref.watch(apiClientProvider);
  final userId = ref.watch(authStateProvider.select((s) => s.user?.id));
  if (userId != null && userId != _cacheOwnerUserId) {
    _cacheOwnerUserId = userId;
    _inMemoryCache = null;
  }
  return OverloadDashboardNotifier(client);
});

/// The selected time range for the overload dashboard (defaults to 12 weeks,
/// the backend default). Separate from the exercise-history range provider so
/// changing one screen's range doesn't move the other's.
final overloadTimeRangeProvider = StateProvider<ExerciseHistoryTimeRange>(
  (ref) => ExerciseHistoryTimeRange.twelveWeeks,
);
