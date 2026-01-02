import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hormonal_health.dart';
import '../repositories/hormonal_health_repository.dart';
import '../../core/providers/user_provider.dart';

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
