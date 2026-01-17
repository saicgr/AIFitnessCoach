import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition.dart';
import '../../../data/models/recipe.dart';
import '../../../data/repositories/nutrition_repository.dart';

/// Provider for caching quick add suggestions
/// This prefetches data when the nutrition screen loads for instant access
final quickAddSuggestionsProvider = FutureProvider.family<QuickAddData, String>(
  (ref, userId) async {
    final repository = ref.read(nutritionRepositoryProvider);

    // Fetch saved foods (favorites) and recent logs in parallel
    final results = await Future.wait([
      repository.getSavedFoods(userId: userId, limit: 8),
      repository.getFoodLogs(userId, limit: 5),
      repository.getRecipes(userId: userId, limit: 5),
    ]);

    final savedFoods = (results[0] as SavedFoodsResponse).items;
    final recentLogs = results[1] as List<FoodLog>;
    final recipes = (results[2] as RecipesResponse).items;

    return QuickAddData(
      suggestions: savedFoods,
      recentLogs: recentLogs,
      templates: recipes,
    );
  },
);

/// Data class for quick add suggestions
class QuickAddData {
  final List<SavedFood> suggestions;
  final List<FoodLog> recentLogs;
  final List<RecipeSummary> templates;

  const QuickAddData({
    required this.suggestions,
    required this.recentLogs,
    required this.templates,
  });
}

/// A minimal bottom sheet for fast meal logging (2 taps max)
class QuickAddSheet extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback onMealLogged;

  const QuickAddSheet({
    super.key,
    required this.userId,
    required this.onMealLogged,
  });

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  bool _isLogging = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final surfaceColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    final suggestionsAsync = ref.watch(quickAddSuggestionsProvider(widget.userId));

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Add',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getMealTypeLabel(),
                      style: TextStyle(
                        fontSize: 13,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
                if (_isLogging)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(teal),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: suggestionsAsync.when(
              data: (data) => _buildContent(context, data, isDark),
              loading: () => _buildLoadingSkeleton(isDark),
              error: (error, _) => _buildErrorState(error.toString(), isDark),
            ),
          ),

          // Bottom action: Manual entry
          _buildManualEntryButton(context, isDark, teal, textPrimary),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, QuickAddData data, bool isDark) {
    final hasSuggestions = data.suggestions.isNotEmpty;
    final hasRecent = data.recentLogs.isNotEmpty;
    final hasTemplates = data.templates.isNotEmpty;

    if (!hasSuggestions && !hasRecent && !hasTemplates) {
      return _buildEmptyState(isDark);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Quick Suggestions (most prominent)
          if (hasSuggestions) ...[
            _SectionHeader(
              title: 'Favorites',
              icon: Icons.star_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: data.suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final food = data.suggestions[index];
                  return _SuggestionChip(
                    name: food.name,
                    calories: food.totalCalories?.round() ?? 0,
                    onTap: () => _logSavedFood(food),
                    isDark: isDark,
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Section 2: Recent Meals
          if (hasRecent) ...[
            _SectionHeader(
              title: 'Recent',
              icon: Icons.history_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            ...data.recentLogs.take(5).map((log) => _RecentMealTile(
                  log: log,
                  onTap: () => _relogMeal(log),
                  isDark: isDark,
                )),
            const SizedBox(height: 20),
          ],

          // Section 3: Templates (Recipes)
          if (hasTemplates) ...[
            _SectionHeader(
              title: 'My Recipes',
              icon: Icons.restaurant_menu_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            ...data.templates.take(3).map((recipe) => _TemplateTile(
                  recipe: recipe,
                  calories: recipe.caloriesPerServing ?? 0,
                  servings: recipe.servings,
                  onTap: () => _logRecipe(recipe),
                  isDark: isDark,
                )),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restaurant_rounded,
            size: 48,
            color: textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Log some meals and save your favorites for quick access here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    final surfaceColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shimmer chips
          SizedBox(
            height: 80,
            child: Row(
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Shimmer rows
          ...List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final errorColor = isDark ? AppColors.error : AppColorsLight.error;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: errorColor),
          const SizedBox(height: 16),
          Text(
            'Failed to load suggestions',
            style: TextStyle(
              fontSize: 14,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntryButton(
    BuildContext context,
    bool isDark,
    Color teal,
    Color textPrimary,
  ) {
    final surfaceColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _openFullLogSheet(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_rounded, size: 20, color: teal),
                const SizedBox(width: 8),
                Text(
                  'Log something else',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────

  String _getMealTypeFromTime() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'breakfast';
    if (hour >= 11 && hour < 15) return 'lunch';
    if (hour >= 15 && hour < 18) return 'snack';
    return 'dinner';
  }

  String _getMealTypeLabel() {
    final mealType = _getMealTypeFromTime();
    final hour = DateTime.now().hour;
    final timeStr = DateFormat.jm().format(DateTime.now());

    switch (mealType) {
      case 'breakfast':
        return 'Logging as Breakfast - $timeStr';
      case 'lunch':
        return 'Logging as Lunch - $timeStr';
      case 'snack':
        return 'Logging as Snack - $timeStr';
      case 'dinner':
        return 'Logging as Dinner - $timeStr';
      default:
        return timeStr;
    }
  }

  Future<void> _logSavedFood(SavedFood food) async {
    if (_isLogging) return;

    setState(() => _isLogging = true);
    HapticFeedback.lightImpact();

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      await repository.relogSavedFood(
        userId: widget.userId,
        savedFoodId: food.id,
        mealType: _getMealTypeFromTime(),
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop();
        widget.onMealLogged();
        _showSuccessSnackbar(food.name, food.totalCalories?.round() ?? 0);
      }
    } catch (e) {
      debugPrint('Error logging saved food: $e');
      if (mounted) {
        setState(() => _isLogging = false);
        _showErrorSnackbar('Failed to log: $e');
      }
    }
  }

  Future<void> _relogMeal(FoodLog log) async {
    if (_isLogging) return;

    // For recent meals, we need to create a new log with the same data
    // Using the log-direct endpoint
    setState(() => _isLogging = true);
    HapticFeedback.lightImpact();

    try {
      final repository = ref.read(nutritionRepositoryProvider);

      // Extract food items from the log
      final foodItems = <Map<String, dynamic>>[];
      if (log.foodItems.isNotEmpty) {
        for (final item in log.foodItems) {
          foodItems.add({
            'name': item.name,
            'calories': item.calories ?? 0,
            'protein_g': item.proteinG?.round() ?? 0,
            'carbs_g': item.carbsG?.round() ?? 0,
            'fat_g': item.fatG?.round() ?? 0,
          });
        }
      } else {
        // Create a single item from the meal type
        foodItems.add({
          'name': _getMealTypeName(log.mealType),
          'calories': log.totalCalories,
          'protein_g': log.proteinG.round(),
          'carbs_g': log.carbsG.round(),
          'fat_g': log.fatG.round(),
        });
      }

      await repository.logAdjustedFood(
        userId: widget.userId,
        mealType: _getMealTypeFromTime(),
        foodItems: foodItems,
        totalCalories: log.totalCalories,
        totalProtein: log.proteinG.round(),
        totalCarbs: log.carbsG.round(),
        totalFat: log.fatG.round(),
        totalFiber: log.fiberG?.round(),
        sourceType: 'relog',
        notes: 'Re-logged from ${log.mealType}',
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop();
        widget.onMealLogged();
        _showSuccessSnackbar(_getLogDisplayName(log), log.totalCalories);
      }
    } catch (e) {
      debugPrint('Error re-logging meal: $e');
      if (mounted) {
        setState(() => _isLogging = false);
        _showErrorSnackbar('Failed to log: $e');
      }
    }
  }

  /// Get a display name for a FoodLog
  String _getLogDisplayName(FoodLog log) {
    if (log.foodItems.isNotEmpty) {
      if (log.foodItems.length == 1) {
        return log.foodItems.first.name;
      }
      return '${log.foodItems.first.name} +${log.foodItems.length - 1}';
    }
    return _getMealTypeName(log.mealType);
  }

  /// Get meal type display name
  String _getMealTypeName(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'snack':
        return 'Snack';
      default:
        return 'Meal';
    }
  }

  Future<void> _logRecipe(RecipeSummary recipe) async {
    if (_isLogging) return;

    setState(() => _isLogging = true);
    HapticFeedback.lightImpact();

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      await repository.logRecipe(
        userId: widget.userId,
        recipeId: recipe.id,
        mealType: _getMealTypeFromTime(),
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop();
        widget.onMealLogged();
        _showSuccessSnackbar(recipe.name, recipe.caloriesPerServing ?? 0);
      }
    } catch (e) {
      debugPrint('Error logging recipe: $e');
      if (mounted) {
        setState(() => _isLogging = false);
        _showErrorSnackbar('Failed to log: $e');
      }
    }
  }

  void _openFullLogSheet(BuildContext context) {
    // Pop with 'openFullLog' result to signal parent to show LogMealSheet
    Navigator.of(context).pop('openFullLog');
  }

  void _showSuccessSnackbar(String name, int calories) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged: $name - $calories cal'),
        backgroundColor: isDark ? AppColors.success : AppColorsLight.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isDark ? AppColors.error : AppColorsLight.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Row(
      children: [
        Icon(icon, size: 18, color: textSecondary),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Suggestion Chip (horizontal scroll)
// ─────────────────────────────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  final String name;
  final int calories;
  final VoidCallback onTap;
  final bool isDark;

  const _SuggestionChip({
    required this.name,
    required this.calories,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 110,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Icon(Icons.local_fire_department_rounded, size: 14, color: teal),
                  const SizedBox(width: 4),
                  Text(
                    '$calories cal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Recent Meal Tile
// ─────────────────────────────────────────────────────────────────

class _RecentMealTile extends StatelessWidget {
  final FoodLog log;
  final VoidCallback onTap;
  final bool isDark;

  const _RecentMealTile({
    required this.log,
    required this.onTap,
    required this.isDark,
  });

  /// Get a display name for a FoodLog
  String _getLogDisplayName() {
    if (log.foodItems.isNotEmpty) {
      if (log.foodItems.length == 1) {
        return log.foodItems.first.name;
      }
      return '${log.foodItems.first.name} +${log.foodItems.length - 1}';
    }
    return _getMealTypeName(log.mealType);
  }

  /// Get meal type display name
  String _getMealTypeName(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'snack':
        return 'Snack';
      default:
        return 'Meal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    final mealName = _getLogDisplayName();
    final timeAgo = _formatTimeAgo(log.loggedAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Meal type emoji
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: teal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      _getMealEmoji(log.mealType),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mealName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Calories
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${log.totalCalories}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'cal',
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.add_circle_outline_rounded, size: 22, color: teal),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMealEmoji(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '🌅';
      case 'lunch':
        return '☀️';
      case 'dinner':
        return '🌙';
      case 'snack':
        return '🍎';
      default:
        return '🍽️';
    }
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Template (Recipe) Tile
// ─────────────────────────────────────────────────────────────────

class _TemplateTile extends StatelessWidget {
  final RecipeSummary recipe;
  final int calories;
  final int servings;
  final VoidCallback onTap;
  final bool isDark;

  const _TemplateTile({
    required this.recipe,
    required this.calories,
    required this.servings,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Recipe icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      size: 18,
                      color: purple,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (servings > 0)
                        Text(
                          '$servings serving${servings > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                // Calories
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$calories',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'cal',
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.add_circle_outline_rounded, size: 22, color: purple),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
