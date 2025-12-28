import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/nutrition.dart';
import '../../data/models/micronutrients.dart';
import '../../data/models/recipe.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/deep_link_service.dart';
import '../../widgets/main_shell.dart';
import 'log_meal_sheet.dart';
import 'nutrient_explorer.dart';
import 'recipe_builder_sheet.dart';

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
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      ref.read(nutritionProvider.notifier).loadTodaySummary(userId);
      ref.read(nutritionProvider.notifier).loadTargets(userId);
      ref.read(nutritionProvider.notifier).loadRecentLogs(userId);
      _loadMicronutrients(userId, dateStr);
      _loadRecipes(userId);
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
            onPressed: () => _showTargetsSettings(context, isDark),
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
    );
  }

  void _showLogMealSheet(bool isDark) {
    // Hide nav bar while sheet is open
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          LogMealSheet(userId: _userId ?? '', isDark: isDark),
    ).then((_) {
      // Show nav bar when sheet is closed
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
      _loadData();
    });
  }

  void _showRecipeBuilder(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          RecipeBuilderSheet(userId: _userId ?? '', isDark: isDark),
    ).then((_) {
      if (_userId != null) {
        _loadRecipes(_userId!);
      }
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

  const _DailyTab({
    required this.userId,
    this.summary,
    this.targets,
    this.micronutrients,
    required this.onRefresh,
    required this.onLogMeal,
    required this.onDeleteMeal,
    required this.isDark,
  });

  @override
  ConsumerState<_DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends ConsumerState<_DailyTab> {
  List<SavedFood> _favorites = [];
  bool _isLoadingFavorites = false;

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

    return RefreshIndicator(
      onRefresh: () async {
        await _loadFavorites();
        widget.onRefresh();
      },
      color: teal,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Energy Balance Card (MacroFactor style)
            _EnergyBalanceCard(
              consumed: widget.summary?.totalCalories ?? 0,
              target: widget.targets?.dailyCalorieTarget ?? 2000,
              isDark: widget.isDark,
            ).animate().fadeIn().scale(),

            const SizedBox(height: 16),

            // Macronutrient Cards Row
            _MacrosRow(
              summary: widget.summary,
              targets: widget.targets,
              isDark: widget.isDark,
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 16),

            // Quick Log Button
            _QuickLogButton(
              onTap: widget.onLogMeal,
              isDark: widget.isDark,
            ).animate().fadeIn(delay: 125.ms),

            const SizedBox(height: 16),

            // Pinned Micronutrients (if available)
            if (widget.micronutrients != null &&
                widget.micronutrients!.pinned.isNotEmpty) ...[
              _PinnedNutrientsCard(
                pinned: widget.micronutrients!.pinned,
                isDark: widget.isDark,
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 16),
            ],

            // Quick Favorites Bar
            if (_favorites.isNotEmpty || _isLoadingFavorites) ...[
              _QuickFavoritesBar(
                favorites: _favorites,
                isLoading: _isLoadingFavorites,
                onTap: _logFavorite,
                isDark: widget.isDark,
              ).animate().fadeIn(delay: 175.ms),
              const SizedBox(height: 16),
            ],

            // Meal Sections
            _MealSections(
              meals: widget.summary?.meals ?? [],
              onLogMeal: widget.onLogMeal,
              onDeleteMeal: widget.onDeleteMeal,
              isDark: widget.isDark,
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 100),
          ],
        ),
      ),
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
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

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

  const _EnergyBalanceCard({
    required this.consumed,
    required this.target,
    required this.isDark,
  });

  int get remaining => target - consumed;
  double get percentage => (consumed / target).clamp(0.0, 1.5);
  bool get isOver => consumed > target;

  @override
  Widget build(BuildContext context) {
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final coral = isDark ? AppColors.coral : AppColorsLight.coral;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    final progressColor = isOver ? coral : teal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: progressColor.withOpacity(0.3)),
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
                valueColor: isOver ? coral : teal,
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

  const _MacrosRow({this.summary, this.targets, required this.isDark});

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
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
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
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

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
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
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
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

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
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

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
