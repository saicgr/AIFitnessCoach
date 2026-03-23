import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sauna_log.dart';
import '../services/api_client.dart';

/// Sauna repository provider
final saunaRepositoryProvider = Provider<SaunaRepository>((ref) {
  return SaunaRepository(ref.watch(apiClientProvider));
});

/// Simple sauna state for the daily summary provider
final dailySaunaProvider = FutureProvider.family<DailySaunaSummary?, String>((ref, userId) async {
  final repo = ref.watch(saunaRepositoryProvider);
  try {
    return await repo.getDailySummary(userId);
  } catch (e) {
    debugPrint('Error loading daily sauna: $e');
    return null;
  }
});

/// Sauna repository
class SaunaRepository {
  final ApiClient _client;

  SaunaRepository(this._client);

  /// Log a sauna session
  Future<SaunaLog> logSauna({
    required String userId,
    required int durationMinutes,
    String? workoutId,
    String? notes,
  }) async {
    try {
      final response = await _client.post(
        '/sauna/log',
        data: {
          'user_id': userId,
          'duration_minutes': durationMinutes,
          if (workoutId != null) 'workout_id': workoutId,
          if (notes != null) 'notes': notes,
          'local_date': DateTime.now().toIso8601String().substring(0, 10),
        },
      );
      return SaunaLog.fromJson(response.data);
    } catch (e) {
      debugPrint('Error logging sauna: $e');
      rethrow;
    }
  }

  /// Get daily sauna summary
  Future<DailySaunaSummary> getDailySummary(String userId, {String? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['date_str'] = date;
      }
      final response = await _client.get(
        '/sauna/daily/$userId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return DailySaunaSummary.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting daily sauna: $e');
      rethrow;
    }
  }

  /// Get sauna logs, optionally filtered by workout
  Future<List<SaunaLog>> getLogs(String userId, {String? workoutId, int days = 7}) async {
    try {
      final queryParams = <String, dynamic>{'days': days};
      if (workoutId != null) {
        queryParams['workout_id'] = workoutId;
      }
      final response = await _client.get(
        '/sauna/logs/$userId',
        queryParameters: queryParams,
      );
      final data = response.data as List;
      return data.map((json) => SaunaLog.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting sauna logs: $e');
      rethrow;
    }
  }

  /// Delete a sauna log
  Future<void> deleteLog(String logId) async {
    try {
      await _client.delete('/sauna/log/$logId');
    } catch (e) {
      debugPrint('Error deleting sauna log: $e');
      rethrow;
    }
  }
}
