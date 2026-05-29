/// Two-up "Reports · Recap" row (issue 7) — replaces the full-width Weekly
/// Report card on Home. Left square = this-week progress + streak → Reports
/// hub; right square = week recap → profile stats. Both read the same live
/// providers the standalone cards used, so nothing about the data changes —
/// only the layout (two squares in one line, per user feedback).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/weekly_plan.dart';
import '../../../../data/providers/consistency_provider.dart';
import '../../../../data/providers/weekly_plan_provider.dart';
import '../../../../data/repositories/workout_repository.dart';
import '../../../../data/services/haptic_service.dart';

class ReportsRecapRow extends ConsumerWidget {
  const ReportsRecapRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);

    // -- Reports square: this week's completed / scheduled + streak. --
    final weekly = ref.watch(workoutsProvider.notifier).weeklyProgress;
    final completed = weekly.$1;
    final scheduled = weekly.$2;
    final reportPct =
        scheduled > 0 ? ((completed / scheduled).clamp(0.0, 1.0)) : 0.0;
    final streak = ref.watch(consistencyProvider).currentStreak;

    // -- Recap square: training entries done / planned this week. --
    int recapDone = 0;
    int recapPlanned = 0;
    final plan = ref.watch(weeklyPlanProvider).currentPlan;
    if (plan != null) {
      final training =
          plan.dailyEntries.where((e) => e.dayType == DayType.training);
      recapPlanned = training.length;
      recapDone = training.where((e) => e.workoutCompleted).length;
    }
    final recapPct =
        recapPlanned > 0 ? ((recapDone / recapPlanned).clamp(0.0, 1.0)) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 116,
        child: Row(
          children: [
            Expanded(
              child: _SquareCard(
                colors: c,
                emoji: '📈',
                label: 'REPORTS',
                headline: scheduled > 0 ? '${(reportPct * 100).round()}%' : '—',
                sub: streak > 0
                    ? '$streak day streak'
                    : (scheduled > 0
                        ? '$completed of $scheduled done'
                        : 'This week'),
                pct: reportPct,
                onTap: () {
                  HapticService.selection();
                  context.push('/reports');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SquareCard(
                colors: c,
                emoji: '📊',
                label: 'YOUR WEEK',
                headline: recapPlanned > 0 ? '$recapDone/$recapPlanned' : 'Recap',
                sub: recapPlanned > 0 ? 'workouts' : 'your week',
                pct: recapPct,
                onTap: () {
                  HapticService.light();
                  context.push('/profile?tab=stats&source=weekly_digest');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareCard extends StatelessWidget {
  final ThemeColors colors;
  final String emoji;
  final String label;
  final String headline;
  final String sub;
  final double pct;
  final VoidCallback onTap;

  const _SquareCard({
    required this.colors,
    required this.emoji,
    required this.label,
    required this.headline,
    required this.sub,
    required this.pct,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: c.elevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                      color: c.textMuted,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 17, color: c.textMuted),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      headline,
                      style: TextStyle(
                        fontSize: 22,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: c.cardBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(c.accent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
