import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../providers/library_providers.dart';
import '../widgets/exercise_search_bar.dart';
import '../widgets/netflix_exercise_carousel.dart';
import '../widgets/exercise_card.dart';

/// Netflix-style exercises tab with horizontal carousels by category
class NetflixExercisesTab extends ConsumerStatefulWidget {
  const NetflixExercisesTab({super.key});

  @override
  ConsumerState<NetflixExercisesTab> createState() =>
      _NetflixExercisesTabState();
}

class _NetflixExercisesTabState extends ConsumerState<NetflixExercisesTab> {
  final ScrollController _scrollController = ScrollController();
  String _prevSearchQuery = '';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesState = ref.watch(exercisesNotifierProvider);
    final searchQuery = ref.watch(exerciseSearchProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    final isSearchMode = searchQuery.isNotEmpty;

    // Trigger search refresh when query changes
    if (searchQuery != _prevSearchQuery && searchQuery.isNotEmpty) {
      _prevSearchQuery = searchQuery;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(exercisesNotifierProvider.notifier).loadExercises(refresh: true);
      });
    } else if (searchQuery.isEmpty && _prevSearchQuery.isNotEmpty) {
      _prevSearchQuery = '';
    }

    return Column(
      children: [
        // Search bar
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ExerciseSearchBar(),
        ),
        const SizedBox(height: 8),

        // Content
        Expanded(
          child: isSearchMode
              ? _buildSearchResults(
                  exercisesState, searchQuery, cyan, textMuted, isDark)
              : _buildCategoryCarousels(exercisesState, cyan, isDark),
        ),
      ],
    );
  }

  Widget _buildSearchResults(
    exercisesState,
    String searchQuery,
    Color cyan,
    Color textMuted,
    bool isDark,
  ) {
    // Trigger search when in search mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (searchQuery.isNotEmpty) {
        ref.read(exercisesNotifierProvider.notifier).loadExercises(refresh: true);
      }
    });

    if (exercisesState.isLoading && exercisesState.exercises.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: cyan),
      );
    }

    final results = exercisesState.exercises;

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No exercises found for "$searchQuery"',
              style: TextStyle(color: textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref.read(exerciseSearchProvider.notifier).state = '';
              },
              child: Text(
                'Clear search',
                style: TextStyle(color: cyan),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '${results.length} exercises found',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              return ExerciseCard(exercise: results[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCarousels(exercisesState, Color cyan, bool isDark) {
    // Watch the category exercises provider
    final categoryExercisesAsync = ref.watch(categoryExercisesProvider);

    return categoryExercisesAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: cyan),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: isDark ? AppColors.error : AppColorsLight.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text('Failed to load exercises'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(categoryExercisesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (categoryData) {
        if (categoryData.isEmpty) {
          return const Center(
            child: Text('No exercises available'),
          );
        }

        // Define category order with "Popular" first as hero
        final categoryOrder = [
          'Popular',
          'Chest',
          'Back',
          'Shoulders',
          'Arms',
          'Legs',
          'Core',
          'Cardio',
        ];

        // Build ordered list of categories
        final orderedCategories = <MapEntry<String, List<LibraryExercise>>>[];

        for (final category in categoryOrder) {
          final exercises = categoryData[category];
          if (exercises != null && exercises.isNotEmpty) {
            orderedCategories.add(MapEntry(category, exercises));
          }
        }

        // Add any remaining categories not in the predefined order
        for (final entry in categoryData.entries) {
          if (!categoryOrder.contains(entry.key) && entry.value.isNotEmpty) {
            orderedCategories.add(entry);
          }
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: orderedCategories.length,
          itemBuilder: (context, index) {
            final entry = orderedCategories[index];
            return NetflixExerciseCarousel(
              categoryTitle: entry.key,
              exercises: entry.value,
              isHeroRow: index == 0, // First row is hero
            );
          },
        );
      },
    );
  }
}
