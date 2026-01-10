import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/hydration_repository.dart';

/// Compact hydration summary block for the Daily tab
class HydrationSummaryBlock extends ConsumerWidget {
  final bool isDark;
  final VoidCallback? onTap;

  const HydrationSummaryBlock({
    super.key,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hydrationProvider);
    final currentMl = state.todaySummary?.totalMl ?? 0;
    final goalMl = state.dailyGoalMl;
    final percentage = goalMl > 0 ? (currentMl / goalMl).clamp(0.0, 1.0) : 0.0;
    final percentageInt = (percentage * 100).round();

    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final electricBlue = isDark
        ? AppColors.electricBlue
        : AppColorsLight.electricBlue;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    final glassSurface = isDark
        ? AppColors.glassSurface
        : AppColorsLight.glassSurface;

    // Format with gallon equivalent
    final gallons = (currentMl / 3785.0).toStringAsFixed(2);
    final goalGallons = (goalMl / 3785.0).toStringAsFixed(2);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: electricBlue, width: 4),
            top: BorderSide(color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
            right: BorderSide(color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
            bottom: BorderSide(color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Icon(
                  Icons.water_drop,
                  color: electricBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Hydration',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                // Values
                Text(
                  '$currentMl / $goalMl ml',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: electricBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$percentageInt%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: electricBlue,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Gallon equivalent
            Text(
              '($gallons / $goalGallons gal)',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),

            const SizedBox(height: 10),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: glassSurface,
                color: electricBlue,
                minHeight: 8,
              ),
            ),

            const SizedBox(height: 8),

            // Tap hint
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Tap to view details',
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
