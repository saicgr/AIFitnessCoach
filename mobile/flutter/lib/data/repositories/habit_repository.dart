import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../services/api_client.dart';

/// Habit repository provider
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HabitRepository(apiClient);
});

/// Habit repository for API calls
class HabitRepository {
  final ApiClient _apiClient;

  HabitRepository(this._apiClient);

  // ============================================
  // HABIT CRUD
  // ============================================

  /// Get all habits for a user
  Future<List<Habit>> getHabits(String userId, {bool isActive = true}) async {
    try {
      debugPrint('🔍 [HabitRepo] Fetching habits for user: $userId');
      final response = await _apiClient.get(
        '/habits/$userId',
        queryParameters: {'is_active': isActive},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        final habits = data
            .map((json) => Habit.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [HabitRepo] Fetched ${habits.length} habits');
        return habits;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error fetching habits: $e');
      rethrow;
    }
  }

  /// Get today's habits with completion status
  Future<TodayHabitsResponse> getTodayHabits(String userId) async {
    try {
      debugPrint('🔍 [HabitRepo] Fetching today habits for user: $userId');
      final response = await _apiClient.get('/habits/$userId/today');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final todayResponse = TodayHabitsResponse.fromJson(data);
        debugPrint(
            '✅ [HabitRepo] Today: ${todayResponse.completedToday}/${todayResponse.totalHabits} completed');
        return todayResponse;
      }
      return TodayHabitsResponse(
        habits: [],
        totalHabits: 0,
        completedToday: 0,
        completionPercentage: 0.0,
      );
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error fetching today habits: $e');
      rethrow;
    }
  }

  /// Create a new habit
  Future<Habit> createHabit(String userId, HabitCreate habit) async {
    try {
      debugPrint('🎯 [HabitRepo] Creating habit: ${habit.name}');
      final response = await _apiClient.post(
        '/habits/$userId',
        data: habit.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final created = Habit.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [HabitRepo] Created habit: ${created.id}');
        return created;
      }
      throw Exception('Failed to create habit: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error creating habit: $e');
      rethrow;
    }
  }

  /// Update an existing habit
  Future<Habit> updateHabit(
      String userId, String habitId, HabitUpdate update) async {
    try {
      debugPrint('🔄 [HabitRepo] Updating habit: $habitId');
      final response = await _apiClient.put(
        '/habits/$userId/$habitId',
        data: update.toJson(),
      );

      if (response.statusCode == 200) {
        final updated = Habit.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [HabitRepo] Updated habit: ${updated.id}');
        return updated;
      }
      throw Exception('Failed to update habit: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error updating habit: $e');
      rethrow;
    }
  }

  /// Delete a habit
  Future<void> deleteHabit(String userId, String habitId,
      {bool hardDelete = false}) async {
    try {
      debugPrint('🗑️ [HabitRepo] Deleting habit: $habitId');
      await _apiClient.delete(
        '/habits/$userId/$habitId',
        queryParameters: {'hard_delete': hardDelete},
      );
      debugPrint('✅ [HabitRepo] Deleted habit: $habitId');
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error deleting habit: $e');
      rethrow;
    }
  }

  /// Archive a habit
  Future<void> archiveHabit(String userId, String habitId) async {
    try {
      debugPrint('📦 [HabitRepo] Archiving habit: $habitId');
      await _apiClient.post('/habits/$userId/$habitId/archive');
      debugPrint('✅ [HabitRepo] Archived habit: $habitId');
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error archiving habit: $e');
      rethrow;
    }
  }

  /// Get archived habits
  Future<List<HabitWithStatus>> getArchivedHabits(String userId) async {
    try {
      debugPrint('🔍 [HabitRepo] Fetching archived habits for user: $userId');
      final response = await _apiClient.get(
        '/habits/$userId',
        queryParameters: {'is_active': false},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        final habits = data
            .map((json) => HabitWithStatus.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [HabitRepo] Fetched ${habits.length} archived habits');
        return habits;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error fetching archived habits: $e');
      rethrow;
    }
  }

  // ============================================
  // HABIT LOGGING
  // ============================================

  /// Log habit completion
  Future<HabitLog> logHabit(String userId, HabitLogCreate log) async {
    try {
      debugPrint('📝 [HabitRepo] Logging habit: ${log.habitId}');
      final response = await _apiClient.post(
        '/habits/$userId/log',
        data: log.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final logEntry = HabitLog.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [HabitRepo] Logged habit: ${logEntry.id}');
        return logEntry;
      }
      throw Exception('Failed to log habit: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error logging habit: $e');
      rethrow;
    }
  }

  /// Toggle today's habit completion (convenience method)
  Future<HabitLog> toggleTodayHabit(
      String userId, String habitId, bool completed,
      {double? value}) async {
    final log = HabitLogCreate(
      habitId: habitId,
      logDate: DateTime.now(),
      completed: completed,
      value: value,
    );
    return logHabit(userId, log);
  }

  /// Update a habit log
  Future<HabitLog> updateHabitLog(
      String userId, String logId, HabitLogUpdate update) async {
    try {
      debugPrint('🔄 [HabitRepo] Updating habit log: $logId');
      final response = await _apiClient.put(
        '/habits/$userId/log/$logId',
        data: update.toJson(),
      );

      if (response.statusCode == 200) {
        final updated = HabitLog.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [HabitRepo] Updated log: ${updated.id}');
        return updated;
      }
      throw Exception('Failed to update log: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error updating log: $e');
      rethrow;
    }
  }

  /// Get habit logs for a date range
  Future<List<HabitLog>> getHabitLogs(
    String userId,
    String habitId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('🔍 [HabitRepo] Fetching logs for habit: $habitId');

      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      final response = await _apiClient.get(
        '/habits/$userId/$habitId/logs',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        final logs = data
            .map((json) => HabitLog.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [HabitRepo] Fetched ${logs.length} logs');
        return logs;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error fetching logs: $e');
      rethrow;
    }
  }

  /// Get habit history for N days
  Future<List<HabitLog>> getHabitHistory(
    String userId,
    String habitId, {
    int days = 30,
  }) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    return getHabitLogs(userId, habitId,
        startDate: startDate, endDate: endDate);
  }

  /// Batch log multiple habits
  Future<void> batchLogHabits(String userId, List<HabitLogCreate> logs) async {
    try {
      debugPrint('📝 [HabitRepo] Batch logging ${logs.length} habits');
      await _apiClient.post(
        '/habits/$userId/batch-log',
        data: {'logs': logs.map((l) => l.toJson()).toList()},
      );
      debugPrint('✅ [HabitRepo] Batch logged ${logs.length} habits');
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error batch logging: $e');
      rethrow;
    }
  }

  // ============================================
  // STREAKS
  // ============================================

  /// Get all habit streaks
  Future<List<HabitStreak>> getAllStreaks(String userId) async {
    try {
      debugPrint('🔥 [HabitRepo] Fetching streaks for user: $userId');
      final response = await _apiClient.get('/habits/$userId/streaks');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        final streaks = data
            .map((json) => HabitStreak.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [HabitRepo] Fetched ${streaks.length} streaks');
        return streaks;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error fetching streaks: $e');
      rethrow;
    }
  }

  /// Get streak for a specific habit
  Future<HabitStreak> getHabitStreak(String userId, String habitId) async {
    try {
      debugPrint('🔥 [HabitRepo] Fetching streak for habit: $habitId');
      final response =
          await _apiClient.get('/habits/$userId/$habitId/streak');

      if (response.statusCode == 200) {
        final streak =
            HabitStreak.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [HabitRepo] Streak: ${streak.currentStreak} days');
        return streak;
      }
      throw Exception('Failed to fetch streak: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error fetching streak: $e');
      rethrow;
    }
  }

  // ============================================
  // SUMMARIES & ANALYTICS
  // ============================================

  /// Get habits summary
  Future<HabitsSummary> getHabitsSummary(String userId) async {
    try {
      debugPrint('📊 [HabitRepo] Fetching summary for user: $userId');
      final response = await _apiClient.get('/habits/$userId/summary');

      if (response.statusCode == 200) {
        final summary =
            HabitsSummary.fromJson(response.data as Map<String, dynamic>);
        debugPrint(
            '✅ [HabitRepo] Summary: ${summary.completedToday}/${summary.totalActiveHabits}');
        return summary;
      }
      throw Exception('Failed to fetch summary: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error fetching summary: $e');
      rethrow;
    }
  }

  /// Get weekly summary
  Future<List<HabitWeeklySummary>> getWeeklySummary(String userId,
      {DateTime? weekStart}) async {
    try {
      debugPrint('📊 [HabitRepo] Fetching weekly summary for user: $userId');

      final queryParams = <String, dynamic>{};
      if (weekStart != null) {
        queryParams['week_start'] = weekStart.toIso8601String().split('T')[0];
      }

      final response = await _apiClient.get(
        '/habits/$userId/weekly-summary',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        final summaries = data
            .map((json) =>
                HabitWeeklySummary.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [HabitRepo] Weekly summary: ${summaries.length} habits');
        return summaries;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error fetching weekly summary: $e');
      rethrow;
    }
  }

  /// Get habit calendar data
  Future<Map<DateTime, List<HabitCalendarData>>> getHabitsCalendar(
    String userId,
    String habitId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      debugPrint('📅 [HabitRepo] Fetching calendar for habit: $habitId');
      final response = await _apiClient.get(
        '/habits/$userId/calendar',
        queryParameters: {
          'habit_id': habitId,
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate.toIso8601String().split('T')[0],
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> calendarData = data['data'] as List? ?? [];

        final result = <DateTime, List<HabitCalendarData>>{};
        for (final item in calendarData) {
          final calData =
              HabitCalendarData.fromJson(item as Map<String, dynamic>);
          final date =
              DateTime.parse(item['date'] as String? ?? DateTime.now().toIso8601String());
          result.putIfAbsent(date, () => []).add(calData);
        }

        debugPrint('✅ [HabitRepo] Calendar data: ${result.length} days');
        return result;
      }
      return {};
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error fetching calendar: $e');
      rethrow;
    }
  }

  // ============================================
  // TEMPLATES & SUGGESTIONS
  // ============================================

  /// Get habit templates
  Future<List<HabitTemplate>> getHabitTemplates({String? category}) async {
    try {
      debugPrint('📋 [HabitRepo] Fetching templates, category: $category');

      final queryParams = <String, dynamic>{};
      if (category != null) {
        queryParams['category'] = category;
      }

      final response = await _apiClient.get(
        '/habits/templates/all',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        final templates = data
            .map((json) =>
                HabitTemplate.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [HabitRepo] Fetched ${templates.length} templates');
        return templates;
      }
      // Fall back to local templates
      return HabitTemplate.defaults;
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error fetching templates: $e');
      // Fall back to local templates on error
      return HabitTemplate.defaults;
    }
  }

  /// Create habit from template
  Future<Habit> createHabitFromTemplate(
      String userId, String templateId) async {
    try {
      debugPrint('📋 [HabitRepo] Creating from template: $templateId');
      final response = await _apiClient.post(
        '/habits/$userId/from-template',
        queryParameters: {'template_id': templateId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final created = Habit.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [HabitRepo] Created from template: ${created.id}');
        return created;
      }
      throw Exception('Failed to create from template: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error creating from template: $e');
      rethrow;
    }
  }

  /// Get AI habit suggestions
  Future<HabitSuggestionResponse> getAISuggestions(
    String userId, {
    List<String>? goals,
    List<String>? currentHabits,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      debugPrint('🤖 [HabitRepo] Fetching AI suggestions for user: $userId');
      final response = await _apiClient.post(
        '/habits/$userId/suggestions',
        data: {
          'goals': goals,
          'current_habits': currentHabits,
          'preferences': preferences,
        },
      );

      if (response.statusCode == 200) {
        final suggestions = HabitSuggestionResponse.fromJson(
            response.data as Map<String, dynamic>);
        debugPrint(
            '✅ [HabitRepo] Got ${suggestions.suggestedHabits.length} suggestions');
        return suggestions;
      }
      throw Exception('Failed to get suggestions: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error getting suggestions: $e');
      rethrow;
    }
  }

  // ============================================
  // INSIGHTS
  // ============================================

  /// Get AI-generated habit insights
  Future<HabitInsights> getHabitInsights(String userId) async {
    try {
      debugPrint('🤖 [HabitRepo] Fetching insights for user: $userId');
      final response = await _apiClient.get('/habits/$userId/insights');

      if (response.statusCode == 200) {
        final insights =
            HabitInsights.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [HabitRepo] Got habit insights');
        return insights;
      }
      throw Exception('Failed to get insights: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error getting insights: $e');
      rethrow;
    }
  }

  // ============================================
  // REORDERING
  // ============================================

  /// Reorder habits
  Future<void> reorderHabits(String userId, Map<String, int> orderMap) async {
    try {
      debugPrint('🔄 [HabitRepo] Reordering ${orderMap.length} habits');
      await _apiClient.post(
        '/habits/$userId/reorder',
        data: {'order': orderMap},
      );
      debugPrint('✅ [HabitRepo] Reordered habits');
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error reordering habits: $e');
      rethrow;
    }
  }

  // ============================================
  // HABIT DETAILS
  // ============================================

  /// Get detailed habit info including stats
  Future<HabitDetail?> getHabitDetail(String userId, String habitId) async {
    try {
      debugPrint('🔍 [HabitRepo] Fetching detail for habit: $habitId');

      // Get the habit info from today's view
      final todayResponse = await getTodayHabits(userId);
      final habit = todayResponse.habits.where((h) => h.id == habitId).firstOrNull;

      if (habit == null) {
        return null;
      }

      // Get streak info
      final streak = await getHabitStreak(userId, habitId);

      // Get history
      final history = await getHabitHistory(userId, habitId, days: 30);

      return HabitDetail(
        habit: habit,
        streak: streak,
        recentLogs: history,
      );
    } catch (e) {
      debugPrint('❌ [HabitRepo] Error fetching habit detail: $e');
      return null;
    }
  }
}

/// Combined habit detail with streak and history
class HabitDetail {
  final HabitWithStatus habit;
  final HabitStreak streak;
  final List<HabitLog> recentLogs;

  HabitDetail({
    required this.habit,
    required this.streak,
    required this.recentLogs,
  });
}
