import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/haptic_service.dart';
import '../../data/providers/trend_series_provider.dart';

/// Entry button into the existing Custom Trends builder ([CustomTrendScreen]
/// at `/trends/custom`), pre-seeded with the metric appropriate to the
/// launching screen.
///
/// The screen passes [seed] — a workout metric on the Workout tab, a nutrition
/// metric on the Nutrition tab — reflecting the on-screen selection so the
/// builder opens already plotting what the user was looking at. The picker's
/// full catalogue remains available for adding overlays.
class CustomTrendsButton extends StatelessWidget {
  /// The metric to pre-select as the primary trend.
  final TrendMetric seed;

  final String title;
  final String subtitle;
  final bool isDark;

  /// Screen accent (e.g. `ref.colors(context).accent`).
  final Color accent;

  const CustomTrendsButton({
    super.key,
    required this.seed,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticService.light();
        context.push('/trends/custom', extra: seed);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.auto_graph_rounded, size: 20, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: textMuted),
          ],
        ),
      ),
    );
  }
}
