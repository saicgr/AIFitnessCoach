part of 'workout_stats_section.dart';

/// 9. ACTIVITY HEATMAP.
///
/// Reuses the shared [ActivityHeatmap] widget, which self-loads its calendar
/// data from `consistencyProvider` / `activityHeatmapProvider` and renders the
/// GitHub-style grid. It honours `heatmapTimeRangeProvider` (default 3M ≈ 13
/// weeks), which matches the compact ~13-week view the brief asks for, so no
/// reimplementation is needed.
///
/// Tapping a day opens the existing workout-day detail sheet (handled inside
/// the widget via [ActivityHeatmap.onDayTapped]).
class _ActivityHeatmapCard extends ConsumerWidget {
  final bool isDark;

  const _ActivityHeatmapCard({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return StatCardShell(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ActivityHeatmap(
            onDayTapped: (date) {
              HapticService.light();
              WorkoutDayDetailSheet.show(context, date);
            },
          ),
        ],
      ),
    );
  }
}
