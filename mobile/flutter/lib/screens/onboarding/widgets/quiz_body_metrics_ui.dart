part of 'quiz_body_metrics.dart';

/// UI builder methods extracted from _QuizBodyMetricsState
extension _QuizBodyMetricsStateUI on _QuizBodyMetricsState {

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
            border: Border.all(
              color: widget.nameError != null ? Colors.red.shade400 : cardBorder,
            ),
          ),
          child: TextField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w300,
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
              widget.onNameChanged(value.trim());
            },
          ),
        ),
        if (widget.nameError != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.red.shade400),
              const SizedBox(width: 4),
              Text(
                widget.nameError!,
                style: TextStyle(fontSize: 12, color: Colors.red.shade400),
              ),
            ],
          ),
        ],
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
          flex: 4,
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
          flex: 4,
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
              Row(
                children: [
                  Expanded(
                    child: _buildGenderChip(
                      isDark: isDark,
                      textPrimary: textPrimary,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      id: 'male',
                      label: 'M',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildGenderChip(
                      isDark: isDark,
                      textPrimary: textPrimary,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      id: 'female',
                      label: 'F',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildGenderChip(
                      isDark: isDark,
                      textPrimary: textPrimary,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      id: 'other',
                      label: 'Other',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05);
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
    FocusNode? focusNode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : textPrimary,
            ),
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
    if (widget.heightCm == null || widget.weightKg == null) {
      return const SizedBox.shrink();
    }
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
    final summaryColor = widget.weightDirection == 'maintain'
        ? const Color(0xFF22C55E)
        : _getWeightChangeColor(_weightChangeAmount);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid
            ? summaryColor.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid
              ? summaryColor.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.weightDirection == 'maintain'
                ? Icons.check_circle_outline
                : Icons.trending_flat,
            color: isValid ? summaryColor : AppColors.error,
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
                          color: isValid ? summaryColor : AppColors.error,
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

}
