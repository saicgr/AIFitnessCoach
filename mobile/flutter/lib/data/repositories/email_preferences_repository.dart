import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/email_preferences.dart';
import '../services/api_client.dart';

/// Email preferences repository provider
final emailPreferencesRepositoryProvider =
    Provider<EmailPreferencesRepository>((ref) {
  return EmailPreferencesRepository(ref.watch(apiClientProvider));
});

/// Repository for managing email subscription preferences.
///
/// Provides methods to get, update, and manage email preferences
/// including quick actions for unsubscribing from marketing emails.
class EmailPreferencesRepository {
  final ApiClient _client;

  EmailPreferencesRepository(this._client);

  // ============================================
  // GET EMAIL PREFERENCES
  // ============================================

  /// Get current email preferences for a user.
  ///
  /// If no preferences exist, the API will create defaults:
  /// - workout_reminders: true (essential)
  /// - weekly_summary: true
  /// - coach_tips: true
  /// - product_updates: true
  /// - promotional: false (opt-in)
  Future<EmailPreferences> getPreferences(String userId) async {
    try {
      debugPrint('📧 [EmailPrefsRepo] Getting preferences for $userId');
      final response = await _client.get('/email-preferences/$userId');

      if (response.data == null) {
        debugPrint('📧 [EmailPrefsRepo] No data returned, using defaults');
        return EmailPreferences.defaults(userId);
      }

      final prefs = EmailPreferences.fromJson(response.data);
      debugPrint('✅ [EmailPrefsRepo] Got preferences: ${prefs.enabledCount}/5 enabled');
      return prefs;
    } catch (e) {
      debugPrint('❌ [EmailPrefsRepo] Error getting preferences: $e');
      rethrow;
    }
  }

  // ============================================
  // UPDATE EMAIL PREFERENCES
  // ============================================

  /// Update email preferences.
  ///
  /// Only sends the fields that need to be updated.
  Future<EmailPreferences> updatePreferences({
    required String userId,
    bool? workoutReminders,
    bool? weeklySummary,
    bool? coachTips,
    bool? productUpdates,
    bool? promotional,
    bool? streakAlerts,
    bool? missedWorkoutAlerts,
    bool? achievementAlerts,
    DateTime? notificationsPausedUntil,
  }) async {
    try {
      debugPrint('📧 [EmailPrefsRepo] Updating preferences for $userId');

      // Build update payload with only non-null fields
      final updateData = <String, dynamic>{};
      if (workoutReminders != null) {
        updateData['workout_reminders'] = workoutReminders;
      }
      if (weeklySummary != null) {
        updateData['weekly_summary'] = weeklySummary;
      }
      if (coachTips != null) {
        updateData['coach_tips'] = coachTips;
      }
      if (productUpdates != null) {
        updateData['product_updates'] = productUpdates;
      }
      if (promotional != null) {
        updateData['promotional'] = promotional;
      }
      if (streakAlerts != null) {
        updateData['streak_alerts'] = streakAlerts;
      }
      if (missedWorkoutAlerts != null) {
        updateData['missed_workout_alerts'] = missedWorkoutAlerts;
      }
      if (achievementAlerts != null) {
        updateData['achievement_alerts'] = achievementAlerts;
      }
      if (notificationsPausedUntil != null) {
        updateData['notifications_paused_until'] =
            notificationsPausedUntil.toIso8601String();
      }

      if (updateData.isEmpty) {
        debugPrint('📧 [EmailPrefsRepo] No changes to update');
        return await getPreferences(userId);
      }

      debugPrint('📧 [EmailPrefsRepo] Update payload: $updateData');

      final response = await _client.put(
        '/email-preferences/$userId',
        data: updateData,
      );

      final prefs = EmailPreferences.fromJson(response.data);
      debugPrint('✅ [EmailPrefsRepo] Preferences updated: ${prefs.enabledCount}/5 enabled');
      return prefs;
    } catch (e) {
      debugPrint('❌ [EmailPrefsRepo] Error updating preferences: $e');
      rethrow;
    }
  }

  /// Update a single email preference by type.
  Future<EmailPreferences> updateSinglePreference({
    required String userId,
    required EmailPreferenceType type,
    required bool enabled,
  }) async {
    switch (type) {
      case EmailPreferenceType.workoutReminders:
        return updatePreferences(userId: userId, workoutReminders: enabled);
      case EmailPreferenceType.weeklySummary:
        return updatePreferences(userId: userId, weeklySummary: enabled);
      case EmailPreferenceType.coachTips:
        return updatePreferences(userId: userId, coachTips: enabled);
      case EmailPreferenceType.productUpdates:
        return updatePreferences(userId: userId, productUpdates: enabled);
      case EmailPreferenceType.promotional:
        return updatePreferences(userId: userId, promotional: enabled);
      case EmailPreferenceType.streakAlerts:
        return updatePreferences(userId: userId, streakAlerts: enabled);
      case EmailPreferenceType.missedWorkoutAlerts:
        return updatePreferences(userId: userId, missedWorkoutAlerts: enabled);
      case EmailPreferenceType.achievementAlerts:
        return updatePreferences(userId: userId, achievementAlerts: enabled);
    }
  }

  // ============================================
  // QUICK ACTIONS
  // ============================================

  /// Unsubscribe from all marketing/non-essential emails.
  ///
  /// This keeps workout_reminders enabled but disables:
  /// - weekly_summary
  /// - coach_tips
  /// - product_updates
  /// - promotional
  Future<UnsubscribeMarketingResponse> unsubscribeFromMarketing(
      String userId) async {
    try {
      debugPrint('📧 [EmailPrefsRepo] Unsubscribing $userId from marketing');

      final response = await _client.post(
        '/email-preferences/$userId/unsubscribe-marketing',
      );

      final result = UnsubscribeMarketingResponse.fromJson(response.data);
      debugPrint('✅ [EmailPrefsRepo] Unsubscribed from marketing: ${result.message}');
      return result;
    } catch (e) {
      debugPrint('❌ [EmailPrefsRepo] Error unsubscribing from marketing: $e');
      rethrow;
    }
  }

  /// Subscribe to all email types.
  Future<EmailPreferences> subscribeToAll(String userId) async {
    try {
      debugPrint('📧 [EmailPrefsRepo] Subscribing $userId to all emails');

      final response = await _client.post(
        '/email-preferences/$userId/subscribe-all',
      );

      final prefs = EmailPreferences.fromJson(response.data);
      debugPrint('✅ [EmailPrefsRepo] Subscribed to all: ${prefs.enabledCount}/5 enabled');
      return prefs;
    } catch (e) {
      debugPrint('❌ [EmailPrefsRepo] Error subscribing to all: $e');
      rethrow;
    }
  }
}

/// Email preference types for individual toggle updates.
///
/// The string values mirror the backend column names and are used in user-
/// facing copy for per-category unsubscribe links.
enum EmailPreferenceType {
  workoutReminders,
  weeklySummary,
  coachTips,
  productUpdates,
  promotional,
  streakAlerts,
  missedWorkoutAlerts,
  achievementAlerts,
}
