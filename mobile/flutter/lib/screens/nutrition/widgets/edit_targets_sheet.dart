import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/posthog_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/utils/weight_utils.dart';
import '../../../data/models/nutrition_preferences.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../onboarding/widgets/calorie_macro_estimator.dart';
import 'nutrition_goals_card.dart' show showNutritionCalculationSheet;

/// Identifies which macro field the user just edited, so the lock-calories
/// balance pass knows which two OTHER fields to recompute.
enum _MacroField { protein, carbs, fat }

class EditTargetsSheet extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback onSaved;

  const EditTargetsSheet({
    super.key,
    required this.userId,
    required this.onSaved,
  });

  @override
  ConsumerState<EditTargetsSheet> createState() => _EditTargetsSheetState();
}

class _EditTargetsSheetState extends ConsumerState<EditTargetsSheet> {
  bool _isPercentageMode = false;
  bool _isLoadingRecommended = false;
  bool _isSaving = false;
  bool _isRecalculating = false;
  String? _selectedRate;

  // B1: "Lock calories" — when true, editing one macro rebalances the others
  // to hold the entered Calories target (grams mode) or keeps the % sum at
  // 100 (percentage mode). Defaults to true: most users expect calories to
  // stay fixed while they shuffle the macro split.
  bool _lockCalories = true;

  // Guards the recursive controller-write cycle. When we programmatically
  // rewrite the OTHER macro controllers inside a balance pass, their
  // listeners would re-fire and trigger another balance pass. This bool
  // short-circuits that. Only the OTHER controllers are ever rewritten —
  // never the field the user is actively editing (preserves their cursor).
  bool _balancing = false;

  // B1: inline warning shown when a single macro's calories alone exceed the
  // calorie target (the other two macros are forced to 0g). Null = no warning.
  String? _macroOverflowWarning;

  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;

  // Live calculated values
  int? _calculatedCalories;
  int? _percentageSum;

  // Recommended values (computed locally on open)
  int? _recommendedCalories;
  int? _recommendedProtein;
  int? _recommendedCarbs;
  int? _recommendedFat;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(nutritionPreferencesProvider).preferences;

    _caloriesController = TextEditingController(
      text: (prefs?.targetCalories ?? 2000).toString(),
    );
    _proteinController = TextEditingController(
      text: (prefs?.targetProteinG ?? 150).toString(),
    );
    _carbsController = TextEditingController(
      text: (prefs?.targetCarbsG ?? 200).toString(),
    );
    _fatController = TextEditingController(
      text: (prefs?.targetFatG ?? 65).toString(),
    );

    _selectedRate = prefs?.rateOfChange;

    // Per-field listeners so a balance pass knows WHICH field changed.
    // The balance routines only ever rewrite the OTHER controllers, so the
    // user's cursor in the edited field is never disturbed.
    _caloriesController.addListener(_onCaloriesChanged);
    _proteinController.addListener(() => _onMacroChanged(_MacroField.protein));
    _carbsController.addListener(() => _onMacroChanged(_MacroField.carbs));
    _fatController.addListener(() => _onMacroChanged(_MacroField.fat));

    _computeRecommended();
    _recalculate();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  bool get _showRateSelector {
    final prefs = ref.read(nutritionPreferencesProvider).preferences;
    final goal = prefs?.primaryGoalEnum;
    return goal == NutritionGoal.loseFat || goal == NutritionGoal.buildMuscle;
  }

  void _computeRecommended() {
    final prefs = ref.read(nutritionPreferencesProvider).preferences;
    if (prefs == null) return;

    final tdee = prefs.calculatedTdee;
    if (tdee == null || tdee <= 0) return;

    // Respect the selected rate pill (lose_fat / build_muscle). Using
    // NutritionCalculator.calculateSafeTarget routes through
    // RateOfChange.calorieAdjustment (the textbook kg/wk × 7700 / 7 rule)
    // and applies the gender-specific minimum-calorie floor. The previous
    // implementation used `goal.calorieAdjustment` (a static -500) which
    // ignored the rate selector and gave wrong recommendations.
    final goal = prefs.primaryGoalEnum;
    final rate = RateOfChange.fromString(_selectedRate ?? prefs.rateOfChange ?? 'moderate');
    final user = ref.read(currentUserProvider).value;
    final gender = user?.gender ?? 'male';

    final safe = NutritionCalculator.calculateSafeTarget(
      tdee: tdee,
      gender: gender,
      goal: goal,
      rate: rate,
    );
    final recCalories = safe.calories;

    // B3: bodyweight-anchored, goal-aware macro recommendation. Protein and
    // fat are pinned to g/kg of bodyweight (physiological need), carbs fill
    // the remaining budget — so the "Rec:" labels reflect the same model
    // the marketing site uses. Falls back to the %-split model internally
    // when bodyweight is unknown.
    final state = ref.read(nutritionPreferencesProvider);
    final bodyweightKg = state.latestWeight ?? user?.weightKg ?? 0;
    final macros = NutritionCalculator.calculateMacrosByBodyweight(
      calories: recCalories.toDouble(),
      bodyweightKg: bodyweightKg,
      goal: goal,
    );

    setState(() {
      _recommendedCalories = recCalories;
      _recommendedProtein = macros.protein;
      _recommendedCarbs = macros.carbs;
      _recommendedFat = macros.fat;
    });
  }

  void _recalculate() {
    final protein = int.tryParse(_proteinController.text);
    final carbs = int.tryParse(_carbsController.text);
    final fat = int.tryParse(_fatController.text);

    if (_isPercentageMode) {
      final sum = (protein ?? 0) + (carbs ?? 0) + (fat ?? 0);
      setState(() => _percentageSum = sum);
    } else {
      if (protein != null && carbs != null && fat != null) {
        setState(() => _calculatedCalories = protein * 4 + carbs * 4 + fat * 9);
      } else {
        setState(() => _calculatedCalories = null);
      }
    }
  }

  // ── B1: lock-calories balancing ──────────────────────────────────────

  /// Writes [value] into [c] without triggering a nested balance pass.
  /// Only ever called on the OTHER controllers (never the edited one), so
  /// the user's cursor position is preserved. We still move the cursor to
  /// the end of these programmatically-written fields for tidiness.
  void _setControllerSilently(TextEditingController c, int value) {
    final text = value.toString();
    if (c.text == text) return; // no-op write — avoid a needless rebuild
    c.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Fired when the Calories field changes.
  void _onCaloriesChanged() {
    if (_balancing) return;
    final calories = int.tryParse(_caloriesController.text);

    // Locked + grams mode: scale all three macros proportionally so they
    // still sum to the new calorie total. Percentage mode has no grams to
    // scale (the % values are calorie-independent), so we only recalc.
    if (_lockCalories && !_isPercentageMode && calories != null && calories > 0) {
      final oldProtein = int.tryParse(_proteinController.text) ?? 0;
      final oldCarbs = int.tryParse(_carbsController.text) ?? 0;
      final oldFat = int.tryParse(_fatController.text) ?? 0;
      final oldKcal = oldProtein * 4 + oldCarbs * 4 + oldFat * 9;

      // Edge case: macros are all-zero/empty — nothing to scale, just
      // recalc so the info row reflects the new (empty) state.
      if (oldKcal > 0) {
        final scale = calories / oldKcal;
        _balancing = true;
        _setControllerSilently(_proteinController, (oldProtein * scale).round());
        _setControllerSilently(_carbsController, (oldCarbs * scale).round());
        _setControllerSilently(_fatController, (oldFat * scale).round());
        _balancing = false;
        _macroOverflowWarning = null;
      }
    }
    _recalculate();
  }

  /// Fired when one of the three macro fields changes. When calories are
  /// locked, rebalances the OTHER two macros to hold the calorie target
  /// (grams mode) or to keep the % sum at 100 (percentage mode).
  void _onMacroChanged(_MacroField edited) {
    if (_balancing) {
      _recalculate();
      return;
    }
    if (!_lockCalories) {
      // Unlocked: free editing — just refresh the calculated-kcal info row.
      _macroOverflowWarning = null;
      _recalculate();
      return;
    }

    if (_isPercentageMode) {
      _balancePercentages(edited);
    } else {
      _balanceGrams(edited);
    }
    _recalculate();
  }

  /// Grams mode, locked. The user edited macro [edited]; recompute the
  /// OTHER two so total calories still equal the entered Calories target.
  /// The other two absorb the calorie delta in proportion to their current
  /// kcal share (preserving their ratio to each other).
  void _balanceGrams(_MacroField edited) {
    final calories = int.tryParse(_caloriesController.text);
    if (calories == null || calories <= 0) {
      _macroOverflowWarning = null;
      return;
    }

    final protein = int.tryParse(_proteinController.text) ?? 0;
    final carbs = int.tryParse(_carbsController.text) ?? 0;
    final fat = int.tryParse(_fatController.text) ?? 0;

    // kcal-per-gram for each macro.
    const kcalPerG = {
      _MacroField.protein: 4,
      _MacroField.carbs: 4,
      _MacroField.fat: 9,
    };

    final editedKcal = _macroGrams(edited, protein, carbs, fat) *
        kcalPerG[edited]!;

    // The two macros that must absorb the remaining budget.
    final others =
        _MacroField.values.where((m) => m != edited).toList(growable: false);
    final otherAKcal =
        _macroGrams(others[0], protein, carbs, fat) * kcalPerG[others[0]]!;
    final otherBKcal =
        _macroGrams(others[1], protein, carbs, fat) * kcalPerG[others[1]]!;

    final remainingKcal = calories - editedKcal;

    _balancing = true;
    if (remainingKcal <= 0) {
      // The edited macro alone meets or exceeds the calorie target — the
      // other two have no room left, so force them to 0g and warn.
      _setControllerSilently(_controllerFor(others[0]), 0);
      _setControllerSilently(_controllerFor(others[1]), 0);
      _macroOverflowWarning =
          '${_macroLabel(edited)} alone exceeds your calorie target';
    } else {
      final othersCurrentKcal = otherAKcal + otherBKcal;
      double aKcal;
      double bKcal;
      if (othersCurrentKcal > 0) {
        // Preserve the two macros' ratio to each other.
        aKcal = remainingKcal * (otherAKcal / othersCurrentKcal);
        bKcal = remainingKcal * (otherBKcal / othersCurrentKcal);
      } else {
        // Edge case: both other macros are currently 0 — no ratio to
        // preserve. Split the remaining budget evenly between them.
        aKcal = remainingKcal / 2;
        bKcal = remainingKcal / 2;
      }
      _setControllerSilently(
          _controllerFor(others[0]), (aKcal / kcalPerG[others[0]]!).round());
      _setControllerSilently(
          _controllerFor(others[1]), (bKcal / kcalPerG[others[1]]!).round());
      _macroOverflowWarning = null;
    }
    _balancing = false;
  }

  /// Percentage mode, locked. The user edited one %, so adjust the OTHER
  /// two to keep the three-way sum at 100.
  void _balancePercentages(_MacroField edited) {
    final editedPct =
        (int.tryParse(_controllerFor(edited).text) ?? 0).clamp(0, 100);

    final others =
        _MacroField.values.where((m) => m != edited).toList(growable: false);
    final aPct = int.tryParse(_controllerFor(others[0]).text) ?? 0;
    final bPct = int.tryParse(_controllerFor(others[1]).text) ?? 0;

    final remaining = 100 - editedPct; // budget for the other two
    final othersSum = aPct + bPct;

    _balancing = true;
    int newA;
    int newB;
    if (othersSum > 0) {
      // Keep the other two in their existing ratio.
      newA = (remaining * (aPct / othersSum)).round();
      newB = remaining - newA; // absorb rounding so the sum is exactly 100
    } else {
      // Both others are 0 — split the remaining budget evenly.
      newA = remaining ~/ 2;
      newB = remaining - newA;
    }
    _setControllerSilently(_controllerFor(others[0]), newA);
    _setControllerSilently(_controllerFor(others[1]), newB);
    _balancing = false;
    _macroOverflowWarning = null;
  }

  int _macroGrams(_MacroField m, int protein, int carbs, int fat) {
    switch (m) {
      case _MacroField.protein:
        return protein;
      case _MacroField.carbs:
        return carbs;
      case _MacroField.fat:
        return fat;
    }
  }

  TextEditingController _controllerFor(_MacroField m) {
    switch (m) {
      case _MacroField.protein:
        return _proteinController;
      case _MacroField.carbs:
        return _carbsController;
      case _MacroField.fat:
        return _fatController;
    }
  }

  String _macroLabel(_MacroField m) {
    switch (m) {
      case _MacroField.protein:
        return 'Protein';
      case _MacroField.carbs:
        return 'Carbs';
      case _MacroField.fat:
        return 'Fat';
    }
  }

  void _onModeToggle(bool toPercentage) {
    final calories = int.tryParse(_caloriesController.text);
    if (calories == null || calories <= 0) return;

    // Guard the bulk controller rewrites below so the per-field balance
    // listeners don't fire mid-conversion.
    _balancing = true;
    if (toPercentage && !_isPercentageMode) {
      // Grams → Percentage
      final protein = int.tryParse(_proteinController.text) ?? 0;
      final fat = int.tryParse(_fatController.text) ?? 0;

      final proteinPct = ((protein * 4 / calories) * 100).round();
      final fatPct = ((fat * 9 / calories) * 100).round();
      final carbsPct = 100 - proteinPct - fatPct;

      _proteinController.text = proteinPct.toString();
      _carbsController.text = carbsPct.toString();
      _fatController.text = fatPct.toString();
    } else if (!toPercentage && _isPercentageMode) {
      // Percentage → Grams
      final pPct = int.tryParse(_proteinController.text) ?? 0;
      final cPct = int.tryParse(_carbsController.text) ?? 0;
      final fPct = int.tryParse(_fatController.text) ?? 0;

      final proteinG = ((calories * pPct / 100) / 4).round();
      final carbsG = ((calories * cPct / 100) / 4).round();
      final fatG = ((calories * fPct / 100) / 9).round();

      _proteinController.text = proteinG.toString();
      _carbsController.text = carbsG.toString();
      _fatController.text = fatG.toString();
    }
    _balancing = false;
    _macroOverflowWarning = null;

    setState(() => _isPercentageMode = toPercentage);
    _recalculate();
  }

  /// Applies the client-computed, rate-aware recommendation directly to the
  /// four fields. NO network call — the backend `recalculateTargets()` uses
  /// the STORED rate_of_change and would ignore the Weekly-Rate chip the
  /// user just tapped. `_computeRecommended()` (run on open, on rate change,
  /// and below) already routes through `RateOfChange` + the bodyweight macro
  /// model, so the locally-held `_recommendedX` values are the correct,
  /// rate-aware source of truth.
  void _useRecommended() {
    setState(() => _isLoadingRecommended = true);
    try {
      // Make sure the recommendation reflects the currently-selected rate
      // chip before we read it (defensive — rate changes already recompute).
      _computeRecommended();

      final cal = _recommendedCalories;
      final protein = _recommendedProtein;
      final carbs = _recommendedCarbs;
      final fat = _recommendedFat;
      if (cal == null || protein == null || carbs == null || fat == null) {
        // No recommendation available — TDEE not yet computed. Surface it
        // rather than silently writing stale/empty values.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Recommendation unavailable — recalculate from profile first'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Switch to grams mode — the recommendation is expressed in grams.
      // Guard the bulk controller writes so the lock-calories balance
      // listeners don't fire and clobber the recommended split.
      _balancing = true;
      _caloriesController.text = cal.toString();
      _proteinController.text = protein.toString();
      _carbsController.text = carbs.toString();
      _fatController.text = fat.toString();
      _balancing = false;

      setState(() {
        _isPercentageMode = false;
        _macroOverflowWarning = null;
      });
      _recalculate();
    } finally {
      if (mounted) setState(() => _isLoadingRecommended = false);
    }
  }

  /// Recompute calorie / macro targets from the user's current profile
  /// (weight, activity, goal) via the backend and refresh the sheet.
  /// Replaces the refresh icon that lived on the removed NutritionGoalsCard.
  Future<void> _recalculateFromProfile() async {
    setState(() => _isRecalculating = true);
    try {
      await ref.read(nutritionPreferencesProvider.notifier)
          .recalculateTargets(widget.userId);

      if (!mounted) return;
      final prefs = ref.read(nutritionPreferencesProvider).preferences;
      // Adopt the backend's refreshed rate (TDEE/BMR are now current).
      if (prefs != null) {
        _selectedRate = prefs.rateOfChange;
      }
      // B2: the backend recalc refreshes TDEE/BMR from profile, but its
      // macro split uses the stored diet-type %. Re-derive the rate-aware
      // bodyweight-anchored recommendation locally and fill the fields from
      // THAT, so the sheet stays consistent with `_computeRecommended()`.
      _computeRecommended();
      final cal = _recommendedCalories;
      final protein = _recommendedProtein;
      final carbs = _recommendedCarbs;
      final fat = _recommendedFat;
      _balancing = true;
      if (cal != null && protein != null && carbs != null && fat != null) {
        _caloriesController.text = cal.toString();
        _proteinController.text = protein.toString();
        _carbsController.text = carbs.toString();
        _fatController.text = fat.toString();
      } else if (prefs != null) {
        // Recommendation not computable (no TDEE) — fall back to the
        // backend-persisted targets so the fields aren't left stale.
        _caloriesController.text = (prefs.targetCalories ?? 2000).toString();
        _proteinController.text = (prefs.targetProteinG ?? 150).toString();
        _carbsController.text = (prefs.targetCarbsG ?? 200).toString();
        _fatController.text = (prefs.targetFatG ?? 65).toString();
      }
      _balancing = false;
      setState(() => _macroOverflowWarning = null);
      _recalculate();

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final teal = isDark ? AppColors.teal : AppColorsLight.teal;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Targets recalculated from profile'),
          backgroundColor: teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to recalculate: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRecalculating = false);
    }
  }

  Future<void> _save() async {
    final calories = int.tryParse(_caloriesController.text);
    if (calories == null || calories <= 0) return;

    int? proteinG, carbsG, fatG;
    int? customProteinPct, customCarbPct, customFatPct;

    if (_isPercentageMode) {
      final pPct = int.tryParse(_proteinController.text) ?? 0;
      final cPct = int.tryParse(_carbsController.text) ?? 0;
      final fPct = int.tryParse(_fatController.text) ?? 0;

      if (pPct + cPct + fPct != 100) return;

      proteinG = ((calories * pPct / 100) / 4).round();
      carbsG = ((calories * cPct / 100) / 4).round();
      fatG = ((calories * fPct / 100) / 9).round();
      customProteinPct = pPct;
      customCarbPct = cPct;
      customFatPct = fPct;
    } else {
      proteinG = int.tryParse(_proteinController.text);
      carbsG = int.tryParse(_carbsController.text);
      fatG = int.tryParse(_fatController.text);
    }

    setState(() => _isSaving = true);
    try {
      ref.read(posthogServiceProvider).capture(
        eventName: 'nutrition_targets_updated',
        properties: <String, Object>{'calories': calories},
      );
      await ref.read(nutritionPreferencesProvider.notifier).updateTargets(
        userId: widget.userId,
        targetCalories: calories,
        targetProteinG: proteinG,
        targetCarbsG: carbsG,
        targetFatG: fatG,
        customProteinPercent: customProteinPct,
        customCarbPercent: customCarbPct,
        customFatPercent: customFatPct,
        rateOfChange: _selectedRate,
      );

      if (mounted) {
        Navigator.pop(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final teal = isDark ? AppColors.teal : AppColorsLight.teal;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Targets updated'),
            backgroundColor: teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme-aware color accessor (light + dark). Sheet-wide accent flows
    // through ThemeColors from the user's AccentColorScope, so the
    // Grams/Percentage toggle, Lock-calories chip, Save button, Rate pills
    // and "Recalculate from profile" link all read in the same app hue.
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;
    final textPrimary = colors.textPrimary;
    final textMuted = colors.textMuted;
    final elevated = colors.elevated;
    final surface = colors.surface;
    final accent = colors.accent;
    // Per-macro colors for the row labels — mirrors the macro rings on the
    // Current Targets card. ThemeColors has no macro-specific getters, so
    // these still resolve directly from AppColors / AppColorsLight.
    final proteinColor =
        isDark ? AppColors.macroProtein : AppColorsLight.macroProtein;
    final carbsColor =
        isDark ? AppColors.macroCarbs : AppColorsLight.macroCarbs;
    final fatColor = isDark ? AppColors.macroFat : AppColorsLight.macroFat;

    final calories = int.tryParse(_caloriesController.text);
    final canToggleToPercent = calories != null && calories > 0;

    // Percentage mode validation
    final percentOk = !_isPercentageMode || _percentageSum == 100;

    // Goal timeline
    final timelineWidget = _buildGoalTimeline(isDark, textMuted, accent);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title row
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
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: textMuted, size: 20),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          // B4: prominent goal banner — surfaces the user's primary goal and
          // their current→target weight right under the title, so the whole
          // sheet is framed by what they're working toward.
          _buildGoalBanner(textPrimary, textMuted, accent),
          const SizedBox(height: 8),

          // Recalculate from profile + current weight context. Showing the
          // weight here (a) gives the user the anchor for the per-kg slider
          // below, and (b) makes "Recalculate from profile" feel less
          // magical — they can see exactly what "profile" means right now.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _isRecalculating ? null : _recalculateFromProfile,
                icon: _isRecalculating
                    ? SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: accent),
                      )
                    : Icon(Icons.refresh, size: 14, color: accent),
                label: Text(
                  'Recalculate from profile',
                  style: TextStyle(
                    fontSize: 12,
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              Builder(builder: (ctx) {
                final state = ref.watch(nutritionPreferencesProvider);
                final user = ref.watch(currentUserProvider).value;
                final weightKg = state.latestWeight ?? user?.weightKg;
                if (weightKg == null || weightKg <= 0) {
                  return const SizedBox.shrink();
                }
                final useKg = user?.usesMetricWeight ?? true;
                final display = WeightUtils.formatWeightFromKg(
                  weightKg,
                  useKg: useKg,
                );
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: elevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: textMuted.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monitor_weight_outlined,
                          size: 12, color: textMuted),
                      const SizedBox(width: 4),
                      Text(
                        display,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),

          // Mode toggle (Grams / Percentage) + Lock-calories chip on one
          // row. Wrap (not Row) so the two never overflow on an iPhone SE
          // — the chip drops below the toggle when width is tight.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Toggle buttons
              Container(
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _toggleButton('Grams', !_isPercentageMode, () {
                      if (_isPercentageMode) _onModeToggle(false);
                    }, textPrimary, accent, surface),
                    _toggleButton(
                      'Percentage',
                      _isPercentageMode,
                      canToggleToPercent
                          ? () {
                              if (!_isPercentageMode) _onModeToggle(true);
                            }
                          : null,
                      textPrimary,
                      accent,
                      surface,
                    ),
                  ],
                ),
              ),
              // B1: "Lock calories" chip. When on, editing one macro
              // rebalances the others to hold the calorie target; editing
              // calories scales all macros. When off, free editing.
              _buildLockCaloriesChip(textPrimary, textMuted, elevated, accent),
            ],
          ),
          const SizedBox(height: 12),

          // Input fields — each label tints with its macro color so the
          // sheet lines up with the macro rings on the Current Targets card.
          _buildFieldRow(
            'Calories',
            _caloriesController,
            'kcal',
            _recommendedCalories,
            textPrimary,
            textMuted,
            elevated,
            accent,
            isCalories: true,
          ),
          const SizedBox(height: 8),
          _buildFieldRow(
            'Protein',
            _proteinController,
            _isPercentageMode ? '%' : 'g',
            _isPercentageMode ? null : _recommendedProtein,
            textPrimary,
            textMuted,
            elevated,
            proteinColor,
          ),
          // Per-kg quick-set scale. Only shown in grams mode (% mode is a
          // share-of-calories paradigm and per-kg doesn't apply). Hidden when
          // we don't know the user's body weight yet so we don't render a
          // broken slider with no anchor.
          if (!_isPercentageMode) ...[
            const SizedBox(height: 6),
            _buildProteinPerKgScale(textPrimary, textMuted, elevated, proteinColor),
          ],
          const SizedBox(height: 8),
          _buildFieldRow(
            'Carbs',
            _carbsController,
            _isPercentageMode ? '%' : 'g',
            _isPercentageMode ? null : _recommendedCarbs,
            textPrimary,
            textMuted,
            elevated,
            carbsColor,
          ),
          const SizedBox(height: 8),
          _buildFieldRow(
            'Fat',
            _fatController,
            _isPercentageMode ? '%' : 'g',
            _isPercentageMode ? null : _recommendedFat,
            textPrimary,
            textMuted,
            elevated,
            fatColor,
          ),
          const SizedBox(height: 8),

          // Info row
          _buildInfoRow(textMuted, accent),
          const SizedBox(height: 4),

          // Goal timeline
          if (timelineWidget != null) ...[
            timelineWidget,
            const SizedBox(height: 8),
          ],

          // Rate of change selector (only for lose/gain goals)
          if (_showRateSelector) ...[
            _buildRateSelector(isDark, textPrimary, textMuted, accent),
            const SizedBox(height: 8),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoadingRecommended ? null : _useRecommended,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    side: BorderSide(color: accent.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoadingRecommended
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accent,
                          ),
                        )
                      : Text(
                          'Use Recommended',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed:
                      (_isSaving || !percentOk) ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Targets',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
        ],
      ),
    );
  }

  Widget _toggleButton(
    String label,
    bool selected,
    VoidCallback? onTap,
    Color textPrimary,
    Color accent,
    Color surface,
  ) {
    // Fixed-width segments (not Expanded) — the toggle now lives inside a
    // Wrap alongside the Lock-calories chip, so it must size intrinsically.
    return SizedBox(
      width: 96,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : (onTap != null
                      ? textPrimary.withValues(alpha: 0.6)
                      : textPrimary.withValues(alpha: 0.3)),
            ),
          ),
        ),
      ),
    );
  }

  /// B4: prominent goal banner. Shows the primary nutrition goal and, when
  /// a target weight exists, the current→target weight transition. Sits
  /// directly under the title so the whole sheet is framed by the goal.
  Widget _buildGoalBanner(
    Color textPrimary,
    Color textMuted,
    Color accent,
  ) {
    final prefs = ref.watch(nutritionPreferencesProvider).preferences;
    if (prefs == null) return const SizedBox.shrink();

    final goal = prefs.primaryGoalEnum;
    final state = ref.watch(nutritionPreferencesProvider);
    final user = ref.watch(currentUserProvider).value;
    // Current weight: prefer the latest logged weight, fall back to the
    // onboarding profile weight.
    final currentKg = state.latestWeight ?? user?.weightKg;
    final targetKg = user?.targetWeightKg;
    final useKg = user?.usesMetricWeight ?? true;

    // Build the "<current>→<target>" suffix only when we have both weights.
    // If target weight is missing we show just the goal (per spec).
    String weightSuffix = '';
    if (currentKg != null && currentKg > 0 && targetKg != null && targetKg > 0) {
      final cur = WeightUtils.formatWeightFromKg(currentKg, useKg: useKg);
      final tgt = WeightUtils.formatWeightFromKg(targetKg, useKg: useKg);
      weightSuffix = ' · $cur → $tgt';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        // Tinted accent wash so the banner reads as the hero context line.
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.track_changes_rounded, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Goal: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: goal.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      color: textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: weightSuffix,
                    style: TextStyle(
                      fontSize: 13,
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// B1: "Lock calories" toggle chip. Tapping flips `_lockCalories`. On
  /// enable we run a balance pass so the macros immediately reconcile with
  /// the current calorie target.
  Widget _buildLockCaloriesChip(
    Color textPrimary,
    Color textMuted,
    Color elevated,
    Color accent,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() => _lockCalories = !_lockCalories);
        if (_lockCalories) {
          // Reconcile macros to the calorie target as soon as the lock
          // turns on, so the user sees a consistent state immediately.
          if (_isPercentageMode) {
            _balancePercentages(_MacroField.protein);
          } else {
            _balanceGrams(_MacroField.protein);
          }
        } else {
          _macroOverflowWarning = null;
        }
        _recalculate();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _lockCalories
              ? accent.withValues(alpha: 0.15)
              : elevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _lockCalories
                ? accent
                : textMuted.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _lockCalories
                  ? Icons.lock_rounded
                  : Icons.lock_open_rounded,
              size: 14,
              color: _lockCalories ? accent : textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              'Lock calories',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _lockCalories ? accent : textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldRow(
    String label,
    TextEditingController controller,
    String suffix,
    int? recommended,
    Color textPrimary,
    Color textMuted,
    Color elevated,
    Color macroColor, {
    bool isCalories = false,
  }) {
    return Row(
      children: [
        // Label + recommended. The macro color tints both so each row is
        // scannable (orange = Fat, purple = Protein, …) and matches the
        // macro rings on the Current Targets card.
        SizedBox(
          width: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: macroColor,
                      ),
                    ),
                  ),
                  // (i) chip on the Calories row — opens the existing
                  // detailed calculation sheet (BMR formula breakdown,
                  // TDEE, goal adjustment, macro split). Sized + styled
                  // visibly so it's not mistaken for a stray dot. Both
                  // action buttons are hidden by the launcher when invoked
                  // from inside Edit Daily Targets (you're already in the
                  // editor).
                  if (isCalories) ...[
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        final prefs = ref.read(nutritionPreferencesProvider).preferences;
                        if (prefs == null) return;
                        showNutritionCalculationSheet(
                          context,
                          prefs: prefs,
                          isDark: Theme.of(context).brightness == Brightness.dark,
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: macroColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (recommended != null)
                GestureDetector(
                  onTap: () {
                    controller.text = recommended.toString();
                    _recalculate();
                  },
                  child: Text(
                    'Rec: ${NumberFormat.decimalPattern().format(recommended)}${isCalories ? '' : 'g'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: macroColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Input field
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: textPrimary, fontSize: 15),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              suffixText: suffix,
              suffixStyle: TextStyle(color: textMuted, fontSize: 13),
              filled: true,
              fillColor: elevated,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Per-kg "scale" under the Protein input. Drag the slider — the protein
  /// gram value updates live to `bodyWeightKg × ratio`. Anchor labels match
  /// common sports-nutrition guidance:
  ///   0.8 g/kg  RDA (sedentary baseline)
  ///   1.2 g/kg  Active / endurance
  ///   1.6 g/kg  Recreational lifter / maintain
  ///   2.0 g/kg  Cutting / fat loss
  ///   2.4 g/kg  Aggressive cut / contest prep
  ///
  /// We *only* allow drag-to-set (one direction). Manually editing the gram
  /// field doesn't snap the slider back — the slider is a quick-set helper,
  /// not a derived display, so users can fine-tune in grams without losing
  /// their custom value.
  Widget _buildProteinPerKgScale(
    Color textPrimary,
    Color textMuted,
    Color elevated,
    Color proteinColor,
  ) {
    final state = ref.watch(nutritionPreferencesProvider);
    // Source priority: latest weight log → user profile weight. Profile
    // weight is the onboarding value and is always present once a user
    // finishes onboarding, so the slider works even when the user hasn't
    // started logging weights yet. Slider only hides if BOTH are null,
    // which should be impossible post-onboarding.
    final user = ref.watch(currentUserProvider).value;
    final weightKg = state.latestWeight ?? user?.weightKg;
    if (weightKg == null || weightKg <= 0) {
      return const SizedBox.shrink();
    }

    // Current g/kg derived from whatever's in the protein field.
    final currentGrams = int.tryParse(_proteinController.text) ?? 0;
    final currentRatio = (currentGrams / weightKg).clamp(0.5, 3.0).toDouble();

    final stops = const [0.8, 1.2, 1.6, 2.0, 2.4];
    final fmt = NumberFormat.decimalPattern();

    // B3: goal-aware "recommended" protein g/kg — mirrors the bodyweight
    // macro model in NutritionCalculator.calculateMacrosByBodyweight:
    // 2.0 g/kg on a cut or lean-gain (lean-mass retention), 1.8 otherwise.
    final goal = ref.watch(nutritionPreferencesProvider).preferences
            ?.primaryGoalEnum ??
        NutritionGoal.maintain;
    final recRatio =
        (goal == NutritionGoal.loseFat || goal == NutritionGoal.buildMuscle)
            ? 2.0
            : 1.8;
    final recGrams = (recRatio * weightKg).round();
    // Goal-tuned phrasing for the recommendation label.
    final String recLabel;
    switch (goal) {
      case NutritionGoal.loseFat:
        recLabel =
            'Recommended to keep muscle while losing fat: ${recGrams}g (${recRatio.toStringAsFixed(1)} g/kg)';
        break;
      case NutritionGoal.buildMuscle:
        recLabel =
            'Recommended to build muscle: ${recGrams}g (${recRatio.toStringAsFixed(1)} g/kg)';
        break;
      default:
        recLabel =
            'Recommended for your goal: ${recGrams}g (${recRatio.toStringAsFixed(1)} g/kg)';
    }
    // Caption explaining why protein is set high — surfaces the science so
    // the recommendation doesn't feel arbitrary.
    final String recCaption = goal == NutritionGoal.loseFat
        ? 'A high protein intake protects lean mass in a calorie deficit.'
        : 'A high protein intake supports muscle growth and recovery.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(110, 0, 0, 0), // align with input column
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live read-out so the user sees exactly what dragging does.
          Row(
            children: [
              Icon(Icons.straighten, size: 12, color: textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${currentRatio.toStringAsFixed(1)} g/kg · '
                  '${(currentRatio * weightKg).round()}g for '
                  '${fmt.format(weightKg.round())}kg',
                  style: TextStyle(fontSize: 11, color: textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // B3: recommended-protein label — names the goal-specific g/kg
          // target so the slider has a clear "aim here" anchor.
          GestureDetector(
            onTap: () {
              // Tap the label to snap protein to the recommendation.
              _proteinController.text = recGrams.toString();
              _proteinController.selection = TextSelection.fromPosition(
                TextPosition(offset: _proteinController.text.length),
              );
              _recalculate();
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 1),
              child: Row(
                children: [
                  Icon(Icons.recommend_rounded, size: 12, color: proteinColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      recLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: proteinColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Slider with a recommended-tick marker overlaid at recRatio. The
          // Slider widget has no native arbitrary-marker, so we paint a thin
          // vertical line via LayoutBuilder positioned along the track.
          LayoutBuilder(
            builder: (context, constraints) {
              const trackPadH = 24.0; // RoundSliderThumbShape ≈ overlay inset
              final usableW = (constraints.maxWidth - trackPadH)
                  .clamp(0.0, double.infinity);
              // Fraction of the 0.8-2.4 range the recommended ratio sits at.
              final recFrac = ((recRatio - 0.8) / (2.4 - 0.8)).clamp(0.0, 1.0);
              final markerLeft = trackPadH / 2 + recFrac * usableW;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      activeTrackColor: proteinColor,
                      inactiveTrackColor:
                          proteinColor.withValues(alpha: 0.18),
                      thumbColor: proteinColor,
                      overlayColor: proteinColor.withValues(alpha: 0.15),
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 14),
                      tickMarkShape:
                          const RoundSliderTickMarkShape(tickMarkRadius: 2),
                      activeTickMarkColor: proteinColor,
                      inactiveTickMarkColor:
                          proteinColor.withValues(alpha: 0.3),
                    ),
                    child: Slider(
                      value: currentRatio,
                      min: 0.8,
                      max: 2.4,
                      divisions: 16, // 0.1 g/kg granularity
                      onChanged: (v) {
                        final grams = (v * weightKg).round();
                        _proteinController.text = grams.toString();
                        _proteinController.selection =
                            TextSelection.fromPosition(
                          TextPosition(
                              offset: _proteinController.text.length),
                        );
                        _recalculate();
                      },
                    ),
                  ),
                  // Recommended tick — a short vertical marker on the track.
                  Positioned(
                    left: markerLeft - 1,
                    top: 4,
                    child: IgnorePointer(
                      child: Container(
                        width: 2,
                        height: 24,
                        decoration: BoxDecoration(
                          color: proteinColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Stop labels — tap to snap.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: stops.map((s) {
                final isActive = (currentRatio - s).abs() < 0.05;
                // Mark the stop that equals the goal's recommended ratio.
                final isRec = (s - recRatio).abs() < 0.05;
                return GestureDetector(
                  onTap: () {
                    final grams = (s * weightKg).round();
                    setState(() {
                      _proteinController.text = grams.toString();
                    });
                    _recalculate();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: (isActive || isRec)
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isActive || isRec
                                ? proteinColor
                                : textMuted,
                          ),
                        ),
                        // Tiny "Rec" tag under the recommended stop.
                        if (isRec)
                          Text(
                            'Rec',
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w700,
                              color: proteinColor.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // B3: science caption explaining the high-protein recommendation.
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              recCaption,
              style: TextStyle(
                fontSize: 10,
                color: textMuted,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(Color textMuted, Color teal) {
    // B1: macro-overflow warning takes precedence — when a single macro's
    // calories alone exceed the calorie target the other two were forced to
    // 0g, which the user must see explained.
    if (_macroOverflowWarning != null) {
      return Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 14, color: Colors.orange),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _macroOverflowWarning!,
              style: const TextStyle(fontSize: 12, color: Colors.orange),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      );
    }

    if (_isPercentageMode) {
      final sum = _percentageSum ?? 0;
      final ok = sum == 100;
      return Row(
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            size: 14,
            color: ok ? teal : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            ok ? 'Total: 100%' : 'Total: $sum% \u00b7 Must equal 100%',
            style: TextStyle(
              fontSize: 12,
              color: ok ? textMuted : Colors.orange,
            ),
          ),
        ],
      );
    }

    // Grams mode
    final enteredCal = int.tryParse(_caloriesController.text);
    final calc = _calculatedCalories;
    if (calc == null || enteredCal == null) {
      return const SizedBox.shrink();
    }

    final diff = (calc - enteredCal).abs();
    final ok = diff <= 10;
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle_outline : Icons.info_outline,
          size: 14,
          color: ok ? teal : Colors.orange,
        ),
        const SizedBox(width: 4),
        Text(
          'Calculated: ${NumberFormat.decimalPattern().format(calc)} kcal'
          '${ok ? '' : ' \u00b7 off by $diff'}',
          style: TextStyle(
            fontSize: 12,
            color: ok ? textMuted : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget? _buildGoalTimeline(bool isDark, Color textMuted, Color teal) {
    final user = ref.read(currentUserProvider).value;
    final prefs = ref.read(nutritionPreferencesProvider).preferences;
    if (user == null || prefs == null) return null;

    final currentWeight = user.weightKg;
    final goalWeight = user.targetWeightKg;
    final nutritionGoal = prefs.primaryGoalEnum;
    final tdee = prefs.calculatedTdee;
    final enteredCal = int.tryParse(_caloriesController.text);

    // Determine weight direction
    String? weightDirection;
    if (nutritionGoal == NutritionGoal.loseFat) {
      weightDirection = 'lose';
    } else if (nutritionGoal == NutritionGoal.buildMuscle) {
      weightDirection = 'gain';
    } else {
      // maintain / recomposition / other
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            Icon(Icons.flag_outlined, size: 14, color: textMuted),
            const SizedBox(width: 4),
            Text(
              'Maintaining weight',
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
          ],
        ),
      );
    }

    // Need weight data for timeline
    if (currentWeight == null || goalWeight == null) return null;

    // Map rate of change. Prefer the user's *current selection* in this sheet
    // (`_selectedRate`) over the persisted `prefs.rateOfChange` so the
    // timeline (weeks-to-goal + deficit/surplus) reflects the rate the user
    // is currently inspecting before they save.
    final rateStr = _selectedRate ?? prefs.rateOfChange ?? 'moderate';

    final weeks = CalorieMacroEstimator.calculateWeeksToGoal(
      currentWeight: currentWeight,
      goalWeight: goalWeight,
      weightDirection: weightDirection,
      weightChangeRate: rateStr,
    );
    final goalDate = CalorieMacroEstimator.calculateGoalDate(
      currentWeight: currentWeight,
      goalWeight: goalWeight,
      weightDirection: weightDirection,
      weightChangeRate: rateStr,
    );

    if (weeks == null || goalDate == null) return null;

    // Daily deficit/surplus
    String deficitInfo = '';
    if (tdee != null && enteredCal != null) {
      final diff = (tdee - enteredCal).abs();
      final label = weightDirection == 'lose' ? 'deficit' : 'surplus';
      deficitInfo = ' \u00b7 $diff cal/d $label';
    }

    final dateStr = DateFormat('MMM d').format(goalDate);
    final goalLabel =
        weightDirection == 'lose' ? 'Lose Fat' : 'Build Muscle';

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(Icons.flag_outlined, size: 14, color: teal),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$goalLabel \u2192 ~$weeks wks ($dateStr)$deficitInfo',
              style: TextStyle(fontSize: 12, color: textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateSelector(bool isDark, Color textPrimary, Color textMuted, Color accent) {
    const rates = [
      ('slow', '0.25', 'Slow'),
      ('moderate', '0.5', 'Moderate'),
      ('fast', '0.75', 'Fast'),
      ('aggressive', '1.0', 'Aggressive'),
    ];
    final selected = _selectedRate ?? 'moderate';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Rate (kg/wk)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted),
        ),
        const SizedBox(height: 6),
        Row(
          children: rates.map((r) {
            final isSelected = selected == r.$1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: r.$1 != 'aggressive' ? 6 : 0),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedRate = r.$1);
                    // Re-derive recommended kcal so the "Rec: X" label and the
                    // goal-timeline deficit refresh as the user picks rates.
                    _computeRecommended();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? accent
                            : textMuted.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          r.$2,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? accent : textPrimary,
                          ),
                        ),
                        Text(
                          r.$3,
                          style: TextStyle(
                            fontSize: 9,
                            color: isSelected ? accent : textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
