import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/nutrition_preferences.dart';
import '../../l10n/generated/app_localizations.dart';

/// Weekly Overview stat card — a row of stat badges (days logged, avg
/// calories, avg protein, optional weight change).
///
/// Extracted verbatim from the /stats Nutrition tab so it can be reused on the
/// Nutrition tab's "Nutrition stats" section without any visual change. The
/// constructor signature (colors-as-params + [AsyncValue] payload) is
/// identical to the original private `_WeeklyOverviewCard`.
class WeeklyOverviewCard extends StatelessWidget {
  final AsyncValue<WeeklySummaryData?> weeklySummary;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;

  const WeeklyOverviewCard({
    super.key,
    required this.weeklySummary,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: weeklySummary.when(
        // Layout-matched skeleton: title line + a row of 3 stat badges.
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(width: 140, height: 16, radius: 6),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: SkeletonBox(height: 64, radius: 12)),
                SizedBox(width: 8),
                Expanded(child: SkeletonBox(height: 64, radius: 12)),
                SizedBox(width: 8),
                Expanded(child: SkeletonBox(height: 64, radius: 12)),
              ],
            ),
          ],
        ),
        error: (_, __) => _errorRow('Could not load weekly summary'),
        data: (data) {
          if (data == null) return _errorRow('No data available');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).nutritionTabPartWeeklyOverview,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatBadge(
                    label: AppLocalizations.of(context).weeklyCheckinSheetDaysLogged,
                    value: '${data.daysLogged}/7',
                    icon: Icons.calendar_today,
                    color: const Color(0xFF4CAF50),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _StatBadge(
                    label: AppLocalizations.of(context).weeklyCheckinSheetAvgCalories,
                    value: '${data.avgCalories}',
                    icon: Icons.local_fire_department,
                    color: const Color(0xFFFF9800),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _StatBadge(
                    label: AppLocalizations.of(context).weeklyCheckinSheetAvgProtein,
                    value: '${data.avgProtein}g',
                    icon: Icons.fitness_center,
                    color: const Color(0xFF009688),
                    isDark: isDark,
                  ),
                  if (data.weightChange != null) ...[
                    const SizedBox(width: 8),
                    _StatBadge(
                      label: AppLocalizations.of(context).workoutSummaryAdvancedWeight,
                      value:
                          '${data.weightChange! > 0 ? '+' : ''}${data.weightChange!.toStringAsFixed(1)} kg',
                      icon: data.weightChange! > 0
                          ? Icons.trending_up
                          : data.weightChange! < 0
                              ? Icons.trending_down
                              : Icons.trending_flat,
                      color: const Color(0xFF2196F3),
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _errorRow(String message) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: textMuted),
        const SizedBox(width: 8),
        Text(message, style: TextStyle(color: textMuted, fontSize: 13)),
      ],
    );
  }
}

/// A single colored stat badge inside [WeeklyOverviewCard].
class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
