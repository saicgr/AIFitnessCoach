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
import '../../fasting/widgets/fasting_stage_model.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/providers/recipe_providers.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/main_shell.dart';
import 'edit_targets_sheet.dart';
import 'hydration_summary_block.dart';
import 'optional_trackers_strip.dart';
import 'logged_meals_section.dart';
import '../../home/widgets/hero_nutrition_card.dart';
import 'schedule_meal_sheet.dart' show SchedulePreset;
import 'goal_row.dart';
import 'nutrition_stats_section.dart';

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
                // Secondary CTA row: Log Water + Fasting, sitting above the
                // calorie card whose footer is the PRIMARY "Log Meal" button —
                // so the tab reads as 3 actions (Water / Fasting / Log Meal)
                // without demoting Log Meal (feedback_augment_dont_replace_ui).
                if (widget.userId.isNotEmpty && widget.isViewingToday)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Expanded(child: _LogWaterButton()),
                        const SizedBox(width: 10),
                        const Expanded(child: _FastingActiveBar()),
                      ],
                    ),
                  ),

                // 0. PENDING SYNC — a logged meal that hasn't reached the server
                //    yet (offline queue). Surfaced so a stranded write is never
                //    silently lost; tap retries the flush.
                if (widget.userId.isNotEmpty)
                  _PendingSyncBar(isDark: widget.isDark),

                // (Removed the "Focus this phase" / pinned-nutrients card —
                // user feedback. The cycle-phase nutrient strip and the pinned
                // micronutrient tracker no longer surface on the nutrition tab;
                // micronutrient detail still lives on pages 2/3 of the hero
                // nutrition carousel below.)

                // 1.5 LEFTOVERS — quick-log from active cook events.
                //     Only appears when the user has batch-cooked recipes remaining.
                _LeftoversCarousel(userId: widget.userId, isDark: widget.isDark),

                // 2. HERO — swipeable Google-Fit-style nutrition card (macros +
                //    micronutrient pages + living mascot). Today-only: it reads
                //    today's logged totals via its own providers, so for past
                //    dates we fall back to the date-scoped calorie-ring hero
                //    inside LoggedMealsSection (showHero below mirrors this).
                if (widget.isViewingToday) ...[
                  // Embedded mode self-sizes (fixed-height carousel + intrinsic
                  // footer) and drops its own horizontal padding so it aligns
                  // with the meal cards below. No external height bound needed.
                  const HeroNutritionCard(embedded: true),
                  const SizedBox(height: 12),
                ],

                // 3. MEAL SECTIONS with (date-scoped) hero-row summary at top.
                //    Daily Goals card removed — the 4 macro rings + goal-config strip
                //    now live on the Profile screen (Nutrition & Fasting card).
                //    On today, the hero row is suppressed (the HeroNutritionCard
                //    above replaces it); on other dates it shows the date's totals.
                Builder(builder: (ctx) {
                  final prefs = ref.watch(nutritionPreferencesProvider);
                  return LoggedMealsSection(
                    showHero: !widget.isViewingToday,
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
                // Gap 6 — hidden entirely when the user turned water tracking off.
                if (widget.userId.isNotEmpty &&
                    (ref.watch(nutritionPreferencesProvider).preferences
                            ?.hydrationTrackingEnabled ??
                        true)) ...[
                  HydrationSummaryBlock(
                    isDark: widget.isDark,
                    onTap: () => context.push('/hydration'),
                  ),
                  const SizedBox(height: 12),
                ],

                // Gap 7 — opt-in sugar / caffeine / alcohol trackers. Renders
                // nothing unless the user enabled at least one in Settings.
                if (widget.userId.isNotEmpty && widget.isViewingToday)
                  OptionalTrackersStrip(
                    userId: widget.userId,
                    isDark: widget.isDark,
                  ),

                // Week-at-a-glance "Nutrition stats" block. Gated on
                // isViewingToday so weekly aggregates don't show when the user
                // is paging back through historical dates.
                if (widget.userId.isNotEmpty && widget.isViewingToday) ...[
                  const SizedBox(height: 4),
                  NutritionStatsSection(
                    userId: widget.userId,
                    isDark: widget.isDark,
                  ),
                  const SizedBox(height: 12),
                ],

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
/// Fasting entry surface on the Nutrition Daily tab. Two visual states:
///
/// * **Inactive** — slim "Start a fast →" row. Discoverable entry point for
///   users who haven't started yet. Tap → `/fasting` picker.
/// * **Active** — protocol + current biological stage + dotted progress +
///   elapsed/remaining counters. Tap → `/fasting` for the full timeline,
///   long-press → quick actions sheet (Stop / Extend / Pause).
///
/// The biological stage label and tint come from `FastingStage` (the same
/// model that powers the Fasting Guide — 7 live metabolic stages from Fed
/// through Deep Autophagy). Resolving the stage is a const-table lookup
/// against `elapsedHours`; no network call.
/// Secondary "Log Water" CTA — half-width sibling of the fasting bar. Mirrors
/// the fasting bar's outlined-tile styling; taps into the hydration screen.
class _LogWaterButton extends ConsumerWidget {
  const _LogWaterButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.colors(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/hydration'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.cardBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.water_drop_outlined,
                    size: 16, color: colors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Log Water',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded,
                    size: 18, color: colors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FastingActiveBar extends ConsumerWidget {
  const _FastingActiveBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fasting = ref.watch(fastingProvider);
    final colors = ref.colors(context);

    if (!fasting.hasFast) {
      // ── Inactive state ─────────────────────────────────────────────
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/fasting'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined,
                      size: 16, color: colors.textSecondary),
                  const SizedBox(width: 10),
                  Text(
                    'Start a fast',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_rounded,
                      size: 18, color: colors.textMuted),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── Active state ────────────────────────────────────────────────
    final active = fasting.activeFast!;
    final elapsedHours = active.elapsedMinutes / 60.0;
    final goalHours = active.goalDurationMinutes ~/ 60;
    final stage = FastingStage.forElapsedHours(elapsedHours);
    final progressFraction = goalHours == 0
        ? 0.0
        : (elapsedHours / goalHours).clamp(0.0, 1.0).toDouble();

    final remainingMinutes = active.goalDurationMinutes - active.elapsedMinutes;
    final isOvertime = remainingMinutes <= 0;
    final remainingLabel = isOvertime
        ? '${fasting.elapsedTimeFormatted} (overtime)'
        : '${fasting.remainingTimeFormatted} left';

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: protocol · stage name
                Row(
                  children: [
                    Icon(stage.icon, size: 16, color: stage.color),
                    const SizedBox(width: 8),
                    Text(
                      _shortProtocolLabel(active.protocol, goalHours),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      ' · ',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textMuted,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        stage.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: stage.color,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: colors.textMuted),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 2: dotted progress (1 dot per goal-hour, capped at 18
                // so it never overflows on iPhone SE at 320pt wide).
                _FastingProgressDots(
                  goalHours: goalHours,
                  fraction: progressFraction,
                  fillColor: stage.color,
                  trackColor: colors.cardBorder,
                ),
                const SizedBox(height: 6),
                // Row 3: elapsed / remaining
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${fasting.elapsedTimeFormatted} elapsed',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                    Text(
                      remainingLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOvertime
                            ? stage.color
                            : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Compact protocol label like "16:8" / "18:6" / "OMAD". Falls back to
  /// the goal hours when the protocol string is custom or empty.
  String _shortProtocolLabel(String protocol, int goalHours) {
    if (protocol.isEmpty) return '${goalHours}h';
    // Already in "Nh" or "N:M" shape from the fasting picker → keep.
    if (protocol.contains(':') || protocol.endsWith('h')) return protocol;
    // Heuristic mapping for common goals when only a free-form name is set.
    switch (goalHours) {
      case 14:
        return '14:10';
      case 16:
        return '16:8';
      case 18:
        return '18:6';
      case 20:
        return '20:4';
      case 23:
      case 24:
        return 'OMAD';
      default:
        return '${goalHours}h';
    }
  }
}

/// Dotted progress strip: one dot per goal-hour. Filled dots use the
/// current stage's color; remaining dots use the neutral card border. Caps
/// at 18 dots so the row fits on iPhone SE (320pt) without overflow — long
/// fasts (24h+) compress to 18 dots evenly.
class _FastingProgressDots extends StatelessWidget {
  final int goalHours;
  final double fraction;
  final Color fillColor;
  final Color trackColor;

  const _FastingProgressDots({
    required this.goalHours,
    required this.fraction,
    required this.fillColor,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final dotCount = goalHours.clamp(8, 18);
    final filledDots = (fraction * dotCount).floor();
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: List.generate(dotCount, (i) {
        final filled = i < filledDots;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: filled ? fillColor : trackColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Slim, amber "waiting to sync" bar shown only when one or more logged meals
/// are still in the offline write queue (`pendingMealSyncCount > 0`). Tapping
/// Retry forces a flush attempt. Hidden entirely at zero, so it costs nothing
/// in the common case — its whole job is to make a stranded write visible
/// instead of silently lost.
class _PendingSyncBar extends ConsumerWidget {
  final bool isDark;
  const _PendingSyncBar({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(
        nutritionProvider.select((s) => s.pendingMealSyncCount));
    if (pending <= 0) return const SizedBox.shrink();

    final colors = ref.colors(context);
    final amber = isDark ? const Color(0xFFFFB74D) : const Color(0xFFE08600);
    final label = pending == 1
        ? '1 meal waiting to sync'
        : '$pending meals waiting to sync';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: amber.withValues(alpha: isDark ? 0.14 : 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: amber.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_upload_outlined, size: 17, color: amber),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Saved on this device, not yet on the server.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: amber.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  ref.read(nutritionProvider.notifier).retryPendingMealWrites();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: amber,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

