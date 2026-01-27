import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/empty_state.dart';
import '../providers/library_providers.dart';
import '../widgets/exercise_search_bar.dart';
import '../widgets/filter_button.dart';
import '../widgets/active_filter_chips.dart';
import '../widgets/exercise_card.dart';
import '../components/exercise_filter_sheet.dart';

/// Exercises tab content with search, filters, and paginated list
class ExercisesTab extends ConsumerStatefulWidget {
  const ExercisesTab({super.key});

  @override
  ConsumerState<ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends ConsumerState<ExercisesTab> {
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

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExerciseFilterSheet(),
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
    final activeFilters = getActiveFilterCount(ref);

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
              const Expanded(child: ExerciseSearchBar()),
              const SizedBox(width: 12),
              FilterButton(
                activeFilterCount: activeFilters,
                onTap: () => _showFilterSheet(context),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Active filter chips
        if (activeFilters > 0) ...[
          const ActiveFilterChipsList(),
          const SizedBox(height: 8),
        ],

        // Exercise list
        Expanded(
          child: _buildExerciseList(
            context,
            exercisesState,
            searchQuery,
            activeFilters,
            totalExercises,
            cyan,
            textMuted,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseList(
    BuildContext context,
    exercisesState,
    String searchQuery,
    int activeFilters,
    int? totalExercises,
    Color cyan,
    Color textMuted,
    bool isDark,
  ) {
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
              onPressed: () => ref
                  .read(exercisesNotifierProvider.notifier)
                  .loadExercises(refresh: true),
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
            ? () => clearSearchAndFilters(ref)
            : null,
      );
    }

    // Calculate display count - show loading indicator if more available
    final hasMoreToLoad = exercisesState.hasMore;
    final itemCount = filtered.length + (hasMoreToLoad ? 1 : 0);

    // Determine count to display:
    // - If no filters/search and we have total from filter options: use that
    // - Otherwise use the current filtered count (which is accurate since backend now filters properly)
    final displayCount = (activeFilters == 0 &&
            searchQuery.isEmpty &&
            totalExercises != null)
        ? totalExercises
        : filtered.length;
    // Show "+" only if there might be more to load
    final showPlus = exercisesState.hasMore &&
        (activeFilters > 0 || searchQuery.isNotEmpty);

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
                            onPressed: () => ref
                                .read(exercisesNotifierProvider.notifier)
                                .loadExercises(),
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
                return ExerciseCard(exercise: exercise)
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: index * 30));
              }
              return ExerciseCard(exercise: exercise);
            },
          ),
        ),
      ],
    );
  }
}
