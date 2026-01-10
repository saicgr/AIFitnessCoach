import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/program.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';
import '../models/filter_option.dart';
import '../models/exercises_state.dart';

// Re-export exceptions for consumers
export '../../../core/exceptions/app_exceptions.dart';

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
        try {
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
        } catch (e) {
          // JSON parsing error
          debugPrint('❌ [Exercises] Parse error: $e');
          final parseException = const ParseException();
          state = state.copyWith(
            isLoading: false,
            error: parseException.userMessage,
          );
        }
      } else {
        // API returned non-200 status
        final apiException = ApiException(
          message: 'Failed to load exercises',
          statusCode: response.statusCode,
        );
        debugPrint('❌ [Exercises] API error: ${response.statusCode}');
        state = state.copyWith(
          isLoading: false,
          error: apiException.userMessage,
        );
      }
    } catch (e) {
      // Handle network and other errors
      debugPrint('❌ [Exercises] Error: $e');
      final appException = ExceptionHandler.handle(e);
      state = state.copyWith(
        isLoading: false,
        error: appException.userMessage,
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

  try {
    final response =
        await apiClient.get('${ApiConstants.library}/exercises/filter-options');

    if (response.statusCode == 200) {
      try {
        return ExerciseFilterOptions.fromJson(
            response.data as Map<String, dynamic>);
      } catch (e) {
        debugPrint('❌ [FilterOptions] Parse error: $e');
        throw const ParseException();
      }
    }

    debugPrint('❌ [FilterOptions] API error: ${response.statusCode}');
    throw ApiException(
      message: 'Failed to load filter options',
      statusCode: response.statusCode,
    );
  } catch (e) {
    if (e is AppException) rethrow;
    debugPrint('❌ [FilterOptions] Error: $e');
    throw ExceptionHandler.handle(e);
  }
});

// ============================================================================
// PROGRAM PROVIDERS
// ============================================================================

/// Programs list provider
final programsProvider =
    FutureProvider.autoDispose<List<LibraryProgram>>((ref) async {
  final apiClient = ref.read(apiClientProvider);

  try {
    final response = await apiClient.get('${ApiConstants.library}/programs');

    if (response.statusCode == 200) {
      try {
        final data = response.data as List;
        return data
            .map((e) => LibraryProgram.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('❌ [Programs] Parse error: $e');
        throw const ParseException();
      }
    }

    debugPrint('❌ [Programs] API error: ${response.statusCode}');
    throw ApiException(
      message: 'Failed to load programs',
      statusCode: response.statusCode,
    );
  } catch (e) {
    if (e is AppException) rethrow;
    debugPrint('❌ [Programs] Error: $e');
    throw ExceptionHandler.handle(e);
  }
});

/// Program categories provider
final programCategoriesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final apiClient = ref.read(apiClientProvider);

  try {
    final response =
        await apiClient.get('${ApiConstants.library}/programs/categories');

    if (response.statusCode == 200) {
      try {
        final data = response.data as List;
        return data.map((e) => e['name'] as String).toList();
      } catch (e) {
        debugPrint('❌ [Categories] Parse error: $e');
        throw const ParseException();
      }
    }

    debugPrint('❌ [Categories] API error: ${response.statusCode}');
    throw ApiException(
      message: 'Failed to load categories',
      statusCode: response.statusCode,
    );
  } catch (e) {
    if (e is AppException) rethrow;
    debugPrint('❌ [Categories] Error: $e');
    throw ExceptionHandler.handle(e);
  }
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

/// Category exercises data with preview (20) and all exercises for See All
class CategoryExercisesData {
  /// Preview exercises for carousel (limited to 20)
  final Map<String, List<LibraryExercise>> preview;
  /// All exercises for each category (for See All screen)
  final Map<String, List<LibraryExercise>> all;

  const CategoryExercisesData({
    required this.preview,
    required this.all,
  });
}

/// Fetches exercises grouped by body part for Netflix-style carousel
final categoryExercisesProvider =
    FutureProvider<CategoryExercisesData>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final preview = <String, List<LibraryExercise>>{};
  final all = <String, List<LibraryExercise>>{};

  try {
    // Fetch more exercises from API for better See All experience
    final response = await apiClient.get(
      '${ApiConstants.library}/exercises?limit=500&offset=0',
    );

    if (response.statusCode != 200) {
      throw ApiException(
        message: 'Failed to load exercises',
        statusCode: response.statusCode,
      );
    }

    final data = response.data as List;
    final allExercises = data
        .map((e) => LibraryExercise.fromJson(e as Map<String, dynamic>))
        .toList();

    if (allExercises.isEmpty) {
      return CategoryExercisesData(preview: preview, all: all);
    }

    // Popular = first exercises
    all['Popular'] = allExercises.take(50).toList();
    preview['Popular'] = allExercises.take(20).toList();

    // Group by body part
    final Map<String, List<LibraryExercise>> byBodyPart = {};
    for (final exercise in allExercises) {
      final bodyPart = exercise.bodyPart ?? 'Other';
      byBodyPart.putIfAbsent(bodyPart, () => []);
      byBodyPart[bodyPart]!.add(exercise);
    }

    // Combine arm muscles into "Arms"
    final armExercises = <LibraryExercise>[];
    for (final key in ['Biceps', 'Triceps', 'Forearms']) {
      armExercises.addAll(byBodyPart[key] ?? []);
    }
    if (armExercises.isNotEmpty) {
      all['Arms'] = armExercises;
      preview['Arms'] = armExercises.take(20).toList();
    }

    // Combine leg muscles into "Legs"
    final legExercises = <LibraryExercise>[];
    for (final key in ['Quadriceps', 'Hamstrings', 'Glutes', 'Calves', 'Hips']) {
      legExercises.addAll(byBodyPart[key] ?? []);
    }
    if (legExercises.isNotEmpty) {
      all['Legs'] = legExercises;
      preview['Legs'] = legExercises.take(20).toList();
    }

    // Direct mappings for other categories
    if (byBodyPart['Chest']?.isNotEmpty == true) {
      all['Chest'] = byBodyPart['Chest']!;
      preview['Chest'] = byBodyPart['Chest']!.take(20).toList();
    }
    if (byBodyPart['Back']?.isNotEmpty == true) {
      all['Back'] = byBodyPart['Back']!;
      preview['Back'] = byBodyPart['Back']!.take(20).toList();
    }
    if (byBodyPart['Shoulders']?.isNotEmpty == true) {
      all['Shoulders'] = byBodyPart['Shoulders']!;
      preview['Shoulders'] = byBodyPart['Shoulders']!.take(20).toList();
    }
    if (byBodyPart['Core']?.isNotEmpty == true) {
      all['Core'] = byBodyPart['Core']!;
      preview['Core'] = byBodyPart['Core']!.take(20).toList();
    }

    return CategoryExercisesData(preview: preview, all: all);
  } catch (e) {
    if (e is AppException) rethrow;
    debugPrint('❌ [CategoryExercises] Error: $e');
    throw ExceptionHandler.handle(e);
  }
});
