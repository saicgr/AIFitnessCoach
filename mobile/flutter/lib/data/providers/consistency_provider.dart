import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/consistency.dart';
import '../models/workout_day_detail.dart';
import '../repositories/consistency_repository.dart';
import '../services/api_client.dart';

/// In-memory cache for instant display on provider recreation
/// Survives provider invalidation and prevents loading flash
ConsistencyState? _consistencyInMemoryCache;

// ============================================
// Consistency State
// ============================================

/// State for consistency insights
class ConsistencyState {
  final ConsistencyInsights? insights;
  final ConsistencyPatterns? patterns;
  final CalendarHeatmapResponse? calendarData;
  final StreakRecoveryResponse? recoveryResponse;
  final bool isLoading;
  final bool isLoadingPatterns;
  final bool isLoadingCalendar;
  final bool isRecovering;
  final String? error;

  const ConsistencyState({
    this.insights,
    this.patterns,
    this.calendarData,
    this.recoveryResponse,
    this.isLoading = false,
    this.isLoadingPatterns = false,
    this.isLoadingCalendar = false,
    this.isRecovering = false,
    this.error,
  });

  ConsistencyState copyWith({
    ConsistencyInsights? insights,
    ConsistencyPatterns? patterns,
    CalendarHeatmapResponse? calendarData,
    StreakRecoveryResponse? recoveryResponse,
    bool? isLoading,
    bool? isLoadingPatterns,
    bool? isLoadingCalendar,
    bool? isRecovering,
    String? error,
    bool clearError = false,
    bool clearRecovery = false,
  }) {
    return ConsistencyState(
      insights: insights ?? this.insights,
      patterns: patterns ?? this.patterns,
      calendarData: calendarData ?? this.calendarData,
      recoveryResponse:
          clearRecovery ? null : (recoveryResponse ?? this.recoveryResponse),
      isLoading: isLoading ?? this.isLoading,
      isLoadingPatterns: isLoadingPatterns ?? this.isLoadingPatterns,
      isLoadingCalendar: isLoadingCalendar ?? this.isLoadingCalendar,
      isRecovering: isRecovering ?? this.isRecovering,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // Computed properties for easy access
  int get currentStreak => insights?.currentStreak ?? 0;
  int get longestStreak => insights?.longestStreak ?? 0;
  bool get isStreakActive => insights?.isStreakActive ?? false;
  bool get needsRecovery => insights?.needsRecovery ?? false;
  String? get recoverySuggestion => insights?.recoverySuggestion;
  DayPattern? get bestDay => insights?.bestDay;
  DayPattern? get worstDay => insights?.worstDay;
  String get monthDisplay => insights?.monthDisplay ?? '0 of 0 workouts';
  double get averageWeeklyRate => insights?.averageWeeklyRate ?? 0.0;
  String get weeklyTrend => insights?.weeklyTrend ?? 'stable';

  /// Check if we have loaded insights
  bool get hasInsights => insights != null;

  /// Check if we have any data
  bool get hasData => insights != null || calendarData != null;
}

// ============================================
// Consistency Notifier
// ============================================

class ConsistencyNotifier extends StateNotifier<ConsistencyState> {
  final ConsistencyRepository _repository;
  String? _currentUserId;

  ConsistencyNotifier(this._repository)
      : super(_consistencyInMemoryCache ?? const ConsistencyState());

  /// Clear in-memory cache (called on logout)
  static void clearCache() {
    _consistencyInMemoryCache = null;
    debugPrint('🧹 [ConsistencyProvider] In-memory cache cleared');
  }

  /// Set user ID for this session
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  /// Load comprehensive consistency insights
  Future<void> loadInsights({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('Warning: [Consistency] No user ID, skipping load');
      return;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final insights = await _repository.getInsights(userId: uid);
      state = state.copyWith(
        insights: insights,
        isLoading: false,
      );
      // Update in-memory cache for instant access on provider recreation
      _consistencyInMemoryCache = state;
      debugPrint('[Consistency] Loaded insights - streak: ${insights.currentStreak}');
    } catch (e) {
      debugPrint('[Consistency] Error loading insights: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load consistency data: $e',
      );
    }
  }

  /// Load detailed patterns analysis
  Future<void> loadPatterns({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('Warning: [Consistency] No user ID, skipping patterns load');
      return;
    }

    state = state.copyWith(isLoadingPatterns: true);

    try {
      final patterns = await _repository.getPatterns(userId: uid);
      state = state.copyWith(
        patterns: patterns,
        isLoadingPatterns: false,
      );
      debugPrint('[Consistency] Loaded patterns');
    } catch (e) {
      debugPrint('[Consistency] Error loading patterns: $e');
      state = state.copyWith(
        isLoadingPatterns: false,
        error: 'Failed to load patterns: $e',
      );
    }
  }

  /// Load calendar heatmap data
  Future<void> loadCalendar({String? userId, int weeks = 4}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('Warning: [Consistency] No user ID, skipping calendar load');
      return;
    }

    state = state.copyWith(isLoadingCalendar: true);

    try {
      final calendarData = await _repository.getCalendarHeatmap(
        userId: uid,
        weeks: weeks,
      );
      state = state.copyWith(
        calendarData: calendarData,
        isLoadingCalendar: false,
      );
      debugPrint('[Consistency] Loaded calendar heatmap');
    } catch (e) {
      debugPrint('[Consistency] Error loading calendar: $e');
      state = state.copyWith(
        isLoadingCalendar: false,
        error: 'Failed to load calendar: $e',
      );
    }
  }

  /// Load all data at once
  Future<void> loadAll({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('Warning: [Consistency] No user ID, skipping load all');
      return;
    }
    _currentUserId = uid;

    // Load insights first (primary data)
    await loadInsights(userId: uid);

    // Load calendar in parallel
    await loadCalendar(userId: uid);
  }

  /// Initiate streak recovery
  Future<StreakRecoveryResponse?> initiateRecovery({
    String? userId,
    String recoveryType = 'standard',
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('Warning: [Consistency] No user ID for recovery');
      return null;
    }

    state = state.copyWith(isRecovering: true, clearError: true);

    try {
      final response = await _repository.initiateRecovery(
        userId: uid,
        recoveryType: recoveryType,
      );
      state = state.copyWith(
        recoveryResponse: response,
        isRecovering: false,
      );
      debugPrint('[Consistency] Recovery initiated: ${response.message}');
      return response;
    } catch (e) {
      debugPrint('[Consistency] Error initiating recovery: $e');
      state = state.copyWith(
        isRecovering: false,
        error: 'Failed to start recovery: $e',
      );
      return null;
    }
  }

  /// Complete streak recovery attempt
  Future<bool> completeRecovery({
    required String attemptId,
    String? workoutId,
    bool wasSuccessful = true,
  }) async {
    final uid = _currentUserId;
    if (uid == null) {
      debugPrint('Warning: [Consistency] No user ID for completing recovery');
      return false;
    }

    try {
      await _repository.completeRecovery(
        attemptId: attemptId,
        userId: uid,
        workoutId: workoutId,
        wasSuccessful: wasSuccessful,
      );
      state = state.copyWith(clearRecovery: true);

      // Reload insights to get updated streak
      await loadInsights();

      debugPrint('[Consistency] Recovery completed successfully');
      return true;
    } catch (e) {
      debugPrint('[Consistency] Error completing recovery: $e');
      return false;
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refresh all data
  Future<void> refresh({String? userId}) async {
    await loadAll(userId: userId);
  }
}

// ============================================
// Providers
// ============================================

/// Main consistency provider
final consistencyProvider =
    StateNotifierProvider<ConsistencyNotifier, ConsistencyState>((ref) {
  final repository = ref.watch(consistencyRepositoryProvider);
  return ConsistencyNotifier(repository);
});

/// Quick access to current streak
final currentStreakProvider = Provider<int>((ref) {
  return ref.watch(consistencyProvider).currentStreak;
});

/// Quick access to longest streak
final longestStreakProvider = Provider<int>((ref) {
  return ref.watch(consistencyProvider).longestStreak;
});

/// Quick access to streak active status
final isStreakActiveProvider = Provider<bool>((ref) {
  return ref.watch(consistencyProvider).isStreakActive;
});

/// Quick access to recovery needed status
final needsRecoveryProvider = Provider<bool>((ref) {
  return ref.watch(consistencyProvider).needsRecovery;
});

/// Quick access to monthly display string
final monthDisplayProvider = Provider<String>((ref) {
  return ref.watch(consistencyProvider).monthDisplay;
});

/// Quick access to best day
final bestDayProvider = Provider<DayPattern?>((ref) {
  return ref.watch(consistencyProvider).bestDay;
});

/// Quick access to worst day
final worstDayProvider = Provider<DayPattern?>((ref) {
  return ref.watch(consistencyProvider).worstDay;
});

/// Provider for calendar heatmap data
final calendarHeatmapProvider = Provider<CalendarHeatmapResponse?>((ref) {
  return ref.watch(consistencyProvider).calendarData;
});

/// Provider for loading state
final consistencyLoadingProvider = Provider<bool>((ref) {
  return ref.watch(consistencyProvider).isLoading;
});

/// Auto-loading provider that loads data when user ID is available
/// Note: Removed autoDispose to prevent refetching on navigation
final consistencyDataProvider = FutureProvider<ConsistencyInsights?>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final userId = await apiClient.getUserId();

  if (userId == null) {
    return null;
  }

  // Set user ID and load insights
  final notifier = ref.read(consistencyProvider.notifier);
  notifier.setUserId(userId);
  await notifier.loadInsights();

  return ref.read(consistencyProvider).insights;
});

// ============================================
// Activity Heatmap Providers
// ============================================

/// Parameter for activity heatmap provider
typedef HeatmapParams = ({String userId, int weeks});

/// Activity heatmap data with configurable time range
/// Note: Removed autoDispose to prevent refetching on navigation
final activityHeatmapProvider = FutureProvider
    .family<CalendarHeatmapResponse, HeatmapParams>((ref, params) async {
  final repository = ref.watch(consistencyRepositoryProvider);
  return repository.getCalendarHeatmap(
    userId: params.userId,
    weeks: params.weeks,
  );
});

// ============================================
// Day Detail Providers
// ============================================

/// Parameter for workout day detail provider
typedef DayDetailParams = ({String userId, String date});

/// Workout day detail for bottom sheet
/// Note: Removed autoDispose to prevent refetching on navigation
final workoutDayDetailProvider = FutureProvider
    .family<WorkoutDayDetail, DayDetailParams>((ref, params) async {
  final repository = ref.watch(consistencyRepositoryProvider);
  return repository.getDayDetail(
    userId: params.userId,
    date: params.date,
  );
});

// ============================================
// Exercise Search Providers
// ============================================

/// Parameter for exercise search provider
typedef ExerciseSearchParams = ({String userId, String exerciseName, int weeks});

/// Exercise search results for heatmap highlighting
/// Note: Removed autoDispose to prevent refetching on navigation
final exerciseSearchProvider = FutureProvider
    .family<ExerciseSearchResponse, ExerciseSearchParams>((ref, params) async {
  final repository = ref.watch(consistencyRepositoryProvider);
  return repository.searchExercise(
    userId: params.userId,
    exerciseName: params.exerciseName,
    weeks: params.weeks,
  );
});

/// Parameter for exercise suggestions provider
typedef SuggestionParams = ({String userId, String query});

/// Exercise name suggestions for autocomplete
/// Note: Removed autoDispose to prevent refetching on navigation
final exerciseSuggestionsProvider = FutureProvider
    .family<List<ExerciseSuggestion>, SuggestionParams>((ref, params) async {
  final repository = ref.watch(consistencyRepositoryProvider);
  return repository.getExerciseSuggestions(
    userId: params.userId,
    query: params.query,
  );
});

// ============================================
// Heatmap Time Range State
// ============================================

/// Time range options for heatmap
enum HeatmapTimeRange {
  week(1, 'Week'),
  oneMonth(4, '1M'),
  threeMonths(13, '3M'),
  sixMonths(26, '6M'),
  oneYear(52, '1Y');

  final int weeks;
  final String label;
  const HeatmapTimeRange(this.weeks, this.label);
}

/// Selected time range for heatmap (preset options)
final heatmapTimeRangeProvider = StateProvider<HeatmapTimeRange>((ref) {
  return HeatmapTimeRange.threeMonths;
});

/// Custom date range for stats filtering (when user selects custom option)
/// If set, this takes precedence over heatmapTimeRangeProvider
final customStatsDateRangeProvider = StateProvider<DateTimeRange?>((ref) {
  return null;
});

/// Current search query for exercise search
final exerciseSearchQueryProvider = StateProvider<String?>((ref) {
  return null;
});
