import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/rating_prompt_service.dart';
import '../../widgets/rating_prompt_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/nutrition.dart';
import '../../data/models/micronutrients.dart';
import '../../data/models/recipe.dart';
import '../../data/providers/nutrition_preferences_provider.dart';
import '../../data/providers/recipe_save_jobs_provider.dart';
import '../../data/providers/schedule_save_jobs_provider.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/data_cache_service.dart';
import '../../data/services/haptic_service.dart';
import '../../data/providers/xp_provider.dart';
import '../../widgets/glass_sheet.dart';
import 'widgets/glass_nutrition_tab_bar.dart';
import '../../widgets/tooltips/tooltips.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/pill_swipe_navigation.dart';
import 'log_meal_sheet.dart';
import 'food_history_screen.dart';
import 'nutrition_settings_screen.dart';
import 'recipe_builder_sheet.dart';
import 'weekly_checkin_sheet.dart';
import 'widgets/daily_tab.dart';
import 'widgets/edit_targets_sheet.dart';
import 'widgets/schedule_meal_sheet.dart';
import 'widgets/share_meal_sheet.dart';
import 'widgets/nutrition_error_state.dart';
import 'widgets/my_foods_sheet.dart';
import 'widgets/nutrition_date_strip.dart';
import 'widgets/share_nutrition_sheet.dart';
import '../../shareables/shareable_sheet.dart';
import '../../shareables/adapters/nutrition_adapter.dart';
import 'widgets/fuel_tab.dart';
// `my_foods_sheet.dart` happens to export an internal helper called RecipesTab
// for the saved-foods grid; alias our real Recipes tab to disambiguate.
import 'widgets/recipes_tab.dart' as recipes_tab show RecipesTab;
import 'widgets/nutrition_patterns_tab.dart';
import 'widgets/post_meal_review_sheet.dart';
import '../../core/services/posthog_service.dart';
import '../../data/repositories/hydration_repository.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  /// Optional meal type to auto-open the log meal sheet (from deep link).
  final String? initialMeal;

  /// Optional initial tab index (0=Daily, 1=Recipes, 2=Patterns, 3=Fuel).
  final int initialTab;

  /// When true, auto-opens the log meal sheet and launches the camera.
  final bool autoOpenCamera;

  /// When true, auto-opens the log meal sheet and launches the barcode scanner.
  final bool autoOpenBarcode;

  /// When non-null, the 45-min check-in reminder push tapped into the app and
  /// we should re-open the post-meal review sheet bound to this food_log_id.
  final String? openCheckinLogId;

  /// Optional initial inner section of the Fuel tab ('nutrients' or 'water').
  /// Used by the hydration-reminder deep-link so tapping a water banner lands
  /// on the Water pill, not the default Nutrients landing.
  final String? initialFuelSection;

  const NutritionScreen({
    super.key,
    this.initialMeal,
    this.initialTab = 0,
    this.autoOpenCamera = false,
    this.autoOpenBarcode = false,
    this.openCheckinLogId,
    this.initialFuelSection,
  });

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen>
    with SingleTickerProviderStateMixin, PillSwipeNavigationMixin {
  // PillSwipeNavigationMixin: Nutrition is index 2
  @override
  int get currentPillIndex => 2;

  // In-memory cache for micronutrient data — survives widget rebuilds
  static DailyMicronutrientSummary? _cachedMicronutrients;
  static String? _cachedMicronutrientsKey; // "userId:date"
  static DateTime? _cachedMicronutrientsTime;
  static const _micronutrientCacheTtl = Duration(minutes: 5);

  // In-memory cache for recipes — survives widget rebuilds
  static List<RecipeSummary>? _cachedRecipes;
  static DateTime? _cachedRecipesTime;
  static const _recipeCacheTtl = Duration(minutes: 5);

  String? _userId;
  DateTime _selectedDate = DateTime.now();
  late TabController _tabController;
  DailyMicronutrientSummary? _micronutrientSummary;
  List<RecipeSummary> _recipes = [];
  bool _isLoadingMicronutrients = false;
  bool _hasCheckedWeeklyCheckin = false;  // Guard flag for weekly check-in prompt

  /// True only while the one-time `nutrition_v1` first-run tour still needs
  /// to run (its `has_seen_` flag is unset). The three tooltip-anchor
  /// `GlobalKey`s (`TooltipAnchors.nutrition*`) are app-global statics, so
  /// attaching them unconditionally crashed with "Duplicate GlobalKey" when
  /// two NutritionScreen instances briefly coexisted (shell keep-alive + a
  /// pushed route). Gate the keys — and the tour overlay — on this flag so
  /// after first run (the vast majority of the app's life) no key exists.
  bool _nutritionTourActive = false;

  /// Sparse set of `yyyy-MM-dd` (local) keys for days with at least one
  /// food log. Drives the dot indicator under each day cell in the date
  /// strip. Refreshed on init + after every successful log.
  Set<String> _loggedDateKeys = const <String>{};

  @override
  void initState() {
    super.initState();
    // Tabs: Daily | Recipes | Patterns | Fuel (merged Nutrients + Water)
    //
    // Animation tuning for iOS-feel slide:
    //   • 260ms — slightly snappier than Flutter's 300ms default. iOS UIKit
    //     uses ~350ms but with a heavier easeOut curve; 260ms with
    //     `Curves.ease` lands at the same perceived crispness.
    //   • All four tabs use AutomaticKeepAliveClientMixin so intermediate
    //     tabs are pre-built — the slide is silky because there's no
    //     widget construction happening mid-animation (which was the
    //     actual cause of the perceived lag earlier).
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab,
      animationDuration: const Duration(milliseconds: 260),
    );
    // Hydrate disk-cached micros + recipes BEFORE kicking the network so
    // the first paint shows real data instead of empty / skeleton. The
    // network refresh that follows is stale-while-revalidate.
    _hydrateFromDisk();
    _loadData();
    _resolveNutritionTourActive();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'nutrition_screen_viewed');
    });
    // Collapse nav bar labels on this secondary page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navBarLabelsExpandedProvider.notifier).state = false;
      // Listen for preferences to become available, then check for weekly check-in
      _setupWeeklyCheckinListener();
      // Auto-refresh Vitamins & Minerals when a meal is logged/edited.
      _setupMicronutrientInvalidationListener();
      // Surface a SnackBar when the one-time targets-recalc migration ran
      // (rate→deficit table was wrong; existing users need a fresh re-derive).
      _setupTargetsMigrationBannerListener();
      // Auto-open log meal sheet if deep-linked with a meal type, camera, or barcode flag
      if (widget.initialMeal != null || widget.autoOpenCamera || widget.autoOpenBarcode) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        _showLogMealSheet(isDark, mealType: widget.initialMeal, autoOpenCamera: widget.autoOpenCamera, autoOpenBarcode: widget.autoOpenBarcode);
      }
      // 45-min reminder tap: re-open the post-meal check-in sheet bound to the log.
      if (widget.openCheckinLogId != null && widget.openCheckinLogId!.isNotEmpty) {
        _reopenCheckinFromReminder(widget.openCheckinLogId!);
      }
    });
  }

  /// Resolve whether the first-run `nutrition_v1` tour still needs to run.
  /// Only then are the tooltip-anchor GlobalKeys attached (see
  /// [_nutritionTourActive]). Once seen, this stays false forever.
  Future<void> _resolveNutritionTourActive() async {
    final sp = await SharedPreferences.getInstance();
    final seen =
        sp.getBool('has_seen_empty_tour_${TooltipIds.nutrition}') ?? false;
    if (!mounted || seen) return;
    setState(() => _nutritionTourActive = true);
  }

  /// Wrap [child] in the tour anchor [key] ONLY while the first-run tour is
  /// pending. Outside first run the key is omitted entirely, so two
  /// NutritionScreen instances can never both hold the same global key.
  Widget _tourAnchor(GlobalKey key, Widget child) =>
      _nutritionTourActive ? KeyedSubtree(key: key, child: child) : child;

  /// Set up listener to trigger weekly check-in when preferences are loaded
  void _setupWeeklyCheckinListener() {
    ref.listenManual(nutritionPreferencesProvider, (previous, next) {
      if (!_hasCheckedWeeklyCheckin &&
          next.preferences != null &&
          (previous?.preferences == null || previous!.isLoading)) {
        _hasCheckedWeeklyCheckin = true;
        _checkAndShowWeeklyCheckin();
      }
    }, fireImmediately: true);
  }

  /// Show a one-time SnackBar when the v2 targets-recalc migration moved
  /// the user's daily calorie target by ≥25 kcal. The provider sets
  /// `pendingMigrationDelta` after the silent recalc; we clear it after
  /// surfacing so it doesn't re-fire on tab switches / hot reloads.
  void _setupTargetsMigrationBannerListener() {
    ref.listenManual(nutritionPreferencesProvider, (previous, next) {
      final delta = next.pendingMigrationDelta;
      if (delta == null) return;
      // Avoid firing twice when the listener pumps the same state object.
      if (previous?.pendingMigrationDelta == delta) return;
      if (!mounted) return;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final teal = isDark ? AppColors.teal : AppColorsLight.teal;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          backgroundColor: teal,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Updated your daily target: ${delta.newCalories} cal/day '
            '(was ${delta.oldCalories}). We fixed how we calculate the deficit '
            'from your weekly rate.',
          ),
          action: SnackBarAction(
            label: 'Review',
            textColor: Colors.white,
            onPressed: () {
              if (!mounted) return;
              // Match the canonical glass-sheet pattern used by
              // daily_tab.dart's `_showEditTargetsSheet`. Previously this
              // entry-point used a raw `showModalBottomSheet` with a solid
              // grey container — no blur, no drag handle, and the floating
              // nav bar rendered on top because `useRootNavigator` defaulted
              // to false. `showGlassSheet` handles both the glassmorphism
              // and root-navigator placement.
              ref.read(floatingNavBarVisibleProvider.notifier).state = false;
              showGlassSheet(
                context: context,
                builder: (_) => GlassSheet(
                  child: EditTargetsSheet(
                    userId: _userId ?? '',
                    onSaved: () {},
                  ),
                ),
              ).whenComplete(() {
                if (mounted) {
                  ref.read(floatingNavBarVisibleProvider.notifier).state = true;
                }
              });
            },
          ),
        ),
      );
      ref
          .read(nutritionPreferencesProvider.notifier)
          .consumePendingMigrationDelta();
    }, fireImmediately: true);
  }

  /// Re-fetch pinned nutrients whenever the day's meal set changes so the
  /// Vitamins & Minerals card updates immediately after a log. Previously
  /// the 5-min TTL on the in-memory micronutrient cache kept showing the
  /// pre-log values until the user navigated away and back.
  void _setupMicronutrientInvalidationListener() {
    ref.listenManual<NutritionState>(nutritionProvider, (prev, next) {
      if (_userId == null) return;
      final prevCount = prev?.todaySummary?.meals.length ?? 0;
      final nextCount = next.todaySummary?.meals.length ?? 0;
      final prevKcal = prev?.todaySummary?.totalCalories ?? 0;
      final nextKcal = next.todaySummary?.totalCalories ?? 0;
      // Trigger on either a new meal row OR a macro delta on an existing
      // meal (edits from the history sheet land on the same date). Bail
      // if we're not viewing today — the cache only covers today anyway.
      if ((nextCount != prevCount || nextKcal != prevKcal) && _isToday) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
        _cachedMicronutrientsTime = null; // force network call
        _loadMicronutrients(_userId!, dateStr);
      }
    });
  }

  @override
  void didUpdateWidget(NutritionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-navigation from Home (Food Log / Water habit cards, deep links)
    // produces a new NutritionScreen widget with the requested tab while
    // the State is preserved by StatefulShellRoute's IndexedStack. Sync the
    // TabController so the user actually lands on the requested tab.
    final target = widget.initialTab;
    if (target >= 0 && target < _tabController.length && _tabController.index != target) {
      _tabController.animateTo(target);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Re-opens the post-meal check-in sheet bound to a specific food_log,
  /// fired from the 45-min reminder notification tap. We look up the log on
  /// the fly so the sheet has the correct food names / calories / log id.
  Future<void> _reopenCheckinFromReminder(String foodLogId) async {
    final userId = _userId ?? await ref.read(apiClientProvider).getUserId();
    if (!mounted || userId == null) return;
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      final logs = await repo.getFoodLogs(userId, limit: 50);
      final match = logs.firstWhere(
        (l) => l.id == foodLogId,
        orElse: () => logs.first,
      );
      if (!mounted) return;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      showPostMealReviewSheet(
        context,
        foodNames: match.foodItems.map((e) => e.name).take(4).toList(),
        totalCalories: match.totalCalories,
        isDark: isDark,
        userId: userId,
        foodLogId: foodLogId,
      );
    } catch (e) {
      debugPrint('⚠️ [Nutrition] reopen from reminder failed: $e');
    }
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId != null && mounted) {
      setState(() => _userId = userId);

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // When forcing (Try Again / pull-to-refresh), invalidate the local
      // micronutrient cache too so the bypassed network call actually fires.
      if (forceRefresh) {
        _cachedMicronutrientsTime = null;
      }

      _loadRecipes(userId, forceRefresh: forceRefresh);
      // Honor the currently-viewed date. Without this branch, retry / pull-
      // to-refresh while on a past date would clobber `state.recentLogs`
      // with today's data and the past-date view would briefly show today's
      // meals under a past-date header.
      if (_isToday) {
        ref.read(nutritionProvider.notifier).loadTodaySummary(userId, forceRefresh: forceRefresh);
        ref.read(nutritionProvider.notifier).loadRecentLogs(userId, forceRefresh: forceRefresh);
      } else {
        ref.read(nutritionProvider.notifier).loadSummaryForDate(userId, _selectedDate);
        ref.read(nutritionProvider.notifier).loadLogsForDate(userId, _selectedDate);
      }
      _loadMicronutrients(userId, dateStr);
      ref.read(nutritionPreferencesProvider.notifier).initialize(userId);
      ref.read(hydrationProvider.notifier).loadTodaySummary(userId);
      _refreshLoggedDateKeys(userId);
    }
  }

  /// Refresh the strip's dot indicators by reducing recent food logs into a
  /// set of local-date keys. Fire-and-forget — failures are logged and the
  /// strip simply renders without dots.
  Future<void> _refreshLoggedDateKeys(String userId) async {
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      final keys = await repo.getLoggedDateKeys(userId, days: 90);
      if (mounted) {
        setState(() => _loggedDateKeys = keys);
      }
    } catch (e) {
      debugPrint('Failed to refresh logged-date keys: $e');
    }
  }

  /// Snap to today + reload after a successful log. The meal always lands
  /// on today (server-now timestamp), so showing the user any other date
  /// would mislead them about where their entry actually lives.
  void _refreshAfterLog() {
    _cachedMicronutrientsTime = null;
    if (!_isToday) {
      _jumpToDate(DateTime.now()); // jumps + loads selected date
    } else {
      _loadData();
    }
    if (_userId != null) {
      _refreshLoggedDateKeys(_userId!);
    }
    // Bump rating-prompt counter — meal logs are a "happy moment"
    // (snap a menu, get macros, done). Service surfaces the sheet only
    // after the threshold + install-age + cooldown all pass, so this
    // call is safe to fire on every log.
    _maybeShowRatingAfterLog();
  }

  Future<void> _maybeShowRatingAfterLog() async {
    try {
      final svc = ref.read(ratingPromptServiceProvider);
      await svc.recordMealLogged();
      if (!mounted) return;
      if (await svc.shouldPrompt()) {
        if (!mounted) return;
        await showRatingPromptSheet(context, ref);
      }
    } catch (e) {
      debugPrint('[NutritionScreen] Rating prompt skipped: $e');
    }
  }

  Future<void> _checkAndShowWeeklyCheckin() async {
    if (!mounted || _userId == null) return;

    final prefsState = ref.read(nutritionPreferencesProvider);
    final prefs = prefsState.preferences;

    if (prefs == null) {
      debugPrint('[NutritionScreen] Skipping weekly check-in - prefs not ready');
      return;
    }

    if (prefs.isWeeklyCheckinDue) {
      if (prefs.weeklyCheckinDismissCount >= 3) {
        debugPrint('[NutritionScreen] Weekly check-in due but user dismissed ${prefs.weeklyCheckinDismissCount} times, skipping auto-show');
        return;
      }

      // Defer if the first-run nutrition tour hasn't been seen yet —
      // otherwise the bottom-sheet barrier scrims the spotlight tooltip
      // and the two overlays collide. The tour auto-marks itself seen
      // after a 1s impression, so the next visit gets the check-in.
      final sp = await SharedPreferences.getInstance();
      final tourSeen =
          sp.getBool('has_seen_empty_tour_${TooltipIds.nutrition}') ?? false;
      if (!tourSeen) {
        debugPrint('[NutritionScreen] Deferring weekly check-in — nutrition tour not yet seen');
        return;
      }

      debugPrint('[NutritionScreen] Weekly check-in is due! Last check-in: ${prefs.lastWeeklyCheckinAt}, Days since: ${prefs.daysSinceLastCheckin}');

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        showWeeklyCheckinSheet(context, ref);
      }
    } else {
      debugPrint('[NutritionScreen] Weekly check-in not due. Enabled: ${prefs.weeklyCheckinEnabled}, Days since: ${prefs.daysSinceLastCheckin}');
    }
  }

  // SharedPreferences-backed cache keys (TTL handled inside DataCacheService).
  // Per-date for micros (rolls over at midnight), global for recipes (recent
  // list rarely changes).
  static const String _diskRecipesKey = 'cache_nutrition_recent_recipes';
  String _diskMicrosKey(String userId, String date) =>
      'cache_nutrition_micros_${userId}_$date';

  /// Pre-hydrate state from on-disk cache so the first frame paints real
  /// data instead of an empty Daily/Fuel tab. Fire-and-forget — the
  /// concurrent `_loadData` network call refreshes whatever lands here.
  Future<void> _hydrateFromDisk() async {
    try {
      final cache = DataCacheService.instance;

      // Recipes — used by Recipes tab + Daily tab quick suggestions.
      final cachedRecipes = await cache.getCachedList(_diskRecipesKey);
      if (cachedRecipes != null && cachedRecipes.isNotEmpty && mounted) {
        final recipes = cachedRecipes
            .map((j) => RecipeSummary.fromJson(j))
            .toList(growable: false);
        _cachedRecipes = recipes;
        _cachedRecipesTime = DateTime.now();
        setState(() => _recipes = recipes);
      }

      // Micros — needs userId, which we may not have yet. The userId
      // resolves immediately from cached auth state on most paths, so
      // try it; if absent we just skip and let the network call fill
      // in (still no spinner since the Daily tab handles null gracefully).
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId == null) return;
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final cachedMicros = await cache.getCached(_diskMicrosKey(userId, dateStr));
      if (cachedMicros != null && mounted) {
        final summary = DailyMicronutrientSummary.fromJson(cachedMicros);
        _cachedMicronutrients = summary;
        _cachedMicronutrientsKey = '$userId:$dateStr';
        _cachedMicronutrientsTime = DateTime.now();
        setState(() => _micronutrientSummary = summary);
      }
    } catch (e) {
      debugPrint('⚠️ [Nutrition] disk hydrate failed: $e');
    }
  }

  Future<void> _loadMicronutrients(String userId, String date) async {
    final cacheKey = '$userId:$date';

    // Serve in-memory cached data instantly if available and fresh
    if (_cachedMicronutrientsKey == cacheKey &&
        _cachedMicronutrients != null &&
        _cachedMicronutrientsTime != null &&
        DateTime.now().difference(_cachedMicronutrientsTime!) < _micronutrientCacheTtl) {
      setState(() {
        _micronutrientSummary = _cachedMicronutrients;
        _isLoadingMicronutrients = false;
      });
      return;
    }

    // Show stale cache while fetching (if same key) so the UI never blanks.
    if (_cachedMicronutrientsKey == cacheKey && _cachedMicronutrients != null) {
      _micronutrientSummary = _cachedMicronutrients;
    }

    setState(() => _isLoadingMicronutrients = true);
    try {
      final repository = ref.read(nutritionRepositoryProvider);
      final summary = await repository.getDailyMicronutrients(
        userId: userId,
        date: date,
      );
      // Update in-memory + persistent caches.
      _cachedMicronutrients = summary;
      _cachedMicronutrientsKey = cacheKey;
      _cachedMicronutrientsTime = DateTime.now();
      unawaited(DataCacheService.instance
          .cache(_diskMicrosKey(userId, date), summary.toJson()));
      if (mounted) {
        setState(() {
          _micronutrientSummary = summary;
          _isLoadingMicronutrients = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading micronutrients: $e');
      if (mounted) {
        setState(() => _isLoadingMicronutrients = false);
      }
    }
  }

  Future<void> _loadRecipes(String userId, {bool forceRefresh = false}) async {
    // Use in-memory cache if fresh enough
    if (!forceRefresh &&
        _cachedRecipes != null &&
        _cachedRecipesTime != null &&
        DateTime.now().difference(_cachedRecipesTime!) < _recipeCacheTtl) {
      if (mounted && _recipes.isEmpty) {
        setState(() => _recipes = _cachedRecipes!);
      }
      return;
    }
    try {
      final repository = ref.read(nutritionRepositoryProvider);
      final response = await repository.getRecipes(
        userId: userId,
        limit: 10,
        sortBy: 'most_logged',
      );
      if (mounted) {
        setState(() => _recipes = response.items);
        _cachedRecipes = response.items;
        _cachedRecipesTime = DateTime.now();
        unawaited(DataCacheService.instance.cacheList(
          _diskRecipesKey,
          response.items.map((r) => r.toJson()).toList(),
        ));
      }
    } catch (e) {
      debugPrint('Error loading recipes: $e');
    }
  }

  /// Jump to a specific calendar date (invoked by the date picker / strip).
  void _jumpToDate(DateTime target) {
    final normalized = DateTime(target.year, target.month, target.day);
    final prevDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final newDateStr = DateFormat('yyyy-MM-dd').format(normalized);
    if (prevDateStr == newDateStr) return;
    setState(() {
      _selectedDate = normalized;
      _micronutrientSummary = null;
    });
    _loadDataForSelectedDate();
  }

  void _loadDataForSelectedDate() {
    if (_userId == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final notifier = ref.read(nutritionProvider.notifier);
    // Always route through the date-specific variants. loadTodaySummary /
    // loadRecentLogs have their own fast-path when the target IS today, so
    // branching here only risks the stale-cache bug (loadSummaryForDate
    // leaves yesterday in state.todaySummary; loadTodaySummary then
    // short-circuits and never refetches).
    if (_isToday) {
      notifier.loadTodaySummary(_userId!);
      notifier.loadRecentLogs(_userId!);
    } else {
      notifier.loadSummaryForDate(_userId!, _selectedDate);
      notifier.loadLogsForDate(_userId!, _selectedDate);
    }
    _loadMicronutrients(_userId!, dateStr);
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String get _dateLabel {
    if (_isToday) return 'Today';
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (_selectedDate.year == yesterday.year &&
        _selectedDate.month == yesterday.month &&
        _selectedDate.day == yesterday.day) {
      return 'Yesterday';
    }
    return DateFormat('MMM d').format(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nutritionProvider);
    final prefsState = ref.watch(nutritionPreferencesProvider);
    final calmMode = prefsState.preferences?.calmModeEnabled ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accentColor = ref.colors(context).accent;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(children: [SafeArea(
        child: wrapWithSwipeDetector(
        child: Column(
          children: [
            // Floating Header Row — actions only (date controls now live in
            // the date strip below).
            _buildHeaderRow(context, isDark, glassSurface, textPrimary, textMuted, textSecondary, elevated),
            // Horizontally-scrolling date strip. Replaces the chevron+pill
            // navigator and adds a meal-logged dot under each day for at-
            // a-glance density.
            _tourAnchor(
              TooltipAnchors.nutritionDateNav,
              NutritionDateStrip(
                selectedDate: _selectedDate,
                loggedDateKeys: _loggedDateKeys,
                onDaySelected: _jumpToDate,
              ),
            ),
            // Tab Bar moved to a floating glassmorphic pill bar docked just
            // above the bottom nav (see Positioned widget below). Keeping
            // this slot empty preserves the column rhythm while the actual
            // selector lives where the user's thumb naturally rests.

          // Tab Content.
          //
          // First-load UX: never block the entire tab with a full-screen
          // skeleton. DailyTab handles null summary gracefully (zeroed
          // macros, empty meal list, log-a-meal CTA visible) so the user
          // gets a usable interface in <16ms instead of staring at a
          // skeleton for a network round-trip. Stale-while-revalidate in
          // loadTodaySummary then fills in real data when the network
          // returns. The full-screen error state is kept ONLY for the
          // truly broken case (network failed AND we have no cached data
          // to fall back on); transient refresh failures on top of stale
          // data are silently swallowed by the notifier.
          Expanded(
            child: (state.error != null && state.todaySummary == null)
                ? NutritionErrorState(
                        error: state.error!,
                        // Always force a refresh when the user explicitly
                        // taps Try Again — otherwise the 5-minute summary
                        // cache short-circuits the call and the user is
                        // stuck on the error screen.
                        onRetry: () => _loadData(forceRefresh: true),
                        isDark: isDark,
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // Daily Tab — anchor for step 1 of `nutrition_v1`
                          // (Log a meal). The tab as a whole is haloed so
                          // the spotlight follows whichever meal row is on
                          // screen.
                          _tourAnchor(
                            TooltipAnchors.nutritionLogMeal,
                            DailyTab(
                            userId: _userId ?? '',
                            tourActive: _nutritionTourActive,
                            summary: state.todaySummary,
                            targets: state.targets,
                            micronutrients: _micronutrientSummary,
                            isViewingToday: _isToday,
                            onRefresh: _loadData,
                            onLogMeal: (mealType) => _showLogMealSheet(isDark, mealType: mealType),
                            onDeleteMeal: (id) => _deleteMeal(id),
                            onCopyMeal: (id, mealType) => _copyMeal(id, mealType),
                            onMoveMeal: (id, mealType) => _moveMeal(id, mealType),
                            onCopyItem: (logId, idx, mealType) => _copyItemAsStandalone(logId, idx, mealType),
                            onMoveItem: (logId, idx, mealType) => _moveItemAsStandalone(logId, idx, mealType),
                            onUpdateMeal: (logId, cal, p, c, f, {double? weightG, List<Map<String, dynamic>>? foodItems, List<FoodItemEdit>? itemEdits}) =>
                                _updateMeal(logId, cal, p, c, f, weightG: weightG, foodItems: foodItems, itemEdits: itemEdits),
                            onUpdateMealTime: (logId, newTime) => _updateMealTime(logId, newTime),
                            onUpdateMealNotes: (logId, notes) => _updateMealNotes(logId, notes),
                            onUpdateMealMood: (logId, {String? moodBefore, String? moodAfter, int? energyLevel}) => _updateMealMood(logId, moodBefore: moodBefore, moodAfter: moodAfter, energyLevel: energyLevel),
                            onSaveFoodToFavorites: (meal) => _saveFoodToFavorites(meal),
                            onSaveMealAsRecipe: (meal, {int? itemIndex, bool createCookEvent = false}) =>
                                _saveMealAsRecipe(meal, itemIndex: itemIndex, createCookEvent: createCookEvent),
                            onScheduleMeal: (meal, {SchedulePreset initialPreset = SchedulePreset.tomorrowOnly, int? itemIndex}) =>
                                _scheduleMealFromLog(meal, initialPreset: initialPreset, itemIndex: itemIndex),
                            onAddToShoppingList: (meal, {int? itemIndex}) =>
                                _addMealToShoppingList(meal, itemIndex: itemIndex),
                            onShareMeal: (meal) => _shareMeal(meal),
                            onFetchItemEdits: _fetchItemEdits,
                            apiClient: ref.read(apiClientProvider),
                            // Fuel tab (index 3) now hosts both Nutrients and Water pill toggles
                            onSwitchToNutrientsTab: () => _tabController.animateTo(3),
                            onSwitchToHydrationTab: () => _tabController.animateTo(3),
                            isDark: isDark,
                            calmMode: calmMode,
                            ),
                          ),

                          // Recipes Tab — full feature (search, build, import, fridge,
                          // schedule, planner, grocery, sharing, versioning, leftovers)
                          recipes_tab.RecipesTab(userId: _userId ?? '', isDark: isDark),

                          // Patterns Tab (macros, top foods, mood patterns, history)
                          NutritionPatternsTab(
                            userId: _userId ?? '',
                            isDark: isDark,
                          ),

                          // Fuel Tab — merged Nutrients + Water with pill toggles
                          FuelTab(
                            userId: _userId ?? '',
                            micronutrients: _micronutrientSummary,
                            isLoading: _isLoadingMicronutrients,
                            onRefreshMicronutrients: () {
                              if (_userId != null) {
                                final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                                _loadMicronutrients(_userId!, dateStr);
                              }
                            },
                            isDark: isDark,
                            initialSection: widget.initialFuelSection,
                          ),
                        ],
                      ),
          ),
          ],
        ),
      ),
      ),
      // Floating glassmorphic tab selector. Docked above MainShell's
      // bottom nav so the four sub-screens are reachable from the thumb
      // zone instead of the screen top. The Stack is bounded by the
      // Scaffold so MediaQuery.viewPadding.bottom gives the safe-area
      // inset; MainShell's nav adds another ~80px on top of that.
      Positioned(
        left: 0,
        right: 0,
        // Sit a small gap above the floating MainShell nav bar. The nav pill
        // (52px tall) sits at viewPadding.bottom + 10, so its top edge is at
        // viewPadding.bottom + 62 — +68 leaves a tidy 6px gap.
        bottom: MediaQuery.of(context).viewPadding.bottom + 68,
        child: Center(
          child: GlassNutritionTabBar(
            controller: _tabController,
            accentColor: accentColor,
            items: const [
              NutritionTabItem(label: 'Daily', icon: Icons.restaurant_menu_rounded),
              NutritionTabItem(label: 'Recipes', icon: Icons.menu_book_rounded),
              NutritionTabItem(label: 'Patterns', icon: Icons.insights_outlined),
              NutritionTabItem(label: 'Fuel', icon: Icons.bolt_outlined),
            ],
          ),
        ),
      ),
      // First-run spotlight tour. Anchors + copy live in
      // `widgets/tooltips/tours/nutrition_tour.dart`. Mounted only while the
      // tour is pending — same gate as its anchor keys (see _tourAnchor).
      if (_nutritionTourActive) NutritionTour.overlay(),
      ]),
      floatingActionButton: null,
    );
  }

  Widget _buildHeaderRow(BuildContext context, bool isDark, Color glassSurface, Color textPrimary, Color textMuted, Color textSecondary, Color elevated) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Title — date controls moved to the NutritionDateStrip below this
          // row. Showing the current date label here keeps the header
          // grounded with vertical-rhythm context. Tapping the label when
          // viewing a non-today date snaps the selection back to today.
          Expanded(
            child: Semantics(
              button: !_isToday,
              label: _isToday ? _dateLabel : 'Jump to today',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _isToday
                    ? null
                    : () {
                        HapticService.light();
                        _jumpToDate(DateTime.now());
                      },
                child: Text(
                  _dateLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          // History
          GestureDetector(
            onTap: () {
              if (_userId != null) {
                Navigator.push(
                  context,
                  AppPageRoute(
                    builder: (_) => FoodHistoryScreen(userId: _userId!),
                  ),
                );
              }
            },
            child: Tooltip(
              message: 'History',
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: glassSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.history, size: 18, color: isDark ? AppColors.teal : AppColorsLight.teal),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // My Foods (Saved Foods + Recipes). Anchor for step 3 of
          // `nutrition_v1`.
          _tourAnchor(
            TooltipAnchors.nutritionMyFoods,
            GestureDetector(
            onTap: () => _showMyFoodsSheet(isDark),
            child: Tooltip(
              message: 'My Foods',
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: glassSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.bookmark_outline, size: 18, color: AppColors.yellow),
              ),
            ),
            ),
          ),
          const SizedBox(width: 6),
          // Share
          GestureDetector(
            onTap: () async {
              // Route through the unified ShareableSheet (item 13). Pulls a
              // fresh daily report from the backend so the share gallery
              // renders with calorie / macro / inflammation / AI summary.
              try {
                final api = ref.read(apiClientProvider);
                final res = await api.dio.post('/nutrition/reports/daily');
                if (!context.mounted) return;
                final shareable = NutritionAdapter.fromDailyReport(
                  ref: ref,
                  json: res.data as Map<String, dynamic>,
                );
                if (shareable == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Log some meals first to share')),
                  );
                  return;
                }
                await ShareableSheet.show(context, data: shareable);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Share failed: $e')),
                  );
                }
              }
            },
            child: Tooltip(
              message: 'Share',
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: glassSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.share_outlined, size: 18, color: textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Stats
          GestureDetector(
            onTap: () => context.push('/stats?tab=4'),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: glassSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.bar_chart_rounded, size: 18, color: textSecondary),
            ),
          ),
          const SizedBox(width: 6),
          // Settings
          GestureDetector(
            onTap: () {
              // Root navigator so the settings screen overlays the whole
              // MainShell (including its floating bottom nav pill) — this
              // page is a full-screen destination, not a tab-peer.
              Navigator.of(context, rootNavigator: true).push(
                AppPageRoute(
                  builder: (_) => const NutritionSettingsScreen(),
                ),
              );
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: glassSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.settings_outlined, size: 18, color: textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogMealSheet(bool isDark, {String? mealType, bool autoOpenCamera = false, bool autoOpenBarcode = false}) async {
    await showLogMealSheet(context, ref, initialMealType: mealType, autoOpenCamera: autoOpenCamera, autoOpenBarcode: autoOpenBarcode, selectedDate: _selectedDate);
    _refreshAfterLog();
  }

  void _showRecipeBuilder(BuildContext context, bool isDark) {
    if (_userId == null || _userId!.isEmpty) {
      debugPrint('Cannot show RecipeBuilderSheet: userId is null or empty');
      return;
    }

    ref.read(floatingNavBarVisibleProvider.notifier).state = false;

    // Use whenComplete (always runs, including on error) instead of .then
    // (only runs on success). Otherwise a thrown future leaves the nav bar
    // hidden forever — same disappearing-bar class fixed in weekly_checkin.
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: RecipeBuilderSheet(userId: _userId!, isDark: isDark),
      ),
    ).whenComplete(() {
      try {
        ref.read(floatingNavBarVisibleProvider.notifier).state = true;
      } catch (_) {/* container disposed mid-dismiss */}
      _loadRecipes(_userId!);
    });
  }

  void _showMyFoodsSheet(bool isDark) {
    if (_userId == null || _userId!.isEmpty) return;

    ref.read(floatingNavBarVisibleProvider.notifier).state = false;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        showHandle: false,
        child: MyFoodsSheet(
          userId: _userId!,
          repository: ref.read(nutritionRepositoryProvider),
          recipes: _recipes,
          isDark: isDark,
          onFoodLogged: () {
            _refreshAfterLog();
          },
          getSuggestedMealType: _getSuggestedMealType,
          onCreateRecipe: () {
            Navigator.of(context).pop();
            _showRecipeBuilder(context, isDark);
          },
          onLogRecipe: (recipe) {
            Navigator.of(context).pop();
            _logRecipe(recipe, isDark);
          },
          onRefreshRecipes: () => _loadRecipes(_userId!),
          // L5 — Saved menus discoverable from the Nutrition tab.
          onOpenSavedMenus: () => context.push('/menu-history'),
        ),
      ),
    ).whenComplete(() {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    });
  }

  String _getSuggestedMealType() {
    final hour = DateTime.now().hour;
    if (hour < 10) return 'breakfast';
    if (hour < 14) return 'lunch';
    if (hour < 17) return 'snack';
    return 'dinner';
  }

  Future<void> _logRecipe(RecipeSummary recipe, bool isDark) async {
    if (_userId == null) return;

    final mealType = await _selectMealType(context, isDark);
    if (mealType == null) return;

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      final result = await repository.logRecipe(
        userId: _userId!,
        recipeId: recipe.id,
        mealType: mealType.value,
      );
      if (mounted) {
        ref.read(xpProvider.notifier).markMealLogged();
        // Splice optimistic FoodLog so the recipe appears instantly
        final now = DateTime.now();
        ref.read(nutritionProvider.notifier).spliceRawLog(
          FoodLog(
            id: result.foodLogId,
            userId: _userId!,
            mealType: mealType.value,
            loggedAt: now,
            foodItems: [FoodItem(name: result.recipeName, calories: result.totalCalories)],
            totalCalories: result.totalCalories,
            proteinG: result.proteinG,
            carbsG: result.carbsG,
            fatG: result.fatG,
            fiberG: result.fiberG,
            sourceType: 'recipe',
            userQuery: result.recipeName,
            createdAt: now,
          ),
          _userId!,
        );
        _refreshAfterLog();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged ${recipe.name}'),
            backgroundColor: isDark ? AppColors.success : AppColorsLight.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log recipe: $e')),
        );
      }
    }
  }

  Future<MealType?> _selectMealType(BuildContext context, bool isDark) async {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return showGlassSheet<MealType>(
      context: context,
      builder: (context) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log as...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...MealType.values.map((type) => ListTile(
                    leading: Text(type.emoji, style: const TextStyle(fontSize: 24)),
                    title: Text(
                      type.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    onTap: () => Navigator.pop(context, type),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMeal(String mealId) async {
    if (_userId == null) return;
    final notifier = ref.read(nutritionProvider.notifier);

    // Optimistically remove from state so the UI updates instantly.
    final removed = notifier.optimisticRemoveLog(mealId);
    if (removed == null) {
      // Not in today's summary — fall back to the legacy synchronous flow
      // (food_history_screen, etc.). Network delay is acceptable there
      // because those screens already show their own list-level spinner.
      _cachedMicronutrientsTime = null;
      await notifier.deleteLog(_userId!, mealId);
      ref.read(posthogServiceProvider).capture(
        eventName: 'food_log_deleted',
        properties: <String, Object>{'food_log_id': mealId},
      );
      return;
    }

    _cachedMicronutrientsTime = null; // Invalidate cache — nutrients changed

    // Show undoable snackbar. We intentionally don't `await` the network
    // delete inside this method — the row is already gone from the UI;
    // the commit fires after the undo window if the user doesn't press it.
    final messenger = ScaffoldMessenger.of(context);
    bool undone = false;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Meal deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            undone = true;
            notifier.restoreLog(removed);
          },
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // After the undo window, commit the network delete (or skip if undone).
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (undone || !mounted) return;
      ref.read(posthogServiceProvider).capture(
        eventName: 'food_log_deleted',
        properties: <String, Object>{'food_log_id': mealId},
      );
      // Errors restore the meal locally and surface via state.error.
      unawaited(notifier.commitDeleteLog(_userId!, mealId, removed));
    });
  }

  Future<void> _copyMeal(String mealId, String targetMealType) async {
    if (_userId == null) return;
    try {
      ref.read(posthogServiceProvider).capture(
        eventName: 'food_log_copied',
        properties: <String, Object>{'food_log_id': mealId, 'target_meal_type': targetMealType},
      );
      final notifier = ref.read(nutritionProvider.notifier);
      final repository = ref.read(nutritionRepositoryProvider);
      final response = await repository.copyFoodLog(logId: mealId, mealType: targetMealType);
      _cachedMicronutrientsTime = null;
      // Splice the new log locally so the UI updates without a refreshAll
      // round-trip. Backend response carries new_id + meal_type only; we
      // clone the source FoodLog with those overrides + a fresh logged_at
      // (server uses now() per copy_food_log endpoint).
      final meals = ref.read(nutritionProvider).todaySummary?.meals ?? const <FoodLog>[];
      final srcIdx = meals.indexWhere((m) => m.id == mealId);
      final newId = response['new_id'] as String?;
      if (srcIdx >= 0 && newId != null) {
        final returnedType = (response['meal_type'] as String?) ?? targetMealType;
        final json = meals[srcIdx].toJson()
          ..['id'] = newId
          ..['meal_type'] = returnedType
          ..['logged_at'] = DateTime.now().toUtc().toIso8601String();
        notifier.spliceRawLog(FoodLog.fromJson(json), _userId!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied to ${targetMealType[0].toUpperCase()}${targetMealType.substring(1)}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error copying meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Couldn’t copy meal: ${_friendlyApiError(e)}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Promote one food inside a multi-item meal into its own standalone log
  /// under `targetMealType`. Leaves the source meal untouched.
  ///
  /// Implemented client-side on top of existing endpoints:
  ///   1. POST `/nutrition/log-direct` with a single-item `food_items` array
  ///      derived from the source item. Source meal's `ai_feedback` is NOT
  ///      forwarded (it describes the whole parent meal, not this item).
  ///   2. Refresh the daily summary so both meal sections update.
  Future<void> _copyItemAsStandalone(String sourceLogId, int itemIdx, String targetMealType) async {
    if (_userId == null) return;
    try {
      final state = ref.read(nutritionProvider);
      final source = state.todaySummary?.meals.firstWhere(
        (m) => m.id == sourceLogId,
        orElse: () => throw Exception('Source meal not found'),
      );
      if (source == null || itemIdx < 0 || itemIdx >= source.foodItems.length) return;
      final item = source.foodItems[itemIdx];

      final itemJson = item.toJson();
      final repo = ref.read(nutritionRepositoryProvider);
      await repo.logAdjustedFood(
        userId: _userId!,
        mealType: targetMealType,
        foodItems: <Map<String, dynamic>>[itemJson],
        totalCalories: item.calories ?? 0,
        totalProtein: (item.proteinG ?? 0).round(),
        totalCarbs: (item.carbsG ?? 0).round(),
        totalFat: (item.fatG ?? 0).round(),
        sourceType: source.sourceType ?? 'text',
        // Keep the originating user-query so the standalone row has a sensible
        // title. Don't forward the image — it describes the source meal, not
        // this single item.
        userQuery: item.name,
      );
      _cachedMicronutrientsTime = null;
      await ref.read(nutritionProvider.notifier).refreshAll(_userId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied ${item.name} to ${targetMealType[0].toUpperCase()}${targetMealType.substring(1)}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error copying item as standalone: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Couldn’t copy item: ${_friendlyApiError(e)}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Move = copy into target + remove from source (delete source if it was
  /// the last item, else update source with the remaining items).
  Future<void> _moveItemAsStandalone(String sourceLogId, int itemIdx, String targetMealType) async {
    if (_userId == null) return;
    try {
      final state = ref.read(nutritionProvider);
      final source = state.todaySummary?.meals.firstWhere(
        (m) => m.id == sourceLogId,
        orElse: () => throw Exception('Source meal not found'),
      );
      if (source == null || itemIdx < 0 || itemIdx >= source.foodItems.length) return;
      final item = source.foodItems[itemIdx];

      final repo = ref.read(nutritionRepositoryProvider);

      // 1. Copy into target meal type.
      await repo.logAdjustedFood(
        userId: _userId!,
        mealType: targetMealType,
        foodItems: <Map<String, dynamic>>[item.toJson()],
        totalCalories: item.calories ?? 0,
        totalProtein: (item.proteinG ?? 0).round(),
        totalCarbs: (item.carbsG ?? 0).round(),
        totalFat: (item.fatG ?? 0).round(),
        sourceType: source.sourceType ?? 'text',
        userQuery: item.name,
      );

      // 2. Remove from source.
      if (source.foodItems.length <= 1) {
        await ref.read(nutritionProvider.notifier).deleteLog(_userId!, source.id);
      } else {
        final remaining = [
          for (int i = 0; i < source.foodItems.length; i++)
            if (i != itemIdx) source.foodItems[i],
        ];
        await repo.updateFoodLog(
          logId: source.id,
          totalCalories: remaining.fold<int>(0, (s, f) => s + (f.calories ?? 0)),
          proteinG: remaining.fold<double>(0, (s, f) => s + (f.proteinG ?? 0)),
          carbsG: remaining.fold<double>(0, (s, f) => s + (f.carbsG ?? 0)),
          fatG: remaining.fold<double>(0, (s, f) => s + (f.fatG ?? 0)),
          foodItems: remaining.map((f) => f.toJson()).toList(),
        );
      }

      _cachedMicronutrientsTime = null;
      await ref.read(nutritionProvider.notifier).refreshAll(_userId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Moved ${item.name} to ${targetMealType[0].toUpperCase()}${targetMealType.substring(1)}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error moving item as standalone: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Couldn’t move item: ${_friendlyApiError(e)}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Background Save-as-Recipe. Returns immediately so the user can keep
  /// scrolling / switch tabs; the AI enrichment runs server-side and a
  /// completion toast surfaces via `RecipeSaveJobsListener` mounted in
  /// `app.dart`. The toast carries a **View** action that pushes
  /// RecipeDetailScreen — so even users who navigate away mid-job get back
  /// to the new recipe in one tap.
  ///
  /// `itemIndex` is non-null when the user invoked from a per-item long
  /// press (e.g. "Save 'Prawns Curry' as recipe" from inside a multi-item
  /// meal). The backend builds a single-ingredient recipe in that case.
  void _saveMealAsRecipe(FoodLog meal, {int? itemIndex, bool createCookEvent = false}) {
    if (_userId == null) return;
    ref.read(posthogServiceProvider).capture(
      eventName: 'food_log_save_as_recipe_invoked',
      properties: <String, Object>{
        'food_log_id': meal.id,
        'item_index': itemIndex ?? -1,
        'create_cook_event': createCookEvent,
        'is_multi_item': meal.foodItems.length > 1,
      },
    );

    // Resolve a friendly meal name for the toast. Per-item uses just that
    // item's name; whole-meal uses user_query when present, falling back to
    // joined item names so the user sees what's being saved.
    final mealName = (itemIndex != null && itemIndex >= 0 && itemIndex < meal.foodItems.length)
        ? meal.foodItems[itemIndex].name
        : (meal.userQuery?.trim().isNotEmpty == true
            ? meal.userQuery!
            : meal.foodItems.map((f) => f.name).take(3).join(' + '));

    final notifier = ref.read(recipeSaveJobsProvider.notifier);
    if (notifier.isPending(meal.id, itemIndex)) {
      // Double-tap protection — silently drop, no second toast.
      return;
    }
    notifier.enqueue(
      logId: meal.id,
      itemIndex: itemIndex,
      mealName: mealName,
      createCookEvent: createCookEvent,
    );

    // Immediate feedback so the user knows their tap registered. Real
    // success / error toast comes from the global listener.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Cooking up your recipe in the background…"),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Open the single-meal share sheet (renders meal card, save / share via
  /// share_plus). Reuses the same Instagram-Stories capture pipeline as the
  /// 4-template `ShareNutritionSheet` — see share_meal_sheet.dart.
  Future<void> _shareMeal(FoodLog meal) async {
    ref.read(posthogServiceProvider).capture(
      eventName: 'food_log_shared_invoked',
      properties: <String, Object>{'food_log_id': meal.id},
    );
    await ShareSingleMealSheet.show(context, meal);
  }

  /// Add a logged meal (or one item from it) to the user's active grocery
  /// list. Backend dedupes by ingredient_name_normalized — "Idli"+"idli"
  /// collapse to one row. Surfaces a snackbar with the merge count + a
  /// **View** action that pushes the existing grocery list screen.
  Future<void> _addMealToShoppingList(FoodLog meal, {int? itemIndex}) async {
    if (_userId == null) return;
    try {
      ref.read(posthogServiceProvider).capture(
        eventName: 'food_log_added_to_shopping_list',
        properties: <String, Object>{
          'food_log_id': meal.id,
          'item_index': itemIndex ?? -1,
        },
      );
      final result = await ref
          .read(nutritionRepositoryProvider)
          .addLogToShoppingList(logId: meal.id, itemIndex: itemIndex);
      if (!mounted) return;
      final n = result.itemsAdded;
      final m = result.itemsMerged;
      final label = m > 0
          ? 'Added $n + merged $m into ${result.listName}'
          : 'Added $n items to ${result.listName}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(label),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('Error adding to shopping list: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn’t add to shopping list: ${_friendlyApiError(e)}"),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// Open the cadence picker sheet and dispatch the schedule call as a
  /// background job. Uses the same fire-and-forget toast pattern as
  /// Save-as-Recipe — see `recipe_save_jobs_provider.dart` for the lifecycle.
  /// Pre-selects the [initialPreset] (used by the "Log again tomorrow"
  /// shortcut to skip straight to ScheduleSheetResult.tomorrowOnly).
  Future<void> _scheduleMealFromLog(
    FoodLog meal, {
    SchedulePreset initialPreset = SchedulePreset.tomorrowOnly,
    int? itemIndex,
  }) async {
    if (_userId == null) return;
    // Use the device IANA timezone (matches feedback_user_local_time_only).
    final timezone = DateTime.now().timeZoneName.isNotEmpty
        ? DateTime.now().timeZoneName
        : 'UTC';
    // Resolve the IANA tz preferred by the backend; fall back to abbreviation
    // when flutter_timezone hasn't been wired here. The backend tolerates both
    // (zoneinfo accepts Olson IDs and falls back to UTC on parse failure).
    final result = await showScheduleMealSheet(
      context: context,
      meal: meal,
      timezone: timezone,
      initialPreset: initialPreset,
    );
    if (result == null) return;

    ref.read(posthogServiceProvider).capture(
      eventName: 'food_log_scheduled_invoked',
      properties: <String, Object>{
        'food_log_id': meal.id,
        'item_index': itemIndex ?? -1,
        'cadence': result.spec.scheduleKind,
        'is_temporary_week_only': result.spec.isTemporaryWeekOnly,
        'interval_days': result.spec.intervalDays,
        'has_until_date': result.spec.untilDate != null,
      },
    );

    final mealName = (itemIndex != null && itemIndex >= 0 && itemIndex < meal.foodItems.length)
        ? meal.foodItems[itemIndex].name
        : (meal.userQuery?.trim().isNotEmpty == true
            ? meal.userQuery!
            : meal.foodItems.map((f) => f.name).take(3).join(' + '));

    ref.read(scheduleSaveJobsProvider.notifier).enqueue(
      logId: meal.id,
      mealName: mealName,
      cadenceLabel: result.cadenceLabel,
      spec: result.spec,
      itemIndex: itemIndex,
      createCookEvent: meal.foodItems.length > 1,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scheduling…'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _moveMeal(String mealId, String targetMealType) async {
    if (_userId == null) return;
    final notifier = ref.read(nutritionProvider.notifier);
    // Optimistically flip the meal_type locally so the UI updates instantly.
    // Restored to its original meal_type if the network call fails.
    final original = notifier.optimisticUpdateLog(mealId, (meal) {
      final json = meal.toJson()..['meal_type'] = targetMealType;
      return FoodLog.fromJson(json);
    });
    try {
      ref.read(posthogServiceProvider).capture(
        eventName: 'food_log_moved',
        properties: <String, Object>{'food_log_id': mealId, 'target_meal_type': targetMealType},
      );
      final repository = ref.read(nutritionRepositoryProvider);
      await repository.moveFoodLog(logId: mealId, mealType: targetMealType);
      _cachedMicronutrientsTime = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Moved to ${targetMealType[0].toUpperCase()}${targetMealType.substring(1)}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Roll back the optimistic mutation on failure so the UI reflects truth.
      if (original != null) {
        notifier.optimisticUpdateLog(mealId, (_) => original);
      }
      debugPrint('Error moving meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Couldn’t move meal: ${_friendlyApiError(e)}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _updateMeal(
    String logId,
    int calories,
    double proteinG,
    double carbsG,
    double fatG, {
    double? weightG,
    List<Map<String, dynamic>>? foodItems,
    List<FoodItemEdit>? itemEdits,
  }) async {
    if (_userId == null) return;
    final repository = ref.read(nutritionRepositoryProvider);

    // Per-edit PostHog analytics — one event per audit row (matches the
    // pre-save path). Fire-and-forget; done up front so it's recorded even
    // though the network write below now runs in the background.
    if (itemEdits != null && itemEdits.isNotEmpty) {
      final posthog = ref.read(posthogServiceProvider);
      for (final e in itemEdits) {
        final deltaPct = e.previousValue != 0
            ? ((e.updatedValue - e.previousValue) / e.previousValue * 100).toStringAsFixed(1)
            : 'inf';
        posthog.capture(
          eventName: 'food_item_edited',
          properties: <String, Object>{
            'field': e.editedField,
            'previous': e.previousValue,
            'updated': e.updatedValue,
            'delta': e.updatedValue - e.previousValue,
            'delta_pct': deltaPct,
            'source': 'post_save_nutrition_screen',
            'food_item_name': e.foodItemName,
            'food_log_id': logId,
          },
        );
      }
    }

    // Micronutrient cache is tied to the day's macros — invalidate it so the
    // next read recomputes after this edit lands.
    _cachedMicronutrientsTime = null;

    // WR2 — optimistic food EDIT. `commitUpdateLog` swaps the in-memory row's
    // calories/macros instantly (meal row + macro rings update within one
    // frame), runs the network PUT in the background, and rolls the row back
    // (with a calm `state.error`) if the server rejects the edit.
    await ref.read(nutritionProvider.notifier).commitUpdateLog(
      logId,
      // Transform: FoodLog has no copyWith (generated model) — rebuild the row
      // with every field preserved and only the edited macros/calories
      // swapped. `foodItems` is kept as-is; the background network response is
      // the source of truth for the per-item breakdown, and the rings only
      // read the row-level totals below.
      (m) => FoodLog(
        id: m.id,
        userId: m.userId,
        mealType: m.mealType,
        loggedAt: m.loggedAt,
        foodItems: m.foodItems,
        totalCalories: calories,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        fiberG: m.fiberG,
        healthScore: m.healthScore,
        healthScoreReasons: m.healthScoreReasons,
        aiFeedback: m.aiFeedback,
        notes: m.notes,
        moodBefore: m.moodBefore,
        moodAfter: m.moodAfter,
        energyLevel: m.energyLevel,
        sodiumMg: m.sodiumMg,
        sugarG: m.sugarG,
        saturatedFatG: m.saturatedFatG,
        cholesterolMg: m.cholesterolMg,
        potassiumMg: m.potassiumMg,
        calciumMg: m.calciumMg,
        ironMg: m.ironMg,
        vitaminAUg: m.vitaminAUg,
        vitaminCMg: m.vitaminCMg,
        vitaminDIu: m.vitaminDIu,
        inflammationScore: m.inflammationScore,
        isUltraProcessed: m.isUltraProcessed,
        glycemicLoad: m.glycemicLoad,
        fodmapRating: m.fodmapRating,
        fodmapReason: m.fodmapReason,
        imageUrl: m.imageUrl,
        sourceType: m.sourceType,
        userQuery: m.userQuery,
        createdAt: m.createdAt,
      ),
      // networkUpdate: only awaited AFTER the optimistic row lands.
      () => repository.updateFoodLog(
        logId: logId,
        totalCalories: calories,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        weightG: weightG,
        foodItems: foodItems,
        itemEdits: itemEdits ?? const [],
      ),
    );
  }

  Future<List<FoodLogEditRecord>> _fetchItemEdits(String logId) async {
    final repository = ref.read(nutritionRepositoryProvider);
    return repository.listFoodLogEdits(logId);
  }

  Future<void> _updateMealTime(String logId, DateTime newTime) async {
    if (_userId == null) return;
    try {
      final repository = ref.read(nutritionRepositoryProvider);
      await repository.updateFoodLogTime(logId: logId, loggedAt: newTime.toIso8601String());
      _cachedMicronutrientsTime = null;
      await ref.read(nutritionProvider.notifier).refreshAll(_userId!);
    } catch (e) {
      debugPrint('Error updating meal time: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Couldn’t update time: ${_friendlyApiError(e)}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _updateMealNotes(String logId, String notes) async {
    if (_userId == null) return;
    try {
      final repository = ref.read(nutritionRepositoryProvider);
      await repository.updateFoodLogNotes(logId: logId, notes: notes);
      _cachedMicronutrientsTime = null;
      await ref.read(nutritionProvider.notifier).refreshAll(_userId!);
    } catch (e) {
      debugPrint('Error updating notes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Couldn’t update notes: ${_friendlyApiError(e)}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _updateMealMood(String logId, {String? moodBefore, String? moodAfter, int? energyLevel}) async {
    if (_userId == null) return;
    try {
      final repository = ref.read(nutritionRepositoryProvider);
      await repository.updateFoodLogMood(logId: logId, moodBefore: moodBefore, moodAfter: moodAfter, energyLevel: energyLevel);
      _cachedMicronutrientsTime = null;
      await ref.read(nutritionProvider.notifier).refreshAll(_userId!);
    } catch (e) {
      debugPrint('Error updating mood: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Couldn’t update mood: ${_friendlyApiError(e)}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _saveFoodToFavorites(FoodLog meal) async {
    if (_userId == null) return;
    try {
      final repository = ref.read(nutritionRepositoryProvider);
      final request = SaveFoodRequest.fromFoodLog(meal);
      await repository.saveFood(userId: _userId!, request: request);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to My Foods'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      debugPrint('Error saving food: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().contains('duplicate') ? 'Already in My Foods' : 'Failed to save food'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  /// Convert any thrown error (DioException, generic Exception) into a short
  /// human-readable string suitable for a SnackBar. For Dio errors, surfaces
  /// the backend's `detail` field + status code so the user (and us) can
  /// see what actually went wrong instead of a generic "Failed".
  String _friendlyApiError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String? detail;
      if (data is Map && data['detail'] != null) {
        detail = data['detail'].toString();
      } else if (data is String && data.isNotEmpty) {
        detail = data;
      }
      if (status != null && detail != null) return '$status — $detail';
      if (status != null) return 'HTTP $status';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Network timeout';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'No connection';
      }
      return e.message ?? 'Network error';
    }
    return e.toString().replaceFirst('Exception: ', '');
  }
}
