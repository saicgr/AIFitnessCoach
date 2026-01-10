import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/muscle_analytics.dart';
import '../repositories/muscle_analytics_repository.dart';

// ============================================================================
// State Providers for UI selections
// ============================================================================

/// Currently selected muscle group for detailed view
final selectedMuscleGroupProvider = StateProvider<String?>((ref) => null);

/// Time range for muscle analytics queries
final muscleAnalyticsTimeRangeProvider = StateProvider<String>((ref) => '4_weeks');

/// Current tab in muscle analytics screen
final muscleAnalyticsTabProvider = StateProvider<int>((ref) => 0);

// ============================================================================
// Data Providers
// ============================================================================

/// Provider for muscle heatmap data
/// Note: Removed autoDispose to prevent refetching on navigation
final muscleHeatmapProvider = FutureProvider<MuscleHeatmapData>((ref) async {
  final repository = ref.watch(muscleAnalyticsRepositoryProvider);
  final timeRange = ref.watch(muscleAnalyticsTimeRangeProvider);
  return repository.getMuscleHeatmap(timeRange: timeRange);
});

/// Provider for muscle training frequency
/// Note: Removed autoDispose to prevent refetching on navigation
final muscleFrequencyProvider = FutureProvider<MuscleTrainingFrequency>((ref) async {
  final repository = ref.watch(muscleAnalyticsRepositoryProvider);
  return repository.getMuscleFrequency();
});

/// Provider for muscle balance analysis
/// Note: Removed autoDispose to prevent refetching on navigation
final muscleBalanceProvider = FutureProvider<MuscleBalanceData>((ref) async {
  final repository = ref.watch(muscleAnalyticsRepositoryProvider);
  return repository.getMuscleBalance();
});

/// Provider for exercises targeting a specific muscle (family provider)
/// Note: Removed autoDispose to prevent refetching on navigation
final muscleExercisesProvider = FutureProvider.family<MuscleExerciseData, String>((ref, muscleGroup) async {
  final repository = ref.watch(muscleAnalyticsRepositoryProvider);
  return repository.getExercisesForMuscle(muscleGroup: muscleGroup);
});

/// Provider for muscle training history (family provider)
/// Note: Removed autoDispose to prevent refetching on navigation
final muscleHistoryProvider = FutureProvider.family<MuscleHistoryData, String>((ref, muscleGroup) async {
  final repository = ref.watch(muscleAnalyticsRepositoryProvider);
  final timeRange = ref.watch(muscleAnalyticsTimeRangeProvider);
  return repository.getMuscleHistory(muscleGroup: muscleGroup, timeRange: timeRange);
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
