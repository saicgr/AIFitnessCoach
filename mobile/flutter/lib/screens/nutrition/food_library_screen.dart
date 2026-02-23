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
import '../../widgets/glass_back_button.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/segmented_tab_bar.dart';
import 'recipe_builder_sheet.dart';

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
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: Text(
          'Food Library',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.sort_rounded, color: textMuted),
            onPressed: _showSortOptions,
            tooltip: 'Sort',
          ),
        ],
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

/// Food Library Card Widget
class _FoodLibraryCard extends StatelessWidget {
  final FoodLibraryItem item;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onLog;
  final VoidCallback onDelete;

  const _FoodLibraryCard({
    required this.item,
    required this.isDark,
    required this.onTap,
    required this.onLog,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

    final isRecipe = item is RecipeLibraryItem;
    final typeColor = isRecipe
        ? AppColors.textSecondary // Purple for recipes
        : AppColors.textPrimary; // Green for saved foods

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.textMuted,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) async {
        HapticService.swipeThreshold();
        return await AppDialog.destructive(
          context,
          title: 'Delete ${item.name}?',
          message: 'This action cannot be undone.',
          icon: Icons.delete_rounded,
        );
      },
      onDismissed: (direction) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Type indicator
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        isRecipe
                            ? Icons.menu_book_rounded
                            : Icons.bookmark_rounded,
                        color: typeColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (item.calories != null) ...[
                              Text(
                                '${item.calories} cal',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (item.protein != null) ...[
                                Text(
                                  ' | ',
                                  style:
                                      TextStyle(fontSize: 13, color: textMuted),
                                ),
                                Text(
                                  '${item.protein!.round()}g protein',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                            if (item.timesUsed > 0) ...[
                              const Spacer(),
                              Icon(
                                Icons.sync_rounded,
                                size: 12,
                                color: textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.timesUsed}x',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Quick log button
                  Material(
                    color: accentColor.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: onLog,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Log',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ],
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
    );
  }
}

/// Sort Options Bottom Sheet
class _SortOptionsSheet extends StatelessWidget {
  final FoodLibrarySortOption currentSort;
  final bool isDark;
  final Function(FoodLibrarySortOption) onSelect;

  const _SortOptionsSheet({
    required this.currentSort,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted.withValues(alpha:0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.sort_rounded, color: textPrimary, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...FoodLibrarySortOption.values.map((option) {
              final isSelected = option == currentSort;
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha:0.15)
                        : textMuted.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    option.icon,
                    color: isSelected ? accentColor : textMuted,
                    size: 20,
                  ),
                ),
                title: Text(
                  option.label,
                  style: TextStyle(
                    color: isSelected ? accentColor : textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_rounded, color: accentColor)
                    : null,
                onTap: () => onSelect(option),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Meal Type Selector Bottom Sheet
class _MealTypeSelector extends StatelessWidget {
  final bool isDark;

  const _MealTypeSelector({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted.withValues(alpha:0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Log to which meal?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...MealType.values.map((mealType) {
              return ListTile(
                leading: Text(
                  mealType.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  mealType.label,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  HapticService.selection();
                  Navigator.pop(context, mealType);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Food Detail Bottom Sheet
class _FoodDetailSheet extends StatelessWidget {
  final FoodLibraryItem item;
  final String userId;
  final bool isDark;
  final VoidCallback onLog;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FoodDetailSheet({
    required this.item,
    required this.userId,
    required this.isDark,
    required this.onLog,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

    final isRecipe = item is RecipeLibraryItem;
    final typeColor = isRecipe
        ? AppColors.textSecondary
        : AppColors.textPrimary;

    // Extract details based on type
    RecipeSummary? recipe;
    SavedFood? savedFood;
    if (item is RecipeLibraryItem) {
      recipe = (item as RecipeLibraryItem).recipe;
    } else if (item is SavedFoodLibraryItem) {
      savedFood = (item as SavedFoodLibraryItem).savedFood;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted.withValues(alpha:0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isRecipe
                          ? Icons.menu_book_rounded
                          : Icons.bookmark_rounded,
                      color: typeColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isRecipe ? 'Recipe' : 'Saved Food',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: typeColor,
                                ),
                              ),
                            ),
                            if (item.timesUsed > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                'Logged ${item.timesUsed}x',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Nutrition Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.glassSurface
                      : AppColorsLight.glassSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nutrition${isRecipe ? ' per serving' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NutrientStat(
                          label: 'Calories',
                          value: item.calories?.toString() ?? '-',
                          unit: 'kcal',
                          color: AppColors.textPrimary,
                          isDark: isDark,
                        ),
                        _NutrientStat(
                          label: 'Protein',
                          value: item.protein?.round().toString() ?? '-',
                          unit: 'g',
                          color: AppColors.textPrimary,
                          isDark: isDark,
                        ),
                        if (savedFood != null) ...[
                          _NutrientStat(
                            label: 'Carbs',
                            value: savedFood.totalCarbsG?.round().toString() ?? '-',
                            unit: 'g',
                            color: AppColors.textPrimary,
                            isDark: isDark,
                          ),
                          _NutrientStat(
                            label: 'Fat',
                            value: savedFood.totalFatG?.round().toString() ?? '-',
                            unit: 'g',
                            color: AppColors.textMuted,
                            isDark: isDark,
                          ),
                        ],
                        if (recipe != null) ...[
                          _NutrientStat(
                            label: 'Servings',
                            value: recipe.servings.toString(),
                            unit: '',
                            color: AppColors.textSecondary,
                            isDark: isDark,
                          ),
                          _NutrientStat(
                            label: 'Ingredients',
                            value: recipe.ingredientCount.toString(),
                            unit: '',
                            color: AppColors.textSecondary,
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Additional info for saved foods
            if (savedFood?.description != null &&
                savedFood!.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.glassSurface
                        : AppColorsLight.glassSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        savedFood.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Primary: Log button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: onLog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        'Log This Food',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Secondary actions row
                  Row(
                    children: [
                      // Edit (only for recipes)
                      if (isRecipe)
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: onEdit,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textPrimary,
                                side: BorderSide(color: cardBorder),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(Icons.edit_rounded, size: 18),
                              label: const Text('Edit'),
                            ),
                          ),
                        ),
                      if (isRecipe) const SizedBox(width: 12),

                      // Delete
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: onDelete,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textMuted,
                              side: BorderSide(
                                  color: AppColors.textMuted.withValues(alpha:0.3)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(Icons.delete_outline_rounded, size: 18),
                            label: const Text('Delete'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Nutrient Stat Widget
class _NutrientStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool isDark;

  const _NutrientStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: value.length > 3 ? 11 : 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          unit.isNotEmpty ? '$value$unit' : value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}
