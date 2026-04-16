import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/nutrition.dart';
import '../../data/models/micronutrients.dart';
import '../../data/models/recipe.dart';
import '../../data/providers/nutrition_preferences_provider.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/providers/xp_provider.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/segmented_tab_bar.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/pill_swipe_navigation.dart';
import 'log_meal_sheet.dart';
import 'food_history_screen.dart';
import 'nutrition_settings_screen.dart';
import 'recipe_builder_sheet.dart';
import 'weekly_checkin_sheet.dart';
import 'widgets/daily_tab.dart';
import 'widgets/nutrition_error_state.dart';
import 'widgets/my_foods_sheet.dart';
import 'widgets/share_nutrition_sheet.dart';
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

  const NutritionScreen({
    super.key,
    this.initialMeal,
    this.initialTab = 0,
    this.autoOpenCamera = false,
    this.autoOpenBarcode = false,
    this.openCheckinLogId,
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
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'nutrition_screen_viewed');
    });
    // Collapse nav bar labels on this secondary page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navBarLabelsExpandedProvider.notifier).state = false;
      // Listen for preferences to become available, then check for weekly check-in
      _setupWeeklyCheckinListener();
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
      ref.read(nutritionProvider.notifier).loadTodaySummary(userId, forceRefresh: forceRefresh);
      _loadMicronutrients(userId, dateStr);
      ref.read(nutritionPreferencesProvider.notifier).initialize(userId);
      ref.read(nutritionProvider.notifier).loadRecentLogs(userId, forceRefresh: forceRefresh);
      ref.read(hydrationProvider.notifier).loadTodaySummary(userId);
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

      debugPrint('[NutritionScreen] Weekly check-in is due! Last check-in: ${prefs.lastWeeklyCheckinAt}, Days since: ${prefs.daysSinceLastCheckin}');

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        showWeeklyCheckinSheet(context, ref);
      }
    } else {
      debugPrint('[NutritionScreen] Weekly check-in not due. Enabled: ${prefs.weeklyCheckinEnabled}, Days since: ${prefs.daysSinceLastCheckin}');
    }
  }

  Future<void> _loadMicronutrients(String userId, String date) async {
    final cacheKey = '$userId:$date';

    // Serve cached data instantly if available and fresh
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

    // Show stale cache while fetching (if same key)
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
      // Update cache
      _cachedMicronutrients = summary;
      _cachedMicronutrientsKey = cacheKey;
      _cachedMicronutrientsTime = DateTime.now();
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
    // Use cached recipes if fresh enough
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
      }
    } catch (e) {
      debugPrint('Error loading recipes: $e');
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadDataForSelectedDate();
  }

  void _loadDataForSelectedDate() {
    if (_userId == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final notifier = ref.read(nutritionProvider.notifier);
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
      body: SafeArea(
        child: wrapWithSwipeDetector(
        child: Column(
          children: [
            // Floating Header Row
            _buildHeaderRow(context, isDark, glassSurface, textPrimary, textMuted, textSecondary, elevated),
            // Tab Bar with colored tabs
            SegmentedTabBar(
              controller: _tabController,
              showIcons: false,
              showBorder: true,
              tabs: const [
                SegmentedTabItem(label: 'Daily', icon: Icons.restaurant_menu_rounded),
                SegmentedTabItem(label: 'Recipes', icon: Icons.menu_book_rounded),
                SegmentedTabItem(label: 'Patterns', icon: Icons.insights_outlined),
                SegmentedTabItem(label: 'Fuel', icon: Icons.bolt_outlined),
              ],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            ),

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
                          // Daily Tab
                          DailyTab(
                            userId: _userId ?? '',
                            summary: state.todaySummary,
                            targets: state.targets,
                            micronutrients: _micronutrientSummary,
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
                            onFetchItemEdits: _fetchItemEdits,
                            apiClient: ref.read(apiClientProvider),
                            // Fuel tab (index 3) now hosts both Nutrients and Water pill toggles
                            onSwitchToNutrientsTab: () => _tabController.animateTo(3),
                            onSwitchToHydrationTab: () => _tabController.animateTo(3),
                            isDark: isDark,
                            calmMode: calmMode,
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
                          ),
                        ],
                      ),
          ),
          ],
        ),
      ),
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildHeaderRow(BuildContext context, bool isDark, Color glassSurface, Color textPrimary, Color textMuted, Color textSecondary, Color elevated) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Date Navigation (left-aligned)
          GestureDetector(
            onTap: () => _changeDate(-1),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: glassSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.chevron_left, size: 20, color: textPrimary),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _loadDataForSelectedDate();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _dateLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _isToday ? null : () => _changeDate(1),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: glassSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: _isToday ? textMuted : textPrimary,
              ),
            ),
          ),
          const Spacer(),
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
          // My Foods (Saved Foods + Recipes)
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
          const SizedBox(width: 6),
          // Share
          GestureDetector(
            onTap: () {
              final state = ref.read(nutritionProvider);
              ShareNutritionSheet.show(
                context,
                ref,
                summary: state.todaySummary,
                targets: state.targets,
              );
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
              Navigator.push(
                context,
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
    _cachedMicronutrientsTime = null; // Invalidate — food was logged
    _loadData();
  }

  void _showRecipeBuilder(BuildContext context, bool isDark) {
    if (_userId == null || _userId!.isEmpty) {
      debugPrint('Cannot show RecipeBuilderSheet: userId is null or empty');
      return;
    }

    ref.read(floatingNavBarVisibleProvider.notifier).state = false;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: RecipeBuilderSheet(userId: _userId!, isDark: isDark),
      ),
    ).then((_) {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
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
            _loadData();
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
      await repository.logRecipe(
        userId: _userId!,
        recipeId: recipe.id,
        mealType: mealType.value,
      );
      if (mounted) {
        ref.read(xpProvider.notifier).markMealLogged();
        _loadData();
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
    _cachedMicronutrientsTime = null; // Invalidate cache — nutrients changed
    ref.read(posthogServiceProvider).capture(
      eventName: 'food_log_deleted',
      properties: <String, Object>{'food_log_id': mealId},
    );
    await ref.read(nutritionProvider.notifier).deleteLog(_userId!, mealId);
  }

  Future<void> _copyMeal(String mealId, String targetMealType) async {
    if (_userId == null) return;
    try {
      ref.read(posthogServiceProvider).capture(
        eventName: 'food_log_copied',
        properties: <String, Object>{'food_log_id': mealId, 'target_meal_type': targetMealType},
      );
      final repository = ref.read(nutritionRepositoryProvider);
      await repository.copyFoodLog(logId: mealId, mealType: targetMealType);
      _cachedMicronutrientsTime = null;
      await ref.read(nutritionProvider.notifier).refreshAll(_userId!);
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
          const SnackBar(
            content: Text('Failed to copy meal'),
            behavior: SnackBarBehavior.floating,
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
          const SnackBar(content: Text('Failed to copy item'), behavior: SnackBarBehavior.floating),
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
          const SnackBar(content: Text('Failed to move item'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _moveMeal(String mealId, String targetMealType) async {
    if (_userId == null) return;
    try {
      ref.read(posthogServiceProvider).capture(
        eventName: 'food_log_moved',
        properties: <String, Object>{'food_log_id': mealId, 'target_meal_type': targetMealType},
      );
      final repository = ref.read(nutritionRepositoryProvider);
      await repository.moveFoodLog(logId: mealId, mealType: targetMealType);
      _cachedMicronutrientsTime = null;
      await ref.read(nutritionProvider.notifier).refreshAll(_userId!);
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
      debugPrint('Error moving meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to move meal'),
            behavior: SnackBarBehavior.floating,
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
    try {
      final repository = ref.read(nutritionRepositoryProvider);
      await repository.updateFoodLog(
        logId: logId,
        totalCalories: calories,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        weightG: weightG,
        foodItems: foodItems,
        itemEdits: itemEdits ?? const [],
      );

      // Per-edit PostHog analytics — one event per audit row (matches the
      // pre-save path). Fire-and-forget.
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

      _cachedMicronutrientsTime = null;
      await ref.read(nutritionProvider.notifier).refreshAll(_userId!);
    } catch (e) {
      debugPrint('Error updating meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update meal'), behavior: SnackBarBehavior.floating),
        );
      }
    }
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
          const SnackBar(content: Text('Failed to update time'), behavior: SnackBarBehavior.floating),
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
          const SnackBar(content: Text('Failed to update notes'), behavior: SnackBarBehavior.floating),
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
          const SnackBar(content: Text('Failed to update mood'), behavior: SnackBarBehavior.floating),
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
}
