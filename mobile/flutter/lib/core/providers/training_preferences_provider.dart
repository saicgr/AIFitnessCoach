import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../constants/api_constants.dart';

/// Progression pace options
enum ProgressionPace {
  slow,
  medium,
  fast;

  String get displayName {
    switch (this) {
      case ProgressionPace.slow:
        return 'Slow';
      case ProgressionPace.medium:
        return 'Medium';
      case ProgressionPace.fast:
        return 'Fast';
    }
  }

  String get description {
    switch (this) {
      case ProgressionPace.slow:
        return 'Increase weight every 3-4 weeks';
      case ProgressionPace.medium:
        return 'Increase weight every 1-2 weeks';
      case ProgressionPace.fast:
        return 'Increase weight every session';
    }
  }

  String get bestFor {
    switch (this) {
      case ProgressionPace.slow:
        return 'Best for: Injury recovery, perfecting form';
      case ProgressionPace.medium:
        return 'Best for: Steady, sustainable progress';
      case ProgressionPace.fast:
        return 'Best for: Beginners with rapid newbie gains';
    }
  }

  String get value => name;

  static ProgressionPace fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'slow':
        return ProgressionPace.slow;
      case 'fast':
        return ProgressionPace.fast;
      case 'medium':
      default:
        return ProgressionPace.medium;
    }
  }
}

/// Workout type options
enum WorkoutType {
  strength,
  cardio,
  mixed,
  mobility,
  recovery;

  String get displayName {
    switch (this) {
      case WorkoutType.strength:
        return 'Strength';
      case WorkoutType.cardio:
        return 'Cardio';
      case WorkoutType.mixed:
        return 'Mixed';
      case WorkoutType.mobility:
        return 'Mobility';
      case WorkoutType.recovery:
        return 'Recovery';
    }
  }

  String get description {
    switch (this) {
      case WorkoutType.strength:
        return 'Weight training focus';
      case WorkoutType.cardio:
        return 'Running, cycling, HIIT';
      case WorkoutType.mixed:
        return 'Strength + cardio days';
      case WorkoutType.mobility:
        return 'Stretching, yoga, flexibility';
      case WorkoutType.recovery:
        return 'Light movement, active rest';
    }
  }

  String get value => name;

  static WorkoutType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'cardio':
        return WorkoutType.cardio;
      case 'mixed':
        return WorkoutType.mixed;
      case 'mobility':
        return WorkoutType.mobility;
      case 'recovery':
        return WorkoutType.recovery;
      case 'strength':
      default:
        return WorkoutType.strength;
    }
  }
}

/// Training preferences state
class TrainingPreferencesState {
  final ProgressionPace progressionPace;
  final WorkoutType workoutType;
  final bool isLoading;
  final String? error;

  const TrainingPreferencesState({
    this.progressionPace = ProgressionPace.medium,
    this.workoutType = WorkoutType.strength,
    this.isLoading = false,
    this.error,
  });

  TrainingPreferencesState copyWith({
    ProgressionPace? progressionPace,
    WorkoutType? workoutType,
    bool? isLoading,
    String? error,
  }) {
    return TrainingPreferencesState(
      progressionPace: progressionPace ?? this.progressionPace,
      workoutType: workoutType ?? this.workoutType,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Training preferences provider
final trainingPreferencesProvider =
    StateNotifierProvider<TrainingPreferencesNotifier, TrainingPreferencesState>(
        (ref) {
  return TrainingPreferencesNotifier(ref);
});

/// Training preferences notifier for managing state
class TrainingPreferencesNotifier extends StateNotifier<TrainingPreferencesState> {
  final Ref _ref;

  TrainingPreferencesNotifier(this._ref) : super(const TrainingPreferencesState()) {
    _init();
  }

  /// Parse preferences JSON string to Map
  Map<String, dynamic>? _parsePreferences(String? prefsJson) {
    if (prefsJson == null || prefsJson.isEmpty) return null;
    try {
      final decoded = jsonDecode(prefsJson);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Initialize preferences from user profile
  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final authState = _ref.read(authStateProvider);
      if (authState.user != null) {
        final prefsMap = _parsePreferences(authState.user!.preferences);
        if (prefsMap != null) {
          final progressionPace = ProgressionPace.fromString(
            prefsMap['progression_pace']?.toString(),
          );
          final workoutType = WorkoutType.fromString(
            prefsMap['workout_type_preference']?.toString(),
          );
          state = TrainingPreferencesState(
            progressionPace: progressionPace,
            workoutType: workoutType,
          );
          debugPrint(
            '   [TrainingPrefs] Loaded: pace=${progressionPace.value}, type=${workoutType.value}',
          );
          return;
        }
      }
      // Use defaults if no user or no preferences
      state = const TrainingPreferencesState();
      debugPrint('   [TrainingPrefs] Using defaults');
    } catch (e) {
      debugPrint('   [TrainingPrefs] Init error: $e');
      state = TrainingPreferencesState(error: e.toString());
    }
  }

  /// Set progression pace and sync to backend
  Future<void> setProgressionPace(ProgressionPace pace) async {
    if (pace == state.progressionPace) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        await apiClient.put(
          '${ApiConstants.users}/$userId',
          data: {'progression_pace': pace.value},
        );
        debugPrint('   [TrainingPrefs] Synced progression_pace: ${pace.value}');
      }

      // Refresh user to get updated data
      await _ref.read(authStateProvider.notifier).refreshUser();

      state = state.copyWith(progressionPace: pace, isLoading: false);
      debugPrint('   [TrainingPrefs] Updated progression_pace to: ${pace.value}');
    } catch (e) {
      debugPrint('   [TrainingPrefs] Update error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Set workout type and sync to backend
  Future<void> setWorkoutType(WorkoutType type) async {
    if (type == state.workoutType) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        await apiClient.put(
          '${ApiConstants.users}/$userId',
          data: {'workout_type_preference': type.value},
        );
        debugPrint('   [TrainingPrefs] Synced workout_type: ${type.value}');
      }

      // Refresh user to get updated data
      await _ref.read(authStateProvider.notifier).refreshUser();

      state = state.copyWith(workoutType: type, isLoading: false);
      debugPrint('   [TrainingPrefs] Updated workout_type to: ${type.value}');
    } catch (e) {
      debugPrint('   [TrainingPrefs] Update error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh preferences from user profile
  Future<void> refresh() async {
    final authState = _ref.read(authStateProvider);
    if (authState.user != null) {
      final prefsMap = _parsePreferences(authState.user!.preferences);
      if (prefsMap != null) {
        state = TrainingPreferencesState(
          progressionPace: ProgressionPace.fromString(
            prefsMap['progression_pace']?.toString(),
          ),
          workoutType: WorkoutType.fromString(
            prefsMap['workout_type_preference']?.toString(),
          ),
        );
      }
    }
  }
}
