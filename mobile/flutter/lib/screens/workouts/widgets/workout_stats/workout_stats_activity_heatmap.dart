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
    // No outer "Activity" title here: the embedded [ActivityHeatmap] renders
    // its own localized "Activity" header (via _buildHeader →
    // AppLocalizations.activityHeatmapActivity) with the time-range chips +
    // refresh control. Keeping a second hardcoded "Activity" Text above it
    // produced the duplicate "Activity / Activity" stack, so it's removed.
    return StatCardShell(
      isDark: isDark,
      child: ActivityHeatmap(
        onDayTapped: (date) {
          HapticService.light();
          WorkoutDayDetailSheet.show(context, date);
        },
      ),
    );
  }
}
