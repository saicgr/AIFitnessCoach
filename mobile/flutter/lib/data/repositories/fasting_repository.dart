import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fasting.dart';
import '../services/api_client.dart';

part 'fasting_repository_part_weight_log_with_fasting.dart';


/// Fasting repository provider
final fastingRepositoryProvider = Provider<FastingRepository>((ref) {
  return FastingRepository(ref.watch(apiClientProvider));
});

/// Fasting repository for all fasting-related API calls
class FastingRepository {
  final ApiClient _client;

  FastingRepository(this._client);

  // ============================================
  // Fasting Records (Active fasts)
  // ============================================

  /// Start a new fast
  Future<FastingRecord> startFast({
    required String userId,
    required FastingProtocol protocol,
    int? customDurationMinutes,
    DateTime? startTime,
  }) async {
    try {
      debugPrint('🕐 [Fasting] Starting fast for $userId with protocol ${protocol.id}${startTime != null ? ' at $startTime' : ''}');
      final response = await _client.post(
        '/fasting/start',
        data: {
          'user_id': userId,
          'protocol': protocol.id,
          'protocol_type': protocol.type.name,
          'goal_duration_minutes': customDurationMinutes ?? protocol.fastingHours * 60,
          if (startTime != null) 'started_at': startTime.toUtc().toIso8601String(),
        },
      );
      debugPrint('✅ [Fasting] Fast started successfully');
      return FastingRecord.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Fasting] Error starting fast: $e');
      rethrow;
    }
  }

  /// End an active fast
  Future<FastEndResult> endFast({
    required String fastId,
    required String userId,
    String? notes,
    String? moodAfter,
    int? energyLevel,
  }) async {
    try {
      debugPrint('🕐 [Fasting] Ending fast $fastId');
      final response = await _client.post(
        '/fasting/$fastId/end',
        data: {
          'user_id': userId,
          if (notes != null) 'notes': notes,
          if (moodAfter != null) 'mood_after': moodAfter,
          if (energyLevel != null) 'energy_level': energyLevel,
        },
      );
      debugPrint('✅ [Fasting] Fast ended successfully');
      return FastEndResult.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Fasting] Error ending fast: $e');
      rethrow;
    }
  }

  /// Get the current active fast (if any)
  Future<FastingRecord?> getActiveFast(String userId) async {
    try {
      debugPrint('🔍 [Fasting] Checking for active fast for $userId');
      final response = await _client.get(
        '/fasting/active/$userId',
      );
      if (response.data == null || (response.data is Map && response.data.isEmpty)) {
        debugPrint('ℹ️ [Fasting] No active fast found');
        return null;
      }
      debugPrint('✅ [Fasting] Found active fast');
      return FastingRecord.fromJson(response.data);
    } catch (e) {
      // 404 means no active fast, which is okay
      if (e.toString().contains('404')) {
        debugPrint('ℹ️ [Fasting] No active fast found (404)');
        return null;
      }
      debugPrint('❌ [Fasting] Error getting active fast: $e');
      rethrow;
    }
  }

  /// Get fasting history
  Future<List<FastingRecord>> getFastingHistory({
    required String userId,
    int limit = 50,
    int offset = 0,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      debugPrint('🔍 [Fasting] Getting fasting history for $userId');
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (fromDate != null) queryParams['from_date'] = fromDate;
      if (toDate != null) queryParams['to_date'] = toDate;

      final response = await _client.get(
        '/fasting/history/$userId',
        queryParameters: queryParams,
      );
      final data = response.data as List;
      debugPrint('✅ [Fasting] Retrieved ${data.length} fasting records');
      return data.map((json) => FastingRecord.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [Fasting] Error getting fasting history: $e');
      rethrow;
    }
  }

  /// Cancel an active fast (no credit given)
  Future<void> cancelFast({
    required String fastId,
    required String userId,
  }) async {
    try {
      debugPrint('🚫 [Fasting] Cancelling fast $fastId');
      await _client.post(
        '/fasting/$fastId/cancel',
        data: {'user_id': userId},
      );
      debugPrint('✅ [Fasting] Fast cancelled');
    } catch (e) {
      debugPrint('❌ [Fasting] Error cancelling fast: $e');
      rethrow;
    }
  }

  /// Update notes or mood for a completed fast
  Future<FastingRecord> updateFastRecord({
    required String fastId,
    required String userId,
    String? notes,
    String? moodBefore,
    String? moodAfter,
    int? energyLevel,
  }) async {
    try {
      debugPrint('📝 [Fasting] Updating fast record $fastId');
      final response = await _client.put(
        '/fasting/$fastId',
        data: {
          'user_id': userId,
          if (notes != null) 'notes': notes,
          if (moodBefore != null) 'mood_before': moodBefore,
          if (moodAfter != null) 'mood_after': moodAfter,
          if (energyLevel != null) 'energy_level': energyLevel,
        },
      );
      debugPrint('✅ [Fasting] Fast record updated');
      return FastingRecord.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Fasting] Error updating fast record: $e');
      rethrow;
    }
  }

  // ============================================
  // Fasting Preferences
  // ============================================

  /// Get user's fasting preferences
  Future<FastingPreferences?> getPreferences(String userId) async {
    try {
      debugPrint('🔍 [Fasting] Getting preferences for $userId');
      final response = await _client.get('/fasting/preferences/$userId');
      if (response.data == null || (response.data is Map && response.data.isEmpty)) {
        return null;
      }
      return FastingPreferences.fromJson(response.data);
    } catch (e) {
      if (e.toString().contains('404')) {
        debugPrint('ℹ️ [Fasting] No preferences found (404)');
        return null;
      }
      debugPrint('❌ [Fasting] Error getting preferences: $e');
      rethrow;
    }
  }

  /// Save/update fasting preferences
  Future<FastingPreferences> savePreferences({
    required String userId,
    required FastingPreferences preferences,
  }) async {
    try {
      debugPrint('💾 [Fasting] Saving preferences for $userId');
      final response = await _client.put(
        '/fasting/preferences/$userId',
        data: preferences.toJson(),
      );
      debugPrint('✅ [Fasting] Preferences saved');
      return FastingPreferences.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Fasting] Error saving preferences: $e');
      rethrow;
    }
  }

  /// Complete fasting onboarding
  Future<void> completeOnboarding({
    required String userId,
    required FastingPreferences preferences,
    required List<String> safetyAcknowledgments,
  }) async {
    try {
      debugPrint('🎓 [Fasting] Completing onboarding for $userId');
      await _client.post(
        '/fasting/onboarding/complete',
        data: {
          'user_id': userId,
          'preferences': preferences.toJson(),
          'safety_acknowledgments': safetyAcknowledgments,
        },
      );
      debugPrint('✅ [Fasting] Onboarding completed');
    } catch (e) {
      debugPrint('❌ [Fasting] Error completing onboarding: $e');
      rethrow;
    }
  }

  // ============================================
  // Fasting Streaks & Stats
  // ============================================

  /// Get user's fasting streak
  Future<FastingStreak> getStreak(String userId) async {
    try {
      debugPrint('🔥 [Fasting] Getting streak for $userId');
      final response = await _client.get('/fasting/streak/$userId');
      return FastingStreak.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Fasting] Error getting streak: $e');
      rethrow;
    }
  }

  /// Get fasting statistics
  Future<FastingStats> getStats({
    required String userId,
    String? period, // 'week', 'month', 'year', 'all'
  }) async {
    try {
      debugPrint('📊 [Fasting] Getting stats for $userId (period: $period)');
      final queryParams = <String, dynamic>{};
      if (period != null) queryParams['period'] = period;

      final response = await _client.get(
        '/fasting/stats/$userId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return FastingStats.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Fasting] Error getting stats: $e');
      rethrow;
    }
  }

  // ============================================
  // Integration with Meal Logging
  // ============================================

  /// Check if logging a meal would break an active fast
  Future<bool> wouldBreakFast(String userId) async {
    final activeFast = await getActiveFast(userId);
    return activeFast != null;
  }

  /// End fast automatically when meal is logged
  Future<FastEndResult?> endFastForMealLogging({
    required String userId,
    required String mealType,
  }) async {
    try {
      final activeFast = await getActiveFast(userId);
      if (activeFast == null) return null;

      debugPrint('🍽️ [Fasting] Breaking fast due to meal logging');
      return await endFast(
        fastId: activeFast.id,
        userId: userId,
        notes: 'Fast ended by logging $mealType',
      );
    } catch (e) {
      debugPrint('❌ [Fasting] Error breaking fast for meal: $e');
      rethrow;
    }
  }

  // ============================================
  // Safety Screening
  // ============================================

  /// Check if user can use fasting features (safety screening)
  Future<SafetyScreeningResult> checkSafetyEligibility(String userId) async {
    try {
      debugPrint('🔒 [Fasting] Checking safety eligibility for $userId');
      final response = await _client.get('/fasting/safety-check/$userId');
      return SafetyScreeningResult.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Fasting] Error checking safety: $e');
      rethrow;
    }
  }

  /// Save safety screening response
  Future<void> saveSafetyScreening({
    required String userId,
    required Map<String, bool> responses,
  }) async {
    try {
      debugPrint('💾 [Fasting] Saving safety screening for $userId');
      await _client.post(
        '/fasting/safety-screening',
        data: {
          'user_id': userId,
          'responses': responses,
        },
      );
      debugPrint('✅ [Fasting] Safety screening saved');
    } catch (e) {
      debugPrint('❌ [Fasting] Error saving safety screening: $e');
      rethrow;
    }
  }

  // ============================================
  // Fasting Impact & Weight Correlation
  // ============================================

  /// Log weight with automatic fasting day detection
  ///
  /// The backend automatically correlates the weight entry with any
  /// fasting record on that date.
  Future<WeightLogWithFasting> logWeight({
    required String userId,
    required double weightKg,
    required String date,
    String? notes,
    String? fastingRecordId,
  }) async {
    try {
      debugPrint('⚖️ [Fasting] Logging weight $weightKg kg for $userId on $date');
      final response = await _client.post(
        '/fasting-impact/weight',
        data: {
          'user_id': userId,
          'weight_kg': weightKg,
          'date': date,
          if (notes != null) 'notes': notes,
          if (fastingRecordId != null) 'fasting_record_id': fastingRecordId,
        },
      );
      debugPrint('✅ [Fasting] Weight logged successfully');
      return WeightLogWithFasting.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Fasting] Error logging weight: $e');
      rethrow;
    }
  }

  /// Get weight logs with fasting correlation data
  ///
  /// Returns weight logs tagged with whether they were on fasting days,
  /// along with summary statistics comparing fasting vs non-fasting days.
  Future<WeightCorrelationResponse> getWeightCorrelation({
    required String userId,
    int days = 30,
    bool includeNonFasting = true,
  }) async {
    try {
      debugPrint('📊 [Fasting] Getting weight correlation for $userId (last $days days)');
      final response = await _client.get(
        '/fasting-impact/weight-correlation/$userId',
        queryParameters: {
          'days': days,
          'include_non_fasting': includeNonFasting,
        },
      );
      debugPrint('✅ [Fasting] Weight correlation retrieved');
      return WeightCorrelationResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Fasting] Error getting weight correlation: $e');
      rethrow;
    }
  }

  /// Get fasting impact analysis
  ///
  /// Compares performance on fasting vs non-fasting days:
  /// - Weight trends
  /// - Workout completion rates
  /// - Goal achievement rates
  /// - Calculates correlation score
  Future<FastingImpactAnalysis> getFastingImpactAnalysis({
    required String userId,
    String period = 'month', // 'week', 'month', '3months', 'all'
  }) async {
    try {
      debugPrint('🎯 [Fasting] Getting fasting impact analysis for $userId (period: $period)');
      final response = await _client.get(
        '/fasting-impact/analysis/$userId',
        queryParameters: {'period': period},
      );
      debugPrint('✅ [Fasting] Fasting impact analysis retrieved');
      return FastingImpactAnalysis.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Fasting] Error getting fasting impact analysis: $e');
      rethrow;
    }
  }

  /// Get AI-generated fasting insight
  ///
  /// Returns AI-generated insight about how fasting impacts the user's goals.
  /// Results are cached for 24 hours on the backend.
  Future<AIFastingInsight> getAIFastingInsight({
    required String userId,
    int days = 30,
  }) async {
    try {
      debugPrint('🤖 [Fasting] Getting AI fasting insight for $userId (last $days days)');
      final response = await _client.get(
        '/fasting-impact/ai-insight/$userId',
        queryParameters: {'days': days},
      );
      debugPrint('✅ [Fasting] AI fasting insight retrieved');
      return AIFastingInsight.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Fasting] Error getting AI fasting insight: $e');
      rethrow;
    }
  }

  /// Force refresh AI fasting insight (bypasses cache)
  ///
  /// Use this when user wants latest analysis after logging new data.
  Future<AIFastingInsight> refreshAIFastingInsight({
    required String userId,
    int days = 30,
  }) async {
    try {
      debugPrint('🔄 [Fasting] Refreshing AI fasting insight for $userId');
      final response = await _client.post(
        '/fasting-impact/ai-insight/refresh/$userId',
        queryParameters: {'days': days},
      );
      debugPrint('✅ [Fasting] AI fasting insight refreshed');
      return AIFastingInsight.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Fasting] Error refreshing AI fasting insight: $e');
      rethrow;
    }
  }

  /// Get fasting calendar data for a specific month
  ///
  /// Each day shows:
  /// - Fasting status (was it a fasting day?)
  /// - Weight if logged
  /// - Workout completed
  /// - Goals hit vs total
  Future<FastingCalendarResponse> getFastingCalendar({
    required String userId,
    required int month,
    required int year,
  }) async {
    try {
      debugPrint('📅 [Fasting] Getting fasting calendar for $userId ($month/$year)');
      final response = await _client.get(
        '/fasting-impact/calendar/$userId',
        queryParameters: {
          'month': month,
          'year': year,
        },
      );
      debugPrint('✅ [Fasting] Fasting calendar retrieved');
      return FastingCalendarResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Fasting] Error getting fasting calendar: $e');
      rethrow;
    }
  }

  // ============================================
  // Historical Fasting Day Marking
  // ============================================

  /// Mark a historical date as a fasting day
  ///
  /// Use this when a user forgot to track a fast but wants to
  /// retroactively mark a past day as a fasting day.
  ///
  /// Constraints:
  /// - Date must be in the past (not today or future)
  /// - Date cannot be more than 30 days in the past
  /// - Cannot mark a date that already has a fasting record
  Future<MarkFastingDayResult> markHistoricalFastingDay({
    required String userId,
    required DateTime date,
    String? protocol,
    double? estimatedHours,
    String? notes,
  }) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      debugPrint('📅 [Fasting] Marking historical fasting day: $dateStr for $userId');

      final response = await _client.post(
        '/fasting-impact/mark-fasting-day',
        data: {
          'user_id': userId,
          'date': dateStr,
          if (protocol != null) 'protocol': protocol,
          if (estimatedHours != null) 'estimated_hours': estimatedHours,
          if (notes != null) 'notes': notes,
        },
      );

      debugPrint('✅ [Fasting] Historical fasting day marked successfully');
      return MarkFastingDayResult.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Fasting] Error marking historical fasting day: $e');
      rethrow;
    }
  }

  // ============================================
  // Fasting Score
  // ============================================

  /// Calculate fasting score from current stats and streak
  ///
  /// This is calculated locally in Dart for instant display.
  /// Call [syncFastingScore] to save to Supabase for historical tracking.
  Future<FastingScore> calculateFastingScore(String userId) async {
    try {
      debugPrint('🎯 [Fasting] Calculating fasting score for $userId');

      // Fetch current stats and streak
      final stats = await getStats(userId: userId);
      final streak = await getStreak(userId);

      // Calculate average protocol difficulty based on average duration
      // 12h = 0.3, 16h = 0.5, 18h = 0.6, 20h = 0.75, 24h+ = 1.0
      final avgHours = stats.avgDurationMinutes / 60;
      double protocolDifficulty;
      if (avgHours >= 24) {
        protocolDifficulty = 1.0;
      } else if (avgHours >= 20) {
        protocolDifficulty = 0.75;
      } else if (avgHours >= 18) {
        protocolDifficulty = 0.6;
      } else if (avgHours >= 16) {
        protocolDifficulty = 0.5;
      } else if (avgHours >= 12) {
        protocolDifficulty = 0.3;
      } else {
        protocolDifficulty = 0.2;
      }

      final score = FastingScore.calculate(
        userId: userId,
        stats: stats,
        streak: streak,
        avgProtocolDifficulty: protocolDifficulty,
      );

      debugPrint('✅ [Fasting] Score calculated: ${score.score} (${score.tierLabel})');
      return score;
    } catch (e) {
      debugPrint('❌ [Fasting] Error calculating fasting score: $e');
      rethrow;
    }
  }

  /// Sync fasting score to Supabase for historical tracking
  ///
  /// Should be called after completing a fast or daily.
  /// Uses upsert to update today's score if already exists.
  Future<FastingScore> syncFastingScore({
    required String userId,
    required FastingScore score,
  }) async {
    try {
      debugPrint('💾 [Fasting] Syncing fasting score for $userId: ${score.score}');
      final response = await _client.post(
        '/fasting/score',
        data: score.toJson(),
      );
      debugPrint('✅ [Fasting] Score synced successfully');
      return FastingScore.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Fasting] Error syncing fasting score: $e');
      // Don't rethrow - score sync failure shouldn't break the app
      return score;
    }
  }

  /// Get fasting score trend (current vs last week)
  Future<FastingScoreTrend> getScoreTrend(String userId) async {
    try {
      debugPrint('📈 [Fasting] Getting score trend for $userId');
      final response = await _client.get('/fasting/score/trend/$userId');
      debugPrint('✅ [Fasting] Score trend retrieved');
      return FastingScoreTrend.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ [Fasting] Error getting score trend: $e');
      // Return default trend on error
      return const FastingScoreTrend(
        currentScore: 0,
        previousScore: 0,
        scoreChange: 0,
        trend: 'stable',
      );
    }
  }

  /// Get historical fasting scores
  Future<List<FastingScore>> getScoreHistory({
    required String userId,
    int days = 30,
  }) async {
    try {
      debugPrint('📊 [Fasting] Getting score history for $userId (last $days days)');
      final response = await _client.get(
        '/fasting/score/history/$userId',
        queryParameters: {'days': days},
      );
      final data = response.data as List;
      debugPrint('✅ [Fasting] Retrieved ${data.length} score records');
      return data.map((json) => FastingScore.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [Fasting] Error getting score history: $e');
      return [];
    }
  }
}
