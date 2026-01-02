import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fasting.dart';
import '../repositories/fasting_repository.dart';

// ============================================
// Fasting State
// ============================================

/// Complete fasting state including active fast, preferences, streak, and stats
class FastingState {
  final FastingRecord? activeFast;
  final FastingPreferences? preferences;
  final FastingStreak? streak;
  final FastingStats? stats;
  final List<FastingRecord> history;
  final bool isLoading;
  final String? error;
  final bool onboardingCompleted;

  const FastingState({
    this.activeFast,
    this.preferences,
    this.streak,
    this.stats,
    this.history = const [],
    this.isLoading = false,
    this.error,
    this.onboardingCompleted = false,
  });

  FastingState copyWith({
    FastingRecord? activeFast,
    FastingPreferences? preferences,
    FastingStreak? streak,
    FastingStats? stats,
    List<FastingRecord>? history,
    bool? isLoading,
    String? error,
    bool? onboardingCompleted,
    bool clearActiveFast = false,
    bool clearError = false,
  }) {
    return FastingState(
      activeFast: clearActiveFast ? null : (activeFast ?? this.activeFast),
      preferences: preferences ?? this.preferences,
      streak: streak ?? this.streak,
      stats: stats ?? this.stats,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  /// Check if user has an active fast
  bool get hasFast => activeFast != null;

  /// Check if fasting feature is enabled for user
  bool get isEnabled => onboardingCompleted && preferences != null;

  /// Get current fasting zone (if fasting)
  FastingZone? get currentZone => activeFast?.currentZone;

  /// Get elapsed time formatted (if fasting)
  String get elapsedTimeFormatted {
    if (activeFast == null) return '--:--';
    final hours = activeFast!.elapsedMinutes ~/ 60;
    final mins = activeFast!.elapsedMinutes % 60;
    return '${hours}h ${mins}m';
  }

  /// Get remaining time formatted (if fasting)
  String get remainingTimeFormatted {
    if (activeFast == null) return '--:--';
    final remaining = activeFast!.goalDurationMinutes - activeFast!.elapsedMinutes;
    if (remaining <= 0) return 'Goal reached!';
    final hours = remaining ~/ 60;
    final mins = remaining % 60;
    return '${hours}h ${mins}m';
  }
}

// ============================================
// Fasting Notifier
// ============================================

/// Fasting state notifier for managing all fasting state
class FastingNotifier extends StateNotifier<FastingState> {
  final FastingRepository _repository;
  Timer? _refreshTimer;

  FastingNotifier(this._repository) : super(const FastingState());

  /// Initialize fasting state for a user
  Future<void> initialize(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🕐 [FastingProvider] Initializing for $userId');

      // Load all data in parallel
      final results = await Future.wait([
        _repository.getActiveFast(userId),
        _repository.getPreferences(userId),
        _repository.getStreak(userId).catchError((_) => const FastingStreak(
              userId: '',
              currentStreak: 0,
              longestStreak: 0,
              totalFastsCompleted: 0,
              totalFastingMinutes: 0,
            )),
        _repository.getStats(userId: userId).catchError((_) => const FastingStats(
              userId: '',
              totalFasts: 0,
              completedFasts: 0,
              avgDurationMinutes: 0,
              longestFastMinutes: 0,
              totalFastingMinutes: 0,
            )),
        _repository.getFastingHistory(userId: userId, limit: 10).catchError((_) => <FastingRecord>[]),
      ]);

      final activeFast = results[0] as FastingRecord?;
      final preferences = results[1] as FastingPreferences?;
      final streak = results[2] as FastingStreak;
      final stats = results[3] as FastingStats;
      final history = results[4] as List<FastingRecord>;

      state = state.copyWith(
        activeFast: activeFast,
        preferences: preferences,
        streak: streak,
        stats: stats,
        history: history,
        isLoading: false,
        onboardingCompleted: preferences?.fastingOnboardingCompleted ?? false,
      );

      // Start refresh timer if there's an active fast
      if (activeFast != null) {
        _startRefreshTimer();
      }

      debugPrint('✅ [FastingProvider] Initialized: hasFast=${activeFast != null}, onboarded=${preferences?.fastingOnboardingCompleted}');
    } catch (e) {
      debugPrint('❌ [FastingProvider] Init error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Start a new fast
  Future<void> startFast({
    required String userId,
    required FastingProtocol protocol,
    int? customDurationMinutes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🕐 [FastingProvider] Starting fast: ${protocol.displayName}');
      final fast = await _repository.startFast(
        userId: userId,
        protocol: protocol,
        customDurationMinutes: customDurationMinutes,
      );
      state = state.copyWith(activeFast: fast, isLoading: false);
      _startRefreshTimer();
      debugPrint('✅ [FastingProvider] Fast started');
    } catch (e) {
      debugPrint('❌ [FastingProvider] Start fast error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// End the current fast
  Future<FastEndResult?> endFast({
    required String userId,
    String? notes,
    String? moodAfter,
    int? energyLevel,
  }) async {
    if (state.activeFast == null) return null;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🕐 [FastingProvider] Ending fast');
      final result = await _repository.endFast(
        fastId: state.activeFast!.id,
        userId: userId,
        notes: notes,
        moodAfter: moodAfter,
        energyLevel: energyLevel,
      );

      // Stop refresh timer
      _stopRefreshTimer();

      // Refresh streak and stats
      final streak = await _repository.getStreak(userId);
      final stats = await _repository.getStats(userId: userId);
      final history = await _repository.getFastingHistory(userId: userId, limit: 10);

      state = state.copyWith(
        clearActiveFast: true,
        streak: streak,
        stats: stats,
        history: history,
        isLoading: false,
      );

      debugPrint('✅ [FastingProvider] Fast ended: ${result.record.completionPercentage?.toStringAsFixed(0) ?? 'N/A'}% complete');
      return result;
    } catch (e) {
      debugPrint('❌ [FastingProvider] End fast error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Cancel the current fast (no credit)
  Future<void> cancelFast(String userId) async {
    if (state.activeFast == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🚫 [FastingProvider] Cancelling fast');
      await _repository.cancelFast(
        fastId: state.activeFast!.id,
        userId: userId,
      );
      _stopRefreshTimer();
      state = state.copyWith(clearActiveFast: true, isLoading: false);
      debugPrint('✅ [FastingProvider] Fast cancelled');
    } catch (e) {
      debugPrint('❌ [FastingProvider] Cancel fast error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Save fasting preferences
  Future<void> savePreferences({
    required String userId,
    required FastingPreferences preferences,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('💾 [FastingProvider] Saving preferences');
      final saved = await _repository.savePreferences(
        userId: userId,
        preferences: preferences,
      );
      state = state.copyWith(preferences: saved, isLoading: false);
      debugPrint('✅ [FastingProvider] Preferences saved');
    } catch (e) {
      debugPrint('❌ [FastingProvider] Save preferences error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Complete fasting onboarding
  Future<void> completeOnboarding({
    required String userId,
    required FastingPreferences preferences,
    required List<String> safetyAcknowledgments,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🎓 [FastingProvider] Completing onboarding');
      await _repository.completeOnboarding(
        userId: userId,
        preferences: preferences,
        safetyAcknowledgments: safetyAcknowledgments,
      );
      state = state.copyWith(
        preferences: preferences.copyWith(fastingOnboardingCompleted: true),
        onboardingCompleted: true,
        isLoading: false,
      );
      debugPrint('✅ [FastingProvider] Onboarding completed');
    } catch (e) {
      debugPrint('❌ [FastingProvider] Onboarding error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh fasting history
  Future<void> refreshHistory(String userId) async {
    try {
      final history = await _repository.getFastingHistory(userId: userId, limit: 50);
      state = state.copyWith(history: history);
    } catch (e) {
      debugPrint('❌ [FastingProvider] Refresh history error: $e');
    }
  }

  /// Force refresh the active fast state (useful for timer updates)
  void refreshActiveFast() {
    if (state.activeFast == null) return;

    // Just trigger a state update to recalculate computed properties
    state = state.copyWith(
      activeFast: state.activeFast!.copyWith(
        // No actual changes, just triggers rebuild
      ),
    );
  }

  /// Start periodic refresh timer for active fast
  void _startRefreshTimer() {
    _stopRefreshTimer();
    // Refresh every minute to update elapsed time
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      refreshActiveFast();
    });
  }

  /// Stop refresh timer
  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _stopRefreshTimer();
    super.dispose();
  }
}

// ============================================
// Providers
// ============================================

/// Fasting state provider
final fastingProvider = StateNotifierProvider<FastingNotifier, FastingState>((ref) {
  return FastingNotifier(
    ref.watch(fastingRepositoryProvider),
  );
});

/// Active fast provider (convenience)
final activeFastProvider = Provider<FastingRecord?>((ref) {
  return ref.watch(fastingProvider).activeFast;
});

/// Is fasting provider (convenience)
final isFastingProvider = Provider<bool>((ref) {
  return ref.watch(fastingProvider).hasFast;
});

/// Current fasting zone provider (convenience)
final currentFastingZoneProvider = Provider<FastingZone?>((ref) {
  return ref.watch(fastingProvider).currentZone;
});

/// Fasting streak provider (convenience)
final fastingStreakProvider = Provider<FastingStreak?>((ref) {
  return ref.watch(fastingProvider).streak;
});

/// Fasting onboarding completed provider (convenience)
final fastingOnboardingCompletedProvider = Provider<bool>((ref) {
  return ref.watch(fastingProvider).onboardingCompleted;
});

// ============================================
// Timer Provider for UI Updates
// ============================================

/// Provides elapsed seconds for active fast (updates every second)
final fastingTimerProvider = StreamProvider.autoDispose<int>((ref) {
  final activeFast = ref.watch(activeFastProvider);
  if (activeFast == null) {
    return Stream.value(0);
  }

  return Stream.periodic(const Duration(seconds: 1), (count) {
    final elapsed = DateTime.now().difference(activeFast.startTime);
    return elapsed.inSeconds;
  });
});

/// Computed elapsed time in minutes
final fastingElapsedMinutesProvider = Provider<int>((ref) {
  final seconds = ref.watch(fastingTimerProvider).value ?? 0;
  return seconds ~/ 60;
});

/// Computed progress percentage (0.0 - 1.0)
final fastingProgressProvider = Provider<double>((ref) {
  final activeFast = ref.watch(activeFastProvider);
  if (activeFast == null) return 0.0;

  final elapsedMinutes = ref.watch(fastingElapsedMinutesProvider);
  final goalMinutes = activeFast.goalDurationMinutes;
  if (goalMinutes <= 0) return 0.0;

  return (elapsedMinutes / goalMinutes).clamp(0.0, 1.0);
});

/// Computed current zone based on elapsed time
final computedFastingZoneProvider = Provider<FastingZone>((ref) {
  final activeFast = ref.watch(activeFastProvider);
  if (activeFast == null) return FastingZone.fed;

  final elapsedMinutes = ref.watch(fastingElapsedMinutesProvider);
  return FastingZone.fromElapsedMinutes(elapsedMinutes);
});

// ============================================
// Safety Check Provider
// ============================================

/// Provider to check if user can use fasting features
final fastingSafetyCheckProvider = FutureProvider.family<SafetyScreeningResult, String>((ref, userId) async {
  final repository = ref.watch(fastingRepositoryProvider);
  return repository.checkSafetyEligibility(userId);
});
