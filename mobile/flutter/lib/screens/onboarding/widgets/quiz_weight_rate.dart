import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Compact rate chip data
class WeightRateOption {
  final String id;
  final String label;
  final double weeklyRate;
  final String rateLabel;
  final IconData icon;
  final Color color;
  final bool recommended;

  const WeightRateOption(this.id, this.label, this.weeklyRate, this.rateLabel, this.icon, this.color, this.recommended);
}

/// Returns rate options based on direction
List<WeightRateOption> getWeightRateOptions({required bool isLosing, required bool useMetric}) {
  if (isLosing) {
    return [
      WeightRateOption('slow', 'Gradual', 0.25, useMetric ? '0.25 kg/wk' : '0.5 lbs/wk', Icons.spa_outlined, AppColors.success, false),
      WeightRateOption('moderate', 'Moderate', 0.5, useMetric ? '0.5 kg/wk' : '1 lb/wk', Icons.balance_outlined, AppColors.success, true),
      WeightRateOption('fast', 'Faster', 0.75, useMetric ? '0.75 kg/wk' : '1.5 lbs/wk', Icons.speed_outlined, AppColors.accent, false),
      WeightRateOption('aggressive', 'Aggressive', 1.0, useMetric ? '1 kg/wk' : '2 lbs/wk', Icons.whatshot_outlined, AppColors.accent, false),
    ];
  }
  return [
    WeightRateOption('slow', 'Lean Bulk', 0.25, useMetric ? '0.25 kg/wk' : '0.5 lbs/wk', Icons.trending_up_outlined, AppColors.success, true),
    WeightRateOption('moderate', 'Standard', 0.35, useMetric ? '0.35 kg/wk' : '0.75 lbs/wk', Icons.fitness_center_outlined, AppColors.success, false),
    WeightRateOption('fast', 'Aggressive', 0.5, useMetric ? '0.5 kg/wk' : '1 lb/wk', Icons.rocket_launch_outlined, AppColors.accent, false),
  ];
}

/// Compact 2x2 (or 1x3) rate chip grid widget
class QuizWeightRateChips extends StatelessWidget {
  final String? selectedRate;
  final List<WeightRateOption> rates;
  final ValueChanged<String> onRateChanged;

  const QuizWeightRateChips({
    super.key,
    required this.selectedRate,
    required this.rates,
    required this.onRateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);
    final cardBg = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    if (rates.length <= 3) {
      return Row(
        children: rates.map((rate) {
          final isLast = rate == rates.last;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 6),
              child: _buildChip(rate, isDark, textPrimary, textSecondary, cardBg, cardBorder),
            ),
          );
        }).toList(),
      ).animate().fadeIn(delay: 150.ms);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: _buildChip(rates[0], isDark, textPrimary, textSecondary, cardBg, cardBorder)),
            const SizedBox(width: 6),
            Expanded(child: _buildChip(rates[1], isDark, textPrimary, textSecondary, cardBg, cardBorder)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _buildChip(rates[2], isDark, textPrimary, textSecondary, cardBg, cardBorder)),
            const SizedBox(width: 6),
            Expanded(child: _buildChip(rates[3], isDark, textPrimary, textSecondary, cardBg, cardBorder)),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildChip(
    WeightRateOption rate,
    bool isDark, Color textPrimary, Color textSecondary, Color cardBg, Color cardBorder,
  ) {
    final isSelected = selectedRate == rate.id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onRateChanged(rate.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppColors.orange, AppColors.orange.withOpacity(0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: rate.recommended && !isSelected
                ? AppColors.success
                : (isSelected ? AppColors.orange : cardBorder),
            width: isSelected || rate.recommended ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.orange.withOpacity(0.25), blurRadius: 6)]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              rate.icon,
              size: 16,
              color: isSelected ? Colors.white : rate.color,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          rate.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (rate.recommended) ...[
                        const SizedBox(width: 3),
                        Icon(Icons.star, size: 10, color: isSelected ? Colors.white : AppColors.accent),
                      ],
                    ],
                  ),
                  Text(
                    rate.rateLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white70 : textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
