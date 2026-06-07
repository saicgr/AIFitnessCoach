import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/hydration_repository.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Compact hydration summary block for the Daily tab
class HydrationSummaryBlock extends ConsumerWidget {
  final bool isDark;
  final VoidCallback? onTap;

  /// Quick-log affordance. When provided, a circular blue "+" button renders in
  /// the header that opens the drink-log sheet directly (the whole-card tap is
  /// reserved for "view details"). Wired to the same handler as [onTap] today,
  /// but kept separate so the two intents can diverge later.
  final VoidCallback? onAdd;

  const HydrationSummaryBlock({
    super.key,
    required this.isDark,
    this.onTap,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('💧 HydrationSummaryBlock build called, isDark: $isDark');
    final state = ref.watch(hydrationProvider);
    final currentMl = state.todaySummary?.totalMl ?? 0;
    final goalMl = state.dailyGoalMl;
    final percentage = goalMl > 0 ? (currentMl / goalMl).clamp(0.0, 1.0) : 0.0;
    final percentageInt = (percentage * 100).round();

    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final electricBlue = isDark
        ? AppColors.waterBlue
        : AppColorsLight.waterBlue;
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

    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: electricBlue, width: 4),
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
                  AppLocalizations.of(context).workoutSummaryAdvancedHydration,
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
                if (onAdd != null) ...[
                  const SizedBox(width: 8),
                  // Quick-log "+": filled blue circle. Opens the drink-log
                  // sheet without going through "view details".
                  Material(
                    color: electricBlue,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onAdd,
                      child: const SizedBox(
                        width: 28,
                        height: 28,
                        child: Icon(
                          Icons.add,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
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
                  AppLocalizations.of(context).weeklySummaryTapToViewDetails,
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
        ),
      ),
    );
  }
}
