import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition.dart';
import '../../../data/models/micronutrients.dart';
import '../../../data/services/api_client.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/main_shell.dart';
import 'edit_targets_sheet.dart';
import 'nutrition_goals_card.dart';
import 'pinned_nutrients_card.dart';
import 'logged_meals_section.dart';
import 'goal_row.dart';

class DailyTab extends ConsumerStatefulWidget {
  final String userId;
  final DailyNutritionSummary? summary;
  final NutritionTargets? targets;
  final DailyMicronutrientSummary? micronutrients;
  final VoidCallback onRefresh;
  final void Function(String? mealType) onLogMeal;
  final void Function(String) onDeleteMeal;
  final void Function(String mealId, String targetMealType) onCopyMeal;
  final void Function(String mealId, String targetMealType) onMoveMeal;
  final void Function(String logId, int calories, double proteinG, double carbsG, double fatG, {double? weightG}) onUpdateMeal;
  final void Function(String logId, DateTime newTime) onUpdateMealTime;
  final void Function(String logId, String notes) onUpdateMealNotes;
  final void Function(String logId, {String? moodBefore, String? moodAfter, int? energyLevel}) onUpdateMealMood;
  final void Function(FoodLog meal) onSaveFoodToFavorites;
  final ApiClient? apiClient;
  final VoidCallback? onSwitchToNutrientsTab;
  final VoidCallback? onSwitchToHydrationTab;
  final bool isDark;
  final bool calmMode;

  const DailyTab({
    super.key,
    required this.userId,
    this.summary,
    this.targets,
    this.micronutrients,
    required this.onRefresh,
    required this.onLogMeal,
    required this.onDeleteMeal,
    required this.onCopyMeal,
    required this.onMoveMeal,
    required this.onUpdateMeal,
    required this.onUpdateMealTime,
    required this.onUpdateMealNotes,
    required this.onUpdateMealMood,
    required this.onSaveFoodToFavorites,
    this.apiClient,
    this.onSwitchToNutrientsTab,
    this.onSwitchToHydrationTab,
    required this.isDark,
    this.calmMode = false,
  });

  @override
  ConsumerState<DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends ConsumerState<DailyTab> {
  List<SavedFood> _favorites = [];
  bool _isLoadingFavorites = false;
  bool _analyticsExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (widget.userId.isEmpty) return;

    setState(() => _isLoadingFavorites = true);
    try {
      final repository = ref.read(nutritionRepositoryProvider);
      final response = await repository.getSavedFoods(
        userId: widget.userId,
        limit: 10,
      );
      if (mounted) {
        setState(() {
          _favorites = response.items;
          _isLoadingFavorites = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      if (mounted) {
        setState(() => _isLoadingFavorites = false);
      }
    }
  }

  Future<void> _logFavorite(SavedFood food) async {
    try {
      final repository = ref.read(nutritionRepositoryProvider);
      // Determine meal type based on time of day
      final hour = DateTime.now().hour;
      String mealType;
      if (hour < 10) {
        mealType = 'breakfast';
      } else if (hour < 14) {
        mealType = 'lunch';
      } else if (hour < 17) {
        mealType = 'snack';
      } else {
        mealType = 'dinner';
      }

      await repository.relogSavedFood(
        userId: widget.userId,
        savedFoodId: food.id,
        mealType: mealType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged ${food.name}'),
            backgroundColor:
                widget.isDark ? AppColors.success : AppColorsLight.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log: $e'),
            backgroundColor:
                widget.isDark ? AppColors.error : AppColorsLight.error,
          ),
        );
      }
    }
  }

  void _showGoalsInfo() {
    final prefsState = ref.read(nutritionPreferencesProvider);
    final elevated =
        widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted =
        widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final purple = widget.isDark ? AppColors.purple : AppColorsLight.purple;
    final orange = widget.isDark ? AppColors.orange : AppColorsLight.orange;
    final coral = widget.isDark ? AppColors.coral : AppColorsLight.coral;

    // Hide nav bar while sheet is open
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        showHandle: false,
        child: DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.track_changes, color: teal, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Your Daily Goals',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap settings icon to adjust these targets',
                        style: TextStyle(
                          fontSize: 13,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Goals list
                      GoalRow(
                        icon: Icons.local_fire_department,
                        label: 'Calories',
                        value: '${prefsState.currentCalorieTarget}',
                        unit: 'kcal',
                        color: teal,
                        isDark: widget.isDark,
                      ),
                      const SizedBox(height: 12),
                      GoalRow(
                        icon: Icons.egg_outlined,
                        label: 'Protein',
                        value: '${prefsState.currentProteinTarget}',
                        unit: 'g',
                        color: purple,
                        isDark: widget.isDark,
                      ),
                      const SizedBox(height: 12),
                      GoalRow(
                        icon: Icons.grain,
                        label: 'Carbohydrates',
                        value: '${prefsState.currentCarbsTarget}',
                        unit: 'g',
                        color: orange,
                        isDark: widget.isDark,
                      ),
                      const SizedBox(height: 12),
                      GoalRow(
                        icon: Icons.water_drop_outlined,
                        label: 'Fat',
                        value: '${prefsState.currentFatTarget}',
                        unit: 'g',
                        color: coral,
                        isDark: widget.isDark,
                      ),
                      const SizedBox(height: 12),
                      GoalRow(
                        icon: Icons.eco_outlined,
                        label: 'Fiber',
                        value: '30',
                        unit: 'g',
                        color: AppColors.cyan,
                        isDark: widget.isDark,
                      ),
                    ],
                  ),
                ),

                // Edit button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to nutrition settings
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: teal,
                        side: BorderSide(color: teal),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.settings, size: 18),
                      label: const Text('Edit Goals in Settings'),
                    ),
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      // Show nav bar again when sheet is closed
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    });
  }

  /// Show edit targets bottom sheet
  void _showEditTargetsSheet(BuildContext context) {
    final prefsState = ref.read(nutritionPreferencesProvider);
    if (prefsState.preferences == null) return;

    // Hide nav bar while sheet is open
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: EditTargetsSheet(
          userId: widget.userId,
          onSaved: () => widget.onRefresh(),
        ),
      ),
    ).whenComplete(() {
      // Show nav bar again when sheet is closed
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    });
  }

  /// Recalculate nutrition targets based on user profile
  Future<void> _recalculateTargets() async {
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;

    // Guard against empty userId
    if (widget.userId.isEmpty) {
      debugPrint('Warning: [NutritionScreen] Cannot recalculate targets - userId is empty');
      return;
    }

    try {
      await ref.read(nutritionPreferencesProvider.notifier).recalculateTargets(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Targets recalculated based on your profile'),
            backgroundColor: teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to recalculate: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final prefsState = ref.watch(nutritionPreferencesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await _loadFavorites();
        widget.onRefresh();
      },
      color: teal,
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. PINNED NUTRIENTS - Compact, at the very top
                if (widget.micronutrients != null &&
                    widget.micronutrients!.pinned.isNotEmpty) ...[
                  PinnedNutrientsCard(
                    pinned: widget.micronutrients!.pinned,
                    isDark: widget.isDark,
                    onEdit: () {
                      // Switch to Nutrients tab where users can pin/unpin nutrients
                      widget.onSwitchToNutrientsTab?.call();
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // 2. GOALS - Nutrition Goals Card
                if (!widget.calmMode)
                  NutritionGoalsCard(
                    targets: widget.targets,
                    summary: widget.summary,
                    isDark: widget.isDark,
                    onEdit: () => _showEditTargetsSheet(context),
                    onRecalculate: () => _recalculateTargets(),
                    onHydrationTap: widget.onSwitchToHydrationTab,
                  ),

                if (!widget.calmMode) const SizedBox(height: 8),

                // 3. MEAL SECTIONS - All 4 meal types always visible with inline add
                LoggedMealsSection(
                  meals: widget.summary?.meals ?? [],
                  onDeleteMeal: widget.onDeleteMeal,
                  onCopyMeal: widget.onCopyMeal,
                  onMoveMeal: widget.onMoveMeal,
                  onUpdateMeal: widget.onUpdateMeal,
                  onUpdateMealTime: widget.onUpdateMealTime,
                  onUpdateMealNotes: widget.onUpdateMealNotes,
                  onUpdateMealMood: widget.onUpdateMealMood,
                  onSaveFoodToFavorites: widget.onSaveFoodToFavorites,
                  onLogMeal: widget.onLogMeal,
                  apiClient: widget.apiClient,
                  isDark: widget.isDark,
                  userId: widget.userId,
                  onFoodSaved: _loadFavorites,
                  calorieTarget: ref.read(nutritionPreferencesProvider).currentCalorieTarget,
                  totalCaloriesEaten: widget.summary?.totalCalories ?? 0,
                ),
                const SizedBox(height: 12),

                const SizedBox(height: 80), // Nav bar clearance
              ],
            ),
          ),
        ],
      ),
    );
  }
}
