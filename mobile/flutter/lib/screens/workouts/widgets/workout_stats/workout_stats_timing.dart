part of 'workout_stats_section.dart';

/// 7. BEST-TIME + STREAK-RISK.
///
/// Reads the consistency insights: `bestDay` / `worstDay` (DayPattern) and
/// `timePatterns` (TimeOfDayPattern) to render a "You're most consistent on
/// {day}, {time}" line, plus a streak-risk nudge (variant pool) when today
/// matches the user's usual training day and the current streak is alive.
class _TimingCard extends ConsumerWidget {
  final bool isDark;
  final Color accent;

  const _TimingCard({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consistency = ref.watch(consistencyProvider);
    final insights = consistency.insights;

    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    if (insights == null && consistency.isLoading) {
      return StatCardShell(
        isDark: isDark,
        child: const _CardSkeleton(height: 56),
      );
    }

    final bestDay = insights?.bestDay;
    final preferredTime = _preferredTimeLabel(insights);
    final streak = insights?.currentStreak ?? 0;

    // Need at least a best-day signal to say anything honest.
    if (bestDay == null || bestDay.totalCompletions == 0) {
      return StatCardShell(
        isDark: isDark,
        child: Row(
          children: [
            Icon(Icons.schedule, size: 22, color: textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Train a few more sessions and we will spot your most consistent day and time.',
                style:
                    TextStyle(fontSize: 13, height: 1.35, color: textMuted),
              ),
            ),
          ],
        ),
      );
    }

    final bestLine = _bestTimeCopy(bestDay.dayName, preferredTime);

    // Streak risk: today matches the best day AND streak is alive.
    final todayName = _todayName();
    final atRisk = streak > 0 &&
        bestDay.dayName.toLowerCase() == todayName.toLowerCase();
    final riskCopy = atRisk ? _streakRiskCopy(streak, bestDay.dayName) : null;

    return StatCardShell(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.schedule, size: 18, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bestLine,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (riskCopy != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.14 : 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.local_fire_department, size: 16, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      riskCopy,
                      style: TextStyle(
                          fontSize: 12, height: 1.35, color: textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Pick the preferred time-of-day label from the consistency time patterns,
  /// if one is flagged preferred or clearly dominant. Returns null otherwise so
  /// the copy stays honest (day-only).
  static String? _preferredTimeLabel(ConsistencyInsights? insights) {
    if (insights == null) return null;
    if (insights.preferredTime != null &&
        insights.preferredTime!.trim().isNotEmpty) {
      return insights.preferredTime!.toLowerCase();
    }
    final patterns = insights.timePatterns;
    if (patterns.isEmpty) return null;
    final preferred = patterns.where((p) => p.isPreferred).toList();
    final pick = preferred.isNotEmpty
        ? preferred.first
        : (patterns..sort((a, b) =>
                b.totalCompletions.compareTo(a.totalCompletions)))
            .first;
    if (pick.totalCompletions == 0) return null;
    return pick.displayName.toLowerCase();
  }

  static String _todayName() {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[(DateTime.now().weekday - 1).clamp(0, 6)];
  }

  /// Best-time copy variant pool (>=4), substituting the real day (+ time when
  /// known). No em dashes.
  static String _bestTimeCopy(String day, String? time) {
    final dayPlural = day.endsWith('s') ? day : '${day}s';
    if (time != null) {
      final variants = <String>[
        "You're most consistent on $dayPlural, usually in the $time.",
        "$dayPlural in the $time are your reliable training slot.",
        'Your habit is strongest on $dayPlural, $time sessions especially.',
        'You rarely miss a $time session on $dayPlural.',
      ];
      return variants[day.length % variants.length];
    }
    final variants = <String>[
      "You're most consistent on $dayPlural.",
      '$dayPlural are your most reliable training day.',
      'Your habit is strongest on $dayPlural.',
      'You show up most often on $dayPlural.',
    ];
    return variants[day.length % variants.length];
  }

  /// Streak-risk nudge variant pool (>=4), substituting the live streak count.
  /// Picked by a stable bucket of the streak so it does not flip on rebuild.
  static String _streakRiskCopy(int streak, String day) {
    final variants = <String>[
      'Today is a $day, your usual training day. A session keeps your $streak day streak alive.',
      "It's $day, when you normally train. Don't let the $streak day streak slip.",
      'Your $streak day streak is on the line today. $day is one of your strongest days.',
      "$day is a habit day for you. Knock out a session to push the streak past $streak.",
    ];
    return variants[streak % variants.length];
  }
}
