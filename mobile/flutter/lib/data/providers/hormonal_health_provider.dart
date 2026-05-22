import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hormonal_health.dart';
import '../repositories/hormonal_health_repository.dart';
import '../../core/providers/user_provider.dart';
import '../../services/cycle/cycle_predictor.dart';

// ============================================================================
// HORMONAL PROFILE PROVIDERS
// ============================================================================

/// Provider for user's hormonal profile
final hormonalProfileProvider = FutureProvider.autoDispose<HormonalProfile?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;

  final repository = ref.watch(hormonalHealthRepositoryProvider);
  return repository.getProfile(user.id);
});

/// State notifier for managing hormonal profile updates
class HormonalProfileNotifier extends StateNotifier<AsyncValue<HormonalProfile?>> {
  final HormonalHealthRepository _repository;
  final String _userId;

  HormonalProfileNotifier(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.getProfile(_userId);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final updated = await _repository.upsertProfile(_userId, data);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _loadProfile();
  }
}

final hormonalProfileNotifierProvider = StateNotifierProvider.autoDispose
    .family<HormonalProfileNotifier, AsyncValue<HormonalProfile?>, String>(
  (ref, userId) {
    final repository = ref.watch(hormonalHealthRepositoryProvider);
    return HormonalProfileNotifier(repository, userId);
  },
);

// ============================================================================
// HORMONE LOGS PROVIDERS
// ============================================================================

/// Provider for hormone logs
final hormoneLogsProvider = FutureProvider.autoDispose
    .family<List<HormoneLog>, ({String userId, int days})>((ref, params) async {
  final repository = ref.watch(hormonalHealthRepositoryProvider);
  final endDate = DateTime.now();
  final startDate = endDate.subtract(Duration(days: params.days));
  return repository.getLogs(params.userId, startDate: startDate, endDate: endDate);
});

/// Provider for today's hormone log
final todayHormoneLogProvider = FutureProvider.autoDispose<HormoneLog?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;

  final repository = ref.watch(hormonalHealthRepositoryProvider);
  return repository.getTodayLog(user.id);
});

/// State notifier for creating/updating hormone logs
class HormoneLogNotifier extends StateNotifier<AsyncValue<void>> {
  final HormonalHealthRepository _repository;
  final String _userId;

  HormoneLogNotifier(this._repository, this._userId)
      : super(const AsyncValue.data(null));

  Future<HormoneLog?> createLog(Map<String, dynamic> logData) async {
    state = const AsyncValue.loading();
    try {
      final log = await _repository.createLog(_userId, logData);
      state = const AsyncValue.data(null);
      return log;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final hormoneLogNotifierProvider =
    StateNotifierProvider.autoDispose.family<HormoneLogNotifier, AsyncValue<void>, String>(
  (ref, userId) {
    final repository = ref.watch(hormonalHealthRepositoryProvider);
    return HormoneLogNotifier(repository, userId);
  },
);

// ============================================================================
// CYCLE PHASE PROVIDERS
// ============================================================================

/// Provider for current cycle phase
final cyclePhaseProvider = FutureProvider.autoDispose<CyclePhaseInfo?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;

  final repository = ref.watch(hormonalHealthRepositoryProvider);
  return repository.getCyclePhase(user.id);
});

/// Provider to log period start
final logPeriodStartProvider = FutureProvider.autoDispose
    .family<void, ({String userId, DateTime? periodDate})>((ref, params) async {
  final repository = ref.watch(hormonalHealthRepositoryProvider);
  await repository.logPeriodStart(params.userId, periodDate: params.periodDate);
});

// ============================================================================
// HORMONE-SUPPORTIVE FOODS PROVIDERS
// ============================================================================

/// Provider for hormone-supportive foods
final hormoneSupportiveFoodsProvider = FutureProvider.autoDispose
    .family<List<HormoneSupportiveFood>, ({HormoneGoal? goal, CyclePhase? phase})>(
  (ref, params) async {
    final repository = ref.watch(hormonalHealthRepositoryProvider);
    return repository.getFoods(goal: params.goal, cyclePhase: params.phase);
  },
);

/// Provider for personalized food recommendations
final hormonalFoodRecommendationsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;

  final repository = ref.watch(hormonalHealthRepositoryProvider);
  return repository.getFoodRecommendations(user.id);
});

// ============================================================================
// COMPREHENSIVE INSIGHTS PROVIDER
// ============================================================================

/// Provider for comprehensive hormonal insights
final hormonalInsightsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;

  final repository = ref.watch(hormonalHealthRepositoryProvider);
  return repository.getInsights(user.id);
});

// ============================================================================
// HELPER PROVIDERS
// ============================================================================

/// Provider to check if user has hormonal tracking enabled
final hasHormonalTrackingProvider = Provider.autoDispose<bool>((ref) {
  final profile = ref.watch(hormonalProfileProvider).value;
  if (profile == null) return false;
  return profile.menstrualTrackingEnabled ||
      profile.testosteroneOptimizationEnabled ||
      profile.hormoneGoals.isNotEmpty;
});

/// Provider for user's hormone goals
final userHormoneGoalsProvider = Provider.autoDispose<List<HormoneGoal>>((ref) {
  final profile = ref.watch(hormonalProfileProvider).value;
  return profile?.hormoneGoals ?? [];
});

/// Provider to check if cycle sync is enabled for workouts
final cycleSyncWorkoutsEnabledProvider = Provider.autoDispose<bool>((ref) {
  final profile = ref.watch(hormonalProfileProvider).value;
  return profile?.cycleSyncWorkouts ?? false;
});

/// Provider to check if cycle sync is enabled for nutrition
final cycleSyncNutritionEnabledProvider = Provider.autoDispose<bool>((ref) {
  final profile = ref.watch(hormonalProfileProvider).value;
  return profile?.cycleSyncNutrition ?? false;
});

// ============================================================================
// CYCLE TRACKING PROVIDERS (Phase B)
// ----------------------------------------------------------------------------
// `cyclePeriodsProvider`  — the user's logged period history.
// `cyclePredictionProvider` — cache-first: serves a cached value + an instant
//   on-device `CyclePredictor` result, then refreshes from the server
//   silently (project "instant data" principle — never a loading spinner on
//   a return visit, never pull-to-refresh).
// `cycleTrackingModeProvider` — the tracking | ttc | pregnancy mode.
// ============================================================================

/// Process-lifetime cache of the last good prediction + period list per user.
/// Survives provider auto-dispose so a re-entry to the Cycle screen paints
/// instantly from cache while the server refresh runs in the background.
class _CycleCache {
  _CycleCache._();
  static final _CycleCache instance = _CycleCache._();

  final Map<String, CyclePrediction> predictions = {};
  final Map<String, List<CyclePeriod>> periods = {};

  void clear() {
    predictions.clear();
    periods.clear();
  }
}

/// The user's logged period history (newest-first), cache-first.
///
/// On first load: hits the server. On a return visit: the previous result is
/// served instantly from [_CycleCache] while the network call refreshes it.
final cyclePeriodsProvider =
    FutureProvider.autoDispose<List<CyclePeriod>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return const [];

  final repository = ref.watch(hormonalHealthRepositoryProvider);
  try {
    final periods = await repository.listPeriods(user.id, limit: 60);
    _CycleCache.instance.periods[user.id] = periods;
    return periods;
  } catch (e) {
    // Network/contract failure — serve the last good value if we have one so
    // the screen stays usable offline. Surface the error only when there is
    // nothing cached (no silent fallback to fabricated data).
    debugPrint('⚠️ [Cycle] listPeriods failed: $e');
    final cached = _CycleCache.instance.periods[user.id];
    if (cached != null) return cached;
    rethrow;
  }
});

/// The current cycle tracking mode (tracking | ttc | pregnancy), read from the
/// hormonal profile. Defaults to [CycleTrackingMode.tracking].
///
/// NOTE: `tracking_mode` is a Phase-A column on `hormonal_profiles` that the
/// Flutter `HormonalProfile` model does not yet surface. Until the model is
/// extended (a later phase), this falls back to the safe default; the screen
/// can still override it locally for the mode toggle.
final cycleTrackingModeProvider =
    Provider.autoDispose<CycleTrackingMode>((ref) {
  final profileAsync = ref.watch(hormonalProfileProvider);
  final profile = profileAsync.value;
  if (profile == null) return CycleTrackingMode.tracking;
  // Pregnancy is a hard stop for predictions; expose it when the profile
  // exposes it in future. For now derive a sensible default: a profile with
  // fertility as a hormone goal implies TTC intent.
  if (profile.hormoneGoals.contains(HormoneGoal.improveFertility)) {
    return CycleTrackingMode.ttc;
  }
  return CycleTrackingMode.tracking;
});

/// Cache-first cycle prediction.
///
/// Resolution order, fastest-first:
///  1. If a server prediction is already cached for this user → return it
///     immediately AND kick off a silent background refresh.
///  2. Otherwise, if period history is available, compute an instant
///     on-device prediction with [CyclePredictor] (mirrors the backend
///     algorithm) so the screen never blocks on the network.
///  3. In parallel, fetch the authoritative server prediction; when it
///     resolves it replaces the cached value and the provider re-emits.
///
/// The server value is always the source of truth — the local predictor is
/// only a same-algorithm stand-in for instant render / offline use.
final cyclePredictionProvider =
    FutureProvider.autoDispose<CyclePrediction?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;

  final repository = ref.watch(hormonalHealthRepositoryProvider);
  final cache = _CycleCache.instance;
  final today = DateTime.now();

  // --- Silent server refresh, runs regardless of what we serve now. --------
  Future<CyclePrediction?> fetchServer() async {
    try {
      final fresh = await repository.getPrediction(user.id);
      cache.predictions[user.id] = fresh;
      return fresh;
    } catch (e) {
      debugPrint('⚠️ [Cycle] getPrediction failed: $e');
      return null;
    }
  }

  // (1) Warm cache → instant return + background refresh.
  final cached = cache.predictions[user.id];
  if (cached != null) {
    // Fire-and-forget refresh; the next provider read picks up the new value.
    // ignore: unawaited_futures
    fetchServer();
    return cached;
  }

  // (2) No cached server value yet — compute an instant local prediction from
  // whatever period history is already loaded, so the UI can render now.
  CyclePrediction? localGuess;
  final periodsAsync = ref.read(cyclePeriodsProvider);
  final periods = periodsAsync.value;
  if (periods != null && periods.isNotEmpty) {
    final profile = ref.read(hormonalProfileProvider).value;
    final mode = ref.read(cycleTrackingModeProvider);
    localGuess = CyclePredictor.predictFromPeriods(
      today: today,
      periods: periods,
      cycleLengthDefault:
          profile?.cycleLengthDays ?? CyclePredictor.defaultCycleLength,
      periodLengthDefault: profile?.typicalPeriodDurationDays ??
          CyclePredictor.defaultPeriodLength,
      hasPcos: profile?.hasPcos ?? false,
      trackingMode: mode,
    );
  }

  // (3) Fetch the authoritative value. If it arrives, use it; otherwise fall
  // back to the local guess (or null when there is genuinely no data).
  final server = await fetchServer();
  return server ?? localGuess;
});

// ============================================================================
// CYCLE SCREEN PROVIDERS (Phases C / D / F)
// ----------------------------------------------------------------------------
// `cycleRawLogsProvider`  — raw `hormone_logs` rows (incl. the cycle columns
//   the typed model drops) over a window, for the Calendar + Insights tabs +
//   the temperature chart.
// `cycleAiInsightProvider` — the proactive server-generated insight; null
//   when none is available so the inline card simply hides.
// ============================================================================

/// Raw `hormone_logs` rows for the cycle feature over the last [days] days.
/// Used by the temperature chart, calendar and insights tabs which need the
/// `basal_body_temperature` / `cervical_mucus` / `period_flow` /
/// `lh_test_result` columns the typed [HormoneLog] omits.
final cycleRawLogsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, days) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return const [];
  final repository = ref.watch(hormonalHealthRepositoryProvider);
  final end = DateTime.now();
  final start = end.subtract(Duration(days: days));
  return repository.getRawLogs(user.id,
      startDate: start, endDate: end, limit: days + 10);
});

/// The proactive server-generated cycle insight (Phase F). Cached per day by
/// the backend; null when nothing is available.
final cycleAiInsightProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;
  final repository = ref.watch(hormonalHealthRepositoryProvider);
  return repository.getAiInsight(user.id);
});
