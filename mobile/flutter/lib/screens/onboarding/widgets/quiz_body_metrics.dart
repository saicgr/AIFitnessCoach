import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';

/// Quiz step for collecting body metrics: height, current weight, and weight goal.
/// Uses two-step approach for weight goal: Direction (Lose/Gain/Maintain) + Amount.
class QuizBodyMetrics extends StatefulWidget {
  final double? heightCm;
  final double? weightKg;
  final double? goalWeightKg;
  final bool useMetric;
  final String? weightDirection;  // 'lose', 'gain', 'maintain'
  final double? weightChangeAmount;  // Amount to change in current unit
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<double> onGoalWeightChanged;
  final ValueChanged<bool> onUnitChanged;
  final ValueChanged<String>? onWeightDirectionChanged;
  final ValueChanged<double>? onWeightChangeAmountChanged;

  const QuizBodyMetrics({
    super.key,
    required this.heightCm,
    required this.weightKg,
    required this.goalWeightKg,
    required this.useMetric,
    this.weightDirection,
    this.weightChangeAmount,
    required this.onHeightChanged,
    required this.onWeightChanged,
    required this.onGoalWeightChanged,
    required this.onUnitChanged,
    this.onWeightDirectionChanged,
    this.onWeightChangeAmountChanged,
  });

  @override
  State<QuizBodyMetrics> createState() => _QuizBodyMetricsState();
}

class _QuizBodyMetricsState extends State<QuizBodyMetrics> {
  late TextEditingController _heightController;
  late TextEditingController _heightFeetController;
  late TextEditingController _heightInchesController;
  late TextEditingController _weightController;

  // Two-step weight goal
  double _weightChangeAmount = 10.0;  // Default 10 lbs or 5 kg

  @override
  void initState() {
    super.initState();
    _initControllers();
    // Initialize weight change amount from widget or default
    if (widget.weightChangeAmount != null) {
      _weightChangeAmount = widget.weightChangeAmount!;
    } else {
      // Default to 10 lbs or ~5 kg
      _weightChangeAmount = widget.useMetric ? 5.0 : 10.0;
    }
  }

  void _initControllers() {
    // Height controllers
    if (widget.useMetric) {
      _heightController = TextEditingController(
        text: widget.heightCm != null ? widget.heightCm!.toStringAsFixed(0) : '',
      );
      _heightFeetController = TextEditingController();
      _heightInchesController = TextEditingController();
    } else {
      _heightController = TextEditingController();
      if (widget.heightCm != null) {
        final totalInches = widget.heightCm! / 2.54;
        final feet = (totalInches / 12).floor();
        final inches = (totalInches % 12).round();
        _heightFeetController = TextEditingController(text: feet.toString());
        _heightInchesController = TextEditingController(text: inches.toString());
      } else {
        _heightFeetController = TextEditingController();
        _heightInchesController = TextEditingController();
      }
    }

    // Weight controller
    if (widget.useMetric) {
      _weightController = TextEditingController(
        text: widget.weightKg != null ? widget.weightKg!.toStringAsFixed(1) : '',
      );
    } else {
      _weightController = TextEditingController(
        text: widget.weightKg != null ? (widget.weightKg! * 2.20462).toStringAsFixed(1) : '',
      );
    }
  }

  @override
  void didUpdateWidget(QuizBodyMetrics oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.useMetric != widget.useMetric) {
      _convertUnits(widget.useMetric);
    }
  }

  void _convertUnits(bool toMetric) {
    if (toMetric) {
      // Imperial to Metric
      // Height: ft/in to cm
      final feet = double.tryParse(_heightFeetController.text) ?? 0;
      final inches = double.tryParse(_heightInchesController.text) ?? 0;
      final totalInches = (feet * 12) + inches;
      final cm = totalInches * 2.54;
      _heightController.text = cm > 0 ? cm.toStringAsFixed(0) : '';

      // Weight: lbs to kg
      final lbs = double.tryParse(_weightController.text) ?? 0;
      final kg = lbs / 2.20462;
      _weightController.text = kg > 0 ? kg.toStringAsFixed(1) : '';

      // Convert weight change amount from lbs to kg
      setState(() {
        _weightChangeAmount = _weightChangeAmount / 2.20462;
      });
    } else {
      // Metric to Imperial
      // Height: cm to ft/in
      final cm = double.tryParse(_heightController.text) ?? 0;
      final totalInches = cm / 2.54;
      final feet = (totalInches / 12).floor();
      final inches = (totalInches % 12).round();
      _heightFeetController.text = feet > 0 ? feet.toString() : '';
      _heightInchesController.text = inches > 0 ? inches.toString() : '';

      // Weight: kg to lbs
      final kg = double.tryParse(_weightController.text) ?? 0;
      final lbs = kg * 2.20462;
      _weightController.text = lbs > 0 ? lbs.toStringAsFixed(1) : '';

      // Convert weight change amount from kg to lbs
      setState(() {
        _weightChangeAmount = _weightChangeAmount * 2.20462;
      });
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onHeightChanged() {
    double? heightCm;
    if (widget.useMetric) {
      heightCm = double.tryParse(_heightController.text);
    } else {
      final feet = double.tryParse(_heightFeetController.text) ?? 0;
      final inches = double.tryParse(_heightInchesController.text) ?? 0;
      final totalInches = (feet * 12) + inches;
      heightCm = totalInches * 2.54;
    }
    if (heightCm != null && heightCm > 0) {
      widget.onHeightChanged(heightCm);
    }
  }

  void _onWeightChanged() {
    final value = double.tryParse(_weightController.text);
    if (value != null && value > 0) {
      final kg = widget.useMetric ? value : value / 2.20462;
      widget.onWeightChanged(kg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(textPrimary),
            const SizedBox(height: 6),
            _buildSubtitle(textSecondary),
            const SizedBox(height: 20),

            // Unit toggle
            _buildUnitToggle(isDark, textPrimary, cardBg, cardBorder),
            const SizedBox(height: 24),

            // Height input
            _buildHeightInput(isDark, textPrimary, textSecondary, cardBg, cardBorder),
            const SizedBox(height: 20),

            // Current weight input
            _buildWeightInput(
              isDark,
              textPrimary,
              textSecondary,
              cardBg,
              cardBorder,
              label: 'Current Weight',
              hint: widget.useMetric ? 'kg' : 'lbs',
              controller: _weightController,
              onChanged: _onWeightChanged,
              icon: Icons.monitor_weight_outlined,
              color: AppColors.purple,
              delay: 400,
            ),

            // Two-step weight goal (only show if current weight is set)
            if (widget.weightKg != null) ...[
              const SizedBox(height: 24),
              _buildWeightGoalSection(isDark, textPrimary, textSecondary, cardBg, cardBorder),
            ],

            // BMI indicator (if both height and weight are set)
            if (widget.heightCm != null && widget.weightKg != null) ...[
              const SizedBox(height: 24),
              _buildBmiIndicator(isDark, textPrimary, textSecondary, cardBg),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(Color textPrimary) {
    return Text(
      "Let's set your body goals",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        height: 1.3,
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05);
  }

  Widget _buildSubtitle(Color textSecondary) {
    return Text(
      "We'll use this to predict when you'll reach your goal",
      style: TextStyle(
        fontSize: 14,
        color: textSecondary,
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildUnitToggle(bool isDark, Color textPrimary, Color cardBg, Color cardBorder) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildUnitOption(
            label: 'Metric',
            subtitle: 'kg, cm',
            isSelected: widget.useMetric,
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onUnitChanged(true);
              _saveUnitPreference(true);
            },
            isDark: isDark,
            textPrimary: textPrimary,
          ),
          _buildUnitOption(
            label: 'Imperial',
            subtitle: 'lbs, ft/in',
            isSelected: !widget.useMetric,
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onUnitChanged(false);
              _saveUnitPreference(false);
            },
            isDark: isDark,
            textPrimary: textPrimary,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _buildUnitOption({
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color textPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.cyanGradient : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white70 : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveUnitPreference(bool useMetric) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('preAuth_useMetric', useMetric);
  }

  Widget _buildHeightInput(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color cardBorder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.height, color: AppColors.cyan, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Height',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.useMetric)
          _buildTextField(
            controller: _heightController,
            hint: 'cm',
            onChanged: (_) => _onHeightChanged(),
            isDark: isDark,
            textPrimary: textPrimary,
            cardBg: cardBg,
            cardBorder: cardBorder,
          )
        else
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _heightFeetController,
                  hint: 'ft',
                  onChanged: (_) => _onHeightChanged(),
                  isDark: isDark,
                  textPrimary: textPrimary,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _heightInchesController,
                  hint: 'in',
                  onChanged: (_) => _onHeightChanged(),
                  isDark: isDark,
                  textPrimary: textPrimary,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                ),
              ),
            ],
          ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05);
  }

  Widget _buildWeightInput(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color cardBorder, {
    required String label,
    required String hint,
    required TextEditingController controller,
    required VoidCallback onChanged,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: controller,
          hint: hint,
          onChanged: (_) => onChanged(),
          isDark: isDark,
          textPrimary: textPrimary,
          cardBg: cardBg,
          cardBorder: cardBorder,
          allowDecimal: true,
        ),
      ],
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.05);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
    required bool isDark,
    required Color textPrimary,
    required Color cardBg,
    required Color cardBorder,
    bool allowDecimal = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            allowDecimal ? RegExp(r'^\d*\.?\d*') : RegExp(r'\d*'),
          ),
        ],
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            fontWeight: FontWeight.normal,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          suffixText: hint,
          suffixStyle: TextStyle(
            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            fontSize: 14,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildBmiIndicator(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
  ) {
    final heightM = widget.heightCm! / 100;
    final bmi = widget.weightKg! / (heightM * heightM);

    String category;
    Color color;
    if (bmi < 18.5) {
      category = 'Underweight';
      color = AppColors.warning;
    } else if (bmi < 25) {
      category = 'Normal';
      color = AppColors.success;
    } else if (bmi < 30) {
      category = 'Overweight';
      color = AppColors.orange;
    } else {
      category = 'Obese';
      color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.insights_outlined, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current BMI: ${bmi.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildWeightGoalSection(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color cardBorder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.flag_outlined, color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Weight Goal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Direction chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildDirectionChip(
              isDark: isDark,
              textPrimary: textPrimary,
              cardBorder: cardBorder,
              id: 'lose',
              emoji: '🔥',
              label: 'Lose',
            ),
            _buildDirectionChip(
              isDark: isDark,
              textPrimary: textPrimary,
              cardBorder: cardBorder,
              id: 'gain',
              emoji: '💪',
              label: 'Gain',
            ),
            _buildDirectionChip(
              isDark: isDark,
              textPrimary: textPrimary,
              cardBorder: cardBorder,
              id: 'maintain',
              emoji: '✨',
              label: 'Maintain',
            ),
          ],
        ),

        // Amount input (only show if lose or gain selected)
        if (widget.weightDirection == 'lose' || widget.weightDirection == 'gain') ...[
          const SizedBox(height: 16),
          _buildAmountInput(isDark, textPrimary, textSecondary, cardBg, cardBorder),
        ],

        // Goal weight summary (if direction is set and either maintain or has amount)
        if (widget.weightDirection != null) ...[
          const SizedBox(height: 16),
          _buildGoalSummary(isDark, textPrimary, textSecondary),
        ],
      ],
    ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.05);
  }

  Widget _buildDirectionChip({
    required bool isDark,
    required Color textPrimary,
    required Color cardBorder,
    required String id,
    required String emoji,
    required String label,
  }) {
    final isSelected = widget.weightDirection == id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onWeightDirectionChanged?.call(id);
        _updateGoalWeight(id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.cyanGradient : null,
          color: isSelected
              ? null
              : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.cyan : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color cardBorder,
  ) {
    final unit = widget.useMetric ? 'kg' : 'lbs';
    final directionLabel = widget.weightDirection == 'lose' ? 'lose' : 'gain';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How much do you want to $directionLabel?',
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // +/- buttons with amount display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIncrementButton(
                icon: Icons.remove,
                onTap: () {
                  if (_weightChangeAmount > 1) {
                    setState(() {
                      _weightChangeAmount -= 1;
                    });
                    widget.onWeightChangeAmountChanged?.call(_weightChangeAmount);
                    _updateGoalWeight(widget.weightDirection!);
                  }
                },
                isDark: isDark,
                cardBorder: cardBorder,
              ),
              const SizedBox(width: 20),
              Column(
                children: [
                  Text(
                    _weightChangeAmount.round().toString(),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              _buildIncrementButton(
                icon: Icons.add,
                onTap: () {
                  if (_weightChangeAmount < 100) {
                    setState(() {
                      _weightChangeAmount += 1;
                    });
                    widget.onWeightChangeAmountChanged?.call(_weightChangeAmount);
                    _updateGoalWeight(widget.weightDirection!);
                  }
                },
                isDark: isDark,
                cardBorder: cardBorder,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncrementButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required Color cardBorder,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Icon(
          icon,
          color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildGoalSummary(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final unit = widget.useMetric ? 'kg' : 'lbs';
    final currentWeight = widget.useMetric
        ? widget.weightKg!
        : widget.weightKg! * 2.20462;

    double goalWeight;
    String message;

    if (widget.weightDirection == 'maintain') {
      goalWeight = currentWeight;
      message = "Let's maintain your current weight!";
    } else if (widget.weightDirection == 'lose') {
      goalWeight = currentWeight - _weightChangeAmount;
      message = 'Target: ${goalWeight.round()} $unit';
    } else {
      goalWeight = currentWeight + _weightChangeAmount;
      message = 'Target: ${goalWeight.round()} $unit';
    }

    final isValid = goalWeight > 0 && goalWeight < 500;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.weightDirection == 'maintain'
                ? Icons.check_circle_outline
                : Icons.trending_flat,
            color: isValid ? AppColors.success : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.weightDirection != 'maintain') ...[
                  Row(
                    children: [
                      Text(
                        '${currentWeight.round()} $unit',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                      Icon(
                        widget.weightDirection == 'lose'
                            ? Icons.arrow_forward
                            : Icons.arrow_forward,
                        color: textSecondary,
                        size: 16,
                      ),
                      Text(
                        '${goalWeight.round()} $unit',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isValid ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: isValid ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateGoalWeight(String direction) {
    if (widget.weightKg == null) return;

    double goalWeightKg;
    if (direction == 'maintain') {
      goalWeightKg = widget.weightKg!;
    } else {
      // Convert amount from display unit to kg
      final amountKg = widget.useMetric
          ? _weightChangeAmount
          : _weightChangeAmount / 2.20462;

      if (direction == 'lose') {
        goalWeightKg = widget.weightKg! - amountKg;
      } else {
        goalWeightKg = widget.weightKg! + amountKg;
      }
    }

    // Validate and update
    if (goalWeightKg > 0 && goalWeightKg < 500) {
      widget.onGoalWeightChanged(goalWeightKg);
    }
  }
}
