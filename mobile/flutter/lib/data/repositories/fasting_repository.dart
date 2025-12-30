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
  }) async {
    try {
      debugPrint('🕐 [Fasting] Starting fast for $userId with protocol ${protocol.id}');
      final response = await _client.post(
        '/fasting/start',
        data: {
          'user_id': userId,
          'protocol': protocol.id,
          'protocol_type': protocol.type,
          'goal_duration_minutes': customDurationMinutes ?? protocol.fastingHours * 60,
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
