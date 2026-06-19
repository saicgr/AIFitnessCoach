import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import '../models/scores.dart';
import '../repositories/scores_repository.dart';
import '../repositories/auth_repository.dart';
import '../services/data_cache_service.dart';

/// In-memory cache for instant display on provider recreation
/// Survives provider invalidation and prevents loading flash
ScoresState? _scoresInMemoryCache;

/// Disk cache keys (12h TTL via `statsKeyPrefix`). Cache the RAW model JSON so
/// a cold start paints last-known scores instantly without a network round-trip.
const String _scoresOverviewCacheKey =
    '${DataCacheService.statsKeyPrefix}scores';
const String _readinessHistoryCacheKey =
    '${DataCacheService.statsKeyPrefix}readiness_history';
const String _strengthScoresCacheKey =
    '${DataCacheService.statsKeyPrefix}strength_scores';

/// Tracks the user_id this static cache belongs to, so we can flush it on a
/// real account switch (sign-out → sign-in different account) and avoid the
/// new user inheriting the prior user's scores.
String? _scoresCacheOwnerUserId;

// ============================================
// Scores State
// ============================================

/// Complete scores state including readiness, strength, nutrition, fitness, and PRs
class ScoresState {
  final ScoresOverview? overview;
  final ReadinessScore? todayReadiness;
  final ReadinessHistory? readinessHistory;
  final AllStrengthScores? strengthScores;
  final PRStats? prStats;
  final DotsScore? dotsScore;
  final StrengthDetail? selectedMuscleDetail;
  final NutritionScoreData? nutritionScore;
  final FitnessScoreBreakdown? fitnessScore;
  final bool isLoading;
  final bool isSubmittingReadiness;
  final bool isCalculatingNutrition;
  final bool isCalculatingFitness;
  final String? error;

  const ScoresState({
    this.overview,
    this.todayReadiness,
    this.readinessHistory,
    this.strengthScores,
    this.prStats,
    this.dotsScore,
    this.selectedMuscleDetail,
    this.nutritionScore,
    this.fitnessScore,
    this.isLoading = false,
    this.isSubmittingReadiness = false,
    this.isCalculatingNutrition = false,
    this.isCalculatingFitness = false,
    this.error,
  });

  ScoresState copyWith({
    ScoresOverview? overview,
    ReadinessScore? todayReadiness,
    ReadinessHistory? readinessHistory,
    AllStrengthScores? strengthScores,
    PRStats? prStats,
    DotsScore? dotsScore,
    StrengthDetail? selectedMuscleDetail,
    NutritionScoreData? nutritionScore,
    FitnessScoreBreakdown? fitnessScore,
    bool? isLoading,
    bool? isSubmittingReadiness,
    bool? isCalculatingNutrition,
    bool? isCalculatingFitness,
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
      dotsScore: dotsScore ?? this.dotsScore,
      selectedMuscleDetail: clearMuscleDetail
          ? null
          : (selectedMuscleDetail ?? this.selectedMuscleDetail),
      nutritionScore: nutritionScore ?? this.nutritionScore,
      fitnessScore: fitnessScore ?? this.fitnessScore,
      isLoading: isLoading ?? this.isLoading,
      isSubmittingReadiness:
          isSubmittingReadiness ?? this.isSubmittingReadiness,
      isCalculatingNutrition:
          isCalculatingNutrition ?? this.isCalculatingNutrition,
      isCalculatingFitness:
          isCalculatingFitness ?? this.isCalculatingFitness,
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

  /// Get nutrition score (0-100)
  int get nutritionScoreValue =>
      nutritionScore?.overallScore ?? overview?.nutritionScore ?? 0;

  /// Get nutrition level (needs_work, fair, good, excellent)
  NutritionLevel get nutritionLevel =>
      nutritionScore?.level ?? overview?.nutritionLevelEnum ?? NutritionLevel.needsWork;

  /// Get overall fitness score (0-100)
  int get overallFitnessScore =>
      fitnessScore?.overallScore ?? overview?.overallFitnessScore ?? 0;

  /// Get fitness level (beginner, developing, fit, athletic, elite)
  FitnessLevel get fitnessLevel =>
      fitnessScore?.level ?? overview?.fitnessLevelEnum ?? FitnessLevel.beginner;

  /// Get consistency score (0-100)
  int get consistencyScore =>
      fitnessScore?.consistencyScore ?? overview?.consistencyScore ?? 0;
}

// ============================================
// Scores Notifier
// ============================================

class ScoresNotifier extends StateNotifier<ScoresState> {
  final ScoresRepository _repository;
  String? _currentUserId;

  ScoresNotifier(this._repository)
      : super(_scoresInMemoryCache ?? const ScoresState());

  /// Clear in-memory cache (called on logout)
  static void clearCache() {
    _scoresInMemoryCache = null;
    debugPrint('🧹 [ScoresProvider] In-memory cache cleared');
  }

  /// Set user ID for this session
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  /// Cold-start disk seed. Paints last-known overview + readiness history
  /// instantly (even if expired) before any network call, so the Stats section
  /// shows real prior numbers rather than a wall of skeletons. No-op when the
  /// in-memory cache already holds richer data for this session.
  Future<void> seedFromDisk({String? userId}) async {
    final uid = userId ??
        Supabase.instance.client.auth.currentUser?.id ??
        _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    // Only seed slices we don't already have in memory.
    final needOverview = state.overview == null;
    final needHistory = state.readinessHistory == null;
    final needStrength = state.strengthScores == null;
    if (!needOverview && !needHistory && !needStrength) return;

    try {
      if (needOverview) {
        final cached = await DataCacheService.instance.getCached(
          _scoresOverviewCacheKey,
          userId: uid,
          returnExpiredOnMiss: true,
        );
        if (cached != null && state.overview == null) {
          final overview = ScoresOverview.fromJson(cached);
          state = state.copyWith(
            overview: overview,
            todayReadiness: overview.todayReadiness,
          );
          _scoresInMemoryCache = state;
          debugPrint('⚡ [ScoresProvider] Seeded overview from disk');
        }
      }
      if (needHistory) {
        final cached = await DataCacheService.instance.getCached(
          _readinessHistoryCacheKey,
          userId: uid,
          returnExpiredOnMiss: true,
        );
        if (cached != null && state.readinessHistory == null) {
          state = state.copyWith(
            readinessHistory: ReadinessHistory.fromJson(cached),
          );
          _scoresInMemoryCache = state;
          debugPrint('⚡ [ScoresProvider] Seeded readiness history from disk');
        }
      }
      if (needStrength) {
        final cached = await DataCacheService.instance.getCached(
          _strengthScoresCacheKey,
          userId: uid,
          returnExpiredOnMiss: true,
        );
        if (cached != null && state.strengthScores == null) {
          state = state.copyWith(
            strengthScores: AllStrengthScores.fromJson(cached),
          );
          _scoresInMemoryCache = state;
          debugPrint('⚡ [ScoresProvider] Seeded strength scores from disk');
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ScoresProvider] Disk seed failed: $e');
    }
  }

  // In-flight + freshness guards for loadScoresOverview. Multiple home cards
  // (readiness / body metrics / fitness score) each fire a load from their
  // initState — without these guards a cold start made 3 identical network
  // calls and churned isLoading across every scores watcher.
  Future<void>? _overviewInFlight;
  String? _overviewInFlightUid;
  DateTime? _overviewLoadedAt;
  static const _overviewFreshness = Duration(seconds: 30);

  /// Load all scores data (overview).
  ///
  /// Concurrent callers for the same user share one in-flight request, and a
  /// successful load is considered fresh for [_overviewFreshness] — repeat
  /// calls inside that window are no-ops. Pass [force] to bypass freshness
  /// (pull-to-refresh, post-workout, post-check-in).
  Future<void> loadScoresOverview({String? userId, bool force = false}) {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('⚠️ [ScoresProvider] No user ID, skipping load');
      return Future.value();
    }
    // Same-user load already in flight — share it (a force call still
    // benefits: the in-flight request returns data at least as fresh).
    final inFlight = _overviewInFlight;
    if (inFlight != null && _overviewInFlightUid == uid) {
      debugPrint('⏳ [ScoresProvider] Overview load in flight — sharing');
      return inFlight;
    }
    // Freshness short-circuit (skipped on force / user switch / no data yet).
    if (!force &&
        _currentUserId == uid &&
        state.overview != null &&
        _overviewLoadedAt != null &&
        DateTime.now().difference(_overviewLoadedAt!) < _overviewFreshness) {
      return Future.value();
    }
    _currentUserId = uid;
    _overviewInFlightUid = uid;
    final future = _doLoadScoresOverview(uid).whenComplete(() {
      _overviewInFlight = null;
      _overviewInFlightUid = null;
    });
    _overviewInFlight = future;
    return future;
  }

  Future<void> _doLoadScoresOverview(String uid) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final overview = await _repository.getScoresOverview(userId: uid);
      state = state.copyWith(
        overview: overview,
        todayReadiness: overview.todayReadiness,
        isLoading: false,
      );
      _overviewLoadedAt = DateTime.now();
      // Update in-memory cache for instant access on provider recreation
      _scoresInMemoryCache = state;
      // Write-through to disk so the next cold start paints instantly.
      await DataCacheService.instance
          .cache(_scoresOverviewCacheKey, overview.toJson(), userId: uid);
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
      _scoresInMemoryCache = state;
      // Write-through to disk for instant cold-start paint.
      await DataCacheService.instance
          .cache(_readinessHistoryCacheKey, history.toJson(), userId: uid);
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
      _scoresInMemoryCache = state;
      // Write-through to disk so the Home strength bars paint instantly from
      // cache on the next cold start (the breakdown widget reads
      // `muscleScoresProvider`, which is only populated here — without this it
      // showed an empty bar list until a /stats round-trip).
      await DataCacheService.instance
          .cache(_strengthScoresCacheKey, scores.toJson(), userId: uid);
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

  // ============================================
  // DOTS / Wilks Score Methods
  // ============================================

  /// Load DOTS and Wilks scores
  Future<void> loadDotsScore({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final score = await _repository.getDotsScore(userId: uid);
      state = state.copyWith(dotsScore: score);
      debugPrint('✅ [ScoresProvider] Loaded DOTS score: ${score.dotsScore}');
    } catch (e) {
      debugPrint('❌ [ScoresProvider] Error loading DOTS score: $e');
    }
  }

  // ============================================
  // Nutrition Score Methods
  // ============================================

  /// Load nutrition score
  Future<void> loadNutritionScore({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final score = await _repository.getNutritionScore(userId: uid);
      state = state.copyWith(nutritionScore: score);
      debugPrint('✅ [ScoresProvider] Loaded nutrition score: ${score.overallScore}');
    } catch (e) {
      debugPrint('❌ [ScoresProvider] Error loading nutrition score: $e');
      state = state.copyWith(error: 'Failed to load nutrition score: $e');
    }
  }

  /// Calculate/recalculate nutrition score
  Future<NutritionScoreData?> calculateNutritionScore({
    String? userId,
    int? weekNumber,
    int? year,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return null;
    _currentUserId = uid;

    state = state.copyWith(isCalculatingNutrition: true, clearError: true);

    try {
      final score = await _repository.calculateNutritionScore(
        userId: uid,
        weekNumber: weekNumber,
        year: year,
      );
      state = state.copyWith(
        nutritionScore: score,
        isCalculatingNutrition: false,
      );
      debugPrint('✅ [ScoresProvider] Calculated nutrition score: ${score.overallScore}');
      return score;
    } catch (e) {
      debugPrint('❌ [ScoresProvider] Error calculating nutrition score: $e');
      state = state.copyWith(
        isCalculatingNutrition: false,
        error: 'Failed to calculate nutrition score: $e',
      );
      return null;
    }
  }

  // ============================================
  // Fitness Score Methods
  // ============================================

  /// Load overall fitness score with breakdown
  Future<void> loadFitnessScore({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final score = await _repository.getFitnessScore(userId: uid);
      state = state.copyWith(fitnessScore: score);
      debugPrint('✅ [ScoresProvider] Loaded fitness score: ${score.overallScore}');
    } catch (e) {
      debugPrint('❌ [ScoresProvider] Error loading fitness score: $e');
      state = state.copyWith(error: 'Failed to load fitness score: $e');
    }
  }

  /// Calculate/recalculate overall fitness score
  Future<FitnessScoreBreakdown?> calculateFitnessScore({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return null;
    _currentUserId = uid;

    state = state.copyWith(isCalculatingFitness: true, clearError: true);

    try {
      final score = await _repository.calculateFitnessScore(userId: uid);
      state = state.copyWith(
        fitnessScore: score,
        isCalculatingFitness: false,
      );
      debugPrint('✅ [ScoresProvider] Calculated fitness score: ${score.overallScore}');
      return score;
    } catch (e) {
      debugPrint('❌ [ScoresProvider] Error calculating fitness score: $e');
      state = state.copyWith(
        isCalculatingFitness: false,
        error: 'Failed to calculate fitness score: $e',
      );
      return null;
    }
  }

  /// Load all scores (overview + detailed scores)
  Future<void> loadAllScores({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('⚠️ [ScoresProvider] No user ID, skipping load all');
      return;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Load overview first
      final overview = await _repository.getScoresOverview(userId: uid);
      state = state.copyWith(
        overview: overview,
        todayReadiness: overview.todayReadiness,
      );
      _scoresInMemoryCache = state;
      // Write-through to disk so the next cold start paints instantly.
      await DataCacheService.instance
          .cache(_scoresOverviewCacheKey, overview.toJson(), userId: uid);

      // Load detailed scores in parallel
      await Future.wait([
        loadNutritionScore(userId: uid),
        loadFitnessScore(userId: uid),
        loadStrengthScores(userId: uid),
        loadPersonalRecords(userId: uid),
      ]);

      state = state.copyWith(isLoading: false);
      debugPrint('✅ [ScoresProvider] Loaded all scores');
    } catch (e) {
      debugPrint('❌ [ScoresProvider] Error loading all scores: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load scores: $e',
      );
    }
  }

  /// Clear any errors
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refresh all data
  Future<void> refresh({String? userId}) async {
    await loadScoresOverview(userId: userId, force: true);
  }

  /// Refresh all scores (detailed)
  Future<void> refreshAll({String? userId}) async {
    await loadAllScores(userId: userId);
  }
}

// ============================================
// Providers
// ============================================

/// Main scores provider
final scoresProvider =
    StateNotifierProvider<ScoresNotifier, ScoresState>((ref) {
  final repository = ref.watch(scoresRepositoryProvider);
  // Watch user_id only — full AuthState churns on token refresh. Flush the
  // static in-memory cache on a real account switch so the new user doesn't
  // inherit the prior user's scores.
  final userId = ref.watch(authStateProvider.select((s) => s.user?.id));
  if (userId != null && userId != _scoresCacheOwnerUserId) {
    _scoresCacheOwnerUserId = userId;
    _scoresInMemoryCache = null;
  }
  return ScoresNotifier(repository);
});

// Convenience providers — each uses `.select()` so a watcher only rebuilds
// when its specific slice of `ScoresState` changes. Without `.select()`, every
// derived provider rebuilds on any state mutation (e.g. setting `isLoading`
// true would invalidate every score widget on the Scores tab).

/// Readiness score for today (convenience provider)
final todayReadinessProvider = Provider<ReadinessScore?>((ref) {
  return ref.watch(scoresProvider.select((s) => s.todayReadiness));
});

/// Has checked in today (convenience provider)
final hasCheckedInTodayProvider = Provider<bool>((ref) {
  return ref.watch(scoresProvider.select((s) => s.hasCheckedInToday));
});

/// Overall strength score (convenience provider)
final overallStrengthScoreProvider = Provider<int>((ref) {
  return ref.watch(scoresProvider.select((s) => s.overallStrengthScore));
});

/// Strength scores by muscle group (convenience provider)
final muscleScoresProvider =
    Provider<Map<String, StrengthScoreData>>((ref) {
  return ref.watch(scoresProvider
      .select((s) => s.strengthScores?.muscleScores ?? const {}));
});

/// PR stats (convenience provider)
final prStatsProvider = Provider<PRStats?>((ref) {
  return ref.watch(scoresProvider.select((s) => s.prStats));
});

/// Scores loading state (convenience provider)
final scoresLoadingProvider = Provider<bool>((ref) {
  return ref.watch(scoresProvider.select((s) => s.isLoading));
});

/// Scores error (convenience provider)
final scoresErrorProvider = Provider<String?>((ref) {
  return ref.watch(scoresProvider.select((s) => s.error));
});

/// Nutrition score (convenience provider)
final nutritionScoreProvider = Provider<int>((ref) {
  return ref.watch(scoresProvider.select((s) => s.nutritionScoreValue));
});

/// Nutrition level (convenience provider)
final nutritionLevelProvider = Provider<NutritionLevel>((ref) {
  return ref.watch(scoresProvider.select((s) => s.nutritionLevel));
});

/// Nutrition score data (convenience provider)
final nutritionScoreDataProvider = Provider<NutritionScoreData?>((ref) {
  return ref.watch(scoresProvider.select((s) => s.nutritionScore));
});

/// Overall fitness score (convenience provider)
final fitnessScoreProvider = Provider<int>((ref) {
  return ref.watch(scoresProvider.select((s) => s.overallFitnessScore));
});

/// Fitness level (convenience provider)
final fitnessLevelProvider = Provider<FitnessLevel>((ref) {
  return ref.watch(scoresProvider.select((s) => s.fitnessLevel));
});

/// Fitness score breakdown (convenience provider)
final fitnessScoreBreakdownProvider = Provider<FitnessScoreBreakdown?>((ref) {
  return ref.watch(scoresProvider.select((s) => s.fitnessScore));
});

/// Consistency score (convenience provider)
final consistencyScoreProvider = Provider<int>((ref) {
  return ref.watch(scoresProvider.select((s) => s.consistencyScore));
});

/// Whether nutrition score is being calculated (convenience provider)
final isCalculatingNutritionProvider = Provider<bool>((ref) {
  return ref.watch(scoresProvider.select((s) => s.isCalculatingNutrition));
});

/// Whether fitness score is being calculated (convenience provider)
final isCalculatingFitnessProvider = Provider<bool>((ref) {
  return ref.watch(scoresProvider.select((s) => s.isCalculatingFitness));
});
