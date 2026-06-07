import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/nutrition.dart';
import '../../../data/models/micronutrient_catalog.dart';
import '../../../data/providers/micronutrient_visibility_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/repositories/hydration_repository.dart';
import 'nutrition_mascot.dart';
import '../../nutrition/log_meal_sheet.dart';
import '../../nutrition/widgets/micro_settings_sheet.dart';
import '../../nutrition/widgets/calories_burned_sheet.dart';
import '../../nutrition/widgets/nutrition_goals_card.dart'
    show showNutritionCalculationSheet;
import '../../nutrition/widgets/edit_targets_sheet.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/main_shell.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Hero nutrition card — Google-Fit-style swipeable carousel.
///
/// Page 1: big calorie progress ring (left) + Protein / Carbs / Fat pills
///         (right). Ring height == the 3-pill stack height.
/// Page 2: 2-column micronutrient grid — Fiber, Sugar, Sodium, Potassium,
///         Cholesterol, Calcium.
/// Page 3: Iron, Vitamin C, Vitamin A, Vitamin D, Saturated Fat, Hydration.
///
/// Dot indicators track the page. Microanimations: ring arc sweep + number
/// count-up on load, staggered pill entrance. Calorie + macro GOALS are
/// tap-to-edit inline (persisted via [NutritionPreferencesNotifier.updateTargets]).
/// Consumed macros + all micronutrients are read-only (sourced from logged
/// meals); micros use FDA Daily Values as the reference goal (there is no
/// per-user micronutrient goal backend, so they are not editable).
class HeroNutritionCard extends ConsumerStatefulWidget {
  /// [embedded] adapts the card for the Nutrition screen's scroll view (vs the
  /// Home hero area it was built for): it drops its own horizontal padding so
  /// it aligns with the meal cards, gives the carousel a fixed height instead
  /// of Expanded (so short pages don't stretch into uneven empty space), and
  /// hides the redundant "View Details" link (you're already on /nutrition).
  const HeroNutritionCard({
    super.key,
    this.embedded = false,
    this.logMealAnchorKey,
    this.isToday = true,
    this.selectedDate,
  });

  final bool embedded;

  /// Whether this card is rendering TODAY. False when the Nutrition screen shows
  /// a past date — drives the Log Meal target date + the loggable-window guard.
  final bool isToday;

  /// The date this card renders (Nutrition screen, date-nav). Null = today. When
  /// non-null the card reads `dailyNutritionProvider(nutritionKeyFor(selectedDate))`
  /// and a Log Meal lands on that date.
  final DateTime? selectedDate;

  /// First-run tour anchor. When non-null (tour pending), the primary
  /// "Log Meal" button is wrapped in this key so the coach-mark can spotlight
  /// just the button instead of the whole tab. Null outside the tour so two
  /// card instances can never both hold the same GlobalKey.
  final GlobalKey? logMealAnchorKey;

  @override
  ConsumerState<HeroNutritionCard> createState() => _HeroNutritionCardState();
}

class _HeroNutritionCardState extends ConsumerState<HeroNutritionCard>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _userId;
  late final AnimationController _animController;
  late final Animation<double> _entrance;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _entrance = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _pageController = PageController();
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// The date-key this card reads/writes. Null selectedDate = today.
  String get _dateKey => widget.selectedDate != null
      ? nutritionKeyFor(widget.selectedDate!)
      : todayNutritionKey();

  /// Whether the Log Meal button should show. Always for today; for a past date
  /// only within the backend's loggable window (today..−30 days) — beyond that
  /// the backend would silently stamp the log as "now", so we hide it instead
  /// (the past view becomes read-only).
  bool get _canLogMeal {
    if (widget.isToday || widget.selectedDate == null) return true;
    final d = widget.selectedDate!;
    final dayOnly = DateTime(d.year, d.month, d.day);
    final earliest = DateTime.now().subtract(const Duration(days: 30));
    final earliestDay =
        DateTime(earliest.year, earliest.month, earliest.day);
    return !dayOnly.isBefore(earliestDay);
  }

  Future<void> _loadData() async {
    // INSTANT-FIRST (feedback_instant_data): render the card immediately from
    // whatever the providers already hold (disk cache / a prior load) instead
    // of blocking behind a 3-way network Future.wait — that wait was what made
    // the card sit as a long gray placeholder on a cold open. The build()
    // watches these providers, so the ring + pills fill in reactively as each
    // refresh lands; no spinner gate on the slowest call.
    if (_isLoading && mounted) {
      setState(() => _isLoading = false);
    }
    // Always kick the entrance animation forward (idempotent on a completed
    // controller). The staggered macro pills read this controller for their
    // fade-in; if it never advanced past 0 they'd stay invisible — so don't
    // gate the forward() behind the _isLoading flip.
    if (!_animController.isCompleted) {
      _animController.forward();
    }

    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId == null || !mounted) return;
    _userId = userId;
    // On the Nutrition screen (embedded), the screen ITSELF owns these loads.
    // Double-fetching here raced the screen's own loadTodaySummary/initialize
    // (shared notifiers) and added redundant network calls. The card watches
    // these providers, so it already reflects the screen's data — just skip.
    if (widget.embedded) return;
    // Home: fire the refreshes without awaiting them together — each provider
    // update repaints the card on its own; the slowest never blocks the others.
    unawaited(
        ref.read(dailyNutritionProvider(_dateKey).notifier).load(userId));
    unawaited(ref.read(hydrationProvider.notifier).loadTodaySummary(userId));
    unawaited(
      ref.read(nutritionPreferencesProvider.notifier).initialize(userId),
    );
  }

  /// Persist an edited goal. [key] is one of: calories, protein, carbs, fat.
  void _commitGoal(String key, int value) {
    final userId = _userId;
    if (userId == null || value <= 0) return;
    HapticService.light();
    final notifier = ref.read(nutritionPreferencesProvider.notifier);
    switch (key) {
      case 'calories':
        notifier.updateTargets(userId: userId, targetCalories: value);
        break;
      case 'protein':
        notifier.updateTargets(userId: userId, targetProteinG: value);
        break;
      case 'carbs':
        notifier.updateTargets(userId: userId, targetCarbsG: value);
        break;
      case 'fat':
        notifier.updateTargets(userId: userId, targetFatG: value);
        break;
    }
  }

  /// Open the BMR/TDEE/goal calculation breakdown sheet (the (i) affordance).
  /// Mirrors logged_meals_section.dart: needs configured preferences; if none
  /// exist we route to the edit-targets sheet instead (so the (i) is never a
  /// dead tap on a fresh account — it becomes "set up your targets").
  void _showInfoSheet() {
    HapticService.light();
    final prefs = ref.read(nutritionPreferencesProvider).preferences;
    if (prefs == null) {
      _showEditTargetsSheet();
      return;
    }
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;
    showNutritionCalculationSheet(
      context,
      prefs: prefs,
      isDark: Theme.of(context).brightness == Brightness.dark,
      onEdit: _showEditTargetsSheet,
    );
    // showNutritionCalculationSheet uses showGlassSheet under the hood; restore
    // the nav bar when it (or the edit sheet it may push) is dismissed. The
    // edit sheet manages its own restore, so a no-op-safe set here is fine.
    ref.read(floatingNavBarVisibleProvider.notifier).state = true;
  }

  /// Open the Edit Daily Targets sheet (the pencil affordance). Wired to the
  /// same EditTargetsSheet the Nutrition screen uses; on save we re-init prefs
  /// so the ring + pills refresh live.
  void _showEditTargetsSheet() {
    HapticService.light();
    final userId = _userId;
    if (userId == null) return;
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;
    showGlassSheet(
      context: context,
      builder: (_) => GlassSheet(
        // Taller sheet (0.92 vs the 0.9 default) so the daily-targets form fits
        // with minimal scrolling now that the header + footer are pinned.
        maxHeightFraction: 0.92,
        child: EditTargetsSheet(
          userId: userId,
          // forceRefresh so a save/recalc that persisted server-side always
          // re-pulls the confirmed targets — the default initialize() is
          // blocked by the once-per-session skip-guard and would leave Home /
          // Profile showing the stale 2000/150/200/65 fallback.
          onSaved: () => ref
              .read(nutritionPreferencesProvider.notifier)
              .initialize(userId, forceRefresh: true),
        ),
      ),
    ).whenComplete(() {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final l10n = AppLocalizations.of(context);

    final nutritionState = ref.watch(dailyNutritionProvider(_dateKey));
    final summary = nutritionState.summary;
    final prefsState = ref.watch(nutritionPreferencesProvider);

    final caloriesConsumed = summary?.totalCalories ?? 0;
    // Guard the 2000 fallback (feedback_no_silent_fallbacks): when the user has
    // not configured targets, treat the target as unset (0 → empty ring) and
    // render a "Set a calorie target" CTA instead of presenting 2000 as real.
    final hasCalorieTarget = prefsState.hasConfiguredTargets;
    final calorieTarget = hasCalorieTarget
        ? prefsState.currentCalorieTarget
        : 0;
    final proteinConsumed = (summary?.totalProteinG ?? 0).round();
    final carbsConsumed = (summary?.totalCarbsG ?? 0).round();
    final fatConsumed = (summary?.totalFatG ?? 0).round();
    final proteinTarget = prefsState.currentProteinTarget;
    final carbsTarget = prefsState.currentCarbsTarget;
    final fatTarget = prefsState.currentFatTarget;
    final caloriesRemaining = calorieTarget - caloriesConsumed;

    // F4 — exercise burn folded into the budget. Only surface the net row when
    // the backend actually adjusted for burn AND there's real burn to show, so
    // a zero/stale day never adds "+0 burned" noise or whipsaws the ring.
    final caloriesBurnedToday = summary?.caloriesBurnedToday ?? 0;
    final burnAdjusted = summary?.burnAdjusted == true;
    final netCalorieRemainder = summary?.netCalorieRemainder;
    final showBurnRow =
        hasCalorieTarget &&
        burnAdjusted &&
        caloriesBurnedToday > 0 &&
        netCalorieRemainder != null;

    final proteinColor = isDark
        ? AppColors.macroProtein
        : AppColorsLight.macroProtein;
    final carbsColor = isDark
        ? AppColors.macroCarbs
        : AppColorsLight.macroCarbs;
    final fatColor = isDark ? AppColors.macroFat : AppColorsLight.macroFat;
    final buttonBg = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final buttonFg = isDark ? Colors.black : Colors.white;

    final calorieProgress = calorieTarget > 0
        ? (caloriesConsumed / calorieTarget).clamp(0.0, 1.3)
        : 0.0;

    // Aggregate micronutrients from the day's logged meals (summary-level
    // model has no micro totals, but each FoodLog carries them).
    final micros = _MicroTotals.fromMeals(summary?.meals ?? const []);

    // Customizable micronutrient tiles (home-deck style): which tiles show + in
    // what order comes from [microVisibilityProvider]; presentation + FDA goals
    // from [kMicroCatalog]; the per-day VALUE from `micros`. Chunked into pages
    // of 6 so each carousel page is a clean 3×2 grid.
    final visibleMicroIds = ref.watch(microVisibilityProvider);
    final microSpecs = <_MicroSpec>[
      for (final id in visibleMicroIds)
        if (microEntryById(id) != null)
          _specForMicro(microEntryById(id)!, micros),
    ];
    final microPages = <List<_MicroSpec>>[];
    for (var i = 0; i < microSpecs.length; i += 6) {
      microPages.add(
        microSpecs.sublist(
          i,
          i + 6 > microSpecs.length ? microSpecs.length : i + 6,
        ),
      );
    }
    final pageCount = 1 + microPages.length; // page 0 = macros
    // If the visible-micro set shrank below the parked page (user hid tiles in
    // the customize sheet), snap the controller back onto a page that still
    // exists next frame so the PageView never sits on a dead index.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      final last = pageCount - 1;
      if ((_pageController.page ?? 0).round() > last) {
        _pageController.jumpToPage(last);
      }
    });

    return Padding(
      // Embedded: no horizontal padding (the Nutrition screen's list already
      // pads), so the card width matches the meal cards below it.
      padding: widget.embedded
          ? const EdgeInsets.only(bottom: 8)
          : const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.08,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: _isLoading
              ? const SizedBox(
                  height: 220,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Column(
                  // Embedded lives in an unbounded scroll view, so the column
                  // must hug its content (it has no Expanded then). Home gives
                  // it a bounded height, where max + Expanded fills the area.
                  mainAxisSize: widget.embedded
                      ? MainAxisSize.min
                      : MainAxisSize.max,
                  children: [
                    // Embedded header chrome — subtle (i) info + pencil edit
                    // affordances in the top-right (ported from the old
                    // logged_meals_section header). The Home hero keeps its own
                    // surrounding chrome, so these only appear when embedded.
                    if (widget.embedded)
                      SizedBox(
                        height: 28,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: _showInfoSheet,
                              icon: Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: textSecondary,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 28,
                              ),
                              tooltip: 'How your targets are calculated',
                            ),
                            IconButton(
                              onPressed: _showEditTargetsSheet,
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: textSecondary,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 28,
                              ),
                              tooltip: 'Edit targets',
                            ),
                          ],
                        ),
                      ),

                    // (Removed the training/rest-day "bolt" adjustment badge —
                    // user feedback: it read as a cryptic icon. Dynamic-target
                    // context still lives in the (i) info sheet.)

                    // ===== swipeable carousel =====
                    // Home: Expanded fills the flexible hero area. Embedded:
                    // a fixed height sized to the tallest page (the calorie
                    // ring), so short micro pages don't stretch into uneven
                    // empty space inside a scroll view.
                    _carousel(
                      embedded: widget.embedded,
                      // Page 1's real height includes the F4 net-burn row when
                      // it shows — pass the inputs so the carousel can size to
                      // the genuinely-tallest page (issue: 0.425px clip).
                      showBurnRow: showBurnRow,
                      calorieTarget: calorieTarget,
                      caloriesConsumed: caloriesConsumed,
                      caloriesBurned: caloriesBurnedToday,
                      netRemaining: netCalorieRemainder ?? 0,
                      // Isolate the carousel's paint: the ring/pill entrance
                      // animations + page swipes repaint frequently, and a
                      // RepaintBoundary keeps that off the rest of the Home feed
                      // (perf pass, issue #14).
                      child: RepaintBoundary(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (_) => HapticService.selection(),
                          children: [
                            // Page 1 — calorie ring + macro pills
                            _MacrosPage(
                              entrance: _entrance,
                              accent: accent,
                              isDark: isDark,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              caloriesRemaining: caloriesRemaining,
                              calorieTarget: calorieTarget,
                              caloriesConsumed: caloriesConsumed,
                              hasCalorieTarget: hasCalorieTarget,
                              calorieProgress: calorieProgress,
                              showBurnRow: showBurnRow,
                              caloriesBurnedToday: caloriesBurnedToday,
                              netCalorieRemainder: netCalorieRemainder ?? 0,
                              onTapBurned: () {
                                HapticService.light();
                                showCaloriesBurnedSheet(
                                  context,
                                  caloriesBurnedToday.toDouble(),
                                );
                              },
                              proteinConsumed: proteinConsumed,
                              carbsConsumed: carbsConsumed,
                              fatConsumed: fatConsumed,
                              proteinTarget: proteinTarget,
                              carbsTarget: carbsTarget,
                              fatTarget: fatTarget,
                              proteinColor: proteinColor,
                              carbsColor: carbsColor,
                              fatColor: fatColor,
                              onEditCalorieGoal: (v) =>
                                  _commitGoal('calories', v),
                              onEditProteinGoal: (v) =>
                                  _commitGoal('protein', v),
                              onEditCarbsGoal: (v) => _commitGoal('carbs', v),
                              onEditFatGoal: (v) => _commitGoal('fat', v),
                            ),
                            // Micronutrient pages — user-customizable (which tiles
                            // show + order live in microVisibilityProvider, edited
                            // via the tune gear beside the dots). Each page is a
                            // 3×2 grid of up to 6 tiles.
                            for (final tiles in microPages)
                              _MicroGridPage(
                                entrance: _entrance,
                                isDark: isDark,
                                tiles: tiles,
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    // Dot indicators + customize gear. The dots stay optically
                    // centered (Stack) while the tune gear pins to the right —
                    // mirrors the home metric deck's footer affordance.
                    SizedBox(
                      height: 22,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (pageCount > 1)
                            SmoothPageIndicator(
                              controller: _pageController,
                              count: pageCount,
                              effect: ExpandingDotsEffect(
                                dotHeight: 7,
                                dotWidth: 7,
                                expansionFactor: 3,
                                spacing: 6,
                                activeDotColor: accent,
                                dotColor: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.18),
                              ),
                            ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Semantics(
                              button: true,
                              label: 'Customize nutrients',
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  HapticService.light();
                                  showMicroSettingsSheet(context, ref);
                                },
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color:
                                        (isDark ? Colors.white : Colors.black)
                                            .withValues(alpha: 0.06),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.tune_rounded,
                                    size: 14,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // LOG MEAL button. Wrapped in the first-run tour anchor
                    // (when provided) so the nutrition coach-mark spotlights
                    // just this button rather than the whole tab. Hidden on a
                    // past date beyond the backend's 30-day loggable window so we
                    // never silently mislog to "now" (the view is read-only then).
                    if (_canLogMeal)
                    KeyedSubtree(
                      key: widget.logMealAnchorKey,
                      child: SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticService.medium();
                            // Past date → the log lands on that date; today →
                            // null selectedDate → server-now.
                            showLogMealSheet(context, ref,
                                selectedDate: widget.selectedDate);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonBg,
                            foregroundColor: buttonFg,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.restaurant_outlined, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                l10n.heroNutritionCardLogMeal,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // View Details — hidden when embedded (it navigates to
                    // /nutrition, which is where the embedded card already is).
                    if (!widget.embedded)
                      GestureDetector(
                        onTap: () {
                          HapticService.light();
                          context.go('/nutrition');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.insights_outlined,
                                size: 13,
                                color: textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.heroWorkoutCardViewDetails,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Carousel sizing: flexible (Expanded) on Home, fixed height when embedded
  /// in the Nutrition screen's scroll view so pages don't stretch unevenly.
  ///
  /// Both candidate page heights are computed per-layout (never hard-coded) so
  /// the carousel adapts to ANY screen width + text scale:
  ///   • the 2-col micro grid scales with width (childAspectRatio 3.55), and
  ///   • page 1 grows by the F4 net-burn row, whose wrapping `Wrap` adds lines
  ///     on narrow screens / large text.
  /// A hard-coded `page1Height = 120` ignored the net-burn row, so on widths
  /// where the grid landed a sub-pixel shorter than the real page-1 stack, page
  /// 1 overflowed by a fraction of a pixel ("BOTTOM OVERFLOWED BY 0.425px").
  /// Pages top-align, so any candidate being the taller one just parks the
  /// shorter pages' slack harmlessly below their content.
  Widget _carousel({
    required bool embedded,
    required Widget child,
    required bool showBurnRow,
    required int calorieTarget,
    required int caloriesConsumed,
    required int caloriesBurned,
    required int netRemaining,
  }) {
    if (!embedded) return Expanded(child: child);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        // _MicroGridPage: crossAxisCount 2, crossAxisSpacing 8,
        // childAspectRatio 3.55 → tile height = ((w - 8) / 2) / 3.55.
        final tileH = ((w - 8) / 2) / 3.55;
        // 3 rows + 2 × 8px mainAxisSpacing.
        final gridHeight = tileH * 3 + 16;
        final page1Height = _page1Height(
          context,
          width: w,
          showBurnRow: showBurnRow,
          calorieTarget: calorieTarget,
          caloriesConsumed: caloriesConsumed,
          caloriesBurned: caloriesBurned,
          netRemaining: netRemaining,
        );
        final h = math.max(page1Height, gridHeight);
        return SizedBox(height: h, child: child);
      },
    );
  }

  /// Real rendered height of carousel page 1 at [width] — the calorie ring /
  /// macro-pill stack (a fixed 120: 3 × 36 pill + 2 × 6 gap == the ring square)
  /// plus, when [showBurnRow] is set, the F4 `_NetRemainingRow`. That row is a
  /// centered [Wrap] of chips, so its line count (and therefore height) depends
  /// on the available width and the user's text scale. We measure each chip and
  /// greedily pack them exactly the way [Wrap] does, so the result matches the
  /// real layout on every device instead of a brittle constant.
  static double _page1Height(
    BuildContext context, {
    required double width,
    required bool showBurnRow,
    required int calorieTarget,
    required int caloriesConsumed,
    required int caloriesBurned,
    required int netRemaining,
  }) {
    const double ringStack = 120;
    if (!showBurnRow) return ringStack;

    final scaler = MediaQuery.textScalerOf(context);
    final over = netRemaining < 0;
    final netLabel = over
        ? 'Net ${netRemaining.abs()} over'
        : 'Net $netRemaining left';

    // (text, fontSize, weight) for every chip, mirroring `_NetRemainingRow`.
    const detail = 10.5;
    final chips = <(String, double, FontWeight)>[
      (netLabel, 12, FontWeight.w800),
      ('·', detail, FontWeight.w600),
      ('Goal $calorieTarget', detail, FontWeight.w600),
      ('− $caloriesConsumed eaten', detail, FontWeight.w600),
      ('+ $caloriesBurned burned', detail, FontWeight.w700),
    ];

    double lineHeight = 0;
    final widths = <double>[];
    for (final (text, size, weight) in chips) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: size, fontWeight: weight),
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      widths.add(tp.width);
      if (tp.height > lineHeight) lineHeight = tp.height;
    }
    // The burned chip is an icon (12) + 2px gap + its text.
    widths[widths.length - 1] += 12 + 2;
    if (lineHeight < 12) lineHeight = 12; // icon never shorter than its glyph

    // CRITICAL: TextPainter reports the TIGHT glyph box (ascent + descent ≈
    // fontSize × 1.17), but when Flutter actually lays the chips out in the
    // Wrap it adds the font's STRUT LEADING on top of that — so the real
    // rendered line box is taller than `tp.height` by the leading (≈ 15-20% of
    // the font size, and it varies by platform: Android's Roboto strut is the
    // tallest). Sizing the carousel to the un-led tight height left page 1 a
    // sub-pixel-to-~2px shorter than its real content, which is the
    // "BOTTOM OVERFLOWED BY 0.425 pixels" stripe. Add a per-line leading factor
    // (it scales with line count, so a flat constant would be wrong on a
    // 2-line wrap) so the prediction is a guaranteed UPPER bound on the real
    // line box. Extra slack parks harmlessly below the top-aligned page.
    const leadingFactor = 1.25;
    lineHeight = lineHeight * leadingFactor;

    // Wrap spacing 6 (horizontal) / runSpacing 2 (vertical); the row Container
    // pads 10 each side, so chips wrap inside `width − 20`.
    const spacing = 6.0;
    const runSpacing = 2.0;
    final avail = width - 20;
    var lines = 1;
    var lineWidth = 0.0;
    for (final cw in widths) {
      if (lineWidth == 0) {
        lineWidth = cw; // first chip on a line always fits (or overflows alone)
      } else if (lineWidth + spacing + cw <= avail) {
        lineWidth += spacing + cw;
      } else {
        lines++;
        lineWidth = cw;
      }
    }

    const vPad = 14.0; // 7 top + 7 bottom
    const gap = 8.0; // SizedBox between the pill row and the net row
    final netRowHeight = vPad + lineHeight * lines + runSpacing * (lines - 1);
    // Ceil to the whole logical pixel so the carousel box can never land a
    // fraction below the real (device-pixel-rounded) page height.
    return (ringStack + gap + netRowHeight).ceilToDouble();
  }

  // --- micronutrient tile builders (catalog-driven, user-customizable) -------
  // Presentation + FDA goal come from [kMicroCatalog]; the per-day VALUE is read
  // from the aggregated [_MicroTotals] by stable id. (Hydration is no longer a
  // carousel tile — it has a dedicated tracker on the Daily tab.)
  _MicroSpec _specForMicro(MicroCatalogEntry e, _MicroTotals m) => _MicroSpec(
    e.name,
    _microValue(e.id, m),
    e.goal,
    e.unit,
    e.emoji,
    e.color,
    e.fixed,
  );

  double _microValue(String id, _MicroTotals m) {
    switch (id) {
      case 'fiber':
        return m.fiberG;
      case 'sugar':
        return m.sugarG;
      case 'sodium':
        return m.sodiumMg;
      case 'potassium':
        return m.potassiumMg;
      case 'cholesterol':
        return m.cholesterolMg;
      case 'calcium':
        return m.calciumMg;
      case 'iron':
        return m.ironMg;
      case 'vitamin_c':
        return m.vitaminCMg;
      case 'vitamin_a':
        return m.vitaminAUg;
      case 'vitamin_d':
        return m.vitaminDIu;
      case 'sat_fat':
        return m.saturatedFatG;
      case 'magnesium':
        return m.magnesiumMg;
      case 'zinc':
        return m.zincMg;
      case 'vitamin_b12':
        return m.vitaminB12Ug;
      case 'folate':
        return m.vitaminB9Ug;
      case 'vitamin_e':
        return m.vitaminEMg;
      case 'omega_3':
        return m.omega3G;
      case 'vitamin_k':
        return m.vitaminKUg;
      case 'vitamin_b6':
        return m.vitaminB6Mg;
      case 'phosphorus':
        return m.phosphorusMg;
      case 'selenium':
        return m.seleniumUg;
      case 'copper':
        return m.copperMg;
      case 'manganese':
        return m.manganeseMg;
      default:
        return 0;
    }
  }
}

// ============================================================================
// PAGE 1 — calorie ring + macro pills
// ============================================================================
class _MacrosPage extends StatelessWidget {
  final Animation<double> entrance;
  final Color accent;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final int caloriesRemaining;
  final int calorieTarget;
  final int caloriesConsumed;
  final bool hasCalorieTarget;
  final double calorieProgress;
  // F4 — exercise burn breakdown (Goal − Eaten + Burned = Net). Only rendered
  // when [showBurnRow] is true (burn data present + backend-adjusted).
  final bool showBurnRow;
  final int caloriesBurnedToday;
  final int netCalorieRemainder;
  final VoidCallback onTapBurned;
  final int proteinConsumed, carbsConsumed, fatConsumed;
  final int proteinTarget, carbsTarget, fatTarget;
  final Color proteinColor, carbsColor, fatColor;
  final ValueChanged<int> onEditCalorieGoal;
  final ValueChanged<int> onEditProteinGoal;
  final ValueChanged<int> onEditCarbsGoal;
  final ValueChanged<int> onEditFatGoal;

  const _MacrosPage({
    required this.entrance,
    required this.accent,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.caloriesRemaining,
    required this.calorieTarget,
    required this.caloriesConsumed,
    required this.hasCalorieTarget,
    required this.calorieProgress,
    required this.showBurnRow,
    required this.caloriesBurnedToday,
    required this.netCalorieRemainder,
    required this.onTapBurned,
    required this.proteinConsumed,
    required this.carbsConsumed,
    required this.fatConsumed,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
    required this.proteinColor,
    required this.carbsColor,
    required this.fatColor,
    required this.onEditCalorieGoal,
    required this.onEditProteinGoal,
    required this.onEditCarbsGoal,
    required this.onEditFatGoal,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final over = caloriesRemaining < 0;
    // The carousel sizes every page to the TALLEST page (the 2-col micro grid,
    // taller than the old fixed 120px ring+pill stack). Rather than top-align
    // the short macro content and leave empty space below (the height mismatch
    // the user flagged), STRETCH the ring + pills to fill that height so page 1
    // visually matches the micronutrient grid pages.
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Calorie ring — a square that fills the page height so it stays
              // balanced with the macro pills, which now stretch to fill the same
              // height as the (taller) micronutrient grid page. Previously a fixed
              // 120×120 box left page 1 visibly shorter than the grid pages.
              AspectRatio(
                aspectRatio: 1,
                child: AnimatedBuilder(
                  animation: entrance,
                  builder: (context, _) {
                    final t = entrance.value;
                    final shown = (caloriesRemaining * t).round();
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: Size.infinite,
                          painter: _CalorieRingPainter(
                            progress: calorieProgress * t,
                            color: over ? AppColors.error : accent,
                            trackColor: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.08),
                          ),
                        ),
                        if (!hasCalorieTarget)
                          // No target configured → CTA, never the 2000 fallback.
                          // (The edit affordance is the pencil in the card header.)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  size: 18,
                                  color: accent,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Set a calorie\ntarget',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          // FittedBox guards against vertical overflow on short
                          // devices now that the mascot sits above the number
                          // inside the (compact) ring.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Finn the shark, centered inside the ring above
                              // "kcal left". Particles off at this small size.
                              NutritionMascot(
                                progress: calorieProgress,
                                size: 54,
                                showParticles: false,
                                justAteTick:
                                    (calorieTarget - caloriesRemaining).round(),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.heroNutritionCardCalLeft.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  over ? '+${shown.abs()}' : '$shown',
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    height: 1.0,
                                    color: over ? AppColors.error : textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              _EditableGoal(
                                value: calorieTarget,
                                prefix: 'of ',
                                suffix: '',
                                onCommit: onEditCalorieGoal,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Macro pills — each stretches to fill the page height so the 3-pill
              // stack matches the micronutrient grid page (8px gaps mirror the
              // grid's mainAxisSpacing). No more short page-1 with empty space.
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: _MacroPill(
                        entrance: entrance,
                        order: 0,
                        emoji: '🍖',
                        label: l10n.weeklyCheckinSheetProtein,
                        consumed: proteinConsumed,
                        goal: proteinTarget,
                        color: proteinColor,
                        isDark: isDark,
                        onEditGoal: onEditProteinGoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _MacroPill(
                        entrance: entrance,
                        order: 1,
                        emoji: '🍞',
                        label: l10n.weeklyCheckinSheetCarbs,
                        consumed: carbsConsumed,
                        goal: carbsTarget,
                        color: carbsColor,
                        isDark: isDark,
                        onEditGoal: onEditCarbsGoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _MacroPill(
                        entrance: entrance,
                        order: 2,
                        emoji: '🧈',
                        label: l10n.weeklyCheckinSheetFat,
                        consumed: fatConsumed,
                        goal: fatTarget,
                        color: fatColor,
                        isDark: isDark,
                        onEditGoal: onEditFatGoal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // F4 — net-remaining breakdown. Hidden entirely unless real burn data is
        // present (showBurnRow). Factual copy, no "you can eat X more!" gamified
        // framing (ED-safety). Tapping the burned figure opens the existing
        // calories-burned breakdown sheet.
        if (showBurnRow) ...[
          const SizedBox(height: 8),
          _NetRemainingRow(
            calorieTarget: calorieTarget,
            caloriesConsumed: caloriesConsumed,
            caloriesBurned: caloriesBurnedToday,
            netRemaining: netCalorieRemainder,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            accent: accent,
            onTapBurned: onTapBurned,
          ),
        ],
      ],
    );
  }
}

/// F4 — a single compact line: "Net N left  ·  Goal G − Eaten E + Burned B".
/// The burned figure is tappable (opens the calories-burned sheet). All copy
/// is factual; no gamified "you can eat more" framing.
class _NetRemainingRow extends StatelessWidget {
  final int calorieTarget;
  final int caloriesConsumed;
  final int caloriesBurned;
  final int netRemaining;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final VoidCallback onTapBurned;

  const _NetRemainingRow({
    required this.calorieTarget,
    required this.caloriesConsumed,
    required this.caloriesBurned,
    required this.netRemaining,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.onTapBurned,
  });

  @override
  Widget build(BuildContext context) {
    final over = netRemaining < 0;
    final netLabel = over
        ? 'Net ${netRemaining.abs()} over'
        : 'Net $netRemaining left';
    final detailStyle = TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      color: textSecondary,
    );
    return Semantics(
      label:
          '$netLabel. Goal $calorieTarget calories minus $caloriesConsumed eaten '
          'plus $caloriesBurned burned. Tap burned to see the breakdown.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 2,
          children: [
            Text(
              netLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: over ? AppColors.error : textPrimary,
              ),
            ),
            Text('·', style: detailStyle),
            Text('Goal $calorieTarget', style: detailStyle),
            Text('− $caloriesConsumed eaten', style: detailStyle),
            // Burned segment is the only tappable part — opens the sheet.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTapBurned,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_outlined,
                    size: 12,
                    color: accent,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '+ $caloriesBurned burned',
                    style: detailStyle.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: accent.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A macro pill: colored chip (emoji) + label + "consumed / editable-goal".
class _MacroPill extends StatelessWidget {
  final Animation<double> entrance;
  final int order;
  final String emoji;
  final String label;
  final int consumed;
  final int goal;
  final Color color;
  final bool isDark;
  final ValueChanged<int> onEditGoal;

  const _MacroPill({
    required this.entrance,
    required this.order,
    required this.emoji,
    required this.label,
    required this.consumed,
    required this.goal,
    required this.color,
    required this.isDark,
    required this.onEditGoal,
  });

  @override
  Widget build(BuildContext context) {
    final tile = color.withValues(alpha: isDark ? 0.16 : 0.10);
    final chipBg = color.withValues(alpha: isDark ? 0.28 : 0.18);
    final labelColor = (isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary);

    // The pill body, built once. No fixed height — the pill stretches to fill
    // the Expanded slot the macro page gives it, so the 3-pill stack matches
    // the micronutrient grid page height.
    final body = Container(
      decoration: BoxDecoration(
        color: tile,
        // Match the micronutrient tiles (page 2/3): 16px radius + 42px emoji
        // chip so all three carousel pages read as one consistent card.
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 9),
          // Compact inline layout: LABEL · consumed / goal on one row so
          // the pill is 34px tall (issue 2) instead of the old 2-line 42px.
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: labelColor,
                  ),
                ),
                const Spacer(),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: consumed),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Text(
                    '$v',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      color: color,
                    ),
                  ),
                ),
                _EditableGoal(
                  value: goal,
                  prefix: ' / ',
                  suffix: 'g',
                  onCommit: onEditGoal,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    ); // end `final body = Container(...)`

    // Drive the staggered entrance via AnimatedBuilder so the pill fades in as
    // the controller animates AND stays visible once it settles. Previously the
    // build read `entrance.value` once without listening, so a build that ran
    // before the animation started left the pill stuck at opacity 0 forever —
    // only a later external rebuild (e.g. the tour overlay) revealed it. That
    // was the "macro pills only show during the tooltip" bug (plan #6).
    return AnimatedBuilder(
      animation: entrance,
      child: body,
      builder: (context, child) {
        final start = 0.25 + order * 0.08;
        final local = ((entrance.value - start) / (1 - start)).clamp(0.0, 1.0);
        return Opacity(
          opacity: local,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - local)),
            child: child,
          ),
        );
      },
    );
  }
}

// ============================================================================
// PAGE 2/3 — micronutrient grid
// ============================================================================
class _MicroSpec {
  final String name;
  final double value;
  final double goal;
  final String unit;
  final String emoji;
  final Color color;
  final int fixed; // decimal places for display
  const _MicroSpec(
    this.name,
    this.value,
    this.goal,
    this.unit,
    this.emoji,
    this.color,
    this.fixed,
  );
}

class _MicroGridPage extends StatelessWidget {
  final Animation<double> entrance;
  final bool isDark;
  final List<_MicroSpec> tiles;

  const _MicroGridPage({
    required this.entrance,
    required this.isDark,
    required this.tiles,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 3.55,
      children: [
        for (int i = 0; i < tiles.length; i++)
          _MicroTile(
            spec: tiles[i],
            entrance: entrance,
            order: i,
            isDark: isDark,
          ),
      ],
    );
  }
}

class _MicroTile extends StatelessWidget {
  final _MicroSpec spec;
  final Animation<double> entrance;
  final int order;
  final bool isDark;

  const _MicroTile({
    required this.spec,
    required this.entrance,
    required this.order,
    required this.isDark,
  });

  String _fmt(double v) =>
      spec.fixed > 0 ? v.toStringAsFixed(spec.fixed) : _grouped(v.round());

  static String _grouped(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final c = spec.color;
    final tile = c.withValues(alpha: isDark ? 0.16 : 0.10);
    final chipBg = c.withValues(alpha: isDark ? 0.28 : 0.18);
    final labelColor = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;

    final start = (0.2 + order * 0.06).clamp(0.0, 0.9);
    final local = ((entrance.value - start) / (1 - start)).clamp(0.0, 1.0);

    return Opacity(
      opacity: local,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - local)),
        child: Container(
          decoration: BoxDecoration(
            color: tile,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
                child: Text(spec.emoji, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: spec.value),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (context, v, _) => Text(
                              _fmt(v),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                                color: c,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          ' / ${_fmt(spec.goal)}${spec.unit}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: labelColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Inline tap-to-edit goal (matches the home-screen inline-editing pattern)
// ============================================================================
class _EditableGoal extends StatefulWidget {
  final int value;
  final String prefix;
  final String suffix;
  final TextStyle style;
  final ValueChanged<int> onCommit;

  const _EditableGoal({
    required this.value,
    required this.prefix,
    required this.suffix,
    required this.style,
    required this.onCommit,
  });

  @override
  State<_EditableGoal> createState() => _EditableGoalState();
}

class _EditableGoalState extends State<_EditableGoal> {
  bool _editing = false;
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) _commit();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _start() {
    HapticService.selection();
    _controller.text = widget.value.toString();
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  void _commit() {
    final parsed = int.tryParse(_controller.text.trim());
    setState(() => _editing = false);
    if (parsed != null && parsed > 0 && parsed != widget.value) {
      widget.onCommit(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AccentColorScope.of(
      context,
    ).getColor(Theme.of(context).brightness == Brightness.dark);
    if (_editing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(widget.prefix, style: widget.style),
          IntrinsicWidth(
            child: Container(
              constraints: const BoxConstraints(minWidth: 22),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                onSubmitted: (_) => _commit(),
                style: widget.style.copyWith(color: accent),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 2),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Text(widget.suffix, style: widget.style),
        ],
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _start,
      child: Text(
        '${widget.prefix}${widget.value}${widget.suffix}',
        style: widget.style,
      ),
    );
  }
}

// ============================================================================
// Calorie ring painter (single arc + track)
// ============================================================================
class _CalorieRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _CalorieRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = size.width * 0.085;
    final radius = (size.width / 2) - stroke / 2;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final clamped = progress.clamp(0.0, 1.0);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, 2 * math.pi * clamped, false, paint);

    // Overshoot wrap when over goal.
    if (progress > 1.0) {
      final over = (progress - 1.0).clamp(0.0, 1.0);
      final overPaint = Paint()
        ..color = Color.lerp(color, Colors.white, 0.35)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, 2 * math.pi * over, false, overPaint);
    }
  }

  @override
  bool shouldRepaint(_CalorieRingPainter old) =>
      old.progress != progress || old.color != color;
}

// ============================================================================
// Micronutrient aggregation from the day's FoodLog list
// ============================================================================
class _MicroTotals {
  final double fiberG, sugarG, sodiumMg, potassiumMg, cholesterolMg, calciumMg;
  final double ironMg, vitaminCMg, vitaminAUg, vitaminDIu, saturatedFatG;
  // Extended micronutrients (mirrors the food_logs columns now surfaced by the
  // daily-summary serialization).
  final double vitaminEMg, vitaminKUg, vitaminB6Mg, vitaminB12Ug, vitaminB9Ug;
  final double magnesiumMg, zincMg, phosphorusMg, seleniumUg, copperMg;
  final double manganeseMg, omega3G;

  const _MicroTotals({
    required this.fiberG,
    required this.sugarG,
    required this.sodiumMg,
    required this.potassiumMg,
    required this.cholesterolMg,
    required this.calciumMg,
    required this.ironMg,
    required this.vitaminCMg,
    required this.vitaminAUg,
    required this.vitaminDIu,
    required this.saturatedFatG,
    required this.vitaminEMg,
    required this.vitaminKUg,
    required this.vitaminB6Mg,
    required this.vitaminB12Ug,
    required this.vitaminB9Ug,
    required this.magnesiumMg,
    required this.zincMg,
    required this.phosphorusMg,
    required this.seleniumUg,
    required this.copperMg,
    required this.manganeseMg,
    required this.omega3G,
  });

  factory _MicroTotals.fromMeals(List<FoodLog> meals) {
    double fiber = 0,
        sugar = 0,
        sodium = 0,
        potassium = 0,
        chol = 0,
        calcium = 0;
    double iron = 0, vitC = 0, vitA = 0, vitD = 0, satFat = 0;
    double vitE = 0, vitK = 0, b6 = 0, b12 = 0, b9 = 0;
    double mag = 0,
        zinc = 0,
        phos = 0,
        sel = 0,
        copper = 0,
        mang = 0,
        omega3 = 0;
    for (final m in meals) {
      fiber += m.fiberG ?? 0;
      sugar += m.sugarG ?? 0;
      sodium += m.sodiumMg ?? 0;
      potassium += m.potassiumMg ?? 0;
      chol += m.cholesterolMg ?? 0;
      calcium += m.calciumMg ?? 0;
      iron += m.ironMg ?? 0;
      vitC += m.vitaminCMg ?? 0;
      vitA += m.vitaminAUg ?? 0;
      vitD += m.vitaminDIu ?? 0;
      satFat += m.saturatedFatG ?? 0;
      vitE += m.vitaminEMg ?? 0;
      vitK += m.vitaminKUg ?? 0;
      b6 += m.vitaminB6Mg ?? 0;
      b12 += m.vitaminB12Ug ?? 0;
      b9 += m.vitaminB9Ug ?? 0;
      mag += m.magnesiumMg ?? 0;
      zinc += m.zincMg ?? 0;
      phos += m.phosphorusMg ?? 0;
      sel += m.seleniumUg ?? 0;
      copper += m.copperMg ?? 0;
      mang += m.manganeseMg ?? 0;
      omega3 += m.omega3G ?? 0;
    }
    return _MicroTotals(
      fiberG: fiber,
      sugarG: sugar,
      sodiumMg: sodium,
      potassiumMg: potassium,
      cholesterolMg: chol,
      calciumMg: calcium,
      ironMg: iron,
      vitaminCMg: vitC,
      vitaminAUg: vitA,
      vitaminDIu: vitD,
      saturatedFatG: satFat,
      vitaminEMg: vitE,
      vitaminKUg: vitK,
      vitaminB6Mg: b6,
      vitaminB12Ug: b12,
      vitaminB9Ug: b9,
      magnesiumMg: mag,
      zincMg: zinc,
      phosphorusMg: phos,
      seleniumUg: sel,
      copperMg: copper,
      manganeseMg: mang,
      omega3G: omega3,
    );
  }
}
