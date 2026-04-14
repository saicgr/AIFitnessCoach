import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/branded_program.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';
import '../models/filter_option.dart';
import '../models/exercises_state.dart';

// Re-export exceptions for consumers
export '../../../core/exceptions/app_exceptions.dart';

// In-memory cache for category exercises (H5: avoid re-fetching all exercises)
CategoryExercisesData? _categoryExercisesCache;
DateTime? _categoryCacheTime;
const _categoryCacheDuration = Duration(hours: 24);

// ============================================================================
// EXERCISE FILTER PROVIDERS (Multi-select)
// ============================================================================

/// Selected muscle groups (body parts) filter
final selectedMuscleGroupsProvider = StateProvider<Set<String>>((ref) => {});

/// Selected equipment filter
final selectedEquipmentsProvider = StateProvider<Set<String>>((ref) => {});

/// Selected DB-category filter (e.g. strength, cardio, yoga — lowercase)
final selectedCategoriesProvider = StateProvider<Set<String>>((ref) => {});

/// Selected exercise types filter
final selectedExerciseTypesProvider = StateProvider<Set<String>>((ref) => {});

/// Selected goals filter
final selectedGoalsProvider = StateProvider<Set<String>>((ref) => {});

/// Selected "suitable for" conditions filter
final selectedSuitableForSetProvider = StateProvider<Set<String>>((ref) => {});

/// Selected "avoid if" conditions filter
final selectedAvoidSetProvider = StateProvider<Set<String>>((ref) => {});

/// Filter to show only exercises the user has performed
final performedOnlyProvider = StateProvider<bool>((ref) => false);

/// Exercise search query
final exerciseSearchProvider = StateProvider<String>((ref) => '');

/// Search suggestion from backend (e.g., "Did you mean: treadmill?")
final searchSuggestionProvider = StateProvider<String?>((ref) => null);

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
      final selectedCategories = _ref.read(selectedCategoriesProvider);
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
      if (selectedCategories.isNotEmpty) {
        queryParams['categories'] = selectedCategories.join(',');
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

      // Read search suggestion header from response
      final suggestion = response.headers.value('x-search-suggestion');
      _ref.read(searchSuggestionProvider.notifier).state = suggestion;

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
/// M1: Removed autoDispose — this is static reference data that rarely changes
final filterOptionsProvider =
    FutureProvider<ExerciseFilterOptions>((ref) async {
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

/// Programs list provider - now uses branded-programs API
/// M1: Removed autoDispose — program list is stable reference data
final programsProvider =
    FutureProvider<List<BrandedProgram>>((ref) async {
  final apiClient = ref.read(apiClientProvider);

  try {
    final response = await apiClient.get('${ApiConstants.library}/branded-programs');

    if (response.statusCode == 200) {
      try {
        final data = response.data as List;
        return data
            .map((e) => BrandedProgram.fromJson(e as Map<String, dynamic>))
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

/// Program categories provider - now uses branded-programs API
/// M1: Removed autoDispose — category list is stable reference data
final programCategoriesProvider =
    FutureProvider<List<String>>((ref) async {
  final apiClient = ref.read(apiClientProvider);

  try {
    final response =
        await apiClient.get('${ApiConstants.library}/branded-programs/categories');

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
  count += ref.read(selectedCategoriesProvider).length;
  count += ref.read(selectedExerciseTypesProvider).length;
  count += ref.read(selectedGoalsProvider).length;
  count += ref.read(selectedSuitableForSetProvider).length;
  count += ref.read(selectedAvoidSetProvider).length;
  if (ref.read(performedOnlyProvider)) count += 1;
  return count;
}

/// Clear all exercise filters
void clearAllFilters(WidgetRef ref) {
  ref.read(selectedMuscleGroupsProvider.notifier).state = {};
  ref.read(selectedEquipmentsProvider.notifier).state = {};
  ref.read(selectedCategoriesProvider.notifier).state = {};
  ref.read(selectedExerciseTypesProvider.notifier).state = {};
  ref.read(selectedGoalsProvider.notifier).state = {};
  ref.read(selectedSuitableForSetProvider.notifier).state = {};
  ref.read(selectedAvoidSetProvider.notifier).state = {};
  ref.read(performedOnlyProvider.notifier).state = false;
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
  /// Flat list of every exercise (deduplicated, sorted A-Z) for "All Exercises" section
  final List<LibraryExercise> allExercisesSorted;
  /// True total count per category from backend (not the capped preview length).
  /// Nullable so that stale cached instances from hot-reload (before this field
  /// existed) can't crash field access — consumers must fall back to `all[k].length`.
  final Map<String, int>? totalCounts;

  const CategoryExercisesData({
    required this.preview,
    required this.all,
    this.allExercisesSorted = const [],
    this.totalCounts,
  });
}

/// Fetches exercises grouped by body part for Netflix-style carousel.
/// Uses the /exercises/grouped endpoint (20 per group) instead of fetching all 1600+.
/// "See All" screens lazy-load the full category via paginated API calls.
/// H5: Uses in-memory cache (valid for 24 hours) to avoid re-fetching.
final categoryExercisesProvider =
    FutureProvider<CategoryExercisesData>((ref) async {
  // H5: Check in-memory cache first
  if (_categoryExercisesCache != null && _categoryCacheTime != null) {
    final elapsed = DateTime.now().difference(_categoryCacheTime!);
    if (elapsed < _categoryCacheDuration) {
      debugPrint('✅ [CategoryExercises] Returning cached data (age: ${elapsed.inMinutes}m)');
      return _categoryExercisesCache!;
    }
  }

  final apiClient = ref.read(apiClientProvider);
  final preview = <String, List<LibraryExercise>>{};
  final all = <String, List<LibraryExercise>>{};

  try {
    // Fetch exercises grouped by body part (20 per group) — much lighter than limit=5000
    final response = await apiClient.get(
      '${ApiConstants.library}/exercises/grouped?limit_per_group=20',
    );

    if (response.statusCode != 200) {
      throw ApiException(
        message: 'Failed to load exercises',
        statusCode: response.statusCode,
      );
    }

    final data = response.data as List;
    if (data.isEmpty) {
      return CategoryExercisesData(preview: preview, all: all);
    }

    // Parse grouped response: [{body_part, count, exercises}, ...]
    // `count` = true total in DB; `exercises` = capped preview (limit_per_group).
    final Map<String, List<LibraryExercise>> byBodyPart = {};
    final Map<String, int> bodyPartCounts = {};
    for (final group in data) {
      final bodyPart = group['body_part'] as String;
      final exercises = (group['exercises'] as List)
          .map((e) => LibraryExercise.fromJson(e as Map<String, dynamic>))
          .toList();
      byBodyPart[bodyPart] = exercises;
      bodyPartCounts[bodyPart] = (group['count'] as num?)?.toInt() ?? exercises.length;
    }

    // Popular = first 20 from the largest groups
    final popularExercises = <LibraryExercise>[];
    for (final group in data) {
      final exercises = (group['exercises'] as List)
          .map((e) => LibraryExercise.fromJson(e as Map<String, dynamic>))
          .toList();
      popularExercises.addAll(exercises);
      if (popularExercises.length >= 20) break;
    }
    if (popularExercises.isNotEmpty) {
      all['Popular'] = popularExercises;
      preview['Popular'] = popularExercises.take(20).toList();
    }

    // Aggregated counts mirror the category composition below.
    final Map<String, int> totalCounts = {};
    if (popularExercises.isNotEmpty) {
      totalCounts['Popular'] = popularExercises.length;
    }

    // Combine arm muscles into "Arms"
    final armExercises = <LibraryExercise>[];
    var armsTotal = 0;
    for (final key in ['Biceps', 'Triceps', 'Forearms']) {
      armExercises.addAll(byBodyPart[key] ?? []);
      armsTotal += bodyPartCounts[key] ?? 0;
    }
    if (armExercises.isNotEmpty) {
      all['Arms'] = armExercises;
      preview['Arms'] = armExercises.take(20).toList();
      totalCounts['Arms'] = armsTotal;
    }

    // Combine leg muscles into "Legs"
    final legExercises = <LibraryExercise>[];
    var legsTotal = 0;
    for (final key in ['Quadriceps', 'Hamstrings', 'Glutes', 'Calves', 'Hips']) {
      legExercises.addAll(byBodyPart[key] ?? []);
      legsTotal += bodyPartCounts[key] ?? 0;
    }
    if (legExercises.isNotEmpty) {
      all['Legs'] = legExercises;
      preview['Legs'] = legExercises.take(20).toList();
      totalCounts['Legs'] = legsTotal;
    }

    // Direct mappings for other categories
    for (final category in ['Chest', 'Back', 'Shoulders', 'Core']) {
      if (byBodyPart[category]?.isNotEmpty == true) {
        all[category] = byBodyPart[category]!;
        preview[category] = byBodyPart[category]!.take(20).toList();
        totalCounts[category] = bodyPartCounts[category] ?? byBodyPart[category]!.length;
      }
    }

    // Build allExercisesSorted from the grouped preview data (deduplicated, sorted A-Z)
    final seenIds = <String>{};
    final allFlat = <LibraryExercise>[];
    for (final exercises in all.values) {
      for (final exercise in exercises) {
        if (exercise.id != null && seenIds.add(exercise.id!)) {
          allFlat.add(exercise);
        }
      }
    }
    allFlat.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // H5: Store result in cache
    final result = CategoryExercisesData(
      preview: preview,
      all: all,
      allExercisesSorted: allFlat,
      totalCounts: totalCounts,
    );
    _categoryExercisesCache = result;
    _categoryCacheTime = DateTime.now();
    debugPrint('✅ [CategoryExercises] Cached ${all.length} categories, ${allFlat.length} exercises (grouped endpoint)');

    return result;
  } catch (e) {
    if (e is AppException) rethrow;
    debugPrint('❌ [CategoryExercises] Error: $e');
    throw ExceptionHandler.handle(e);
  }
});
