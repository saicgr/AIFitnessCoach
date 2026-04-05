import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition.dart';
import '../../../data/models/nutrition_preferences.dart';
import '../../../data/models/recipe.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/nutrition/health_metrics_card.dart';
import '../../../widgets/nutrition/food_mood_analytics_card.dart';
import '../weekly_checkin_sheet.dart';

/// My Foods sheet with 2 tabs: Saved Foods + My Recipes
class MyFoodsSheet extends StatefulWidget {
  final String userId;
  final NutritionRepository repository;
  final List<RecipeSummary> recipes;
  final bool isDark;
  final VoidCallback onFoodLogged;
  final String Function() getSuggestedMealType;
  final VoidCallback onCreateRecipe;
  final void Function(RecipeSummary) onLogRecipe;
  final VoidCallback onRefreshRecipes;

  const MyFoodsSheet({
    super.key,
    required this.userId,
    required this.repository,
    required this.recipes,
    required this.isDark,
    required this.onFoodLogged,
    required this.getSuggestedMealType,
    required this.onCreateRecipe,
    required this.onLogRecipe,
    required this.onRefreshRecipes,
  });

  @override
  State<MyFoodsSheet> createState() => _MyFoodsSheetState();
}

class _MyFoodsSheetState extends State<MyFoodsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final bg = widget.isDark
        ? AppColors.elevated
        : AppColorsLight.elevated;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Icon(Icons.bookmark_outline, color: teal, size: 22),
              const SizedBox(width: 10),
              Text(
                'My Foods',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(Icons.close, color: textColor.withOpacity(0.5)),
              ),
            ],
          ),
        ),
        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: teal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: teal,
            unselectedLabelColor: textColor.withOpacity(0.5),
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            dividerHeight: 0,
            tabs: const [
              Tab(text: 'Saved Foods'),
              Tab(text: 'My Recipes'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              SavedFoodsFilterSheet(
                userId: widget.userId,
                repository: widget.repository,
                isDark: widget.isDark,
                onFoodLogged: widget.onFoodLogged,
                getSuggestedMealType: widget.getSuggestedMealType,
              ),
              RecipesTab(
                userId: widget.userId,
                recipes: widget.recipes,
                onCreateRecipe: widget.onCreateRecipe,
                onLogRecipe: widget.onLogRecipe,
                onRefresh: widget.onRefreshRecipes,
                isDark: widget.isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SavedFoodsFilterSheet extends StatefulWidget {
  final String userId;
  final NutritionRepository repository;
  final bool isDark;
  final VoidCallback onFoodLogged;
  final String Function() getSuggestedMealType;

  const SavedFoodsFilterSheet({
    super.key,
    required this.userId,
    required this.repository,
    required this.isDark,
    required this.onFoodLogged,
    required this.getSuggestedMealType,
  });

  @override
  State<SavedFoodsFilterSheet> createState() => _SavedFoodsFilterSheetState();
}

class _SavedFoodsFilterSheetState extends State<SavedFoodsFilterSheet> {
  List<SavedFood> _foods = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _activeFilter = 'all';
  String _sortBy = 'times_logged';
  String _sortOrder = 'desc';
  Timer? _debounceTimer;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchFoods();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFoods() async {
    setState(() => _isLoading = true);
    try {
      double? minProteinG;
      int? maxCalories;
      String? sourceType;

      if (_activeFilter == 'high_protein') minProteinG = 20;
      if (_activeFilter == 'low_cal') maxCalories = 300;
      if (_activeFilter == 'text') sourceType = 'text';
      if (_activeFilter == 'barcode') sourceType = 'barcode';

      final response = await widget.repository.getSavedFoods(
        userId: widget.userId,
        limit: 50,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        minProteinG: minProteinG,
        maxCalories: maxCalories,
        sourceType: sourceType,
      );
      if (mounted) {
        setState(() {
          _foods = response.items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _foods = [];
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    final trimmed = value.trim();
    if (trimmed.length < 3 && trimmed.isNotEmpty) {
      setState(() => _searchQuery = trimmed);
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      setState(() => _searchQuery = trimmed);
      _fetchFoods();
    });
  }

  void _setFilter(String filter) {
    if (_activeFilter == filter) return;
    setState(() => _activeFilter = filter);
    _fetchFoods();
  }

  void _setSort(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortOrder = _sortOrder == 'desc' ? 'asc' : 'desc';
      } else {
        _sortBy = sortBy;
        _sortOrder = sortBy == 'name' ? 'asc' : 'desc';
      }
    });
    _fetchFoods();
  }

  @override
  Widget build(BuildContext context) {
    final elevated = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final surface = widget.isDark ? AppColors.surface : AppColorsLight.surface;

    return Column(
        children: [
          const SizedBox(height: 8),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(color: textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search saved foods...',
                hintStyle: TextStyle(color: textMuted, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: textMuted, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: textMuted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('all', 'All', teal, textMuted),
                const SizedBox(width: 8),
                _buildFilterChip('high_protein', 'High Protein', teal, textMuted),
                const SizedBox(width: 8),
                _buildFilterChip('low_cal', 'Low Cal', teal, textMuted),
                const SizedBox(width: 8),
                _buildFilterChip('text', 'Text', teal, textMuted),
                const SizedBox(width: 8),
                _buildFilterChip('barcode', 'Barcode', teal, textMuted),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Sort chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSortChip('times_logged', 'Most Used', teal, textMuted),
                const SizedBox(width: 8),
                _buildSortChip('total_protein_g', 'Protein', teal, textMuted),
                const SizedBox(width: 8),
                _buildSortChip('total_calories', 'Calories', teal, textMuted),
                const SizedBox(width: 8),
                _buildSortChip('name', 'Name', teal, textMuted),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Food list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: teal))
                : _foods.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bookmark_border, size: 48, color: textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No saved foods found',
                              style: TextStyle(fontSize: 14, color: textMuted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Save foods when logging meals',
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _foods.length,
                        itemBuilder: (context, index) {
                          final food = _foods[index];
                          return Dismissible(
                            key: Key(food.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) async {
                              setState(() => _foods.removeAt(index));
                              try {
                                await widget.repository.deleteSavedFood(
                                  userId: widget.userId,
                                  savedFoodId: food.id,
                                );
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to delete: $e')),
                                  );
                                }
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: teal.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.restaurant, color: teal, size: 20),
                                ),
                                title: Text(
                                  food.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${food.totalCalories ?? 0} kcal \u00B7 P:${food.totalProteinG?.toInt() ?? 0}g \u00B7 C:${food.totalCarbsG?.toInt() ?? 0}g \u00B7 F:${food.totalFatG?.toInt() ?? 0}g',
                                      style: TextStyle(fontSize: 11, color: textMuted),
                                    ),
                                    if (food.timesLogged > 0)
                                      Text(
                                        'Logged ${food.timesLogged}x',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: teal.withValues(alpha: 0.8),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.add_circle_outline, color: teal, size: 26),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    try {
                                      await widget.repository.relogSavedFood(
                                        userId: widget.userId,
                                        savedFoodId: food.id,
                                        mealType: widget.getSuggestedMealType(),
                                      );
                                      widget.onFoodLogged();
                                    } catch (e) {
                                      debugPrint('Failed to relog saved food: $e');
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
    );
  }

  Widget _buildFilterChip(String value, String label, Color teal, Color textMuted) {
    final isSelected = _activeFilter == value;
    return GestureDetector(
      onTap: () => _setFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? teal.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? teal : textMuted.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? teal : textMuted,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String value, String label, Color teal, Color textMuted) {
    final isSelected = _sortBy == value;
    final icon = _sortOrder == 'asc' ? Icons.arrow_upward : Icons.arrow_downward;
    return GestureDetector(
      onTap: () => _setSort(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? teal.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? teal : textMuted.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? teal : textMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 12, color: teal),
            ],
          ],
        ),
      ),
    );
  }
}

class RecipesTab extends StatelessWidget {
  final String userId;
  final List<RecipeSummary> recipes;
  final VoidCallback onCreateRecipe;
  final void Function(RecipeSummary) onLogRecipe;
  final VoidCallback onRefresh;
  final bool isDark;

  const RecipesTab({
    super.key,
    required this.userId,
    required this.recipes,
    required this.onCreateRecipe,
    required this.onLogRecipe,
    required this.onRefresh,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: teal,
      child: recipes.isEmpty
          ? _EmptyRecipesState(
              onCreateRecipe: onCreateRecipe,
              isDark: isDark,
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: recipes.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: onCreateRecipe,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: teal.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: teal),
                            const SizedBox(width: 8),
                            Text(
                              'Create New Recipe',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: teal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final recipe = recipes[index - 1];
                return _RecipeCard(
                  recipe: recipe,
                  onLog: () => onLogRecipe(recipe),
                  isDark: isDark,
                );
              },
            ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final RecipeSummary recipe;
  final VoidCallback onLog;
  final bool isDark;

  const _RecipeCard({
    required this.recipe,
    required this.onLog,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onLog,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      recipe.categoryEnum.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${recipe.caloriesPerServing ?? 0} kcal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: teal,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${recipe.ingredientCount} ingredients',
                            style: TextStyle(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                          if (recipe.timesLogged > 0) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.repeat, size: 12, color: textMuted),
                            Text(
                              ' ${recipe.timesLogged}x',
                              style: TextStyle(
                                fontSize: 11,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: teal, size: 28),
                  onPressed: onLog,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRecipesState extends StatelessWidget {
  final VoidCallback onCreateRecipe;
  final bool isDark;

  const _EmptyRecipesState({
    required this.onCreateRecipe,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.restaurant_menu, size: 40, color: teal),
            ),
            const SizedBox(height: 24),
            Text(
              'No recipes yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create recipes to quickly log meals you eat often',
              style: TextStyle(fontSize: 14, color: textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreateRecipe,
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Recipe'),
              style: FilledButton.styleFrom(
                backgroundColor: teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
