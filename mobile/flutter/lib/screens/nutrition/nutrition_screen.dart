import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/nutrition.dart';
import '../../data/models/micronutrients.dart';
import '../../data/models/nutrition_preferences.dart';
import '../../data/models/recipe.dart';
import '../../data/providers/nutrition_preferences_provider.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/services/api_client.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/nutrition/health_metrics_card.dart';
import '../../widgets/nutrition/food_mood_analytics_card.dart';
import 'log_meal_sheet.dart';
import 'nutrient_explorer.dart';
import 'nutrition_onboarding/nutrition_onboarding_screen.dart';
import 'nutrition_onboarding/nutrition_welcome_screen.dart';
import 'nutrition_settings_screen.dart';
import 'recipe_builder_sheet.dart';
import 'weekly_checkin_sheet.dart';
import 'widgets/quick_add_fab.dart';
import 'widgets/quick_add_sheet.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen>
    with SingleTickerProviderStateMixin {
  String? _userId;
  DateTime _selectedDate = DateTime.now();
  late TabController _tabController;
  DailyMicronutrientSummary? _micronutrientSummary;
  List<RecipeSummary> _recipes = [];
  bool _isLoadingMicronutrients = false;
  bool _hasCheckedOnboarding = false;
  bool _hasSkippedOnboarding = false;
  bool _onboardingJustCompleted = false;  // Guard flag to prevent redirect loop

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
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

      // Initialize nutrition preferences and check onboarding status
      await ref.read(nutritionPreferencesProvider.notifier).initialize(userId);

      // Check if onboarding is needed (only once per screen load)
      if (!_hasCheckedOnboarding) {
        _hasCheckedOnboarding = true;
        await _checkAndShowOnboarding();
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      ref.read(nutritionProvider.notifier).loadTodaySummary(userId);
      ref.read(nutritionProvider.notifier).loadTargets(userId);
      ref.read(nutritionProvider.notifier).loadRecentLogs(userId);
      _loadMicronutrients(userId, dateStr);
      _loadRecipes(userId);

      // Prefetch quick add suggestions for instant access
      ref.invalidate(quickAddSuggestionsProvider(userId));
    }
  }

  Future<void> _checkAndShowOnboarding() async {
    if (!mounted) return;

    // CRITICAL: Skip if we just completed onboarding to prevent redirect loop
    if (_onboardingJustCompleted) {
      debugPrint('⚠️ [NutritionScreen] Skipping onboarding check - just completed');
      return;
    }

    final prefsState = ref.read(nutritionPreferencesProvider);

    // Check if onboarding is complete - check both state flag and preferences object
    // This handles cases where the state flag might not be set but preferences exist
    final isOnboardingComplete = prefsState.onboardingCompleted ||
        (prefsState.preferences?.nutritionOnboardingCompleted ?? false);

    debugPrint('🥗 [NutritionScreen] Checking onboarding: stateFlag=${prefsState.onboardingCompleted}, prefsFlag=${prefsState.preferences?.nutritionOnboardingCompleted}, final=$isOnboardingComplete');

    // If onboarding not completed and not skipped, show welcome screen first
    if (!isOnboardingComplete && !_hasSkippedOnboarding) {
      debugPrint('🥗 [NutritionScreen] Onboarding not completed, showing welcome');

      // Hide floating nav bar during onboarding
      ref.read(floatingNavBarVisibleProvider.notifier).state = false;

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => _NutritionWelcomeFlow(),
        ),
      );

      // Show floating nav bar again
      if (mounted) {
        ref.read(floatingNavBarVisibleProvider.notifier).state = true;
      }

      // If onboarding was completed
      if (result == true && mounted) {
        debugPrint('✅ [NutritionScreen] Onboarding completed successfully');
        // Set guard flag BEFORE any data reload to prevent loop
        _onboardingJustCompleted = true;

        // The provider already has the correct state from completeOnboarding()
        // Just reload nutrition data without re-initializing preferences
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
        ref.read(nutritionProvider.notifier).loadTodaySummary(_userId!);
        ref.read(nutritionProvider.notifier).loadTargets(_userId!);
        ref.read(nutritionProvider.notifier).loadRecentLogs(_userId!);
        _loadMicronutrients(_userId!, dateStr);
        _loadRecipes(_userId!);

        // Trigger rebuild with the already-updated provider state
        setState(() {});
      } else if (mounted) {
        // User skipped - remember this so we don't ask again during this session
        debugPrint('⏭️ [NutritionScreen] User skipped onboarding');
        setState(() => _hasSkippedOnboarding = true);
      }
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
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        title: const Text('Food Diary'),
        centerTitle: false,
        actions: [
          // Date Navigation
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: textPrimary),
                onPressed: () => _changeDate(-1),
                visualDensity: VisualDensity.compact,
              ),
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
                      ref
                          .read(nutritionProvider.notifier)
                          .loadTodaySummary(_userId!);
                      _loadMicronutrients(_userId!, dateStr);
                    }
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: elevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _dateLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: _isToday ? textMuted : textPrimary,
                ),
                onPressed: _isToday ? null : () => _changeDate(1),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NutritionSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: teal,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: textMuted,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Daily'),
                Tab(text: 'Nutrients'),
                Tab(text: 'Recipes'),
              ],
            ),
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
                            onLogMeal: () => _showLogMealSheet(isDark),
                            onDeleteMeal: (id) => _deleteMeal(id),
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
                        ],
                      ),
          ),
        ],
      ),
      // Quick Add FAB - only visible when quickLogMode is enabled
      floatingActionButton: _userId != null
          ? QuickAddFABSimple(
              userId: _userId!,
              onMealLogged: _loadData,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _showLogMealSheet(bool isDark) async {
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

    // Hide nav bar while sheet is open
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          LogMealSheet(userId: userId!, isDark: isDark),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          RecipeBuilderSheet(userId: _userId!, isDark: isDark),
    ).then((_) {
      // Show nav bar when sheet is closed
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
      _loadRecipes(_userId!);
    });
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

    return showModalBottomSheet<MealType>(
      context: context,
      backgroundColor: nearBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
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
    );
  }

  Future<void> _deleteMeal(String mealId) async {
    if (_userId == null) return;
    await ref.read(nutritionProvider.notifier).deleteLog(_userId!, mealId);
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: nearBlack,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
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
// Daily Tab - MacroFactor-inspired layout
// ─────────────────────────────────────────────────────────────────

class _DailyTab extends ConsumerStatefulWidget {
  final String userId;
  final DailyNutritionSummary? summary;
  final NutritionTargets? targets;
  final DailyMicronutrientSummary? micronutrients;
  final VoidCallback onRefresh;
  final VoidCallback onLogMeal;
  final void Function(String) onDeleteMeal;
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

  @override
  Widget build(BuildContext context) {
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final prefsState = ref.watch(nutritionPreferencesProvider);
    final compactMode = prefsState.preferences?.compactTrackerViewEnabled ?? false;

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
                // Compact Energy Header with Quick Add (prioritized at top)
                _CompactEnergyHeader(
                  consumed: widget.summary?.totalCalories ?? 0,
                  target: widget.targets?.dailyCalorieTarget ?? 2000,
                  onQuickAdd: widget.onLogMeal,
                  isDark: widget.isDark,
                  calmMode: widget.calmMode,
                ).animate().fadeIn().scale(),

                const SizedBox(height: 16),

                // MEAL SECTIONS - MOVED TO TOP for easy logging
                _MealSections(
                  meals: widget.summary?.meals ?? [],
                  onLogMeal: widget.onLogMeal,
                  onDeleteMeal: widget.onDeleteMeal,
                  isDark: widget.isDark,
                ).animate().fadeIn(delay: 50.ms),

                const SizedBox(height: 16),

                // Quick Favorites Bar (inline with meals for quick logging)
                if (_favorites.isNotEmpty || _isLoadingFavorites) ...[
                  _QuickFavoritesBar(
                    favorites: _favorites,
                    isLoading: _isLoadingFavorites,
                    onTap: _logFavorite,
                    isDark: widget.isDark,
                  ).animate().fadeIn(delay: 75.ms),
                  const SizedBox(height: 16),
                ],

                // Macros Summary (compact row)
                if (!widget.calmMode)
                  _MacrosRow(
                    summary: widget.summary,
                    targets: widget.targets,
                    isDark: widget.isDark,
                  ).animate().fadeIn(delay: 100.ms),

                if (!widget.calmMode) const SizedBox(height: 16),

                // Pinned Micronutrients (if available)
                if (widget.micronutrients != null &&
                    widget.micronutrients!.pinned.isNotEmpty) ...[
                  _PinnedNutrientsCard(
                    pinned: widget.micronutrients!.pinned,
                    isDark: widget.isDark,
                  ).animate().fadeIn(delay: 110.ms),
                  const SizedBox(height: 16),
                ],

                // VIEW ANALYTICS - Expandable section to reduce scrolling
                _ViewAnalyticsSection(
                  userId: widget.userId,
                  isDark: widget.isDark,
                  initiallyExpanded: !compactMode && _analyticsExpanded,
                  onExpandChanged: (expanded) {
                    setState(() => _analyticsExpanded = expanded);
                  },
                ).animate().fadeIn(delay: 125.ms),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
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

  const _CompactEnergyHeader({
    required this.consumed,
    required this.target,
    required this.onQuickAdd,
    required this.isDark,
    this.calmMode = false,
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
              // Remaining
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isOver ? '+${consumed - target}' : '$remaining',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isOver ? overColor : teal,
                      ),
                    ),
                    Text(
                      isOver ? 'over' : 'left',
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
            Icon(Icons.star, size: 16, color: const Color(0xFFFFD93D)),
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

class _PinnedNutrientsCard extends StatelessWidget {
  final List<NutrientProgress> pinned;
  final bool isDark;

  const _PinnedNutrientsCard({
    required this.pinned,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const Spacer(),
              Icon(Icons.edit, size: 16, color: textMuted),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pinned.map((nutrient) {
              return _PinnedNutrientChip(
                nutrient: nutrient,
                isDark: isDark,
              );
            }).toList(),
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
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final color = Color(
        int.parse(nutrient.progressColor.replaceFirst('#', '0xFF')));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            nutrient.displayName,
            style: TextStyle(
              fontSize: 10,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${nutrient.formattedCurrent}${nutrient.unit}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 50,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (nutrient.percentage / 100).clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: glassSurface,
                color: color,
              ),
            ),
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

  const _MealSections({
    required this.meals,
    required this.onLogMeal,
    required this.onDeleteMeal,
    required this.isDark,
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

  const _CollapsibleMealSection({
    required this.mealType,
    required this.meals,
    required this.totalCalories,
    required this.onLogMeal,
    required this.onDeleteMeal,
    required this.isDark,
  });

  @override
  State<_CollapsibleMealSection> createState() =>
      _CollapsibleMealSectionState();
}

class _CollapsibleMealSectionState extends State<_CollapsibleMealSection> {
  bool _isExpanded = true;

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
  final bool isDark;

  const _MealItem({
    required this.meal,
    required this.onDelete,
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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

            // Macro chips
            Row(
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: textMuted,
                  ),
                ),
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
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Energy card skeleton
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 16),
          // Macros row skeleton
          Row(
            children: List.generate(
              4,
              (_) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 100,
                  decoration: BoxDecoration(
                    color: elevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Meal sections skeleton
          ...List.generate(
            4,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 60,
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
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
                                ? const Color(0xFF4ECDC4)
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

// ─────────────────────────────────────────────────────────────────
// Nutrition Welcome Flow (Welcome + Onboarding)
// ─────────────────────────────────────────────────────────────────

/// Combined flow that shows welcome screen first, then onboarding
class _NutritionWelcomeFlow extends StatefulWidget {
  const _NutritionWelcomeFlow();

  @override
  State<_NutritionWelcomeFlow> createState() => _NutritionWelcomeFlowState();
}

class _NutritionWelcomeFlowState extends State<_NutritionWelcomeFlow> {
  bool _showingOnboarding = false;

  @override
  Widget build(BuildContext context) {
    if (_showingOnboarding) {
      return NutritionOnboardingScreen(
        onComplete: () {
          Navigator.of(context).pop(true);
        },
        onSkip: () {
          Navigator.of(context).pop(false);
        },
      );
    }

    return NutritionWelcomeScreen(
      onGetStarted: () {
        setState(() => _showingOnboarding = true);
      },
      onSkip: () {
        Navigator.of(context).pop(false);
      },
    );
  }
}
