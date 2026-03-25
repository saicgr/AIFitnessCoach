import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/posthog_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/models/nutrition_preferences.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../onboarding/widgets/calorie_macro_estimator.dart';

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

    // Use the goal's calorie adjustment to get recommended calories
    final goal = prefs.primaryGoalEnum;
    final recCalories = tdee + goal.calorieAdjustment;

    // Use NutritionCalculator.calculateMacros for recommended macros
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
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;

    final calories = int.tryParse(_caloriesController.text);
    final canToggleToPercent = calories != null && calories > 0;

    // Percentage mode validation
    final percentOk = !_isPercentageMode || _percentageSum == 100;

    // Goal timeline
    final timelineWidget = _buildGoalTimeline(isDark, textMuted, teal);

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
                }, textPrimary, teal, surface),
                _toggleButton(
                  'Percentage',
                  _isPercentageMode,
                  canToggleToPercent
                      ? () {
                          if (!_isPercentageMode) _onModeToggle(true);
                        }
                      : null,
                  textPrimary,
                  teal,
                  surface,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Input fields
          _buildFieldRow(
            'Calories',
            _caloriesController,
            'kcal',
            _recommendedCalories,
            textPrimary,
            textMuted,
            elevated,
            teal,
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
            teal,
          ),
          const SizedBox(height: 8),
          _buildFieldRow(
            'Carbs',
            _carbsController,
            _isPercentageMode ? '%' : 'g',
            _isPercentageMode ? null : _recommendedCarbs,
            textPrimary,
            textMuted,
            elevated,
            teal,
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
            teal,
          ),
          const SizedBox(height: 8),

          // Info row
          _buildInfoRow(textMuted, teal),
          const SizedBox(height: 4),

          // Goal timeline
          if (timelineWidget != null) ...[
            timelineWidget,
            const SizedBox(height: 8),
          ],

          // Rate of change selector (only for lose/gain goals)
          if (_showRateSelector) ...[
            _buildRateSelector(isDark, textPrimary, textMuted, teal),
            const SizedBox(height: 8),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoadingRecommended ? null : _useRecommended,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: teal,
                    side: BorderSide(color: teal.withValues(alpha: 0.5)),
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
                            color: teal,
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
                    backgroundColor: teal,
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
    Color teal,
    Color surface,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? teal : Colors.transparent,
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
    Color teal, {
    bool isCalories = false,
  }) {
    return Row(
      children: [
        // Label + recommended
        SizedBox(
          width: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
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
                      color: teal.withValues(alpha: 0.7),
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

    // Map rate of change
    final rateStr = prefs.rateOfChange ?? 'moderate';

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

  Widget _buildRateSelector(bool isDark, Color textPrimary, Color textMuted, Color teal) {
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
                  onTap: () => setState(() => _selectedRate = r.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? teal.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? teal : textMuted.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          r.$2,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? teal : textPrimary,
                          ),
                        ),
                        Text(
                          r.$3,
                          style: TextStyle(
                            fontSize: 9,
                            color: isSelected ? teal : textMuted,
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
