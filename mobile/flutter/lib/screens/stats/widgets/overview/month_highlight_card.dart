import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/widgets/skeleton/skeleton_box.dart';
import '../../../../data/models/consistency.dart';
import '../../../../data/providers/consistency_provider.dart';
import '../../../../widgets/design_system/zealova.dart';

/// Overview-tab "Month Highlight" card (Gravl Image #5, bottom-right tile).
///
/// An accent-filled highlight [GlassCard] reading "{MonthName} / N workouts"
/// (this calendar month's completed workouts) with a large faded month-number
/// watermark behind it, mirroring Gravl's big translucent figure. Tapping opens
/// the full stats screen (`/stats`).
///
/// Data: [consistencyProvider]. Prefers `insights.monthWorkoutsCompleted` (the
/// app-wide "this month" count). When insights haven't arrived yet but the
/// calendar heatmap has, it falls back to counting `status == 'completed'`
/// entries whose date is in the current calendar month from
/// [CalendarHeatmapResponse]. Skeleton on a truly empty first load.
class MonthHighlightCard extends ConsumerWidget {
  const MonthHighlightCard({super.key});

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// Count completed workouts in the current calendar month from the heatmap.
  static int _monthCountFromCalendar(CalendarHeatmapResponse data) {
    final now = DateTime.now();
    var count = 0;
    for (final day in data.data) {
      if (day.status.toLowerCase() != 'completed') continue;
      final d = DateTime.tryParse(day.date);
      if (d == null) continue;
      if (d.year == now.year && d.month == now.month) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ThemeColors.of(context);
    final accent = colors.accent;

    final monthCompleted = ref.watch(consistencyProvider
        .select((s) => s.insights?.monthWorkoutsCompleted));
    final calendar =
        ref.watch(consistencyProvider.select((s) => s.calendarData));
    final isInitialLoad = ref.watch(consistencyProvider.select((s) =>
        (s.isLoading || s.isLoadingCalendar) &&
        s.insights == null &&
        s.calendarData == null));

    // Resolve the count: insights first, then a calendar-derived count.
    int? count = monthCompleted;
    count ??= calendar != null ? _monthCountFromCalendar(calendar) : null;

    final hasData = count != null;

    return ZealovaCard(
      variant: ZealovaCardVariant.hero,
      radius: AppRadius.lg,
      padding: EdgeInsets.zero,
      onTap: () {
        HapticService.instance.tap();
        context.push('/stats');
      },
      child: (!hasData && isInitialLoad)
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _buildSkeleton(),
            )
          : _buildContent(context, colors, accent, count ?? 0),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeColors colors,
    Color accent,
    int count,
  ) {
    final now = DateTime.now();
    final monthName = _monthNames[now.month - 1];
    final monthNumber = now.month.toString().padLeft(2, '0');

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(
        children: [
          // Big faded month-number watermark — Anton numeral, desaturated.
          Positioned(
            right: -8,
            bottom: -22,
            child: IgnorePointer(
              child: Text(
                monthNumber,
                style: ZType.disp(
                  104,
                  color: colors.textMuted.withValues(alpha: 0.10),
                  letterSpacing: -2,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ZealovaSectionKicker(monthName, accent: true),
                const SizedBox(height: AppSpacing.sm),
                // Anton hero numeral — the one accent element on this card.
                Text(
                  '$count',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZType.disp(48, color: accent),
                ),
                const SizedBox(height: 6),
                Text(
                  (count == 1 ? 'workout' : 'workouts').toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      ZType.lbl(11, color: colors.textMuted, letterSpacing: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SkeletonBox(width: 80, height: 11),
        SizedBox(height: AppSpacing.sm),
        SkeletonBox(width: 56, height: 44),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(width: 64, height: 11),
      ],
    );
  }
}
