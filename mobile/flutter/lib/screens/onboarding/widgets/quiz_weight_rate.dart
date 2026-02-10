import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Quiz step for selecting weight change rate (how fast to lose/gain weight).
/// Shows options with safety labels and projected timeline.
class QuizWeightRate extends StatelessWidget {
  final String? weightDirection; // 'lose' or 'gain'
  final String? selectedRate; // 'slow', 'moderate', 'fast'
  final double? currentWeight;
  final double? goalWeight;
  final bool useMetric;
  final ValueChanged<String> onRateChanged;
  final bool showHeader;

  const QuizWeightRate({
    super.key,
    required this.weightDirection,
    required this.selectedRate,
    required this.currentWeight,
    required this.goalWeight,
    required this.useMetric,
    required this.onRateChanged,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use stronger, more visible colors with proper contrast
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);
    final cardBg = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final isLosing = weightDirection == 'lose';
    final weightDiff = ((currentWeight ?? 0) - (goalWeight ?? 0)).abs();

    final rates = isLosing
        ? [
            {
              'id': 'slow',
              'label': 'Gradual',
              'rate': 0.25,
              'rateLabel': useMetric ? '0.25 kg/week' : '0.5 lbs/week',
              'safety': 'Safe',
              'safetyColor': AppColors.success,
              'icon': Icons.spa_outlined,
              'desc': 'Sustainable long-term, preserves muscle mass',
              'recommended': false,
            },
            {
              'id': 'moderate',
              'label': 'Moderate',
              'rate': 0.5,
              'rateLabel': useMetric ? '0.5 kg/week' : '1 lb/week',
              'safety': 'Safe',
              'safetyColor': AppColors.success,
              'icon': Icons.balance_outlined,
              'desc': 'Balanced approach, clinically recommended',
              'recommended': true,
            },
            {
              'id': 'fast',
              'label': 'Faster',
              'rate': 0.75,
              'rateLabel': useMetric ? '0.75 kg/week' : '1.5 lbs/week',
              'safety': 'Moderate',
              'safetyColor': AppColors.accent,
              'icon': Icons.speed_outlined,
              'desc': 'Requires discipline and careful nutrition',
              'recommended': false,
            },
            {
              'id': 'aggressive',
              'label': 'Aggressive',
              'rate': 1.0,
              'rateLabel': useMetric ? '1 kg/week' : '2 lbs/week',
              'safety': 'Intense',
              'safetyColor': AppColors.accent,
              'icon': Icons.whatshot_outlined,
              'desc': 'Maximum safe rate, requires strict adherence',
              'recommended': false,
            },
          ]
        : [
            {
              'id': 'slow',
              'label': 'Lean Bulk',
              'rate': 0.25,
              'rateLabel': useMetric ? '0.25 kg/week' : '0.5 lbs/week',
              'safety': 'Safe',
              'safetyColor': AppColors.success,
              'icon': Icons.trending_up_outlined,
              'desc': 'Minimizes fat gain while building muscle',
              'recommended': true,
            },
            {
              'id': 'moderate',
              'label': 'Standard',
              'rate': 0.35,
              'rateLabel': useMetric ? '0.35 kg/week' : '0.75 lbs/week',
              'safety': 'Safe',
              'safetyColor': AppColors.success,
              'icon': Icons.fitness_center_outlined,
              'desc': 'Good balance of muscle gain and minimal fat',
              'recommended': false,
            },
            {
              'id': 'fast',
              'label': 'Aggressive',
              'rate': 0.5,
              'rateLabel': useMetric ? '0.5 kg/week' : '1 lb/week',
              'safety': 'Moderate',
              'safetyColor': AppColors.accent,
              'icon': Icons.rocket_launch_outlined,
              'desc': 'Maximizes growth, may gain some fat',
              'recommended': false,
            },
          ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Text(
              isLosing
                  ? 'How fast do you want to lose weight?'
                  : 'How fast do you want to gain weight?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                height: 1.3,
              ),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
            const SizedBox(height: 6),
            Text(
              'Choose a pace that fits your lifestyle',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 20),
          ],

          // Scrollable rate options
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Rate options
                  ...rates.asMap().entries.map((entry) {
                    final index = entry.key;
                    final rate = entry.value;
                    final isSelected = selectedRate == rate['id'];
                    final isRecommended = rate['recommended'] as bool;
                    final safetyColor = rate['safetyColor'] as Color;

                    // Calculate weeks to goal
                    final weeklyRate = rate['rate'] as double;
                    final weeksToGoal = weightDiff > 0 ? (weightDiff / weeklyRate).ceil() : 0;
                    final goalDate = DateTime.now().add(Duration(days: weeksToGoal * 7));

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onRateChanged(rate['id'] as String);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: isSelected
                  ? LinearGradient(
                      colors: [AppColors.orange, AppColors.orange.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
                            color: isSelected ? null : cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isRecommended && !isSelected
                                  ? AppColors.success
                                  : (isSelected ? AppColors.accent : cardBorder),
                              width: isSelected || isRecommended ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.accent.withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Icon
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.2)
                                          : safetyColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      rate['icon'] as IconData,
                                      color: isSelected ? Colors.white : safetyColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Label, rate, and badges
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Title row with flexible badges
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                rate['label'] as String,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected ? Colors.white : textPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // Safety badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? Colors.white.withOpacity(0.2)
                                                    : safetyColor.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                rate['safety'] as String,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected ? Colors.white : safetyColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        // Rate and recommended badge row
                                        Row(
                                          children: [
                                            Text(
                                              rate['rateLabel'] as String,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: isSelected ? Colors.white70 : AppColors.accent,
                                              ),
                                            ),
                                            if (isRecommended) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? Colors.white.withOpacity(0.2)
                                                      : AppColors.accent.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.star,
                                                      size: 9,
                                                      color: isSelected ? Colors.white : AppColors.accent,
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      'Best',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w600,
                                                        color: isSelected ? Colors.white : AppColors.accent,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Selection indicator
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: isSelected
                                          ? null
                                          : Border.all(color: cardBorder, width: 2),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                                        : null,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Description
                              Text(
                                rate['desc'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? Colors.white70 : textSecondary,
                                ),
                              ),
                              // Timeline preview
                              if (weightDiff > 0) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withOpacity(0.1)
                                        : (isDark ? AppColors.elevated : AppColorsLight.elevated),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 12,
                                        color: isSelected ? Colors.white70 : textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          '${_formatDate(goalDate)} (~$weeksToGoal wks)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isSelected ? Colors.white70 : textSecondary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ).animate(delay: (200 + index * 100).ms).fadeIn().slideX(begin: 0.05),
                    );
                  }),

                  const SizedBox(height: 12),

                  // Info note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isLosing
                                ? 'Slower rates preserve muscle and are easier to maintain.'
                                : 'Slower rates minimize fat gain while building muscle.',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 600.ms).fadeIn(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }
}
