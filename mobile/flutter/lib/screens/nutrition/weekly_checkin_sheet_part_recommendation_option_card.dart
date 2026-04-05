part of 'weekly_checkin_sheet.dart';


class _RecommendationOptionCard extends StatelessWidget {
  final RecommendationOption option;
  final bool isSelected;
  final bool isRecommended;
  final int? currentCalories;
  final VoidCallback onTap;
  final bool isDark;

  const _RecommendationOptionCard({
    required this.option,
    required this.isSelected,
    required this.isRecommended,
    this.currentCalories,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = ThemeColors.of(context).accent;

    // Use accent color for selected state
    final optionColor = teal;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? optionColor.withValues(alpha: 0.15)
              : isDark
                  ? Colors.black12
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? optionColor
                : isDark
                    ? Colors.white10
                    : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  option.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            option.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: teal.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'RECOMMENDED',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: teal,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        option.formattedWeeklyChange,
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                      if (currentCalories != null && currentCalories! > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatCalorieDelta(currentCalories!, option.calories),
                          style: TextStyle(
                            fontSize: 11,
                            color: teal,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Radio indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? optionColor : textMuted,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: optionColor,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Macros row
            Row(
              children: [
                _MacroChip(
                  label: '${option.calories} cal',
                  color: teal,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _MacroChip(
                  label: '${option.proteinG}g P',
                  color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _MacroChip(
                  label: '${option.carbsG}g C',
                  color: isDark ? AppColors.orange : AppColorsLight.orange,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _MacroChip(
                  label: '${option.fatG}g F',
                  color: isDark ? AppColors.purple : AppColorsLight.purple,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              option.description,
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCalorieDelta(int current, int target) {
    final delta = target - current;
    final sign = delta >= 0 ? '+' : '';
    return '$current \u2192 $target ($sign$delta cal)';
  }
}


class _MacroChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _MacroChip({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Adaptive TDEE Card (Legacy fallback)
// ─────────────────────────────────────────────────────────────────

class _AdaptiveTdeeCard extends StatelessWidget {
  final AdaptiveCalculation calculation;
  final bool isDark;

  const _AdaptiveTdeeCard({required this.calculation, required this.isDark});

  /// Check if we have insufficient data for meaningful calculation
  bool get hasInsufficientData =>
      calculation.calculatedTdee == 0 || calculation.daysLogged < 6 || calculation.weightEntries < 2;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final teal = ThemeColors.of(context).accent;

    // Show insufficient data state
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
                      'Based on actual intake & weight changes',
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
                  '${calculation.calculatedTdee}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: teal,
                  ),
                ),
                Text(
                  'calories/day',
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Confidence indicator
          Row(
            children: [
              Icon(
                calculation.dataQualityScore >= 0.7
                    ? Icons.verified
                    : Icons.info_outline,
                size: 16,
                color: calculation.dataQualityScore >= 0.7
                    ? AppColors.textPrimary
                    : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getConfidenceMessage(calculation.dataQualityScore),
                  style: TextStyle(fontSize: 12, color: textSecondary),
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
    final daysNeeded = 6 - calculation.daysLogged;
    final weightsNeeded = 2 - calculation.weightEntries;

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
            'Keep Logging!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We need a bit more data to calculate your personalized TDEE.',
            style: TextStyle(fontSize: 14, color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Progress indicators
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.nearBlack : AppColorsLight.nearWhite).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Food logging progress
                _buildProgressRow(
                  icon: Icons.restaurant,
                  label: 'Food Logging',
                  current: calculation.daysLogged,
                  target: 6,
                  color: calculation.daysLogged >= 6 ? AppColors.textPrimary : Colors.orange,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 12),
                // Weight logging progress
                _buildProgressRow(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Weight Logs',
                  current: calculation.weightEntries,
                  target: 2,
                  color: calculation.weightEntries >= 2 ? AppColors.textPrimary : Colors.orange,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Helpful tips
          Text(
            daysNeeded > 0 && weightsNeeded > 0
                ? 'Log meals for $daysNeeded more day${daysNeeded > 1 ? 's' : ''} and add $weightsNeeded weight${weightsNeeded > 1 ? 's' : ''}'
                : daysNeeded > 0
                    ? 'Log meals for $daysNeeded more day${daysNeeded > 1 ? 's' : ''} to unlock insights'
                    : 'Add $weightsNeeded more weight log${weightsNeeded > 1 ? 's' : ''} to unlock insights',
            style: TextStyle(
              fontSize: 13,
              color: teal,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow({
    required IconData icon,
    required String label,
    required int current,
    required int target,
    required Color color,
    required Color textPrimary,
    required Color textMuted,
  }) {
    final progress = (current / target).clamp(0.0, 1.0);
    final isComplete = current >= target;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: TextStyle(fontSize: 13, color: textPrimary)),
                  Text(
                    isComplete ? 'Complete!' : '$current / $target days',
                    style: TextStyle(
                      fontSize: 12,
                      color: isComplete ? AppColors.textPrimary : textMuted,
                      fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getConfidenceMessage(double score) {
    if (score >= 0.8) {
      return 'High confidence - Based on ${(score * 100).round()}% data quality';
    } else if (score >= 0.5) {
      return 'Moderate confidence - Log more consistently for better accuracy';
    } else {
      return 'Low confidence - Need more data for accurate calculation';
    }
  }
}


// ─────────────────────────────────────────────────────────────────
// Recommendation Card (Legacy fallback)
// ─────────────────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  final WeeklyRecommendation recommendation;
  final bool isDark;

  const _RecommendationCard({
    required this.recommendation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final primaryColor = ThemeColors.of(context).accent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.lightbulb, size: 20, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Recommended Adjustment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recommendation.adjustmentReason != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.psychology, size: 20, color: primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      recommendation.adjustmentReason!,
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // New targets
          Text(
            'New Targets',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TargetItem(
                  label: 'Calories',
                  value: '${recommendation.recommendedCalories}',
                  unit: 'kcal',
                  color: primaryColor,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TargetItem(
                  label: 'Protein',
                  value: '${recommendation.recommendedProteinG}',
                  unit: 'g',
                  color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TargetItem(
                  label: 'Carbs',
                  value: '${recommendation.recommendedCarbsG}',
                  unit: 'g',
                  color: isDark ? AppColors.orange : AppColorsLight.orange,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TargetItem(
                  label: 'Fat',
                  value: '${recommendation.recommendedFatG}',
                  unit: 'g',
                  color: isDark ? AppColors.purple : AppColorsLight.purple,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _TargetItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool isDark;

  const _TargetItem({
    required this.label,
    required this.value,
    required this.unit,
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: textMuted)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
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
// No Recommendation Card
// ─────────────────────────────────────────────────────────────────

class _NoRecommendationCard extends StatelessWidget {
  final bool isDark;

  const _NoRecommendationCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = ThemeColors.of(context).accent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 48, color: teal),
          const SizedBox(height: 16),
          Text(
            'You\'re On Track!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your current targets are aligned with your progress. Keep up the great work!',
            style: TextStyle(fontSize: 14, color: textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Tips Card
// ─────────────────────────────────────────────────────────────────

class _TipsCard extends StatelessWidget {
  final bool isDark;
  final WeeklySummaryData? summary;
  final AdherenceSummary? adherence;

  const _TipsCard({
    required this.isDark,
    this.summary,
    this.adherence,
  });

  List<String> _getContextualTips() {
    final tips = <String>[];

    // Data-driven tips
    if (summary != null && summary!.daysLogged < 5) {
      tips.add('Log meals at least 5 days this week for accurate TDEE');
    }
    if (summary != null && summary!.weightChange == null) {
      tips.add('Add weight entries 2-3x per week at the same time');
    }
    if (adherence != null && adherence!.averageAdherence < 70) {
      tips.add('Focus on hitting your calorie target more consistently');
    }
    if (adherence != null && adherence!.sustainabilityRating == 'low') {
      tips.add('Consider a more moderate approach for long-term adherence');
    }

    // Fill with defaults if we don't have enough contextual tips
    if (tips.isEmpty || (summary == null && adherence == null)) {
      tips.clear();
      tips.addAll([
        'Log meals consistently for more accurate TDEE calculations',
        'Weigh yourself 2-3 times per week at the same time',
        'Focus on weekly trends, not daily fluctuations',
      ]);
    }

    return tips;
  }

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final tips = _getContextualTips();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, size: 18, color: textMuted),
              const SizedBox(width: 8),
              Text(
                'Tips for Better Results',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => _TipItem(text: tip, isDark: isDark)),
        ],
      ),
    );
  }
}


class _TipItem extends StatelessWidget {
  final String text;
  final bool isDark;

  const _TipItem({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, size: 14, color: ThemeColors.of(context).accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}


class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final Color textColor;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: textColor, height: 1.4),
          ),
        ),
      ],
    );
  }
}

