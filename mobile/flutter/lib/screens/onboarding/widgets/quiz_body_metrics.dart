import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import 'scroll_hint_arrow.dart';

part 'quiz_body_metrics_ui.dart';

part 'quiz_body_metrics_ext.dart';


/// Quiz step for collecting body metrics: name, DOB, gender, height, current weight, and weight goal.
/// Uses two-step approach for weight goal: Direction (Lose/Gain/Maintain) + Amount.
class QuizBodyMetrics extends StatefulWidget {
  final String? name;
  final DateTime? dateOfBirth;
  final String? gender;  // 'male', 'female', or 'other'
  final double? heightCm;
  final double? weightKg;
  final double? goalWeightKg;
  final bool useMetric;
  final String? weightDirection;  // 'lose', 'gain', 'maintain'
  final double? weightChangeAmount;  // Amount to change in current unit
  final ValueChanged<String> onNameChanged;
  final ValueChanged<DateTime> onDateOfBirthChanged;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<double> onGoalWeightChanged;
  final ValueChanged<bool> onUnitChanged;
  final ValueChanged<String>? onWeightDirectionChanged;
  final ValueChanged<double>? onWeightChangeAmountChanged;
  final bool showHeader;
  /// When true, reduces spacing/padding to fit foldable right-pane without scrolling.
  final bool compact;
  /// Validation error for the name field. Shown inline below the text field.
  final String? nameError;

  const QuizBodyMetrics({
    super.key,
    this.name,
    this.dateOfBirth,
    this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.goalWeightKg,
    required this.useMetric,
    this.weightDirection,
    this.weightChangeAmount,
    required this.onNameChanged,
    required this.onDateOfBirthChanged,
    required this.onGenderChanged,
    required this.onHeightChanged,
    required this.onWeightChanged,
    required this.onGoalWeightChanged,
    required this.onUnitChanged,
    this.onWeightDirectionChanged,
    this.onWeightChangeAmountChanged,
    this.showHeader = true,
    this.compact = false,
    this.nameError,
  });

  /// Calculate age from date of birth
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  @override
  State<QuizBodyMetrics> createState() => _QuizBodyMetricsState();
}

class _QuizBodyMetricsState extends State<QuizBodyMetrics> {
  late TextEditingController _heightController;
  late TextEditingController _heightFeetController;
  late TextEditingController _heightInchesController;
  late TextEditingController _weightController;
  late TextEditingController _nameController;
  late ScrollController _scrollController;

  // Separate unit preferences for height and weight
  late bool _heightInMetric;
  late bool _weightInMetric;

  // Two-step weight goal
  double _weightChangeAmount = 10.0;  // Default 10 lbs or 5 kg

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Initialize name controller
    _nameController = TextEditingController(text: widget.name ?? '');
    // Initialize separate unit preferences (both start with the global preference)
    _heightInMetric = widget.useMetric;
    _weightInMetric = widget.useMetric;
    _initControllers();
    // Initialize weight change amount from widget or default
    if (widget.weightChangeAmount != null) {
      _weightChangeAmount = widget.weightChangeAmount!;
    } else {
      // Default to 10 lbs or ~5 kg
      _weightChangeAmount = _weightInMetric ? 5.0 : 10.0;
    }
  }

  void _initControllers() {
    // Height controllers
    if (_heightInMetric) {
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
    if (_weightInMetric) {
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
    // No longer need to respond to global unit change since we have per-field toggles
  }

  void _convertHeightUnits(bool toMetric) {
    if (toMetric) {
      // Imperial to Metric: ft/in to cm
      final feet = double.tryParse(_heightFeetController.text) ?? 0;
      final inches = double.tryParse(_heightInchesController.text) ?? 0;
      final totalInches = (feet * 12) + inches;
      final cm = totalInches * 2.54;
      _heightController.text = cm > 0 ? cm.toStringAsFixed(0) : '';
    } else {
      // Metric to Imperial: cm to ft/in
      final cm = double.tryParse(_heightController.text) ?? 0;
      final totalInches = cm / 2.54;
      final feet = (totalInches / 12).floor();
      final inches = (totalInches % 12).round();
      _heightFeetController.text = feet > 0 ? feet.toString() : '';
      _heightInchesController.text = inches > 0 ? inches.toString() : '';
    }
  }

  void _convertWeightUnits(bool toMetric) {
    if (toMetric) {
      // Imperial to Metric: lbs to kg
      final lbs = double.tryParse(_weightController.text) ?? 0;
      final kg = lbs / 2.20462;
      _weightController.text = kg > 0 ? kg.toStringAsFixed(1) : '';
      // Convert weight change amount from lbs to kg
      setState(() {
        _weightChangeAmount = _weightChangeAmount / 2.20462;
      });
    } else {
      // Metric to Imperial: kg to lbs
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
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onHeightChanged() {
    double? heightCm;
    if (_heightInMetric) {
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
      final kg = _weightInMetric ? value : value / 2.20462;
      widget.onWeightChanged(kg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use stronger, more visible colors with proper contrast
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);
    final cardBg = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final sectionGap = widget.compact ? 12.0 : 20.0;
    final goalGap = widget.compact ? 14.0 : 24.0;
    final bottomPad = widget.compact ? 8.0 : 60.0;

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.compact ? 16 : 24),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showHeader) ...[
                  _buildTitle(textPrimary),
                  const SizedBox(height: 6),
                  _buildSubtitle(textSecondary),
                  SizedBox(height: goalGap),
                ],

                // Name input (NEW)
                _buildNameInput(isDark, textPrimary, textSecondary, cardBg, cardBorder),
                SizedBox(height: sectionGap),

                // DOB and Gender inputs
                _buildDobGenderSection(isDark, textPrimary, textSecondary, cardBg, cardBorder),
                SizedBox(height: sectionGap),

                // Height and Weight in single row
                _buildHeightWeightRow(isDark, textPrimary, textSecondary, cardBg, cardBorder),

                // Two-step weight goal (only show if current weight is set)
                if (widget.weightKg != null) ...[
                  SizedBox(height: goalGap),
                  _buildWeightGoalSection(isDark, textPrimary, textSecondary, cardBg, cardBorder),
                ],

                SizedBox(height: bottomPad),
              ],
            ),
          ),
        ),
        if (!widget.compact) ScrollHintArrow(scrollController: _scrollController),
      ],
    );
  }

  Future<void> _showDatePicker(bool isDark) async {
    HapticFeedback.selectionClick();

    final now = DateTime.now();
    final initialDate = widget.dateOfBirth ?? DateTime(now.year - 25, now.month, now.day);
    const orange = Color(0xFFF97316); // App accent color

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 16, now.month, now.day), // Min 16 years old (health data + AI + payments)
      helpText: 'SELECT YOUR DATE OF BIRTH',
      cancelText: 'CANCEL',
      confirmText: 'OK',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: orange,
                    onPrimary: Colors.white,
                    surface: AppColors.elevated,
                    onSurface: AppColors.textPrimary,
                    secondary: orange,
                    onSecondary: Colors.white,
                  )
                : ColorScheme.light(
                    primary: orange,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppColorsLight.textPrimary,
                    secondary: orange,
                    onSecondary: Colors.white,
                  ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: orange,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      widget.onDateOfBirthChanged(picked);
    }
  }

  Widget _buildAmountInput(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color cardBorder,
  ) {
    final unit = _weightInMetric ? 'kg' : 'lbs';
    final directionLabel = widget.weightDirection == 'lose' ? 'lose' : 'gain';

    final compact = widget.compact;
    final cardPad = compact ? 12.0 : 16.0;
    final innerGap = compact ? 10.0 : 16.0;
    final amountFontSize = compact ? 28.0 : 36.0;
    final btnSpacing = compact ? 14.0 : 20.0;

    return Container(
      padding: EdgeInsets.all(cardPad),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with question and unit toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'How much do you want to $directionLabel?',
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                ),
              ),
              // Unit toggle (kg/lbs)
              _buildAmountUnitToggle(isDark, cardBg, cardBorder),
            ],
          ),
          SizedBox(height: innerGap),

          // +/- buttons with amount display (tap number to type)
          Builder(builder: (context) {
            final amountColor = _getWeightChangeColor(_weightChangeAmount);
            // Calculate max for stepper (same logic as slider)
            final minMax = _weightInMetric ? 5.0 : 11.0;
            double stepperMax;
            if (widget.weightDirection == 'lose' && widget.weightKg != null) {
              final cwu = _weightInMetric ? widget.weightKg! : widget.weightKg! * 2.20462;
              stepperMax = (cwu * 0.5).roundToDouble().clamp(minMax, cwu - 1);
            } else if (widget.weightDirection == 'gain') {
              final cwu = widget.weightKg != null
                  ? (_weightInMetric ? widget.weightKg! : widget.weightKg! * 2.20462)
                  : (_weightInMetric ? 70.0 : 154.0);
              stepperMax = (cwu * 0.5).roundToDouble().clamp(_weightInMetric ? 10.0 : 22.0, _weightInMetric ? 50.0 : 110.0);
            } else {
              stepperMax = _weightInMetric ? 40.0 : 88.0;
            }
            return Row(
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
                SizedBox(width: btnSpacing),
                // Tappable amount display
                GestureDetector(
                  onTap: () => _showAmountInputDialog(isDark, textPrimary, textSecondary, unit),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: compact ? 4 : 8),
                    decoration: BoxDecoration(
                      color: amountColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: amountColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _weightChangeAmount.round().toString(),
                          style: TextStyle(
                            fontSize: amountFontSize,
                            fontWeight: FontWeight.bold,
                            color: amountColor,
                          ),
                        ),
                        Text(
                          unit,
                          style: TextStyle(
                            fontSize: compact ? 12 : 14,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: btnSpacing),
                _buildIncrementButton(
                  icon: Icons.add,
                  onTap: () {
                    if (_weightChangeAmount < stepperMax) {
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
            );
          }),

          SizedBox(height: innerGap),

          // Weight goal slider
          _buildWeightGoalSlider(isDark, textSecondary, cardBorder),
        ],
      ),
    );
  }

  Widget _buildAmountUnitToggle(bool isDark, Color cardBg, Color cardBorder) {
    const orange = Color(0xFFF97316);
    const orangeGradient = LinearGradient(
      colors: [orange, Color(0xFFEA580C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (!_weightInMetric) {
                HapticFeedback.selectionClick();
                _convertWeightUnits(true);
                setState(() => _weightInMetric = true);
                widget.onUnitChanged(true);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: _weightInMetric ? orangeGradient : null,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'kg',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _weightInMetric
                      ? Colors.white
                      : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (_weightInMetric) {
                HapticFeedback.selectionClick();
                _convertWeightUnits(false);
                setState(() => _weightInMetric = false);
                widget.onUnitChanged(false);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: !_weightInMetric ? orangeGradient : null,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'lbs',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: !_weightInMetric
                      ? Colors.white
                      : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get health-aware color for weight change amount
  Color _getWeightChangeColor(double amount) {
    if (widget.weightKg == null || widget.weightKg! <= 0) return const Color(0xFFF97316);

    final currentWeightInUnit = _weightInMetric
        ? widget.weightKg!
        : widget.weightKg! * 2.20462;
    final percent = (amount / currentWeightInUnit) * 100;

    if (widget.weightDirection == 'gain') {
      // Gain: green up to 10%, orange up to 20%, red beyond
      if (percent <= 15) return const Color(0xFF22C55E);
      if (percent <= 30) return const Color(0xFFF97316);
      return const Color(0xFFEF4444);
    }

    // Lose: green up to 10%, orange up to 20%, red beyond
    if (percent <= 15) return const Color(0xFF22C55E);
    if (percent <= 30) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  /// Get health label for current weight change amount
  String _getWeightChangeLabel(double amount) {
    if (widget.weightKg == null || widget.weightKg! <= 0) return '';

    final currentWeightInUnit = _weightInMetric
        ? widget.weightKg!
        : widget.weightKg! * 2.20462;
    final percent = (amount / currentWeightInUnit) * 100;

    if (percent <= 5) return 'Gentle & sustainable';
    if (percent <= 15) return 'Healthy goal';
    if (percent <= 30) return 'Aggressive but achievable';
    return 'Consult a professional first';
  }

  Widget _buildWeightGoalSlider(bool isDark, Color textSecondary, Color cardBorder) {
    final unit = _weightInMetric ? 'kg' : 'lbs';
    const minAmount = 0.5;
    const step = 1.0;

    // Realistic max based on body weight
    // Lose: cap at 40% of current weight (min 5kg/11lbs so light users still have range)
    // Gain: cap at 30% of current weight (min 10kg/22lbs)
    double maxAmount;
    final minMax = _weightInMetric ? 5.0 : 11.0;

    if (widget.weightDirection == 'lose' && widget.weightKg != null) {
      final currentWeightInUnit = _weightInMetric
          ? widget.weightKg!
          : widget.weightKg! * 2.20462;
      maxAmount = (currentWeightInUnit * 0.5).roundToDouble().clamp(minMax, currentWeightInUnit - 1);
    } else if (widget.weightDirection == 'gain') {
      final currentWeightInUnit = widget.weightKg != null
          ? (_weightInMetric ? widget.weightKg! : widget.weightKg! * 2.20462)
          : (_weightInMetric ? 70.0 : 154.0);
      maxAmount = (currentWeightInUnit * 0.5).roundToDouble().clamp(_weightInMetric ? 10.0 : 22.0, _weightInMetric ? 50.0 : 110.0);
    } else {
      maxAmount = _weightInMetric ? 40.0 : 88.0;
    }

    final divisions = ((maxAmount - minAmount) / step).toInt().clamp(1, 200);
    final sliderColor = _getWeightChangeColor(_weightChangeAmount);
    final healthLabel = _getWeightChangeLabel(_weightChangeAmount);

    // Quick-select amounts based on direction
    final isLose = widget.weightDirection == 'lose';
    final quickAmounts = _weightInMetric
        ? (isLose ? [5.0, 10.0, 15.0, 20.0, 25.0] : [5.0, 10.0, 15.0, 20.0, 25.0])
        : (isLose ? [10.0, 20.0, 30.0, 45.0, 55.0] : [10.0, 20.0, 30.0, 45.0, 55.0]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: sliderColor,
            inactiveTrackColor: sliderColor.withValues(alpha: 0.15),
            thumbColor: sliderColor,
            overlayColor: sliderColor.withValues(alpha: 0.1),
            trackHeight: 6,
            tickMarkShape: RoundSliderTickMarkShape(tickMarkRadius: 2),
            activeTickMarkColor: Colors.white.withValues(alpha: 0.4),
            inactiveTickMarkColor: sliderColor.withValues(alpha: 0.25),
          ),
          child: Slider(
            value: _weightChangeAmount.clamp(minAmount, maxAmount),
            min: minAmount,
            max: maxAmount,
            divisions: divisions,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() {
                _weightChangeAmount = double.parse(value.toStringAsFixed(1));
              });
              widget.onWeightChangeAmountChanged?.call(_weightChangeAmount);
              if (widget.weightDirection != null) {
                _updateGoalWeight(widget.weightDirection!);
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${minAmount.toStringAsFixed(1)} $unit', style: TextStyle(fontSize: 11, color: textSecondary)),
              if (healthLabel.isNotEmpty)
                Text(
                  healthLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: sliderColor),
                ),
              Text('${maxAmount.round()} $unit', style: TextStyle(fontSize: 11, color: textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Quick-select chips
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: quickAmounts
              .where((v) => v <= maxAmount)
              .map((amount) {
            final isSelected = _weightChangeAmount.round() == amount.round();
            final prefix = isLose ? '-' : '+';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _weightChangeAmount = amount;
                  });
                  widget.onWeightChangeAmountChanged?.call(_weightChangeAmount);
                  if (widget.weightDirection != null) {
                    _updateGoalWeight(widget.weightDirection!);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? sliderColor.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? sliderColor.withValues(alpha: 0.6)
                          : cardBorder,
                    ),
                  ),
                  child: Text(
                    '$prefix${amount.round()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? sliderColor : textSecondary,
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

  void _showAmountInputDialog(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    String unit,
  ) {
    HapticFeedback.selectionClick();
    final controller = TextEditingController(text: _weightChangeAmount.round().toString());
    final directionLabel = widget.weightDirection == 'lose' ? 'lose' : 'gain';

    // Calculate realistic max (same logic as slider)
    final minMax = _weightInMetric ? 5.0 : 11.0;
    double dialogMax;
    if (widget.weightDirection == 'lose' && widget.weightKg != null) {
      final cwu = _weightInMetric ? widget.weightKg! : widget.weightKg! * 2.20462;
      dialogMax = (cwu * 0.5).roundToDouble().clamp(minMax, cwu - 1);
    } else if (widget.weightDirection == 'gain') {
      final cwu = widget.weightKg != null
          ? (_weightInMetric ? widget.weightKg! : widget.weightKg! * 2.20462)
          : (_weightInMetric ? 70.0 : 154.0);
      dialogMax = (cwu * 0.5).roundToDouble().clamp(_weightInMetric ? 10.0 : 22.0, _weightInMetric ? 50.0 : 110.0);
    } else {
      dialogMax = _weightInMetric ? 40.0 : 88.0;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Enter amount to $directionLabel',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF97316),
              ),
              decoration: InputDecoration(
                suffixText: unit,
                suffixStyle: TextStyle(
                  fontSize: 18,
                  color: textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFF97316)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFF97316), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}\.?\d{0,1}')),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a value between 1-${dialogMax.round()} $unit',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value >= 1 && value <= dialogMax) {
                setState(() {
                  _weightChangeAmount = value;
                });
                widget.onWeightChangeAmountChanged?.call(_weightChangeAmount);
                _updateGoalWeight(widget.weightDirection!);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _updateGoalWeight(String direction) {
    if (widget.weightKg == null) return;

    double goalWeightKg;
    if (direction == 'maintain') {
      goalWeightKg = widget.weightKg!.roundToDouble();
    } else {
      // Convert amount from display unit to kg, using rounded values
      // so the stored goal matches the displayed summary
      final amountKg = _weightInMetric
          ? _weightChangeAmount.roundToDouble()
          : _weightChangeAmount.roundToDouble() / 2.20462;

      final currentKgRounded = widget.weightKg!.roundToDouble();
      if (direction == 'lose') {
        goalWeightKg = currentKgRounded - amountKg;
      } else {
        goalWeightKg = currentKgRounded + amountKg;
      }
    }

    // Validate and update
    if (goalWeightKg > 0 && goalWeightKg < 500) {
      widget.onGoalWeightChanged(goalWeightKg);
    }
  }
}
