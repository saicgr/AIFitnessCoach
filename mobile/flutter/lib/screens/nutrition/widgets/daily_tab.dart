import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/chrome_constants.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/nutrition.dart';
import 'nutrition_catalog_view.dart';
import '../../../data/models/micronutrients.dart';
import '../../../data/services/api_client.dart';
import '../../../data/repositories/hydration_repository.dart';
import '../../workout/widgets/hydration_dialog.dart';
import '../../../data/providers/fasting_provider.dart';
import '../../fasting/widgets/fasting_stage_model.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/providers/meal_logged_ghost_provider.dart';
import '../../../data/providers/recipe_providers.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../widgets/design_system/zealova.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/main_shell.dart';
import 'edit_targets_sheet.dart';
import 'hydration_summary_block.dart';
import 'optional_trackers_strip.dart';
import 'coach_recommends_card.dart';
import 'micros_entry_card.dart';
import 'logged_meals_section.dart';
import '../../../widgets/tooltips/tooltip_anchors.dart';
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

  /// The date the tab is currently showing. Drives the date-scoped nutrition
  /// family reads (headline + meal sections) and the Log Meal target date so
  /// logging on a past day files onto that day, not "now".
  final DateTime selectedDate;

  /// Forwarded to [FastingSavedRow] so its cards carry the `nutrition_v1`
  /// tour anchor keys only while the first-run tour is active.
  final bool tourActive;

  /// When 'water', the tab auto-scrolls to the hydration card on first build /
  /// on a deep-link re-navigation (e.g. the Home "Water" card or a hydration
  /// reminder). Water lives on Daily now (the Fuel sub-tab was retired).
  final String? initialFuelSection;

  const DailyTab({
    super.key,
    required this.userId,
    this.tourActive = false,
    this.summary,
    this.targets,
    this.micronutrients,
    this.isViewingToday = true,
    required this.selectedDate,
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
    this.initialFuelSection,
  });

  @override
  ConsumerState<DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends ConsumerState<DailyTab>
    with AutomaticKeepAliveClientMixin {
  List<SavedFood> _favorites = [];
  bool _isLoadingFavorites = false;
  bool _analyticsExpanded = false;

  // Body scroll controller + an anchor on the hydration card so "Log Water"
  // (and a ?fuelSection=water deep link) can smooth-scroll to the tracker that
  // now lives inline on the Daily tab.
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _hydrationKey = GlobalKey();

  // Keep this tab's state alive when the user switches away and back —
  // otherwise the favorites fetch and the (heavy) meal-list rebuild fires
  // on every visit, which is the perceived "lag" when returning to Daily.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    if (widget.initialFuelSection == 'water') _scheduleScrollToHydration();
  }

  @override
  void didUpdateWidget(DailyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A deep-link re-navigation (Home "Water" card / hydration reminder) keeps
    // this State alive (IndexedStack) and just passes a new fuelSection — so
    // re-arm the scroll when it newly becomes 'water'.
    if (widget.initialFuelSection == 'water' &&
        oldWidget.initialFuelSection != 'water') {
      _scheduleScrollToHydration();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Smooth-scroll the body so the inline hydration card is fully visible.
  void _scrollToHydration() {
    final ctx = _hydrationKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      alignment: 0.1, // park it near the top, not flush against the app bar
    );
  }

  void _scheduleScrollToHydration() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToHydration();
    });
  }

  /// Open the shared drink-logging sheet and persist the result. This is the
  /// hydration card's tap target now that the old `/hydration` screen is gone
  /// (its route only redirected back into the Nutrition tabs).
  Future<void> _logWaterFromCard() async {
    final result = await showHydrationDialog(
      context: context,
      totalIntakeMl: ref.read(hydrationProvider).todaySummary?.totalMl ?? 0,
    );
    if (result == null || !mounted) return;
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId == null || !mounted) return;
    await ref.read(hydrationProvider.notifier).quickLog(
          userId: userId,
          drinkType: result.drinkType.name,
          amountMl: result.amountMl,
        );
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
        // Signature v2 — flash the "✓ Added to <Meal>" ghost on the slot the
        // saved food filed into (computed above by time of day).
        ref.read(mealLoggedGhostProvider.notifier).show(mealType);
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
                          Icon(Icons.track_changes, color: teal, size: 22),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context).dailyYourDailyGoals.toUpperCase(),
                            style: ZType.disp(22, color: textPrimary, letterSpacing: 0.5),
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
            controller: _scrollController,
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
                        Expanded(child: _LogWaterButton(onTap: _scrollToHydration)),
                        const SizedBox(width: 10),
                        const Expanded(child: _FastingActiveBar()),
                      ],
                    ),
                  ),

                // 0. PENDING SYNC — a logged meal that hasn't reached the server
                //    yet (offline queue). Surfaced so a stranded write is never
                //    silently lost; tap retries the flush.
                if (widget.userId.isNotEmpty)
                  _PendingSyncBar(isDark: widget.isDark, userId: widget.userId),

                // (Removed the "Focus this phase" / pinned-nutrients card —
                // user feedback. The cycle-phase nutrient strip and the pinned
                // micronutrient tracker no longer surface on the nutrition tab;
                // micronutrient detail still lives on pages 2/3 of the hero
                // nutrition carousel below.)

                // 1.5 LEFTOVERS — quick-log from active cook events.
                //     Only appears when the user has batch-cooked recipes remaining.
                _LeftoversCarousel(userId: widget.userId, isDark: widget.isDark),

                // 2. HEADLINE — signature-v2 fuel ledger lead. A big Anton
                //    calorie numeral + targets chip, a hairline consumed/target
                //    track, the three SEMANTIC macro rows (protein violet /
                //    carbs cyan / fat orange) in the `rn-mline` shape, a muted
                //    "Xg protein left · Y kcal left" line, and a Fraunces coach
                //    whisper. This replaces the ring-card's role as the visual
                //    hero (the v2 frame is flat, hairline-led — no ring).
                //    Pure presentation: reads `widget.summary` + the prefs
                //    targets; no new mutation, no provider write.
                _NutritionHeadline(
                  summary: widget.summary,
                  isViewingToday: widget.isViewingToday,
                  onEditTargets:
                      widget.calmMode ? null : () => _showEditTargetsSheet(context),
                ),

                // 2b. PRIMARY LOG MEAL CTA — signature-v2 is MEAL-led: the
                //    headline owns the hero numeral + macro dots, and the
                //    record IS the meal sections below. The old swipeable
                //    Google-Fit "fuel detail" card (living mascot + ring +
                //    P/C/F gradient pills) was OFF-SPEC and is removed. Its
                //    only load-bearing affordance was the primary "Log Meal"
                //    button (the per-meal "+" rows in LoggedMealsSection are
                //    secondary), so we re-add the single Signature primary CTA
                //    here — wired to the SAME `onLogMeal` callback (null slot =
                //    let the log file into the slot picked downstream) — and
                //    keep the first-run `nutritionLogMeal` tour anchor on it so
                //    the coach-mark still has its target.
                const SizedBox(height: 16),
                KeyedSubtree(
                  key: widget.tourActive
                      ? TooltipAnchors.nutritionLogMeal
                      : null,
                  child: ZealovaButton(
                    label: 'Log Meal',
                    trailingIcon: Icons.add_rounded,
                    onTap: () => widget.onLogMeal(null),
                  ),
                ),
                const SizedBox(height: 4),
                // F3 — "Coach recommends" card backed by /quick-suggestion.
                // Self-hides until a suggestion is available (no empty shell).
                // Today-only: recommending meals for a past day is nonsensical.
                if (widget.isViewingToday && widget.userId.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  CoachRecommendsCard(
                    userId: widget.userId,
                    isDark: widget.isDark,
                  ),
                ],

                // 3. MEAL SECTIONS — the durable record (BREAKFAST / LUNCH /
                //    DINNER / SNACKS as collapsible hairline sections). Daily
                //    Goals card removed — the 4 macro rings + goal-config strip
                //    now live on the Profile screen (Nutrition & Fasting card).
                //    The signature-v2 headline above owns the calorie numeral +
                //    macro dots, so this section renders only the meal list (no
                //    embedded ring hero).
                // Magazine catalog — a grid of the day's food photos (the
                // user's uploaded images; no AI generation). Opens on tap.
                if ((widget.summary?.meals ?? const []).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text("TODAY'S LOG",
                              style: ZType.lbl(11,
                                  color: ThemeColors.of(context).textMuted,
                                  letterSpacing: 2)),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Catalog view',
                          onPressed: () {
                            final meals = widget.summary?.meals ?? const <FoodLog>[];
                            showNutritionCatalog(
                              context,
                              meals: meals,
                              dateLabel: widget.isViewingToday ? 'Today' : 'Logged',
                              totalCalories: meals.fold<int>(
                                  0, (s, m) => s + m.totalCalories),
                            );
                          },
                          icon: Icon(Icons.grid_view_rounded,
                              size: 19,
                              color: ThemeColors.of(context).textMuted),
                        ),
                      ],
                    ),
                  ),
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
                // Gap 6 — hidden entirely when the user turned water tracking off.
                if (widget.userId.isNotEmpty &&
                    (ref.watch(nutritionPreferencesProvider).preferences
                            ?.hydrationTrackingEnabled ??
                        true)) ...[
                  HydrationSummaryBlock(
                    key: _hydrationKey,
                    isDark: widget.isDark,
                    // Old `/hydration` route only redirected back into the
                    // Nutrition tabs (and mis-landed on Patterns); tapping the
                    // card now opens the drink-log sheet inline.
                    onTap: _logWaterFromCard,
                    // Explicit "+" quick-log affordance on the card header.
                    onAdd: _logWaterFromCard,
                  ),
                ],

                // Gap 7 — opt-in sugar / caffeine / alcohol trackers. Renders
                // nothing unless the user enabled at least one in Settings.
                // Owns its own leading gap so an empty strip never doubles the
                // spacing between Hydration and Vitamins (it returns
                // SizedBox.shrink when no tracker is enabled).
                if (widget.userId.isNotEmpty && widget.isViewingToday)
                  OptionalTrackersStrip(
                    userId: widget.userId,
                    isDark: widget.isDark,
                  ),

                // F5 — "Vitamins & minerals" entry point. Expands to a peek of
                // pinned nutrients and opens the full micros detail view.
                if (widget.userId.isNotEmpty && widget.isViewingToday) ...[
                  const SizedBox(height: 12),
                  MicrosEntryCard(
                    micronutrients: widget.micronutrients,
                    isDark: widget.isDark,
                  ),
                ],

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

                // Clearance for the floating MainShell nav. The Daily /
                // Recipes / Patterns selector moved to a top segmented
                // control (chrome consolidation Variant A, 2026-06), so the
                // old 76px sub-tab-bar clearance is gone.
                SizedBox(
                  height: MediaQuery.of(context).viewPadding.bottom +
                      kMainNavClearance +
                      16,
                ),
              ],
            ),
          ),
          // Signature v2 — the transient "✓ Added to <Meal>" ghost. Auto-
          // dismisses; presentation-only. Sits above the meal sections (the
          // durable record) but below the nav, parked near the composer line.
          const Positioned(
            left: 0,
            right: 0,
            bottom: 96,
            child: IgnorePointer(child: _MealLoggedGhostOverlay()),
          ),
        ],
      ),
    );
  }
}

/// The auto-dismissing "✓ Added to [meal]" ghost (Signature v2 · Nutrition).
///
/// Listens to [mealLoggedGhostProvider]; when a new event arrives it fades +
/// rises in, holds briefly, then fades out and clears the provider. Pure
/// presentation — it carries no logging side effect. Filing into the correct
/// meal is decided upstream (by the entry's timestamp / picked slot); this
/// overlay only NAMES the meal the log landed in.
class _MealLoggedGhostOverlay extends ConsumerStatefulWidget {
  const _MealLoggedGhostOverlay();

  @override
  ConsumerState<_MealLoggedGhostOverlay> createState() =>
      _MealLoggedGhostOverlayState();
}

class _MealLoggedGhostOverlayState
    extends ConsumerState<_MealLoggedGhostOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _lastSeq = 0;
  String _mealLabel = '';
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _trigger(MealLoggedGhost ghost) {
    _lastSeq = ghost.seq;
    // 'snack' → "Snacks" to match the Snacks meal-section label.
    final label =
        ghost.mealType == 'snack' ? 'Snacks' : _titleCase(ghost.mealType);
    setState(() => _mealLabel = label);
    _holdTimer?.cancel();
    _controller.forward(from: 0);
    // Hold ~1.5s after the entrance, then fade out and clear.
    _holdTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _controller.reverse().then((_) {
        if (mounted) ref.read(mealLoggedGhostProvider.notifier).clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Fire whenever a new ghost event lands (dedupe by monotonic seq).
    ref.listen<MealLoggedGhost?>(mealLoggedGhostProvider, (prev, next) {
      if (next != null && next.seq != _lastSeq) _trigger(next);
    });

    if (_mealLabel.isEmpty) return const SizedBox.shrink();

    final tc = ThemeColors.of(context);
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeOutCubic.transform(_controller.value);
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 10),
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: tc.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: tc.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: tc.isDark ? 0.4 : 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, size: 15, color: tc.textPrimary),
              const SizedBox(width: 8),
              Text(
                'Added to $_mealLabel'.toUpperCase(),
                style: ZType.lbl(11.5,
                    color: tc.textPrimary, letterSpacing: 1.4),
              ),
            ],
          ),
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
                  AppLocalizations.of(context).dailyLeftoversReadyToLog.toUpperCase(),
                  style: ZType.lbl(11, color: muted, letterSpacing: 2.0),
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
                        final mealSlot = _currentMealSlot();
                        try {
                          await ref.read(nutritionRepositoryProvider).logRecipe(
                                userId: userId,
                                recipeId: ev.recipeId ?? '',
                                mealType: mealSlot,
                                servings: 1.0,
                              );
                          // Signature v2 — ghost confirms the leftover's meal slot.
                          ref.read(mealLoggedGhostProvider.notifier).show(mealSlot);
                          // Invalidate so the carousel updates portions_remaining
                          ref.invalidate(activeCookEventsProvider(userId));
                          // Reflect the logged leftover on the Daily summary
                          // (rings + meal list), Home timeline, and the weekly
                          // NUTRITION STATS + inflammation trend.
                          final notifier = ref.read(
                              dailyNutritionProvider(todayNutritionKey())
                                  .notifier);
                          notifier.load(userId, forceRefresh: true);
                          notifier.refreshTimeline();
                          notifier.refreshNutritionStats(userId);
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
  final VoidCallback onTap;
  const _LogWaterButton({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.colors(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
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
                    'LOG WATER',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ZType.lbl(13, color: colors.textPrimary, letterSpacing: 1.5),
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
                    'START A FAST',
                    style: ZType.lbl(13, color: colors.textPrimary, letterSpacing: 1.5),
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

/// ═══════════════════════════════════════════════════════════════════════
/// _NutritionHeadline — the signature-v2 "fuel ledger" lead composition.
///
/// Maps 1:1 to Section C · Nutrition frame 1 (`#nutrition`) of
/// `docs/planning/app-redesign-2026-06/signature-v2.html`:
///   • a big Anton calorie numeral (`disp 54`) + a "Targets · N kcal ▸" chip
///     (`.rn-chip`, tap → edit-targets sheet),
///   • a 3px hairline consumed/target track (`.rn-track`),
///   • the three SEMANTIC macro rows (`.rn-mline`): a colored dot + `eaten/goal`
///     + a P/C/F mark — protein violet, carbs cyan, fat orange (kept semantic),
///   • a muted "Xg protein left · Y kcal left" line (`.lbl` mut),
///   • a Fraunces coach whisper (`.rn-coach`).
///
/// Pure presentation — reads [summary] and the nutrition-preferences targets;
/// it performs no mutation and no provider write. When the user has not
/// configured targets the chip reads "Set a target" and the remaining-line is
/// suppressed (we never present the 2000 fallback as a real plan).
class _NutritionHeadline extends ConsumerWidget {
  final DailyNutritionSummary? summary;
  final bool isViewingToday;
  final VoidCallback? onEditTargets;

  const _NutritionHeadline({
    required this.summary,
    required this.isViewingToday,
    required this.onEditTargets,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final prefs = ref.watch(nutritionPreferencesProvider);
    final configured = prefs.hasConfiguredTargets;

    final eatenCal = summary?.totalCalories ?? 0;
    final eatenP = (summary?.totalProteinG ?? 0).round();
    final eatenC = (summary?.totalCarbsG ?? 0).round();
    final eatenF = (summary?.totalFatG ?? 0).round();

    final calTarget = configured ? prefs.currentCalorieTarget : 0;
    final pTarget = configured ? prefs.currentProteinTarget : 0;
    final cTarget = configured ? prefs.currentCarbsTarget : 0;
    final fTarget = configured ? prefs.currentFatTarget : 0;

    final calLeft = (calTarget - eatenCal);
    final pLeft = (pTarget - eatenP);
    final fraction = (configured && calTarget > 0)
        ? (eatenCal / calTarget).clamp(0.0, 1.0)
        : 0.0;

    // The "left" line mirrors the v2 caption ("64g protein left · 740 kcal
    // left"). Only shown today + when targets are configured + while there's
    // genuinely something left (an over-budget day flips to a spent line).
    String? leftLine;
    if (configured && isViewingToday) {
      if (calLeft > 0 && pLeft > 0) {
        leftLine = '${pLeft}g protein left · $calLeft kcal left';
      } else if (calLeft > 0) {
        leftLine = '$calLeft kcal left';
      } else if (calLeft < 0) {
        leftLine = '${-calLeft} kcal over target';
      } else if (eatenCal > 0) {
        leftLine = 'Target reached';
      }
    }

    final coachLine = _coachLine(
      configured: configured,
      isViewingToday: isViewingToday,
      eatenCal: eatenCal,
      calTarget: calTarget,
      pLeft: pLeft,
      hasMeals: (summary?.meals ?? const []).isNotEmpty,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Big Anton numeral + targets chip (baseline-aligned).
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  _formatThousands(eatenCal),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZType.disp(44, color: tc.textPrimary, height: 0.95),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _TargetsChip(
                  label: configured
                      ? 'Targets · ${_formatThousands(calTarget)} kcal'
                      : 'Set a target',
                  onTap: onEditTargets,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          // Hairline consumed/target track.
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 3,
              backgroundColor: tc.cardBorder.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(tc.textSecondary),
            ),
          ),
          const SizedBox(height: 8),
          // Semantic macro rows — protein violet / carbs cyan / fat orange.
          Row(
            children: [
              _MacroStat(
                color: AppColors.macroProtein,
                eaten: eatenP,
                target: pTarget,
                mark: 'P',
                showTarget: configured,
              ),
              const SizedBox(width: 14),
              _MacroStat(
                color: AppColors.macroCarbs,
                eaten: eatenC,
                target: cTarget,
                mark: 'C',
                showTarget: configured,
              ),
              const SizedBox(width: 14),
              _MacroStat(
                color: AppColors.macroFat,
                eaten: eatenF,
                target: fTarget,
                mark: 'F',
                showTarget: configured,
              ),
            ],
          ),
          if (leftLine != null) ...[
            const SizedBox(height: 8),
            Text(
              leftLine,
              style: ZType.lbl(10, color: tc.textMuted, letterSpacing: 0.8),
            ),
          ],
          if (coachLine != null) ...[
            const SizedBox(height: 8),
            Text(
              coachLine,
              style: ZType.ser(12.5, color: tc.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  /// The Fraunces coach whisper — a small human line keyed to the day's gap.
  /// Variant pools keep it from reading robotic (feedback_dynamic_copy).
  String? _coachLine({
    required bool configured,
    required bool isViewingToday,
    required int eatenCal,
    required int calTarget,
    required int pLeft,
    required bool hasMeals,
  }) {
    if (!isViewingToday) return null;
    if (!configured) {
      return 'Set your targets and I’ll keep your day on track.';
    }
    if (eatenCal == 0 && !hasMeals) {
      return 'Fresh page. Log your first meal when you’re ready.';
    }
    if (pLeft > 30) {
      return 'Protein’s the long pole today — lean on it next meal.';
    }
    if (calTarget > 0 && eatenCal > calTarget) {
      return 'A touch over — tomorrow’s a clean slate.';
    }
    if (pLeft <= 0) {
      return 'Protein’s handled. Nicely fuelled.';
    }
    return 'Steady fuelling. You’re on pace.';
  }

  static String _formatThousands(int n) {
    final s = n.abs().toString();
    final buf = StringBuffer(n < 0 ? '-' : '');
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

/// The "Targets · N kcal ▸" chip (`.rn-chip`) — a hairline pill that opens the
/// edit-targets sheet. Outlined, accent-free (matches the v2 frame's muted
/// chips). Disabled (no chevron, no tap) when [onTap] is null (calm mode).
class _TargetsChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _TargetsChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: tc.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: tc.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: ZType.lbl(10.5, color: tc.textSecondary, letterSpacing: 1.0),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 5),
                Icon(Icons.chevron_right_rounded,
                    size: 15, color: tc.textMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One semantic macro stat in the `.rn-mline` shape: a colored dot, an Anton
/// `eaten` numeral, a small "/target" superscript, and a Barlow P/C/F mark.
/// The dot color is macro-semantic (protein violet / carbs cyan / fat orange)
/// and is the ONLY place color is spent in the headline.
class _MacroStat extends StatelessWidget {
  final Color color;
  final int eaten;
  final int target;
  final String mark;
  final bool showTarget;

  const _MacroStat({
    required this.color,
    required this.eaten,
    required this.target,
    required this.mark,
    required this.showTarget,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$eaten',
                style: ZType.disp(16, color: tc.textPrimary, letterSpacing: 0.5),
              ),
              if (showTarget)
                TextSpan(
                  text: '/$target',
                  style: ZType.lbl(10.5,
                      color: tc.textMuted, letterSpacing: 0.5),
                ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          mark,
          style: ZType.lbl(10, color: tc.textMuted, letterSpacing: 2.0),
        ),
      ],
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
  final String userId;
  const _PendingSyncBar({required this.isDark, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(
        nutritionMetaProvider.select((s) => s.pendingMealSyncCount));
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
                  ref.read(nutritionMetaProvider.notifier).retryPendingMealWrites(userId);
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

