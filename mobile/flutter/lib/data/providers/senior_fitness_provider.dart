import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/senior_settings.dart';
import '../repositories/senior_fitness_repository.dart';

// ============================================
// State Classes
// ============================================

/// State for senior fitness settings and recovery
class SeniorFitnessState {
  final bool isLoading;
  final String? error;
  final SeniorRecoverySettings? settings;
  final RecoveryStatus? recoveryStatus;
  final List<SeniorMobilityExercise> mobilityExercises;
  final List<SeniorMobilityExercise> balanceExercises;
  final List<SeniorWorkoutLog> workoutHistory;
  final SeniorWorkoutHistoryResponse? historyStats;
  final WorkoutModificationResult? lastModificationResult;

  const SeniorFitnessState({
    this.isLoading = false,
    this.error,
    this.settings,
    this.recoveryStatus,
    this.mobilityExercises = const [],
    this.balanceExercises = const [],
    this.workoutHistory = const [],
    this.historyStats,
    this.lastModificationResult,
  });

  SeniorFitnessState copyWith({
    bool? isLoading,
    String? error,
    SeniorRecoverySettings? settings,
    RecoveryStatus? recoveryStatus,
    List<SeniorMobilityExercise>? mobilityExercises,
    List<SeniorMobilityExercise>? balanceExercises,
    List<SeniorWorkoutLog>? workoutHistory,
    SeniorWorkoutHistoryResponse? historyStats,
    WorkoutModificationResult? lastModificationResult,
    bool clearError = false,
    bool clearModificationResult = false,
  }) {
    return SeniorFitnessState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      settings: settings ?? this.settings,
      recoveryStatus: recoveryStatus ?? this.recoveryStatus,
      mobilityExercises: mobilityExercises ?? this.mobilityExercises,
      balanceExercises: balanceExercises ?? this.balanceExercises,
      workoutHistory: workoutHistory ?? this.workoutHistory,
      historyStats: historyStats ?? this.historyStats,
      lastModificationResult: clearModificationResult
          ? null
          : (lastModificationResult ?? this.lastModificationResult),
    );
  }

  /// Check if user is ready for workout
  bool get isReadyForWorkout => recoveryStatus?.isReady ?? true;

  /// Check if settings are loaded
  bool get hasSettings => settings != null;

  /// Get recovery percentage
  double get recoveryPercentage => recoveryStatus?.recoveryPercentage ?? 100.0;

  /// Get seated mobility exercises
  List<SeniorMobilityExercise> get seatedMobilityExercises =>
      mobilityExercises.where((e) => e.isSeated).toList();

  /// Get standing mobility exercises
  List<SeniorMobilityExercise> get standingMobilityExercises =>
      mobilityExercises.where((e) => !e.isSeated).toList();

  /// Get easy balance exercises
  List<SeniorMobilityExercise> get easyBalanceExercises =>
      balanceExercises.where((e) => e.difficultyLevel == 'easy').toList();
}

// ============================================
// State Notifier
// ============================================

class SeniorFitnessNotifier extends StateNotifier<SeniorFitnessState> {
  final SeniorFitnessRepository _repository;
  String? _currentUserId;

  SeniorFitnessNotifier(this._repository) : super(const SeniorFitnessState());

  /// Set user ID for this session
  void setUserId(String userId) {
    _currentUserId = userId;
  }

  // ─────────────────────────────────────────────────────────────────
  // Settings Management
  // ─────────────────────────────────────────────────────────────────

  /// Load senior recovery settings
  Future<void> loadSettings({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      debugPrint('No user ID, skipping load settings');
      return;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final settings = await _repository.getSettings(uid);
      state = state.copyWith(isLoading: false, settings: settings);
      debugPrint('Loaded senior settings for user $uid');
    } catch (e) {
      debugPrint('Error loading senior settings: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load settings: $e',
      );
    }
  }

  /// Update senior recovery settings
  Future<bool> updateSettings({
    required SeniorRecoverySettings settings,
    String? userId,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      state = state.copyWith(error: 'User not authenticated');
      return false;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final updatedSettings = await _repository.updateSettings(
        userId: uid,
        settings: settings,
      );
      state = state.copyWith(isLoading: false, settings: updatedSettings);
      debugPrint('Updated senior settings');
      return true;
    } catch (e) {
      debugPrint('Error updating senior settings: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update settings: $e',
      );
      return false;
    }
  }

  /// Patch specific settings
  Future<bool> patchSettings({
    required Map<String, dynamic> updates,
    String? userId,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      state = state.copyWith(error: 'User not authenticated');
      return false;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final updatedSettings = await _repository.patchSettings(
        userId: uid,
        updates: updates,
      );
      state = state.copyWith(isLoading: false, settings: updatedSettings);
      debugPrint('Patched senior settings');
      return true;
    } catch (e) {
      debugPrint('Error patching senior settings: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update settings: $e',
      );
      return false;
    }
  }

  /// Reset settings to defaults
  Future<bool> resetSettings({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return false;
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final settings = await _repository.resetSettings(uid);
      state = state.copyWith(isLoading: false, settings: settings);
      debugPrint('Reset senior settings to defaults');
      return true;
    } catch (e) {
      debugPrint('Error resetting settings: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to reset settings: $e',
      );
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Recovery Status
  // ─────────────────────────────────────────────────────────────────

  /// Check recovery status
  Future<void> checkRecoveryStatus({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    try {
      final status = await _repository.checkRecoveryStatus(uid);
      state = state.copyWith(recoveryStatus: status);
      debugPrint('Recovery status: ${status.statusLabel} (${status.recoveryPercentageDisplay})');
    } catch (e) {
      debugPrint('Error checking recovery status: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Workout Logging
  // ─────────────────────────────────────────────────────────────────

  /// Log a completed workout
  Future<SeniorWorkoutLog?> logWorkoutCompletion({
    required String workoutId,
    required String workoutName,
    required String workoutType,
    required int durationMinutes,
    int? perceivedExertion,
    int? energyLevelBefore,
    int? energyLevelAfter,
    bool jointPainReported = false,
    List<String> jointPainAreas = const [],
    int balanceExercisesCompleted = 0,
    int mobilityExercisesCompleted = 0,
    List<String> modificationsUsed = const [],
    bool warmupCompleted = true,
    bool cooldownCompleted = true,
    int? recoveryRating,
    String? notes,
    String? userId,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      state = state.copyWith(error: 'User not authenticated');
      return null;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final log = await _repository.logWorkoutCompletion(
        userId: uid,
        workoutId: workoutId,
        workoutName: workoutName,
        workoutType: workoutType,
        durationMinutes: durationMinutes,
        perceivedExertion: perceivedExertion,
        energyLevelBefore: energyLevelBefore,
        energyLevelAfter: energyLevelAfter,
        jointPainReported: jointPainReported,
        jointPainAreas: jointPainAreas,
        balanceExercisesCompleted: balanceExercisesCompleted,
        mobilityExercisesCompleted: mobilityExercisesCompleted,
        modificationsUsed: modificationsUsed,
        warmupCompleted: warmupCompleted,
        cooldownCompleted: cooldownCompleted,
        recoveryRating: recoveryRating,
        notes: notes,
      );

      // Add to history
      final updatedHistory = [log, ...state.workoutHistory];
      state = state.copyWith(isLoading: false, workoutHistory: updatedHistory);

      // Refresh recovery status
      checkRecoveryStatus(userId: uid);

      debugPrint('Logged workout: ${log.workoutName}');
      return log;
    } catch (e) {
      debugPrint('Error logging workout: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to log workout: $e',
      );
      return null;
    }
  }

  /// Load workout history
  Future<void> loadWorkoutHistory({
    String? userId,
    int limit = 50,
    int? days,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _repository.getWorkoutHistory(
        userId: uid,
        limit: limit,
        days: days,
      );

      state = state.copyWith(
        isLoading: false,
        workoutHistory: response.workoutLogs,
        historyStats: response,
      );
      debugPrint('Loaded ${response.totalWorkouts} workout logs');
    } catch (e) {
      debugPrint('Error loading workout history: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load workout history: $e',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Mobility & Balance Exercises
  // ─────────────────────────────────────────────────────────────────

  /// Load mobility exercises
  Future<void> loadMobilityExercises({
    String? targetArea,
    bool? isSeated,
    String? difficultyLevel,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final exercises = await _repository.getMobilityExercises(
        targetArea: targetArea,
        isSeated: isSeated,
        difficultyLevel: difficultyLevel,
      );

      state = state.copyWith(isLoading: false, mobilityExercises: exercises);
      debugPrint('Loaded ${exercises.length} mobility exercises');
    } catch (e) {
      debugPrint('Error loading mobility exercises: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load mobility exercises: $e',
      );
    }
  }

  /// Load balance exercises
  Future<void> loadBalanceExercises({
    String? difficultyLevel,
    bool? requiresSupport,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final exercises = await _repository.getBalanceExercises(
        difficultyLevel: difficultyLevel,
        requiresSupport: requiresSupport,
      );

      state = state.copyWith(isLoading: false, balanceExercises: exercises);
      debugPrint('Loaded ${exercises.length} balance exercises');
    } catch (e) {
      debugPrint('Error loading balance exercises: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load balance exercises: $e',
      );
    }
  }

  /// Load mobility exercises by focus areas from settings
  Future<void> loadMobilityExercisesForUser({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;

    // Ensure settings are loaded
    if (state.settings == null) {
      await loadSettings(userId: uid);
    }

    final focusAreas = state.settings?.mobilityFocusAreas ?? [];
    if (focusAreas.isEmpty) {
      await loadMobilityExercises();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final exercises = await _repository.getMobilityExercisesByAreas(focusAreas);
      state = state.copyWith(isLoading: false, mobilityExercises: exercises);
      debugPrint('Loaded ${exercises.length} mobility exercises for focus areas');
    } catch (e) {
      debugPrint('Error loading mobility exercises by areas: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load mobility exercises: $e',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Workout Modifications
  // ─────────────────────────────────────────────────────────────────

  /// Preview modifications for a workout
  Future<WorkoutModificationResult?> previewModifications({
    required String workoutId,
    String? userId,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      state = state.copyWith(error: 'User not authenticated');
      return null;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repository.previewWorkoutModifications(
        userId: uid,
        workoutId: workoutId,
      );

      state = state.copyWith(
        isLoading: false,
        lastModificationResult: result,
      );
      debugPrint('Preview modifications: ${result.modificationsSummary}');
      return result;
    } catch (e) {
      debugPrint('Error previewing modifications: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to preview modifications: $e',
      );
      return null;
    }
  }

  /// Apply modifications to a workout
  Future<WorkoutModificationResult?> modifyWorkout({
    required String workoutId,
    String? userId,
  }) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) {
      state = state.copyWith(error: 'User not authenticated');
      return null;
    }
    _currentUserId = uid;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repository.modifyWorkoutForSenior(
        userId: uid,
        workoutId: workoutId,
      );

      state = state.copyWith(
        isLoading: false,
        lastModificationResult: result,
      );
      debugPrint('Applied modifications: ${result.modificationsSummary}');
      return result;
    } catch (e) {
      debugPrint('Error modifying workout: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to modify workout: $e',
      );
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Utility Methods
  // ─────────────────────────────────────────────────────────────────

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear modification result
  void clearModificationResult() {
    state = state.copyWith(clearModificationResult: true);
  }

  /// Refresh all data
  Future<void> refresh({String? userId}) async {
    final uid = userId ?? _currentUserId;
    if (uid == null) return;

    await Future.wait([
      loadSettings(userId: uid),
      checkRecoveryStatus(userId: uid),
      loadWorkoutHistory(userId: uid, limit: 20),
    ]);
  }

  /// Initialize for a user
  Future<void> initialize({required String userId}) async {
    _currentUserId = userId;
    await refresh(userId: userId);
    await loadMobilityExercisesForUser(userId: userId);
    await loadBalanceExercises();
  }
}

// ============================================
// Providers
// ============================================

/// Main senior fitness provider
final seniorFitnessProvider =
    StateNotifierProvider<SeniorFitnessNotifier, SeniorFitnessState>((ref) {
  final repository = ref.watch(seniorFitnessRepositoryProvider);
  return SeniorFitnessNotifier(repository);
});

/// Senior recovery settings (convenience provider)
final seniorSettingsProvider = Provider<SeniorRecoverySettings?>((ref) {
  return ref.watch(seniorFitnessProvider).settings;
});

/// Recovery status provider
final recoveryStatusProvider = Provider<RecoveryStatus?>((ref) {
  return ref.watch(seniorFitnessProvider).recoveryStatus;
});

/// Recovery status future provider (for initial fetch)
final recoveryStatusFutureProvider =
    FutureProvider.family<RecoveryStatus, String>((ref, userId) async {
  final repository = ref.watch(seniorFitnessRepositoryProvider);
  return repository.checkRecoveryStatus(userId);
});

/// Mobility exercises provider
final mobilityExercisesProvider = Provider<List<SeniorMobilityExercise>>((ref) {
  return ref.watch(seniorFitnessProvider).mobilityExercises;
});

/// Balance exercises provider
final balanceExercisesProvider = Provider<List<SeniorMobilityExercise>>((ref) {
  return ref.watch(seniorFitnessProvider).balanceExercises;
});

/// Workout history provider
final seniorWorkoutHistoryProvider = Provider<List<SeniorWorkoutLog>>((ref) {
  return ref.watch(seniorFitnessProvider).workoutHistory;
});

/// History stats provider
final seniorHistoryStatsProvider = Provider<SeniorWorkoutHistoryResponse?>((ref) {
  return ref.watch(seniorFitnessProvider).historyStats;
});

/// Is ready for workout provider
final isReadyForWorkoutProvider = Provider<bool>((ref) {
  return ref.watch(seniorFitnessProvider).isReadyForWorkout;
});

/// Loading state provider
final seniorFitnessLoadingProvider = Provider<bool>((ref) {
  return ref.watch(seniorFitnessProvider).isLoading;
});

/// Error state provider
final seniorFitnessErrorProvider = Provider<String?>((ref) {
  return ref.watch(seniorFitnessProvider).error;
});

/// Last modification result provider
final lastModificationResultProvider = Provider<WorkoutModificationResult?>((ref) {
  return ref.watch(seniorFitnessProvider).lastModificationResult;
});

/// Seated mobility exercises provider
final seatedMobilityExercisesProvider = Provider<List<SeniorMobilityExercise>>((ref) {
  return ref.watch(seniorFitnessProvider).seatedMobilityExercises;
});

/// Standing mobility exercises provider
final standingMobilityExercisesProvider = Provider<List<SeniorMobilityExercise>>((ref) {
  return ref.watch(seniorFitnessProvider).standingMobilityExercises;
});

/// Easy balance exercises provider
final easyBalanceExercisesProvider = Provider<List<SeniorMobilityExercise>>((ref) {
  return ref.watch(seniorFitnessProvider).easyBalanceExercises;
});

/// Low-impact alternatives provider (family provider for specific exercise)
final lowImpactAlternativesProvider =
    FutureProvider.family<List<LowImpactAlternative>, String>((ref, exerciseName) async {
  final repository = ref.watch(seniorFitnessRepositoryProvider);
  return repository.getLowImpactAlternatives(exerciseName: exerciseName);
});

/// Settings with defaults provider (never null)
final seniorSettingsWithDefaultsProvider = Provider<SeniorRecoverySettings>((ref) {
  return ref.watch(seniorSettingsProvider) ?? SeniorRecoverySettings.defaultSettings();
});

/// Has low-impact preferences enabled
final hasLowImpactPreferencesProvider = Provider<bool>((ref) {
  final settings = ref.watch(seniorSettingsWithDefaultsProvider);
  return settings.hasLowImpactPreferences;
});

/// Recovery percentage provider
final recoveryPercentageProvider = Provider<double>((ref) {
  return ref.watch(seniorFitnessProvider).recoveryPercentage;
});

/// Mobility focus areas provider
final mobilityFocusAreasProvider = Provider<List<String>>((ref) {
  final settings = ref.watch(seniorSettingsWithDefaultsProvider);
  return settings.mobilityFocusAreas;
});

/// Joint considerations provider
final jointConsiderationsProvider = Provider<List<String>>((ref) {
  final settings = ref.watch(seniorSettingsWithDefaultsProvider);
  return settings.jointConsiderations;
});
