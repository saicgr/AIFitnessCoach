import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/glass_sheet.dart';

/// A bottom sheet widget for editing the daily step goal.
///
/// Features:
/// - Slider from 1000 to 15000 steps
/// - Preset buttons: 5000, 7500, 10000, 12000
/// - "Use Progressive Goal" toggle with explanation
/// - Save/Cancel buttons
class StepGoalEditorSheet extends StatefulWidget {
  /// The current step goal
  final int currentGoal;

  /// Whether progressive goals are enabled
  final bool useProgressiveGoal;

  /// Callback when the goal is saved
  final void Function(int goal, bool useProgressive)? onSave;

  /// Whether to use dark theme
  final bool isDark;

  const StepGoalEditorSheet({
    super.key,
    required this.currentGoal,
    this.useProgressiveGoal = false,
    this.onSave,
    this.isDark = true,
  });

  /// Shows the step goal editor as a bottom sheet
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required int currentGoal,
    bool useProgressiveGoal = false,
    bool isDark = true,
  }) {
    return showGlassSheet<Map<String, dynamic>>(
      context: context,
      useRootNavigator: true,
      builder: (context) => StepGoalEditorSheet(
        currentGoal: currentGoal,
        useProgressiveGoal: useProgressiveGoal,
        isDark: isDark,
      ),
    );
  }

  @override
  State<StepGoalEditorSheet> createState() => _StepGoalEditorSheetState();
}

class _StepGoalEditorSheetState extends State<StepGoalEditorSheet> {
  late int _selectedGoal;
  late bool _useProgressiveGoal;

  static const int _minGoal = 1000;
  static const int _maxGoal = 15000;
  static const int _step = 500;

  static const List<int> _presets = [5000, 7500, 10000, 12000];

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.currentGoal.clamp(_minGoal, _maxGoal);
    _useProgressiveGoal = widget.useProgressiveGoal;
  }

  void _setGoal(int goal) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedGoal = goal.clamp(_minGoal, _maxGoal);
    });
  }

  void _save() {
    HapticFeedback.mediumImpact();
    widget.onSave?.call(_selectedGoal, _useProgressiveGoal);
    Navigator.pop(context, {
      'goal': _selectedGoal,
      'useProgressive': _useProgressiveGoal,
    });
  }

  void _cancel() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final electricBlue = isDark ? AppColors.electricBlue : AppColorsLight.electricBlue;
    final success = isDark ? AppColors.success : AppColorsLight.success;

    return GlassSheet(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.of(context).viewPadding.bottom + 20,
          ),
          child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(
                Icons.flag_rounded,
                color: electricBlue,
                size: 24,
                semanticLabel: 'Goal',
              ),
              const SizedBox(width: 12),
              Text(
                'Set Step Goal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Current value display
          Center(
            child: Semantics(
              label: 'Selected goal: $_selectedGoal steps',
              child: Column(
                children: [
                  Text(
                    _formatNumber(_selectedGoal),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: electricBlue,
                      letterSpacing: -2,
                    ),
                  ),
                  Text(
                    'steps per day',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Slider
          Semantics(
            label: 'Step goal slider, from $_minGoal to $_maxGoal steps',
            slider: true,
            value: '$_selectedGoal steps',
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: electricBlue,
                inactiveTrackColor: elevated,
                thumbColor: electricBlue,
                overlayColor: electricBlue.withOpacity(0.2),
                trackHeight: 8,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
              ),
              child: Slider(
                value: _selectedGoal.toDouble(),
                min: _minGoal.toDouble(),
                max: _maxGoal.toDouble(),
                divisions: (_maxGoal - _minGoal) ~/ _step,
                onChanged: (value) => _setGoal(value.round()),
              ),
            ),
          ),

          // Min/Max labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_minGoal ~/ 1000}k',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                  ),
                ),
                Text(
                  '${_maxGoal ~/ 1000}k',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Preset buttons
          Text(
            'QUICK SELECT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: _presets.map((preset) {
              final isSelected = _selectedGoal == preset;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Semantics(
                    label: '${preset ~/ 1000}${preset % 1000 == 500 ? '.5' : ''}k steps preset${isSelected ? ', selected' : ''}',
                    button: true,
                    selected: isSelected,
                    child: GestureDetector(
                      onTap: () => _setGoal(preset),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? electricBlue : elevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? electricBlue
                                : textMuted.withOpacity(0.2),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _formatPreset(preset),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Progressive goal toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _useProgressiveGoal
                    ? success.withOpacity(0.4)
                    : textMuted.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  toggled: _useProgressiveGoal,
                  label: 'Use Progressive Goal',
                  hint: 'Automatically increases your goal as you improve',
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  size: 18,
                                  color: success,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Use Progressive Goal',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Automatically increases your goal as you improve',
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _useProgressiveGoal,
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          setState(() => _useProgressiveGoal = value);
                        },
                        activeColor: success,
                      ),
                    ],
                  ),
                ),

                if (_useProgressiveGoal) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'When you hit your goal 5 days in a row, we\'ll increase it by 500 steps. Missing 3 days will reset to your base goal.',
                            style: TextStyle(
                              fontSize: 12,
                              color: success,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Cancel',
                  child: OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textSecondary,
                      side: BorderSide(color: textMuted.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Semantics(
                  button: true,
                  label: 'Save goal of $_selectedGoal steps',
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: electricBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Goal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
          ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      final thousands = number / 1000;
      if (number % 1000 == 0) {
        return '${thousands.toInt()},000';
      }
      return '${thousands.toStringAsFixed(1).replaceAll('.', ',')}00';
    }
    return number.toString();
  }

  String _formatPreset(int preset) {
    final thousands = preset ~/ 1000;
    final hundreds = (preset % 1000) ~/ 100;
    if (hundreds == 0) {
      return '${thousands}k';
    }
    return '$thousands.${hundreds}k';
  }
}
