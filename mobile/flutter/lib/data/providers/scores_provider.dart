import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scores.dart';
import '../repositories/scores_repository.dart';

// ============================================
// Scores State
// ============================================

/// Complete scores state including readiness, strength, and PRs
class ScoresState {
  final ScoresOverview? overview;
  final ReadinessScore? todayReadiness;
  final ReadinessHistory? readinessHistory;
  final AllStrengthScores? strengthScores;
  final PRStats? prStats;
  final StrengthDetail? selectedMuscleDetail;
  final bool isLoading;
  final bool isSubmittingReadiness;
  final String? error;

  const ScoresState({
    this.overview,
    this.todayReadiness,
    this.readinessHistory,
    this.strengthScores,
    this.prStats,
    this.selectedMuscleDetail,
    this.isLoading = false,
    this.isSubmittingReadiness = false,
    this.error,
  });

  ScoresState copyWith({
    ScoresOverview? overview,
    ReadinessScore? todayReadiness,
    ReadinessHistory? readinessHistory,
    AllStrengthScores? strengthScores,
    PRStats? prStats,
    StrengthDetail? selectedMuscleDetail,
    bool? isLoading,
    bool? isSubmittingReadiness,
    String? error,
    bool clearError = false,
    bool clearTodayReadiness = false,
    bool clearMuscleDetail = false,
  }) {
    return ScoresState(
      overview: overview ?? this.overview,
      todayReadiness:
          clearTodayReadiness ? null : (todayReadiness ?? this.todayReadiness),
      readinessHistory: readinessHistory ?? this.readinessHistory,
      strengthScores: strengthScores ?? this.strengthScores,
      prStats: prStats ?? this.prStats,
      selectedMuscleDetail: clearMuscleDetail
          ? null
          : (selectedMuscleDetail ?? this.selectedMuscleDetail),
      isLoading: isLoading ?? this.isLoading,
      isSubmittingReadiness:
          isSubmittingReadiness ?? this.isSubmittingReadiness,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Check if user has checked in today
  bool get hasCheckedInToday =>
      overview?.hasCheckedInToday ?? todayReadiness != null;

  /// Get overall readiness score (0-100)
  int get readinessScore =>
      todayReadiness?.readinessScore ??
      overview?.todayReadiness?.readinessScore ??
      0;

  /// Get overall strength score (0-100)
  int get overallStrengthScore =>
      strengthScores?.overallScore ?? overview?.overallStrengthScore ?? 0;

  /// Get 7-day readiness average
  double? get readinessAverage7Days =>
      readinessHistory?.averageScore ?? overview?.readinessAverage7Days;

  /// Get PR count in last 30 days
  int get prCount30Days =>
      prStats?.prsThisPeriod ?? overview?.prCount30Days ?? 0;
}

// ============================================
// Scores Notifier
// ============================================

class ScoresNotifier extends StateNotifier<ScoresState> {
  final ScoresRepository _repository;
  String? _currentUserId;

  ScoresNotifier(this._repository) : super(const ScoresState());

  /// Set user ID for this session
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  /// Load all scores data (overview)
  Future<void> loadScoresOverview({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('⚠️ [ScoresProvider] No user ID, skipping load');
      return;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final overview = await _repository.getScoresOverview(userId: uid);
      state = state.copyWith(
        overview: overview,
        todayReadiness: overview.todayReadiness,
        isLoading: false,
      );
      debugPrint('✅ [ScoresProvider] Loaded scores overview');
    } catch (e) {
      debugPrint('❌ [ScoresProvider] Error loading overview: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load scores: $e',
      );
    }
  }

  /// Submit readiness check-in
  Future<ReadinessScore?> submitReadinessCheckIn({
    required String userId,
    required int sleepQuality,
    required int fatigueLevel,
    required int stressLevel,
    required int muscleSoreness,
    int? mood,
    int? energyLevel,
  }) async {
    _currentUserId = userId;
    state = state.copyWith(isSubmittingReadiness: true, clearError: true);

    try {
      final readiness = await _repository.submitReadinessCheckIn(
        userId: userId,
        sleepQuality: sleepQuality,
        fatigueLevel: fatigueLevel,
        stressLevel: stressLevel,
        muscleSoreness: muscleSoreness,
        mood: mood,
        energyLevel: energyLevel,
      );

      state = state.copyWith(
        todayReadiness: readiness,
        isSubmittingReadiness: false,
      );

      debugPrint('✅ [ScoresProvider] Submitted readiness check-in');
      return readiness;
    } catch (e) {
      debugPrint('❌ [ScoresProvider] Error submitting check-in: $e');
      state = state.copyWith(
        isSubmittingReadiness: false,
        error: 'Failed to submit check-in: $e',
      );
      return null;
    }
  }

  /// Load readiness history
  Future<void> loadReadinessHistory({String? userId, int days = 30}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final history = await _repository.getReadinessHistory(
        userId: uid,
        days: days,
      );
      state = state.copyWith(readinessHistory: history);
      debugPrint('✅ [ScoresProvider] Loaded readiness history');
    } catch (e) {
      debugPrint('❌ [ScoresProvider] Error loading readiness history: $e');
      state = state.copyWith(error: 'Failed to load history: $e');
    }
  }

  /// Load all strength scores
  Future<void> loadStrengthScores({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final scores = await _repository.getAllStrengthScores(userId: uid);
      state = state.copyWith(
        strengthScores: scores,
        isLoading: false,
      );
      debugPrint('✅ [ScoresProvider] Loaded strength scores');
    } catch (e) {
      debugPrint('❌ [ScoresProvider] Error loading strength scores: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load strength scores: $e',
      );
    }
  }

  /// Load strength detail for a specific muscle group
  Future<void> loadMuscleDetail(String muscleGroup, {String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearMuscleDetail: true);

    try {
      final detail = await _repository.getStrengthDetail(
        userId: uid,
        muscleGroup: muscleGroup,
      );
      state = state.copyWith(
        selectedMuscleDetail: detail,
        isLoading: false,
      );
      debugPrint('✅ [ScoresProvider] Loaded muscle detail for $muscleGroup');
    } catch (e) {
      debugPrint('❌ [ScoresProvider] Error loading muscle detail: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load muscle detail: $e',
      );
    }
  }

  /// Recalculate strength scores
  Future<void> recalculateStrengthScores({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.calculateStrengthScores(userId: uid);
      // Reload after calculation
      await loadStrengthScores(userId: uid);
      debugPrint('✅ [ScoresProvider] Recalculated strength scores');
    } catch (e) {
      debugPrint('❌ [ScoresProvider] Error recalculating: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to recalculate: $e',
      );
    }
  }

  /// Load personal records
  Future<void> loadPersonalRecords({String? userId, int limit = 10, int periodDays = 30}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final stats = await _repository.getPersonalRecords(
        userId: uid,
        limit: limit,
        periodDays: periodDays,
      );
      state = state.copyWith(prStats: stats);
      debugPrint('✅ [ScoresProvider] Loaded personal records');
    } catch (e) {
      debugPrint('❌ [ScoresProvider] Error loading PRs: $e');
      state = state.copyWith(error: 'Failed to load PRs: $e');
    }
  }

  /// Clear any errors
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refresh all data
  Future<void> refresh({String? userId}) async {
    await loadScoresOverview(userId: userId);
  }
}

// ============================================
// Providers
// ============================================

/// Main scores provider
final scoresProvider =
    StateNotifierProvider<ScoresNotifier, ScoresState>((ref) {
  final repository = ref.watch(scoresRepositoryProvider);
  return ScoresNotifier(repository);
});

/// Readiness score for today (convenience provider)
final todayReadinessProvider = Provider<ReadinessScore?>((ref) {
  return ref.watch(scoresProvider).todayReadiness;
});

/// Has checked in today (convenience provider)
final hasCheckedInTodayProvider = Provider<bool>((ref) {
  return ref.watch(scoresProvider).hasCheckedInToday;
});

/// Overall strength score (convenience provider)
final overallStrengthScoreProvider = Provider<int>((ref) {
  return ref.watch(scoresProvider).overallStrengthScore;
});

/// Strength scores by muscle group (convenience provider)
final muscleScoresProvider =
    Provider<Map<String, StrengthScoreData>>((ref) {
  return ref.watch(scoresProvider).strengthScores?.muscleScores ?? {};
});

/// PR stats (convenience provider)
final prStatsProvider = Provider<PRStats?>((ref) {
  return ref.watch(scoresProvider).prStats;
});

/// Scores loading state (convenience provider)
final scoresLoadingProvider = Provider<bool>((ref) {
  return ref.watch(scoresProvider).isLoading;
});

/// Scores error (convenience provider)
final scoresErrorProvider = Provider<String?>((ref) {
  return ref.watch(scoresProvider).error;
});
