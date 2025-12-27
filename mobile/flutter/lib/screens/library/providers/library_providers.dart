import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/program.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';
import '../models/filter_option.dart';
import '../models/exercises_state.dart';

// ============================================================================
// EXERCISE FILTER PROVIDERS (Multi-select)
// ============================================================================

/// Selected muscle groups (body parts) filter
final selectedMuscleGroupsProvider = StateProvider<Set<String>>((ref) => {});

/// Selected equipment filter
final selectedEquipmentsProvider = StateProvider<Set<String>>((ref) => {});

/// Selected exercise types filter
final selectedExerciseTypesProvider = StateProvider<Set<String>>((ref) => {});

/// Selected goals filter
final selectedGoalsProvider = StateProvider<Set<String>>((ref) => {});

/// Selected "suitable for" conditions filter
final selectedSuitableForSetProvider = StateProvider<Set<String>>((ref) => {});

/// Selected "avoid if" conditions filter
final selectedAvoidSetProvider = StateProvider<Set<String>>((ref) => {});

/// Exercise search query
final exerciseSearchProvider = StateProvider<String>((ref) => '');

// ============================================================================
// EXERCISES STATE NOTIFIER
// ============================================================================

/// State notifier for paginated exercises
class ExercisesNotifier extends StateNotifier<ExercisesState> {
  final Ref _ref;

  ExercisesNotifier(this._ref) : super(const ExercisesState());

  Future<void> loadExercises({bool refresh = false}) async {
    if (state.isLoading) return;
    if (!refresh && !state.hasMore) return;

    final newOffset = refresh ? 0 : state.offset;

    state = state.copyWith(
      isLoading: true,
      error: null,
      offset: newOffset,
      exercises: refresh ? [] : state.exercises,
      hasMore: refresh ? true : state.hasMore,
    );

    try {
      final apiClient = _ref.read(apiClientProvider);
      final selectedMuscles = _ref.read(selectedMuscleGroupsProvider);
      final selectedEquipments = _ref.read(selectedEquipmentsProvider);
      final selectedTypes = _ref.read(selectedExerciseTypesProvider);
      final selectedGoals = _ref.read(selectedGoalsProvider);
      final selectedSuitableFor = _ref.read(selectedSuitableForSetProvider);
      final selectedAvoid = _ref.read(selectedAvoidSetProvider);
      final searchQuery = _ref.read(exerciseSearchProvider);

      // Build query parameters
      final queryParams = <String, String>{};
      if (selectedMuscles.isNotEmpty) {
        queryParams['body_parts'] = selectedMuscles.join(',');
      }
      if (selectedEquipments.isNotEmpty) {
        queryParams['equipment'] = selectedEquipments.join(',');
      }
      if (selectedTypes.isNotEmpty) {
        queryParams['exercise_types'] = selectedTypes.join(',');
      }
      if (selectedGoals.isNotEmpty) {
        queryParams['goals'] = selectedGoals.join(',');
      }
      if (selectedSuitableFor.isNotEmpty) {
        queryParams['suitable_for'] = selectedSuitableFor.join(',');
      }
      if (selectedAvoid.isNotEmpty) {
        queryParams['avoid_if'] = selectedAvoid.join(',');
      }
      if (searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      // Add pagination
      queryParams['limit'] = '$exercisesPageSize';
      queryParams['offset'] = '$newOffset';

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final url = '${ApiConstants.library}/exercises?$queryString';

      final response = await apiClient.get(url);

      if (response.statusCode == 200) {
        final data = response.data as List;
        final newExercises = data
            .map((e) => LibraryExercise.fromJson(e as Map<String, dynamic>))
            .toList();

        state = state.copyWith(
          exercises:
              refresh ? newExercises : [...state.exercises, ...newExercises],
          isLoading: false,
          hasMore: newExercises.length >= exercisesPageSize,
          offset: newOffset + newExercises.length,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load exercises',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

/// Exercises state notifier provider
final exercisesNotifierProvider =
    StateNotifierProvider<ExercisesNotifier, ExercisesState>((ref) {
  final notifier = ExercisesNotifier(ref);
  // Auto-load on creation
  notifier.loadExercises();
  return notifier;
});

/// Simple provider for backward compatibility (returns current exercises list)
final exercisesProvider = Provider<AsyncValue<List<LibraryExercise>>>((ref) {
  final state = ref.watch(exercisesNotifierProvider);
  if (state.error != null) {
    return AsyncValue.error(state.error!, StackTrace.current);
  }
  if (state.isLoading && state.exercises.isEmpty) {
    return const AsyncValue.loading();
  }
  return AsyncValue.data(state.exercises);
});

/// Filter options provider - fetches available filter options from API
final filterOptionsProvider =
    FutureProvider.autoDispose<ExerciseFilterOptions>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response =
      await apiClient.get('${ApiConstants.library}/exercises/filter-options');

  if (response.statusCode == 200) {
    return ExerciseFilterOptions.fromJson(
        response.data as Map<String, dynamic>);
  }
  throw Exception('Failed to load filter options');
});

// ============================================================================
// PROGRAM PROVIDERS
// ============================================================================

/// Programs list provider
final programsProvider =
    FutureProvider.autoDispose<List<LibraryProgram>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('${ApiConstants.library}/programs');

  if (response.statusCode == 200) {
    final data = response.data as List;
    return data
        .map((e) => LibraryProgram.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  throw Exception('Failed to load programs');
});

/// Program categories provider
final programCategoriesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response =
      await apiClient.get('${ApiConstants.library}/programs/categories');

  if (response.statusCode == 200) {
    final data = response.data as List;
    return data.map((e) => e['name'] as String).toList();
  }
  throw Exception('Failed to load categories');
});

/// Program search query
final programSearchProvider = StateProvider<String>((ref) => '');

/// Selected program category
final selectedProgramCategoryProvider = StateProvider<String?>((ref) => null);

// ============================================================================
// MY STATS PROVIDERS
// ============================================================================

/// Provider for exercise history
final exerciseHistoryProvider =
    FutureProvider<List<ExerciseHistoryItem>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final userId = await apiClient.getUserId();
  if (userId == null) return [];

  final repository = ref.read(workoutRepositoryProvider);
  return repository.getExerciseHistory(userId: userId, limit: 50);
});

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/// Get total count of active filters
int getActiveFilterCount(WidgetRef ref) {
  int count = 0;
  count += ref.read(selectedMuscleGroupsProvider).length;
  count += ref.read(selectedEquipmentsProvider).length;
  count += ref.read(selectedExerciseTypesProvider).length;
  count += ref.read(selectedGoalsProvider).length;
  count += ref.read(selectedSuitableForSetProvider).length;
  count += ref.read(selectedAvoidSetProvider).length;
  return count;
}

/// Clear all exercise filters
void clearAllFilters(WidgetRef ref) {
  ref.read(selectedMuscleGroupsProvider.notifier).state = {};
  ref.read(selectedEquipmentsProvider.notifier).state = {};
  ref.read(selectedExerciseTypesProvider.notifier).state = {};
  ref.read(selectedGoalsProvider.notifier).state = {};
  ref.read(selectedSuitableForSetProvider.notifier).state = {};
  ref.read(selectedAvoidSetProvider.notifier).state = {};
}

/// Clear exercise search and all filters
void clearSearchAndFilters(WidgetRef ref) {
  ref.read(exerciseSearchProvider.notifier).state = '';
  clearAllFilters(ref);
}

// ============================================================================
// CATEGORY EXERCISES PROVIDER (for Netflix carousel)
// ============================================================================

/// Fetches exercises grouped by body part for Netflix-style carousel
final categoryExercisesProvider =
    FutureProvider.autoDispose<Map<String, List<LibraryExercise>>>((ref) async {
  final apiClient = ref.read(apiClientProvider);

  final result = <String, List<LibraryExercise>>{};

  // Fetch ALL exercises first (the API returns normalized body parts)
  try {
    debugPrint('🎬 [Netflix] Fetching all exercises for categorization...');
    final allResponse = await apiClient.get(
      '${ApiConstants.library}/exercises?limit=500&offset=0',
    );

    if (allResponse.statusCode == 200) {
      final data = allResponse.data as List;
      final allExercises = data
          .map((e) => LibraryExercise.fromJson(e as Map<String, dynamic>))
          .toList();

      debugPrint('🎬 [Netflix] Loaded ${allExercises.length} total exercises');

      // Popular = first 20 exercises
      result['Popular'] = allExercises.take(20).toList();

      // Group by body part (the API returns normalized body_part field)
      final Map<String, List<LibraryExercise>> byBodyPart = {};
      for (final exercise in allExercises) {
        final bodyPart = exercise.bodyPart ?? 'Other';
        byBodyPart.putIfAbsent(bodyPart, () => []);
        byBodyPart[bodyPart]!.add(exercise);
      }

      debugPrint('🎬 [Netflix] Body parts found: ${byBodyPart.keys.toList()}');

      // Map to display categories
      // Combine arm muscles into "Arms"
      final armExercises = <LibraryExercise>[];
      for (final key in ['Biceps', 'Triceps', 'Forearms']) {
        armExercises.addAll(byBodyPart[key] ?? []);
      }
      if (armExercises.isNotEmpty) {
        result['Arms'] = armExercises.take(20).toList();
      }

      // Combine leg muscles into "Legs"
      final legExercises = <LibraryExercise>[];
      for (final key in ['Quadriceps', 'Hamstrings', 'Glutes', 'Calves', 'Hips']) {
        legExercises.addAll(byBodyPart[key] ?? []);
      }
      if (legExercises.isNotEmpty) {
        result['Legs'] = legExercises.take(20).toList();
      }

      // Direct mappings for other categories
      if (byBodyPart['Chest']?.isNotEmpty == true) {
        result['Chest'] = byBodyPart['Chest']!.take(20).toList();
      }
      if (byBodyPart['Back']?.isNotEmpty == true) {
        result['Back'] = byBodyPart['Back']!.take(20).toList();
      }
      if (byBodyPart['Shoulders']?.isNotEmpty == true) {
        result['Shoulders'] = byBodyPart['Shoulders']!.take(20).toList();
      }
      if (byBodyPart['Core']?.isNotEmpty == true) {
        result['Core'] = byBodyPart['Core']!.take(20).toList();
      }

      debugPrint('🎬 [Netflix] Categories built: ${result.keys.toList()}');
      for (final entry in result.entries) {
        debugPrint('🎬 [Netflix]   ${entry.key}: ${entry.value.length} exercises');
      }
    }
  } catch (e) {
    debugPrint('❌ [Netflix] Error loading exercises: $e');
  }

  return result;
});
