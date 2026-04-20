import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user.dart' as app_user;

/// Provider for the current user from auth state
/// L1: Uses .select() to only rebuild when user data or status actually changes,
/// not on every auth state mutation (e.g. token refresh)
final currentUserProvider = Provider<AsyncValue<app_user.User?>>((ref) {
  final user = ref.watch(authStateProvider.select((s) => s.user));
  final status = ref.watch(authStateProvider.select((s) => s.status));
  final errorMessage = ref.watch(authStateProvider.select((s) => s.errorMessage));
  if (status == AuthStatus.loading && user == null) {
    return const AsyncValue.loading();
  }
  if (errorMessage != null) {
    return AsyncValue.error(errorMessage, StackTrace.current);
  }
  return AsyncValue.data(user);
});

/// Provider for the current user ID (convenience provider)
/// L1: Uses .select() to only rebuild when the user ID changes
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider.select((s) => s.user?.id));
});

/// Provider for user's weight unit preference ('kg' or 'lbs')
/// Body weight unit provider — for weighing yourself, BMI, body measurements.
/// Defaults to 'kg' if user is not loaded yet.
final weightUnitProvider = Provider<String>((ref) {
  return ref.watch(authStateProvider.select((s) => s.user?.preferredWeightUnit)) ?? 'kg';
});

/// Body weight: whether user prefers metric (kg) for body measurements.
final useKgProvider = Provider<bool>((ref) {
  final unit = ref.watch(weightUnitProvider);
  return unit == 'kg';
});

/// Workout weight unit provider — for exercise weights, sets, lifting.
/// Separate from body weight unit (user may weigh in kg but lift in lbs).
/// Falls back to body weight unit if not explicitly set.
final workoutWeightUnitProvider = Provider<String>((ref) {
  return ref.watch(authStateProvider.select((s) => s.user?.preferredWorkoutWeightUnit)) ?? 'lbs';
});

/// Workout weight: whether user prefers metric (kg) for lifting.
final useKgForWorkoutProvider = Provider<bool>((ref) {
  final unit = ref.watch(workoutWeightUnitProvider);
  return unit == 'kg';
});

/// Whether fatigue detection alerts are enabled during workouts.
/// Persisted to SharedPreferences. Defaults to true.
final fatigueAlertsEnabledProvider =
    StateNotifierProvider<FatigueAlertsNotifier, bool>((ref) {
  return FatigueAlertsNotifier();
});

class FatigueAlertsNotifier extends StateNotifier<bool> {
  static const _key = 'fatigue_alerts_enabled';

  FatigueAlertsNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }

  Future<void> setEnabled(bool enabled) async {
    if (state == enabled) return;
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}

/// Whether the pre-set coaching insight banner is shown above Set 1 of each
/// exercise during a workout. Persisted to SharedPreferences. Defaults to true.
final preSetInsightEnabledProvider =
    StateNotifierProvider<PreSetInsightNotifier, bool>((ref) {
  return PreSetInsightNotifier();
});

class PreSetInsightNotifier extends StateNotifier<bool> {
  static const _key = 'pre_set_insight_enabled';

  PreSetInsightNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }

  Future<void> setEnabled(bool enabled) async {
    if (state == enabled) return;
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}
