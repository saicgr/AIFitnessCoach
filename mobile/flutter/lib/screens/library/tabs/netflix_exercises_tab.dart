import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../data/models/exercise.dart';
import '../providers/library_providers.dart';
import '../widgets/exercise_search_bar.dart';
import '../widgets/netflix_exercise_carousel.dart';

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
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

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
              color: textMuted.withValues(alpha: 0.5),
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

    // Group search results by body part for Netflix-style display
    final Map<String, List<LibraryExercise>> groupedResults = {};
    for (final exercise in results) {
      final bodyPart = exercise.bodyPart ?? 'Other';
      groupedResults.putIfAbsent(bodyPart, () => []);
      groupedResults[bodyPart]!.add(exercise);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search results header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Results for "$searchQuery"',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${results.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cyan,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Display results grouped by body part using Netflix carousels
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: groupedResults.entries.map((entry) {
              return NetflixExerciseCarousel(
                categoryTitle: entry.key,
                exercises: entry.value,
              );
            }).toList(),
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
      error: (error, stackTrace) {
        // Get user-friendly error message
        final errorMessage = error is AppException
            ? error.userMessage
            : 'Unable to load data. Please try again';
        final isNetworkError = error is NetworkException;

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isNetworkError ? Icons.wifi_off : Icons.error_outline,
                  color: isDark ? AppColors.error : AppColorsLight.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(categoryExercisesProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      data: (categoryData) {
        if (categoryData.preview.isEmpty) {
          return const Center(
            child: Text('No exercises available'),
          );
        }

        // Define category order
        final categoryOrder = [
          'Popular',
          'Chest',
          'Back',
          'Shoulders',
          'Arms',
          'Legs',
          'Core',
        ];

        // Build ordered list of categories (excluding Popular for hero)
        final orderedCategories = <String>[];
        final popularExercises = categoryData.preview['Popular'] ?? [];

        for (final category in categoryOrder) {
          if (category == 'Popular') continue; // Skip - used for hero
          final exercises = categoryData.preview[category];
          if (exercises != null && exercises.isNotEmpty) {
            orderedCategories.add(category);
          }
        }

        // Add any remaining categories not in the predefined order
        for (final category in categoryData.preview.keys) {
          if (!categoryOrder.contains(category) &&
              categoryData.preview[category]?.isNotEmpty == true &&
              !orderedCategories.contains(category)) {
            orderedCategories.add(category);
          }
        }

        return ListView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 100),
          physics: const BouncingScrollPhysics(),
          children: [
            // Featured Hero Section at top
            if (popularExercises.isNotEmpty)
              NetflixHeroSection(exercises: popularExercises.take(8).toList()),

            // Category rows (Netflix style with multiple cards per row)
            ...orderedCategories.map((category) => NetflixExerciseCarousel(
              categoryTitle: category,
              exercises: categoryData.preview[category] ?? [],
              allExercises: categoryData.all[category],
            )),
          ],
        );
      },
    );
  }
}
