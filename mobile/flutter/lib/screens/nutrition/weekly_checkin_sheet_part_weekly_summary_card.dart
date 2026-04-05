part of 'weekly_checkin_sheet.dart';


// ─────────────────────────────────────────────────────────────────
// Weekly Summary Card
// ─────────────────────────────────────────────────────────────────

class _WeeklySummaryCard extends StatelessWidget {
  final WeeklySummaryData summary;
  final bool isDark;

  const _WeeklySummaryCard({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, size: 20, color: textMuted),
              const SizedBox(width: 12),
              Text(
                'This Week',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Days Logged',
                  value: '${summary.daysLogged}/7',
                  icon: Icons.check_circle,
                  color: isDark ? AppColors.green : AppColorsLight.green,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryMetric(
                  label: 'Avg Calories',
                  value: '${summary.avgCalories}',
                  icon: Icons.local_fire_department,
                  color: isDark ? AppColors.orange : AppColorsLight.orange,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Avg Protein',
                  value: '${summary.avgProtein}g',
                  icon: Icons.fitness_center,
                  color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryMetric(
                  label: 'Weight Change',
                  value: _formatWeightChange(summary.weightChange),
                  icon: Icons.trending_flat,
                  color: _getWeightChangeColor(summary.weightChange),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatWeightChange(double? change) {
    if (change == null) return 'N/A';
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)} kg';
  }

  Color _getWeightChangeColor(double? change) {
    if (change == null) return Colors.grey;
    if (change.abs() < 0.2) return isDark ? AppColors.cyan : AppColorsLight.cyan; // Stable
    if (change < 0) return isDark ? AppColors.green : AppColorsLight.green; // Loss
    return isDark ? AppColors.orange : AppColorsLight.orange; // Gain
  }
}


class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Detailed TDEE Card (MacroFactor-style with confidence intervals)
// ─────────────────────────────────────────────────────────────────

class _DetailedTdeeCard extends StatelessWidget {
  final DetailedTDEE detailedTdee;
  final bool isDark;

  const _DetailedTdeeCard({required this.detailedTdee, required this.isDark});

  /// Check if we have insufficient data for meaningful calculation
  bool get hasInsufficientData =>
      detailedTdee.tdee == 0 || !detailedTdee.hasReliableData;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = ThemeColors.of(context).accent;

    // Show insufficient data state for first-time users
    if (hasInsufficientData) {
      return _buildInsufficientDataState(textPrimary, textMuted, textSecondary, teal);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            teal.withValues(alpha: 0.15),
            teal.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: teal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_graph, size: 20, color: teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Adaptive TDEE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'EMA-smoothed calculation',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text(
                  '${detailedTdee.tdee}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: teal,
                  ),
                ),
                // Confidence interval
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    detailedTdee.uncertaintyDisplay,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: teal,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'calories/day',
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Confidence range bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${detailedTdee.confidenceLow}',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                    Text(
                      'Confidence Range',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    Text(
                      '${detailedTdee.confidenceHigh}',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: detailedTdee.dataQualityScore,
                    backgroundColor: textMuted.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(teal),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Weight trend
          Row(
            children: [
              Text(
                detailedTdee.weightTrend.directionEmoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Weight trend: ${detailedTdee.weightTrend.formattedWeeklyRate}',
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsufficientDataState(
    Color textPrimary,
    Color textMuted,
    Color textSecondary,
    Color teal,
  ) {
    final dataQualityPercent = (detailedTdee.dataQualityScore * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.elevated : AppColorsLight.elevated),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Header with icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.hourglass_empty, size: 32, color: Colors.orange),
          ),
          const SizedBox(height: 16),
          Text(
            'Building Your Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep logging your meals and weight to unlock personalized TDEE calculations.',
            style: TextStyle(fontSize: 14, color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.nearBlack : AppColorsLight.nearWhite).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Data Quality', style: TextStyle(fontSize: 13, color: textPrimary)),
                    Text(
                      '$dataQualityPercent%',
                      style: TextStyle(
                        fontSize: 13,
                        color: dataQualityPercent >= 60 ? AppColors.textPrimary : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: detailedTdee.dataQualityScore,
                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      dataQualityPercent >= 60 ? AppColors.textPrimary : Colors.orange,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Need 60% data quality for accurate calculations',
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: teal),
              const SizedBox(width: 8),
              Text(
                'Log meals consistently for best results',
                style: TextStyle(
                  fontSize: 13,
                  color: teal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Metabolic Adaptation Alert
// ─────────────────────────────────────────────────────────────────

class _MetabolicAdaptationAlert extends StatelessWidget {
  final MetabolicAdaptationInfo adaptation;
  final bool isDark;

  const _MetabolicAdaptationAlert({required this.adaptation, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Color based on severity
    Color alertColor;
    switch (adaptation.severity) {
      case 'high':
        alertColor = AppColors.textMuted;
        break;
      case 'medium':
        alertColor = AppColors.textSecondary;
        break;
      default:
        alertColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alertColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: alertColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                adaptation.isPlateau ? Icons.pause_circle : Icons.trending_down,
                color: alertColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  adaptation.isPlateau
                      ? 'Plateau Detected'
                      : 'Metabolic Adaptation Detected',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            adaptation.actionDescription,
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: alertColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb_outline, size: 16, color: alertColor),
                const SizedBox(width: 8),
                Text(
                  'Suggested: ${adaptation.actionDisplayName}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: alertColor,
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


// ─────────────────────────────────────────────────────────────────
// Adherence & Sustainability Card
// ─────────────────────────────────────────────────────────────────

class _AdherenceCard extends StatelessWidget {
  final AdherenceSummary adherence;
  final bool isDark;

  const _AdherenceCard({required this.adherence, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Sustainability color
    Color sustainColor;
    switch (adherence.sustainabilityRating) {
      case 'high':
        sustainColor = AppColors.textPrimary;
        break;
      case 'medium':
        sustainColor = AppColors.textSecondary;
        break;
      default:
        sustainColor = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, size: 20, color: textMuted),
              const SizedBox(width: 12),
              Text(
                'Adherence & Sustainability',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Adherence and Sustainability scores side by side
          Row(
            children: [
              Expanded(
                child: _ScoreCircle(
                  label: 'Adherence',
                  value: adherence.averageAdherence,
                  color: AppColors.textSecondary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ScoreCircle(
                  label: 'Sustainability',
                  value: adherence.sustainabilityScore * 100,
                  color: sustainColor,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rating chip
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sustainColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sustainColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    adherence.ratingEmoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${adherence.sustainabilityRating.toUpperCase()} SUSTAINABILITY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: sustainColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recommendation text
          if (adherence.recommendation.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black12 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tips_and_updates, size: 16, color: textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      adherence.recommendation,
                      style: TextStyle(fontSize: 12, color: textSecondary),
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


class _ScoreCircle extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isDark;

  const _ScoreCircle({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      children: [
        SizedBox(
          height: 80,
          width: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  value: value / 100,
                  strokeWidth: 8,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text(
                '${value.round()}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: textMuted),
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Multi-Option Recommendation Card (MacroFactor-style)
// ─────────────────────────────────────────────────────────────────

class _MultiOptionRecommendationCard extends StatelessWidget {
  final RecommendationOptions options;
  final String? selectedOption;
  final int? currentCalories;
  final ValueChanged<String> onOptionSelected;
  final bool isDark;

  const _MultiOptionRecommendationCard({
    required this.options,
    required this.selectedOption,
    this.currentCalories,
    required this.onOptionSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final teal = ThemeColors.of(context).accent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.route, size: 20, color: teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Your Path',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Select a recommendation based on your preference',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Option cards (no Apply button — it's in the sticky CTA)
          ...options.options.map((option) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RecommendationOptionCard(
              option: option,
              isSelected: selectedOption == option.optionType,
              isRecommended: options.recommendedOption == option.optionType,
              currentCalories: currentCalories,
              onTap: () => onOptionSelected(option.optionType),
              isDark: isDark,
            ),
          )),
        ],
      ),
    );
  }
}

