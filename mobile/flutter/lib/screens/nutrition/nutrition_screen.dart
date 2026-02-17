import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/nutrition.dart';
import '../../data/models/micronutrients.dart';
import '../../data/models/nutrition_preferences.dart';
import '../../data/models/recipe.dart';
import '../../data/providers/nutrition_preferences_provider.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/repositories/nutrition_preferences_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/providers/xp_provider.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/segmented_tab_bar.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/pill_swipe_navigation.dart';
import '../../widgets/nutrition/health_metrics_card.dart';
import '../../widgets/nutrition/food_mood_analytics_card.dart';
import 'log_meal_sheet.dart';
import 'nutrient_explorer.dart';
import 'nutrition_settings_screen.dart';
import 'recipe_builder_sheet.dart';
import 'weekly_checkin_sheet.dart';
import 'widgets/quick_add_fab.dart';
import 'widgets/nutrition_goals_card.dart';
import 'tabs/hydration_tab.dart';
import 'tabs/fasting_tab.dart';
import '../../data/repositories/hydration_repository.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen>
    with SingleTickerProviderStateMixin, PillSwipeNavigationMixin {
  // PillSwipeNavigationMixin: Nutrition is index 2
  @override
  int get currentPillIndex => 2;

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
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
    // Collapse nav bar labels on this secondary page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navBarLabelsExpandedProvider.notifier).state = false;
      // Listen for preferences to become available, then check for weekly check-in
      _setupWeeklyCheckinListener();
    });
  }

  /// Set up listener to trigger weekly check-in when preferences are loaded
  void _setupWeeklyCheckinListener() {
    // Use listen to detect when preferences become available
    ref.listenManual(nutritionPreferencesProvider, (previous, next) {
      // Only trigger once: when preferences first become available
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
    if (userId != null) {
      setState(() => _userId = userId);

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // Phase 1: Load essential data for immediate display (blocking)
      await Future.wait([
        ref.read(nutritionProvider.notifier).loadTodaySummary(userId),
        ref.read(nutritionProvider.notifier).loadTargets(userId),
      ], eagerError: false);

      // Phase 2: Load secondary data in background (non-blocking)
      // These run without await to not block UI
      Future.wait([
        ref.read(nutritionPreferencesProvider.notifier).initialize(userId),
        ref.read(nutritionProvider.notifier).loadRecentLogs(userId),
        ref.read(hydrationProvider.notifier).loadTodaySummary(userId),
      ], eagerError: false);

      // Phase 3: Lazy load micronutrients and recipes (non-blocking)
      _loadMicronutrients(userId, dateStr);
      _loadRecipes(userId);

      // Log state after initialization for debugging
      final initState = ref.read(nutritionPreferencesProvider);
      debugPrint('🥗 [NutritionScreen] After init: prefs=${initState.preferences != null}, calories=${initState.preferences?.targetCalories}');

      // Note: Removed ref.invalidate(quickAddSuggestionsProvider) to prevent unnecessary refetching
      // Quick add suggestions will be loaded on-demand when the sheet opens
    }
  }

  /// Check if weekly check-in is due and show the sheet if enabled
  Future<void> _checkAndShowWeeklyCheckin() async {
    if (!mounted || _userId == null) return;

    final prefsState = ref.read(nutritionPreferencesProvider);
    final prefs = prefsState.preferences;

    // Skip if preferences not loaded
    if (prefs == null) {
      debugPrint('📅 [NutritionScreen] Skipping weekly check-in - prefs not ready');
      return;
    }

    // Check if weekly check-in is due using the model helper
    if (prefs.isWeeklyCheckinDue) {
      debugPrint('📅 [NutritionScreen] Weekly check-in is due! Last check-in: ${prefs.lastWeeklyCheckinAt}, Days since: ${prefs.daysSinceLastCheckin}');

      // Small delay to let the screen render first
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        showWeeklyCheckinSheet(context, ref);
      }
    } else {
      debugPrint('📅 [NutritionScreen] Weekly check-in not due. Enabled: ${prefs.weeklyCheckinEnabled}, Days since: ${prefs.daysSinceLastCheckin}');
    }
  }

  Future<void> _loadMicronutrients(String userId, String date) async {
    setState(() => _isLoadingMicronutrients = true);
    try {
      final repository = ref.read(nutritionRepositoryProvider);
      final summary = await repository.getDailyMicronutrients(
        userId: userId,
        date: date,
      );
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
    if (_userId != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      ref
          .read(nutritionProvider.notifier)
          .loadTodaySummary(_userId!);
      _loadMicronutrients(_userId!, dateStr);
    }
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
    // Get dynamic accent color from provider
    final accentColor = ref.colors(context).accent;

    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: wrapWithSwipeDetector(
        child: Column(
          children: [
            // Floating Header Row
            Padding(
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
                        if (_userId != null) {
                          final dateStr = DateFormat('yyyy-MM-dd').format(picked);
                          ref.read(nutritionProvider.notifier).loadTodaySummary(_userId!);
                          _loadMicronutrients(_userId!, dateStr);
                        }
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
                  // Saved Foods - labeled pill for discoverability
                  GestureDetector(
                    onTap: () => _showFavoritesSheet(isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: glassSurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmark_outline, size: 16, color: AppColors.yellow),
                          const SizedBox(width: 4),
                          Text(
                            'Saved',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Stats - floating circle
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
                  const SizedBox(width: 8),
                  // Settings - floating circle
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
            ),
            // Tab Bar with colored tabs
            SegmentedTabBar(
              controller: _tabController,
              showIcons: true,
              showBorder: true,
              tabs: const [
                SegmentedTabItem(label: 'Daily', icon: Icons.restaurant_menu_rounded),
                SegmentedTabItem(label: 'Nutrients', icon: Icons.science_outlined),
                SegmentedTabItem(label: 'Recipes', icon: Icons.menu_book_rounded),
                SegmentedTabItem(label: 'Water', icon: Icons.water_drop_outlined),
                SegmentedTabItem(label: 'Fast', icon: Icons.timer_outlined),
              ],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),

          // Tab Content
          Expanded(
            child: state.isLoading
                ? _NutritionLoadingSkeleton(isDark: isDark)
                : state.error != null
                    ? _NutritionErrorState(
                        error: state.error!,
                        onRetry: _loadData,
                        isDark: isDark,
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // Daily Tab
                          _DailyTab(
                            userId: _userId ?? '',
                            summary: state.todaySummary,
                            targets: state.targets,
                            micronutrients: _micronutrientSummary,
                            onRefresh: _loadData,
                            onLogMeal: (mealType) => _showLogMealSheet(isDark, mealType: mealType),
                            onDeleteMeal: (id) => _deleteMeal(id),
                            onCopyMeal: (id, mealType) => _copyMeal(id, mealType),
                            onSwitchToNutrientsTab: () => _tabController.animateTo(1), // Switch to Nutrients tab (index 1)
                            onSwitchToHydrationTab: () => _tabController.animateTo(3), // Switch to Hydration tab (index 3)
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
                                final dateStr = DateFormat('yyyy-MM-dd')
                                    .format(_selectedDate);
                                _loadMicronutrients(_userId!, dateStr);
                              }
                            },
                            isDark: isDark,
                          ),

                          // Recipes Tab
                          _RecipesTab(
                            userId: _userId ?? '',
                            recipes: _recipes,
                            onCreateRecipe: () =>
                                _showRecipeBuilder(context, isDark),
                            onLogRecipe: (recipe) =>
                                _logRecipe(recipe, isDark),
                            onRefresh: () {
                              if (_userId != null) {
                                _loadRecipes(_userId!);
                              }
                            },
                            isDark: isDark,
                          ),

                          // Hydration Tab
                          HydrationTab(
                            userId: _userId ?? '',
                            isDark: isDark,
                          ),

                          // Fasting Tab
                          FastingTab(
                            userId: _userId ?? '',
                            isDark: isDark,
                          ),
                        ],
                      ),
          ),
          ],
        ),
      ),
      ),
      // Quick Add FAB for easy food logging - padded above the floating nav bar
      floatingActionButton: _userId != null && _userId!.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: QuickAddFABSimple(
                userId: _userId!,
                onMealLogged: () {
                  // Refresh nutrition data after logging a meal
                  ref.read(nutritionProvider.notifier).loadTodaySummary(_userId!);
                },
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _showLogMealSheet(bool isDark, {String? mealType}) async {
    // Try local state first, fallback to apiClient
    String? userId = _userId;
    if (userId == null || userId.isEmpty) {
      debugPrint('_showLogMealSheet: local userId is null, trying apiClient...');
      userId = await ref.read(apiClientProvider).getUserId();
    }

    // Guard: Don't show sheet if user ID is not available
    if (userId == null || userId.isEmpty) {
      debugPrint('Cannot show LogMealSheet: userId is null or empty');
      return;
    }

    // Update local state if we got it from apiClient
    if (_userId == null) {
      setState(() => _userId = userId);
    }

    // Convert string to MealType if provided
    MealType? initialMealType;
    if (mealType != null) {
      initialMealType = MealType.values.firstWhere(
        (t) => t.value == mealType,
        orElse: () => MealType.lunch,
      );
    }

    // Hide nav bar while sheet is open
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: LogMealSheet(
          userId: userId!,
          isDark: isDark,
          initialMealType: initialMealType,
        ),
      ),
    ).then((_) {
      // Show nav bar when sheet is closed
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
      _loadData();
    });
  }

  void _showRecipeBuilder(BuildContext context, bool isDark) {
    // Guard: Don't show sheet if user ID is not available
    if (_userId == null || _userId!.isEmpty) {
      debugPrint('Cannot show RecipeBuilderSheet: userId is null or empty');
      return;
    }

    // Hide nav bar while sheet is open
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: RecipeBuilderSheet(userId: _userId!, isDark: isDark),
      ),
    ).then((_) {
      // Show nav bar when sheet is closed
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
      _loadRecipes(_userId!);
    });
  }


  /// Show favorites/saved foods sheet
  void _showFavoritesSheet(bool isDark) {
    if (_userId == null || _userId!.isEmpty) return;

    ref.read(floatingNavBarVisibleProvider.notifier).state = false;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        showHandle: false,
        child: _SavedFoodsFilterSheet(
          userId: _userId!,
          repository: ref.read(nutritionRepositoryProvider),
          isDark: isDark,
          onFoodLogged: () {
            _loadData();
          },
          getSuggestedMealType: _getSuggestedMealType,
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
        // Award XP for daily goal
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
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

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
    await ref.read(nutritionProvider.notifier).deleteLog(_userId!, mealId);
  }

  Future<void> _copyMeal(String mealId, String targetMealType) async {
    if (_userId == null) return;
    try {
      final repository = ref.read(nutritionRepositoryProvider);
      await repository.copyFoodLog(logId: mealId, mealType: targetMealType);
      // Refresh data to show the copied meal
      _loadData();
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

  void _showTargetsSettings(BuildContext context, bool isDark) {
    final state = ref.read(nutritionProvider);
    final caloriesController = TextEditingController(
      text: (state.targets?.dailyCalorieTarget ?? 2000).toString(),
    );
    final proteinController = TextEditingController(
      text: (state.targets?.dailyProteinTargetG ?? 150).toString(),
    );
    final carbsController = TextEditingController(
      text: (state.targets?.dailyCarbsTargetG ?? 250).toString(),
    );
    final fatController = TextEditingController(
      text: (state.targets?.dailyFatTargetG ?? 70).toString(),
    );

    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Targets',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textPrimary),
                decoration:
                    _inputDecoration('Calories', 'kcal', elevated, textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: proteinController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textPrimary),
                decoration:
                    _inputDecoration('Protein', 'g', elevated, textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: carbsController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textPrimary),
                decoration:
                    _inputDecoration('Carbs', 'g', elevated, textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fatController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textPrimary),
                decoration:
                    _inputDecoration('Fat', 'g', elevated, textMuted),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_userId != null) {
                      ref.read(nutritionProvider.notifier).updateTargets(
                            _userId!,
                            calorieTarget:
                                int.tryParse(caloriesController.text),
                            proteinTarget:
                                double.tryParse(proteinController.text),
                            carbsTarget:
                                double.tryParse(carbsController.text),
                            fatTarget:
                                double.tryParse(fatController.text),
                          );
                    }
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Update Targets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      String label, String suffix, Color fillColor, Color labelColor) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: labelColor),
      suffixText: suffix,
      suffixStyle: TextStyle(color: labelColor),
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Colored Tab Bar with distinct colors for each tab
// ─────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────
// Daily Tab - MacroFactor-inspired layout
// ─────────────────────────────────────────────────────────────────

class _DailyTab extends ConsumerStatefulWidget {
  final String userId;
  final DailyNutritionSummary? summary;
  final NutritionTargets? targets;
  final DailyMicronutrientSummary? micronutrients;
  final VoidCallback onRefresh;
  final void Function(String? mealType) onLogMeal;
  final void Function(String) onDeleteMeal;
  final void Function(String mealId, String targetMealType) onCopyMeal;
  final VoidCallback? onSwitchToNutrientsTab;
  final VoidCallback? onSwitchToHydrationTab;
  final bool isDark;
  final bool calmMode;

  const _DailyTab({
    required this.userId,
    this.summary,
    this.targets,
    this.micronutrients,
    required this.onRefresh,
    required this.onLogMeal,
    required this.onDeleteMeal,
    required this.onCopyMeal,
    this.onSwitchToNutrientsTab,
    this.onSwitchToHydrationTab,
    required this.isDark,
    this.calmMode = false,
  });

  @override
  ConsumerState<_DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends ConsumerState<_DailyTab> {
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
    final targets = widget.targets;
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
                      _GoalRow(
                        icon: Icons.local_fire_department,
                        label: 'Calories',
                        value: '${targets?.dailyCalorieTarget ?? 2000}',
                        unit: 'kcal',
                        color: teal,
                        isDark: widget.isDark,
                      ),
                      const SizedBox(height: 12),
                      _GoalRow(
                        icon: Icons.egg_outlined,
                        label: 'Protein',
                        value: '${(targets?.dailyProteinTargetG ?? 150).toInt()}',
                        unit: 'g',
                        color: purple,
                        isDark: widget.isDark,
                      ),
                      const SizedBox(height: 12),
                      _GoalRow(
                        icon: Icons.grain,
                        label: 'Carbohydrates',
                        value: '${(targets?.dailyCarbsTargetG ?? 250).toInt()}',
                        unit: 'g',
                        color: orange,
                        isDark: widget.isDark,
                      ),
                      const SizedBox(height: 12),
                      _GoalRow(
                        icon: Icons.water_drop_outlined,
                        label: 'Fat',
                        value: '${(targets?.dailyFatTargetG ?? 70).toInt()}',
                        unit: 'g',
                        color: coral,
                        isDark: widget.isDark,
                      ),
                      const SizedBox(height: 12),
                      _GoalRow(
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
                        Navigator.pushNamed(context, '/nutrition/settings');
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
    final preferences = prefsState.preferences;
    if (preferences == null) return;

    final isDark = widget.isDark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    final caloriesController = TextEditingController(
      text: (preferences.targetCalories ?? 2000).toString(),
    );
    final proteinController = TextEditingController(
      text: (preferences.targetProteinG ?? 150).toString(),
    );
    final carbsController = TextEditingController(
      text: (preferences.targetCarbsG ?? 200).toString(),
    );
    final fatController = TextEditingController(
      text: (preferences.targetFatG ?? 65).toString(),
    );

    // Hide nav bar while sheet is open
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Daily Targets',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close, color: textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Manually set your daily nutrition goals',
                style: TextStyle(fontSize: 14, color: textMuted),
              ),
              const SizedBox(height: 24),
              _buildTargetField(caloriesController, 'Calories', 'kcal', elevated, textMuted, textPrimary),
              const SizedBox(height: 12),
              _buildTargetField(proteinController, 'Protein', 'g', elevated, textMuted, textPrimary),
              const SizedBox(height: 12),
              _buildTargetField(carbsController, 'Carbs', 'g', elevated, textMuted, textPrimary),
              const SizedBox(height: 12),
              _buildTargetField(fatController, 'Fat', 'g', elevated, textMuted, textPrimary),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final calories = int.tryParse(caloriesController.text);
                    final protein = int.tryParse(proteinController.text);
                    final carbs = int.tryParse(carbsController.text);
                    final fat = int.tryParse(fatController.text);

                    if (calories != null || protein != null || carbs != null || fat != null) {
                      await ref.read(nutritionPreferencesProvider.notifier).updateTargets(
                        userId: widget.userId,
                        targetCalories: calories,
                        targetProteinG: protein,
                        targetCarbsG: carbs,
                        targetFatG: fat,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Targets updated'),
                            backgroundColor: teal,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        widget.onRefresh();
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Targets', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      // Show nav bar again when sheet is closed
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    });
  }

  Widget _buildTargetField(
    TextEditingController controller,
    String label,
    String suffix,
    Color elevated,
    Color textMuted,
    Color textPrimary,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(color: textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textMuted),
        suffixText: suffix,
        suffixStyle: TextStyle(color: textMuted),
        filled: true,
        fillColor: elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  /// Recalculate nutrition targets based on user profile
  Future<void> _recalculateTargets() async {
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;

    // Guard against empty userId
    if (widget.userId.isEmpty) {
      debugPrint('⚠️ [NutritionScreen] Cannot recalculate targets - userId is empty');
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
                  _PinnedNutrientsCard(
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

                if (!widget.calmMode) const SizedBox(height: 12),

                // 3. COMPACT MEAL LOGGING ROW - Quick add buttons for each meal type
                _CompactMealLogRow(
                  isDark: widget.isDark,
                  onLogMeal: widget.onLogMeal,
                  meals: widget.summary?.meals ?? [],
                ),

                const SizedBox(height: 12),

                // 4. LOGGED MEALS ONLY - Show only meals that have been logged
                if ((widget.summary?.meals ?? []).isNotEmpty) ...[
                  _LoggedMealsSection(
                    meals: widget.summary?.meals ?? [],
                    onDeleteMeal: widget.onDeleteMeal,
                    onCopyMeal: widget.onCopyMeal,
                    isDark: widget.isDark,
                    userId: widget.userId,
                    onFoodSaved: _loadFavorites,
                  ),
                  const SizedBox(height: 12),
                ],


                const SizedBox(height: 100), // FAB clearance
              ],
            ),
          ),
        ],
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────
// Compact Meal Log Row - Quick add buttons for each meal type
// ─────────────────────────────────────────────────────────────────

class _CompactMealLogRow extends StatelessWidget {
  final bool isDark;
  final void Function(String mealType) onLogMeal;
  final List<FoodLog> meals;

  const _CompactMealLogRow({
    required this.isDark,
    required this.onLogMeal,
    required this.meals,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Calculate calories per meal type
    final mealCalories = <String, int>{};
    for (final meal in meals) {
      final type = meal.mealType ?? 'snack';
      mealCalories[type] = (mealCalories[type] ?? 0) + meal.totalCalories;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MealQuickAddChip(
              label: 'Breakfast',
              emoji: '🍳',
              mealType: 'breakfast',
              calories: mealCalories['breakfast'],
              isDark: isDark,
              onTap: onLogMeal,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: textMuted.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _MealQuickAddChip(
              label: 'Lunch',
              emoji: '🥗',
              mealType: 'lunch',
              calories: mealCalories['lunch'],
              isDark: isDark,
              onTap: onLogMeal,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: textMuted.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _MealQuickAddChip(
              label: 'Dinner',
              emoji: '🍽️',
              mealType: 'dinner',
              calories: mealCalories['dinner'],
              isDark: isDark,
              onTap: onLogMeal,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: textMuted.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _MealQuickAddChip(
              label: 'Snacks',
              emoji: '🍎',
              mealType: 'snack',
              calories: mealCalories['snack'],
              isDark: isDark,
              onTap: onLogMeal,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealQuickAddChip extends StatelessWidget {
  final String label;
  final String emoji;
  final String mealType;
  final int? calories;
  final bool isDark;
  final void Function(String mealType) onTap;

  const _MealQuickAddChip({
    required this.label,
    required this.emoji,
    required this.mealType,
    this.calories,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(mealType),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji with circled + icon
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: teal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
              if (calories != null && calories! > 0)
                Text(
                  '${calories}kcal',
                  style: TextStyle(
                    fontSize: 10,
                    color: teal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Logged Meals Section - Shows only meals that have been logged
// ─────────────────────────────────────────────────────────────────

class _LoggedMealsSection extends StatelessWidget {
  final List<FoodLog> meals;
  final void Function(String) onDeleteMeal;
  final void Function(String mealId, String targetMealType) onCopyMeal;
  final bool isDark;
  final String userId;
  final VoidCallback onFoodSaved;

  const _LoggedMealsSection({
    required this.meals,
    required this.onDeleteMeal,
    required this.onCopyMeal,
    required this.isDark,
    required this.userId,
    required this.onFoodSaved,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Group meals by type
    final mealsByType = <String, List<FoodLog>>{};
    for (final meal in meals) {
      final type = meal.mealType ?? 'snack';
      mealsByType.putIfAbsent(type, () => []).add(meal);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Meals',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...mealsByType.entries.map((entry) {
            final mealType = entry.key;
            final typeMeals = entry.value;
            final totalCal = typeMeals.fold<int>(0, (sum, m) => sum + m.totalCalories);
            final emoji = _getMealEmoji(mealType);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        mealType.substring(0, 1).toUpperCase() + mealType.substring(1),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$totalCal kcal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...typeMeals.map((meal) => Dismissible(
                    key: ValueKey(meal.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      margin: const EdgeInsets.only(left: 24, top: 2, bottom: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.delete_outline, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
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
                            },
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                      // Wait for snackbar to finish
                      await Future.delayed(const Duration(seconds: 4));
                      if (!undone) {
                        onDeleteMeal(meal.id);
                      }
                      return !undone;
                    },
                    child: InkWell(
                      onTap: () => _showMealDetails(context, meal),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24, top: 4, bottom: 4, right: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                meal.foodItems.isNotEmpty
                                    ? meal.foodItems.map((f) => f.name).join(', ')
                                    : 'Food',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${meal.totalCalories} kcal',
                              style: TextStyle(
                                fontSize: 11,
                                color: textMuted,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: textMuted.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getMealEmoji(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return '🍳';
      case 'lunch':
        return '🥗';
      case 'dinner':
        return '🍽️';
      case 'snack':
        return '🍎';
      default:
        return '🍴';
    }
  }

  void _showMealDetails(BuildContext context, FoodLog meal) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDarkTheme ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDarkTheme ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDarkTheme ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDarkTheme ? AppColors.teal : AppColorsLight.teal;
    final cardBorder = isDarkTheme ? AppColors.cardBorder : AppColorsLight.cardBorder;

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        maxHeightFraction: 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    _getMealEmoji(meal.mealType),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.mealType.substring(0, 1).toUpperCase() +
                              meal.mealType.substring(1),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          '${meal.totalCalories} kcal',
                          style: TextStyle(
                            fontSize: 14,
                            color: teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _copyMealTo(ctx, meal),
                    icon: Icon(Icons.content_copy, color: teal, size: 20),
                    tooltip: 'Copy to...',
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onDeleteMeal(meal.id);
                    },
                    icon: Icon(Icons.delete_outline, color: AppColors.error),
                    tooltip: 'Delete meal',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Food items list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: meal.foodItems.length,
                itemBuilder: (context, index) {
                  final food = meal.foodItems[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBorder.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _MacroChip(label: 'Cal', value: '${food.calories ?? 0}', color: teal),
                            const SizedBox(width: 8),
                            _MacroChip(label: 'P', value: '${(food.proteinG ?? 0).toStringAsFixed(0)}g', color: AppColors.purple),
                            const SizedBox(width: 8),
                            _MacroChip(label: 'C', value: '${(food.carbsG ?? 0).toStringAsFixed(0)}g', color: AppColors.orange),
                            const SizedBox(width: 8),
                            _MacroChip(label: 'F', value: '${(food.fatG ?? 0).toStringAsFixed(0)}g', color: AppColors.error),
                          ],
                        ),
                        if (food.amount != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Amount: ${food.amount}',
                            style: TextStyle(
                              fontSize: 11,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            // Macros summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: cardBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MacroSummary(
                    label: 'Protein',
                    value: '${meal.proteinG.toStringAsFixed(0)}g',
                    color: AppColors.purple,
                    isDark: isDarkTheme,
                  ),
                  _MacroSummary(
                    label: 'Carbs',
                    value: '${meal.carbsG.toStringAsFixed(0)}g',
                    color: AppColors.orange,
                    isDark: isDarkTheme,
                  ),
                  _MacroSummary(
                    label: 'Fat',
                    value: '${meal.fatG.toStringAsFixed(0)}g',
                    color: AppColors.error,
                    isDark: isDarkTheme,
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _copyMealTo(BuildContext sheetContext, FoodLog meal) {
    final isDarkTheme = Theme.of(sheetContext).brightness == Brightness.dark;
    final elevated = isDarkTheme ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDarkTheme ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final teal = isDarkTheme ? AppColors.teal : AppColorsLight.teal;

    final mealTypes = [
      {'id': 'breakfast', 'label': 'Breakfast', 'emoji': '\u{1F373}'},
      {'id': 'lunch', 'label': 'Lunch', 'emoji': '\u{2600}\u{FE0F}'},
      {'id': 'dinner', 'label': 'Dinner', 'emoji': '\u{1F319}'},
      {'id': 'snack', 'label': 'Snack', 'emoji': '\u{1F34E}'},
    ];

    showGlassSheet(
      context: sheetContext,
      builder: (ctx) => GlassSheet(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Copy to...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...mealTypes.map((type) => ListTile(
                leading: Text(type['emoji']!, style: const TextStyle(fontSize: 20)),
                title: Text(
                  type['label']!,
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                tileColor: meal.mealType == type['id'] ? teal.withOpacity(0.1) : null,
                trailing: meal.mealType == type['id']
                    ? Text('Current', style: TextStyle(fontSize: 12, color: teal))
                    : null,
                onTap: () {
                  Navigator.pop(ctx);       // close picker
                  Navigator.pop(sheetContext); // close meal details
                  onCopyMeal(meal.id, type['id']!);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget for macro chips in meal details
class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// Helper widget for macro summary in meal details
class _MacroSummary extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MacroSummary({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Compact Energy Header - Horizontal bar with progress + quick add
// ─────────────────────────────────────────────────────────────────

class _CompactEnergyHeader extends StatelessWidget {
  final int consumed;
  final int target;
  final VoidCallback onQuickAdd;
  final bool isDark;
  final bool calmMode;
  final DailyNutritionSummary? summary;
  final NutritionTargets? targets;
  final DynamicNutritionTargets? dynamicTargets;
  final VoidCallback? onMacrosTap;

  const _CompactEnergyHeader({
    required this.consumed,
    required this.target,
    required this.onQuickAdd,
    required this.isDark,
    this.calmMode = false,
    this.summary,
    this.targets,
    this.dynamicTargets,
    this.onMacrosTap,
  });

  int get remaining => target - consumed;
  double get percentage => (consumed / target).clamp(0.0, 1.5);
  bool get isOver => consumed > target;

  @override
  Widget build(BuildContext context) {
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final overColor = isDark ? AppColors.orange : AppColorsLight.orange;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final progressColor = calmMode ? purple : (isOver ? overColor : teal);

    // Calm mode shows a simpler mindful display
    if (calmMode) {
      return _buildCalmModeHeader(
        elevated: elevated,
        textPrimary: textPrimary,
        textMuted: textMuted,
        progressColor: purple,
        glassSurface: glassSurface,
        cardBorder: cardBorder,
        teal: teal,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: progressColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Main row: Eaten | Progress | Remaining | Quick Add
          Row(
            children: [
              // Eaten
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$consumed',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                    Text(
                      'eaten',
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Center: Visual progress indicator
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: percentage.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: glassSurface,
                        color: progressColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(percentage * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Remaining - More prominent with label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isOver ? 'OVER' : 'REMAINING',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      isOver ? '+${consumed - target}' : '$remaining',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isOver ? overColor : teal,
                      ),
                    ),
                    Text(
                      'kcal',
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Quick Add Button - More prominent with label
              Material(
                color: teal,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onQuickAdd,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Log',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Goal label
          Text(
            'Goal: $target kcal',
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
            ),
          ),
          // Compact macro targets row
          if (summary != null || targets != null) ...[
            const SizedBox(height: 12),
            CompactMacroTargets(
              summary: summary,
              targets: targets,
              dynamicTargets: dynamicTargets,
              isDark: isDark,
              onTap: onMacrosTap,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalmModeHeader({
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color progressColor,
    required Color glassSurface,
    required Color cardBorder,
    required Color teal,
  }) {
    // Determine the message based on how much was eaten
    final String message;
    final IconData icon;

    if (consumed == 0) {
      message = "Ready to nourish";
      icon = Icons.wb_sunny_rounded;
    } else if (percentage < 0.5) {
      message = "Taking it easy";
      icon = Icons.spa_rounded;
    } else if (percentage >= 0.5 && percentage < 0.85) {
      message = "Nourishing well";
      icon = Icons.favorite_rounded;
    } else if (percentage >= 0.85 && percentage <= 1.1) {
      message = "Well balanced";
      icon = Icons.check_circle_rounded;
    } else {
      message = "Enjoying food";
      icon = Icons.restaurant_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: progressColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: progressColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: progressColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: glassSurface,
                    color: progressColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Quick Add Button - More prominent with label
          Material(
            color: teal,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onQuickAdd,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Log',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// View Analytics Section - Expandable section for analytics cards
// ─────────────────────────────────────────────────────────────────

class _ViewAnalyticsSection extends StatefulWidget {
  final String userId;
  final bool isDark;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpandChanged;

  const _ViewAnalyticsSection({
    required this.userId,
    required this.isDark,
    this.initiallyExpanded = false,
    this.onExpandChanged,
  });

  @override
  State<_ViewAnalyticsSection> createState() => _ViewAnalyticsSectionState();
}

class _ViewAnalyticsSectionState extends State<_ViewAnalyticsSection>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      widget.onExpandChanged?.call(_isExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    final elevated = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;

    return Column(
      children: [
        // Expandable Header
        Material(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      color: teal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analytics & Insights',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Streak, weight, check-in, metrics',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: _iconTurns,
                    child: Icon(
                      Icons.expand_more,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Expandable Content
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                // Nutrition Streak Card
                _NutritionStreakCard(
                  userId: widget.userId,
                  isDark: widget.isDark,
                ),

                const SizedBox(height: 12),

                // Weight Tracking Card
                _WeightTrackingCard(
                  userId: widget.userId,
                  isDark: widget.isDark,
                ),

                const SizedBox(height: 12),

                // Weekly Check-in Card (Adaptive TDEE)
                _WeeklyCheckinCard(
                  userId: widget.userId,
                  isDark: widget.isDark,
                ),

                const SizedBox(height: 12),

                // Health Metrics Card (Blood Glucose & Insulin)
                HealthMetricsCard(
                  isDark: widget.isDark,
                ),

                const SizedBox(height: 12),

                // Food & Mood Analytics Card
                FoodMoodAnalyticsCard(
                  userId: widget.userId,
                  isDark: widget.isDark,
                ),
              ],
            ),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Quick Log Button - Prominent button to log food
// ─────────────────────────────────────────────────────────────────

class _QuickLogButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _QuickLogButton({
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Material(
      color: teal,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_outline,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Log Food',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Quick Favorites Bar - Horizontal scrollable favorites
// ─────────────────────────────────────────────────────────────────

class _QuickFavoritesBar extends StatelessWidget {
  final List<SavedFood> favorites;
  final bool isLoading;
  final void Function(SavedFood) onTap;
  final bool isDark;

  const _QuickFavoritesBar({
    required this.favorites,
    required this.isLoading,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.star, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              'QUICK ADD',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Scrollable chips
        if (isLoading)
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, __) => Container(
                width: 100,
                height: 44,
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: favorites.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final food = favorites[index];
                return _FavoriteChip(
                  food: food,
                  onTap: () => onTap(food),
                  isDark: isDark,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _FavoriteChip extends StatelessWidget {
  final SavedFood food;
  final VoidCallback onTap;
  final bool isDark;

  const _FavoriteChip({
    required this.food,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Truncate name if too long
    final displayName = food.name.length > 15
        ? '${food.name.substring(0, 12)}...'
        : food.name;

    return Material(
      color: elevated,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16, color: teal),
              const SizedBox(width: 6),
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              if (food.totalCalories != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${food.totalCalories}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: teal,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Energy Balance Card (MacroFactor style: Goal - Food = Remaining)
// ─────────────────────────────────────────────────────────────────

class _EnergyBalanceCard extends StatelessWidget {
  final int consumed;
  final int target;
  final bool isDark;
  final bool calmMode;

  const _EnergyBalanceCard({
    required this.consumed,
    required this.target,
    required this.isDark,
    this.calmMode = false,
  });

  int get remaining => target - consumed;
  double get percentage => (consumed / target).clamp(0.0, 1.5);
  bool get isOver => consumed > target;

  @override
  Widget build(BuildContext context) {
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    // Use soft orange instead of coral/red for over-target (non-judgmental)
    final overColor = isDark ? AppColors.orange : AppColorsLight.orange;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    final progressColor = calmMode ? purple : (isOver ? overColor : teal);

    // Calm mode shows a mindful message instead of numbers
    if (calmMode) {
      return _buildCalmModeCard(
        elevated: elevated,
        textPrimary: textPrimary,
        textMuted: textMuted,
        progressColor: progressColor,
        glassSurface: glassSurface,
        purple: purple,
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: progressColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Formula Row: Goal - Food = Remaining
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FormulaItem(
                value: target.toString(),
                label: 'Goal',
                isDark: isDark,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '-',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textMuted,
                  ),
                ),
              ),
              _FormulaItem(
                value: consumed.toString(),
                label: 'Food',
                valueColor: progressColor,
                isDark: isDark,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '=',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textMuted,
                  ),
                ),
              ),
              _FormulaItem(
                value: isOver ? '+${consumed - target}' : remaining.toString(),
                label: isOver ? 'Over' : 'Left',
                valueColor: isOver ? overColor : teal,
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: glassSurface,
              color: progressColor,
            ),
          ),

          const SizedBox(height: 8),

          // Percentage label
          Text(
            '${(percentage * 100).toInt()}% of daily goal',
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalmModeCard({
    required Color elevated,
    required Color textPrimary,
    required Color textMuted,
    required Color progressColor,
    required Color glassSurface,
    required Color purple,
  }) {
    // Determine the message based on how much was eaten
    final String message;
    final IconData icon;

    if (consumed == 0) {
      message = "Ready to nourish your body today";
      icon = Icons.wb_sunny_rounded;
    } else if (percentage < 0.5) {
      message = "You're taking it easy today";
      icon = Icons.spa_rounded;
    } else if (percentage >= 0.5 && percentage < 0.85) {
      message = "Nourishing your body well";
      icon = Icons.favorite_rounded;
    } else if (percentage >= 0.85 && percentage <= 1.1) {
      message = "Well balanced today";
      icon = Icons.check_circle_rounded;
    } else {
      message = "Enjoying your food today";
      icon = Icons.restaurant_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Calm Mode Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: purple.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: purple),
          ),
          const SizedBox(height: 16),

          // Mindful message
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Focus on how food makes you feel',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: textMuted,
            ),
          ),

          const SizedBox(height: 20),

          // Gentle progress bar (no numbers)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: glassSurface,
              color: purple,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormulaItem extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;
  final bool isDark;

  const _FormulaItem({
    required this.value,
    required this.label,
    this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: valueColor ?? textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Macros Row - 4 compact macro cards
// ─────────────────────────────────────────────────────────────────

class _MacrosRow extends StatelessWidget {
  final DailyNutritionSummary? summary;
  final NutritionTargets? targets;
  final bool isDark;
  final bool calmMode;

  const _MacrosRow({
    this.summary,
    this.targets,
    required this.isDark,
    this.calmMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final coral = isDark ? AppColors.coral : AppColorsLight.coral;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Row(
      children: [
        Expanded(
          child: _CompactMacroCard(
            label: 'Protein',
            current: summary?.totalProteinG ?? 0,
            target: targets?.dailyProteinTargetG ?? 150,
            color: purple,
            unit: 'g',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CompactMacroCard(
            label: 'Carbs',
            current: summary?.totalCarbsG ?? 0,
            target: targets?.dailyCarbsTargetG ?? 250,
            color: orange,
            unit: 'g',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CompactMacroCard(
            label: 'Fat',
            current: summary?.totalFatG ?? 0,
            target: targets?.dailyFatTargetG ?? 70,
            color: coral,
            unit: 'g',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CompactMacroCard(
            label: 'Fiber',
            current: summary?.totalFiberG ?? 0,
            target: 30,
            color: cyan,
            unit: 'g',
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _CompactMacroCard extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;
  final String unit;
  final bool isDark;

  const _CompactMacroCard({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.unit,
    required this.isDark,
  });

  double get percentage => (current / target).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${current.toInt()}$unit',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 4,
              backgroundColor: glassSurface,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '/${target.toInt()}$unit',
            style: TextStyle(
              fontSize: 10,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Pinned Nutrients Card
// ─────────────────────────────────────────────────────────────────

class _PinnedNutrientsCard extends StatefulWidget {
  final List<NutrientProgress> pinned;
  final bool isDark;
  final VoidCallback? onEdit;

  const _PinnedNutrientsCard({
    required this.pinned,
    required this.isDark,
    this.onEdit,
  });

  @override
  State<_PinnedNutrientsCard> createState() => _PinnedNutrientsCardState();
}

class _PinnedNutrientsCardState extends State<_PinnedNutrientsCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final elevated =
        widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final textMuted =
        widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - always visible, tappable
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                Text(
                  'PINNED NUTRIENTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.pinned.length}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: teal,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onEdit,
                  icon: Icon(Icons.edit, size: 14, color: textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Edit Pinned Nutrients',
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: textMuted,
                ),
              ],
            ),
          ),
          // Expandable chips
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.pinned.map((nutrient) {
                  return _PinnedNutrientChip(
                    nutrient: nutrient,
                    isDark: widget.isDark,
                  );
                }).toList(),
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _PinnedNutrientChip extends StatelessWidget {
  final NutrientProgress nutrient;
  final bool isDark;

  const _PinnedNutrientChip({
    required this.nutrient,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final color = Color(
        int.parse(nutrient.progressColor.replaceFirst('#', '0xFF')));
    final percentage = nutrient.percentage.clamp(0.0, 100.0);

    return Container(
      width: 68,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nutrient name
          Text(
            nutrient.displayName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: elevated,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          // Current / Target + Unit combined
          Text(
            '${nutrient.formattedCurrent}/${nutrient.formattedTarget} ${nutrient.unit}',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Meal Sections - Collapsible by meal type
// ─────────────────────────────────────────────────────────────────

class _MealSections extends StatelessWidget {
  final List<FoodLog> meals;
  final VoidCallback onLogMeal;
  final void Function(String) onDeleteMeal;
  final bool isDark;
  final String userId;
  final VoidCallback onFoodSaved;

  const _MealSections({
    required this.meals,
    required this.onLogMeal,
    required this.onDeleteMeal,
    required this.isDark,
    required this.userId,
    required this.onFoodSaved,
  });

  @override
  Widget build(BuildContext context) {
    // Group meals by type
    final mealsByType = <MealType, List<FoodLog>>{};
    for (final type in MealType.values) {
      mealsByType[type] = meals
          .where((m) => m.mealType == type.value)
          .toList();
    }

    return Column(
      children: MealType.values.map((type) {
        final typeMeals = mealsByType[type] ?? [];
        final totalCalories =
            typeMeals.fold<int>(0, (sum, m) => sum + m.totalCalories);

        return _CollapsibleMealSection(
          mealType: type,
          meals: typeMeals,
          totalCalories: totalCalories,
          onLogMeal: onLogMeal,
          onDeleteMeal: onDeleteMeal,
          isDark: isDark,
          userId: userId,
          onFoodSaved: onFoodSaved,
        );
      }).toList(),
    );
  }
}

class _CollapsibleMealSection extends StatefulWidget {
  final MealType mealType;
  final List<FoodLog> meals;
  final int totalCalories;
  final VoidCallback onLogMeal;
  final void Function(String) onDeleteMeal;
  final bool isDark;
  final String userId;
  final VoidCallback onFoodSaved;

  const _CollapsibleMealSection({
    required this.mealType,
    required this.meals,
    required this.totalCalories,
    required this.onLogMeal,
    required this.onDeleteMeal,
    required this.isDark,
    required this.userId,
    required this.onFoodSaved,
  });

  @override
  State<_CollapsibleMealSection> createState() =>
      _CollapsibleMealSectionState();
}

class _CollapsibleMealSectionState extends State<_CollapsibleMealSection> {
  bool _isExpanded = true;

  void _showFoodDetail(FoodLog meal) {
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: _FoodDetailSheet(
          meal: meal,
          userId: widget.userId,
          isDark: widget.isDark,
          onSaved: widget.onFoodSaved,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final elevated =
        widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted =
        widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final cardBorder =
        widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    widget.mealType.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.mealType.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (widget.totalCalories > 0)
                    Text(
                      '${widget.totalCalories} kcal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: teal,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: textMuted,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (_isExpanded) ...[
            if (widget.meals.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GestureDetector(
                  onTap: widget.onLogMeal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: teal.withOpacity(0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 20, color: teal),
                        const SizedBox(width: 8),
                        Text(
                          'Add Food',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...widget.meals.map((meal) => _MealItem(
                    meal: meal,
                    onDelete: () => widget.onDeleteMeal(meal.id),
                    isDark: widget.isDark,
                    onTap: () => _showFoodDetail(meal),
                  )),
          ],
        ],
      ),
    );
  }
}

class _MealItem extends StatelessWidget {
  final FoodLog meal;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final bool isDark;

  const _MealItem({
    required this.meal,
    required this.onDelete,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final coral = isDark ? AppColors.coral : AppColorsLight.coral;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    final time =
        '${meal.loggedAt.hour.toString().padLeft(2, '0')}:${meal.loggedAt.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: Key(meal.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: isDark ? AppColors.error : AppColorsLight.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food items list
              ...meal.foodItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 14,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        if (item.amount != null)
                          Text(
                            item.amount!,
                            style: TextStyle(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.calories ?? 0}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: teal,
                          ),
                        ),
                      ],
                    ),
                  )),

              // Macro chips + tap hint
              Row(
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.touch_app, size: 12, color: textMuted.withValues(alpha: 0.5)),
                  const Spacer(),
                  _MiniMacroChip(
                    label: 'P',
                    value: meal.proteinG,
                    color: purple,
                  ),
                  const SizedBox(width: 6),
                  _MiniMacroChip(
                    label: 'C',
                    value: meal.carbsG,
                    color: orange,
                  ),
                  const SizedBox(width: 6),
                  _MiniMacroChip(
                    label: 'F',
                    value: meal.fatG,
                    color: coral,
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

class _MiniMacroChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MiniMacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: ${value.toInt()}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Food Detail Sheet (shown when tapping a logged meal)
// ─────────────────────────────────────────────────────────────────

class _FoodDetailSheet extends ConsumerStatefulWidget {
  final FoodLog meal;
  final String userId;
  final bool isDark;
  final VoidCallback onSaved;

  const _FoodDetailSheet({
    required this.meal,
    required this.userId,
    required this.isDark,
    required this.onSaved,
  });

  @override
  ConsumerState<_FoodDetailSheet> createState() => _FoodDetailSheetState();
}

class _FoodDetailSheetState extends ConsumerState<_FoodDetailSheet> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final elevated =
        widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted =
        widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        widget.isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final purple = widget.isDark ? AppColors.purple : AppColorsLight.purple;
    final orange = widget.isDark ? AppColors.orange : AppColorsLight.orange;
    final coral = widget.isDark ? AppColors.coral : AppColorsLight.coral;
    final cardBorder =
        widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final time =
        '${widget.meal.loggedAt.hour.toString().padLeft(2, '0')}:${widget.meal.loggedAt.minute.toString().padLeft(2, '0')}';
    final dateStr = DateFormat('MMM d, y').format(widget.meal.loggedAt);

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  MealType.fromValue(widget.meal.mealType).emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        MealType.fromValue(widget.meal.mealType)
                            .label
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '$dateStr at $time',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Calories badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: teal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.meal.totalCalories} kcal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: teal,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // Food items list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'ITEMS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...widget.meal.foodItems.map((item) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? AppColors.glassSurface
                        : AppColorsLight.glassSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                            if (item.amount != null)
                              Text(
                                item.amount!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${item.calories ?? 0} cal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: teal,
                        ),
                      ),
                    ],
                  ),
                ),
              )),

          const SizedBox(height: 16),

          // Macros section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'MACROS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _MacroDetailChip(
                  label: 'Protein',
                  value: widget.meal.proteinG,
                  color: purple,
                  isDark: widget.isDark,
                ),
                const SizedBox(width: 8),
                _MacroDetailChip(
                  label: 'Carbs',
                  value: widget.meal.carbsG,
                  color: orange,
                  isDark: widget.isDark,
                ),
                const SizedBox(width: 8),
                _MacroDetailChip(
                  label: 'Fat',
                  value: widget.meal.fatG,
                  color: coral,
                  isDark: widget.isDark,
                ),
                if (widget.meal.fiberG != null) ...[
                  const SizedBox(width: 8),
                  _MacroDetailChip(
                    label: 'Fiber',
                    value: widget.meal.fiberG!,
                    color: AppColors.success,
                    isDark: widget.isDark,
                  ),
                ],
              ],
            ),
          ),

          // Health score if available
          if (widget.meal.healthScore != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getScoreColor(widget.meal.healthScore!)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _getScoreColor(widget.meal.healthScore!)
                        .withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.eco_outlined,
                      color: _getScoreColor(widget.meal.healthScore!),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Health Score',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.meal.healthScore}/10',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(widget.meal.healthScore!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // AI Feedback if available
          if (widget.meal.aiFeedback != null &&
              widget.meal.aiFeedback!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: AppColors.cyan,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.meal.aiFeedback!,
                        style: TextStyle(
                          fontSize: 13,
                          color: textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Save to favorites button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveToFavorites,
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isSaving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      )
                    : const Icon(Icons.bookmark_add_outlined, size: 20),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save to Favorites',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // Extra bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 8) return AppColors.success;
    if (score >= 5) return AppColors.warning;
    return AppColors.error;
  }

  Future<void> _saveToFavorites() async {
    setState(() => _isSaving = true);

    try {
      final repository = ref.read(nutritionRepositoryProvider);
      final request = SaveFoodRequest.fromFoodLog(widget.meal);

      await repository.saveFood(
        userId: widget.userId,
        request: request,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved to favorites!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}

class _MacroDetailChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isDark;

  const _MacroDetailChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '${value.toInt()}g',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool isDark;

  const _GoalRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            unit,
            style: TextStyle(
              fontSize: 13,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Recipes Tab
// ─────────────────────────────────────────────────────────────────

class _RecipesTab extends StatelessWidget {
  final String userId;
  final List<RecipeSummary> recipes;
  final VoidCallback onCreateRecipe;
  final void Function(RecipeSummary) onLogRecipe;
  final VoidCallback onRefresh;
  final bool isDark;

  const _RecipesTab({
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
              // Extra bottom padding for floating nav bar
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: recipes.length + 1, // +1 for create button
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Create recipe button at top
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
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
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
                // Recipe emoji/icon
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
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
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
              child: Icon(
                Icons.restaurant_menu,
                size: 40,
                color: teal,
              ),
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
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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

// ─────────────────────────────────────────────────────────────────
// Loading Skeleton
// ─────────────────────────────────────────────────────────────────

class _NutritionLoadingSkeleton extends StatelessWidget {
  final bool isDark;

  const _NutritionLoadingSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final shimmerBase = isDark
        ? AppColors.elevated.withValues(alpha: 0.6)
        : AppColorsLight.elevated;
    final shimmerHighlight = isDark
        ? AppColors.glassSurface.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.5);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Energy card skeleton with shimmer
          _ShimmerContainer(
            height: 140,
            borderRadius: 20,
            baseColor: shimmerBase,
            highlightColor: shimmerHighlight,
          ),
          const SizedBox(height: 16),
          // Macros row skeleton with staggered shimmer
          Row(
            children: List.generate(
              4,
              (index) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ShimmerContainer(
                    height: 100,
                    borderRadius: 12,
                    baseColor: shimmerBase,
                    highlightColor: shimmerHighlight,
                    delay: Duration(milliseconds: index * 100),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Meal sections skeleton with staggered shimmer
          ...List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ShimmerContainer(
                height: 60,
                borderRadius: 16,
                baseColor: shimmerBase,
                highlightColor: shimmerHighlight,
                delay: Duration(milliseconds: 400 + index * 100),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer container with smooth animation
class _ShimmerContainer extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;
  final Duration delay;

  const _ShimmerContainer({
    required this.height,
    this.width,
    required this.borderRadius,
    required this.baseColor,
    required this.highlightColor,
    this.delay = Duration.zero,
  });

  @override
  State<_ShimmerContainer> createState() => _ShimmerContainerState();
}

class _ShimmerContainerState extends State<_ShimmerContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Start with delay for staggered effect
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Error State
// ─────────────────────────────────────────────────────────────────

class _NutritionErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final bool isDark;

  const _NutritionErrorState({
    required this.error,
    required this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final errorColor = isDark ? AppColors.error : AppColorsLight.error;

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
                color: errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to load nutrition data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                backgroundColor: errorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
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


// ─────────────────────────────────────────────────────────────────
// Weight Tracking Card
// ─────────────────────────────────────────────────────────────────

class _WeightTrackingCard extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;

  const _WeightTrackingCard({
    required this.userId,
    required this.isDark,
  });

  @override
  ConsumerState<_WeightTrackingCard> createState() => _WeightTrackingCardState();
}

class _WeightTrackingCardState extends ConsumerState<_WeightTrackingCard> {
  final _weightController = TextEditingController();
  bool _isLogging = false;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _logWeight() async {
    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) return;

    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0 || weight > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid weight'),
          backgroundColor: widget.isDark ? AppColors.error : AppColorsLight.error,
        ),
      );
      return;
    }

    setState(() => _isLogging = true);
    try {
      await ref.read(nutritionPreferencesProvider.notifier).logWeight(
            userId: widget.userId,
            weightKg: weight,
          );

      if (mounted) {
        _weightController.clear();
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Weight logged: ${weight.toStringAsFixed(1)} kg'),
            backgroundColor:
                widget.isDark ? AppColors.success : AppColorsLight.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log weight: $e'),
            backgroundColor: widget.isDark ? AppColors.error : AppColorsLight.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLogging = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefsState = ref.watch(nutritionPreferencesProvider);
    final latestWeight = prefsState.latestWeight;
    final weightTrend = prefsState.weightTrend;

    final elevated = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final cardBorder =
        widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Determine trend icon and color
    IconData trendIcon;
    Color trendColor;
    String trendText;

    if (weightTrend != null) {
      switch (weightTrend.direction) {
        case 'losing':
          trendIcon = Icons.trending_down;
          trendColor = Colors.green;
          trendText = '${weightTrend.weeklyRateKg?.abs().toStringAsFixed(2) ?? '0'} kg/week';
          break;
        case 'gaining':
          trendIcon = Icons.trending_up;
          trendColor = Colors.orange;
          trendText = '+${weightTrend.weeklyRateKg?.toStringAsFixed(2) ?? '0'} kg/week';
          break;
        default:
          trendIcon = Icons.trending_flat;
          trendColor = textMuted;
          trendText = 'Stable';
      }
    } else {
      trendIcon = Icons.trending_flat;
      trendColor = textMuted;
      trendText = 'Log weight to see trend';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.monitor_weight_outlined, color: teal, size: 24),
              const SizedBox(width: 12),
              Text(
                'Weight',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              if (latestWeight != null)
                Text(
                  '${latestWeight.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Trend indicator
          Row(
            children: [
              Icon(trendIcon, color: trendColor, size: 20),
              const SizedBox(width: 8),
              Text(
                trendText,
                style: TextStyle(
                  fontSize: 13,
                  color: trendColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Mini Weight Chart (if we have history data)
          if (prefsState.weightHistory.length >= 2) ...[
            const SizedBox(height: 16),
            _MiniWeightChart(
              weightHistory: prefsState.weightHistory,
              isDark: widget.isDark,
              trendColor: trendColor,
            ),
          ],

          const SizedBox(height: 16),

          // Quick log row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Enter weight (kg)',
                    hintStyle: TextStyle(color: textMuted),
                    filled: true,
                    fillColor: widget.isDark
                        ? AppColors.pureBlack
                        : AppColorsLight.pureWhite,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: teal, width: 2),
                    ),
                  ),
                  onSubmitted: (_) => _logWeight(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _isLogging ? null : _logWeight,
                  style: FilledButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: _isLogging
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Log'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Nutrition Streak Card
// ─────────────────────────────────────────────────────────────────

class _NutritionStreakCard extends ConsumerWidget {
  final String userId;
  final bool isDark;

  const _NutritionStreakCard({required this.userId, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(nutritionStreakProvider);

    if (streak == null) return const SizedBox.shrink();

    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    // Determine streak color based on streak length
    final streakColor = streak.currentStreakDays >= 7
        ? orange
        : streak.currentStreakDays >= 3
            ? teal
            : purple;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Streak fire/badge icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: streakColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: streakColor.withValues(alpha: 0.3)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      streak.currentStreakDays >= 7
                          ? Icons.local_fire_department
                          : Icons.emoji_events,
                      size: 28,
                      color: streakColor,
                    ),
                    if (streak.currentStreakDays > 0)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: streakColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${streak.currentStreakDays}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Streak info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${streak.currentStreakDays} Day Streak',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        if (streak.currentStreakDays >= streak.longestStreakEver &&
                            streak.currentStreakDays > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'BEST',
                              style: TextStyle(
                                color: orange,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      streak.weeklyGoalEnabled
                          ? '${streak.daysLoggedThisWeek}/${streak.weeklyGoalDays} days this week'
                          : 'Best: ${streak.longestStreakEver} days',
                      style: TextStyle(fontSize: 13, color: textMuted),
                    ),
                  ],
                ),
              ),

              // Streak freezes
              if (streak.freezesAvailable > 0)
                Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        2,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            index < streak.freezesAvailable
                                ? Icons.ac_unit
                                : Icons.ac_unit_outlined,
                            size: 18,
                            color: index < streak.freezesAvailable
                                ? textPrimary
                                : textMuted.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Freezes',
                      style: TextStyle(fontSize: 10, color: textMuted),
                    ),
                  ],
                ),
            ],
          ),

          // Weekly goal progress (if enabled)
          if (streak.weeklyGoalEnabled) ...[
            const SizedBox(height: 16),
            _WeeklyGoalProgress(
              daysLogged: streak.daysLoggedThisWeek,
              goalDays: streak.weeklyGoalDays,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyGoalProgress extends StatelessWidget {
  final int daysLogged;
  final int goalDays;
  final bool isDark;

  const _WeeklyGoalProgress({
    required this.daysLogged,
    required this.goalDays,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final isGoalMet = daysLogged >= goalDays;
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday; // 1 = Monday

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Weekly Goal',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
            if (isGoalMet)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 14, color: teal),
                  const SizedBox(width: 4),
                  Text(
                    'Complete!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: teal,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final dayNumber = index + 1;
            final isToday = dayNumber == today;
            final isLogged = index < daysLogged; // Simplified - in real app, check actual logged days

            return Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isLogged
                        ? teal.withValues(alpha: 0.2)
                        : elevated,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isToday
                          ? teal
                          : isLogged
                              ? teal.withValues(alpha: 0.5)
                              : textMuted.withValues(alpha: 0.2),
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: isLogged
                        ? Icon(Icons.check, size: 16, color: teal)
                        : Text(
                            weekDays[index],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isToday ? teal : textMuted,
                            ),
                          ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Weekly Check-in Card - Shows adaptive TDEE and prompts check-in
// ─────────────────────────────────────────────────────────────────

class _WeeklyCheckinCard extends ConsumerWidget {
  final String userId;
  final bool isDark;

  const _WeeklyCheckinCard({required this.userId, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsState = ref.watch(nutritionPreferencesProvider);
    final adaptiveCalc = prefsState.adaptiveCalculation;

    // Show different states based on data availability
    final hasEnoughData = adaptiveCalc != null && adaptiveCalc.daysLogged >= 7;

    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (hasEnoughData ? teal : purple).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasEnoughData ? Icons.insights : Icons.trending_up,
                  color: hasEnoughData ? teal : purple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasEnoughData ? 'Weekly Check-in' : 'Adaptive Targets',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getSubtitle(adaptiveCalc),
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // TDEE Info (if available)
          if (adaptiveCalc != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _TdeeInfoItem(
                    label: 'Calculated TDEE',
                    value: '${adaptiveCalc.calculatedTdee}',
                    unit: 'cal',
                    color: teal,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: textMuted.withValues(alpha: 0.2),
                  ),
                  _TdeeInfoItem(
                    label: 'Data Quality',
                    value: '${(adaptiveCalc.dataQualityScore * 100).round()}%',
                    unit: '',
                    color: adaptiveCalc.dataQualityScore >= 0.7
                        ? teal
                        : adaptiveCalc.dataQualityScore >= 0.4
                            ? orange
                            : textMuted,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                ],
              ),
            ),
          ],

          // Check-in Button
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: hasEnoughData ? teal : teal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _openCheckinSheet(context, ref),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasEnoughData ? Icons.checklist : Icons.insights,
                        size: 18,
                        color: hasEnoughData ? Colors.white : teal,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasEnoughData
                            ? 'View Weekly Summary'
                            : 'View Progress',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: hasEnoughData ? Colors.white : teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSubtitle(AdaptiveCalculation? calc) {
    if (calc != null) {
      if (calc.daysLogged >= 7) {
        return 'TDEE calculated from ${calc.daysLogged} days of data';
      }
      return '${7 - calc.daysLogged} more days until adaptive targets';
    }
    return 'Track for 7+ days to unlock adaptive targets';
  }

  void _openCheckinSheet(BuildContext context, WidgetRef ref) {
    showWeeklyCheckinSheet(context, ref);
  }
}

class _TdeeInfoItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color textPrimary;
  final Color textMuted;

  const _TdeeInfoItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Mini Weight Chart - Compact trend visualization
// ─────────────────────────────────────────────────────────────────

class _MiniWeightChart extends StatelessWidget {
  final List<WeightLog> weightHistory;
  final bool isDark;
  final Color trendColor;

  const _MiniWeightChart({
    required this.weightHistory,
    required this.isDark,
    required this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    if (weightHistory.length < 2) return const SizedBox.shrink();

    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Get last 14 days of data (or less if not available)
    final recentData = weightHistory.take(14).toList().reversed.toList();

    if (recentData.isEmpty) return const SizedBox.shrink();

    // Calculate min/max for proper scaling
    final weights = recentData.map((w) => w.weightKg).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);

    // Add padding to the range
    final range = maxWeight - minWeight;
    final padding = range < 1 ? 1.0 : range * 0.2;
    final minY = minWeight - padding;
    final maxY = maxWeight + padding;

    // Create spots for the chart
    final spots = <FlSpot>[];
    for (int i = 0; i < recentData.length; i++) {
      spots.add(FlSpot(i.toDouble(), recentData[i].weightKg));
    }

    return Container(
      height: 100,
      padding: const EdgeInsets.only(right: 8),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 3,
            getDrawingHorizontalLine: (value) => FlLine(
              color: cardBorder,
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  // Only show first and last labels
                  if (value == minY || value == maxY) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(fontSize: 10, color: textMuted),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: (recentData.length / 3).ceil().toDouble().clamp(1, double.infinity),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < recentData.length) {
                    final date = recentData[index].loggedAt;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('d/M').format(date),
                        style: TextStyle(fontSize: 9, color: textMuted),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: trendColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  // Show dot only for first and last point
                  final isEndpoint = index == 0 || index == spots.length - 1;
                  return FlDotCirclePainter(
                    radius: isEndpoint ? 4 : 2,
                    color: trendColor,
                    strokeWidth: 0,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: trendColor.withValues(alpha: 0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) =>
                  isDark ? AppColors.elevated : AppColorsLight.elevated,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  final index = touchedSpot.spotIndex;
                  if (index >= 0 && index < recentData.length) {
                    final weight = recentData[index];
                    return LineTooltipItem(
                      '${weight.weightKg.toStringAsFixed(1)} kg\n${DateFormat('MMM d').format(weight.loggedAt)}',
                      TextStyle(
                        color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }
                  return null;
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedFoodsFilterSheet extends StatefulWidget {
  final String userId;
  final NutritionRepository repository;
  final bool isDark;
  final VoidCallback onFoodLogged;
  final String Function() getSuggestedMealType;

  const _SavedFoodsFilterSheet({
    required this.userId,
    required this.repository,
    required this.isDark,
    required this.onFoodLogged,
    required this.getSuggestedMealType,
  });

  @override
  State<_SavedFoodsFilterSheet> createState() => _SavedFoodsFilterSheetState();
}

class _SavedFoodsFilterSheetState extends State<_SavedFoodsFilterSheet> {
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
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value);
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

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.bookmark, color: teal, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Saved Foods',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textMuted, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
                        controller: scrollController,
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
                                      '${food.totalCalories ?? 0} kcal · P:${food.totalProteinG?.toInt() ?? 0}g · C:${food.totalCarbsG?.toInt() ?? 0}g · F:${food.totalFatG?.toInt() ?? 0}g',
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
      ),
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
