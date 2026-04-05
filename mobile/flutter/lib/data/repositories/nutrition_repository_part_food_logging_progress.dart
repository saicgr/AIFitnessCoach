part of 'nutrition_repository.dart';


/// Progress event for streaming food logging
class FoodLoggingProgress {
  /// Current step number (1-indexed)
  final int step;

  /// Total number of steps
  final int totalSteps;

  /// Human-readable status message
  final String message;

  /// Additional detail about the current step
  final String? detail;

  /// Time elapsed since start in milliseconds
  final int elapsedMs;

  /// The logged food response (only set when complete)
  final LogFoodResponse? foodLog;

  /// Whether logging completed successfully
  final bool isCompleted;

  /// Whether an error occurred
  final bool hasError;

  /// Whether this is an analysis-only result (not yet saved to database)
  final bool isAnalysisOnly;

  FoodLoggingProgress({
    required this.step,
    required this.totalSteps,
    required this.message,
    this.detail,
    required this.elapsedMs,
    this.foodLog,
    this.isCompleted = false,
    this.hasError = false,
    this.isAnalysisOnly = false,
  });

  /// Progress as a percentage (0.0 to 1.0)
  double get progress => totalSteps > 0 ? step / totalSteps : 0;

  /// Whether logging is still in progress
  bool get isLoading => !isCompleted && !hasError;

  @override
  String toString() => 'FoodLoggingProgress(step: $step/$totalSteps, message: $message, elapsedMs: $elapsedMs)';
}


/// Nutrition state
class NutritionState {
  final bool isLoading;
  final String? error;
  final DailyNutritionSummary? todaySummary;
  final NutritionTargets? targets;
  final List<FoodLog> recentLogs;

  const NutritionState({
    this.isLoading = false,
    this.error,
    this.todaySummary,
    this.targets,
    this.recentLogs = const [],
  });

  NutritionState copyWith({
    bool? isLoading,
    String? error,
    DailyNutritionSummary? todaySummary,
    NutritionTargets? targets,
    List<FoodLog>? recentLogs,
  }) {
    return NutritionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      todaySummary: todaySummary ?? this.todaySummary,
      targets: targets ?? this.targets,
      recentLogs: recentLogs ?? this.recentLogs,
    );
  }
}


/// Nutrition state notifier
class NutritionNotifier extends StateNotifier<NutritionState> {
  final NutritionRepository _repository;
  final Ref _ref;
  String? _lastLoadedUserId;  // Track which user data is loaded for
  DateTime? _lastLoadTime;     // Track when data was last loaded

  NutritionNotifier(this._repository, this._ref) : super(const NutritionState());

  /// Check if we should skip loading (data is fresh - less than 5 minutes old)
  bool _shouldSkipLoad(String userId) {
    if (_lastLoadedUserId != userId) return false;
    if (_lastLoadTime == null) return false;
    final elapsed = DateTime.now().difference(_lastLoadTime!);
    return elapsed.inMinutes < 5;  // Cache for 5 minutes to improve navigation speed
  }

  /// Load today's nutrition summary
  Future<void> loadTodaySummary(String userId, {bool forceRefresh = false}) async {
    // Skip if data is fresh (prevents redundant calls on tab switch)
    if (!forceRefresh && _shouldSkipLoad(userId) && state.todaySummary != null) {
      debugPrint('🥗 [NutritionProvider] Skipping loadTodaySummary - data is fresh');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      // Pass local date to avoid UTC mismatch on server (Render runs in UTC)
      final localDate = DateTime.now().toIso8601String().substring(0, 10);
      final summary = await _repository.getDailySummary(userId, date: localDate);
      state = state.copyWith(isLoading: false, todaySummary: summary);
      _lastLoadedUserId = userId;
      _lastLoadTime = DateTime.now();

      // Check if protein goal was hit and award XP
      _checkProteinGoal(summary);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Check if user hit their daily protein goal and award XP
  void _checkProteinGoal(DailyNutritionSummary summary) {
    final targets = state.targets;
    if (targets == null) return;

    final proteinConsumed = summary.totalProteinG ?? 0;
    final proteinTarget = targets.dailyProteinTargetG ?? 150;

    if (proteinConsumed >= proteinTarget) {
      debugPrint('🎯 [NutritionProvider] Protein goal hit! ${proteinConsumed.toInt()}g / ${proteinTarget.toInt()}g');
      // Award XP - the provider handles duplicate prevention
      _ref.read(xpProvider.notifier).markProteinGoalHit();
    }
  }

  /// Load nutrition targets
  Future<void> loadTargets(String userId, {bool forceRefresh = false}) async {
    // Skip if data is fresh
    if (!forceRefresh && _shouldSkipLoad(userId) && state.targets != null) {
      return;
    }

    try {
      final targets = await _repository.getTargets(userId);
      state = state.copyWith(targets: targets);
    } catch (e) {
      debugPrint('Error loading nutrition targets: $e');
    }
  }

  /// Load recent food logs
  Future<void> loadRecentLogs(String userId, {int limit = 50, bool forceRefresh = false}) async {
    // Skip if data is fresh
    if (!forceRefresh && _shouldSkipLoad(userId) && state.recentLogs.isNotEmpty) {
      debugPrint('🥗 [NutritionProvider] Skipping loadRecentLogs - data is fresh');
      return;
    }

    try {
      final logs = await _repository.getFoodLogs(userId, limit: limit);
      state = state.copyWith(recentLogs: logs);
    } catch (e) {
      debugPrint('Error loading recent food logs: $e');
    }
  }

  /// Force refresh all data (use after logging a meal, etc.)
  Future<void> refreshAll(String userId) async {
    _lastLoadTime = null;  // Clear cache
    await Future.wait([
      loadTodaySummary(userId, forceRefresh: true),
      loadTargets(userId, forceRefresh: true),
      loadRecentLogs(userId, forceRefresh: true),
    ]);
  }

  /// Delete a food log
  Future<void> deleteLog(String userId, String logId) async {
    try {
      await _repository.deleteFoodLog(logId);
      await loadTodaySummary(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update nutrition targets
  Future<void> updateTargets(
    String userId, {
    int? calorieTarget,
    double? proteinTarget,
    double? carbsTarget,
    double? fatTarget,
  }) async {
    try {
      await _repository.updateTargets(
        userId,
        calorieTarget: calorieTarget,
        proteinTarget: proteinTarget,
        carbsTarget: carbsTarget,
        fatTarget: fatTarget,
      );
      await loadTargets(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}


/// Combined data for the enhanced weekly check-in screen
class WeeklyCheckinData {
  final DetailedTDEE? detailedTdee;
  final AdherenceSummary? adherenceSummary;
  final RecommendationOptions? recommendationOptions;
  final WeeklySummaryData? weeklySummary;

  const WeeklyCheckinData({
    this.detailedTdee,
    this.adherenceSummary,
    this.recommendationOptions,
    this.weeklySummary,
  });

  /// Check if we have enough data for a meaningful check-in
  bool get hasEnoughData =>
      detailedTdee != null ||
      adherenceSummary != null ||
      recommendationOptions != null;

  /// Check if metabolic adaptation was detected
  bool get hasMetabolicAdaptation =>
      detailedTdee?.hasAdaptation ?? false;

  /// Get the current sustainability rating
  String? get sustainabilityRating =>
      adherenceSummary?.sustainabilityRating;

  /// Check if there are multiple recommendation options
  bool get hasMultipleOptions =>
      (recommendationOptions?.options.length ?? 0) > 1;
}

