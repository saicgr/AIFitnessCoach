import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cardio_session.dart';
import '../services/api_client.dart';

/// Cardio repository provider
final cardioRepositoryProvider = Provider<CardioRepository>((ref) {
  return CardioRepository(ref.watch(apiClientProvider));
});

/// Cardio repository for managing cardio sessions
class CardioRepository {
  final ApiClient _client;

  CardioRepository(this._client);

  /// Log a new cardio session
  Future<CardioSession> logSession({
    required String userId,
    required String cardioType,
    required String location,
    required int durationMinutes,
    double? distanceKm,
    double? avgPacePerKm,
    double? avgSpeedKmh,
    double? elevationGainM,
    int? avgHeartRate,
    int? maxHeartRate,
    int? caloriesBurned,
    String? notes,
    String? weatherConditions,
    String? workoutId,
  }) async {
    try {
      debugPrint('🏃 [CardioRepository] Logging session: $cardioType at $location');
      final response = await _client.post(
        '/cardio/log',
        data: {
          'user_id': userId,
          'cardio_type': cardioType,
          'location': location,
          'duration_minutes': durationMinutes,
          if (distanceKm != null) 'distance_km': distanceKm,
          if (avgPacePerKm != null) 'avg_pace_per_km': avgPacePerKm,
          if (avgSpeedKmh != null) 'avg_speed_kmh': avgSpeedKmh,
          if (elevationGainM != null) 'elevation_gain_m': elevationGainM,
          if (avgHeartRate != null) 'avg_heart_rate': avgHeartRate,
          if (maxHeartRate != null) 'max_heart_rate': maxHeartRate,
          if (caloriesBurned != null) 'calories_burned': caloriesBurned,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (weatherConditions != null) 'weather_conditions': weatherConditions,
          if (workoutId != null) 'workout_id': workoutId,
        },
      );
      debugPrint('✅ [CardioRepository] Session logged successfully');
      return CardioSession.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [CardioRepository] Error logging session: $e');
      rethrow;
    }
  }

  /// Get cardio sessions for a user
  Future<List<CardioSession>> getSessions({
    required String userId,
    int limit = 20,
    int offset = 0,
    String? cardioType,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('🔍 [CardioRepository] Getting sessions for $userId');
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (cardioType != null) queryParams['cardio_type'] = cardioType;
      if (location != null) queryParams['location'] = location;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final response = await _client.get(
        '/cardio/sessions/$userId',
        queryParameters: queryParams,
      );
      final data = response.data as List;
      debugPrint('✅ [CardioRepository] Got ${data.length} sessions');
      return data.map((json) => CardioSession.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [CardioRepository] Error getting sessions: $e');
      rethrow;
    }
  }

  /// Get a single cardio session by ID
  Future<CardioSession> getSession(String sessionId) async {
    try {
      final response = await _client.get('/cardio/session/$sessionId');
      return CardioSession.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [CardioRepository] Error getting session: $e');
      rethrow;
    }
  }

  /// Update a cardio session
  Future<CardioSession> updateSession({
    required String sessionId,
    String? cardioType,
    String? location,
    int? durationMinutes,
    double? distanceKm,
    double? avgPacePerKm,
    double? avgSpeedKmh,
    double? elevationGainM,
    int? avgHeartRate,
    int? maxHeartRate,
    int? caloriesBurned,
    String? notes,
    String? weatherConditions,
  }) async {
    try {
      debugPrint('📝 [CardioRepository] Updating session: $sessionId');
      final data = <String, dynamic>{};
      if (cardioType != null) data['cardio_type'] = cardioType;
      if (location != null) data['location'] = location;
      if (durationMinutes != null) data['duration_minutes'] = durationMinutes;
      if (distanceKm != null) data['distance_km'] = distanceKm;
      if (avgPacePerKm != null) data['avg_pace_per_km'] = avgPacePerKm;
      if (avgSpeedKmh != null) data['avg_speed_kmh'] = avgSpeedKmh;
      if (elevationGainM != null) data['elevation_gain_m'] = elevationGainM;
      if (avgHeartRate != null) data['avg_heart_rate'] = avgHeartRate;
      if (maxHeartRate != null) data['max_heart_rate'] = maxHeartRate;
      if (caloriesBurned != null) data['calories_burned'] = caloriesBurned;
      if (notes != null) data['notes'] = notes;
      if (weatherConditions != null) data['weather_conditions'] = weatherConditions;

      final response = await _client.put(
        '/cardio/session/$sessionId',
        data: data,
      );
      debugPrint('✅ [CardioRepository] Session updated');
      return CardioSession.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [CardioRepository] Error updating session: $e');
      rethrow;
    }
  }

  /// Delete a cardio session
  Future<void> deleteSession(String sessionId) async {
    try {
      debugPrint('🗑️ [CardioRepository] Deleting session: $sessionId');
      await _client.delete('/cardio/session/$sessionId');
      debugPrint('✅ [CardioRepository] Session deleted');
    } catch (e) {
      debugPrint('❌ [CardioRepository] Error deleting session: $e');
      rethrow;
    }
  }

  /// Get daily cardio summary
  Future<DailyCardioSummary> getDailySummary(String userId, {String? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) queryParams['date'] = date;

      final response = await _client.get(
        '/cardio/daily/$userId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return DailyCardioSummary.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [CardioRepository] Error getting daily summary: $e');
      rethrow;
    }
  }

  /// Get cardio statistics for a user
  Future<CardioStats> getStats({
    required String userId,
    String? cardioType,
    int days = 30,
  }) async {
    try {
      final queryParams = <String, dynamic>{'days': days};
      if (cardioType != null) queryParams['cardio_type'] = cardioType;

      final response = await _client.get(
        '/cardio/stats/$userId',
        queryParameters: queryParams,
      );
      return CardioStats.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [CardioRepository] Error getting stats: $e');
      rethrow;
    }
  }

  /// Get cardio history by date range
  Future<List<CardioSession>> getHistory({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _client.get(
        '/cardio/history/$userId',
        queryParameters: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );
      final data = response.data as List;
      return data.map((json) => CardioSession.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [CardioRepository] Error getting history: $e');
      rethrow;
    }
  }

  /// Get recent cardio sessions
  Future<List<CardioSession>> getRecentSessions(String userId, {int limit = 5}) async {
    try {
      final response = await _client.get(
        '/cardio/recent/$userId',
        queryParameters: {'limit': limit},
      );
      final data = response.data as List;
      return data.map((json) => CardioSession.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [CardioRepository] Error getting recent sessions: $e');
      rethrow;
    }
  }
}
