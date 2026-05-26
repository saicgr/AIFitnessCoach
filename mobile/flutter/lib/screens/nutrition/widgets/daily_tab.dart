import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../widgets/liquid_glass_action_bar.dart';
import '../../../data/models/nutrition.dart';
import '../../../data/models/micronutrients.dart';
import '../../../data/services/api_client.dart';
import '../../../data/providers/fasting_provider.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/providers/recipe_providers.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/main_shell.dart';
import 'edit_targets_sheet.dart';
import 'hydration_summary_block.dart';
import 'pinned_nutrients_card.dart';
import 'logged_meals_section.dart';
import 'schedule_meal_sheet.dart' show SchedulePreset;
import 'goal_row.dart';

import '../../../l10n/generated/app_localizations.dart';
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
  /// Per-item copy/move — promote one food inside a multi-item meal to its
  /// own standalone log under a different meal type.
  final void Function(String sourceLogId, int itemIdx, String targetMealType)? onCopyItem;
  final void Function(String sourceLogId, int itemIdx, String targetMealType)? onMoveItem;
  final void Function(String logId, int calories, double proteinG, double carbsG, double fatG, {double? weightG, List<Map<String, dynamic>>? foodItems, List<FoodItemEdit>? itemEdits}) onUpdateMeal;
  final void Function(String logId, DateTime newTime) onUpdateMealTime;
  final void Function(String logId, String notes) onUpdateMealNotes;
  final void Function(String logId, {String? moodBefore, String? moodAfter, int? energyLevel}) onUpdateMealMood;
  final void Function(FoodLog meal) onSaveFoodToFavorites;
  final void Function(FoodLog meal, {int? itemIndex, bool createCookEvent}) onSaveMealAsRecipe;
  final void Function(FoodLog meal, {SchedulePreset initialPreset, int? itemIndex}) onScheduleMeal;
  final void Function(FoodLog meal, {int? itemIndex}) onAddToShoppingList;
  final void Function(FoodLog meal) onShareMeal;
  final void Function(String mealType) onShareMealGroup;
  /// Share the whole day's nutrition card. Surface 3.1 — share moved off
  /// the screen header into the calorie card; null hides the in-card icon.
  final VoidCallback? onShareDay;
  final Future<List<FoodLogEditRecord>> Function(String logId)? onFetchItemEdits;
  final ApiClient? apiClient;
  final VoidCallback? onSwitchToNutrientsTab;
  final VoidCallback? onSwitchToHydrationTab;
  final bool isDark;
  final bool calmMode;
  /// When false, the streak / "start your streak" banner is suppressed —
  /// showing a "log a meal today" CTA while the user is viewing a past day
  /// is nonsensical.
  final bool isViewingToday;

  /// Forwarded to [FastingSavedRow] so its cards carry the `nutrition_v1`
  /// tour anchor keys only while the first-run tour is active.
  final bool tourActive;

  const DailyTab({
    super.key,
    required this.userId,
    this.tourActive = false,
    this.summary,
    this.targets,
    this.micronutrients,
    this.isViewingToday = true,
    required this.onRefresh,
    required this.onLogMeal,
    required this.onDeleteMeal,
    required this.onCopyMeal,
    required this.onMoveMeal,
    this.onCopyItem,
    this.onMoveItem,
    required this.onUpdateMeal,
    required this.onUpdateMealTime,
    required this.onUpdateMealNotes,
    required this.onUpdateMealMood,
    required this.onSaveFoodToFavorites,
    required this.onSaveMealAsRecipe,
    required this.onScheduleMeal,
    required this.onAddToShoppingList,
    required this.onShareMeal,
    required this.onShareMealGroup,
    this.onShareDay,
    this.onFetchItemEdits,
    this.apiClient,
    this.onSwitchToNutrientsTab,
    this.onSwitchToHydrationTab,
    required this.isDark,
    this.calmMode = false,
  });

  @override
  ConsumerState<DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends ConsumerState<DailyTab>
    with AutomaticKeepAliveClientMixin {
  List<SavedFood> _favorites = [];
  bool _isLoadingFavorites = false;
  bool _analyticsExpanded = false;

  // Keep this tab's state alive when the user switches away and back —
  // otherwise the favorites fetch and the (heavy) meal-list rebuild fires
  // on every visit, which is the perceived "lag" when returning to Daily.
  @override
  bool get wantKeepAlive => true;

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
                            AppLocalizations.of(context).dailyYourDailyGoals,
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
                        AppLocalizations.of(context).dailyTapSettingsIconTo,
                        style: TextStyle(
                          fontSize: 13,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Goals list
                      GoalRow(
                        icon: Icons.local_fire_department,
                        label: AppLocalizations.of(context).workoutSummaryGeneralCalories,
                        value: '${prefsState.currentCalorieTarget}',
                        unit: 'kcal',
                        color: teal,
                        isDark: widget.isDark,
                      ),
                      const SizedBox(height: 12),
                      GoalRow(
                        icon: Icons.egg_outlined,
                        label: AppLocalizations.of(context).weeklyCheckinSheetProtein,
                        value: '${prefsState.currentProteinTarget}',
                        unit: 'g',
                        color: purple,
                        isDark: widget.isDark,
                      ),
                      const SizedBox(height: 12),
                      GoalRow(
                        icon: Icons.grain,
                        label: AppLocalizations.of(context).dailyCarbohydrates,
                        value: '${prefsState.currentCarbsTarget}',
                        unit: 'g',
                        color: orange,
                        isDark: widget.isDark,
                      ),
                      const SizedBox(height: 12),
                      GoalRow(
                        icon: Icons.water_drop_outlined,
                        label: AppLocalizations.of(context).weeklyCheckinSheetFat,
                        value: '${prefsState.currentFatTarget}',
                        unit: 'g',
                        color: coral,
                        isDark: widget.isDark,
                      ),
                      const SizedBox(height: 12),
                      GoalRow(
                        icon: Icons.eco_outlined,
                        label: AppLocalizations.of(context).recipeBuilderSheetFiber,
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
                      label: Text(AppLocalizations.of(context).dailyEditGoalsInSettings),
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
  void _showPinnedNutrientsEditSheet() {
    final micro = widget.micronutrients;
    if (micro == null) return;

    // Hide the floating nav bar while the sheet is open.
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;
    showGlassSheet(
      context: context,
      builder: (_) => GlassSheet(
        child: _PinnedNutrientsEditSheet(
          userId: widget.userId,
          micronutrients: micro,
          isDark: widget.isDark,
          onSaved: () => widget.onRefresh(),
        ),
      ),
    ).whenComplete(() {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    });
  }

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

  // Note: `_recalculateTargets` used to live here as the handler for the
  // refresh icon on the removed NutritionGoalsCard. The equivalent flow is
  // now exposed as "Recalculate from profile" inside EditTargetsSheet.

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;

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
                // Surface 3.2 — the Fasting + Saved split row is gone.
                // Fasting becomes contextual: a slim "Fasting active" bar
                // appears above the calorie card only while a fast is in
                // progress; idle = hidden. Saved is reachable via the
                // Nutrition header kebab and the Recipes sub-tab.
                if (widget.userId.isNotEmpty && widget.isViewingToday)
                  const _FastingActiveBar(),

                // 1. MORE NUTRIENTS (formerly "Pinned nutrients") — Compact, at the very top
                if (widget.micronutrients != null &&
                    widget.micronutrients!.pinned.isNotEmpty) ...[
                  PinnedNutrientsCard(
                    pinned: widget.micronutrients!.pinned,
                    isDark: widget.isDark,
                    onEdit: () => _showPinnedNutrientsEditSheet(),
                  ),
                  const SizedBox(height: 12),
                ],

                // 1.5 LEFTOVERS — quick-log from active cook events.
                //     Only appears when the user has batch-cooked recipes remaining.
                _LeftoversCarousel(userId: widget.userId, isDark: widget.isDark),

                // 2. MEAL SECTIONS with hero-row summary at top of card.
                //    Daily Goals card removed — the 4 macro rings + goal-config strip
                //    now live on the Profile screen (Nutrition & Fasting card).
                //    Calorie remaining + macro progress is now the hero of this card.
                Builder(builder: (ctx) {
                  final prefs = ref.watch(nutritionPreferencesProvider);
                  return LoggedMealsSection(
                    meals: widget.summary?.meals ?? [],
                    onDeleteMeal: widget.onDeleteMeal,
                    onCopyMeal: widget.onCopyMeal,
                    onMoveMeal: widget.onMoveMeal,
                    onCopyItem: widget.onCopyItem,
                    onMoveItem: widget.onMoveItem,
                    onUpdateMeal: widget.onUpdateMeal,
                    onUpdateMealTime: widget.onUpdateMealTime,
                    onUpdateMealNotes: widget.onUpdateMealNotes,
                    onUpdateMealMood: widget.onUpdateMealMood,
                    onSaveFoodToFavorites: widget.onSaveFoodToFavorites,
                    onSaveMealAsRecipe: widget.onSaveMealAsRecipe,
                    onScheduleMeal: widget.onScheduleMeal,
                    onAddToShoppingList: widget.onAddToShoppingList,
                    onShareMeal: widget.onShareMeal,
                    onShareMealGroup: widget.onShareMealGroup,
                    onLogMeal: widget.onLogMeal,
                    onFetchItemEdits: widget.onFetchItemEdits,
                    apiClient: widget.apiClient,
                    isDark: widget.isDark,
                    userId: widget.userId,
                    onFoodSaved: _loadFavorites,
                    // Pass null when the user hasn't configured nutrition
                    // targets so the section shows "Set a calorie target"
                    // instead of presenting the 2000 fallback as a real
                    // plan (the user spotted this on 2026-05-25).
                    calorieTarget: prefs.hasConfiguredTargets
                        ? prefs.currentCalorieTarget
                        : null,
                    totalCaloriesEaten: widget.summary?.totalCalories ?? 0,
                    proteinTarget: prefs.hasConfiguredTargets
                        ? prefs.currentProteinTarget
                        : 0,
                    carbsTarget: prefs.hasConfiguredTargets
                        ? prefs.currentCarbsTarget
                        : 0,
                    fatTarget: prefs.hasConfiguredTargets
                        ? prefs.currentFatTarget
                        : 0,
                    consumedProtein: widget.summary?.totalProteinG ?? 0,
                    consumedCarbs: widget.summary?.totalCarbsG ?? 0,
                    consumedFat: widget.summary?.totalFatG ?? 0,
                    onEditTargets: widget.calmMode ? null : () => _showEditTargetsSheet(context),
                    onShareDay: widget.onShareDay,
                  );
                }),
                const SizedBox(height: 12),

                // Surface 3.6 — Water tile re-mounts here as a slim tile
                // below the calorie card. The "Fuel" sub-tab is gone, so
                // hydration lives in Daily for at-a-glance tracking.
                if (widget.userId.isNotEmpty)
                  HydrationSummaryBlock(
                    isDark: widget.isDark,
                    onTap: () => context.push('/hydration'),
                  ),
                if (widget.userId.isNotEmpty) const SizedBox(height: 12),

                // Clearance for the floating Daily / Recipes / Patterns
                // glass tab bar (sits at viewPadding.bottom + 76, height 56)
                // plus the MainShell nav below it.
                SizedBox(
                  height: MediaQuery.of(context).viewPadding.bottom +
                      76 +
                      kLiquidGlassActionBarHeight +
                      16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet that lets users pin/unpin micronutrients directly from the
/// Pinned Nutrients card's ✏ button. Previously the button just navigated
/// to the Nutrients tab, which didn't actually edit anything.
class _PinnedNutrientsEditSheet extends ConsumerStatefulWidget {
  final String userId;
  final DailyMicronutrientSummary micronutrients;
  final bool isDark;
  final VoidCallback onSaved;

  const _PinnedNutrientsEditSheet({
    required this.userId,
    required this.micronutrients,
    required this.isDark,
    required this.onSaved,
  });

  @override
  ConsumerState<_PinnedNutrientsEditSheet> createState() =>
      _PinnedNutrientsEditSheetState();
}

class _PinnedNutrientsEditSheetState
    extends ConsumerState<_PinnedNutrientsEditSheet> {
  late Set<String> _pinned;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _pinned = widget.micronutrients.pinned
        .map((n) => n.nutrientKey)
        .toSet();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(nutritionRepositoryProvider).updatePinnedNutrients(
            userId: widget.userId,
            pinnedNutrients: _pinned.toList(),
          );
      if (!mounted) return;
      widget.onSaved();
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).nutrientExplorerFailedToUpdatePinned)),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    final groups = <String, List<NutrientProgress>>{
      'Vitamins': widget.micronutrients.vitamins,
      'Minerals': widget.micronutrients.minerals,
      'Fatty Acids': widget.micronutrients.fattyAcids,
      'Other': widget.micronutrients.other,
    };

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppLocalizations.of(context).dailyPinNutrients,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_pinned.length} pinned',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: teal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).dailyPickTheNutrientsYou,
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final entry in groups.entries) ...[
                      if (entry.value.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 6),
                          child: Text(
                            entry.key.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: textMuted,
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final n in entry.value)
                              _NutrientToggleChip(
                                label: n.displayName,
                                selected: _pinned.contains(n.nutrientKey),
                                // Per-nutrient color sourced from the backend
                                // (n.progressColor — '#FF0000' etc.). Falls
                                // back to the teal accent if parsing fails.
                                accent: _parseHex(n.progressColor) ?? teal,
                                elevated: isDark
                                    ? AppColors.elevated
                                    : AppColorsLight.elevated,
                                textPrimary: textPrimary,
                                textMuted: textMuted,
                                cardBorder: cardBorder,
                                onTap: () {
                                  setState(() {
                                    if (_pinned.contains(n.nutrientKey)) {
                                      _pinned.remove(n.nutrientKey);
                                    } else {
                                      _pinned.add(n.nutrientKey);
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal,
                  foregroundColor: isDark ? AppColors.pureBlack : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(AppLocalizations.of(context).buttonSave,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Parse a "#RRGGBB" / "RRGGBB" hex string into a Color. Returns null if the
/// input can't be parsed.
Color? _parseHex(String hex) {
  var s = hex.replaceFirst('#', '');
  if (s.length == 6) s = 'FF$s';
  if (s.length != 8) return null;
  final v = int.tryParse(s, radix: 16);
  if (v == null) return null;
  return Color(v);
}

class _NutrientToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final Color elevated;
  final Color textPrimary;
  final Color textMuted;
  final Color cardBorder;
  final VoidCallback onTap;

  const _NutrientToggleChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.elevated,
    required this.textPrimary,
    required this.textMuted,
    required this.cardBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
        decoration: BoxDecoration(
          // Selected chips fill with the nutrient's accent; unselected get
          // a faint tint of the same accent so the sheet still reads as a
          // colourful palette instead of a wall of grey pills.
          color: selected
              ? accent.withValues(alpha: 0.22)
              : accent.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? accent
                : accent.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Leading colour dot so every chip telegraphs its accent even
            // when the label itself is unselected text.
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            // Flexible + ellipsis: a long nutrient label (or a long-locale
            // translation) would otherwise overflow this fixed-width chip Row.
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? accent : textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              selected
                  ? Icons.push_pin_rounded
                  : Icons.push_pin_outlined,
              size: 13,
              color: selected ? accent : accent.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick-log-from-leftovers carousel. Appears above the meal-sections card
/// when the user has active cook events (batch-cooked recipes with portions
/// remaining). Tapping a chip logs one portion now under the current meal slot
/// and decrements portions_remaining (DB trigger from migration 509).
class _LeftoversCarousel extends ConsumerWidget {
  final String userId;
  final bool isDark;
  const _LeftoversCarousel({required this.userId, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId.isEmpty) return const SizedBox.shrink();
    final leftoversAsync = ref.watch(activeCookEventsProvider(userId));
    return leftoversAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final accent = AppColors.orange; // matches leftovers warning color family
        final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
        final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
        final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  AppLocalizations.of(context).dailyLeftoversReadyToLog,
                  style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final ev = items[i];
                    final warningColor = ev.isExpired
                        ? AppColors.error
                        : ev.isExpiringSoon
                            ? AppColors.yellow
                            : accent;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: ev.isExpired ? null : () async {
                        try {
                          await ref.read(nutritionRepositoryProvider).logRecipe(
                                userId: userId,
                                recipeId: ev.recipeId ?? '',
                                mealType: _currentMealSlot(),
                                servings: 1.0,
                              );
                          // Invalidate so the carousel updates portions_remaining
                          ref.invalidate(activeCookEventsProvider(userId));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Logged ${ev.recipeName ?? "leftover"}')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Log failed: $e')),
                            );
                          }
                        }
                      },
                      child: Container(
                        width: 200,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: warningColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.kitchen_rounded, color: warningColor, size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    ev.isExpired ? AppLocalizations.of(context).recipesExpired : AppLocalizations.of(context).dailyTapToLog,
                                    style: TextStyle(fontSize: 9, color: warningColor, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ev.recipeName ?? AppLocalizations.of(context).recipesCookedDish,
                                    style: TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.w700),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${ev.portionsRemaining.toStringAsFixed(0)} of ${ev.portionsMade.toStringAsFixed(0)} left',
                                    style: TextStyle(color: muted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _currentMealSlot() {
    final h = DateTime.now().hour;
    if (h < 10) return 'breakfast';
    if (h < 14) return 'lunch';
    if (h < 17) return 'snack';
    return 'dinner';
  }
}

/// Surface 3.2 — slim contextual bar shown directly above the calorie card
/// ONLY while a fast is in progress. Idle state renders nothing (the bar
/// disappears completely). Tap routes to the full /fasting screen.
class _FastingActiveBar extends ConsumerWidget {
  const _FastingActiveBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fasting = ref.watch(fastingProvider);
    if (!fasting.hasFast) return const SizedBox.shrink();

    final colors = ref.colors(context);
    final remainingMinutes = fasting.activeFast!.goalDurationMinutes -
        fasting.activeFast!.elapsedMinutes;
    final value = remainingMinutes > 0
        ? '${fasting.remainingTimeFormatted} left'
        : fasting.elapsedTimeFormatted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/fasting'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.cardBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, size: 16, color: colors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Fasting active',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: colors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
