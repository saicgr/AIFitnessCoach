import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/nutrition.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/repositories/nutrition_preferences_repository.dart';
import '../../../data/repositories/hydration_repository.dart';
import '../../nutrition/log_meal_sheet.dart';
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
  const HeroNutritionCard({super.key});

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
    _entrance = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _pageController = PageController();
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final existingNutrition = ref.read(nutritionProvider).todaySummary;
    final existingPrefs = ref.read(nutritionPreferencesProvider).currentCalorieTarget;
    if (existingNutrition != null && existingPrefs > 0 && _isLoading) {
      setState(() => _isLoading = false);
      _animController.forward();
    }

    final apiClient = ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();
    if (userId != null && mounted) {
      _userId = userId;
      await Future.wait([
        ref.read(nutritionProvider.notifier).loadTodaySummary(userId),
        ref.read(hydrationProvider.notifier).loadTodaySummary(userId),
        ref.read(nutritionPreferencesProvider.notifier).initialize(userId),
      ]);
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
        _animController.forward();
      }
    }
  }

  String _adjustmentLabel(DynamicNutritionTargets dt) {
    switch (dt.adjustmentReason) {
      case 'training_day':
        return 'Training day (+${dt.calorieAdjustment} kcal)';
      case 'rest_day':
        return 'Rest day (${dt.calorieAdjustment} kcal)';
      case 'fasting_day':
        return 'Fasting day';
      default:
        return '';
    }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final l10n = AppLocalizations.of(context);

    final nutritionState = ref.watch(nutritionProvider);
    final summary = nutritionState.todaySummary;
    final prefsState = ref.watch(nutritionPreferencesProvider);
    final dynamicTargets = prefsState.dynamicTargets;
    final hydrationState = ref.watch(hydrationProvider);
    final waterConsumedMl = hydrationState.todaySummary?.totalMl ?? 0;
    final waterGoalMl = hydrationState.todaySummary?.goalMl ?? hydrationState.dailyGoalMl;

    final caloriesConsumed = summary?.totalCalories ?? 0;
    final calorieTarget = prefsState.currentCalorieTarget;
    final proteinConsumed = (summary?.totalProteinG ?? 0).round();
    final carbsConsumed = (summary?.totalCarbsG ?? 0).round();
    final fatConsumed = (summary?.totalFatG ?? 0).round();
    final proteinTarget = prefsState.currentProteinTarget;
    final carbsTarget = prefsState.currentCarbsTarget;
    final fatTarget = prefsState.currentFatTarget;
    final caloriesRemaining = calorieTarget - caloriesConsumed;

    final proteinColor = isDark ? AppColors.macroProtein : AppColorsLight.macroProtein;
    final carbsColor = isDark ? AppColors.macroCarbs : AppColorsLight.macroCarbs;
    final fatColor = isDark ? AppColors.macroFat : AppColorsLight.macroFat;
    final buttonBg = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final buttonFg = isDark ? Colors.black : Colors.white;

    final calorieProgress =
        calorieTarget > 0 ? (caloriesConsumed / calorieTarget).clamp(0.0, 1.3) : 0.0;

    // Aggregate micronutrients from the day's logged meals (summary-level
    // model has no micro totals, but each FoodLog carries them).
    final micros = _MicroTotals.fromMeals(summary?.meals ?? const []);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
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
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : Column(
                  children: [
                    // Training/rest-day adjustment badge (kept above the carousel)
                    if (dynamicTargets != null &&
                        dynamicTargets.adjustmentReason != 'base_targets') ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline, size: 11, color: accent),
                              const SizedBox(width: 4),
                              Text(
                                _adjustmentLabel(dynamicTargets),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: accent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // ===== swipeable carousel =====
                    Expanded(
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
                            calorieProgress: calorieProgress,
                            proteinConsumed: proteinConsumed,
                            carbsConsumed: carbsConsumed,
                            fatConsumed: fatConsumed,
                            proteinTarget: proteinTarget,
                            carbsTarget: carbsTarget,
                            fatTarget: fatTarget,
                            proteinColor: proteinColor,
                            carbsColor: carbsColor,
                            fatColor: fatColor,
                            onEditCalorieGoal: (v) => _commitGoal('calories', v),
                            onEditProteinGoal: (v) => _commitGoal('protein', v),
                            onEditCarbsGoal: (v) => _commitGoal('carbs', v),
                            onEditFatGoal: (v) => _commitGoal('fat', v),
                          ),
                          // Page 2 — micronutrients
                          _MicroGridPage(
                            entrance: _entrance,
                            isDark: isDark,
                            tiles: _microPage2(micros),
                          ),
                          // Page 3 — more micronutrients + hydration
                          _MicroGridPage(
                            entrance: _entrance,
                            isDark: isDark,
                            tiles: _microPage3(micros, waterConsumedMl, waterGoalMl),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    // Dot indicators + edit hint
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: 3,
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
                    const SizedBox(height: 8),

                    // LOG MEAL button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticService.medium();
                          showLogMealSheet(context, ref);
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
                    // View Details
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
                            Icon(Icons.insights_outlined, size: 13, color: textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              l10n.heroWorkoutCardViewDetails,
                              style: TextStyle(color: textSecondary, fontSize: 11),
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

  // --- micronutrient page definitions (FDA Daily Values as reference goals) ---
  List<_MicroSpec> _microPage2(_MicroTotals m) => [
        _MicroSpec('Fiber', m.fiberG, 28, 'g', '🥦', const Color(0xFF3F8F5F), 0),
        _MicroSpec('Sugar', m.sugarG, 50, 'g', '🍬', const Color(0xFFB65689), 0),
        _MicroSpec('Sodium', m.sodiumMg, 2300, 'mg', '🧂', const Color(0xFF5560BF), 0),
        _MicroSpec('Potassium', m.potassiumMg, 4700, 'mg', '🍌', const Color(0xFFCC8A2A), 0),
        _MicroSpec('Cholesterol', m.cholesterolMg, 300, 'mg', '🧈', const Color(0xFFCF5F4A), 0),
        _MicroSpec('Calcium', m.calciumMg, 1300, 'mg', '🥛', const Color(0xFF3A9A9A), 0),
      ];

  List<_MicroSpec> _microPage3(_MicroTotals m, int waterMl, int waterGoalMl) => [
        _MicroSpec('Iron', m.ironMg, 18, 'mg', '🩸', const Color(0xFF8C5BB0), 0),
        _MicroSpec('Vitamin C', m.vitaminCMg, 90, 'mg', '🍊', const Color(0xFFC79520), 0),
        _MicroSpec('Vitamin A', m.vitaminAUg, 900, 'µg', '🥕', const Color(0xFFD9802E), 0),
        _MicroSpec('Vitamin D', m.vitaminDIu, 800, 'IU', '☀️', const Color(0xFFCFA62A), 0),
        _MicroSpec('Sat. Fat', m.saturatedFatG, 20, 'g', '🧀', const Color(0xFFCF5F4A), 0),
        _MicroSpec('Hydration', waterMl / 1000.0,
            (waterGoalMl / 1000.0), 'L', '💧', const Color(0xFF3F7FA3), 1),
      ];
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
  final double calorieProgress;
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
    required this.calorieProgress,
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
    // Ring is a fixed square (== the 3-pill stack height) so the pills keep
    // their width — an AspectRatio in a Row would derive width from the tall
    // bounded height and crush the pills.
    return Center(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Calorie ring
          SizedBox(
            width: 142,
            height: 142,
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
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        Text(
                          over ? '+${shown.abs()}' : '$shown',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            color: over ? AppColors.error : textPrimary,
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
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Macro pills
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MacroPill(
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
                const SizedBox(height: 8),
                _MacroPill(
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
                const SizedBox(height: 8),
                _MacroPill(
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
              ],
            ),
          ),
        ],
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
    final labelColor = (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary);

    // Staggered entrance.
    final start = 0.25 + order * 0.08;
    final local = ((entrance.value - start) / (1 - start)).clamp(0.0, 1.0);

    return Opacity(
      opacity: local,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - local)),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: tile,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: labelColor,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: consumed),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, _) => Text(
                            '$v',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
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
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: labelColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
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
      this.name, this.value, this.goal, this.unit, this.emoji, this.color, this.fixed);
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
          _MicroTile(spec: tiles[i], entrance: entrance, order: i, isDark: isDark),
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
    final labelColor = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

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
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
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
          baseOffset: 0, extentOffset: _controller.text.length);
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
    final accent = AccentColorScope.of(context)
        .getColor(Theme.of(context).brightness == Brightness.dark);
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
  });

  factory _MicroTotals.fromMeals(List<FoodLog> meals) {
    double fiber = 0, sugar = 0, sodium = 0, potassium = 0, chol = 0, calcium = 0;
    double iron = 0, vitC = 0, vitA = 0, vitD = 0, satFat = 0;
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
    );
  }
}
