import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/services/food_search_service.dart' as search;
import '../../../widgets/empty_state.dart';
import 'food_search_bar.dart';

/// A results list widget for food search
class FoodSearchResults extends ConsumerWidget {
  final String userId;
  final Function(search.FoodSearchResult result) onResultSelected;
  final FoodSearchFilter? filter;
  final ScrollController? scrollController;
  final bool showCategories;
  final VoidCallback? onAnalyzeWithAI;

  const FoodSearchResults({
    super.key,
    required this.userId,
    required this.onResultSelected,
    this.filter,
    this.scrollController,
    this.showCategories = true,
    this.onAnalyzeWithAI,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(search.foodSearchStateProvider);

    return searchState.when(
      data: (state) => _buildStateWidget(context, ref, state),
      loading: () => const _ShimmerLoadingResults(),
      error: (error, _) => _ErrorState(
        message: error.toString(),
        onRetry: () {
          final service = ref.read(search.foodSearchServiceProvider);
          service.search('', userId); // Reset search
        },
      ),
    );
  }

  Widget _buildStateWidget(
      BuildContext context, WidgetRef ref, search.FoodSearchState state) {
    switch (state) {
      case search.FoodSearchInitial():
        return _InitialState(
          userId: userId,
          onSearchTapped: (query) {
            final service = ref.read(search.foodSearchServiceProvider);
            final cachedLogs = ref.read(nutritionProvider).recentLogs;
            service.search(query, userId, cachedLogs: cachedLogs);
          },
        );

      case search.FoodSearchLoading():
        return const _ShimmerLoadingResults();

      case search.FoodSearchResults(:final saved, :final recent, :final database, :final foodDatabase, :final query, :final fromCache):
        if (saved.isEmpty && recent.isEmpty && database.isEmpty && foodDatabase.isEmpty) {
          return _NoResultsState(query: query, onAnalyzeWithAI: onAnalyzeWithAI);
        }

        // Apply filter
        List<search.FoodSearchResult> filteredSaved = saved;
        List<search.FoodSearchResult> filteredRecent = recent;
        List<search.FoodSearchResult> filteredDatabase = database;
        List<search.FoodSearchResult> filteredFoodDatabase = foodDatabase;

        if (filter != null) {
          switch (filter!) {
            case FoodSearchFilter.saved:
              filteredRecent = [];
              filteredDatabase = [];
              filteredFoodDatabase = [];
              break;
            case FoodSearchFilter.recent:
              filteredSaved = [];
              filteredDatabase = [];
              filteredFoodDatabase = [];
              break;
            case FoodSearchFilter.foodDatabase:
              filteredSaved = [];
              filteredRecent = [];
              filteredDatabase = [];
              break;
            case FoodSearchFilter.all:
              // Show all
              break;
          }
        }

        return _ResultsList(
          saved: filteredSaved,
          recent: filteredRecent,
          database: filteredDatabase,
          foodDatabase: filteredFoodDatabase,
          onResultSelected: onResultSelected,
          scrollController: scrollController,
          showCategories: showCategories,
          fromCache: fromCache,
        );

      case search.FoodSearchError(:final message, :final query):
        return _ErrorState(
          message: message,
          onRetry: () {
            final service = ref.read(search.foodSearchServiceProvider);
            final cachedLogs = ref.read(nutritionProvider).recentLogs;
            service.search(query, userId, cachedLogs: cachedLogs);
          },
        );
    }
  }
}

/// Initial state showing recent searches
class _InitialState extends ConsumerWidget {
  final String userId;
  final Function(String query) onSearchTapped;

  const _InitialState({
    required this.userId,
    required this.onSearchTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RecentSearchesList(
          onSearchTapped: onSearchTapped,
          onClearAll: () {
            ref.read(search.recentSearchesProvider.notifier).clearSearches();
          },
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Type to search your saved foods, recent meals, or the database.',
            style: TextStyle(
              color: textMuted,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// Shimmer loading effect for results
class _ShimmerLoadingResults extends StatefulWidget {
  const _ShimmerLoadingResults();

  @override
  State<_ShimmerLoadingResults> createState() => _ShimmerLoadingResultsState();
}

class _ShimmerLoadingResultsState extends State<_ShimmerLoadingResults>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final highlightColor =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              height: 72,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment(_animation.value - 1, 0),
                  end: Alignment(_animation.value, 0),
                  colors: [
                    baseColor,
                    highlightColor,
                    baseColor,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Icon skeleton
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: highlightColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Name skeleton
                          Container(
                            height: 14,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: highlightColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Calories skeleton
                          Container(
                            height: 12,
                            width: 80,
                            decoration: BoxDecoration(
                              color: highlightColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Arrow skeleton
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: highlightColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Results list with categories
class _ResultsList extends StatelessWidget {
  final List<search.FoodSearchResult> saved;
  final List<search.FoodSearchResult> recent;
  final List<search.FoodSearchResult> database;
  final List<search.FoodSearchResult> foodDatabase;
  final Function(search.FoodSearchResult result) onResultSelected;
  final ScrollController? scrollController;
  final bool showCategories;
  final bool fromCache;

  const _ResultsList({
    required this.saved,
    required this.recent,
    required this.database,
    this.foodDatabase = const [],
    required this.onResultSelected,
    this.scrollController,
    this.showCategories = true,
    this.fromCache = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build flat list with headers
    final List<Widget> items = [];

    // Cache indicator
    if (fromCache) {
      items.add(_CacheIndicator(isDark: isDark));
    }

    // Saved Foods section
    if (saved.isNotEmpty && showCategories) {
      items.add(_SectionHeader(
        title: 'Saved Foods',
        icon: Icons.bookmark_rounded,
        count: saved.length,
        isDark: isDark,
      ));
      items.addAll(saved.map((result) => _ResultCard(
            result: result,
            onTap: () => onResultSelected(result),
            isDark: isDark,
          )));
    }

    // Recent section
    if (recent.isNotEmpty && showCategories) {
      items.add(_SectionHeader(
        title: 'Recent',
        icon: Icons.history_rounded,
        count: recent.length,
        isDark: isDark,
      ));
      items.addAll(recent.map((result) => _ResultCard(
            result: result,
            onTap: () => onResultSelected(result),
            isDark: isDark,
          )));
    }

    // Database section
    if (database.isNotEmpty && showCategories) {
      items.add(_SectionHeader(
        title: 'Database',
        icon: Icons.storage_rounded,
        count: database.length,
        isDark: isDark,
      ));
      items.addAll(database.map((result) => _ResultCard(
            result: result,
            onTap: () => onResultSelected(result),
            isDark: isDark,
          )));
    }

    // Food Database section
    if (foodDatabase.isNotEmpty && showCategories) {
      items.add(_SectionHeader(
        title: 'Food Database',
        icon: Icons.restaurant_menu_rounded,
        count: foodDatabase.length,
        isDark: isDark,
      ));
      items.addAll(foodDatabase.map((result) => _ResultCard(
            result: result,
            onTap: () => onResultSelected(result),
            isDark: isDark,
          )));
    }

    // If not showing categories, just show flat list
    if (!showCategories) {
      final allResults = [...saved, ...recent, ...database, ...foodDatabase];
      items.clear();
      items.addAll(allResults.map((result) => _ResultCard(
            result: result,
            onTap: () => onResultSelected(result),
            isDark: isDark,
          )));
    }

    return ListView(
      controller: scrollController,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: items,
    );
  }
}

/// Cache indicator pill
class _CacheIndicator extends StatelessWidget {
  final bool isDark;

  const _CacheIndicator({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flash_on_rounded,
            size: 14,
            color: textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            'Instant results',
            style: TextStyle(
              color: textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header for categorized results
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: textMuted.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual result card
class _ResultCard extends StatelessWidget {
  final search.FoodSearchResult result;
  final VoidCallback onTap;
  final bool isDark;

  const _ResultCard({
    required this.result,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Get source-specific icon and color
    final (IconData icon, Color color) = _getSourceIcon(result.source, isDark);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
              ),
            ),
            child: Row(
              children: [
                // Source icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Food info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        result.name,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Brand if available
                      if (result.brand != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          result.brand!,
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 4),

                      // Nutrition info
                      Row(
                        children: [
                          _NutrientPill(
                            label: '${result.calories}',
                            unit: 'kcal',
                            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                            isDark: isDark,
                          ),
                          if (result.protein != null) ...[
                            const SizedBox(width: 8),
                            _NutrientPill(
                              label: '${result.protein!.toStringAsFixed(0)}g',
                              unit: 'protein',
                              color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                              isDark: isDark,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Chevron
                Icon(
                  Icons.chevron_right_rounded,
                  color: textMuted,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (IconData, Color) _getSourceIcon(search.FoodSearchSource source, bool isDark) {
    switch (source) {
      case search.FoodSearchSource.saved:
        return (
          Icons.bookmark_rounded,
          isDark ? AppColors.cyan : AppColorsLight.cyan
        );
      case search.FoodSearchSource.recent:
        return (
          Icons.history_rounded,
          isDark ? AppColors.purple : AppColorsLight.purple
        );
      case search.FoodSearchSource.database:
        return (
          Icons.storage_rounded,
          isDark ? AppColors.teal : AppColorsLight.teal
        );
      case search.FoodSearchSource.barcode:
        return (
          Icons.qr_code_scanner_rounded,
          isDark ? AppColors.orange : AppColorsLight.orange
        );
      case search.FoodSearchSource.foodDatabase:
        return (
          Icons.restaurant_menu_rounded,
          isDark ? AppColors.green : AppColorsLight.green
        );
    }
  }
}

/// Small nutrient pill
class _NutrientPill extends StatelessWidget {
  final String label;
  final String unit;
  final Color color;
  final bool isDark;

  const _NutrientPill({
    required this.label,
    required this.unit,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          unit,
          style: TextStyle(
            color: textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// No results state
class _NoResultsState extends StatelessWidget {
  final String query;
  final VoidCallback? onAnalyzeWithAI;

  const _NoResultsState({required this.query, this.onAnalyzeWithAI});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No foods found',
            subtitle: 'No saved foods match "$query".',
            iconColor: AppColors.textMuted,
            useLottie: false,
          ),
          if (onAnalyzeWithAI != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAnalyzeWithAI,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text(
                  'Analyze with AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI will estimate nutrition for "$query"',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Error state
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Something went wrong',
        subtitle: message,
        actionLabel: 'Retry',
        onAction: onRetry,
        iconColor: AppColors.error,
        useLottie: false,
      ),
    );
  }
}

/// Inline food search widget combining search bar and results
class FoodSearchWidget extends ConsumerWidget {
  final String userId;
  final Function(search.FoodSearchResult result) onResultSelected;
  final bool autofocus;
  final String? hintText;

  const FoodSearchWidget({
    super.key,
    required this.userId,
    required this.onResultSelected,
    this.autofocus = false,
    this.hintText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FoodSearchBar(
          userId: userId,
          autofocus: autofocus,
          hintText: hintText,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: FoodSearchResults(
            userId: userId,
            onResultSelected: onResultSelected,
          ),
        ),
      ],
    );
  }
}
