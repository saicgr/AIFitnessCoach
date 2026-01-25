import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../data/services/haptic_service.dart';
import '../components/exercise_filter_sheet.dart';
import '../providers/library_providers.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _prevSearchQuery = '';
  bool _isSearchExpanded = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExerciseFilterSheet(),
    );
  }

  void _toggleSearch() {
    HapticService.light();
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (_isSearchExpanded) {
        _searchFocusNode.requestFocus();
      } else {
        _searchFocusNode.unfocus();
        _searchController.clear();
        ref.read(exerciseSearchProvider.notifier).state = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final exercisesState = ref.watch(exercisesNotifierProvider);
    final searchQuery = ref.watch(exerciseSearchProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final accentColor = ThemeColors.of(context).accent;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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

    // Get active filter count for badge
    final activeFilterCount = getActiveFilterCount(ref);

    return Stack(
      children: [
        // Main content
        Column(
          children: [
            // Content
            Expanded(
              child: isSearchMode
                  ? _buildSearchResults(
                      exercisesState, searchQuery, cyan, textMuted, isDark)
                  : _buildCategoryCarousels(exercisesState, cyan, isDark),
            ),
          ],
        ),

        // Floating buttons - search and filter
        Positioned(
          left: _isSearchExpanded ? 16 : null,
          right: 16,
          bottom: bottomPadding + 16,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: _isSearchExpanded
                ? _buildExpandedSearchBar(context, isDark, elevated, accentColor, textMuted, activeFilterCount)
                : _buildFloatingButtons(context, isDark, accentColor, activeFilterCount),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingButtons(BuildContext context, bool isDark, Color accentColor, int activeFilterCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Filter button
        GestureDetector(
          onTap: () => _showFilterSheet(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.tune_rounded,
                        color: accentColor,
                        size: 26,
                      ),
                    ),
                    if (activeFilterCount > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$activeFilterCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Search button
        GestureDetector(
          onTap: _toggleSearch,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.search_rounded,
                    color: accentColor,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedSearchBar(
    BuildContext context,
    bool isDark,
    Color elevated,
    Color accentColor,
    Color textMuted,
    int activeFilterCount,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 18),
              Icon(
                Icons.search_rounded,
                color: accentColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (value) {
                    ref.read(exerciseSearchProvider.notifier).state = value;
                  },
                  cursorColor: accentColor,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    hintStyle: TextStyle(
                      color: textMuted.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Filter button inside search bar
              GestureDetector(
                onTap: () => _showFilterSheet(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.tune_rounded,
                          color: accentColor,
                          size: 18,
                        ),
                      ),
                      if (activeFilterCount > 0)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$activeFilterCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Close button
              GestureDetector(
                onTap: _toggleSearch,
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.close_rounded,
                      color: accentColor,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
                _searchController.clear();
                setState(() {
                  _isSearchExpanded = false;
                });
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
