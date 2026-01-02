import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fasting_impact.dart';

/// Card showing a single fasting impact metric comparison
class FastingImpactCard extends StatelessWidget {
  final String title;
  final String? fastingValue;
  final String? nonFastingValue;
  final String? fastingLabel;
  final String? nonFastingLabel;
  final String? differenceText;
  final IconData icon;
  final Color? positiveColor;
  final bool isPositive;
  final bool isDark;
  final CorrelationStrength? correlation;

  const FastingImpactCard({
    super.key,
    required this.title,
    this.fastingValue,
    this.nonFastingValue,
    this.fastingLabel,
    this.nonFastingLabel,
    this.differenceText,
    required this.icon,
    this.positiveColor,
    this.isPositive = true,
    this.isDark = true,
    this.correlation,
  });

  factory FastingImpactCard.fromComparison({
    required String title,
    required IconData icon,
    required FastingComparisonStats comparison,
    required String Function(FastingComparisonStats) getFastingValue,
    required String Function(FastingComparisonStats) getNonFastingValue,
    required String Function(FastingComparisonStats) getDifference,
    required bool Function(FastingComparisonStats) checkPositive,
  }) {
    return FastingImpactCard(
      title: title,
      icon: icon,
      fastingValue: getFastingValue(comparison),
      nonFastingValue: getNonFastingValue(comparison),
      differenceText: getDifference(comparison),
      isPositive: checkPositive(comparison),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final accentColor = positiveColor ??
        (isPositive ? AppColors.success : AppColors.orange);

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
              Icon(icon, color: AppColors.cyan, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildValueColumn(
                  fastingLabel ?? 'Fasting Days',
                  fastingValue ?? '--',
                  AppColors.cyan,
                  textMuted,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: textMuted.withOpacity(0.2),
              ),
              Expanded(
                child: _buildValueColumn(
                  nonFastingLabel ?? 'Non-Fasting',
                  nonFastingValue ?? '--',
                  textMuted,
                  textMuted,
                ),
              ),
            ],
          ),
          if (correlation != null) ...[
            const SizedBox(height: 8),
            Text(
              'Correlation: ${correlation!.displayName}',
              style: TextStyle(
                fontSize: 12,
                color: correlation!.isPositive
                    ? AppColors.success
                    : correlation!.isNegative
                        ? AppColors.error
                        : textMuted,
              ),
            ),
          ],
          if (differenceText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: accentColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    differenceText!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValueColumn(
    String label,
    String value,
    Color valueColor,
    Color labelColor,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: labelColor,
          ),
        ),
      ],
    );
  }
}
