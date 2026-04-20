part of 'nutrition_repository.dart';


/// Persistent (cross-launch) cache for the user's daily nutrition summary.
///
/// Backed by SharedPreferences so we don't need a Drift schema bump (which
/// would require running build_runner — pinned off per project rules). The
/// payload is a JSON-encoded `DailyNutritionSummary` keyed by user_id; we
/// also stamp the date so a stale Wednesday cache doesn't accidentally
/// render as Thursday data.
///
/// Used to power stale-while-revalidate on the Nutrition tab: cold-start
/// app open seeds `state.todaySummary` from disk synchronously so the UI
/// renders immediately, while the network refetch fires in parallel.
class _NutritionDiskCache {
  static const _prefix = 'nutrition_summary_v1::';

  static String _key(String userId) => '$_prefix$userId';

  static Future<DailyNutritionSummary?> read(String userId, String todayStr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null || raw.isEmpty) return null;
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      // Discard the cache if it's not for today's local date — yesterday's
      // numbers rendered as today's would be far worse than a quick skeleton.
      final cachedDate = envelope['date'] as String?;
      if (cachedDate != todayStr) return null;
      final body = envelope['summary'] as Map<String, dynamic>?;
      if (body == null) return null;
      return DailyNutritionSummary.fromJson(body);
    } catch (e) {
      debugPrint('🥗 [NutritionDiskCache] read failed: $e');
      return null;
    }
  }

  static Future<void> write(
    String userId,
    String todayStr,
    DailyNutritionSummary summary,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(userId),
        jsonEncode({
          'date': todayStr,
          'cached_at': DateTime.now().toIso8601String(),
          'summary': summary.toJson(),
        }),
      );
    } catch (e) {
      debugPrint('🥗 [NutritionDiskCache] write failed: $e');
    }
  }

  static Future<void> clear(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(userId));
    } catch (_) {/* best-effort */}
  }
}


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


/// Progress event for multi-image food analysis. Carries the raw backend
/// payload in [result] on completion so the caller can branch on
/// `analysis_type` ("plate" / "menu" / "buffet") and render appropriately.
class MultiImageAnalysisProgress {
  final int step;
  final int totalSteps;
  final String message;
  final String? detail;
  final int elapsedMs;

  /// Raw response payload from backend's `done` event. Includes:
  /// - `analysis_type`: "plate" | "menu" | "buffet"
  /// - `food_items`: flat list of dishes (for menu/buffet) or food items (plate)
  /// - `sections`, `suggested_plate`, `recommended_order`, `tips` (menu/buffet)
  /// - `food_log_id`, macros, `health_score`, `ai_suggestion` (plate auto-log)
  /// - `image_urls`, `storage_keys`, `mime_types`
  final Map<String, dynamic>? result;

  final bool isCompleted;
  final bool hasError;

  MultiImageAnalysisProgress({
    required this.step,
    required this.totalSteps,
    required this.message,
    this.detail,
    required this.elapsedMs,
    this.result,
    this.isCompleted = false,
    this.hasError = false,
  });

  double get progress => totalSteps > 0 ? step / totalSteps : 0;
  bool get isLoading => !isCompleted && !hasError;

  String? get analysisType => result?['analysis_type'] as String?;
  List<Map<String, dynamic>> get foodItems {
    final raw = result?['food_items'] as List? ?? const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  String toString() =>
      'MultiImageAnalysisProgress(step: $step/$totalSteps, type: $analysisType, message: $message)';
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

  /// Pre-seed state from bootstrap data so the home screen shows nutrition instantly.
  void preSeedFromBootstrap({
    required int calories,
    int? targetCalories,
    required double protein,
    required double carbs,
    required double fat,
    double? targetProtein,
    double? targetCarbs,
    double? targetFat,
  }) {
    if (state.todaySummary != null) return; // Don't overwrite real data
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    state = state.copyWith(
      todaySummary: DailyNutritionSummary(
        date: todayStr,
        totalCalories: calories,
        totalProteinG: protein,
        totalCarbsG: carbs,
        totalFatG: fat,
      ),
      targets: targetCalories != null ? NutritionTargets(
        userId: '',
        dailyCalorieTarget: targetCalories,
        dailyProteinTargetG: targetProtein ?? 0,
        dailyCarbsTargetG: targetCarbs ?? 0,
        dailyFatTargetG: targetFat ?? 0,
      ) : null,
    );
    debugPrint('⚡ [Nutrition] Pre-seeded from bootstrap');
  }

  /// Check if we should skip loading (data is fresh - less than 5 minutes old)
  bool _shouldSkipLoad(String userId) {
    if (_lastLoadedUserId != userId) return false;
    if (_lastLoadTime == null) return false;
    final elapsed = DateTime.now().difference(_lastLoadTime!);
    return elapsed.inMinutes < 5;  // Cache for 5 minutes to improve navigation speed
  }

  /// Load today's nutrition summary.
  ///
  /// Stale-while-revalidate flow:
  ///   1. In-memory cache hit (<5 min, same user) → return immediately,
  ///      clearing any leftover error so retry works.
  ///   2. Otherwise, if the in-memory state is empty, try the disk cache
  ///      (SharedPreferences, scoped to today's local date). On hit, render
  ///      that data instantly (no skeleton) and continue to the network
  ///      refresh in the background.
  ///   3. Otherwise, show the skeleton and wait for the network.
  ///   4. On network success, update state + write to disk for the next
  ///      cold start.
  ///   5. On network failure: if we're displaying any data (in-memory or
  ///      from disk), keep it and silently swallow the error. Only surface
  ///      the error banner when we have nothing else to show.
  Future<void> loadTodaySummary(String userId, {bool forceRefresh = false}) async {
    // (1) In-memory freshness short-circuit. Still clear stale error so
    // Try Again doesn't get stuck with the cache-skip path.
    if (!forceRefresh && _shouldSkipLoad(userId) && state.todaySummary != null) {
      debugPrint('🥗 [NutritionProvider] Skipping loadTodaySummary - data is fresh');
      if (state.error != null) {
        state = state.copyWith(error: null);
      }
      return;
    }

    final localDate = Tz.localDate();

    // (2) Disk seed. Only when in-memory is empty AND we're not force-
    // refreshing (force = user explicitly asked for fresh data).
    if (!forceRefresh && state.todaySummary == null) {
      // Set isLoading=true synchronously *before* yielding to the disk read,
      // so the first build frame shows the skeleton instead of an empty
      // TabBarView. The disk read is fast (~10ms) — either resolves to
      // cached data (skeleton replaced immediately) or stays as skeleton
      // until the network call below returns.
      state = state.copyWith(isLoading: true, error: null);
      final cached = await _NutritionDiskCache.read(userId, localDate);
      if (cached != null) {
        debugPrint('🥗 [NutritionProvider] Seeded from disk cache for $localDate');
        state = state.copyWith(
          isLoading: false,
          todaySummary: cached,
        );
      }
      // else: keep isLoading=true, the network call below will resolve it
    } else {
      // We already have data on screen; just clear any error so the network
      // call below can refresh silently without flashing the error banner.
      state = state.copyWith(error: null);
    }

    final stopwatch = Stopwatch()..start();
    try {
      // Pass local date to avoid UTC mismatch on server (Render runs in UTC)
      final summary = await _repository.getDailySummary(userId, date: localDate);
      debugPrint(
        '🥗 [NutritionProvider] loadTodaySummary network: ${stopwatch.elapsedMilliseconds}ms '
        '(meals=${summary.meals.length}, kcal=${summary.totalCalories})',
      );
      state = state.copyWith(isLoading: false, todaySummary: summary);
      _lastLoadedUserId = userId;
      _lastLoadTime = DateTime.now();

      // (4) Persist to disk for next cold start. Fire-and-forget — never
      // block the UI on disk I/O.
      unawaited(_NutritionDiskCache.write(userId, localDate, summary));

      // Check if protein goal was hit and award XP
      _checkProteinGoal(summary);
    } catch (e) {
      debugPrint(
        '🥗 [NutritionProvider] loadTodaySummary FAILED after ${stopwatch.elapsedMilliseconds}ms: $e',
      );
      // (5) Only surface the error if we have nothing on screen.
      if (state.todaySummary == null) {
        state = state.copyWith(isLoading: false, error: e.toString());
      } else {
        state = state.copyWith(isLoading: false);
      }
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

    _checkCalorieGoal(summary);
  }

  /// Fire the "calorie deficit" XP award when the user has logged the bulk of
  /// their day's food (>= 80% of target) AND stayed under their calorie
  /// target. The 80% floor prevents premature firing after a single small
  /// snack; the upper bound is the target itself since "less than target"
  /// defines the deficit. Idempotent per day via the provider.
  void _checkCalorieGoal(DailyNutritionSummary summary) {
    final targets = state.targets;
    if (targets == null) return;

    final caloriesConsumed = summary.totalCalories;
    final calorieTarget = targets.dailyCalorieTarget;
    if (calorieTarget == null || calorieTarget <= 0) return;

    final floor = (calorieTarget * 0.8).round();
    if (caloriesConsumed >= floor && caloriesConsumed < calorieTarget) {
      debugPrint('🎯 [NutritionProvider] Calorie deficit hit! $caloriesConsumed / $calorieTarget kcal');
      _ref.read(xpProvider.notifier).markCalorieGoalHit();
    }
  }

  /// Load nutrition summary for a specific date (used when navigating dates)
  Future<void> loadSummaryForDate(String userId, DateTime date) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final summary = await _repository.getDailySummary(userId, date: dateStr);
      state = state.copyWith(isLoading: false, todaySummary: summary);
      _lastLoadedUserId = userId;
      _lastLoadTime = DateTime.now();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load food logs for a specific date
  Future<void> loadLogsForDate(String userId, DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final logs = await _repository.getFoodLogs(userId, fromDate: dateStr, toDate: dateStr);
      state = state.copyWith(recentLogs: logs);
    } catch (e) {
      debugPrint('Error loading food logs for date: $e');
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
      // Force-refresh: without this, the cache-skip in loadTodaySummary
      // returns immediately and the deleted meal stays visible in the UI.
      // The disk cache is overwritten by loadTodaySummary's success path,
      // so the next cold start won't re-render the deleted meal either.
      await loadTodaySummary(userId, forceRefresh: true);
      await loadRecentLogs(userId, forceRefresh: true);
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

