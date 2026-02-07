import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schedule_item.dart';
import '../services/api_client.dart';

/// Schedule repository provider
final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ScheduleRepository(apiClient);
});

/// Repository for daily schedule API calls
class ScheduleRepository {
  final ApiClient _apiClient;

  ScheduleRepository(this._apiClient);

  // ============================================
  // SCHEDULE ITEM CRUD
  // ============================================

  /// Get all schedule items for a user, optionally filtered by date
  Future<List<ScheduleItem>> getItems(String userId, {DateTime? date}) async {
    try {
      debugPrint('🔍 [ScheduleRepo] Fetching items for user: $userId');
      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['date'] = date.toIso8601String().split('T')[0];
      }

      final response = await _apiClient.get(
        '/daily-schedule/$userId/items',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        final items = data
            .map((json) => ScheduleItem.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [ScheduleRepo] Fetched ${items.length} items');
        return items;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [ScheduleRepo] Error fetching items: $e');
      rethrow;
    }
  }

  /// Get a single schedule item
  Future<ScheduleItem> getItem(String userId, String itemId) async {
    try {
      debugPrint('🔍 [ScheduleRepo] Fetching item: $itemId');
      final response = await _apiClient.get(
        '/daily-schedule/$userId/items/$itemId',
      );

      if (response.statusCode == 200) {
        final item =
            ScheduleItem.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [ScheduleRepo] Fetched item: ${item.title}');
        return item;
      }
      throw Exception('Failed to fetch item: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [ScheduleRepo] Error fetching item: $e');
      rethrow;
    }
  }

  /// Create a new schedule item
  Future<ScheduleItem> createItem(
      String userId, ScheduleItemCreate item) async {
    try {
      debugPrint('🎯 [ScheduleRepo] Creating item: ${item.title}');
      final response = await _apiClient.post(
        '/daily-schedule/$userId/items',
        data: item.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final created =
            ScheduleItem.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [ScheduleRepo] Created item: ${created.id}');
        return created;
      }
      throw Exception('Failed to create item: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [ScheduleRepo] Error creating item: $e');
      rethrow;
    }
  }

  /// Update an existing schedule item
  Future<ScheduleItem> updateItem(
      String userId, String itemId, Map<String, dynamic> updates) async {
    try {
      debugPrint('🔄 [ScheduleRepo] Updating item: $itemId');
      final response = await _apiClient.put(
        '/daily-schedule/$userId/items/$itemId',
        data: updates,
      );

      if (response.statusCode == 200) {
        final updated =
            ScheduleItem.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [ScheduleRepo] Updated item: ${updated.id}');
        return updated;
      }
      throw Exception('Failed to update item: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [ScheduleRepo] Error updating item: $e');
      rethrow;
    }
  }

  /// Delete a schedule item
  Future<bool> deleteItem(String userId, String itemId) async {
    try {
      debugPrint('🗑️ [ScheduleRepo] Deleting item: $itemId');
      final response = await _apiClient.delete(
        '/daily-schedule/$userId/items/$itemId',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('✅ [ScheduleRepo] Deleted item: $itemId');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ [ScheduleRepo] Error deleting item: $e');
      rethrow;
    }
  }

  // ============================================
  // DAILY SCHEDULE & UP NEXT
  // ============================================

  /// Get the full daily schedule for a specific date
  Future<DailyScheduleResponse> getDailySchedule(
      String userId, DateTime date) async {
    try {
      debugPrint(
          '📅 [ScheduleRepo] Fetching daily schedule for ${date.toIso8601String().split('T')[0]}');
      final response = await _apiClient.get(
        '/daily-schedule/$userId/daily',
        queryParameters: {
          'date': date.toIso8601String().split('T')[0],
        },
      );

      if (response.statusCode == 200) {
        final schedule = DailyScheduleResponse.fromJson(
            response.data as Map<String, dynamic>);
        debugPrint(
            '✅ [ScheduleRepo] Daily schedule: ${schedule.items.length} items');
        return schedule;
      }
      return DailyScheduleResponse(
        date: date,
        items: [],
        summary: {'total_items': 0, 'completed': 0, 'upcoming': 0},
      );
    } catch (e) {
      debugPrint('❌ [ScheduleRepo] Error fetching daily schedule: $e');
      rethrow;
    }
  }

  /// Get the next upcoming schedule items
  Future<UpNextResponse> getUpNext(String userId, {int limit = 3}) async {
    try {
      debugPrint('🔍 [ScheduleRepo] Fetching up-next items for user: $userId');
      final response = await _apiClient.get(
        '/daily-schedule/$userId/up-next',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final upNext =
            UpNextResponse.fromJson(response.data as Map<String, dynamic>);
        debugPrint(
            '✅ [ScheduleRepo] Up-next: ${upNext.items.length} items');
        return upNext;
      }
      return UpNextResponse(items: [], asOf: DateTime.now());
    } catch (e) {
      debugPrint('❌ [ScheduleRepo] Error fetching up-next: $e');
      rethrow;
    }
  }

  // ============================================
  // STATUS ACTIONS
  // ============================================

  /// Mark a schedule item as completed
  Future<ScheduleItem> completeItem(String userId, String itemId) async {
    try {
      debugPrint('✅ [ScheduleRepo] Completing item: $itemId');
      final response = await _apiClient.post(
        '/daily-schedule/$userId/items/$itemId/complete',
      );

      if (response.statusCode == 200) {
        final completed =
            ScheduleItem.fromJson(response.data as Map<String, dynamic>);
        debugPrint('✅ [ScheduleRepo] Completed item: ${completed.id}');
        return completed;
      }
      throw Exception('Failed to complete item: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [ScheduleRepo] Error completing item: $e');
      rethrow;
    }
  }

  // ============================================
  // AUTO-POPULATE
  // ============================================

  /// Auto-populate the schedule for a date from existing data
  Future<List<ScheduleItem>> autoPopulate(
    String userId,
    DateTime date, {
    bool? includeWorkouts,
    bool? includeHabits,
    bool? includeFasting,
  }) async {
    try {
      debugPrint(
          '🤖 [ScheduleRepo] Auto-populating schedule for ${date.toIso8601String().split('T')[0]}');
      final data = <String, dynamic>{
        'date': date.toIso8601String().split('T')[0],
      };
      if (includeWorkouts != null) data['include_workouts'] = includeWorkouts;
      if (includeHabits != null) data['include_habits'] = includeHabits;
      if (includeFasting != null) data['include_fasting'] = includeFasting;

      final response = await _apiClient.post(
        '/daily-schedule/$userId/auto-populate',
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> items = response.data as List;
        final scheduleItems = items
            .map((json) => ScheduleItem.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint(
            '✅ [ScheduleRepo] Auto-populated ${scheduleItems.length} items');
        return scheduleItems;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [ScheduleRepo] Error auto-populating: $e');
      rethrow;
    }
  }

  // ============================================
  // GOOGLE CALENDAR
  // ============================================

  /// Connect Google Calendar with an auth code
  Future<bool> connectGoogleCalendar(
    String userId,
    String authCode, {
    String? calendarId,
  }) async {
    try {
      debugPrint('🔗 [ScheduleRepo] Connecting Google Calendar');
      final data = <String, dynamic>{
        'auth_code': authCode,
      };
      if (calendarId != null) data['calendar_id'] = calendarId;

      final response = await _apiClient.post(
        '/daily-schedule/$userId/google-calendar/connect',
        data: data,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [ScheduleRepo] Google Calendar connected');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ [ScheduleRepo] Error connecting Google Calendar: $e');
      rethrow;
    }
  }

  /// Get busy times from Google Calendar for a date
  Future<List<Map<String, dynamic>>> getGoogleCalendarBusyTimes(
      String userId, DateTime date) async {
    try {
      debugPrint(
          '📅 [ScheduleRepo] Fetching Google Calendar busy times for ${date.toIso8601String().split('T')[0]}');
      final response = await _apiClient.get(
        '/daily-schedule/$userId/google-calendar/busy-times',
        queryParameters: {
          'date': date.toIso8601String().split('T')[0],
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        final busyTimes = data.cast<Map<String, dynamic>>();
        debugPrint(
            '✅ [ScheduleRepo] Got ${busyTimes.length} busy time slots');
        return busyTimes;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [ScheduleRepo] Error fetching busy times: $e');
      rethrow;
    }
  }

  /// Push a schedule item to Google Calendar
  Future<bool> pushToGoogleCalendar(String userId, String itemId) async {
    try {
      debugPrint('📤 [ScheduleRepo] Pushing item $itemId to Google Calendar');
      final response = await _apiClient.post(
        '/daily-schedule/$userId/items/$itemId/push-to-gcal',
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [ScheduleRepo] Pushed to Google Calendar');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ [ScheduleRepo] Error pushing to Google Calendar: $e');
      rethrow;
    }
  }
}
