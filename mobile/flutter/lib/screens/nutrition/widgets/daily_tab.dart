import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition.dart';
import '../../../data/models/micronutrients.dart';
import '../../../data/services/api_client.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/main_shell.dart';
import 'edit_targets_sheet.dart';
import 'nutrition_goals_card.dart';
import 'pinned_nutrients_card.dart';
import 'logged_meals_section.dart';
import 'goal_row.dart';

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
  final void Function(String logId, int calories, double proteinG, double carbsG, double fatG, {double? weightG}) onUpdateMeal;
  final void Function(String logId, DateTime newTime) onUpdateMealTime;
  final void Function(String logId, String notes) onUpdateMealNotes;
  final void Function(String logId, {String? moodBefore, String? moodAfter, int? energyLevel}) onUpdateMealMood;
  final void Function(FoodLog meal) onSaveFoodToFavorites;
  final ApiClient? apiClient;
  final VoidCallback? onSwitchToNutrientsTab;
  final VoidCallback? onSwitchToHydrationTab;
  final bool isDark;
  final bool calmMode;

  const DailyTab({
    super.key,
    required this.userId,
    this.summary,
    this.targets,
    this.micronutrients,
    required this.onRefresh,
    required this.onLogMeal,
    required this.onDeleteMeal,
    required this.onCopyMeal,
    required this.onMoveMeal,
    required this.onUpdateMeal,
    required this.onUpdateMealTime,
    required this.onUpdateMealNotes,
    required this.onUpdateMealMood,
    required this.onSaveFoodToFavorites,
    this.apiClient,
    this.onSwitchToNutrientsTab,
    this.onSwitchToHydrationTab,
    required this.isDark,
    this.calmMode = false,
  });

  @override
  ConsumerState<DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends ConsumerState<DailyTab> {
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
                      GoalRow(
                        icon: Icons.local_fire_department,
                        label: 'Calories',
                        value: '${prefsState.currentCalorieTarget}',
                        unit: 'kcal',
                        color: teal,
                        isDark: widget.isDark,
                      ),
                      const SizedBox(height: 12),
                      GoalRow(
                        icon: Icons.egg_outlined,
                        label: 'Protein',
                        value: '${prefsState.currentProteinTarget}',
                        unit: 'g',
                        color: purple,
                        isDark: widget.isDark,
                      ),
                      const SizedBox(height: 12),
                      GoalRow(
                        icon: Icons.grain,
                        label: 'Carbohydrates',
                        value: '${prefsState.currentCarbsTarget}',
                        unit: 'g',
                        color: orange,
                        isDark: widget.isDark,
                      ),
                      const SizedBox(height: 12),
                      GoalRow(
                        icon: Icons.water_drop_outlined,
                        label: 'Fat',
                        value: '${prefsState.currentFatTarget}',
                        unit: 'g',
                        color: coral,
                        isDark: widget.isDark,
                      ),
                      const SizedBox(height: 12),
                      GoalRow(
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

  /// Recalculate nutrition targets based on user profile
  Future<void> _recalculateTargets() async {
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;

    // Guard against empty userId
    if (widget.userId.isEmpty) {
      debugPrint('Warning: [NutritionScreen] Cannot recalculate targets - userId is empty');
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
                  PinnedNutrientsCard(
                    pinned: widget.micronutrients!.pinned,
                    isDark: widget.isDark,
                    onEdit: () => _showPinnedNutrientsEditSheet(),
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

                if (!widget.calmMode) const SizedBox(height: 8),

                // 3. MEAL SECTIONS - All 4 meal types always visible with inline add
                LoggedMealsSection(
                  meals: widget.summary?.meals ?? [],
                  onDeleteMeal: widget.onDeleteMeal,
                  onCopyMeal: widget.onCopyMeal,
                  onMoveMeal: widget.onMoveMeal,
                  onUpdateMeal: widget.onUpdateMeal,
                  onUpdateMealTime: widget.onUpdateMealTime,
                  onUpdateMealNotes: widget.onUpdateMealNotes,
                  onUpdateMealMood: widget.onUpdateMealMood,
                  onSaveFoodToFavorites: widget.onSaveFoodToFavorites,
                  onLogMeal: widget.onLogMeal,
                  apiClient: widget.apiClient,
                  isDark: widget.isDark,
                  userId: widget.userId,
                  onFoodSaved: _loadFavorites,
                  calorieTarget: ref.read(nutritionPreferencesProvider).currentCalorieTarget,
                  totalCaloriesEaten: widget.summary?.totalCalories ?? 0,
                ),
                const SizedBox(height: 12),

                const SizedBox(height: 80), // Nav bar clearance
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
        const SnackBar(content: Text('Failed to update pinned nutrients')),
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
                  'Pin nutrients',
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
              'Pick the nutrients you want to see at the top of the Daily tab.',
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
                    : const Text('Save',
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
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? accent : textPrimary,
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
