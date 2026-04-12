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
import 'nutrient_explorer.dart';
import 'food_history_screen.dart';
import 'nutrition_settings_screen.dart';
import 'recipe_builder_sheet.dart';
import 'weekly_checkin_sheet.dart';
import 'widgets/daily_tab.dart';
import 'widgets/nutrition_loading_skeleton.dart';
import 'widgets/nutrition_error_state.dart';
import 'widgets/my_foods_sheet.dart';
import 'widgets/share_nutrition_sheet.dart';
import 'tabs/hydration_tab.dart';
// COMING SOON: Fasting tab — uncomment when fasting feature launches
// import 'tabs/fasting_tab.dart';
import '../../core/services/posthog_service.dart';
import '../../data/repositories/hydration_repository.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  /// Optional meal type to auto-open the log meal sheet (from deep link).
  final String? initialMeal;

  /// Optional initial tab index (0=Daily, 1=Nutrients, 2=Water).
  /// COMING SOON: Fasting will be index 3 when re-enabled.
  final int initialTab;

  /// When true, auto-opens the log meal sheet and launches the camera.
  final bool autoOpenCamera;

  /// When true, auto-opens the log meal sheet and launches the barcode scanner.
  final bool autoOpenBarcode;

  const NutritionScreen({super.key, this.initialMeal, this.initialTab = 0, this.autoOpenCamera = false, this.autoOpenBarcode = false});

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
    // COMING SOON: Change back to length: 4 when fasting tab is re-enabled
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
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

  Future<void> _loadData() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId != null && mounted) {
      setState(() => _userId = userId);

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      _loadRecipes(userId);
      ref.read(nutritionProvider.notifier).loadTodaySummary(userId);
      _loadMicronutrients(userId, dateStr);
      ref.read(nutritionPreferencesProvider.notifier).initialize(userId);
      ref.read(nutritionProvider.notifier).loadRecentLogs(userId);
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

  Future<void> _loadRecipes(String userId) async {
    try {
      final repository = ref.read(nutritionRepositoryProvider);
      final response = await repository.getRecipes(
        userId: userId,
        limit: 10,
        sortBy: 'times_logged',
      );
      if (mounted) {
        setState(() => _recipes = response.items);
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
                SegmentedTabItem(label: 'Nutrients', icon: Icons.science_outlined),
                SegmentedTabItem(label: 'Water', icon: Icons.water_drop_outlined),
                // COMING SOON: Fasting tab — uncomment when fasting feature launches
                // SegmentedTabItem(label: 'Fast', icon: Icons.timer_outlined),
              ],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            ),

          // Tab Content
          Expanded(
            child: state.isLoading
                ? NutritionLoadingSkeleton(isDark: isDark)
                : state.error != null
                    ? NutritionErrorState(
                        error: state.error!,
                        onRetry: _loadData,
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
                            onUpdateMeal: (logId, cal, p, c, f, {double? weightG}) => _updateMeal(logId, cal, p, c, f, weightG: weightG),
                            onUpdateMealTime: (logId, newTime) => _updateMealTime(logId, newTime),
                            onUpdateMealNotes: (logId, notes) => _updateMealNotes(logId, notes),
                            onUpdateMealMood: (logId, {String? moodBefore, String? moodAfter, int? energyLevel}) => _updateMealMood(logId, moodBefore: moodBefore, moodAfter: moodAfter, energyLevel: energyLevel),
                            onSaveFoodToFavorites: (meal) => _saveFoodToFavorites(meal),
                            apiClient: ref.read(apiClientProvider),
                            onSwitchToNutrientsTab: () => _tabController.animateTo(1),
                            onSwitchToHydrationTab: () => _tabController.animateTo(2),
                            isDark: isDark,
                            calmMode: calmMode,
                          ),

                          // Nutrients Tab
                          NutrientExplorerTab(
                            userId: _userId ?? '',
                            summary: _micronutrientSummary,
                            isLoading: _isLoadingMicronutrients,
                            onRefresh: () {
                              if (_userId != null) {
                                final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                                _loadMicronutrients(_userId!, dateStr);
                              }
                            },
                            isDark: isDark,
                          ),

                          // Hydration Tab
                          HydrationTab(
                            userId: _userId ?? '',
                            isDark: isDark,
                          ),

                          // COMING SOON: Fasting Tab — uncomment when fasting feature launches
                          // FastingTab(
                          //   userId: _userId ?? '',
                          //   isDark: isDark,
                          // ),
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
    await ref.read(nutritionProvider.notifier).deleteLog(_userId!, mealId);
  }

  Future<void> _copyMeal(String mealId, String targetMealType) async {
    if (_userId == null) return;
    try {
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

  Future<void> _moveMeal(String mealId, String targetMealType) async {
    if (_userId == null) return;
    try {
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

  Future<void> _updateMeal(String logId, int calories, double proteinG, double carbsG, double fatG, {double? weightG}) async {
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
      );
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
