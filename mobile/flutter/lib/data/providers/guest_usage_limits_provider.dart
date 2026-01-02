import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'guest_mode_provider.dart';

/// Guest usage limits - SEVERELY restricted to encourage sign-up
/// Free tier users get much more generous limits
class GuestUsageLimits {
  /// Maximum chat messages per day for guests (very limited to show value)
  static const int maxChatMessagesPerDay = 3;

  /// Maximum workout generations for guests (just enough to try)
  static const int maxWorkoutGenerationsTotal = 1;

  /// Nutrition scanning limits - 1 of each type to try
  static const int maxPhotoScansTotal = 1;
  static const int maxBarcodeScansTotal = 1;
  static const int maxTextDescribeTotal = 1;

  /// Legacy food scan limit (combined)
  static const int maxFoodScansPerDay = 1;

  /// Maximum exercise library views (unlimited for discovery)
  static const int maxExerciseLibraryViews = 999;

  /// Maximum nutrition log entries per day
  static const int maxNutritionLogsPerDay = 2;

  /// Fasting tracker DISABLED for guests
  static const bool fastingEnabled = false;

  /// Progress tracking disabled for guests
  static const bool progressTrackingEnabled = false;

  /// Workout history disabled for guests
  static const bool workoutHistoryEnabled = false;
}

/// Tracks guest usage for the current day/month
class GuestUsageState {
  final int chatMessagesToday;
  final int workoutGenerationsTotal;
  final int photoScansTotal;
  final int barcodeScansTotal;
  final int textDescribeTotal;
  final int foodScansToday; // Legacy
  final int nutritionLogsToday;
  final DateTime lastResetDate;
  final DateTime lastMonthlyResetDate;

  const GuestUsageState({
    this.chatMessagesToday = 0,
    this.workoutGenerationsTotal = 0,
    this.photoScansTotal = 0,
    this.barcodeScansTotal = 0,
    this.textDescribeTotal = 0,
    this.foodScansToday = 0,
    this.nutritionLogsToday = 0,
    required this.lastResetDate,
    required this.lastMonthlyResetDate,
  });

  /// Check if chat limit is reached
  bool get isChatLimitReached =>
      chatMessagesToday >= GuestUsageLimits.maxChatMessagesPerDay;

  /// Check if workout generation limit is reached
  bool get isWorkoutLimitReached =>
      workoutGenerationsTotal >= GuestUsageLimits.maxWorkoutGenerationsTotal;

  /// Check if photo scan limit is reached
  bool get isPhotoScanLimitReached =>
      photoScansTotal >= GuestUsageLimits.maxPhotoScansTotal;

  /// Check if barcode scan limit is reached
  bool get isBarcodeScanLimitReached =>
      barcodeScansTotal >= GuestUsageLimits.maxBarcodeScansTotal;

  /// Check if text describe limit is reached
  bool get isTextDescribeLimitReached =>
      textDescribeTotal >= GuestUsageLimits.maxTextDescribeTotal;

  /// Check if food scan limit is reached (legacy)
  bool get isFoodScanLimitReached =>
      foodScansToday >= GuestUsageLimits.maxFoodScansPerDay;

  /// Check if nutrition log limit is reached
  bool get isNutritionLogLimitReached =>
      nutritionLogsToday >= GuestUsageLimits.maxNutritionLogsPerDay;

  /// Remaining chat messages today
  int get remainingChatMessages =>
      (GuestUsageLimits.maxChatMessagesPerDay - chatMessagesToday).clamp(0, GuestUsageLimits.maxChatMessagesPerDay);

  /// Remaining workout generations
  int get remainingWorkoutGenerations =>
      (GuestUsageLimits.maxWorkoutGenerationsTotal - workoutGenerationsTotal).clamp(0, GuestUsageLimits.maxWorkoutGenerationsTotal);

  /// Remaining food scans today
  int get remainingFoodScans =>
      (GuestUsageLimits.maxFoodScansPerDay - foodScansToday).clamp(0, GuestUsageLimits.maxFoodScansPerDay);

  /// Remaining nutrition logs today
  int get remainingNutritionLogs =>
      (GuestUsageLimits.maxNutritionLogsPerDay - nutritionLogsToday).clamp(0, GuestUsageLimits.maxNutritionLogsPerDay);

  GuestUsageState copyWith({
    int? chatMessagesToday,
    int? workoutGenerationsTotal,
    int? photoScansTotal,
    int? barcodeScansTotal,
    int? textDescribeTotal,
    int? foodScansToday,
    int? nutritionLogsToday,
    DateTime? lastResetDate,
    DateTime? lastMonthlyResetDate,
  }) {
    return GuestUsageState(
      chatMessagesToday: chatMessagesToday ?? this.chatMessagesToday,
      workoutGenerationsTotal: workoutGenerationsTotal ?? this.workoutGenerationsTotal,
      photoScansTotal: photoScansTotal ?? this.photoScansTotal,
      barcodeScansTotal: barcodeScansTotal ?? this.barcodeScansTotal,
      textDescribeTotal: textDescribeTotal ?? this.textDescribeTotal,
      foodScansToday: foodScansToday ?? this.foodScansToday,
      nutritionLogsToday: nutritionLogsToday ?? this.nutritionLogsToday,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      lastMonthlyResetDate: lastMonthlyResetDate ?? this.lastMonthlyResetDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'chatMessagesToday': chatMessagesToday,
        'workoutGenerationsTotal': workoutGenerationsTotal,
        'photoScansTotal': photoScansTotal,
        'barcodeScansTotal': barcodeScansTotal,
        'textDescribeTotal': textDescribeTotal,
        'foodScansToday': foodScansToday,
        'nutritionLogsToday': nutritionLogsToday,
        'lastResetDate': lastResetDate.toIso8601String(),
        'lastMonthlyResetDate': lastMonthlyResetDate.toIso8601String(),
      };

  factory GuestUsageState.fromJson(Map<String, dynamic> json) {
    return GuestUsageState(
      chatMessagesToday: json['chatMessagesToday'] as int? ?? 0,
      workoutGenerationsTotal: json['workoutGenerationsTotal'] as int? ?? 0,
      photoScansTotal: json['photoScansTotal'] as int? ?? 0,
      barcodeScansTotal: json['barcodeScansTotal'] as int? ?? 0,
      textDescribeTotal: json['textDescribeTotal'] as int? ?? 0,
      foodScansToday: json['foodScansToday'] as int? ?? 0,
      nutritionLogsToday: json['nutritionLogsToday'] as int? ?? 0,
      lastResetDate: json['lastResetDate'] != null
          ? DateTime.parse(json['lastResetDate'] as String)
          : DateTime.now(),
      lastMonthlyResetDate: json['lastMonthlyResetDate'] != null
          ? DateTime.parse(json['lastMonthlyResetDate'] as String)
          : DateTime.now(),
    );
  }

  factory GuestUsageState.initial() {
    final now = DateTime.now();
    return GuestUsageState(
      lastResetDate: now,
      lastMonthlyResetDate: DateTime(now.year, now.month, 1),
    );
  }
}

/// Notifier for managing guest usage limits
class GuestUsageLimitsNotifier extends StateNotifier<GuestUsageState> {
  static const String _storageKey = 'guest_usage_state';

  GuestUsageLimitsNotifier() : super(GuestUsageState.initial()) {
    _loadState();
  }

  /// Load persisted state from storage
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        var loadedState = GuestUsageState.fromJson(json);

        // Check if we need to reset daily counters
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final lastReset = DateTime(
          loadedState.lastResetDate.year,
          loadedState.lastResetDate.month,
          loadedState.lastResetDate.day,
        );

        if (today.isAfter(lastReset)) {
          // Reset daily counters
          loadedState = loadedState.copyWith(
            chatMessagesToday: 0,
            foodScansToday: 0,
            nutritionLogsToday: 0,
            lastResetDate: now,
          );
          debugPrint('[GuestUsage] Daily counters reset');
        }

        // Check if we need to reset monthly counters
        final thisMonth = DateTime(now.year, now.month, 1);
        final lastMonthlyReset = DateTime(
          loadedState.lastMonthlyResetDate.year,
          loadedState.lastMonthlyResetDate.month,
          1,
        );

        if (thisMonth.isAfter(lastMonthlyReset)) {
          // Note: workoutGenerationsTotal is lifetime, not monthly reset
          // But we update the monthly reset date for tracking
          loadedState = loadedState.copyWith(
            lastMonthlyResetDate: thisMonth,
          );
          debugPrint('[GuestUsage] Monthly reset date updated');
        }

        state = loadedState;
        await _saveState();
      }
    } catch (e) {
      debugPrint('[GuestUsage] Failed to load state: $e');
    }
  }

  /// Save state to storage
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('[GuestUsage] Failed to save state: $e');
    }
  }

  /// Use a chat message (returns false if limit reached)
  Future<bool> useChatMessage() async {
    if (state.isChatLimitReached) {
      return false;
    }

    state = state.copyWith(
      chatMessagesToday: state.chatMessagesToday + 1,
    );
    await _saveState();
    debugPrint('[GuestUsage] Chat message used: ${state.chatMessagesToday}/${GuestUsageLimits.maxChatMessagesPerDay}');
    return true;
  }

  /// Use a workout generation (returns false if limit reached)
  Future<bool> useWorkoutGeneration() async {
    if (state.isWorkoutLimitReached) {
      return false;
    }

    state = state.copyWith(
      workoutGenerationsTotal: state.workoutGenerationsTotal + 1,
    );
    await _saveState();
    debugPrint('[GuestUsage] Workout generation used: ${state.workoutGenerationsTotal}/${GuestUsageLimits.maxWorkoutGenerationsTotal}');
    return true;
  }

  /// Use a photo scan (returns false if limit reached)
  Future<bool> usePhotoScan() async {
    if (state.isPhotoScanLimitReached) {
      return false;
    }

    state = state.copyWith(
      photoScansTotal: state.photoScansTotal + 1,
    );
    await _saveState();
    debugPrint('[GuestUsage] Photo scan used: ${state.photoScansTotal}/${GuestUsageLimits.maxPhotoScansTotal}');
    return true;
  }

  /// Use a barcode scan (returns false if limit reached)
  Future<bool> useBarcodeScan() async {
    if (state.isBarcodeScanLimitReached) {
      return false;
    }

    state = state.copyWith(
      barcodeScansTotal: state.barcodeScansTotal + 1,
    );
    await _saveState();
    debugPrint('[GuestUsage] Barcode scan used: ${state.barcodeScansTotal}/${GuestUsageLimits.maxBarcodeScansTotal}');
    return true;
  }

  /// Use a text describe scan (returns false if limit reached)
  Future<bool> useTextDescribe() async {
    if (state.isTextDescribeLimitReached) {
      return false;
    }

    state = state.copyWith(
      textDescribeTotal: state.textDescribeTotal + 1,
    );
    await _saveState();
    debugPrint('[GuestUsage] Text describe used: ${state.textDescribeTotal}/${GuestUsageLimits.maxTextDescribeTotal}');
    return true;
  }

  /// Use a food scan - legacy (returns false if limit reached)
  Future<bool> useFoodScan() async {
    if (state.isFoodScanLimitReached) {
      return false;
    }

    state = state.copyWith(
      foodScansToday: state.foodScansToday + 1,
    );
    await _saveState();
    debugPrint('[GuestUsage] Food scan used: ${state.foodScansToday}/${GuestUsageLimits.maxFoodScansPerDay}');
    return true;
  }

  /// Use a nutrition log (returns false if limit reached)
  Future<bool> useNutritionLog() async {
    if (state.isNutritionLogLimitReached) {
      return false;
    }

    state = state.copyWith(
      nutritionLogsToday: state.nutritionLogsToday + 1,
    );
    await _saveState();
    debugPrint('[GuestUsage] Nutrition log used: ${state.nutritionLogsToday}/${GuestUsageLimits.maxNutritionLogsPerDay}');
    return true;
  }

  /// Reset all usage (for testing or when user signs up)
  Future<void> resetAll() async {
    state = GuestUsageState.initial();
    await _saveState();
  }
}

/// Provider for guest usage limits
final guestUsageLimitsProvider =
    StateNotifierProvider<GuestUsageLimitsNotifier, GuestUsageState>((ref) {
  return GuestUsageLimitsNotifier();
});

/// Quick check if chat is available for guest
final canGuestChatProvider = Provider<bool>((ref) {
  final isGuest = ref.watch(isGuestModeProvider);
  if (!isGuest) return true; // Logged-in users have no limit

  final usage = ref.watch(guestUsageLimitsProvider);
  return !usage.isChatLimitReached;
});

/// Quick check if workout generation is available for guest
final canGuestGenerateWorkoutProvider = Provider<bool>((ref) {
  final isGuest = ref.watch(isGuestModeProvider);
  if (!isGuest) return true; // Logged-in users have no limit

  final usage = ref.watch(guestUsageLimitsProvider);
  return !usage.isWorkoutLimitReached;
});

/// Quick check if food scan is available for guest
final canGuestScanFoodProvider = Provider<bool>((ref) {
  final isGuest = ref.watch(isGuestModeProvider);
  if (!isGuest) return true; // Logged-in users have no limit

  final usage = ref.watch(guestUsageLimitsProvider);
  return !usage.isFoodScanLimitReached;
});

/// Remaining chat messages for display
final guestRemainingChatsProvider = Provider<int>((ref) {
  final isGuest = ref.watch(isGuestModeProvider);
  if (!isGuest) return 999; // Logged-in users have no limit shown

  return ref.watch(guestUsageLimitsProvider).remainingChatMessages;
});

/// Remaining workout generations for display
final guestRemainingWorkoutsProvider = Provider<int>((ref) {
  final isGuest = ref.watch(isGuestModeProvider);
  if (!isGuest) return 999; // Logged-in users have no limit shown

  return ref.watch(guestUsageLimitsProvider).remainingWorkoutGenerations;
});

/// Quick check if photo scan is available for guest
final canGuestPhotoScanProvider = Provider<bool>((ref) {
  final isGuest = ref.watch(isGuestModeProvider);
  if (!isGuest) return true;

  final usage = ref.watch(guestUsageLimitsProvider);
  return !usage.isPhotoScanLimitReached;
});

/// Quick check if barcode scan is available for guest
final canGuestBarcodeScanProvider = Provider<bool>((ref) {
  final isGuest = ref.watch(isGuestModeProvider);
  if (!isGuest) return true;

  final usage = ref.watch(guestUsageLimitsProvider);
  return !usage.isBarcodeScanLimitReached;
});

/// Quick check if text describe is available for guest
final canGuestTextDescribeProvider = Provider<bool>((ref) {
  final isGuest = ref.watch(isGuestModeProvider);
  if (!isGuest) return true;

  final usage = ref.watch(guestUsageLimitsProvider);
  return !usage.isTextDescribeLimitReached;
});

/// Check if fasting is enabled for current user
final isFastingEnabledProvider = Provider<bool>((ref) {
  final isGuest = ref.watch(isGuestModeProvider);
  if (isGuest) return GuestUsageLimits.fastingEnabled; // false for guests
  return true; // Enabled for logged-in users
});

/// Check if progress tracking is enabled for current user
final isProgressTrackingEnabledProvider = Provider<bool>((ref) {
  final isGuest = ref.watch(isGuestModeProvider);
  if (isGuest) return GuestUsageLimits.progressTrackingEnabled; // false for guests
  return true;
});

/// Check if workout history is enabled for current user
final isWorkoutHistoryEnabledProvider = Provider<bool>((ref) {
  final isGuest = ref.watch(isGuestModeProvider);
  if (isGuest) return GuestUsageLimits.workoutHistoryEnabled; // false for guests
  return true;
});
