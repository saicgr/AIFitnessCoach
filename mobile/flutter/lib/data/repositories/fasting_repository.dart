import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fasting.dart';
import '../services/api_client.dart';

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
  /// Returns Gemini AI-generated insight about how fasting impacts the user's goals.
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

// ============================================
// Weight Log with Fasting Correlation Model
// ============================================

/// Weight log entry with fasting correlation data
class WeightLogWithFasting {
  final String id;
  final String userId;
  final double weightKg;
  final String date;
  final String? notes;
  final String? fastingRecordId;
  final bool isFastingDay;
  final String? fastingProtocol;
  final double? fastingCompletionPercent;
  final String createdAt;

  WeightLogWithFasting({
    required this.id,
    required this.userId,
    required this.weightKg,
    required this.date,
    this.notes,
    this.fastingRecordId,
    required this.isFastingDay,
    this.fastingProtocol,
    this.fastingCompletionPercent,
    required this.createdAt,
  });

  factory WeightLogWithFasting.fromJson(Map<String, dynamic> json) {
    return WeightLogWithFasting(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      weightKg: (json['weight_kg'] as num).toDouble(),
      date: json['date'] as String,
      notes: json['notes'] as String?,
      fastingRecordId: json['fasting_record_id'] as String?,
      isFastingDay: json['is_fasting_day'] as bool? ?? false,
      fastingProtocol: json['fasting_protocol'] as String?,
      fastingCompletionPercent: (json['fasting_completion_percent'] as num?)?.toDouble(),
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'weight_kg': weightKg,
        'date': date,
        'notes': notes,
        'fasting_record_id': fastingRecordId,
        'is_fasting_day': isFastingDay,
        'fasting_protocol': fastingProtocol,
        'fasting_completion_percent': fastingCompletionPercent,
        'created_at': createdAt,
      };
}

// ============================================
// Weight Correlation Response Model
// ============================================

/// Response containing weight logs with fasting correlation data
class WeightCorrelationResponse {
  final String userId;
  final int periodDays;
  final List<WeightLogWithFasting> weightLogs;
  final WeightCorrelationSummary summary;

  WeightCorrelationResponse({
    required this.userId,
    required this.periodDays,
    required this.weightLogs,
    required this.summary,
  });

  factory WeightCorrelationResponse.fromJson(Map<String, dynamic> json) {
    return WeightCorrelationResponse(
      userId: json['user_id'] as String,
      periodDays: json['period_days'] as int,
      weightLogs: (json['weight_logs'] as List<dynamic>)
          .map((e) => WeightLogWithFasting.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: WeightCorrelationSummary.fromJson(json['summary'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'period_days': periodDays,
        'weight_logs': weightLogs.map((e) => e.toJson()).toList(),
        'summary': summary.toJson(),
      };
}

/// Summary statistics for weight correlation
class WeightCorrelationSummary {
  final int totalLogs;
  final int fastingDayLogs;
  final int nonFastingDayLogs;
  final double? avgWeightFastingDays;
  final double? avgWeightNonFastingDays;
  final double? weightDifference;

  WeightCorrelationSummary({
    required this.totalLogs,
    required this.fastingDayLogs,
    required this.nonFastingDayLogs,
    this.avgWeightFastingDays,
    this.avgWeightNonFastingDays,
    this.weightDifference,
  });

  factory WeightCorrelationSummary.fromJson(Map<String, dynamic> json) {
    return WeightCorrelationSummary(
      totalLogs: json['total_logs'] as int? ?? 0,
      fastingDayLogs: json['fasting_day_logs'] as int? ?? 0,
      nonFastingDayLogs: json['non_fasting_day_logs'] as int? ?? 0,
      avgWeightFastingDays: (json['avg_weight_fasting_days'] as num?)?.toDouble(),
      avgWeightNonFastingDays: (json['avg_weight_non_fasting_days'] as num?)?.toDouble(),
      weightDifference: (json['weight_difference'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'total_logs': totalLogs,
        'fasting_day_logs': fastingDayLogs,
        'non_fasting_day_logs': nonFastingDayLogs,
        'avg_weight_fasting_days': avgWeightFastingDays,
        'avg_weight_non_fasting_days': avgWeightNonFastingDays,
        'weight_difference': weightDifference,
      };
}

// ============================================
// Fasting Impact Analysis Model
// ============================================

/// Fasting impact analysis response
class FastingImpactAnalysis {
  final String userId;
  final String period;
  final String analysisDate;

  // Weight metrics
  final double? avgWeightFastingDays;
  final double? avgWeightNonFastingDays;
  final String? weightTrendFasting;

  // Workout metrics
  final int workoutsOnFastingDays;
  final int workoutsOnNonFastingDays;
  final double? avgWorkoutCompletionFasting;
  final double? avgWorkoutCompletionNonFasting;

  // Goal metrics
  final int goalsHitOnFastingDays;
  final int goalsHitOnNonFastingDays;
  final double? goalCompletionRateFasting;
  final double? goalCompletionRateNonFasting;

  // Correlation
  final double? correlationScore;
  final String? correlationInterpretation;

  // Summary
  final String fastingImpactSummary;
  final List<String> recommendations;

  FastingImpactAnalysis({
    required this.userId,
    required this.period,
    required this.analysisDate,
    this.avgWeightFastingDays,
    this.avgWeightNonFastingDays,
    this.weightTrendFasting,
    this.workoutsOnFastingDays = 0,
    this.workoutsOnNonFastingDays = 0,
    this.avgWorkoutCompletionFasting,
    this.avgWorkoutCompletionNonFasting,
    this.goalsHitOnFastingDays = 0,
    this.goalsHitOnNonFastingDays = 0,
    this.goalCompletionRateFasting,
    this.goalCompletionRateNonFasting,
    this.correlationScore,
    this.correlationInterpretation,
    required this.fastingImpactSummary,
    required this.recommendations,
  });

  factory FastingImpactAnalysis.fromJson(Map<String, dynamic> json) {
    return FastingImpactAnalysis(
      userId: json['user_id'] as String,
      period: json['period'] as String,
      analysisDate: json['analysis_date'] as String,
      avgWeightFastingDays: (json['avg_weight_fasting_days'] as num?)?.toDouble(),
      avgWeightNonFastingDays: (json['avg_weight_non_fasting_days'] as num?)?.toDouble(),
      weightTrendFasting: json['weight_trend_fasting'] as String?,
      workoutsOnFastingDays: json['workouts_on_fasting_days'] as int? ?? 0,
      workoutsOnNonFastingDays: json['workouts_on_non_fasting_days'] as int? ?? 0,
      avgWorkoutCompletionFasting: (json['avg_workout_completion_fasting'] as num?)?.toDouble(),
      avgWorkoutCompletionNonFasting: (json['avg_workout_completion_non_fasting'] as num?)?.toDouble(),
      goalsHitOnFastingDays: json['goals_hit_on_fasting_days'] as int? ?? 0,
      goalsHitOnNonFastingDays: json['goals_hit_on_non_fasting_days'] as int? ?? 0,
      goalCompletionRateFasting: (json['goal_completion_rate_fasting'] as num?)?.toDouble(),
      goalCompletionRateNonFasting: (json['goal_completion_rate_non_fasting'] as num?)?.toDouble(),
      correlationScore: (json['correlation_score'] as num?)?.toDouble(),
      correlationInterpretation: json['correlation_interpretation'] as String?,
      fastingImpactSummary: json['fasting_impact_summary'] as String? ?? '',
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'period': period,
        'analysis_date': analysisDate,
        'avg_weight_fasting_days': avgWeightFastingDays,
        'avg_weight_non_fasting_days': avgWeightNonFastingDays,
        'weight_trend_fasting': weightTrendFasting,
        'workouts_on_fasting_days': workoutsOnFastingDays,
        'workouts_on_non_fasting_days': workoutsOnNonFastingDays,
        'avg_workout_completion_fasting': avgWorkoutCompletionFasting,
        'avg_workout_completion_non_fasting': avgWorkoutCompletionNonFasting,
        'goals_hit_on_fasting_days': goalsHitOnFastingDays,
        'goals_hit_on_non_fasting_days': goalsHitOnNonFastingDays,
        'goal_completion_rate_fasting': goalCompletionRateFasting,
        'goal_completion_rate_non_fasting': goalCompletionRateNonFasting,
        'correlation_score': correlationScore,
        'correlation_interpretation': correlationInterpretation,
        'fasting_impact_summary': fastingImpactSummary,
        'recommendations': recommendations,
      };

  /// Check if the weight trend is positive (decreasing)
  bool get isWeightTrendPositive => weightTrendFasting == 'decreasing';

  /// Check if correlation is positive
  bool get hasPositiveCorrelation => (correlationScore ?? 0) > 0.1;

  /// Get the difference in workout completion rate
  double? get workoutCompletionDifference {
    if (avgWorkoutCompletionFasting == null || avgWorkoutCompletionNonFasting == null) {
      return null;
    }
    return avgWorkoutCompletionFasting! - avgWorkoutCompletionNonFasting!;
  }

  /// Get the difference in goal completion rate
  double? get goalCompletionDifference {
    if (goalCompletionRateFasting == null || goalCompletionRateNonFasting == null) {
      return null;
    }
    return goalCompletionRateFasting! - goalCompletionRateNonFasting!;
  }
}

// ============================================
// AI Fasting Insight Model
// ============================================

/// AI-generated fasting insight from Gemini
class AIFastingInsight {
  final String id;
  final String userId;
  final String insightType; // 'positive', 'neutral', 'negative', 'needs_more_data'
  final String title;
  final String message;
  final String recommendation;
  final String? keyFinding;
  final Map<String, dynamic> dataSummary;
  final String createdAt;

  AIFastingInsight({
    required this.id,
    required this.userId,
    required this.insightType,
    required this.title,
    required this.message,
    required this.recommendation,
    this.keyFinding,
    required this.dataSummary,
    required this.createdAt,
  });

  factory AIFastingInsight.fromJson(Map<String, dynamic> json) {
    return AIFastingInsight(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      insightType: json['insight_type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      recommendation: json['recommendation'] as String,
      keyFinding: json['key_finding'] as String?,
      dataSummary: json['data_summary'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'insight_type': insightType,
        'title': title,
        'message': message,
        'recommendation': recommendation,
        'key_finding': keyFinding,
        'data_summary': dataSummary,
        'created_at': createdAt,
      };

  /// Check if insight is positive
  bool get isPositive => insightType == 'positive';

  /// Check if insight is negative
  bool get isNegative => insightType == 'negative';

  /// Check if more data is needed
  bool get needsMoreData => insightType == 'needs_more_data';

  /// Check if insight is neutral
  bool get isNeutral => insightType == 'neutral';
}

// ============================================
// Fasting Calendar Response Model
// ============================================

/// Calendar view response with fasting, weight, workout, and goal data
class FastingCalendarResponse {
  final String userId;
  final int month;
  final int year;
  final List<CalendarDayData> days;
  final CalendarSummary summary;

  FastingCalendarResponse({
    required this.userId,
    required this.month,
    required this.year,
    required this.days,
    required this.summary,
  });

  factory FastingCalendarResponse.fromJson(Map<String, dynamic> json) {
    return FastingCalendarResponse(
      userId: json['user_id'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      days: (json['days'] as List<dynamic>)
          .map((e) => CalendarDayData.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: CalendarSummary.fromJson(json['summary'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'month': month,
        'year': year,
        'days': days.map((e) => e.toJson()).toList(),
        'summary': summary.toJson(),
      };

  /// Get a specific day's data by date
  CalendarDayData? getDayData(DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      return days.firstWhere((d) => d.date == dateStr);
    } catch (_) {
      return null;
    }
  }

  /// Get all fasting days
  List<CalendarDayData> get fastingDays => days.where((d) => d.isFastingDay).toList();

  /// Get all days with workouts
  List<CalendarDayData> get workoutDays => days.where((d) => d.workoutCompleted).toList();
}

/// Data for a single calendar day
class CalendarDayData {
  final String date;
  final bool isFastingDay;
  final String? fastingProtocol;
  final double? fastingCompletionPercent;
  final String? fastingRecordId;
  final double? weightLogged;
  final bool workoutCompleted;
  final String? workoutId;
  final int goalsHit;
  final int goalsTotal;

  CalendarDayData({
    required this.date,
    required this.isFastingDay,
    this.fastingProtocol,
    this.fastingCompletionPercent,
    this.fastingRecordId,
    this.weightLogged,
    this.workoutCompleted = false,
    this.workoutId,
    this.goalsHit = 0,
    this.goalsTotal = 0,
  });

  factory CalendarDayData.fromJson(Map<String, dynamic> json) {
    return CalendarDayData(
      date: json['date'] as String,
      isFastingDay: json['is_fasting_day'] as bool? ?? false,
      fastingProtocol: json['fasting_protocol'] as String?,
      fastingCompletionPercent: (json['fasting_completion_percent'] as num?)?.toDouble(),
      fastingRecordId: json['fasting_record_id'] as String?,
      weightLogged: (json['weight_logged'] as num?)?.toDouble(),
      workoutCompleted: json['workout_completed'] as bool? ?? false,
      workoutId: json['workout_id'] as String?,
      goalsHit: json['goals_hit'] as int? ?? 0,
      goalsTotal: json['goals_total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'is_fasting_day': isFastingDay,
        'fasting_protocol': fastingProtocol,
        'fasting_completion_percent': fastingCompletionPercent,
        'fasting_record_id': fastingRecordId,
        'weight_logged': weightLogged,
        'workout_completed': workoutCompleted,
        'workout_id': workoutId,
        'goals_hit': goalsHit,
        'goals_total': goalsTotal,
      };

  /// Get goal completion percentage
  double get goalCompletionPercent => goalsTotal > 0 ? (goalsHit / goalsTotal) * 100 : 0;

  /// Check if all goals were hit
  bool get allGoalsHit => goalsTotal > 0 && goalsHit == goalsTotal;

  /// Parse the date string to DateTime
  DateTime get dateTime => DateTime.parse(date);
}

/// Summary statistics for the calendar month
class CalendarSummary {
  final int totalDays;
  final int fastingDays;
  final int workoutDays;
  final int totalGoalsHit;
  final int daysWithWeightLogged;
  final double fastingRate;

  CalendarSummary({
    required this.totalDays,
    required this.fastingDays,
    required this.workoutDays,
    required this.totalGoalsHit,
    required this.daysWithWeightLogged,
    required this.fastingRate,
  });

  factory CalendarSummary.fromJson(Map<String, dynamic> json) {
    return CalendarSummary(
      totalDays: json['total_days'] as int? ?? 0,
      fastingDays: json['fasting_days'] as int? ?? 0,
      workoutDays: json['workout_days'] as int? ?? 0,
      totalGoalsHit: json['total_goals_hit'] as int? ?? 0,
      daysWithWeightLogged: json['days_with_weight_logged'] as int? ?? 0,
      fastingRate: (json['fasting_rate'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_days': totalDays,
        'fasting_days': fastingDays,
        'workout_days': workoutDays,
        'total_goals_hit': totalGoalsHit,
        'days_with_weight_logged': daysWithWeightLogged,
        'fasting_rate': fastingRate,
      };

  /// Get workout rate percentage
  double get workoutRate => totalDays > 0 ? (workoutDays / totalDays) * 100 : 0;

  /// Get weight logging rate percentage
  double get weightLoggingRate => totalDays > 0 ? (daysWithWeightLogged / totalDays) * 100 : 0;
}

/// Result of safety screening check
class SafetyScreeningResult {
  final bool canUseFasting;
  final bool requiresWarning;
  final List<String> warnings;
  final List<String> blockedReasons;

  SafetyScreeningResult({
    required this.canUseFasting,
    this.requiresWarning = false,
    this.warnings = const [],
    this.blockedReasons = const [],
  });

  factory SafetyScreeningResult.fromJson(Map<String, dynamic> json) {
    return SafetyScreeningResult(
      canUseFasting: json['can_use_fasting'] as bool? ?? true,
      requiresWarning: json['requires_warning'] as bool? ?? false,
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      blockedReasons: (json['blocked_reasons'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'can_use_fasting': canUseFasting,
        'requires_warning': requiresWarning,
        'warnings': warnings,
        'blocked_reasons': blockedReasons,
      };
}

// ============================================
// Mark Historical Fasting Day Result Model
// ============================================

/// Result of marking a historical fasting day
class MarkFastingDayResult {
  final String id;
  final String userId;
  final String date;
  final String? protocol;
  final double? estimatedHours;
  final String status;
  final double completionPercentage;
  final String? notes;
  final String createdAt;
  final String message;

  MarkFastingDayResult({
    required this.id,
    required this.userId,
    required this.date,
    this.protocol,
    this.estimatedHours,
    required this.status,
    required this.completionPercentage,
    this.notes,
    required this.createdAt,
    required this.message,
  });

  factory MarkFastingDayResult.fromJson(Map<String, dynamic> json) {
    return MarkFastingDayResult(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: json['date'] as String,
      protocol: json['protocol'] as String?,
      estimatedHours: (json['estimated_hours'] as num?)?.toDouble(),
      status: json['status'] as String,
      completionPercentage: (json['completion_percentage'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'date': date,
        'protocol': protocol,
        'estimated_hours': estimatedHours,
        'status': status,
        'completion_percentage': completionPercentage,
        'notes': notes,
        'created_at': createdAt,
        'message': message,
      };

  /// Parse the date string to DateTime
  DateTime get dateTime => DateTime.parse(date);
}
