import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/calibration.dart';

/// Card displaying AI suggested adjustments from calibration
class SuggestedAdjustmentsCard extends StatelessWidget {
  final CalibrationSuggestedAdjustments adjustments;
  final bool isDark;

  const SuggestedAdjustmentsCard({
    super.key,
    required this.adjustments,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final success = isDark ? AppColors.success : AppColorsLight.success;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cyan.withValues(alpha: 0.1),
            purple.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cyan.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_fix_high,
                    color: cyan,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suggested Adjustments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      if (adjustments.hasChanges)
                        Text(
                          'Based on your calibration performance',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        )
                      else
                        Text(
                          'Your current settings look great!',
                          style: TextStyle(
                            fontSize: 13,
                            color: success,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Adjustment items
          if (adjustments.hasChanges) ...[
            Divider(
              height: 1,
              color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Fitness level change
                  if (adjustments.shouldChangeFitnessLevel &&
                      adjustments.suggestedFitnessLevel != null)
                    _buildAdjustmentItem(
                      icon: Icons.trending_up,
                      iconColor: purple,
                      title: 'Fitness Level',
                      currentValue: adjustments.currentFitnessLevel ?? 'Unknown',
                      newValue: adjustments.suggestedFitnessLevel!,
                      isDark: isDark,
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.05),

                  // Intensity change
                  if (adjustments.shouldChangeIntensity &&
                      adjustments.suggestedIntensity != null) ...[
                    if (adjustments.shouldChangeFitnessLevel)
                      const SizedBox(height: 12),
                    _buildAdjustmentItem(
                      icon: Icons.speed,
                      iconColor: orange,
                      title: 'Training Intensity',
                      currentValue: adjustments.currentIntensity ?? 'Unknown',
                      newValue: adjustments.suggestedIntensity!,
                      isDark: isDark,
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
                  ],

                  // Weight adjustment
                  if (adjustments.weightMultiplier != null &&
                      adjustments.weightMultiplier != 1.0) ...[
                    if (adjustments.shouldChangeFitnessLevel ||
                        adjustments.shouldChangeIntensity)
                      const SizedBox(height: 12),
                    _buildWeightAdjustmentItem(
                      multiplier: adjustments.weightMultiplier!,
                      description: adjustments.weightAdjustmentDescription,
                      isDark: isDark,
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05),
                  ],
                ],
              ),
            ),
          ],

          // Message to user
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (adjustments.hasChanges ? cyan : success)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (adjustments.hasChanges ? cyan : success)
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  adjustments.hasChanges
                      ? Icons.lightbulb_outline
                      : Icons.check_circle_outline,
                  size: 20,
                  color: adjustments.hasChanges ? cyan : success,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    adjustments.messageToUser,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),

          // Detailed recommendations
          if (adjustments.detailedRecommendations != null &&
              adjustments.detailedRecommendations!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommendations',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...adjustments.detailedRecommendations!
                      .asMap()
                      .entries
                      .map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check,
                            size: 16,
                            color: success,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: (500 + entry.key * 100).ms);
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdjustmentItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String currentValue,
    required String newValue,
    required bool isDark,
  }) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final success = isDark ? AppColors.success : AppColorsLight.success;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Current value
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: textSecondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatFitnessLevel(currentValue),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),

                    // Arrow
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: success,
                      ),
                    ),

                    // New value
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: success.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: success.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        _formatFitnessLevel(newValue),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: success,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightAdjustmentItem({
    required double multiplier,
    String? description,
    required bool isDark,
  }) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final isIncrease = multiplier > 1.0;
    final color = isIncrease
        ? (isDark ? AppColors.success : AppColorsLight.success)
        : (isDark ? AppColors.warning : AppColorsLight.warning);

    final percentage = ((multiplier - 1) * 100).round();
    final percentageStr = percentage > 0 ? '+$percentage%' : '$percentage%';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIncrease
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Starting Weights',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${isIncrease ? 'Increase' : 'Decrease'} by ',
                      style: TextStyle(
                        fontSize: 14,
                        color: textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        percentageStr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFitnessLevel(String level) {
    // Capitalize first letter
    if (level.isEmpty) return level;
    return level[0].toUpperCase() + level.substring(1).toLowerCase();
  }
}
