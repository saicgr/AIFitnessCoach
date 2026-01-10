import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hydration.dart';
import '../services/api_client.dart';

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
  return HydrationNotifier(ref.watch(hydrationRepositoryProvider));
});

/// Hydration state notifier
class HydrationNotifier extends StateNotifier<HydrationState> {
  final HydrationRepository _repository;

  HydrationNotifier(this._repository) : super(const HydrationState());

  /// Load today's hydration summary
  /// Set [showLoading] to false for background refreshes (e.g., after adding water)
  Future<void> loadTodaySummary(String userId, {bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final summary = await _repository.getDailySummary(userId);
      state = state.copyWith(
        isLoading: false,
        todaySummary: summary,
        dailyGoalMl: summary.goalMl,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Log hydration
  Future<bool> logHydration({
    required String userId,
    required String drinkType,
    required int amountMl,
    String? workoutId,
    String? notes,
  }) async {
    try {
      // Optimistic update - immediately update the total
      final currentSummary = state.todaySummary;
      if (currentSummary != null) {
        final newTotal = currentSummary.totalMl + amountMl;
        final updatedSummary = DailyHydrationSummary(
          date: currentSummary.date,
          totalMl: newTotal,
          waterMl: drinkType == 'water' ? currentSummary.waterMl + amountMl : currentSummary.waterMl,
          proteinShakeMl: drinkType == 'protein_shake' ? currentSummary.proteinShakeMl + amountMl : currentSummary.proteinShakeMl,
          sportsDrinkMl: drinkType == 'sports_drink' ? currentSummary.sportsDrinkMl + amountMl : currentSummary.sportsDrinkMl,
          otherMl: (drinkType != 'water' && drinkType != 'protein_shake' && drinkType != 'sports_drink')
              ? currentSummary.otherMl + amountMl : currentSummary.otherMl,
          goalMl: currentSummary.goalMl,
          goalPercentage: newTotal / currentSummary.goalMl,
          entries: currentSummary.entries,
        );
        state = state.copyWith(todaySummary: updatedSummary);
      }

      await _repository.logHydration(
        userId: userId,
        drinkType: drinkType,
        amountMl: amountMl,
        workoutId: workoutId,
        notes: notes,
      );
      // Refresh summary in background (no loading indicator)
      await loadTodaySummary(userId, showLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      // Reload to revert optimistic update on error
      return false;
    }
  }

  /// Quick log hydration
  Future<bool> quickLog({
    required String userId,
    String drinkType = 'water',
    int amountMl = 250,
  }) async {
    try {
      // Optimistic update - immediately update the total
      final currentSummary = state.todaySummary;
      if (currentSummary != null) {
        final newTotal = currentSummary.totalMl + amountMl;
        final updatedSummary = DailyHydrationSummary(
          date: currentSummary.date,
          totalMl: newTotal,
          waterMl: drinkType == 'water' ? currentSummary.waterMl + amountMl : currentSummary.waterMl,
          proteinShakeMl: drinkType == 'protein_shake' ? currentSummary.proteinShakeMl + amountMl : currentSummary.proteinShakeMl,
          sportsDrinkMl: drinkType == 'sports_drink' ? currentSummary.sportsDrinkMl + amountMl : currentSummary.sportsDrinkMl,
          otherMl: (drinkType != 'water' && drinkType != 'protein_shake' && drinkType != 'sports_drink')
              ? currentSummary.otherMl + amountMl : currentSummary.otherMl,
          goalMl: currentSummary.goalMl,
          goalPercentage: newTotal / currentSummary.goalMl,
          entries: currentSummary.entries,
        );
        state = state.copyWith(todaySummary: updatedSummary);
      }

      await _repository.quickLog(
        userId: userId,
        drinkType: drinkType,
        amountMl: amountMl,
      );
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
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'drink_type': drinkType,
        'amount_ml': amountMl,
      };
      if (workoutId != null) {
        queryParams['workout_id'] = workoutId;
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
