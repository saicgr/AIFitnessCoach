import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mood.dart';
import '../repositories/auth_repository.dart';
import '../repositories/mood_history_repository.dart';

/// State for mood history
class MoodHistoryState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<MoodHistoryItem> checkins;
  final int totalCount;
  final bool hasMore;
  final MoodAnalyticsResponse? analytics;
  final MoodHistoryItem? todayCheckin;
  final int currentOffset;

  const MoodHistoryState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.checkins = const [],
    this.totalCount = 0,
    this.hasMore = false,
    this.analytics,
    this.todayCheckin,
    this.currentOffset = 0,
  });

  MoodHistoryState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<MoodHistoryItem>? checkins,
    int? totalCount,
    bool? hasMore,
    MoodAnalyticsResponse? analytics,
    MoodHistoryItem? todayCheckin,
    int? currentOffset,
    bool clearError = false,
    bool clearTodayCheckin = false,
  }) {
    return MoodHistoryState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      checkins: checkins ?? this.checkins,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      analytics: analytics ?? this.analytics,
      todayCheckin: clearTodayCheckin ? null : (todayCheckin ?? this.todayCheckin),
      currentOffset: currentOffset ?? this.currentOffset,
    );
  }
}

/// Provider for mood history state
final moodHistoryProvider =
    StateNotifierProvider<MoodHistoryNotifier, MoodHistoryState>((ref) {
  return MoodHistoryNotifier(
    ref.watch(moodHistoryRepositoryProvider),
    ref.watch(authRepositoryProvider),
  );
});

/// Notifier for mood history state management
class MoodHistoryNotifier extends StateNotifier<MoodHistoryState> {
  final MoodHistoryRepository _repository;
  final AuthRepository _authRepository;

  MoodHistoryNotifier(this._repository, this._authRepository)
      : super(const MoodHistoryState());

  /// Initialize data by loading history and analytics
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        // Load history, analytics, and today's check-in in parallel
        final results = await Future.wait([
          _repository.getMoodHistory(userId: user.id, limit: 30),
          _repository.getMoodAnalytics(userId: user.id, days: 30),
          _repository.getTodayMood(userId: user.id),
        ]);

        final historyResponse = results[0] as MoodHistoryResponse;
        final analytics = results[1] as MoodAnalyticsResponse?;
        final todayCheckin = results[2] as MoodHistoryItem?;

        state = state.copyWith(
          isLoading: false,
          checkins: historyResponse.checkins,
          totalCount: historyResponse.totalCount,
          hasMore: historyResponse.hasMore,
          analytics: analytics,
          todayCheckin: todayCheckin,
          currentOffset: historyResponse.checkins.length,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'User not logged in',
        );
      }
    } catch (e) {
      debugPrint('Error initializing mood history: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more history (pagination)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        final response = await _repository.getMoodHistory(
          userId: user.id,
          limit: 30,
          offset: state.currentOffset,
        );

        state = state.copyWith(
          isLoadingMore: false,
          checkins: [...state.checkins, ...response.checkins],
          totalCount: response.totalCount,
          hasMore: response.hasMore,
          currentOffset: state.currentOffset + response.checkins.length,
        );
      }
    } catch (e) {
      debugPrint('Error loading more mood history: $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    state = state.copyWith(currentOffset: 0);
    await initialize();
  }

  /// Mark a workout as completed
  Future<bool> markWorkoutCompleted(String checkinId) async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        final success = await _repository.markWorkoutCompleted(
          userId: user.id,
          checkinId: checkinId,
        );

        if (success) {
          // Update local state
          final updatedCheckins = state.checkins.map((c) {
            if (c.id == checkinId) {
              return MoodHistoryItem(
                id: c.id,
                mood: c.mood,
                moodEmoji: c.moodEmoji,
                moodColor: c.moodColor,
                checkInTime: c.checkInTime,
                workoutGenerated: c.workoutGenerated,
                workoutCompleted: true,
                workout: c.workout,
                context: c.context,
              );
            }
            return c;
          }).toList();

          state = state.copyWith(checkins: updatedCheckins);
        }

        return success;
      }
      return false;
    } catch (e) {
      debugPrint('Error marking workout completed: $e');
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for mood analytics only (cached)
final moodAnalyticsProvider = FutureProvider<MoodAnalyticsResponse?>((ref) async {
  final repository = ref.watch(moodHistoryRepositoryProvider);
  final authRepository = ref.watch(authRepositoryProvider);

  final user = await authRepository.getCurrentUser();
  if (user != null) {
    return await repository.getMoodAnalytics(userId: user.id, days: 30);
  }
  return null;
});

/// Provider for today's mood check-in
final todayMoodCheckinProvider = FutureProvider<MoodHistoryItem?>((ref) async {
  final repository = ref.watch(moodHistoryRepositoryProvider);
  final authRepository = ref.watch(authRepositoryProvider);

  final user = await authRepository.getCurrentUser();
  if (user != null) {
    return await repository.getTodayMood(userId: user.id);
  }
  return null;
});
