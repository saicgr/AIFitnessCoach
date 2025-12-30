import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/custom_exercise.dart';
import '../../data/repositories/custom_exercise_repository.dart';
import '../../data/services/api_client.dart';

/// State for custom exercises
class CustomExercisesState {
  final List<CustomExercise> exercises;
  final CustomExerciseStats? stats;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const CustomExercisesState({
    this.exercises = const [],
    this.stats,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  CustomExercisesState copyWith({
    List<CustomExercise>? exercises,
    CustomExerciseStats? stats,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return CustomExercisesState(
      exercises: exercises ?? this.exercises,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  /// Get only simple (non-composite) exercises
  List<CustomExercise> get simpleExercises =>
      exercises.where((e) => !e.isComposite).toList();

  /// Get only composite exercises
  List<CustomExercise> get compositeExercises =>
      exercises.where((e) => e.isComposite).toList();

  /// Get exercises grouped by muscle
  Map<String, List<CustomExercise>> get exercisesByMuscle {
    final Map<String, List<CustomExercise>> grouped = {};
    for (final exercise in exercises) {
      final muscle = exercise.primaryMuscle;
      grouped.putIfAbsent(muscle, () => []);
      grouped[muscle]!.add(exercise);
    }
    return grouped;
  }

  /// Find an exercise by ID
  CustomExercise? findById(String id) {
    try {
      return exercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Custom exercises provider
final customExercisesProvider =
    StateNotifierProvider<CustomExercisesNotifier, CustomExercisesState>((ref) {
  return CustomExercisesNotifier(ref);
});

/// Notifier for managing custom exercises state
class CustomExercisesNotifier extends StateNotifier<CustomExercisesState> {
  final Ref _ref;
  bool _initialized = false;

  CustomExercisesNotifier(this._ref) : super(const CustomExercisesState());

  /// Initialize/refresh custom exercises from API
  Future<void> initialize() async {
    if (_initialized && state.exercises.isNotEmpty) {
      return; // Already initialized with data
    }
    await refresh();
    _initialized = true;
  }

  /// Force refresh from API
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final repository = _ref.read(customExerciseRepositoryProvider);

      // Fetch exercises and stats in parallel
      final results = await Future.wait([
        repository.getAllCustomExercises(userId),
        repository.getStats(userId),
      ]);

      final exercises = results[0] as List<CustomExercise>;
      final stats = results[1] as CustomExerciseStats;

      state = state.copyWith(
        exercises: exercises,
        stats: stats,
        isLoading: false,
      );
      debugPrint('🏋️ [CustomExercisesProvider] Loaded ${exercises.length} exercises');
    } catch (e) {
      debugPrint('❌ [CustomExercisesProvider] Error loading: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create a simple custom exercise
  Future<CustomExercise?> createSimpleExercise({
    required String name,
    required String primaryMuscle,
    required String equipment,
    String? instructions,
    int defaultSets = 3,
    int? defaultReps = 10,
    bool isCompound = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final repository = _ref.read(customExerciseRepositoryProvider);
      final request = CreateCustomExerciseRequest(
        name: name,
        primaryMuscle: primaryMuscle,
        equipment: equipment,
        instructions: instructions,
        defaultSets: defaultSets,
        defaultReps: defaultReps,
        isCompound: isCompound,
      );

      final exercise = await repository.createSimpleExercise(
        userId: userId,
        request: request,
      );

      // Add to local state
      state = state.copyWith(
        exercises: [exercise, ...state.exercises],
        isLoading: false,
        successMessage: 'Created "${exercise.name}"',
      );

      debugPrint('✅ [CustomExercisesProvider] Created: ${exercise.name}');
      return exercise;
    } catch (e) {
      debugPrint('❌ [CustomExercisesProvider] Error creating: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Create a composite exercise
  Future<CustomExercise?> createCompositeExercise({
    required String name,
    required String primaryMuscle,
    List<String> secondaryMuscles = const [],
    required String equipment,
    required ComboType comboType,
    required List<ComponentExercise> components,
    String? instructions,
    String? customNotes,
    int defaultSets = 3,
    int defaultRestSeconds = 60,
    List<String> tags = const [],
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      if (components.length < 2) {
        throw Exception('Composite exercises require at least 2 components');
      }

      final repository = _ref.read(customExerciseRepositoryProvider);
      final request = CreateCompositeExerciseRequest(
        name: name,
        primaryMuscle: primaryMuscle,
        secondaryMuscles: secondaryMuscles,
        equipment: equipment,
        comboType: comboType.value,
        componentExercises: components,
        instructions: instructions,
        customNotes: customNotes,
        defaultSets: defaultSets,
        defaultRestSeconds: defaultRestSeconds,
        tags: tags,
      );

      final exercise = await repository.createCompositeExercise(
        userId: userId,
        request: request,
      );

      // Add to local state
      state = state.copyWith(
        exercises: [exercise, ...state.exercises],
        isLoading: false,
        successMessage: 'Created "${exercise.name}"',
      );

      debugPrint('✅ [CustomExercisesProvider] Created composite: ${exercise.name}');
      return exercise;
    } catch (e) {
      debugPrint('❌ [CustomExercisesProvider] Error creating composite: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Update a custom exercise
  Future<CustomExercise?> updateExercise({
    required String exerciseId,
    String? name,
    String? primaryMuscle,
    List<String>? secondaryMuscles,
    String? equipment,
    String? instructions,
    int? defaultSets,
    int? defaultReps,
    int? defaultRestSeconds,
    String? comboType,
    List<ComponentExercise>? componentExercises,
    String? customNotes,
    List<String>? tags,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final repository = _ref.read(customExerciseRepositoryProvider);

      // Build update map with only non-null values
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (primaryMuscle != null) updates['primary_muscle'] = primaryMuscle;
      if (secondaryMuscles != null) updates['secondary_muscles'] = secondaryMuscles;
      if (equipment != null) updates['equipment'] = equipment;
      if (instructions != null) updates['instructions'] = instructions;
      if (defaultSets != null) updates['default_sets'] = defaultSets;
      if (defaultReps != null) updates['default_reps'] = defaultReps;
      if (defaultRestSeconds != null) updates['default_rest_seconds'] = defaultRestSeconds;
      if (comboType != null) updates['combo_type'] = comboType;
      if (componentExercises != null) {
        updates['component_exercises'] = componentExercises.map((c) => c.toJson()).toList();
      }
      if (customNotes != null) updates['custom_notes'] = customNotes;
      if (tags != null) updates['tags'] = tags;

      final updated = await repository.updateExercise(
        userId: userId,
        exerciseId: exerciseId,
        updates: updates,
      );

      // Update in local state
      final updatedList = state.exercises.map((e) {
        if (e.id == exerciseId) return updated;
        return e;
      }).toList();

      state = state.copyWith(
        exercises: updatedList,
        isLoading: false,
        successMessage: 'Updated "${updated.name}"',
      );

      debugPrint('✅ [CustomExercisesProvider] Updated: ${updated.name}');
      return updated;
    } catch (e) {
      debugPrint('❌ [CustomExercisesProvider] Error updating: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Delete a custom exercise
  Future<bool> deleteExercise(String exerciseId) async {
    final exercise = state.findById(exerciseId);
    final exerciseName = exercise?.name ?? 'Exercise';

    // Optimistic update
    state = state.copyWith(
      exercises: state.exercises.where((e) => e.id != exerciseId).toList(),
    );

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final repository = _ref.read(customExerciseRepositoryProvider);
      await repository.deleteExercise(userId: userId, exerciseId: exerciseId);

      state = state.copyWith(successMessage: 'Deleted "$exerciseName"');
      debugPrint('✅ [CustomExercisesProvider] Deleted: $exerciseId');
      return true;
    } catch (e) {
      debugPrint('❌ [CustomExercisesProvider] Error deleting: $e');
      // Rollback optimistic update
      if (exercise != null) {
        state = state.copyWith(
          exercises: [...state.exercises, exercise],
          error: e.toString(),
        );
      }
      return false;
    }
  }

  /// Log usage of a custom exercise (e.g., when completed in a workout)
  Future<void> logUsage({
    required String exerciseId,
    String? workoutId,
    int? rating,
    String? notes,
  }) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) return;

      final repository = _ref.read(customExerciseRepositoryProvider);
      await repository.logUsage(
        userId: userId,
        exerciseId: exerciseId,
        workoutId: workoutId,
        rating: rating,
        notes: notes,
      );

      // Update local usage count
      final updatedList = state.exercises.map((e) {
        if (e.id == exerciseId) {
          return e.copyWith(
            usageCount: e.usageCount + 1,
            lastUsed: DateTime.now().toIso8601String(),
          );
        }
        return e;
      }).toList();

      state = state.copyWith(exercises: updatedList);
      debugPrint('✅ [CustomExercisesProvider] Logged usage of $exerciseId');
    } catch (e) {
      debugPrint('⚠️ [CustomExercisesProvider] Failed to log usage: $e');
      // Don't update state on error - usage logging is not critical
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear success message
  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }
}

/// Provider for searching the exercise library
final exerciseSearchProvider = FutureProvider.family<List<ExerciseSearchResult>, String>((ref, query) async {
  if (query.length < 2) return [];

  final repository = ref.read(customExerciseRepositoryProvider);
  return repository.searchLibrary(query: query);
});

/// Convenience providers
final hasCustomExercisesProvider = Provider<bool>((ref) {
  return ref.watch(customExercisesProvider).exercises.isNotEmpty;
});

final customExerciseCountProvider = Provider<int>((ref) {
  return ref.watch(customExercisesProvider).exercises.length;
});

final compositeExerciseCountProvider = Provider<int>((ref) {
  return ref.watch(customExercisesProvider).compositeExercises.length;
});
