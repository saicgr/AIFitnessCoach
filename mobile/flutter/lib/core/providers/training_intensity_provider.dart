import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/training_intensity.dart';
import '../../data/repositories/training_intensity_repository.dart';
import '../../data/services/api_client.dart';

// -----------------------------------------------------------------------------
// State Classes
// -----------------------------------------------------------------------------

/// State for the user's 1RMs
class UserOneRMsState {
  final List<UserExercise1RM> oneRMs;
  final bool isLoading;
  final String? error;

  const UserOneRMsState({
    this.oneRMs = const [],
    this.isLoading = false,
    this.error,
  });

  UserOneRMsState copyWith({
    List<UserExercise1RM>? oneRMs,
    bool? isLoading,
    String? error,
  }) {
    return UserOneRMsState(
      oneRMs: oneRMs ?? this.oneRMs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get 1RM for a specific exercise (case-insensitive)
  UserExercise1RM? get1RM(String exerciseName) {
    final lowerName = exerciseName.toLowerCase();
    for (final rm in oneRMs) {
      if (rm.exerciseName.toLowerCase() == lowerName) {
        return rm;
      }
    }
    return null;
  }

  /// Check if we have a 1RM for an exercise
  bool has1RM(String exerciseName) => get1RM(exerciseName) != null;

  /// Group 1RMs by body part (for display)
  Map<String, List<UserExercise1RM>> get groupedByBodyPart {
    // This would require body_part info - for now group alphabetically
    final grouped = <String, List<UserExercise1RM>>{};
    for (final rm in oneRMs) {
      final firstLetter = rm.exerciseName.isNotEmpty
          ? rm.exerciseName[0].toUpperCase()
          : '#';
      grouped.putIfAbsent(firstLetter, () => []).add(rm);
    }
    return grouped;
  }
}

/// State for training intensity settings
class TrainingIntensityState {
  final int globalIntensityPercent;
  final String globalDescription;
  final Map<String, int> exerciseOverrides;
  final bool isLoading;
  final String? error;

  const TrainingIntensityState({
    this.globalIntensityPercent = 75,
    this.globalDescription = 'Working Weight / Hypertrophy',
    this.exerciseOverrides = const {},
    this.isLoading = false,
    this.error,
  });

  TrainingIntensityState copyWith({
    int? globalIntensityPercent,
    String? globalDescription,
    Map<String, int>? exerciseOverrides,
    bool? isLoading,
    String? error,
  }) {
    return TrainingIntensityState(
      globalIntensityPercent:
          globalIntensityPercent ?? this.globalIntensityPercent,
      globalDescription: globalDescription ?? this.globalDescription,
      exerciseOverrides: exerciseOverrides ?? this.exerciseOverrides,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get intensity for a specific exercise (override or global)
  int getIntensityFor(String exerciseName) {
    final lowerName = exerciseName.toLowerCase();
    return exerciseOverrides[lowerName] ??
        exerciseOverrides[exerciseName] ??
        globalIntensityPercent;
  }

  /// Check if an exercise has an override
  bool hasOverride(String exerciseName) {
    final lowerName = exerciseName.toLowerCase();
    return exerciseOverrides.containsKey(lowerName) ||
        exerciseOverrides.containsKey(exerciseName);
  }
}

// -----------------------------------------------------------------------------
// Notifiers
// -----------------------------------------------------------------------------

/// Notifier for managing user's 1RMs
class UserOneRMsNotifier extends StateNotifier<UserOneRMsState> {
  final Ref _ref;

  UserOneRMsNotifier(this._ref) : super(const UserOneRMsState(isLoading: true)) {
    _loadOneRMs();
  }

  Future<void> _loadOneRMs() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final repo = _ref.read(trainingIntensityRepositoryProvider);
      final oneRMs = await repo.getUserOneRMs(userId);

      state = state.copyWith(
        oneRMs: oneRMs,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading 1RMs: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadOneRMs();
  }

  /// Add or update a 1RM
  Future<bool> setOneRM({
    required String exerciseName,
    required double oneRepMaxKg,
    String source = 'manual',
    double confidence = 1.0,
  }) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) return false;

      final repo = _ref.read(trainingIntensityRepositoryProvider);
      final result = await repo.setOneRM(
        userId: userId,
        exerciseName: exerciseName,
        oneRepMaxKg: oneRepMaxKg,
        source: source,
        confidence: confidence,
      );

      if (result != null) {
        // Update local state
        final updatedList = List<UserExercise1RM>.from(state.oneRMs);
        final existingIndex = updatedList.indexWhere(
          (rm) => rm.exerciseName.toLowerCase() == exerciseName.toLowerCase(),
        );
        if (existingIndex >= 0) {
          updatedList[existingIndex] = result;
        } else {
          updatedList.add(result);
        }
        state = state.copyWith(oneRMs: updatedList);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error setting 1RM: $e');
      return false;
    }
  }

  /// Delete a 1RM
  Future<bool> deleteOneRM(String exerciseName) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) return false;

      final repo = _ref.read(trainingIntensityRepositoryProvider);
      final success = await repo.deleteOneRM(userId, exerciseName);

      if (success) {
        final updatedList = state.oneRMs
            .where((rm) =>
                rm.exerciseName.toLowerCase() != exerciseName.toLowerCase())
            .toList();
        state = state.copyWith(oneRMs: updatedList);
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting 1RM: $e');
      return false;
    }
  }

  /// Auto-populate 1RMs from workout history
  Future<AutoPopulateResponse?> autoPopulate({
    int daysLookback = 90,
    double minConfidence = 0.7,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return null;
      }

      final repo = _ref.read(trainingIntensityRepositoryProvider);
      final response = await repo.autoPopulateOneRMs(
        userId: userId,
        daysLookback: daysLookback,
        minConfidence: minConfidence,
      );

      // Reload 1RMs after auto-populate
      await _loadOneRMs();
      return response;
    } catch (e) {
      debugPrint('Error auto-populating 1RMs: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

/// Notifier for managing training intensity settings
class TrainingIntensityNotifier extends StateNotifier<TrainingIntensityState> {
  final Ref _ref;

  TrainingIntensityNotifier(this._ref)
      : super(const TrainingIntensityState(isLoading: true)) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final repo = _ref.read(trainingIntensityRepositoryProvider);
      final settings = await repo.getIntensitySettings(userId);

      state = state.copyWith(
        globalIntensityPercent: settings.globalIntensityPercent,
        globalDescription: settings.globalDescription,
        exerciseOverrides: settings.exerciseOverrides,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading intensity settings: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadSettings();
  }

  /// Set global training intensity
  Future<bool> setGlobalIntensity(int intensityPercent) async {
    try {
      // Optimistic update
      final oldPercent = state.globalIntensityPercent;
      state = state.copyWith(
        globalIntensityPercent: intensityPercent,
        globalDescription:
            IntensityLevelInfo.getDescriptionForPercent(intensityPercent),
      );

      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) {
        state = state.copyWith(globalIntensityPercent: oldPercent);
        return false;
      }

      final repo = _ref.read(trainingIntensityRepositoryProvider);
      final response = await repo.setGlobalIntensity(
        userId: userId,
        intensityPercent: intensityPercent,
      );

      if (response != null) {
        state = state.copyWith(
          globalIntensityPercent: response.intensityPercent,
          globalDescription: response.description,
        );
        return true;
      } else {
        state = state.copyWith(globalIntensityPercent: oldPercent);
        return false;
      }
    } catch (e) {
      debugPrint('Error setting global intensity: $e');
      return false;
    }
  }

  /// Set per-exercise intensity override
  Future<bool> setExerciseOverride(
      String exerciseName, int intensityPercent) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) return false;

      final repo = _ref.read(trainingIntensityRepositoryProvider);
      final response = await repo.setExerciseIntensityOverride(
        userId: userId,
        exerciseName: exerciseName,
        intensityPercent: intensityPercent,
      );

      if (response != null) {
        final updatedOverrides = Map<String, int>.from(state.exerciseOverrides);
        updatedOverrides[exerciseName.toLowerCase()] = intensityPercent;
        state = state.copyWith(exerciseOverrides: updatedOverrides);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error setting exercise override: $e');
      return false;
    }
  }

  /// Remove per-exercise intensity override
  Future<bool> removeExerciseOverride(String exerciseName) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) return false;

      final repo = _ref.read(trainingIntensityRepositoryProvider);
      final success = await repo.removeExerciseIntensityOverride(
        userId: userId,
        exerciseName: exerciseName,
      );

      if (success) {
        final updatedOverrides = Map<String, int>.from(state.exerciseOverrides);
        updatedOverrides.remove(exerciseName.toLowerCase());
        updatedOverrides.remove(exerciseName);
        state = state.copyWith(exerciseOverrides: updatedOverrides);
      }
      return success;
    } catch (e) {
      debugPrint('Error removing exercise override: $e');
      return false;
    }
  }
}

// -----------------------------------------------------------------------------
// Providers
// -----------------------------------------------------------------------------

/// Provider for user's 1RMs
final userOneRMsProvider =
    StateNotifierProvider<UserOneRMsNotifier, UserOneRMsState>((ref) {
  return UserOneRMsNotifier(ref);
});

/// Provider for training intensity settings
final trainingIntensityProvider =
    StateNotifierProvider<TrainingIntensityNotifier, TrainingIntensityState>(
        (ref) {
  return TrainingIntensityNotifier(ref);
});

/// Provider to get 1RM for a specific exercise
final exerciseOneRMProvider = Provider.family<UserExercise1RM?, String>((
  ref,
  exerciseName,
) {
  final oneRMsState = ref.watch(userOneRMsProvider);
  return oneRMsState.get1RM(exerciseName);
});

/// Provider to get training intensity for a specific exercise
final exerciseIntensityProvider = Provider.family<int, String>((
  ref,
  exerciseName,
) {
  final intensityState = ref.watch(trainingIntensityProvider);
  return intensityState.getIntensityFor(exerciseName);
});

/// Provider to calculate working weight for an exercise
final exerciseWorkingWeightProvider = Provider.family<double?, String>((
  ref,
  exerciseName,
) {
  final oneRM = ref.watch(exerciseOneRMProvider(exerciseName));
  if (oneRM == null) return null;

  final intensity = ref.watch(exerciseIntensityProvider(exerciseName));

  return TrainingIntensityRepository.calculateWorkingWeightLocal(
    oneRepMaxKg: oneRM.oneRepMaxKg,
    intensityPercent: intensity,
  );
});

/// Provider for working weight display string
final exerciseWorkingWeightDisplayProvider = Provider.family<String?, String>((
  ref,
  exerciseName,
) {
  final oneRM = ref.watch(exerciseOneRMProvider(exerciseName));
  if (oneRM == null) return null;

  final intensity = ref.watch(exerciseIntensityProvider(exerciseName));
  final workingWeight = ref.watch(exerciseWorkingWeightProvider(exerciseName));

  if (workingWeight == null) return null;

  return '${workingWeight.toStringAsFixed(1)} kg ($intensity% of 1RM)';
});
