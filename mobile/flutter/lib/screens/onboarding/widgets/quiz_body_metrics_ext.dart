part of 'quiz_body_metrics.dart';

/// Methods extracted from _QuizBodyMetricsState
extension __QuizBodyMetricsStateExt on _QuizBodyMetricsState {

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

}
