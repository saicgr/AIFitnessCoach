import 'dart:async';

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
import '../../../data/repositories/measurements_repository.dart';
import '../../../widgets/design_system/zealova.dart';
import '../../onboarding/widgets/calorie_macro_estimator.dart';
import 'nutrition_goals_card.dart' show showNutritionCalculationSheet;

import '../../../l10n/generated/app_localizations.dart';
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

  // Per-macro debounced commit timers. When the user types in a macro field
  // we schedule a commit ~600ms after the last keystroke, so the lock-calories
  // rebalance of the OTHER two macros fires without requiring the user to
  // dismiss the keyboard or tap away.
  final Map<_MacroField, Timer?> _macroCommitTimers = {
    _MacroField.protein: null,
    _MacroField.carbs: null,
    _MacroField.fat: null,
  };

  // B1: inline warning shown when a single macro's calories alone exceed the
  // calorie target (the other two macros are forced to 0g). Null = no warning.
  String? _macroOverflowWarning;

  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;

  // B-rebalance-on-commit: per-macro FocusNodes. The lock-calories rebalance
  // of the OTHER two macros now runs only when the edited field is COMMITTED
  // (onEditingComplete or focus loss) — not on every keystroke. Mid-type the
  // field can transiently read 0g (e.g. clearing "150" to retype it), and a
  // per-keystroke rebalance would blow up the other two macros. While typing
  // we only refresh the live calculated-kcal / split display.
  late final FocusNode _proteinFocus;
  late final FocusNode _carbsFocus;
  late final FocusNode _fatFocus;

  // Live calculated values
  int? _calculatedCalories;
  int? _percentageSum;

  // Recommended values (computed locally on open)
  int? _recommendedCalories;
  int? _recommendedProtein;
  int? _recommendedCarbs;
  int? _recommendedFat;

  // B5: last non-zero carbs:fat kcal ratio. When a lock-calories rebalance
  // would otherwise split evenly between two 0-kcal macros, we restore THIS
  // remembered ratio instead of permanently flattening the split to 50/50.
  double? _lastCarbsFatRatio; // carbsKcal / (carbsKcal + fatKcal)

  // B7: currently-selected diet preset. Drives the goal-derived vs fixed
  // g/kg macro recommendation.
  MacroPreset _selectedPreset =
      MacroPreset.recommended;

  // B10: snapshot of the four macro fields + rate + preset taken when the
  // sheet opens, so the "Reset" action can revert to exactly that state.
  late final String _initialCalories;
  late final String _initialProtein;
  late final String _initialCarbs;
  late final String _initialFat;
  String? _initialRate;
  late final MacroPreset _initialPreset;

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

    // B-rebalance-on-commit: FocusNodes drive the rebalance on focus-loss.
    _proteinFocus = FocusNode();
    _carbsFocus = FocusNode();
    _fatFocus = FocusNode();
    _proteinFocus.addListener(() => _onMacroFocusChange(_MacroField.protein));
    _carbsFocus.addListener(() => _onMacroFocusChange(_MacroField.carbs));
    _fatFocus.addListener(() => _onMacroFocusChange(_MacroField.fat));

    // B5: seed the remembered carbs:fat ratio from the opening values so the
    // first even-split edge case can still restore a real ratio.
    _rememberCarbsFatRatio();

    // B10: snapshot the opening state for the Reset action.
    _initialCalories = _caloriesController.text;
    _initialProtein = _proteinController.text;
    _initialCarbs = _carbsController.text;
    _initialFat = _fatController.text;
    _initialRate = _selectedRate;
    _initialPreset = _selectedPreset;

    // Per-field listeners. While typing these ONLY refresh the live display
    // (calculated kcal / split bar). The actual lock-calories rebalance of
    // the OTHER two macros runs on COMMIT — see `_onMacroFocusChange` and the
    // `onEditingComplete` hook on each macro field.
    _caloriesController.addListener(_onCaloriesChanged);
    _proteinController.addListener(() => _onMacroChanged(_MacroField.protein));
    _carbsController.addListener(() => _onMacroChanged(_MacroField.carbs));
    _fatController.addListener(() => _onMacroChanged(_MacroField.fat));

    _computeRecommended();
    _recalculate();

    // B4: ensure the latest body-fat measurement is available so the
    // lean-body-mass protein anchor can trigger. `measurementsProvider`'s
    // notifier doesn't auto-load — kick a (cache-first, cheap) load and
    // re-derive the recommendation once it lands. No-op if already loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final hasData =
          ref.read(measurementsProvider).summary?.latestByType.isNotEmpty ??
              false;
      if (hasData) return;
      await ref
          .read(measurementsProvider.notifier)
          .loadAllMeasurements(widget.userId);
      if (!mounted) return;
      // Recompute so the LBM-anchored protein recommendation appears.
      _computeRecommended();
    });
  }

  @override
  void dispose() {
    for (final t in _macroCommitTimers.values) {
      t?.cancel();
    }
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _proteinFocus.dispose();
    _carbsFocus.dispose();
    _fatFocus.dispose();
    super.dispose();
  }

  /// B5: remember the current carbs:fat split (as a carbs-fraction of the two
  /// macros' combined kcal) whenever both are non-zero. Restored later when a
  /// rebalance would otherwise have to split two 0-kcal macros evenly.
  void _rememberCarbsFatRatio() {
    final carbs = int.tryParse(_carbsController.text) ?? 0;
    final fat = int.tryParse(_fatController.text) ?? 0;
    final carbsKcal = carbs * 4;
    final fatKcal = fat * 9;
    final total = carbsKcal + fatKcal;
    if (total > 0) {
      _lastCarbsFatRatio = carbsKcal / total;
    }
  }

  FocusNode _focusFor(_MacroField m) {
    switch (m) {
      case _MacroField.protein:
        return _proteinFocus;
      case _MacroField.carbs:
        return _carbsFocus;
      case _MacroField.fat:
        return _fatFocus;
    }
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

    // B3/B7: bodyweight-anchored, goal-aware (or preset-driven) macro
    // recommendation. Protein and fat are pinned to g/kg (physiological
    // need), carbs fill the remaining budget. The selected diet preset
    // overrides the goal-derived g/kg. The protein anchor (lean mass / goal
    // weight / total bodyweight) is resolved inside calculateMacrosByBodyweight.
    final state = ref.read(nutritionPreferencesProvider);
    final bodyweightKg = state.latestWeight ?? user?.weightKg ?? 0;
    final macros = NutritionCalculator.calculateMacrosByBodyweight(
      calories: recCalories.toDouble(),
      bodyweightKg: bodyweightKg,
      goal: goal,
      preset: _selectedPreset,
      bodyFatPercent: _bodyFatPercent(),
      targetWeightKg: user?.targetWeightKg,
    );

    setState(() {
      _recommendedCalories = recCalories;
      _recommendedProtein = macros.protein;
      _recommendedCarbs = macros.carbs;
      _recommendedFat = macros.fat;
    });
  }

  /// B4: body-fat % anchor source. Reads the latest logged body-fat
  /// measurement from `measurementsProvider` (the StateNotifier behind the
  /// Measurements screen — `MeasurementType.bodyFat` entries are stored as a
  /// percentage, unit `%`). When the user has logged a body-fat reading the
  /// protein anchor resolves to LEAN BODY MASS; otherwise this returns null
  /// and `resolveProteinAnchor` falls through to goal-weight / bodyweight.
  ///
  /// `summary` is null until the notifier has loaded (3-tier cache — usually
  /// already warm), and a `<= 0` / `>= 100` reading is treated as absent so a
  /// stray bad entry can't poison the anchor.
  double? _bodyFatPercent() {
    final summary = ref.read(measurementsProvider).summary;
    final entry = summary?.latestByType[MeasurementType.bodyFat];
    final bf = entry?.value;
    if (bf == null || bf <= 0 || bf >= 100) return null;
    return bf;
  }

  /// B4: resolves the protein anchor (lean mass / goal weight / bodyweight)
  /// for the current user, so the slider + caption can describe the base.
  ({double baseKg, String label, bool isLeanMass})? _proteinAnchor() {
    final state = ref.read(nutritionPreferencesProvider);
    final user = ref.read(currentUserProvider).value;
    final bodyweightKg = state.latestWeight ?? user?.weightKg ?? 0;
    if (bodyweightKg <= 0) return null;
    final goal =
        state.preferences?.primaryGoalEnum ?? NutritionGoal.maintain;
    return NutritionCalculator.resolveProteinAnchor(
      bodyweightKg: bodyweightKg,
      goal: goal,
      bodyFatPercent: _bodyFatPercent(),
      targetWeightKg: user?.targetWeightKg,
    );
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

  /// Fired on EVERY keystroke in macro field [m]. Per spec, typing must NOT
  /// immediately trigger the lock-calories rebalance — clearing "150" to
  /// retype it would momentarily read 0g and explode the other macros. So we
  /// (a) refresh the live display now and (b) schedule a debounced commit
  /// ~600ms after the last keystroke so the rebalance fires without requiring
  /// the user to dismiss the keyboard or tap away.
  void _onMacroChanged(_MacroField m) {
    // Programmatic rewrite from a balance pass still needs the display to
    // refresh, but must not itself re-balance — also skip the debounce
    // scheduling (the value isn't user-typed).
    _recalculate();
    if (_balancing) return;

    _macroCommitTimers[m]?.cancel();
    _macroCommitTimers[m] = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      // Skip empty/zero — the user is mid-edit (e.g., cleared the field to
      // retype). A real commit happens on focus-loss / onEditingComplete in
      // that case.
      final v = int.tryParse(_controllerFor(m).text);
      if (v == null || v <= 0) return;
      _commitMacro(m);
    });
  }

  /// B-rebalance-on-commit: focus-loss path. When a macro field loses focus
  /// (user tapped elsewhere / dismissed the keyboard) we treat that as a
  /// commit and run the rebalance.
  void _onMacroFocusChange(_MacroField edited) {
    if (!mounted) return;
    if (_focusFor(edited).hasFocus) return; // gained focus — nothing to do
    _commitMacro(edited);
  }

  /// Commits an edit to macro [edited]: when calories are locked, rebalances
  /// the OTHER two macros to hold the calorie target (grams mode) or keep the
  /// % sum at 100 (percentage mode). Invoked from `onEditingComplete` and on
  /// focus loss — never per keystroke.
  void _commitMacro(_MacroField edited) {
    if (_balancing) {
      _recalculate();
      return;
    }
    if (!_lockCalories) {
      // Unlocked: free editing — just refresh the calculated-kcal info row.
      setState(() => _macroOverflowWarning = null);
      _rememberCarbsFatRatio();
      _recalculate();
      return;
    }

    if (_isPercentageMode) {
      _balancePercentages(edited);
    } else {
      _balanceGrams(edited);
    }
    // B5: capture the post-rebalance carbs:fat ratio so future even-split
    // edge cases can restore it.
    _rememberCarbsFatRatio();
    setState(() {}); // surface _macroOverflowWarning changes
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
        // B5: edge case — both other macros are currently 0 kcal, so their
        // proportional split is undefined (a divide-by-zero). When the two
        // others ARE carbs and fat AND we have a remembered carbs:fat ratio
        // from before they were zeroed, restore THAT ratio instead of
        // flattening permanently to 50/50. Otherwise split evenly.
        final isCarbsFatPair = others.contains(_MacroField.carbs) &&
            others.contains(_MacroField.fat);
        if (isCarbsFatPair && _lastCarbsFatRatio != null) {
          // _lastCarbsFatRatio is the carbs share of (carbs+fat) kcal.
          final carbsIdx = others[0] == _MacroField.carbs ? 0 : 1;
          final carbsShare = remainingKcal * _lastCarbsFatRatio!;
          final fatShare = remainingKcal - carbsShare;
          aKcal = carbsIdx == 0 ? carbsShare : fatShare;
          bKcal = carbsIdx == 0 ? fatShare : carbsShare;
        } else {
          // No ratio to restore — split the remaining budget evenly.
          aKcal = remainingKcal / 2;
          bKcal = remainingKcal / 2;
        }
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
          SnackBar(
            content: Text(
                AppLocalizations.of(context).editTargetsRecommendationUnavailableR),
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
      _rememberCarbsFatRatio();
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
      _rememberCarbsFatRatio();
      _recalculate();

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final teal = isDark ? AppColors.teal : AppColorsLight.teal;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).editTargetsTargetsRecalculatedFromProf),
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

    // Fire analytics + the (now-optimistic) provider update. Both are
    // synchronous on the foreground frame — the provider applies the new
    // targets to state immediately and persists in the background. Pop
    // straight after so the user never sees a spinner on save.
    ref.read(posthogServiceProvider).capture(
      eventName: 'nutrition_targets_updated',
      properties: <String, Object>{'calories': calories},
    );
    // No await — provider now updates state synchronously and persists in
    // the background. Holding _isSaving briefly suppresses double-taps.
    setState(() => _isSaving = true);
    unawaited(
      ref.read(nutritionPreferencesProvider.notifier).updateTargets(
            userId: widget.userId,
            targetCalories: calories,
            targetProteinG: proteinG,
            targetCarbsG: carbsG,
            targetFatG: fatG,
            customProteinPercent: customProteinPct,
            customCarbPercent: customCarbPct,
            customFatPercent: customFatPct,
            rateOfChange: _selectedRate,
          ),
    );

    if (!mounted) return;
    Navigator.pop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(AppLocalizations.of(context).editTargetsTargetsUpdated),
        backgroundColor: teal,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.onSaved();
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
      // Bottom keyboard/safe-area inset is handled by the enclosing GlassSheet
      // (it lifts the whole sheet above the keyboard), so we only add a small
      // constant here — adding viewInsets again would double-pad and leave a
      // gap below the pinned footer when the keyboard is up.
      padding: const EdgeInsets.only(left: 20, right: 20, top: 4, bottom: 8),
      // The form is taller than the glass-sheet's max height (~715 px) once
      // the goal banner + recalc row + macros sliders + timeline all render.
      // Only the FORM scrolls — the Reset link + action buttons are pinned in
      // a footer below so Save/Reset are always reachable without scrolling.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Pinned header — title + Reset + close, then the goal banner.
          // These stay fixed while only the form below scrolls, so the user
          // always sees what they're editing toward and Reset/close are one tap
          // away (issue #7).
          Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context).editTargetsEditDailyTargets.toUpperCase(),
                  style: ZType.lbl(18, color: textPrimary, letterSpacing: 1.6),
                ),
              ),
              // Reset moved up beside the close button (was a footer link).
              TextButton.icon(
                onPressed: _isSaving ? null : _resetToInitial,
                icon: Icon(Icons.restart_alt_rounded,
                    size: 15, color: textMuted),
                label: Text(
                  AppLocalizations.of(context).trophyFilterReset,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 2),
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
          Flexible(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Baseline-vs-today banner. When today's dynamic target differs
          // from the stored baseline (training/rest/fasting day), tell the
          // user they're editing the BASELINE and what today's adjusted
          // value is — otherwise the 1500 / 1700 mismatch reads as a bug.
          _buildBaselineTodayBanner(textMuted, accent),

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
                  AppLocalizations.of(context).nutritionSettingsScreenRecalculateFromProfile,
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
                    color: surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
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
                  color: surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
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
            macroField: _MacroField.protein,
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
            macroField: _MacroField.carbs,
          ),
          // B9: per-kg readout under the Carbs field (grams mode only).
          if (!_isPercentageMode) ...[
            const SizedBox(height: 4),
            _buildMacroPerKgCaption(_carbsController, textMuted),
          ],
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
            macroField: _MacroField.fat,
          ),
          // B9: per-kg readout under the Fat field (grams mode only).
          if (!_isPercentageMode) ...[
            const SizedBox(height: 4),
            _buildMacroPerKgCaption(_fatController, textMuted),
          ],
          const SizedBox(height: 8),

          // B8: live macro-split bar — P/C/F calorie proportions.
          _buildMacroSplitBar(proteinColor, carbsColor, fatColor, textMuted),
          const SizedBox(height: 8),

          // B7: diet preset chips.
          _buildPresetChips(textPrimary, textMuted, elevated, accent),
          const SizedBox(height: 8),

          // Info row
          _buildInfoRow(textMuted, accent),
          const SizedBox(height: 4),

          // Goal timeline
          if (timelineWidget != null) ...[
            timelineWidget,
            const SizedBox(height: 8),
          ],

          // B11: inline non-blocking sanity warnings (deficit / floor /
          // extreme g/kg). Sits right under the info row's territory.
          ..._buildSanityWarnings(textMuted),

          // Rate of change selector (only for lose/gain goals)
          if (_showRateSelector) ...[
            _buildRateSelector(isDark, textPrimary, textMuted, accent),
            const SizedBox(height: 8),
          ],
                ],
              ),
            ),
          ),

          // ── Pinned footer ──────────────────────────────────────────────
          // Action buttons live OUTSIDE the scroll view so they stay visible no
          // matter how far the form is scrolled. (Reset moved up to the pinned
          // header beside the close button — issue #7.) A hairline rule
          // separates them from the scrolling content above.
          const ZealovaRule(
            margin: EdgeInsets.only(top: 4, bottom: 8),
          ),

          // Action buttons. Secondary "Use recommended" is a ghost (hairline
          // outline); the single primary CTA is Save. Loading states keep the
          // hairline frame and swap in a spinner.
          Row(
            children: [
              Expanded(
                child: _isLoadingRecommended
                    ? Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.cardBorder),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accent,
                          ),
                        ),
                      )
                    : ZealovaButton(
                        label: AppLocalizations.of(context).editTargetsUseRecommended,
                        variant: ZealovaButtonVariant.ghost,
                        onTap: _useRecommended,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: (_isSaving)
                    ? Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ThemeColors.of(context).accentContrast,
                          ),
                        ),
                      )
                    : ZealovaButton(
                        label: AppLocalizations.of(context).editTargetsSaveTargets,
                        variant: ZealovaButtonVariant.primary,
                        onTap: percentOk ? _save : null,
                      ),
              ),
            ],
          ),
          // Safe-area bottom inset is added by the enclosing GlassSheet, so
          // only a small visual gap is needed under the buttons here.
          const SizedBox(height: 4),
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
            color: selected ? accent.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? accent : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label.toUpperCase(),
            style: ZType.lbl(
              12,
              color: selected
                  ? accent
                  : (onTap != null
                      ? textPrimary.withValues(alpha: 0.6)
                      : textPrimary.withValues(alpha: 0.3)),
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  /// Shown when today's adjusted target (training/rest/fasting day bump)
  /// differs from the user's stored baseline. The Edit sheet always edits
  /// the BASELINE — without this banner the user sees 1500 here vs 1700 on
  /// the Daily ring and reads it as a bug. Tap → opens the BMR/TDEE/goal
  /// calculation sheet for the full breakdown.
  Widget _buildBaselineTodayBanner(Color textMuted, Color accent) {
    final state = ref.watch(nutritionPreferencesProvider);
    final dyn = state.dynamicTargets;
    final reason = dyn?.adjustmentReason ?? 'base_targets';
    final delta = dyn?.calorieAdjustment ?? 0;
    if (reason == 'base_targets' || delta.abs() < 10) {
      return const SizedBox.shrink();
    }

    final baseline = state.preferences?.targetCalories ?? 0;
    final todays = dyn?.targetCalories ?? baseline;

    final tag = switch (reason) {
      'training_day' => 'training',
      'rest_day' => 'rest',
      'fasting_day' => 'fasting',
      _ => 'today',
    };
    final signed = delta > 0 ? '+$delta' : '$delta';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            final prefs = ref.read(nutritionPreferencesProvider).preferences;
            if (prefs == null) return;
            showNutritionCalculationSheet(
              context,
              prefs: prefs,
              isDark: Theme.of(context).brightness == Brightness.dark,
            );
          },
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: ThemeColors.of(context).surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: textMuted,
                      ),
                      children: [
                        const TextSpan(text: 'Editing your '),
                        const TextSpan(
                          text: 'baseline',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' ($baseline cal). Today: '),
                        TextSpan(
                          text: '$todays cal',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                        TextSpan(text: '  ($signed $tag).'),
                      ],
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: textMuted),
              ],
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
        // Hairline-bordered flat surface — the accent stays reserved for the
        // single primary Save CTA.
        color: ThemeColors.of(context).surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
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
              : ThemeColors.of(context).surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _lockCalories
                ? accent
                : AppColors.cardBorder,
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
              AppLocalizations.of(context).editTargetsLockCalories,
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
    // B-rebalance-on-commit: when set, the field is a macro field — attach
    // its FocusNode and run the lock-calories rebalance on `onEditingComplete`.
    _MacroField? macroField,
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
            focusNode: macroField != null ? _focusFor(macroField) : null,
            keyboardType: TextInputType.number,
            // B-rebalance-on-commit: keyboard "done" / next is a commit.
            textInputAction: TextInputAction.done,
            onEditingComplete: macroField != null
                ? () {
                    _commitMacro(macroField);
                    FocusScope.of(context).unfocus();
                  }
                : null,
            style: TextStyle(color: textPrimary, fontSize: 15),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              suffixText: suffix,
              suffixStyle: TextStyle(color: textMuted, fontSize: 13),
              filled: true,
              fillColor: ThemeColors.of(context).surface,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: ThemeColors.of(context).accent),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.cardBorder),
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
    // MUST be clamped to the Slider's [min, max] (0.8..2.4) below — passing
    // a value outside that range trips Slider's `value >= min && value <= max`
    // assertion. Users on a very low-protein target can legitimately sit
    // below 0.8 g/kg; we pin the thumb to the floor of the visible scale
    // (the protein grams field itself stays untouched).
    final currentGrams = int.tryParse(_proteinController.text) ?? 0;
    // Guard weightKg<=0 — onboarding edge case can leave it 0/null, and
    // `n / 0` → NaN, which .clamp() preserves, tripping Slider's range assert.
    final currentRatio = weightKg > 0
        ? (currentGrams / weightKg).clamp(0.8, 2.4).toDouble()
        : 1.6;

    final stops = const [0.8, 1.2, 1.6, 2.0, 2.4];
    final fmt = NumberFormat.decimalPattern();

    // B3: goal-aware "recommended" protein g/kg. The goal may be genuinely
    // unknown (no preferences row) — distinguish that from `maintain` so the
    // copy + default ratio are honestly generic rather than maintain-tinted.
    final NutritionGoal? goalOrNull =
        ref.watch(nutritionPreferencesProvider).preferences?.primaryGoalEnum;
    final goal = goalOrNull ?? NutritionGoal.maintain;
    final recRatio =
        (goal == NutritionGoal.loseFat || goal == NutritionGoal.buildMuscle)
            ? 2.0
            : 1.8; // generic / maintain default

    // B4: protein anchor — base weight may be lean mass / goal weight /
    // bodyweight. The slider's "recommended grams" uses the SAME anchor so
    // it agrees with the headline recommendation.
    final anchor = _proteinAnchor();
    final anchorBaseKg = anchor?.baseKg ?? weightKg;
    final anchorLabel = anchor?.label ?? 'based on bodyweight';
    // LBM anchor uses a higher g/kg band (see calculateMacrosByBodyweight).
    final effectiveRatio = (anchor?.isLeanMass ?? false)
        ? (recRatio * 1.15).clamp(2.0, 2.7)
        : recRatio;
    final recGrams = (effectiveRatio * anchorBaseKg).round();

    // B3: goal-adaptive recommendation label. The "g/kg" shown is the
    // g/kg-of-anchor figure so the caption and number are consistent.
    final String recLabel;
    switch (goalOrNull) {
      case NutritionGoal.loseFat:
        recLabel =
            'Recommended to keep muscle while losing fat: ${recGrams}g (${effectiveRatio.toStringAsFixed(1)} g/kg)';
        break;
      case NutritionGoal.buildMuscle:
        recLabel =
            'Recommended to support muscle growth: ${recGrams}g (${effectiveRatio.toStringAsFixed(1)} g/kg)';
        break;
      case NutritionGoal.maintain:
      case NutritionGoal.recomposition:
        recLabel =
            'Recommended to maintain lean mass: ${recGrams}g (${effectiveRatio.toStringAsFixed(1)} g/kg)';
        break;
      default:
        // Goal null / improveEnergy / eatHealthier — generic phrasing.
        recLabel =
            'Recommended protein: ${recGrams}g (${effectiveRatio.toStringAsFixed(1)} g/kg)';
    }
    // B3: goal-adaptive science caption. Generic when the goal is unknown.
    final String recCaption;
    switch (goalOrNull) {
      case NutritionGoal.loseFat:
        recCaption =
            'A high protein intake protects lean mass in a calorie deficit.';
        break;
      case NutritionGoal.buildMuscle:
        recCaption =
            'A high protein intake supports muscle growth and recovery.';
        break;
      case NutritionGoal.maintain:
      case NutritionGoal.recomposition:
        recCaption =
            'Adequate protein maintains lean mass and supports recovery.';
        break;
      default:
        recCaption =
            'Adequate protein supports recovery and lean-mass retention.';
    }

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
                        if (!mounted) return;
                        final grams = (v * weightKg).round();
                        _proteinController.text = grams.toString();
                        _proteinController.selection =
                            TextSelection.fromPosition(
                          TextPosition(
                              offset: _proteinController.text.length),
                        );
                        // Live display refresh while dragging — calories
                        // bar updates per-tick. The actual rebalance of
                        // carbs/fat happens on release (`onChangeEnd`),
                        // matching the typing → commit-on-focus-loss
                        // pattern so dragging doesn't twitch the other
                        // macros every 0.1 g/kg.
                        _recalculate();
                      },
                      onChangeEnd: (_) {
                        // Commit on release — fires `_commitMacro` which
                        // runs the lock-calories rebalance (carbs/fat
                        // absorb the calorie delta in proportion to their
                        // current kcal share). Previously the slider only
                        // called `_recalculate()` and skipped the commit
                        // entirely, so dragging protein up never adjusted
                        // carbs/fat even though Lock calories was on.
                        _commitMacro(_MacroField.protein);
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
                    // Tap-to-snap is a single atomic commit (no drag
                    // intermediate state), so fire the rebalance
                    // immediately. Same fix as the slider's onChangeEnd.
                    _commitMacro(_MacroField.protein);
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
                            AppLocalizations.of(context).editTargetsRec,
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
          // B4: name the protein anchor base so the recommendation isn't a
          // mystery — "based on lean mass" / "based on goal weight" / etc.
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Row(
              children: [
                Icon(Icons.anchor_rounded, size: 9, color: textMuted),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    'Protein target $anchorLabel',
                    style: TextStyle(fontSize: 9, color: textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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
            ok ? AppLocalizations.of(context).editTargetsTotal100 : 'Total: $sum% \u00b7 Must equal 100%',
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
              AppLocalizations.of(context).editTargetsMaintainingWeight,
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

    // B2: detect whether the recommended calories were FLOORED at the
    // gender-specific safe minimum. If so, the nominal rate (the chip the
    // user picked) is NOT what they'll actually get \u2014 the achievable rate is
    // limited by the real deficit `TDEE \u2212 flooredCalories`. We recompute the
    // timeline from that actual deficit and surface a "capped" note.
    final user2 = ref.read(currentUserProvider).value;
    final gender = user2?.gender ?? 'male';
    bool capped = false;
    int? cappedMinimum;
    int? weeks;
    DateTime? goalDate;
    int? actualDeficit; // cal/d \u2014 the deficit we actually display

    if (tdee != null && tdee > 0) {
      final safe = NutritionCalculator.calculateSafeTarget(
        tdee: tdee,
        gender: gender,
        goal: nutritionGoal,
        rate: RateOfChange.fromString(rateStr),
      );
      capped = safe.wasAdjusted;
      cappedMinimum = capped ? safe.calories : null;
    }

    final weightDiff = (currentWeight - goalWeight).abs();

    if (capped && nutritionGoal == NutritionGoal.loseFat && weightDiff >= 0.1) {
      // Recompute timeline from the ACTUAL deficit. The nominal rate is
      // unreachable once calories hit the floor.
      // Wishnofsky: 1 kg fat \u2248 7700 kcal \u2192 weekly rate = deficit\u00d77/7700.
      actualDeficit = tdee! - cappedMinimum!;
      if (actualDeficit <= 0) {
        // Floor sits at or above TDEE \u2014 no deficit is possible at all.
        return Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 14, color: Colors.orange),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Safe-minimum calories ($cappedMinimum) meet your TDEE \u2014 '
                  'no deficit possible. Increase activity to lose fat.',
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        );
      }
      final weeklyRateKg = actualDeficit * 7 / 7700;
      weeks = (weightDiff / weeklyRateKg).ceil();
      goalDate = DateTime.now().add(Duration(days: weeks * 7));
    } else {
      // Not capped \u2014 use the standard rate-driven estimate.
      weeks = CalorieMacroEstimator.calculateWeeksToGoal(
        currentWeight: currentWeight,
        goalWeight: goalWeight,
        weightDirection: weightDirection,
        weightChangeRate: rateStr,
      );
      goalDate = CalorieMacroEstimator.calculateGoalDate(
        currentWeight: currentWeight,
        goalWeight: goalWeight,
        weightDirection: weightDirection,
        weightChangeRate: rateStr,
      );
      // Deficit/surplus from the actual entered calories vs TDEE.
      if (tdee != null && enteredCal != null) {
        actualDeficit = (tdee - enteredCal).abs();
      }
    }

    if (weeks == null || goalDate == null) return null;

    // Daily deficit/surplus label \u2014 always from the ACTUAL figure.
    String deficitInfo = '';
    if (actualDeficit != null) {
      final label = weightDirection == 'lose' ? 'deficit' : 'surplus';
      deficitInfo = ' \u00b7 $actualDeficit cal/d $label';
    }

    final dateStr = DateFormat('MMM d').format(goalDate);
    final goalLabel =
        weightDirection == 'lose' ? 'Lose Fat' : 'Build Muscle';

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          // B2: capped-at-safe-minimum note. The timeline above is already
          // recomputed from the real deficit \u2014 this explains WHY it's slower
          // than the rate chip implies.
          if (capped && cappedMinimum != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 18),
              child: Text(
                'Capped at safe minimum ($cappedMinimum kcal). '
                'Timeline reflects the actual deficit.',
                style: const TextStyle(fontSize: 10, color: Colors.orange),
                maxLines: 2,
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
        ZealovaSectionKicker(
          AppLocalizations.of(context).editTargetsWeeklyRateKgWk,
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
                    // Re-derive recommended kcal under the new rate, then write
                    // it into the Calories + macro fields so the visible
                    // numbers actually change (not just the "Rec:" label).
                    // NOTE: when the user's deficit already hits the gender
                    // safe-minimum floor, every rate resolves to the same
                    // floored calories — the "Capped at safe minimum" note
                    // under the timeline explains why the value won't move.
                    _computeRecommended();
                    _applyRecommendedToFields();
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
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          r.$2,
                          style: ZType.disp(
                            16,
                            color: isSelected ? accent : textPrimary,
                          ),
                        ),
                        Text(
                          r.$3.toUpperCase(),
                          style: ZType.lbl(
                            8,
                            color: isSelected ? accent : textMuted,
                            letterSpacing: 1,
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

  // ── B9: per-kg readout under Fat / Carbs ─────────────────────────────

  /// Small "X.X g/kg" caption under a macro field, mirroring the Protein
  /// field's per-kg slider read-out. Grams mode only — % mode has no grams.
  /// Hidden when bodyweight is unknown (no anchor for the ratio).
  Widget _buildMacroPerKgCaption(
    TextEditingController controller,
    Color textMuted,
  ) {
    final state = ref.watch(nutritionPreferencesProvider);
    final user = ref.watch(currentUserProvider).value;
    final weightKg = state.latestWeight ?? user?.weightKg;
    if (weightKg == null || weightKg <= 0) return const SizedBox.shrink();

    final grams = int.tryParse(controller.text) ?? 0;
    final ratio = grams / weightKg;
    return Padding(
      padding: const EdgeInsets.only(left: 110), // align with input column
      child: Row(
        children: [
          Icon(Icons.straighten, size: 10, color: textMuted),
          const SizedBox(width: 4),
          Text(
            '${ratio.toStringAsFixed(1)} g/kg',
            style: TextStyle(fontSize: 10, color: textMuted),
          ),
        ],
      ),
    );
  }

  // ── B8: live macro-split bar ─────────────────────────────────────────

  /// Horizontal stacked bar showing the P/C/F calorie proportions, updating
  /// live as the user edits. In grams mode the kcal are computed from grams;
  /// in % mode the entered percentages are used directly.
  Widget _buildMacroSplitBar(
    Color proteinColor,
    Color carbsColor,
    Color fatColor,
    Color textMuted,
  ) {
    final p = int.tryParse(_proteinController.text) ?? 0;
    final c = int.tryParse(_carbsController.text) ?? 0;
    final f = int.tryParse(_fatController.text) ?? 0;

    // Calorie contribution of each macro.
    final int pKcal;
    final int cKcal;
    final int fKcal;
    if (_isPercentageMode) {
      // % mode: the entered values already ARE the calorie shares.
      pKcal = p;
      cKcal = c;
      fKcal = f;
    } else {
      pKcal = p * 4;
      cKcal = c * 4;
      fKcal = f * 9;
    }
    final total = pKcal + cKcal + fKcal;
    if (total <= 0) return const SizedBox.shrink();

    final pPct = (pKcal / total * 100).round();
    final cPct = (cKcal / total * 100).round();
    final fPct = 100 - pPct - cPct; // absorb rounding

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                if (pKcal > 0)
                  Expanded(flex: pKcal, child: Container(color: proteinColor)),
                if (cKcal > 0)
                  Expanded(flex: cKcal, child: Container(color: carbsColor)),
                if (fKcal > 0)
                  Expanded(flex: fKcal, child: Container(color: fatColor)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Legend with each macro's % share.
        Row(
          children: [
            _splitLegendDot('P', pPct, proteinColor),
            const SizedBox(width: 10),
            _splitLegendDot('C', cPct, carbsColor),
            const SizedBox(width: 10),
            _splitLegendDot('F', fPct, fatColor),
          ],
        ),
      ],
    );
  }

  Widget _splitLegendDot(String label, int pct, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label $pct%',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── B7: diet preset chips ────────────────────────────────────────────

  /// Preset chip row. Selecting a preset overrides the goal-derived g/kg and
  /// recomputes the recommendation, then applies it to the fields.
  Widget _buildPresetChips(
    Color textPrimary,
    Color textMuted,
    Color elevated,
    Color accent,
  ) {
    const presets = [
      (MacroPreset.recommended, 'Recommended'),
      (MacroPreset.balanced, 'Balanced'),
      (MacroPreset.highProteinCut, 'High-Protein Cut'),
      (MacroPreset.keto, 'Keto'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ZealovaSectionKicker(
          AppLocalizations.of(context).editTargetsDietPreset,
        ),
        const SizedBox(height: 6),
        // Horizontally scrollable row so all chips sit on a single line —
        // adding a future preset (e.g. "Carb-Cycle") would otherwise
        // wrap to a second row. Right-edge fade hints at scrollability;
        // chips have intrinsic width so each label stays on one line.
        SizedBox(
          height: 32,
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: const [
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.92, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final entry = presets[i];
                final selected = _selectedPreset == entry.$1;
                return Align(
                  alignment: Alignment.center,
                  child: ZealovaChip(
                    label: entry.$2,
                    selected: selected,
                    onTap: () => _onPresetSelected(entry.$1),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// B7: select a diet preset — recompute the recommendation under the new
  /// preset's g/kg and apply it to the macro fields. Switches to grams mode
  /// (presets are bodyweight-anchored gram models).
  void _onPresetSelected(MacroPreset preset) {
    setState(() => _selectedPreset = preset);
    // Recompute `_recommendedX` under the new preset, then write the result
    // into the four fields.
    _computeRecommended();
    _applyRecommendedToFields();
  }

  /// Writes the freshly computed `_recommendedX` values into the four input
  /// fields (grams mode). Shared by the diet-preset chips AND the weekly-rate
  /// selector so BOTH immediately update the Calories + macro fields rather
  /// than only refreshing the "Rec:" label. Without this, tapping a rate pill
  /// looked like a no-op — the recommendation moved but the visible numbers
  /// never did (the calorie field still read whatever was typed).
  ///
  /// No-op when there's no computable recommendation (missing TDEE) — the
  /// chip/pill selection still sticks, there's just nothing to apply.
  void _applyRecommendedToFields() {
    final cal = _recommendedCalories;
    final protein = _recommendedProtein;
    final carbs = _recommendedCarbs;
    final fat = _recommendedFat;
    if (cal == null || protein == null || carbs == null || fat == null) {
      return;
    }
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
    _rememberCarbsFatRatio();
    _recalculate();
  }

  // ── B10: reset ───────────────────────────────────────────────────────

  /// Reverts the four macro fields + selected rate + preset to the values
  /// captured when the sheet opened.
  void _resetToInitial() {
    _balancing = true;
    _caloriesController.text = _initialCalories;
    _proteinController.text = _initialProtein;
    _carbsController.text = _initialCarbs;
    _fatController.text = _initialFat;
    _balancing = false;
    setState(() {
      _selectedRate = _initialRate;
      _selectedPreset = _initialPreset;
      _macroOverflowWarning = null;
      _isPercentageMode = false; // opening state is always grams mode
    });
    _rememberCarbsFatRatio();
    _computeRecommended();
    _recalculate();
  }

  // ── B11: inline non-blocking sanity warnings ─────────────────────────

  /// Builds zero or more non-blocking warning rows. These never gate Save —
  /// they only flag values that are likely unintended:
  ///   - entered calories ≥ TDEE on a Lose Fat goal (no deficit)
  ///   - entered calories below the gender-specific safe floor
  ///   - protein > ~2.6 g/kg (very high) or fat < ~0.5 g/kg (very low)
  List<Widget> _buildSanityWarnings(Color textMuted) {
    // % mode has no absolute grams/calories to sanity-check.
    if (_isPercentageMode) return const [];

    final warnings = <String>[];
    final prefs = ref.read(nutritionPreferencesProvider).preferences;
    final user = ref.read(currentUserProvider).value;
    final goal = prefs?.primaryGoalEnum;
    final tdee = prefs?.calculatedTdee;
    final enteredCal = int.tryParse(_caloriesController.text);

    // 1. No-deficit warning on a Lose Fat goal.
    if (goal == NutritionGoal.loseFat &&
        tdee != null &&
        tdee > 0 &&
        enteredCal != null &&
        enteredCal >= tdee) {
      warnings.add(
          "This won't create a deficit — calories meet or exceed your TDEE "
          '($tdee kcal).');
    }

    // 2. Below the safe calorie floor.
    if (enteredCal != null) {
      final gender = user?.gender ?? 'male';
      final floor = gender.toLowerCase() == 'female'
          ? NutritionCalculator.minCaloriesFemale
          : NutritionCalculator.minCaloriesMale;
      if (enteredCal < floor) {
        warnings.add(
            'Below the safe minimum of $floor kcal/day — check this is '
            'intended.');
      }
    }

    // 3. Extreme protein / fat g/kg.
    final weightKg =
        ref.read(nutritionPreferencesProvider).latestWeight ?? user?.weightKg;
    if (weightKg != null && weightKg > 0) {
      final protein = int.tryParse(_proteinController.text) ?? 0;
      final fat = int.tryParse(_fatController.text) ?? 0;
      final proteinPerKg = protein / weightKg;
      final fatPerKg = fat / weightKg;
      if (proteinPerKg > 2.6) {
        warnings.add(
            'Protein is very high (${proteinPerKg.toStringAsFixed(1)} g/kg) — '
            'check this is intended.');
      }
      if (fat > 0 && fatPerKg < 0.5) {
        warnings.add(
            'Fat is very low (${fatPerKg.toStringAsFixed(1)} g/kg) — '
            'check this is intended.');
      }
    }

    if (warnings.isEmpty) return const [];

    return [
      ...warnings.map((w) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    w,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.orange),
                    maxLines: 3,
                  ),
                ),
              ],
            ),
          )),
      const SizedBox(height: 4),
    ];
  }
}
