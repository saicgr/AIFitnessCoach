import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Free Tier Limits Configuration
///
/// Defines the limits for free tier users to ensure transparency
/// about what they can do without paying.
class FreeTierLimits {
  /// Maximum chat messages per day for free users
  static const int chatMessagesPerDay = 10;

  /// Maximum workout generations per month for free users
  static const int workoutGenerationsPerMonth = 4;

  /// Maximum food scans per day for free users
  static const int foodScansPerDay = 0; // Premium only

  /// Whether nutrition tracking is enabled for free users
  static const bool nutritionTrackingEnabled = false;

  /// Maximum exercises viewable in library for free users
  static const int exerciseLibraryLimit = 50;

  /// Whether custom exercises can be created by free users
  static const bool customExercisesEnabled = false;

  /// Maximum saved workouts for free users
  static const int savedWorkoutsLimit = 3;

  /// Whether workout history is available for free users
  static const bool workoutHistoryEnabled = true;

  /// Days of workout history available for free users
  static const int workoutHistoryDays = 7;
}

/// Feature usage tracking for a specific feature
class FeatureUsage {
  final String featureId;
  final int currentUsage;
  final int limit;
  final DateTime? resetDate;
  final bool isUnlimited;

  const FeatureUsage({
    required this.featureId,
    required this.currentUsage,
    required this.limit,
    this.resetDate,
    this.isUnlimited = false,
  });

  bool get isAtLimit => !isUnlimited && currentUsage >= limit;
  int get remaining => isUnlimited ? -1 : (limit - currentUsage).clamp(0, limit);
  double get usagePercentage =>
      isUnlimited ? 0 : (currentUsage / limit).clamp(0.0, 1.0);

  FeatureUsage copyWith({
    String? featureId,
    int? currentUsage,
    int? limit,
    DateTime? resetDate,
    bool? isUnlimited,
  }) {
    return FeatureUsage(
      featureId: featureId ?? this.featureId,
      currentUsage: currentUsage ?? this.currentUsage,
      limit: limit ?? this.limit,
      resetDate: resetDate ?? this.resetDate,
      isUnlimited: isUnlimited ?? this.isUnlimited,
    );
  }
}

/// State for free tier usage tracking
class FreeTierState {
  final Map<String, FeatureUsage> featureUsage;
  final bool isPremium;
  final bool isLoading;
  final String? error;

  const FreeTierState({
    this.featureUsage = const {},
    this.isPremium = false,
    this.isLoading = true,
    this.error,
  });

  FreeTierState copyWith({
    Map<String, FeatureUsage>? featureUsage,
    bool? isPremium,
    bool? isLoading,
    String? error,
  }) {
    return FreeTierState(
      featureUsage: featureUsage ?? this.featureUsage,
      isPremium: isPremium ?? this.isPremium,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get usage for a specific feature
  FeatureUsage? getUsage(String featureId) => featureUsage[featureId];

  /// Check if a feature is at its limit
  bool isFeatureAtLimit(String featureId) {
    if (isPremium) return false;
    final usage = featureUsage[featureId];
    return usage?.isAtLimit ?? false;
  }

  /// Get remaining uses for a feature
  int getRemainingUses(String featureId) {
    if (isPremium) return -1; // Unlimited
    final usage = featureUsage[featureId];
    return usage?.remaining ?? 0;
  }
}

/// Feature IDs for tracking
class FeatureIds {
  static const String chatMessages = 'chat_messages';
  static const String workoutGenerations = 'workout_generations';
  static const String foodScans = 'food_scans';
  static const String exerciseLibrary = 'exercise_library';
  static const String customExercises = 'custom_exercises';
  static const String savedWorkouts = 'saved_workouts';
}

/// Free tier state notifier
class FreeTierNotifier extends StateNotifier<FreeTierState> {
  FreeTierNotifier() : super(const FreeTierState()) {
    _loadUsage();
  }

  static const String _prefsKeyPrefix = 'free_tier_';

  /// Load usage from local storage
  Future<void> _loadUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if we need to reset daily counters
      await _checkAndResetDailyCounters(prefs);

      // Check if we need to reset monthly counters
      await _checkAndResetMonthlyCounters(prefs);

      // Load all feature usage
      final usage = <String, FeatureUsage>{};

      // Chat messages (daily limit)
      final chatUsage = prefs.getInt('$_prefsKeyPrefix${FeatureIds.chatMessages}') ?? 0;
      usage[FeatureIds.chatMessages] = FeatureUsage(
        featureId: FeatureIds.chatMessages,
        currentUsage: chatUsage,
        limit: FreeTierLimits.chatMessagesPerDay,
        resetDate: _getNextDayReset(),
      );

      // Workout generations (monthly limit)
      final workoutUsage =
          prefs.getInt('$_prefsKeyPrefix${FeatureIds.workoutGenerations}') ?? 0;
      usage[FeatureIds.workoutGenerations] = FeatureUsage(
        featureId: FeatureIds.workoutGenerations,
        currentUsage: workoutUsage,
        limit: FreeTierLimits.workoutGenerationsPerMonth,
        resetDate: _getNextMonthReset(),
      );

      // Food scans (premium only - always at limit for free)
      usage[FeatureIds.foodScans] = FeatureUsage(
        featureId: FeatureIds.foodScans,
        currentUsage: 0,
        limit: FreeTierLimits.foodScansPerDay,
      );

      // Saved workouts
      final savedWorkouts =
          prefs.getInt('$_prefsKeyPrefix${FeatureIds.savedWorkouts}') ?? 0;
      usage[FeatureIds.savedWorkouts] = FeatureUsage(
        featureId: FeatureIds.savedWorkouts,
        currentUsage: savedWorkouts,
        limit: FreeTierLimits.savedWorkoutsLimit,
      );

      state = state.copyWith(
        featureUsage: usage,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load usage data: $e',
      );
    }
  }

  /// Check and reset daily counters
  Future<void> _checkAndResetDailyCounters(SharedPreferences prefs) async {
    final lastResetStr = prefs.getString('${_prefsKeyPrefix}daily_reset');
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    if (lastResetStr != todayStr) {
      // Reset daily counters
      await prefs.setInt('$_prefsKeyPrefix${FeatureIds.chatMessages}', 0);
      await prefs.setString('${_prefsKeyPrefix}daily_reset', todayStr);
    }
  }

  /// Check and reset monthly counters
  Future<void> _checkAndResetMonthlyCounters(SharedPreferences prefs) async {
    final lastResetStr = prefs.getString('${_prefsKeyPrefix}monthly_reset');
    final today = DateTime.now();
    final monthStr = '${today.year}-${today.month}';

    if (lastResetStr != monthStr) {
      // Reset monthly counters
      await prefs.setInt('$_prefsKeyPrefix${FeatureIds.workoutGenerations}', 0);
      await prefs.setString('${_prefsKeyPrefix}monthly_reset', monthStr);
    }
  }

  DateTime _getNextDayReset() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  DateTime _getNextMonthReset() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1);
  }

  /// Increment usage for a feature
  Future<bool> incrementUsage(String featureId) async {
    if (state.isPremium) return true; // Premium has no limits

    final currentUsage = state.featureUsage[featureId];
    if (currentUsage == null) return false;

    if (currentUsage.isAtLimit) {
      return false; // At limit, can't use
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final newUsage = currentUsage.currentUsage + 1;
      await prefs.setInt('$_prefsKeyPrefix$featureId', newUsage);

      final updatedUsage = Map<String, FeatureUsage>.from(state.featureUsage);
      updatedUsage[featureId] = currentUsage.copyWith(currentUsage: newUsage);

      state = state.copyWith(featureUsage: updatedUsage);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if a feature can be used
  bool canUseFeature(String featureId) {
    if (state.isPremium) return true;
    return !state.isFeatureAtLimit(featureId);
  }

  /// Set premium status
  void setPremiumStatus(bool isPremium) {
    state = state.copyWith(isPremium: isPremium);
  }

  /// Get a user-friendly message about usage
  String getUsageMessage(String featureId) {
    if (state.isPremium) return 'Unlimited';

    final usage = state.featureUsage[featureId];
    if (usage == null) return 'Unknown';

    if (usage.isAtLimit) {
      if (usage.resetDate != null) {
        final now = DateTime.now();
        final diff = usage.resetDate!.difference(now);
        if (diff.inHours > 24) {
          return 'Resets in ${diff.inDays} days';
        } else if (diff.inHours > 0) {
          return 'Resets in ${diff.inHours} hours';
        } else {
          return 'Resets soon';
        }
      }
      return 'Limit reached';
    }

    return '${usage.remaining} remaining';
  }
}

/// Provider for free tier state
final freeTierProvider =
    StateNotifierProvider<FreeTierNotifier, FreeTierState>((ref) {
  return FreeTierNotifier();
});

/// Provider for checking if a specific feature can be used
final canUseFeatureProvider = Provider.family<bool, String>((ref, featureId) {
  final state = ref.watch(freeTierProvider);
  if (state.isPremium) return true;
  return !state.isFeatureAtLimit(featureId);
});

/// Provider for getting remaining uses of a feature
final remainingUsesProvider = Provider.family<int, String>((ref, featureId) {
  final state = ref.watch(freeTierProvider);
  return state.getRemainingUses(featureId);
});
