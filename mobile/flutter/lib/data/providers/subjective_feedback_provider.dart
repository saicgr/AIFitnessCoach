import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subjective_feedback.dart';
import '../repositories/auth_repository.dart';
import '../services/api_client.dart';

/// State for subjective feedback tracking
class SubjectiveFeedbackState {
  final bool isLoading;
  final String? error;

  // Current pre-workout check-in (before workout starts)
  final SubjectiveFeedback? currentPreCheckin;

  // Feel results summary
  final FeelResultsSummary? feelResults;

  // Trends data
  final SubjectiveTrendsResponse? trends;

  // Quick stats for home screen
  final SubjectiveQuickStats? quickStats;

  // History
  final List<SubjectiveFeedback> history;
  final bool hasMoreHistory;
  final int historyOffset;

  const SubjectiveFeedbackState({
    this.isLoading = false,
    this.error,
    this.currentPreCheckin,
    this.feelResults,
    this.trends,
    this.quickStats,
    this.history = const [],
    this.hasMoreHistory = false,
    this.historyOffset = 0,
  });

  SubjectiveFeedbackState copyWith({
    bool? isLoading,
    String? error,
    SubjectiveFeedback? currentPreCheckin,
    FeelResultsSummary? feelResults,
    SubjectiveTrendsResponse? trends,
    SubjectiveQuickStats? quickStats,
    List<SubjectiveFeedback>? history,
    bool? hasMoreHistory,
    int? historyOffset,
    bool clearError = false,
    bool clearPreCheckin = false,
  }) {
    return SubjectiveFeedbackState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPreCheckin: clearPreCheckin ? null : (currentPreCheckin ?? this.currentPreCheckin),
      feelResults: feelResults ?? this.feelResults,
      trends: trends ?? this.trends,
      quickStats: quickStats ?? this.quickStats,
      history: history ?? this.history,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      historyOffset: historyOffset ?? this.historyOffset,
    );
  }
}

/// Provider for subjective feedback state
final subjectiveFeedbackProvider =
    StateNotifierProvider<SubjectiveFeedbackNotifier, SubjectiveFeedbackState>((ref) {
  return SubjectiveFeedbackNotifier(
    ref.watch(apiClientProvider),
    ref.watch(authRepositoryProvider),
  );
});

/// Notifier for subjective feedback state management
class SubjectiveFeedbackNotifier extends StateNotifier<SubjectiveFeedbackState> {
  final ApiClient _apiClient;
  final AuthRepository _authRepository;

  SubjectiveFeedbackNotifier(this._apiClient, this._authRepository)
      : super(const SubjectiveFeedbackState());

  /// Create a pre-workout check-in
  Future<SubjectiveFeedback?> createPreCheckin({
    required int moodBefore,
    int? energyBefore,
    int? sleepQuality,
    int? stressLevel,
    String? workoutId,
  }) async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user == null) {
        state = state.copyWith(error: 'User not logged in');
        return null;
      }

      debugPrint('Creating pre-workout check-in: mood=$moodBefore');

      final response = await _apiClient.post(
        '/v1/subjective-feedback/pre-checkin',
        data: {
          'user_id': user.id,
          'workout_id': workoutId,
          'mood_before': moodBefore,
          if (energyBefore != null) 'energy_before': energyBefore,
          if (sleepQuality != null) 'sleep_quality': sleepQuality,
          if (stressLevel != null) 'stress_level': stressLevel,
        },
      );

      final feedback = SubjectiveFeedback.fromJson(response.data as Map<String, dynamic>);

      state = state.copyWith(
        currentPreCheckin: feedback,
        clearError: true,
      );

      debugPrint('Pre-workout check-in created: ${feedback.id}');
      return feedback;
    } catch (e) {
      debugPrint('Error creating pre-workout check-in: $e');
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Create a post-workout check-in
  Future<SubjectiveFeedback?> createPostCheckin({
    required String workoutId,
    required int moodAfter,
    int? energyAfter,
    int? confidenceLevel,
    int? sorenessLevel,
    bool feelingStronger = false,
    String? notes,
  }) async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user == null) {
        state = state.copyWith(error: 'User not logged in');
        return null;
      }

      debugPrint('Creating post-workout check-in: workout=$workoutId, mood=$moodAfter');

      final response = await _apiClient.post(
        '/v1/subjective-feedback/workouts/$workoutId/post-checkin',
        data: {
          'user_id': user.id,
          'workout_id': workoutId,
          'mood_after': moodAfter,
          if (energyAfter != null) 'energy_after': energyAfter,
          if (confidenceLevel != null) 'confidence_level': confidenceLevel,
          if (sorenessLevel != null) 'soreness_level': sorenessLevel,
          'feeling_stronger': feelingStronger,
          if (notes != null) 'notes': notes,
        },
      );

      final feedback = SubjectiveFeedback.fromJson(response.data as Map<String, dynamic>);

      // Clear the current pre-checkin and refresh quick stats
      state = state.copyWith(
        clearPreCheckin: true,
        clearError: true,
      );

      // Refresh quick stats in background
      loadQuickStats();

      debugPrint('Post-workout check-in created: ${feedback.id}');
      return feedback;
    } catch (e) {
      debugPrint('Error creating post-workout check-in: $e');
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Load feel results summary
  Future<void> loadFeelResults() async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user == null) return;

      state = state.copyWith(isLoading: true);

      final response = await _apiClient.get(
        '/v1/subjective-feedback/progress/feel-results',
        queryParameters: {'user_id': user.id},
      );

      final summary = FeelResultsSummary.fromJson(response.data as Map<String, dynamic>);

      state = state.copyWith(
        isLoading: false,
        feelResults: summary,
        clearError: true,
      );

      debugPrint('Loaded feel results: ${summary.totalWorkoutsTracked} workouts tracked');
    } catch (e) {
      debugPrint('Error loading feel results: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load subjective trends
  Future<void> loadTrends({int days = 30}) async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user == null) return;

      state = state.copyWith(isLoading: true);

      final response = await _apiClient.get(
        '/v1/subjective-feedback/progress/subjective-trends',
        queryParameters: {
          'user_id': user.id,
          'days': days,
        },
      );

      final trends = SubjectiveTrendsResponse.fromJson(response.data as Map<String, dynamic>);

      state = state.copyWith(
        isLoading: false,
        trends: trends,
        clearError: true,
      );

      debugPrint('Loaded subjective trends: ${trends.totalWorkouts} workouts');
    } catch (e) {
      debugPrint('Error loading subjective trends: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load quick stats for home screen widget
  Future<void> loadQuickStats() async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user == null) return;

      final response = await _apiClient.get(
        '/v1/subjective-feedback/quick-stats',
        queryParameters: {'user_id': user.id},
      );

      final stats = SubjectiveQuickStats.fromJson(response.data as Map<String, dynamic>);

      state = state.copyWith(
        quickStats: stats,
        clearError: true,
      );

      debugPrint('Loaded quick stats: hasData=${stats.hasData}');
    } catch (e) {
      debugPrint('Error loading quick stats: $e');
      // Don't set error state for quick stats - it's not critical
    }
  }

  /// Load history of subjective feedback
  Future<void> loadHistory({bool refresh = false}) async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user == null) return;

      final offset = refresh ? 0 : state.historyOffset;

      if (!refresh && !state.hasMoreHistory && state.history.isNotEmpty) {
        return;
      }

      state = state.copyWith(isLoading: true);

      final response = await _apiClient.get(
        '/v1/subjective-feedback/history',
        queryParameters: {
          'user_id': user.id,
          'limit': 20,
          'offset': offset,
        },
      );

      final historyList = (response.data as List<dynamic>)
          .map((item) => SubjectiveFeedback.fromJson(item as Map<String, dynamic>))
          .toList();

      final newHistory = refresh ? historyList : [...state.history, ...historyList];

      state = state.copyWith(
        isLoading: false,
        history: newHistory,
        hasMoreHistory: historyList.length >= 20,
        historyOffset: offset + historyList.length,
        clearError: true,
      );

      debugPrint('Loaded ${historyList.length} history items');
    } catch (e) {
      debugPrint('Error loading history: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get feedback for a specific workout
  Future<SubjectiveFeedback?> getWorkoutFeedback(String workoutId) async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user == null) return null;

      final response = await _apiClient.get(
        '/v1/subjective-feedback/workouts/$workoutId',
        queryParameters: {'user_id': user.id},
      );

      if (response.data == null) return null;

      return SubjectiveFeedback.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error getting workout feedback: $e');
      return null;
    }
  }

  /// Clear current pre-checkin
  void clearPreCheckin() {
    state = state.copyWith(clearPreCheckin: true);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for feel results summary only (cached)
final feelResultsProvider = FutureProvider<FeelResultsSummary?>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final authRepository = ref.watch(authRepositoryProvider);

  final user = await authRepository.getCurrentUser();
  if (user == null) return null;

  try {
    final response = await apiClient.get(
      '/v1/subjective-feedback/progress/feel-results',
      queryParameters: {'user_id': user.id},
    );

    return FeelResultsSummary.fromJson(response.data as Map<String, dynamic>);
  } catch (e) {
    debugPrint('Error loading feel results: $e');
    return null;
  }
});

/// Provider for quick stats (for home screen widget)
final subjectiveQuickStatsProvider = FutureProvider<SubjectiveQuickStats?>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final authRepository = ref.watch(authRepositoryProvider);

  final user = await authRepository.getCurrentUser();
  if (user == null) return null;

  try {
    final response = await apiClient.get(
      '/v1/subjective-feedback/quick-stats',
      queryParameters: {'user_id': user.id},
    );

    return SubjectiveQuickStats.fromJson(response.data as Map<String, dynamic>);
  } catch (e) {
    debugPrint('Error loading quick stats: $e');
    return null;
  }
});
