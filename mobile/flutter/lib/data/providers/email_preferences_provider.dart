import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/email_preferences.dart';
import '../repositories/email_preferences_repository.dart';

// ============================================
// EMAIL PREFERENCES STATE
// ============================================

/// Complete email preferences state
class EmailPreferencesState {
  final EmailPreferences? preferences;
  final bool isLoading;
  final String? error;

  const EmailPreferencesState({
    this.preferences,
    this.isLoading = false,
    this.error,
  });

  EmailPreferencesState copyWith({
    EmailPreferences? preferences,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return EmailPreferencesState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Check if all marketing emails are disabled
  bool get isAllMarketingDisabled =>
      preferences?.isAllMarketingDisabled ?? false;

  /// Check if all email types are enabled
  bool get isAllEnabled => preferences?.isAllEnabled ?? false;
}

// ============================================
// EMAIL PREFERENCES NOTIFIER
// ============================================

/// Email preferences state notifier
class EmailPreferencesNotifier extends StateNotifier<EmailPreferencesState> {
  final EmailPreferencesRepository _repository;

  EmailPreferencesNotifier(this._repository)
      : super(const EmailPreferencesState());

  /// Initialize email preferences for a user
  Future<void> initialize(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('📧 [EmailPrefsProvider] Initializing for $userId');
      final preferences = await _repository.getPreferences(userId);
      state = state.copyWith(
        preferences: preferences,
        isLoading: false,
      );
      debugPrint(
          '✅ [EmailPrefsProvider] Initialized: ${preferences.enabledCount}/5 enabled');
    } catch (e) {
      debugPrint('❌ [EmailPrefsProvider] Init error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Update a single preference toggle
  Future<void> updatePreference({
    required String userId,
    required EmailPreferenceType type,
    required bool enabled,
  }) async {
    // Optimistically update the UI
    final previousPrefs = state.preferences;
    if (previousPrefs != null) {
      EmailPreferences optimisticUpdate;
      switch (type) {
        case EmailPreferenceType.workoutReminders:
          optimisticUpdate =
              previousPrefs.copyWith(workoutReminders: enabled);
          break;
        case EmailPreferenceType.weeklySummary:
          optimisticUpdate = previousPrefs.copyWith(weeklySummary: enabled);
          break;
        case EmailPreferenceType.coachTips:
          optimisticUpdate = previousPrefs.copyWith(coachTips: enabled);
          break;
        case EmailPreferenceType.productUpdates:
          optimisticUpdate = previousPrefs.copyWith(productUpdates: enabled);
          break;
        case EmailPreferenceType.promotional:
          optimisticUpdate = previousPrefs.copyWith(promotional: enabled);
          break;
      }
      state = state.copyWith(preferences: optimisticUpdate, clearError: true);
    }

    try {
      debugPrint('📧 [EmailPrefsProvider] Updating ${type.name} to $enabled');
      final preferences = await _repository.updateSinglePreference(
        userId: userId,
        type: type,
        enabled: enabled,
      );
      state = state.copyWith(preferences: preferences);
      debugPrint('✅ [EmailPrefsProvider] ${type.name} updated');
    } catch (e) {
      debugPrint('❌ [EmailPrefsProvider] Update error: $e');
      // Revert on error
      if (previousPrefs != null) {
        state = state.copyWith(preferences: previousPrefs, error: e.toString());
      } else {
        state = state.copyWith(error: e.toString());
      }
    }
  }

  /// Update all preferences at once
  Future<void> updateAllPreferences({
    required String userId,
    bool? workoutReminders,
    bool? weeklySummary,
    bool? coachTips,
    bool? productUpdates,
    bool? promotional,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('📧 [EmailPrefsProvider] Updating all preferences');
      final preferences = await _repository.updatePreferences(
        userId: userId,
        workoutReminders: workoutReminders,
        weeklySummary: weeklySummary,
        coachTips: coachTips,
        productUpdates: productUpdates,
        promotional: promotional,
      );
      state = state.copyWith(
        preferences: preferences,
        isLoading: false,
      );
      debugPrint(
          '✅ [EmailPrefsProvider] All preferences updated: ${preferences.enabledCount}/5 enabled');
    } catch (e) {
      debugPrint('❌ [EmailPrefsProvider] Update all error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Unsubscribe from all marketing emails
  Future<bool> unsubscribeFromMarketing(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('📧 [EmailPrefsProvider] Unsubscribing from marketing');
      final result = await _repository.unsubscribeFromMarketing(userId);
      state = state.copyWith(
        preferences: result.preferences,
        isLoading: false,
      );
      debugPrint('✅ [EmailPrefsProvider] Unsubscribed from marketing');
      return result.success;
    } catch (e) {
      debugPrint('❌ [EmailPrefsProvider] Unsubscribe error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Subscribe to all email types
  Future<bool> subscribeToAll(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('📧 [EmailPrefsProvider] Subscribing to all');
      final preferences = await _repository.subscribeToAll(userId);
      state = state.copyWith(
        preferences: preferences,
        isLoading: false,
      );
      debugPrint('✅ [EmailPrefsProvider] Subscribed to all');
      return true;
    } catch (e) {
      debugPrint('❌ [EmailPrefsProvider] Subscribe all error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ============================================
// PROVIDERS
// ============================================

/// Email preferences state provider
final emailPreferencesProvider =
    StateNotifierProvider<EmailPreferencesNotifier, EmailPreferencesState>(
        (ref) {
  return EmailPreferencesNotifier(
    ref.watch(emailPreferencesRepositoryProvider),
  );
});

/// Convenience provider for just the preferences object
final currentEmailPreferencesProvider = Provider<EmailPreferences?>((ref) {
  return ref.watch(emailPreferencesProvider).preferences;
});

/// Convenience provider to check if loading
final emailPreferencesLoadingProvider = Provider<bool>((ref) {
  return ref.watch(emailPreferencesProvider).isLoading;
});

/// Convenience provider for error state
final emailPreferencesErrorProvider = Provider<String?>((ref) {
  return ref.watch(emailPreferencesProvider).error;
});

/// Provider to check if all marketing is disabled
final isAllMarketingDisabledProvider = Provider<bool>((ref) {
  return ref.watch(emailPreferencesProvider).isAllMarketingDisabled;
});
