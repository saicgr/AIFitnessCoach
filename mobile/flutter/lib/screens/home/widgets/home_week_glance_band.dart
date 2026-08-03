/// Home week-glance band — Change 3 of the 2026-08 density pass
/// (docs/planning/mockups/home-density-2026-08-01.html, register #176).
///
/// Sits directly under the masthead date, before the first banner (no
/// section reorder — this is a new insertion at the top, every existing
/// section keeps its place). The user asked for this specifically: "I also
/// do not see any graphs and such in the proposed mockup" — Home showed
/// ~90 words above the fold and 0 numbers reflecting anything EARNED; every
/// visible element was either a sentence or an outstanding obligation
/// (missed workout, connect health, hydrate, log sleep). This band is the
/// one piece of the screen that shows a STATE instead of a queue: a 7-bar
/// week (today highlighted, a bar lights up when a workout was completed
/// that day) plus the current streak in a ring.
///
/// Data sources — both real, already-loaded elsewhere on Home, no new
/// fetch:
///   * Per-day completion → [workoutsProvider], day-matched with
///     [isScheduledOnLocalDay] — the SAME local-day helper the week-selector
///     strip's caller uses (`unified_home_widgets.dart`), so this band can
///     never disagree with that strip about which days were completed, and
///     it inherits the app's local-day-window correctness (never a UTC-date
///     substring compare — see CLAUDE.md "Local-day windows").
///   * Streak → [xpCurrentStreakProvider] — the same counter the streak
///     explainer sheet reads.
///
/// Deliberately NOT weekly training volume in kg: that number is only
/// aggregated server-side for the Progress tab's dashboard
/// (`WeeklyVolumeData`), and Home doesn't fetch it. Completion-per-day +
/// streak is real data Home already has loaded; volume would have meant
/// adding a fetch just to paint this one band, which the mockup explicitly
/// left as "the metric is a proposal, not a fixed choice."
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/week_start_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/repositories/workout_repository.dart' show workoutsProvider;
import 'home_schedule_dates.dart';
import 'home/unified_home_widgets.dart' show kHomeHPad;

class HomeWeekGlanceBand extends ConsumerWidget {
  const HomeWeekGlanceBand({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final weekConfig = ref.watch(weekDisplayConfigProvider);
    final workouts = ref.watch(workoutsProvider).valueOrNull ?? const [];
    final streak = ref.watch(xpCurrentStreakProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = weekConfig.weekStart(today);
    final todayDisplayIndex =
        weekConfig.displayOrder.indexOf(today.weekday - 1);

    final completed = List<bool>.generate(7, (displayIndex) {
      final date = weekStart.add(Duration(days: displayIndex));
      if (date.isAfter(today)) return false;
      return workouts.any((w) =>
          isScheduledOnLocalDay(w.scheduledDate, date) &&
          w.isCompleted == true &&
          !w.isSyncedFromHealthApp);
    });
    final sessionsThisWeek = completed.where((done) => done).length;

    return Padding(
      padding: kHomeHPad,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _StreakRing(streak: streak, c: c),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('THIS WEEK',
                          style: ZType.lbl(10,
                              color: c.textMuted, letterSpacing: 1.6)),
                      Text(
                        sessionsThisWeek == 1
                            ? '1 session'
                            : '$sessionsThisWeek sessions',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 26,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (i) {
                        final barDate = weekStart.add(Duration(days: i));
                        final isToday = i == todayDisplayIndex;
                        final isFuture = barDate.isAfter(today);
                        final on = completed[i];
                        final heightFactor =
                            isFuture ? 0.14 : (on ? (isToday ? 1.0 : 0.7) : 0.22);
                        return Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 2),
                            child: FractionallySizedBox(
                              alignment: Alignment.bottomCenter,
                              heightFactor: heightFactor,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: on
                                      ? c.accent
                                      : c.textMuted.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(3),
                                  border: isToday && !on
                                      ? Border.all(
                                          color: c.accent, width: 1.2)
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
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

/// Streak ring — a conic fill (accent) proportional to the current streak,
/// capped at a week (7 days reads as "full", matching the 7-bar chart it
/// sits beside rather than an arbitrary constant).
class _StreakRing extends StatelessWidget {
  final int streak;
  final ThemeColors c;
  const _StreakRing({required this.streak, required this.c});

  @override
  Widget build(BuildContext context) {
    final progress = (streak / 7).clamp(0.0, 1.0);
    final hasStreak = streak > 0;
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: hasStreak ? progress : 1.0,
              strokeWidth: 4,
              backgroundColor: c.textMuted.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(
                hasStreak ? c.accent : c.textMuted.withValues(alpha: 0.18),
              ),
            ),
          ),
          Text(
            '$streak',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
