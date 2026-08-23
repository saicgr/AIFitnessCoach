import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/cache/cache_first_mixin.dart';
import '../models/muscle_analytics.dart';
import '../repositories/auth_repository.dart';
import '../repositories/muscle_analytics_repository.dart';
import 'gym_progress_filter_provider.dart';

// ============================================================================
// Per-gym filter wiring
// ============================================================================

/// Surface key for the muscle-analytics gym filter chips. Shared by the data
/// providers below and the screen's [GymProgressFilter].
const muscleAnalyticsGymSurfaceKey = 'muscle_analytics';

/// The gym id the muscle-analytics surface is currently scoped to, or null for
/// the pooled "All gyms" view. Reads the shared per-surface filter selection so
/// the data providers refetch whenever the user taps a gym chip.
final muscleAnalyticsGymProfileIdProvider = Provider<String?>((ref) {
  final selection =
      ref.watch(gymProgressFilterProvider(muscleAnalyticsGymSurfaceKey));
  // isAllGyms (or unresolved) → combined; a specific gym → that gym.
  if (selection.isAllGyms) return null;
  return selection.gymProfileId;
});

// ============================================================================
// State Providers for UI selections
// ============================================================================

/// Currently selected muscle group for detailed view
final selectedMuscleGroupProvider = StateProvider<String?>((ref) => null);

/// Time range for muscle analytics queries
final muscleAnalyticsTimeRangeProvider = StateProvider<String>((ref) => '1_day');

/// Current tab in muscle analytics screen
final muscleAnalyticsTabProvider = StateProvider<int>((ref) => 0);

// ============================================================================
// Data Providers
// ============================================================================
//
// Instant-load standard (Part 2) for the Muscle Trends tabs. These used to be
// bare `FutureProvider`s — in-memory only, so a cold app launch always sat on
// the tab's skeleton for the full round trip. Each is now a disk-cache-first
// `StateNotifier` (see [CacheFirstMixin]): a restart paints the last-seen tab
// instantly while a fresh copy loads silently behind it. Cache key is scoped
// per time-range + gym filter (mirrors `DiscoverSnapshotNotifier`'s
// per-board+scope keying) so switching either never shows a stale scope's data
// mislabeled as the new one.

/// Cache-first loader for muscle heatmap data. Scoped by time range + gym.
class MuscleHeatmapNotifier extends StateNotifier<AsyncValue<MuscleHeatmapData>>
    with CacheFirstMixin {
  MuscleHeatmapNotifier({
    required MuscleAnalyticsRepository repository,
    required String timeRange,
    required String? gymProfileId,
    required String userId,
  })  : _repository = repository,
        _timeRange = timeRange,
        _gymProfileId = gymProfileId,
        _userId = userId,
        super(const AsyncValue.loading()) {
    load();
  }

  final MuscleAnalyticsRepository _repository;
  final String _timeRange;
  final String? _gymProfileId;
  final String _userId;

  static const int _schemaVersion = 1;

  Future<void> load() async {
    await loadCacheFirst<MuscleHeatmapData>(
      cacheKey: 'muscle_heatmap::${_timeRange}__${_gymProfileId ?? "_all"}',
      userId: _userId,
      ttl: const Duration(hours: 6),
      schemaVersion: _schemaVersion,
      fetch: () => _repository.getMuscleHeatmap(
          timeRange: _timeRange, gymProfileId: _gymProfileId),
      decode: MuscleHeatmapData.fromJson,
      encode: (d) => d.toJson(),
      emit: (data, {required bool fromCache}) {
        if (!mounted) return;
        state = AsyncValue.data(data);
      },
      onError: (e, st) {
        if (!mounted) return;
        try {
          if (state.valueOrNull == null) state = AsyncValue.error(e, st);
        } catch (_) {/* disposed between the check and the read */}
      },
    );
  }
}

/// Provider for muscle heatmap data. Watches the time range + gym filter so it
/// refetches whenever either changes.
final muscleHeatmapProvider =
    StateNotifierProvider<MuscleHeatmapNotifier, AsyncValue<MuscleHeatmapData>>(
        (ref) {
  final timeRange = ref.watch(muscleAnalyticsTimeRangeProvider);
  final gymProfileId = ref.watch(muscleAnalyticsGymProfileIdProvider);
  final userId = ref.watch(authStateProvider).user?.id ?? '';
  return MuscleHeatmapNotifier(
    repository: ref.watch(muscleAnalyticsRepositoryProvider),
    timeRange: timeRange,
    gymProfileId: gymProfileId,
    userId: userId,
  );
});

/// Cache-first loader for muscle training frequency data. Scoped by gym.
class MuscleFrequencyNotifier
    extends StateNotifier<AsyncValue<MuscleTrainingFrequency>>
    with CacheFirstMixin {
  MuscleFrequencyNotifier({
    required MuscleAnalyticsRepository repository,
    required String? gymProfileId,
    required String userId,
  })  : _repository = repository,
        _gymProfileId = gymProfileId,
        _userId = userId,
        super(const AsyncValue.loading()) {
    load();
  }

  final MuscleAnalyticsRepository _repository;
  final String? _gymProfileId;
  final String _userId;

  static const int _schemaVersion = 1;

  Future<void> load() async {
    await loadCacheFirst<MuscleTrainingFrequency>(
      cacheKey: 'muscle_frequency::${_gymProfileId ?? "_all"}',
      userId: _userId,
      ttl: const Duration(hours: 6),
      schemaVersion: _schemaVersion,
      fetch: () => _repository.getMuscleFrequency(gymProfileId: _gymProfileId),
      decode: MuscleTrainingFrequency.fromJson,
      encode: (d) => d.toJson(),
      emit: (data, {required bool fromCache}) {
        if (!mounted) return;
        state = AsyncValue.data(data);
      },
      onError: (e, st) {
        if (!mounted) return;
        try {
          if (state.valueOrNull == null) state = AsyncValue.error(e, st);
        } catch (_) {/* disposed between the check and the read */}
      },
    );
  }
}

/// Provider for muscle training frequency. Watches the gym filter so it
/// refetches when the user picks a gym.
final muscleFrequencyProvider = StateNotifierProvider<MuscleFrequencyNotifier,
    AsyncValue<MuscleTrainingFrequency>>((ref) {
  final gymProfileId = ref.watch(muscleAnalyticsGymProfileIdProvider);
  final userId = ref.watch(authStateProvider).user?.id ?? '';
  return MuscleFrequencyNotifier(
    repository: ref.watch(muscleAnalyticsRepositoryProvider),
    gymProfileId: gymProfileId,
    userId: userId,
  );
});

/// Cache-first loader for muscle balance data. Scoped by gym.
class MuscleBalanceNotifier extends StateNotifier<AsyncValue<MuscleBalanceData>>
    with CacheFirstMixin {
  MuscleBalanceNotifier({
    required MuscleAnalyticsRepository repository,
    required String? gymProfileId,
    required String userId,
  })  : _repository = repository,
        _gymProfileId = gymProfileId,
        _userId = userId,
        super(const AsyncValue.loading()) {
    load();
  }

  final MuscleAnalyticsRepository _repository;
  final String? _gymProfileId;
  final String _userId;

  static const int _schemaVersion = 1;

  Future<void> load() async {
    await loadCacheFirst<MuscleBalanceData>(
      cacheKey: 'muscle_balance::${_gymProfileId ?? "_all"}',
      userId: _userId,
      ttl: const Duration(hours: 6),
      schemaVersion: _schemaVersion,
      fetch: () => _repository.getMuscleBalance(gymProfileId: _gymProfileId),
      decode: MuscleBalanceData.fromJson,
      encode: (d) => d.toJson(),
      emit: (data, {required bool fromCache}) {
        if (!mounted) return;
        state = AsyncValue.data(data);
      },
      onError: (e, st) {
        if (!mounted) return;
        try {
          if (state.valueOrNull == null) state = AsyncValue.error(e, st);
        } catch (_) {/* disposed between the check and the read */}
      },
    );
  }
}

/// Provider for muscle balance analysis. Watches the gym filter so it
/// refetches when the user picks a gym.
final muscleBalanceProvider = StateNotifierProvider<MuscleBalanceNotifier,
    AsyncValue<MuscleBalanceData>>((ref) {
  final gymProfileId = ref.watch(muscleAnalyticsGymProfileIdProvider);
  final userId = ref.watch(authStateProvider).user?.id ?? '';
  return MuscleBalanceNotifier(
    repository: ref.watch(muscleAnalyticsRepositoryProvider),
    gymProfileId: gymProfileId,
    userId: userId,
  );
});

/// Provider for exercises targeting a specific muscle (family provider)
/// Note: Removed autoDispose to prevent refetching on navigation
final muscleExercisesProvider = FutureProvider.family<MuscleExerciseData, String>((ref, muscleGroup) async {
  final repository = ref.watch(muscleAnalyticsRepositoryProvider);
  return repository.getExercisesForMuscle(muscleGroup: muscleGroup);
});

/// Provider for muscle training history (family provider)
/// Note: Removed autoDispose to prevent refetching on navigation.
/// Watches the gym filter selection so it refetches when the user picks a gym.
final muscleHistoryProvider = FutureProvider.family<MuscleHistoryData, String>((ref, muscleGroup) async {
  final repository = ref.watch(muscleAnalyticsRepositoryProvider);
  final timeRange = ref.watch(muscleAnalyticsTimeRangeProvider);
  final gymProfileId = ref.watch(muscleAnalyticsGymProfileIdProvider);
  return repository.getMuscleHistory(
      muscleGroup: muscleGroup, timeRange: timeRange, gymProfileId: gymProfileId);
});

// ============================================================================
// Derived Providers
// ============================================================================

/// Get list of all muscle groups from heatmap data
/// Note: Removed autoDispose to prevent refetching on navigation
final allMuscleGroupsProvider = Provider<AsyncValue<List<String>>>((ref) {
  final heatmapAsync = ref.watch(muscleHeatmapProvider);
  return heatmapAsync.whenData((heatmap) {
    return heatmap.muscleIntensities.map((m) => m.muscleId).toList();
  });
});

/// Get top trained muscles (top 5)
/// Note: Removed autoDispose to prevent refetching on navigation
final topTrainedMusclesProvider = Provider<AsyncValue<List<MuscleIntensity>>>((ref) {
  final heatmapAsync = ref.watch(muscleHeatmapProvider);
  return heatmapAsync.whenData((heatmap) {
    return heatmap.getTopMuscles(5);
  });
});

/// Get neglected muscles (bottom 20% intensity)
/// Note: Removed autoDispose to prevent refetching on navigation
final neglectedMusclesProvider = Provider<AsyncValue<List<MuscleIntensity>>>((ref) {
  final heatmapAsync = ref.watch(muscleHeatmapProvider);
  return heatmapAsync.whenData((heatmap) {
    return heatmap.getNeglectedMuscles(threshold: 0.2);
  });
});

/// Get undertrained muscles from frequency data
/// Note: Removed autoDispose to prevent refetching on navigation
final undertrainedMusclesProvider = Provider<AsyncValue<List<MuscleFrequencyData>>>((ref) {
  final frequencyAsync = ref.watch(muscleFrequencyProvider);
  return frequencyAsync.whenData((frequency) {
    return frequency.frequencies.where((f) => f.isUndertrained).toList();
  });
});

/// Get overtrained muscles from frequency data
/// Note: Removed autoDispose to prevent refetching on navigation
final overtrainedMusclesProvider = Provider<AsyncValue<List<MuscleFrequencyData>>>((ref) {
  final frequencyAsync = ref.watch(muscleFrequencyProvider);
  return frequencyAsync.whenData((frequency) {
    return frequency.frequencies.where((f) => f.isOvertrained).toList();
  });
});

/// Get balance recommendations
/// Note: Removed autoDispose to prevent refetching on navigation
final balanceRecommendationsProvider = Provider<AsyncValue<List<String>>>((ref) {
  final balanceAsync = ref.watch(muscleBalanceProvider);
  return balanceAsync.whenData((balance) {
    return balance.recommendations ?? [];
  });
});

/// Check if there are significant imbalances
/// Note: Removed autoDispose to prevent refetching on navigation
final hasSignificantImbalancesProvider = Provider<AsyncValue<bool>>((ref) {
  final balanceAsync = ref.watch(muscleBalanceProvider);
  return balanceAsync.whenData((balance) {
    return balance.hasImbalances;
  });
});

// ============================================================================
// Combined Analytics Provider
// ============================================================================

/// Combined muscle analytics state
class MuscleAnalyticsSummary {
  final MuscleHeatmapData? heatmap;
  final MuscleTrainingFrequency? frequency;
  final MuscleBalanceData? balance;
  final bool isLoading;
  final String? error;

  const MuscleAnalyticsSummary({
    this.heatmap,
    this.frequency,
    this.balance,
    this.isLoading = false,
    this.error,
  });

  bool get hasData => heatmap != null || frequency != null || balance != null;

  int get undertrainedCount => frequency?.frequencies.where((f) => f.isUndertrained).length ?? 0;
  int get overtrainedCount => frequency?.frequencies.where((f) => f.isOvertrained).length ?? 0;
  bool get hasImbalances => balance?.hasImbalances ?? false;
  double get balanceScore => balance?.balanceScore ?? 0;
}

/// Provider that combines all muscle analytics data
/// Note: Removed autoDispose to prevent refetching on navigation
final muscleAnalyticsSummaryProvider = Provider<MuscleAnalyticsSummary>((ref) {
  final heatmapAsync = ref.watch(muscleHeatmapProvider);
  final frequencyAsync = ref.watch(muscleFrequencyProvider);
  final balanceAsync = ref.watch(muscleBalanceProvider);

  final isLoading = heatmapAsync.isLoading || frequencyAsync.isLoading || balanceAsync.isLoading;

  String? error;
  if (heatmapAsync.hasError) error = heatmapAsync.error.toString();
  if (frequencyAsync.hasError) error = frequencyAsync.error.toString();
  if (balanceAsync.hasError) error = balanceAsync.error.toString();

  return MuscleAnalyticsSummary(
    heatmap: heatmapAsync.valueOrNull,
    frequency: frequencyAsync.valueOrNull,
    balance: balanceAsync.valueOrNull,
    isLoading: isLoading,
    error: error,
  );
});
