import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import 'scroll_hint_arrow.dart';

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
      "We'll use this to calculate your personalized targets",
      style: TextStyle(
        fontSize: 14,
        color: textSecondary,
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildNameInput(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color cardBorder,
  ) {
    final compact = widget.compact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 6 : 8),
              decoration: BoxDecoration(
                color: AppColors.electricBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(compact ? 8 : 10),
              ),
              child: Icon(Icons.person_outline, color: AppColors.electricBlue, size: compact ? 16 : 20),
            ),
            SizedBox(width: compact ? 8 : 12),
            Text(
              'What should we call you?',
              style: TextStyle(
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 8 : 12),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: TextField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                fontWeight: FontWeight.normal,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: compact ? 10 : 14),
              border: InputBorder.none,
            ),
            onChanged: (value) {
              if (value.trim().isNotEmpty) {
                widget.onNameChanged(value.trim());
              }
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.05);
  }

  Widget _buildDobGenderSection(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color cardBorder,
  ) {
    // Format DOB for display
    String dobDisplay = 'Select date';
    if (widget.dateOfBirth != null) {
      final dob = widget.dateOfBirth!;
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      dobDisplay = '${months[dob.month - 1]} ${dob.day}, ${dob.year}';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date of Birth input (compact)
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.cake_outlined, color: AppColors.accent, size: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'DOB',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  if (widget.age != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${widget.age}y',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showDatePicker(isDark),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          dobDisplay,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: widget.dateOfBirth != null ? FontWeight.w600 : FontWeight.normal,
                            color: widget.dateOfBirth != null
                                ? textPrimary
                                : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.calendar_today_outlined,
                        color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Gender selection
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.person_outline, color: AppColors.accent, size: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Gender',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildGenderChip(
                    isDark: isDark,
                    textPrimary: textPrimary,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    id: 'male',
                    label: 'M',
                  ),
                  _buildGenderChip(
                    isDark: isDark,
                    textPrimary: textPrimary,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    id: 'female',
                    label: 'F',
                  ),
                  _buildGenderChip(
                    isDark: isDark,
                    textPrimary: textPrimary,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    id: 'other',
                    label: 'Other',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05);
  }

  Widget _buildHeightWeightRow(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color cardBorder,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Height section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.height, color: AppColors.accent, size: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Height',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  _buildSmallUnitToggle(
                    isMetric: _heightInMetric,
                    metricLabel: 'cm',
                    imperialLabel: 'ft',
                    onChanged: (isMetric) {
                      _convertHeightUnits(isMetric);
                      setState(() => _heightInMetric = isMetric);
                    },
                    isDark: isDark,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_heightInMetric)
                _buildCompactTextField(
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
                      child: _buildCompactTextField(
                        controller: _heightFeetController,
                        hint: 'ft',
                        onChanged: (_) => _onHeightChanged(),
                        isDark: isDark,
                        textPrimary: textPrimary,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildCompactTextField(
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
          ),
        ),
        const SizedBox(width: 10),
        // Weight section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.monitor_weight_outlined, color: AppColors.accent, size: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Weight',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  _buildSmallUnitToggle(
                    isMetric: _weightInMetric,
                    metricLabel: 'kg',
                    imperialLabel: 'lb',
                    onChanged: (isMetric) {
                      _convertWeightUnits(isMetric);
                      setState(() => _weightInMetric = isMetric);
                      // Propagate weight unit change to parent for use in subsequent screens
                      widget.onUnitChanged(isMetric);
                    },
                    isDark: isDark,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildCompactTextField(
                controller: _weightController,
                hint: _weightInMetric ? 'kg' : 'lbs',
                onChanged: (_) => _onWeightChanged(),
                isDark: isDark,
                textPrimary: textPrimary,
                cardBg: cardBg,
                cardBorder: cardBorder,
                allowDecimal: true,
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.05);
  }

  Widget _buildCompactTextField({
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
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
            fontWeight: FontWeight.normal,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
        ),
        onChanged: onChanged,
      ),
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

  Widget _buildGenderChip({
    required bool isDark,
    required Color textPrimary,
    required Color cardBg,
    required Color cardBorder,
    required String id,
    required String label,
  }) {
    final isSelected = widget.gender == id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onGenderChanged(id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
                  ? LinearGradient(
                      colors: [AppColors.orange, AppColors.orange.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
          color: isSelected ? null : cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.orange : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSmallUnitToggle({
    required bool isMetric,
    required String metricLabel,
    required String imperialLabel,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
  }) {
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
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(true);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                gradient: isMetric ? orangeGradient : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                metricLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isMetric
                      ? Colors.white
                      : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(false);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                gradient: !isMetric ? orangeGradient : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                imperialLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: !isMetric
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
      color = AppColors.accent;
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
    final compact = widget.compact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 6 : 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(compact ? 8 : 10),
              ),
              child: Icon(Icons.flag_outlined, color: AppColors.success, size: compact ? 16 : 20),
            ),
            SizedBox(width: compact ? 8 : 12),
            Text(
              'Weight Goal',
              style: TextStyle(
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 8 : 12),

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
          gradient: isSelected
                  ? LinearGradient(
                      colors: [AppColors.orange, AppColors.orange.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
          color: isSelected
              ? null
              : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.orange : cardBorder,
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
    final unit = _weightInMetric ? 'kg' : 'lbs';
    final directionLabel = widget.weightDirection == 'lose' ? 'lose' : 'gain';
    const orange = Color(0xFFF97316);

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
              SizedBox(width: btnSpacing),
              // Tappable amount display
              GestureDetector(
                onTap: () => _showAmountInputDialog(isDark, textPrimary, textSecondary, unit),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: compact ? 4 : 8),
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: orange.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _weightChangeAmount.round().toString(),
                        style: TextStyle(
                          fontSize: amountFontSize,
                          fontWeight: FontWeight.bold,
                          color: orange,
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

  Widget _buildWeightGoalSlider(bool isDark, Color textSecondary, Color cardBorder) {
    final unit = _weightInMetric ? 'kg' : 'lbs';
    const minAmount = 0.5;
    const step = 0.5;
    const orange = Color(0xFFF97316);

    // Calculate max amount based on direction
    // For "lose": can't lose more than current weight minus 1 kg/lb (to stay positive)
    // For "gain": use default max (100kg or 200lbs)
    double defaultMax = _weightInMetric ? 100.0 : 200.0;
    double maxAmount = defaultMax;

    if (widget.weightDirection == 'lose' && widget.weightKg != null) {
      // Convert current weight to display unit if needed
      final currentWeightInUnit = _weightInMetric
          ? widget.weightKg!
          : widget.weightKg! * 2.20462;
      // Max loss is current weight minus 1 (can't go to 0 or negative)
      maxAmount = (currentWeightInUnit - 1).clamp(minAmount, defaultMax);
    }

    final divisions = ((maxAmount - minAmount) / step).toInt().clamp(1, 1000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: orange,
            inactiveTrackColor: orange.withValues(alpha: 0.2),
            thumbColor: orange,
            overlayColor: orange.withValues(alpha: 0.1),
            trackHeight: 6,
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
              Text('0.5 $unit', style: TextStyle(fontSize: 11, color: textSecondary)),
              Text('${maxAmount.toStringAsFixed(maxAmount == maxAmount.roundToDouble() ? 0 : 1)} $unit',
                   style: TextStyle(fontSize: 11, color: textSecondary)),
            ],
          ),
        ),
      ],
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

  void _showAmountInputDialog(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    String unit,
  ) {
    HapticFeedback.selectionClick();
    final controller = TextEditingController(text: _weightChangeAmount.round().toString());
    final directionLabel = widget.weightDirection == 'lose' ? 'lose' : 'gain';

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
              'Enter a value between 1-100 $unit',
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
              if (value != null && value >= 1 && value <= 100) {
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

  Widget _buildGoalSummary(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final unit = _weightInMetric ? 'kg' : 'lbs';
    final currentWeight = _weightInMetric
        ? widget.weightKg!
        : widget.weightKg! * 2.20462;

    // Use rounded current weight so the display math is consistent
    // (e.g. 100 kg - 5 kg = 95 kg, not 100.5 - 5.0 = 95.5 → 96)
    final roundedCurrentWeight = currentWeight.roundToDouble();
    double goalWeight;
    String message;

    if (widget.weightDirection == 'maintain') {
      goalWeight = roundedCurrentWeight;
      message = "Let's maintain your current weight!";
    } else if (widget.weightDirection == 'lose') {
      goalWeight = roundedCurrentWeight - _weightChangeAmount.roundToDouble();
      message = 'Target: ${goalWeight.round()} $unit';
    } else {
      goalWeight = roundedCurrentWeight + _weightChangeAmount.roundToDouble();
      message = 'Target: ${goalWeight.round()} $unit';
    }

    final isValid = goalWeight > 0 && goalWeight < 500;
    const orange = Color(0xFFF97316);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid
            ? orange.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid
              ? orange.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.weightDirection == 'maintain'
                ? Icons.check_circle_outline
                : Icons.trending_flat,
            color: isValid ? orange : AppColors.error,
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
                          color: isValid ? orange : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isValid ? textSecondary : AppColors.error,
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
