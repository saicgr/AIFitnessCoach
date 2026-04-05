import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/nutrition.dart';
import '../../data/models/recipe.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/haptic_service.dart';
import '../../data/providers/xp_provider.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/pill_app_bar.dart';
import '../../widgets/glass_sheet.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/segmented_tab_bar.dart';
import 'recipe_builder_sheet.dart';

part 'food_library_screen_part_food_library_card.dart';


/// Sort options for the food library
enum FoodLibrarySortOption {
  name('Name', Icons.sort_by_alpha_rounded),
  frequency('Most Used', Icons.trending_up_rounded),
  recent('Recently Added', Icons.schedule_rounded);

  final String label;
  final IconData icon;
  const FoodLibrarySortOption(this.label, this.icon);
}

/// Tab type for the food library
enum FoodLibraryTab {
  all,
  saved,
  recipes,
}

/// Unified food library item type
sealed class FoodLibraryItem {
  String get id;
  String get name;
  int? get calories;
  double? get protein;
  DateTime get createdAt;
  int get timesUsed;
}

/// Saved food item wrapper
class SavedFoodLibraryItem implements FoodLibraryItem {
  final SavedFood savedFood;

  SavedFoodLibraryItem(this.savedFood);

  @override
  String get id => savedFood.id;
  @override
  String get name => savedFood.name;
  @override
  int? get calories => savedFood.totalCalories;
  @override
  double? get protein => savedFood.totalProteinG;
  @override
  DateTime get createdAt => savedFood.createdAt;
  @override
  int get timesUsed => savedFood.timesLogged;
}

/// Recipe item wrapper
class RecipeLibraryItem implements FoodLibraryItem {
  final RecipeSummary recipe;

  RecipeLibraryItem(this.recipe);

  @override
  String get id => recipe.id;
  @override
  String get name => recipe.name;
  @override
  int? get calories => recipe.caloriesPerServing;
  @override
  double? get protein => recipe.proteinPerServingG;
  @override
  DateTime get createdAt => recipe.createdAt;
  @override
  int get timesUsed => recipe.timesLogged;
}

/// State for the food library
class FoodLibraryState {
  final List<SavedFood> savedFoods;
  final List<RecipeSummary> recipes;
  final bool isLoading;
  final String? error;
  final FoodLibrarySortOption sortOption;
  final String searchQuery;
  final MealType? mealTypeFilter;

  const FoodLibraryState({
    this.savedFoods = const [],
    this.recipes = const [],
    this.isLoading = false,
    this.error,
    this.sortOption = FoodLibrarySortOption.frequency,
    this.searchQuery = '',
    this.mealTypeFilter,
  });

  FoodLibraryState copyWith({
    List<SavedFood>? savedFoods,
    List<RecipeSummary>? recipes,
    bool? isLoading,
    String? error,
    FoodLibrarySortOption? sortOption,
    String? searchQuery,
    MealType? mealTypeFilter,
    bool clearMealTypeFilter = false,
  }) {
    return FoodLibraryState(
      savedFoods: savedFoods ?? this.savedFoods,
      recipes: recipes ?? this.recipes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      sortOption: sortOption ?? this.sortOption,
      searchQuery: searchQuery ?? this.searchQuery,
      mealTypeFilter:
          clearMealTypeFilter ? null : (mealTypeFilter ?? this.mealTypeFilter),
    );
  }

  /// Get all items combined
  List<FoodLibraryItem> get allItems {
    final items = <FoodLibraryItem>[
      ...savedFoods.map((f) => SavedFoodLibraryItem(f)),
      ...recipes.map((r) => RecipeLibraryItem(r)),
    ];
    return _sortAndFilter(items);
  }

  /// Get saved foods only
  List<FoodLibraryItem> get savedItems {
    final items =
        savedFoods.map((f) => SavedFoodLibraryItem(f)).toList().cast<FoodLibraryItem>();
    return _sortAndFilter(items);
  }

  /// Get recipes only
  List<FoodLibraryItem> get recipeItems {
    final items =
        recipes.map((r) => RecipeLibraryItem(r)).toList().cast<FoodLibraryItem>();
    return _sortAndFilter(items);
  }

  List<FoodLibraryItem> _sortAndFilter(List<FoodLibraryItem> items) {
    // Filter by search query
    var filtered = items;
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = items
          .where((item) => item.name.toLowerCase().contains(query))
          .toList();
    }

    // Sort
    switch (sortOption) {
      case FoodLibrarySortOption.name:
        filtered.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case FoodLibrarySortOption.frequency:
        filtered.sort((a, b) => b.timesUsed.compareTo(a.timesUsed));
        break;
      case FoodLibrarySortOption.recent:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filtered;
  }
}

/// State notifier for food library
class FoodLibraryNotifier extends StateNotifier<FoodLibraryState> {
  final NutritionRepository _repository;
  final String _userId;

  FoodLibraryNotifier(this._repository, this._userId)
      : super(const FoodLibraryState());

  /// Load all food library data
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load saved foods and recipes in parallel
      final results = await Future.wait([
        _repository.getSavedFoods(userId: _userId, limit: 100),
        _repository.getRecipes(
            userId: _userId, limit: 100, sortBy: 'times_logged'),
      ]);

      final savedFoodsResponse = results[0] as SavedFoodsResponse;
      final recipesResponse = results[1] as RecipesResponse;

      state = state.copyWith(
        isLoading: false,
        savedFoods: savedFoodsResponse.items,
        recipes: recipesResponse.items,
      );
    } catch (e) {
      debugPrint('Error loading food library: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load food library',
      );
    }
  }

  /// Set sort option
  void setSortOption(FoodLibrarySortOption option) {
    HapticService.selection();
    state = state.copyWith(sortOption: option);
  }

  /// Set search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Set meal type filter
  void setMealTypeFilter(MealType? mealType) {
    HapticService.selection();
    if (mealType == state.mealTypeFilter) {
      state = state.copyWith(clearMealTypeFilter: true);
    } else {
      state = state.copyWith(mealTypeFilter: mealType);
    }
  }

  /// Delete a saved food
  Future<bool> deleteSavedFood(String savedFoodId) async {
    try {
      await _repository.deleteSavedFood(userId: _userId, savedFoodId: savedFoodId);
      state = state.copyWith(
        savedFoods: state.savedFoods.where((f) => f.id != savedFoodId).toList(),
      );
      return true;
    } catch (e) {
      debugPrint('Error deleting saved food: $e');
      return false;
    }
  }

  /// Delete a recipe
  Future<bool> deleteRecipe(String recipeId) async {
    try {
      await _repository.deleteRecipe(userId: _userId, recipeId: recipeId);
      state = state.copyWith(
        recipes: state.recipes.where((r) => r.id != recipeId).toList(),
      );
      return true;
    } catch (e) {
      debugPrint('Error deleting recipe: $e');
      return false;
    }
  }
}

/// Provider for food library
final foodLibraryProvider = StateNotifierProvider.family
    .autoDispose<FoodLibraryNotifier, FoodLibraryState, String>(
  (ref, userId) {
    final repository = ref.watch(nutritionRepositoryProvider);
    final notifier = FoodLibraryNotifier(repository, userId);
    // Load data immediately
    notifier.loadData();
    return notifier;
  },
);

/// Unified Food Library Screen
class FoodLibraryScreen extends ConsumerStatefulWidget {
  const FoodLibraryScreen({super.key});

  @override
  ConsumerState<FoodLibraryScreen> createState() => _FoodLibraryScreenState();
}

class _FoodLibraryScreenState extends ConsumerState<FoodLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String? _userId;
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchFocusNode.addListener(_onSearchFocusChange);
    _loadUserId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'food_library_viewed');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchFocusChange() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  Future<void> _loadUserId() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (mounted && userId != null) {
      setState(() => _userId = userId);
    }
  }

  void _onSearchChanged(String query) {
    if (_userId != null) {
      ref.read(foodLibraryProvider(_userId!).notifier).setSearchQuery(query);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
    _searchFocusNode.unfocus();
  }

  Future<void> _showSortOptions() async {
    if (_userId == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentSort = ref.read(foodLibraryProvider(_userId!)).sortOption;

    HapticService.light();

    await showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: _SortOptionsSheet(
          currentSort: currentSort,
          isDark: isDark,
          onSelect: (option) {
            ref.read(foodLibraryProvider(_userId!).notifier).setSortOption(option);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _createNewRecipe() async {
    if (_userId == null) return;

    HapticService.medium();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showGlassSheet<bool>(
      context: context,
      builder: (context) => GlassSheet(
        child: RecipeBuilderSheet(
          userId: _userId!,
          isDark: isDark,
        ),
      ),
    );

    if (result == true && mounted) {
      // Refresh the list
      ref.read(foodLibraryProvider(_userId!).notifier).loadData();
    }
  }

  Future<void> _quickLogItem(FoodLibraryItem item) async {
    if (_userId == null) return;

    HapticService.medium();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repository = ref.read(nutritionRepositoryProvider);

    // Show meal type selector
    final mealType = await showGlassSheet<MealType>(
      context: context,
      builder: (context) => GlassSheet(
        child: _MealTypeSelector(isDark: isDark),
      ),
    );

    if (mealType == null || !mounted) return;

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text('Logging ${item.name}...'),
          ],
        ),
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        duration: const Duration(seconds: 10),
      ),
    );

    try {
      if (item is SavedFoodLibraryItem) {
        await repository.relogSavedFood(
          userId: _userId!,
          savedFoodId: item.id,
          mealType: mealType.value,
        );
      } else if (item is RecipeLibraryItem) {
        await repository.logRecipe(
          userId: _userId!,
          recipeId: item.id,
          mealType: mealType.value,
        );
      }

      if (!mounted) return;

      // Award XP for daily goal
      ref.read(xpProvider.notifier).markMealLogged();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${item.name} logged to ${mealType.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      HapticService.success();

      // Refresh the list
      ref.read(foodLibraryProvider(_userId!).notifier).loadData();
      ref.read(nutritionProvider.notifier).loadTodaySummary(_userId!);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log: $e'),
          backgroundColor: AppColors.textMuted,
          behavior: SnackBarBehavior.floating,
        ),
      );
      HapticService.error();
    }
  }

  Future<void> _showItemDetails(FoodLibraryItem item) async {
    if (_userId == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    HapticService.light();

    await showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: _FoodDetailSheet(
          item: item,
          userId: _userId!,
          isDark: isDark,
          onLog: () {
            Navigator.pop(context);
            _quickLogItem(item);
          },
          onEdit: () async {
            Navigator.pop(context);
            if (item is RecipeLibraryItem) {
              // Load full recipe then open editor
              final repository = ref.read(nutritionRepositoryProvider);
              try {
                final fullRecipe = await repository.getRecipe(
                  userId: _userId!,
                  recipeId: item.id,
                );
                if (mounted) {
                  final result = await showGlassSheet<bool>(
                    context: context,
                    builder: (context) => GlassSheet(
                      child: RecipeBuilderSheet(
                        userId: _userId!,
                        isDark: isDark,
                        existingRecipe: fullRecipe,
                      ),
                    ),
                  );
                if (result == true && mounted) {
                  ref.read(foodLibraryProvider(_userId!).notifier).loadData();
                }
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to load recipe: $e'),
                    backgroundColor: AppColors.textMuted,
                  ),
                );
              }
            }
          }
        },
        onDelete: () async {
          Navigator.pop(context);
          await _deleteItem(item);
        },
      ),
      ),
    );
  }

  Future<void> _deleteItem(FoodLibraryItem item) async {
    if (_userId == null) return;

    final confirm = await AppDialog.destructive(
      context,
      title: 'Delete ${item.name}?',
      message: 'This action cannot be undone.',
      icon: Icons.delete_rounded,
    );

    if (confirm != true) return;

    HapticService.medium();

    bool success;
    if (item is SavedFoodLibraryItem) {
      success = await ref
          .read(foodLibraryProvider(_userId!).notifier)
          .deleteSavedFood(item.id);
    } else if (item is RecipeLibraryItem) {
      success = await ref
          .read(foodLibraryProvider(_userId!).notifier)
          .deleteRecipe(item.id);
    } else {
      success = false;
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} deleted'),
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.elevated : AppColorsLight.elevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete'),
          backgroundColor: AppColors.textMuted,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

    if (_userId == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: accentColor),
        ),
      );
    }

    final libraryState = ref.watch(foodLibraryProvider(_userId!));

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PillAppBar(
        title: 'Food Library',
        actions: [PillAppBarAction(icon: Icons.sort_rounded, onTap: _showSortOptions)],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isSearchFocused ? accentColor : cardBorder,
                  width: _isSearchFocused ? 2 : 1,
                ),
                boxShadow: _isSearchFocused
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha:0.2),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Icon(
                      Icons.search_rounded,
                      color: _isSearchFocused ? accentColor : textMuted,
                      size: 22,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      style: TextStyle(color: textPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Search foods and recipes...',
                        hintStyle: TextStyle(color: textMuted, fontSize: 16),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textMuted, size: 20),
                      onPressed: _clearSearch,
                    )
                  else
                    const SizedBox(width: 8),
                ],
              ),
            ),
          ),

          // Tab Bar
          SegmentedTabBar(
            controller: _tabController,
            showIcons: false,
            tabs: [
              SegmentedTabItem(label: 'All (${libraryState.allItems.length})'),
              SegmentedTabItem(label: 'Saved (${libraryState.savedItems.length})'),
              SegmentedTabItem(label: 'Recipes (${libraryState.recipeItems.length})'),
            ],
          ),

          const SizedBox(height: 8),

          // Content
          Expanded(
            child: libraryState.isLoading
                ? _buildShimmerLoading(isDark, elevated, cardBorder)
                : libraryState.error != null
                    ? _buildErrorState(
                        libraryState.error!, isDark, textPrimary, textMuted, accentColor)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildItemsList(
                            libraryState.allItems,
                            'No foods yet',
                            'Start by logging meals to build your library',
                            isDark,
                            textPrimary,
                            textMuted,
                            elevated,
                            cardBorder,
                            accentColor,
                          ),
                          _buildItemsList(
                            libraryState.savedItems,
                            'No saved foods',
                            'Save foods you eat often for quick access',
                            isDark,
                            textPrimary,
                            textMuted,
                            elevated,
                            cardBorder,
                            accentColor,
                          ),
                          _buildItemsList(
                            libraryState.recipeItems,
                            'No recipes yet',
                            'Create recipes to track homemade meals',
                            isDark,
                            textPrimary,
                            textMuted,
                            elevated,
                            cardBorder,
                            accentColor,
                          ),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewRecipe,
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Recipe',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(bool isDark, Color elevated, Color cardBorder) {
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      highlightColor:
          isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80,
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark, Color textPrimary,
      Color textMuted, Color accentColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: TextStyle(
                fontSize: 16,
                color: textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {
                if (_userId != null) {
                  ref.read(foodLibraryProvider(_userId!).notifier).loadData();
                }
              },
              icon: Icon(Icons.refresh_rounded, color: accentColor),
              label: Text(
                'Retry',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(
    List<FoodLibraryItem> items,
    String emptyTitle,
    String emptySubtitle,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color elevated,
    Color cardBorder,
    Color accentColor,
  ) {
    if (items.isEmpty) {
      return _buildEmptyState(
          emptyTitle, emptySubtitle, isDark, textPrimary, textMuted);
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_userId != null) {
          await ref.read(foodLibraryProvider(_userId!).notifier).loadData();
        }
      },
      color: accentColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _FoodLibraryCard(
            item: item,
            isDark: isDark,
            onTap: () => _showItemDetails(item),
            onLog: () => _quickLogItem(item),
            onDelete: () => _deleteItem(item),
          )
              .animate()
              .fadeIn(duration: 200.ms, delay: (index * 30).ms)
              .slideY(begin: 0.1, end: 0, duration: 200.ms);
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, bool isDark,
      Color textPrimary, Color textMuted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.elevated : AppColorsLight.elevated)
                    .withValues(alpha:0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_menu_rounded,
                size: 40,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
