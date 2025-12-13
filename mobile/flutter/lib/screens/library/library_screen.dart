import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/exercise.dart';
import '../../data/models/program.dart';
import '../../data/services/api_client.dart';
import '../../widgets/empty_state.dart';

// ═══════════════════════════════════════════════════════════════════
// EXERCISE FILTER OPTIONS MODEL
// ═══════════════════════════════════════════════════════════════════

class FilterOption {
  final String name;
  final int count;

  FilterOption({required this.name, required this.count});

  factory FilterOption.fromJson(Map<String, dynamic> json) {
    return FilterOption(
      name: json['name'] as String,
      count: json['count'] as int,
    );
  }
}

class ExerciseFilterOptions {
  final List<FilterOption> bodyParts;
  final List<FilterOption> equipment;
  final List<FilterOption> exerciseTypes;
  final List<FilterOption> goals;
  final List<FilterOption> suitableFor;
  final List<FilterOption> avoidIf;
  final int totalExercises;

  ExerciseFilterOptions({
    required this.bodyParts,
    required this.equipment,
    required this.exerciseTypes,
    required this.goals,
    required this.suitableFor,
    required this.avoidIf,
    required this.totalExercises,
  });

  factory ExerciseFilterOptions.fromJson(Map<String, dynamic> json) {
    return ExerciseFilterOptions(
      bodyParts: (json['body_parts'] as List? ?? [])
          .map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      equipment: (json['equipment'] as List? ?? [])
          .map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      exerciseTypes: (json['exercise_types'] as List? ?? [])
          .map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      goals: (json['goals'] as List? ?? [])
          .map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      suitableFor: (json['suitable_for'] as List? ?? [])
          .map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      avoidIf: (json['avoid_if'] as List? ?? [])
          .map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalExercises: json['total_exercises'] as int? ?? 0,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// EXERCISE PROVIDERS
// ═══════════════════════════════════════════════════════════════════

// Multi-select filter providers (Set<String> for multiple selections)
final selectedMuscleGroupsProvider = StateProvider<Set<String>>((ref) => {});
final selectedEquipmentsProvider = StateProvider<Set<String>>((ref) => {});
final selectedExerciseTypesProvider = StateProvider<Set<String>>((ref) => {});
final selectedGoalsProvider = StateProvider<Set<String>>((ref) => {});
final selectedSuitableForSetProvider = StateProvider<Set<String>>((ref) => {});
final selectedAvoidSetProvider = StateProvider<Set<String>>((ref) => {});

// Pagination limit for exercises - load 100 at a time for faster initial load
const int _exercisesPageSize = 100;

// State class for paginated exercises
class ExercisesState {
  final List<LibraryExercise> exercises;
  final bool isLoading;
  final bool hasMore;
  final int offset;
  final String? error;

  const ExercisesState({
    this.exercises = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.offset = 0,
    this.error,
  });

  ExercisesState copyWith({
    List<LibraryExercise>? exercises,
    bool? isLoading,
    bool? hasMore,
    int? offset,
    String? error,
  }) {
    return ExercisesState(
      exercises: exercises ?? this.exercises,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      error: error,
    );
  }
}

// State notifier for paginated exercises
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
      if (selectedMuscles.isNotEmpty) queryParams['body_parts'] = selectedMuscles.join(',');
      if (selectedEquipments.isNotEmpty) queryParams['equipment'] = selectedEquipments.join(',');
      if (selectedTypes.isNotEmpty) queryParams['exercise_types'] = selectedTypes.join(',');
      if (selectedGoals.isNotEmpty) queryParams['goals'] = selectedGoals.join(',');
      if (selectedSuitableFor.isNotEmpty) queryParams['suitable_for'] = selectedSuitableFor.join(',');
      if (selectedAvoid.isNotEmpty) queryParams['avoid_if'] = selectedAvoid.join(',');
      if (searchQuery.isNotEmpty) queryParams['search'] = searchQuery;

      // Add pagination
      queryParams['limit'] = '$_exercisesPageSize';
      queryParams['offset'] = '$newOffset';

      final queryString = queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final url = '${ApiConstants.library}/exercises?$queryString';

      final response = await apiClient.get(url);

      if (response.statusCode == 200) {
        final data = response.data as List;
        final newExercises = data.map((e) => LibraryExercise.fromJson(e as Map<String, dynamic>)).toList();

        state = state.copyWith(
          exercises: refresh ? newExercises : [...state.exercises, ...newExercises],
          isLoading: false,
          hasMore: newExercises.length >= _exercisesPageSize,
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

final exercisesNotifierProvider = StateNotifierProvider<ExercisesNotifier, ExercisesState>((ref) {
  final notifier = ExercisesNotifier(ref);
  // Auto-load on creation
  notifier.loadExercises();
  return notifier;
});

// Simple provider for backward compatibility (returns current exercises list)
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

final filterOptionsProvider = FutureProvider.autoDispose<ExerciseFilterOptions>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('${ApiConstants.library}/exercises/filter-options');

  if (response.statusCode == 200) {
    return ExerciseFilterOptions.fromJson(response.data as Map<String, dynamic>);
  }
  throw Exception('Failed to load filter options');
});

final exerciseSearchProvider = StateProvider<String>((ref) => '');

// ═══════════════════════════════════════════════════════════════════
// PROGRAM PROVIDERS
// ═══════════════════════════════════════════════════════════════════

final programsProvider = FutureProvider.autoDispose<List<LibraryProgram>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('${ApiConstants.library}/programs');

  if (response.statusCode == 200) {
    final data = response.data as List;
    return data.map((e) => LibraryProgram.fromJson(e as Map<String, dynamic>)).toList();
  }
  throw Exception('Failed to load programs');
});

final programCategoriesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.get('${ApiConstants.library}/programs/categories');

  if (response.statusCode == 200) {
    final data = response.data as List;
    return data.map((e) => e['name'] as String).toList();
  }
  throw Exception('Failed to load categories');
});

final programSearchProvider = StateProvider<String>((ref) => '');
final selectedProgramCategoryProvider = StateProvider<String?>((ref) => null);

// ═══════════════════════════════════════════════════════════════════
// MAIN LIBRARY SCREEN WITH TABS
// ═══════════════════════════════════════════════════════════════════

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Library',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Browse exercises and programs',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                        ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(12),
                border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: cyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: cyan,
                unselectedLabelColor: textMuted,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'Exercises'),
                  Tab(text: 'Programs'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _ExercisesTab(),
                  _ProgramsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// EXERCISES TAB
// ═══════════════════════════════════════════════════════════════════

class _ExercisesTab extends ConsumerStatefulWidget {
  const _ExercisesTab();

  @override
  ConsumerState<_ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends ConsumerState<_ExercisesTab> {
  final ScrollController _scrollController = ScrollController();
  Set<String> _prevMuscles = {};
  Set<String> _prevEquipments = {};
  Set<String> _prevTypes = {};
  Set<String> _prevGoals = {};
  Set<String> _prevSuitableFor = {};
  Set<String> _prevAvoid = {};
  String _prevSearch = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom
      ref.read(exercisesNotifierProvider.notifier).loadExercises();
    }
  }

  int _getActiveFilterCount() {
    int count = 0;
    count += ref.read(selectedMuscleGroupsProvider).length;
    count += ref.read(selectedEquipmentsProvider).length;
    count += ref.read(selectedExerciseTypesProvider).length;
    count += ref.read(selectedGoalsProvider).length;
    count += ref.read(selectedSuitableForSetProvider).length;
    count += ref.read(selectedAvoidSetProvider).length;
    return count;
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ExerciseFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercisesState = ref.watch(exercisesNotifierProvider);
    final filterOptions = ref.watch(filterOptionsProvider);
    final searchQuery = ref.watch(exerciseSearchProvider);
    final selectedMuscles = ref.watch(selectedMuscleGroupsProvider);
    final selectedEquipments = ref.watch(selectedEquipmentsProvider);
    final selectedTypes = ref.watch(selectedExerciseTypesProvider);
    final selectedGoals = ref.watch(selectedGoalsProvider);
    final selectedSuitableFor = ref.watch(selectedSuitableForSetProvider);
    final selectedAvoid = ref.watch(selectedAvoidSetProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final activeFilters = _getActiveFilterCount();

    // Get total exercise count from filter options (when no filters applied)
    final totalExercises = filterOptions.valueOrNull?.totalExercises;

    // Check if filters or search changed and refresh exercises
    if (selectedMuscles != _prevMuscles ||
        selectedEquipments != _prevEquipments ||
        selectedTypes != _prevTypes ||
        selectedGoals != _prevGoals ||
        selectedSuitableFor != _prevSuitableFor ||
        selectedAvoid != _prevAvoid ||
        searchQuery != _prevSearch) {
      _prevMuscles = selectedMuscles;
      _prevEquipments = selectedEquipments;
      _prevTypes = selectedTypes;
      _prevGoals = selectedGoals;
      _prevSuitableFor = selectedSuitableFor;
      _prevAvoid = selectedAvoid;
      _prevSearch = searchQuery;
      // Schedule refresh after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(exercisesNotifierProvider.notifier).loadExercises(refresh: true);
      });
    }

    return Column(
      children: [
        // Search bar with filter button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) =>
                      ref.read(exerciseSearchProvider.notifier).state = value,
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    prefixIcon: Icon(Icons.search, color: textMuted),
                    filled: true,
                    fillColor: elevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: isDark ? BorderSide.none : BorderSide(color: AppColorsLight.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: isDark ? BorderSide.none : BorderSide(color: AppColorsLight.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cyan),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Filter button
              GestureDetector(
                onTap: () => _showFilterSheet(context),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: activeFilters > 0 ? cyan.withOpacity(0.2) : elevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: activeFilters > 0 ? cyan : (isDark ? Colors.transparent : AppColorsLight.cardBorder),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.tune,
                        color: activeFilters > 0 ? cyan : textMuted,
                      ),
                      if (activeFilters > 0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: cyan,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$activeFilters',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Active filter chips (show currently applied filters)
        if (activeFilters > 0)
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Body part chips
                ...selectedMuscles.map((muscle) => _ActiveFilterChip(
                  label: muscle,
                  onRemove: () {
                    final newSet = Set<String>.from(selectedMuscles)..remove(muscle);
                    ref.read(selectedMuscleGroupsProvider.notifier).state = newSet;
                  },
                )),
                // Equipment chips
                ...selectedEquipments.map((equip) => _ActiveFilterChip(
                  label: equip,
                  onRemove: () {
                    final newSet = Set<String>.from(selectedEquipments)..remove(equip);
                    ref.read(selectedEquipmentsProvider.notifier).state = newSet;
                  },
                )),
                // Type chips
                ...selectedTypes.map((type) => _ActiveFilterChip(
                  label: type,
                  onRemove: () {
                    final newSet = Set<String>.from(selectedTypes)..remove(type);
                    ref.read(selectedExerciseTypesProvider.notifier).state = newSet;
                  },
                )),
                // Goal chips
                ...selectedGoals.map((goal) => _ActiveFilterChip(
                  label: goal,
                  onRemove: () {
                    final newSet = Set<String>.from(selectedGoals)..remove(goal);
                    ref.read(selectedGoalsProvider.notifier).state = newSet;
                  },
                )),
                // Suitable for chips
                ...selectedSuitableFor.map((suitable) => _ActiveFilterChip(
                  label: suitable,
                  onRemove: () {
                    final newSet = Set<String>.from(selectedSuitableFor)..remove(suitable);
                    ref.read(selectedSuitableForSetProvider.notifier).state = newSet;
                  },
                )),
                // Avoid chips
                ...selectedAvoid.map((avoid) => _ActiveFilterChip(
                  label: 'Avoid: $avoid',
                  onRemove: () {
                    final newSet = Set<String>.from(selectedAvoid)..remove(avoid);
                    ref.read(selectedAvoidSetProvider.notifier).state = newSet;
                  },
                )),
                // Clear all
                if (activeFilters > 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(selectedMuscleGroupsProvider.notifier).state = {};
                        ref.read(selectedEquipmentsProvider.notifier).state = {};
                        ref.read(selectedExerciseTypesProvider.notifier).state = {};
                        ref.read(selectedGoalsProvider.notifier).state = {};
                        ref.read(selectedSuitableForSetProvider.notifier).state = {};
                        ref.read(selectedAvoidSetProvider.notifier).state = {};
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: textMuted.withOpacity(0.5)),
                        ),
                        child: Text(
                          'Clear all',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

        if (activeFilters > 0)
          const SizedBox(height: 8),

        // Exercise list
        Expanded(
          child: Builder(
            builder: (context) {
              // Handle loading state
              if (exercisesState.isLoading && exercisesState.exercises.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(color: cyan),
                );
              }

              // Handle error state
              if (exercisesState.error != null && exercisesState.exercises.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: isDark ? AppColors.error : AppColorsLight.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text('Failed to load exercises: ${exercisesState.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(exercisesNotifierProvider.notifier).loadExercises(refresh: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              // Show exercises (backend handles both filters AND search now)
              final filtered = exercisesState.exercises;

              if (filtered.isEmpty && !exercisesState.isLoading) {
                return EmptyState.noExercises(
                  onAction: searchQuery.isNotEmpty || activeFilters > 0
                      ? () {
                          ref.read(exerciseSearchProvider.notifier).state = '';
                          ref.read(selectedMuscleGroupsProvider.notifier).state = {};
                          ref.read(selectedEquipmentsProvider.notifier).state = {};
                          ref.read(selectedExerciseTypesProvider.notifier).state = {};
                          ref.read(selectedGoalsProvider.notifier).state = {};
                          ref.read(selectedSuitableForSetProvider.notifier).state = {};
                          ref.read(selectedAvoidSetProvider.notifier).state = {};
                        }
                      : null,
                );
              }

              // Calculate display count - show loading indicator if more available
              final hasMoreToLoad = exercisesState.hasMore;
              final itemCount = filtered.length + (hasMoreToLoad ? 1 : 0);

              // Determine count to display:
              // - If no filters/search and we have total from filter options: use that
              // - Otherwise use the current filtered count (which is accurate since backend now filters properly)
              final displayCount = (activeFilters == 0 && searchQuery.isEmpty && totalExercises != null)
                  ? totalExercises
                  : filtered.length;
              // Show "+" only if there might be more to load
              final showPlus = exercisesState.hasMore && (activeFilters > 0 || searchQuery.isNotEmpty);

              return Column(
                children: [
                  // Result count header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          showPlus
                              ? '$displayCount+ ${displayCount == 1 ? 'exercise' : 'exercises'} found'
                              : '$displayCount ${displayCount == 1 ? 'exercise' : 'exercises'} found',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Exercise list with infinite scroll
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        // Loading indicator at the end
                        if (index >= filtered.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: exercisesState.isLoading
                                  ? CircularProgressIndicator(color: cyan)
                                  : TextButton(
                                      onPressed: () => ref.read(exercisesNotifierProvider.notifier).loadExercises(),
                                      child: Text(
                                        'Load more',
                                        style: TextStyle(color: cyan),
                                      ),
                                    ),
                            ),
                          );
                        }

                        final exercise = filtered[index];
                        // Only animate the first 10 items to avoid performance issues
                        if (index < 10) {
                          return _ExerciseCard(exercise: exercise)
                              .animate()
                              .fadeIn(delay: Duration(milliseconds: index * 30));
                        }
                        return _ExerciseCard(exercise: exercise);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ACTIVE FILTER CHIP
// ═══════════════════════════════════════════════════════════════════

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveFilterChip({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: cyan.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cyan),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: cyan,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close,
                size: 14,
                color: cyan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// EXERCISE FILTER SHEET
// ═══════════════════════════════════════════════════════════════════

class _ExerciseFilterSheet extends ConsumerWidget {
  const _ExerciseFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterOptionsAsync = ref.watch(filterOptionsProvider);
    final selectedMuscles = ref.watch(selectedMuscleGroupsProvider);
    final selectedEquipments = ref.watch(selectedEquipmentsProvider);
    final selectedTypes = ref.watch(selectedExerciseTypesProvider);
    final selectedGoals = ref.watch(selectedGoalsProvider);
    final selectedSuitableFor = ref.watch(selectedSuitableForSetProvider);
    final selectedAvoid = ref.watch(selectedAvoidSetProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBackground = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final success = isDark ? AppColors.success : AppColorsLight.success;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: sheetBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(selectedMuscleGroupsProvider.notifier).state = {};
                      ref.read(selectedEquipmentsProvider.notifier).state = {};
                      ref.read(selectedExerciseTypesProvider.notifier).state = {};
                      ref.read(selectedGoalsProvider.notifier).state = {};
                      ref.read(selectedSuitableForSetProvider.notifier).state = {};
                      ref.read(selectedAvoidSetProvider.notifier).state = {};
                    },
                    child: Text(
                      'Clear all',
                      style: TextStyle(color: cyan),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Filter content
            Expanded(
              child: filterOptionsAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: cyan),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: textMuted, size: 48),
                      const SizedBox(height: 16),
                      Text('Failed to load filters', style: TextStyle(color: textMuted)),
                      TextButton(
                        onPressed: () => ref.refresh(filterOptionsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (filterOptions) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Body Part / Muscle Group section
                        _FilterSection(
                          title: 'BODY PART',
                          icon: Icons.accessibility_new,
                          color: purple,
                          options: filterOptions.bodyParts,
                          selectedValues: selectedMuscles,
                          onToggle: (value) {
                            final newSet = Set<String>.from(selectedMuscles);
                            // Case-insensitive check for existing value
                            final existing = newSet.firstWhere(
                              (v) => v.toLowerCase() == value.toLowerCase(),
                              orElse: () => '',
                            );
                            if (existing.isNotEmpty) {
                              newSet.remove(existing);
                            } else {
                              newSet.add(value);
                            }
                            ref.read(selectedMuscleGroupsProvider.notifier).state = newSet;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Equipment section
                        _FilterSection(
                          title: 'EQUIPMENT',
                          icon: Icons.fitness_center,
                          color: cyan,
                          options: filterOptions.equipment,
                          selectedValues: selectedEquipments,
                          onToggle: (value) {
                            final newSet = Set<String>.from(selectedEquipments);
                            final existing = newSet.firstWhere(
                              (v) => v.toLowerCase() == value.toLowerCase(),
                              orElse: () => '',
                            );
                            if (existing.isNotEmpty) {
                              newSet.remove(existing);
                            } else {
                              newSet.add(value);
                            }
                            ref.read(selectedEquipmentsProvider.notifier).state = newSet;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Exercise Type section
                        _FilterSection(
                          title: 'EXERCISE TYPE',
                          icon: Icons.category,
                          color: success,
                          options: filterOptions.exerciseTypes,
                          selectedValues: selectedTypes,
                          onToggle: (value) {
                            final newSet = Set<String>.from(selectedTypes);
                            final existing = newSet.firstWhere(
                              (v) => v.toLowerCase() == value.toLowerCase(),
                              orElse: () => '',
                            );
                            if (existing.isNotEmpty) {
                              newSet.remove(existing);
                            } else {
                              newSet.add(value);
                            }
                            ref.read(selectedExerciseTypesProvider.notifier).state = newSet;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Goals section
                        _FilterSection(
                          title: 'GOALS',
                          icon: Icons.track_changes,
                          color: Colors.orange,
                          options: filterOptions.goals,
                          selectedValues: selectedGoals,
                          onToggle: (value) {
                            final newSet = Set<String>.from(selectedGoals);
                            final existing = newSet.firstWhere(
                              (v) => v.toLowerCase() == value.toLowerCase(),
                              orElse: () => '',
                            );
                            if (existing.isNotEmpty) {
                              newSet.remove(existing);
                            } else {
                              newSet.add(value);
                            }
                            ref.read(selectedGoalsProvider.notifier).state = newSet;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Suitable For section
                        _FilterSection(
                          title: 'SUITABLE FOR',
                          icon: Icons.person_outline,
                          color: Colors.teal,
                          options: filterOptions.suitableFor,
                          selectedValues: selectedSuitableFor,
                          onToggle: (value) {
                            final newSet = Set<String>.from(selectedSuitableFor);
                            final existing = newSet.firstWhere(
                              (v) => v.toLowerCase() == value.toLowerCase(),
                              orElse: () => '',
                            );
                            if (existing.isNotEmpty) {
                              newSet.remove(existing);
                            } else {
                              newSet.add(value);
                            }
                            ref.read(selectedSuitableForSetProvider.notifier).state = newSet;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Avoid If section
                        _FilterSection(
                          title: 'AVOID IF YOU HAVE',
                          icon: Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                          options: filterOptions.avoidIf,
                          selectedValues: selectedAvoid,
                          onToggle: (value) {
                            final newSet = Set<String>.from(selectedAvoid);
                            final existing = newSet.firstWhere(
                              (v) => v.toLowerCase() == value.toLowerCase(),
                              orElse: () => '',
                            );
                            if (existing.isNotEmpty) {
                              newSet.remove(existing);
                            } else {
                              newSet.add(value);
                            }
                            ref.read(selectedAvoidSetProvider.notifier).state = newSet;
                          },
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Apply button - extra bottom padding for floating nav bar
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).padding.bottom + 88, // 88 = nav bar (56) + margins (32)
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// FILTER SECTION (Multi-select)
// ═══════════════════════════════════════════════════════════════════

class _FilterSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<FilterOption> options;
  final Set<String> selectedValues;
  final Function(String) onToggle;
  final int initialShowCount;
  final bool initiallyExpanded;

  const _FilterSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.options,
    required this.selectedValues,
    required this.onToggle,
    this.initialShowCount = 6,
    this.initiallyExpanded = false,
  });

  @override
  State<_FilterSection> createState() => _FilterSectionState();
}

class _FilterSectionState extends State<_FilterSection> {
  bool _showAll = false;
  bool _isExpanded = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded || widget.selectedValues.isNotEmpty;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_FilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-expand if any value is selected
    if (widget.selectedValues.isNotEmpty && !_isExpanded) {
      setState(() => _isExpanded = true);
    }
  }

  List<FilterOption> get _filteredOptions {
    List<FilterOption> options;
    if (_searchQuery.isEmpty) {
      options = List.from(widget.options);
    } else {
      options = widget.options
          .where((opt) => opt.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Ensure "Other" is always at the end
    options.sort((a, b) {
      final aIsOther = a.name.toLowerCase() == 'other';
      final bIsOther = b.name.toLowerCase() == 'other';
      if (aIsOther && !bIsOther) return 1;
      if (!aIsOther && bIsOther) return -1;
      return 0; // Keep original order for non-"Other" items
    });

    return options;
  }

  String _shortenName(String name) {
    // Shorten long equipment names
    if (name.length <= 20) return name;

    // Common abbreviations
    final replacements = {
      'Hammer Strength': 'HS',
      'Iso-Lateral': 'Iso',
      'MTS ': '',
      'Machine': 'Mach.',
      'Resistance Band': 'Res. Band',
      'Cable Pulley Machine': 'Cable',
      'Dual Cable Pulley Machine': 'Dual Cable',
      'Plate-Loaded': 'Plate',
      'Plate Loaded': 'Plate',
    };

    String shortened = name;
    for (final entry in replacements.entries) {
      shortened = shortened.replaceAll(entry.key, entry.value);
    }

    // If still too long, truncate
    if (shortened.length > 25) {
      shortened = '${shortened.substring(0, 22)}...';
    }

    return shortened;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    final filteredOpts = _filteredOptions;
    final displayOptions = _showAll || _searchQuery.isNotEmpty
        ? filteredOpts
        : filteredOpts.take(widget.initialShowCount).toList();
    final hasMore = filteredOpts.length > widget.initialShowCount && _searchQuery.isEmpty;

    final hasSelection = widget.selectedValues.isNotEmpty;
    final selectionCount = widget.selectedValues.length;
    final selectionText = selectionCount == 1
        ? widget.selectedValues.first
        : '$selectionCount selected';

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasSelection ? widget.color.withOpacity(0.3) : cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsible header
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.icon, size: 18, color: widget.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                              ),
                            ),
                            if (hasSelection) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: widget.color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$selectionCount',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: widget.color,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (hasSelection)
                          Text(
                            selectionText,
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.color,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Expandable options
          if (_isExpanded) ...[
            Divider(height: 1, color: cardBorder),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search field - only show if many options
                  if (widget.options.length > 6) ...[
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: glassSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _searchQuery = value),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search ${widget.title.toLowerCase()}...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: textMuted,
                          ),
                          prefixIcon: Icon(Icons.search, size: 20, color: textMuted),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: Icon(Icons.close, size: 18, color: textMuted),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // No results message
                  if (displayOptions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No matching options',
                          style: TextStyle(
                            fontSize: 13,
                            color: textMuted,
                          ),
                        ),
                      ),
                    )
                  else
                  // Options wrap - multi-select chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: displayOptions.map((option) {
                      final isSelected = widget.selectedValues.any(
                        (v) => v.toLowerCase() == option.name.toLowerCase()
                      );
                      final displayName = _shortenName(option.name);
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => widget.onToggle(option.name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? widget.color.withOpacity(0.2) : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? widget.color : Colors.transparent,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  Icon(Icons.check, size: 16, color: widget.color),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected ? widget.color : textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Show more/less button
                  if (hasMore)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _showAll = !_showAll),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _showAll ? 'Show less' : 'Show ${widget.options.length - widget.initialShowCount} more',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: widget.color,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _showAll ? Icons.expand_less : Icons.expand_more,
                              size: 18,
                              color: widget.color,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PROGRAMS TAB
// ═══════════════════════════════════════════════════════════════════

class _ProgramsTab extends ConsumerWidget {
  const _ProgramsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(programsProvider);
    final categoriesAsync = ref.watch(programCategoriesProvider);
    final searchQuery = ref.watch(programSearchProvider);
    final selectedCategory = ref.watch(selectedProgramCategoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (value) =>
                ref.read(programSearchProvider.notifier).state = value,
            decoration: InputDecoration(
              hintText: 'Search programs...',
              prefixIcon: Icon(Icons.search, color: textMuted),
              filled: true,
              fillColor: elevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: isDark ? BorderSide.none : BorderSide(color: AppColorsLight.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: isDark ? BorderSide.none : BorderSide(color: AppColorsLight.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cyan),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Category filter chips
        SizedBox(
          height: 40,
          child: categoriesAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (categories) {
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: selectedCategory == null,
                    onTap: () {
                      ref.read(selectedProgramCategoryProvider.notifier).state = null;
                    },
                  ),
                  ...categories.map((category) => _FilterChip(
                        label: category,
                        isSelected: selectedCategory == category,
                        onTap: () {
                          ref.read(selectedProgramCategoryProvider.notifier).state =
                              selectedCategory == category ? null : category;
                        },
                      )),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Programs list
        Expanded(
          child: programsAsync.when(
            loading: () => Center(
              child: CircularProgressIndicator(color: cyan),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: isDark ? AppColors.error : AppColorsLight.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text('Failed to load programs: $e'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(programsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (programs) {
              var filtered = programs;

              if (searchQuery.isNotEmpty) {
                filtered = filtered
                    .where((p) =>
                        p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        p.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        (p.celebrityName?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
                        (p.goals?.any((g) => g.toLowerCase().contains(searchQuery.toLowerCase())) ?? false))
                    .toList();
              }

              if (selectedCategory != null) {
                filtered = filtered
                    .where((p) => p.category == selectedCategory)
                    .toList();
              }

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: textMuted,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text('No programs found'),
                      if (searchQuery.isNotEmpty || selectedCategory != null)
                        TextButton(
                          onPressed: () {
                            ref.read(programSearchProvider.notifier).state = '';
                            ref.read(selectedProgramCategoryProvider.notifier).state = null;
                          },
                          child: const Text('Clear filters'),
                        ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final program = filtered[index];
                  return _ProgramCard(program: program)
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: index * 50));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? cyan.withOpacity(0.2) : elevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? cyan : cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? cyan : textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// EXERCISE CARD
// ═══════════════════════════════════════════════════════════════════

class _ExerciseCard extends StatelessWidget {
  final LibraryExercise exercise;

  const _ExerciseCard({required this.exercise});

  IconData _getBodyPartIcon(String? bodyPart) {
    switch (bodyPart?.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.airline_seat_flat;
      case 'shoulders':
        return Icons.accessibility_new;
      case 'biceps':
      case 'triceps':
      case 'arms':
        return Icons.sports_martial_arts;
      case 'core':
      case 'abdominals':
        return Icons.self_improvement;
      case 'quadriceps':
      case 'legs':
      case 'glutes':
      case 'hamstrings':
      case 'calves':
        return Icons.directions_run;
      case 'cardio':
      case 'other':
        return Icons.monitor_heart;
      case 'neck':
        return Icons.face;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final hasVideo = exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => _showExerciseDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
        ),
        child: Row(
          children: [
            // Thumbnail with video indicator
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    purple.withOpacity(0.3),
                    cyan.withOpacity(0.2),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Body part icon
                  Icon(
                    _getBodyPartIcon(exercise.bodyPart),
                    size: 36,
                    color: purple.withOpacity(0.8),
                  ),
                  // Video play indicator
                  if (hasVideo)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cyan,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          size: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (exercise.muscleGroup != null) ...[
                          _InfoBadge(
                            icon: Icons.accessibility_new,
                            text: exercise.muscleGroup!,
                            color: purple,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (exercise.difficulty != null)
                          _InfoBadge(
                            icon: Icons.signal_cellular_alt,
                            text: exercise.difficulty!,
                            color: AppColors.getDifficultyColor(exercise.difficulty!),
                          ),
                      ],
                    ),
                    if (exercise.equipment != null &&
                        exercise.equipment!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        exercise.equipment!.take(2).join(', '),
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Arrow
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExerciseDetailSheet(exercise: exercise),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PROGRAM CARD
// ═══════════════════════════════════════════════════════════════════

class _ProgramCard extends StatelessWidget {
  final LibraryProgram program;

  const _ProgramCard({required this.program});

  Color _getCategoryColor(String category, bool isDark) {
    switch (category.toLowerCase()) {
      case 'celebrity workout':
        return isDark ? AppColors.purple : AppColorsLight.purple;
      case 'goal-based':
        return isDark ? AppColors.cyan : AppColorsLight.cyan;
      case 'sport training':
        return isDark ? AppColors.success : AppColorsLight.success;
      default:
        return isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'celebrity workout':
        return Icons.star;
      case 'goal-based':
        return Icons.track_changes;
      case 'sport training':
        return Icons.sports;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final categoryColor = _getCategoryColor(program.category, isDark);

    return GestureDetector(
      onTap: () => _showProgramDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
        ),
        child: Row(
          children: [
            // Category icon area
            Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Icon(
                  _getCategoryIcon(program.category),
                  size: 32,
                  color: categoryColor,
                ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Program name
                    Text(
                      program.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Category & Difficulty badges
                    Row(
                      children: [
                        _InfoBadge(
                          icon: _getCategoryIcon(program.category),
                          text: program.category,
                          color: categoryColor,
                        ),
                        if (program.difficultyLevel != null) ...[
                          const SizedBox(width: 8),
                          _InfoBadge(
                            icon: Icons.signal_cellular_alt,
                            text: program.difficultyLevel!,
                            color: AppColors.getDifficultyColor(program.difficultyLevel!),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Duration & Sessions
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: textMuted),
                        const SizedBox(width: 4),
                        Text(
                          program.durationDisplay,
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.repeat, size: 12, color: textMuted),
                        const SizedBox(width: 4),
                        Text(
                          program.sessionsDisplay,
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Arrow
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProgramDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProgramDetailSheet(program: program),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// INFO BADGE (Shared)
// ═══════════════════════════════════════════════════════════════════

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoBadge({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// EXERCISE DETAIL SHEET
// ═══════════════════════════════════════════════════════════════════

class _ExerciseDetailSheet extends ConsumerStatefulWidget {
  final LibraryExercise exercise;

  const _ExerciseDetailSheet({required this.exercise});

  @override
  ConsumerState<_ExerciseDetailSheet> createState() => _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends ConsumerState<_ExerciseDetailSheet> {
  VideoPlayerController? _videoController;
  bool _isLoadingVideo = true;
  bool _videoInitialized = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadVideo() async {
    // Use original_name to fetch the video
    final exerciseName = widget.exercise.originalName ?? widget.exercise.name;
    if (exerciseName.isEmpty) {
      setState(() {
        _isLoadingVideo = false;
        _videoError = 'No exercise name';
      });
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final videoResponse = await apiClient.get(
        '/videos/by-exercise/${Uri.encodeComponent(exerciseName)}',
      );

      if (videoResponse.statusCode == 200 && videoResponse.data != null) {
        final videoUrl = videoResponse.data['url'] as String?;
        if (videoUrl != null && mounted) {
          _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
          await _videoController!.initialize();
          _videoController!.setLooping(true);
          _videoController!.setVolume(0);
          _videoController!.play();
          setState(() {
            _videoInitialized = true;
            _isLoadingVideo = false;
          });
        }
      } else {
        setState(() {
          _isLoadingVideo = false;
          _videoError = 'Video not available';
        });
      }
    } catch (e) {
      debugPrint('Error loading video: $e');
      if (mounted) {
        setState(() {
          _isLoadingVideo = false;
          _videoError = 'Failed to load video';
        });
      }
    }
  }

  void _toggleVideo() {
    if (_videoController == null) return;
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBackground = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: sheetBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Video Player
              GestureDetector(
                onTap: _toggleVideo,
                child: Container(
                  width: double.infinity,
                  height: 300,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: elevated,
                    borderRadius: BorderRadius.circular(16),
                    border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _buildVideoContent(cyan, textMuted, purple),
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              const SizedBox(height: 12),

              // Badges
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (exercise.muscleGroup != null)
                      _DetailBadge(
                        icon: Icons.accessibility_new,
                        label: 'Muscle',
                        value: exercise.muscleGroup!,
                        color: purple,
                      ),
                    if (exercise.difficulty != null)
                      _DetailBadge(
                        icon: Icons.signal_cellular_alt,
                        label: 'Level',
                        value: exercise.difficulty!,
                        color: AppColors.getDifficultyColor(exercise.difficulty!),
                      ),
                    if (exercise.type != null)
                      _DetailBadge(
                        icon: Icons.category,
                        label: 'Type',
                        value: exercise.type!,
                        color: cyan,
                      ),
                  ],
                ),
              ),

              // Equipment
              if (exercise.equipment != null && exercise.equipment!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EQUIPMENT NEEDED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: exercise.equipment!.map((eq) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: elevated,
                              borderRadius: BorderRadius.circular(8),
                              border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  size: 14,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  eq,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              // Instructions
              if (exercise.instructions != null &&
                  exercise.instructions!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INSTRUCTIONS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...exercise.instructions!.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: cyan.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: cyan,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent(Color cyan, Color textMuted, Color purple) {
    if (_isLoadingVideo) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: cyan),
            const SizedBox(height: 12),
            Text(
              'Loading video...',
              style: TextStyle(color: textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_videoInitialized && _videoController != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          // Play/Pause overlay
          AnimatedOpacity(
            opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.play_arrow,
                size: 48,
                color: cyan,
              ),
            ),
          ),
          // Muted indicator
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.volume_off,
                size: 16,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      );
    }

    // Fallback - no video available
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off,
            size: 48,
            color: purple.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            _videoError ?? 'Video not available',
            style: TextStyle(color: textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PROGRAM DETAIL SHEET
// ═══════════════════════════════════════════════════════════════════

class _ProgramDetailSheet extends StatelessWidget {
  final LibraryProgram program;

  const _ProgramDetailSheet({required this.program});

  Color _getCategoryColor(String category, bool isDark) {
    switch (category.toLowerCase()) {
      case 'celebrity workout':
        return isDark ? AppColors.purple : AppColorsLight.purple;
      case 'goal-based':
        return isDark ? AppColors.cyan : AppColorsLight.cyan;
      case 'sport training':
        return isDark ? AppColors.success : AppColorsLight.success;
      default:
        return isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'celebrity workout':
        return Icons.star;
      case 'goal-based':
        return Icons.track_changes;
      case 'sport training':
        return Icons.sports;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBackground = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final categoryColor = _getCategoryColor(program.category, isDark);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: sheetBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Hero area with icon
              Container(
                width: double.infinity,
                height: 150,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      categoryColor.withOpacity(0.3),
                      categoryColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(program.category),
                    size: 64,
                    color: categoryColor,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  program.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),

              // Celebrity name if present
              if (program.celebrityName != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Inspired by ${program.celebrityName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Badges
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DetailBadge(
                      icon: _getCategoryIcon(program.category),
                      label: 'Category',
                      value: program.category,
                      color: categoryColor,
                    ),
                    if (program.difficultyLevel != null)
                      _DetailBadge(
                        icon: Icons.signal_cellular_alt,
                        label: 'Level',
                        value: program.difficultyLevel!,
                        color: AppColors.getDifficultyColor(program.difficultyLevel!),
                      ),
                    if (program.durationWeeks != null)
                      _DetailBadge(
                        icon: Icons.calendar_today,
                        label: 'Duration',
                        value: '${program.durationWeeks} weeks',
                        color: cyan,
                      ),
                    if (program.sessionsPerWeek != null)
                      _DetailBadge(
                        icon: Icons.repeat,
                        label: 'Sessions',
                        value: '${program.sessionsPerWeek}/week',
                        color: cyan,
                      ),
                  ],
                ),
              ),

              // Description
              if (program.description != null && program.description!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DESCRIPTION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        program.description!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Goals
              if (program.goals != null && program.goals!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GOALS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: program.goals!.map((goal) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: cyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 14,
                                  color: cyan,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  goal,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: cyan,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              // Tags
              if (program.tags != null && program.tags!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TAGS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: program.tags!.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: elevated,
                              borderRadius: BorderRadius.circular(16),
                              border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Start Program button (placeholder)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Program "${program.name}" selected! Feature coming soon.'),
                          backgroundColor: cyan,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Start This Program',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// DETAIL BADGE (Shared)
// ═══════════════════════════════════════════════════════════════════

class _DetailBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(8),
        border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: textMuted,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
