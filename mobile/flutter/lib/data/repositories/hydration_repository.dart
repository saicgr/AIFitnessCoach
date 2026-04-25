import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hydration.dart';
import '../services/api_client.dart';
import '../../utils/tz.dart';
import '../services/health_service.dart';
import '../providers/xp_provider.dart';

/// In-memory cache for instant display on provider recreation
/// Survives provider invalidation and prevents loading flash
HydrationState? _hydrationInMemoryCache;

/// Hydration repository provider
final hydrationRepositoryProvider = Provider<HydrationRepository>((ref) {
  return HydrationRepository(ref.watch(apiClientProvider));
});

/// Hydration state
class HydrationState {
  final bool isLoading;
  final String? error;
  final DailyHydrationSummary? todaySummary;
  final List<HydrationLog> recentLogs;
  final int dailyGoalMl;

  const HydrationState({
    this.isLoading = false,
    this.error,
    this.todaySummary,
    this.recentLogs = const [],
    this.dailyGoalMl = 2500,
  });

  HydrationState copyWith({
    bool? isLoading,
    String? error,
    DailyHydrationSummary? todaySummary,
    List<HydrationLog>? recentLogs,
    int? dailyGoalMl,
  }) {
    return HydrationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      todaySummary: todaySummary ?? this.todaySummary,
      recentLogs: recentLogs ?? this.recentLogs,
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
    );
  }
}

/// Hydration state provider
final hydrationProvider =
    StateNotifierProvider<HydrationNotifier, HydrationState>((ref) {
  return HydrationNotifier(ref.watch(hydrationRepositoryProvider), ref);
});

/// Hydration state notifier
class HydrationNotifier extends StateNotifier<HydrationState> {
  final HydrationRepository _repository;
  final Ref _ref;

  /// Monotonic counter to discard stale responses from earlier loads.
  /// Incremented at the start of every [loadTodaySummary]; the response is
  /// only applied when the epoch still matches (i.e. no newer load started).
  int _loadEpoch = 0;

  HydrationNotifier(this._repository, this._ref)
      : super(_hydrationInMemoryCache ?? const HydrationState());

  /// Clear in-memory cache (called on logout)
  static void clearCache() {
    _hydrationInMemoryCache = null;
    debugPrint('🧹 [HydrationProvider] In-memory cache cleared');
  }

  /// Pre-seed state from bootstrap data so the home screen shows hydration instantly.
  void preSeedFromBootstrap({required int currentMl, required int targetMl}) {
    if (state.todaySummary != null) return; // Don't overwrite real data
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    state = state.copyWith(
      todaySummary: DailyHydrationSummary(
        date: todayStr,
        totalMl: currentMl,
        waterMl: currentMl,
        goalMl: targetMl,
        goalPercentage: targetMl > 0 ? (currentMl / targetMl * 100).clamp(0, 100) : 0,
      ),
      dailyGoalMl: targetMl,
    );
    debugPrint('⚡ [Hydration] Pre-seeded from bootstrap');
  }

  /// Load today's hydration summary
  /// Set [showLoading] to false for background refreshes (e.g., after adding water)
  Future<void> loadTodaySummary(String userId, {bool showLoading = true}) async {
    final epoch = ++_loadEpoch;
    if (showLoading) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      // Pass local date to avoid UTC mismatch on server (Render runs in UTC)
      final localDate = Tz.localDate();
      final summary = await _repository.getDailySummary(userId, date: localDate);
      // Only apply if no newer load was started while we were awaiting
      if (_loadEpoch != epoch) return;
      state = state.copyWith(
        isLoading: false,
        todaySummary: summary,
        dailyGoalMl: summary.goalMl,
      );
      // Update in-memory cache for instant access on provider recreation
      _hydrationInMemoryCache = state;

      _checkHydrationGoal(summary);
    } catch (e) {
      if (_loadEpoch != epoch) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Fire-once-per-day XP award when the user crosses their hydration goal.
  /// `markHydrationGoalHit` is idempotent — subsequent calls are no-ops.
  void _checkHydrationGoal(DailyHydrationSummary summary) {
    if (summary.goalMl > 0 && summary.totalMl >= summary.goalMl) {
      _ref.read(xpProvider.notifier).markHydrationGoalHit();
    }
  }

  /// Log hydration. `source` is the surface this came from
  /// (HydrationSource enum) — drives the per-row icon + badge in the
  /// Fuel/Water tab Today's Log. Defaults to manual when unspecified so the
  /// UI never renders an empty origin.
  Future<bool> logHydration({
    required String userId,
    required String drinkType,
    required int amountMl,
    String? workoutId,
    String? notes,
    HydrationSource source = HydrationSource.manual,
  }) async {
    try {
      // Invalidate any in-flight background load so it doesn't overwrite
      ++_loadEpoch;
      // Optimistic update - immediately update the total.
      // If todaySummary is null (first log, initial load not yet complete),
      // create a fresh summary so the UI updates instantly.
      final currentSummary = state.todaySummary ?? DailyHydrationSummary(
        date: Tz.localDate(),
        goalMl: state.dailyGoalMl,
      );
      final newTotal = currentSummary.totalMl + amountMl;
      final goalMl = currentSummary.goalMl > 0 ? currentSummary.goalMl : state.dailyGoalMl;
      state = state.copyWith(todaySummary: DailyHydrationSummary(
        date: currentSummary.date,
        totalMl: newTotal,
        waterMl: drinkType == 'water' ? currentSummary.waterMl + amountMl : currentSummary.waterMl,
        proteinShakeMl: drinkType == 'protein_shake' ? currentSummary.proteinShakeMl + amountMl : currentSummary.proteinShakeMl,
        sportsDrinkMl: drinkType == 'sports_drink' ? currentSummary.sportsDrinkMl + amountMl : currentSummary.sportsDrinkMl,
        otherMl: (drinkType != 'water' && drinkType != 'protein_shake' && drinkType != 'sports_drink')
            ? currentSummary.otherMl + amountMl : currentSummary.otherMl,
        goalMl: goalMl,
        goalPercentage: goalMl > 0 ? newTotal / goalMl : 0,
        entries: currentSummary.entries,
      ));

      await _repository.logHydration(
        userId: userId,
        drinkType: drinkType,
        amountMl: amountMl,
        workoutId: workoutId,
        notes: notes,
        localDate: Tz.localDate(),
        source: source,
      );

      // Fire-and-forget: sync hydration to Health Connect / HealthKit
      HealthService.syncHydrationToHealthIfEnabled(amountMl: amountMl);

      // Refresh summary in background (no loading indicator)
      await loadTodaySummary(userId, showLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      // Reload to revert optimistic update on error
      return false;
    }
  }

  /// Quick log hydration. `source` defaults to home — every quickLog caller
  /// today is the home-screen quick-add hero. Workout/chat/nutrition surfaces
  /// must pass an explicit source so the badge is correct.
  Future<bool> quickLog({
    required String userId,
    String drinkType = 'water',
    int amountMl = 250,
    HydrationSource source = HydrationSource.home,
  }) async {
    try {
      // Invalidate any in-flight background load so it doesn't overwrite
      ++_loadEpoch;
      // Optimistic update - immediately update the total.
      // If todaySummary is null (first log, initial load not yet complete),
      // create a fresh summary so the UI updates instantly.
      final currentSummary = state.todaySummary ?? DailyHydrationSummary(
        date: Tz.localDate(),
        goalMl: state.dailyGoalMl,
      );
      final newTotal = currentSummary.totalMl + amountMl;
      final goalMl = currentSummary.goalMl > 0 ? currentSummary.goalMl : state.dailyGoalMl;
      state = state.copyWith(todaySummary: DailyHydrationSummary(
        date: currentSummary.date,
        totalMl: newTotal,
        waterMl: drinkType == 'water' ? currentSummary.waterMl + amountMl : currentSummary.waterMl,
        proteinShakeMl: drinkType == 'protein_shake' ? currentSummary.proteinShakeMl + amountMl : currentSummary.proteinShakeMl,
        sportsDrinkMl: drinkType == 'sports_drink' ? currentSummary.sportsDrinkMl + amountMl : currentSummary.sportsDrinkMl,
        otherMl: (drinkType != 'water' && drinkType != 'protein_shake' && drinkType != 'sports_drink')
            ? currentSummary.otherMl + amountMl : currentSummary.otherMl,
        goalMl: goalMl,
        goalPercentage: goalMl > 0 ? newTotal / goalMl : 0,
        entries: currentSummary.entries,
      ));

      await _repository.quickLog(
        userId: userId,
        drinkType: drinkType,
        amountMl: amountMl,
        localDate: Tz.localDate(),
        source: source,
      );

      // Fire-and-forget: sync hydration to Health Connect / HealthKit
      HealthService.syncHydrationToHealthIfEnabled(amountMl: amountMl);

      // Refresh summary in background (no loading indicator)
      await loadTodaySummary(userId, showLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update daily goal
  Future<void> updateGoal(String userId, int goalMl) async {
    try {
      // Optimistic update
      state = state.copyWith(dailyGoalMl: goalMl);
      await _repository.updateGoal(userId, goalMl);
      // Refresh in background
      await loadTodaySummary(userId, showLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete a log entry
  Future<void> deleteLog(String userId, String logId) async {
    try {
      await _repository.deleteLog(logId);
      // Refresh in background (no loading indicator)
      await loadTodaySummary(userId, showLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Hydration repository
class HydrationRepository {
  final ApiClient _client;

  HydrationRepository(this._client);

  /// Get daily hydration summary
  Future<DailyHydrationSummary> getDailySummary(String userId, {String? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['date_str'] = date;
      }
      final response = await _client.get(
        '/hydration/daily/$userId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return DailyHydrationSummary.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting daily hydration: $e');
      rethrow;
    }
  }

  /// Log hydration
  Future<HydrationLog> logHydration({
    required String userId,
    required String drinkType,
    required int amountMl,
    String? workoutId,
    String? notes,
    String? localDate,
    HydrationSource source = HydrationSource.manual,
  }) async {
    try {
      final response = await _client.post(
        '/hydration/log',
        data: {
          'user_id': userId,
          'drink_type': drinkType,
          'amount_ml': amountMl,
          if (workoutId != null) 'workout_id': workoutId,
          if (notes != null) 'notes': notes,
          if (localDate != null) 'local_date': localDate,
          'source': source.value,
        },
      );
      return HydrationLog.fromJson(response.data);
    } catch (e) {
      debugPrint('Error logging hydration: $e');
      rethrow;
    }
  }

  /// Quick log hydration
  Future<HydrationLog> quickLog({
    required String userId,
    String drinkType = 'water',
    int amountMl = 250,
    String? workoutId,
    String? localDate,
    HydrationSource source = HydrationSource.home,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'drink_type': drinkType,
        'amount_ml': amountMl,
        'source': source.value,
      };
      if (workoutId != null) {
        queryParams['workout_id'] = workoutId;
      }
      if (localDate != null) {
        queryParams['local_date'] = localDate;
      }
      final response = await _client.post(
        '/hydration/quick-log/$userId',
        queryParameters: queryParams,
      );
      return HydrationLog.fromJson(response.data);
    } catch (e) {
      debugPrint('Error quick logging hydration: $e');
      rethrow;
    }
  }

  /// Get hydration logs
  Future<List<HydrationLog>> getLogs(String userId, {int days = 7}) async {
    try {
      final response = await _client.get(
        '/hydration/logs/$userId',
        queryParameters: {'days': days},
      );
      final data = response.data as List;
      return data.map((json) => HydrationLog.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting hydration logs: $e');
      rethrow;
    }
  }

  /// Delete a log
  Future<void> deleteLog(String logId) async {
    try {
      await _client.delete('/hydration/log/$logId');
    } catch (e) {
      debugPrint('Error deleting hydration log: $e');
      rethrow;
    }
  }

  /// Get user's hydration goal
  Future<int> getGoal(String userId) async {
    try {
      final response = await _client.get('/hydration/goal/$userId');
      return response.data['daily_goal_ml'] ?? 2500;
    } catch (e) {
      debugPrint('Error getting hydration goal: $e');
      return 2500;
    }
  }

  /// Update user's hydration goal
  Future<void> updateGoal(String userId, int goalMl) async {
    try {
      await _client.put(
        '/hydration/goal/$userId',
        data: {'daily_goal_ml': goalMl},
      );
    } catch (e) {
      debugPrint('Error updating hydration goal: $e');
      rethrow;
    }
  }
}
