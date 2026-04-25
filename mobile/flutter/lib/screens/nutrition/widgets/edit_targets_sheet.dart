import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/posthog_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/utils/weight_utils.dart';
import '../../../data/models/nutrition_preferences.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../onboarding/widgets/calorie_macro_estimator.dart';
import 'nutrition_goals_card.dart' show showNutritionCalculationSheet;

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

    _caloriesController.addListener(_recalculate);
    _proteinController.addListener(_recalculate);
    _carbsController.addListener(_recalculate);
    _fatController.addListener(_recalculate);

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

    final macros = NutritionCalculator.calculateMacros(
      calories: recCalories,
      dietType: prefs.dietTypeEnum,
      customCarbPercent: prefs.customCarbPercent,
      customProteinPercent: prefs.customProteinPercent,
      customFatPercent: prefs.customFatPercent,
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

  void _onModeToggle(bool toPercentage) {
    final calories = int.tryParse(_caloriesController.text);
    if (calories == null || calories <= 0) return;

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

    setState(() => _isPercentageMode = toPercentage);
    _recalculate();
  }

  Future<void> _useRecommended() async {
    setState(() => _isLoadingRecommended = true);

    try {
      await ref
          .read(nutritionPreferencesProvider.notifier)
          .recalculateTargets(widget.userId);

      final prefs = ref.read(nutritionPreferencesProvider).preferences;
      if (prefs != null && mounted) {
        // Switch back to grams mode for clarity
        setState(() => _isPercentageMode = false);

        _caloriesController.text =
            (prefs.targetCalories ?? 2000).toString();
        _proteinController.text =
            (prefs.targetProteinG ?? 150).toString();
        _carbsController.text =
            (prefs.targetCarbsG ?? 200).toString();
        _fatController.text =
            (prefs.targetFatG ?? 65).toString();

        // Refresh recommended values too
        _computeRecommended();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load recommended: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
      if (prefs != null) {
        _caloriesController.text = (prefs.targetCalories ?? 2000).toString();
        _proteinController.text = (prefs.targetProteinG ?? 150).toString();
        _carbsController.text = (prefs.targetCarbsG ?? 200).toString();
        _fatController.text = (prefs.targetFatG ?? 65).toString();
        _selectedRate = prefs.rateOfChange;
      }
      _computeRecommended();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    // Sheet-wide accent — matches the user's AccentColorScope so the
    // Grams/Percentage toggle, Save button, Rate-of-Change pills, and
    // "Recalculate from profile" link all read in the same app-wide hue.
    final accent = AccentColorScope.of(context).getColor(isDark);
    // Per-macro colors for the row labels — mirrors the macro rings on the
    // Current Targets card (Calories=accent, P=purple, C=cyan, F=orange).
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

          // Toggle buttons
          Container(
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
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
    return Expanded(
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
              Text(
                '${currentRatio.toStringAsFixed(1)} g/kg · '
                '${(currentRatio * weightKg).round()}g for '
                '${fmt.format(weightKg.round())}kg',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              activeTrackColor: proteinColor,
              inactiveTrackColor: proteinColor.withValues(alpha: 0.18),
              thumbColor: proteinColor,
              overlayColor: proteinColor.withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
              activeTickMarkColor: proteinColor,
              inactiveTickMarkColor: proteinColor.withValues(alpha: 0.3),
            ),
            child: Slider(
              value: currentRatio,
              min: 0.8,
              max: 2.4,
              divisions: 16, // 0.1 g/kg granularity
              onChanged: (v) {
                final grams = (v * weightKg).round();
                _proteinController.text = grams.toString();
                _proteinController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _proteinController.text.length),
                );
                _recalculate();
              },
            ),
          ),
          // Stop labels — tap to snap.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: stops.map((s) {
                final isActive = (currentRatio - s).abs() < 0.05;
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
                    child: Text(
                      s.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                        color: isActive ? proteinColor : textMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(Color textMuted, Color teal) {
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
