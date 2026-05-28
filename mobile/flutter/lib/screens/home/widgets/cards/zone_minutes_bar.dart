/// F3.24 — Zone-minutes bar.
///
/// Apple Health "Exercise minutes" / Fitbit "Active Zone Minutes" — minutes
/// spent in elevated HR zones today. Collapses when no data.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/combined_health_provider.dart';

/// Weekly active-minute signal — sums `DailyActivity.activeMinutes` across
/// the most recent 7 calendar days from `combinedHealthHistoryProvider`
/// (which reads the backend `/activity/history` rows synced from
/// HealthKit / Health Connect).
///
/// Limitation: the synced `daily_activity` schema does not carry a
/// moderate-vs-vigorous split, so all active minutes are reported as
/// `moderateMinutes` and `vigorousMinutes` stays null. The WHO equivalence
/// (1 vigorous min = 2 moderate min) in the card still computes correctly
/// because the missing vigorous bucket contributes 0.
/// TODO(backend): GET /api/v1/health/zone-minutes?days=7 with a per-day
/// moderate/vigorous split (HK `appleExerciseTime` vs HR-zone derived).
final zoneMinutesSignalProvider =
    Provider.autoDispose<({int? moderateMinutes, int? vigorousMinutes})>((ref) {
  final async = ref.watch(combinedHealthHistoryProvider);
  return async.maybeWhen(
    data: (h) {
      if (!h.hasData) {
        return (moderateMinutes: null, vigorousMinutes: null);
      }
      final now = DateTime.now();
      final cutoff = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6));
      var total = 0;
      var counted = 0;
      for (final d in h.days) {
        final dk = DateTime(d.date.year, d.date.month, d.date.day);
        if (dk.isBefore(cutoff)) continue;
        final mins = d.activeMinutes ?? 0;
        if (mins > 0) {
          total += mins;
          counted++;
        }
      }
      if (counted == 0) {
        return (moderateMinutes: null, vigorousMinutes: null);
      }
      return (moderateMinutes: total, vigorousMinutes: null);
    },
    orElse: () => (moderateMinutes: null, vigorousMinutes: null),
  );
});

class ZoneMinutesBar extends ConsumerWidget {
  /// Minutes in moderate zone (zone 2-ish).
  final int? moderateMinutes;

  /// Minutes in vigorous zone (zone 3+).
  final int? vigorousMinutes;

  /// Weekly target (WHO: 150 min moderate or 75 vigorous; vigorous counts 2x).
  final int weeklyGoal;

  const ZoneMinutesBar({
    super.key,
    this.moderateMinutes,
    this.vigorousMinutes,
    this.weeklyGoal = 150,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signal = ref.watch(zoneMinutesSignalProvider);
    final m = moderateMinutes ?? signal.moderateMinutes;
    final v = vigorousMinutes ?? signal.vigorousMinutes;
    if (m == null && v == null) return const SizedBox.shrink();
    final c = ThemeColors.of(context);
    // WHO equivalence: 1 vigorous min = 2 moderate min.
    final effective = (m ?? 0) + 2 * (v ?? 0);
    final pct = (effective / weeklyGoal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: c.accent),
              const SizedBox(width: 6),
              Text(
                'Zone minutes (week)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$effective / $weeklyGoal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: c.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(c.accent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Moderate ${m ?? 0} · Vigorous ${v ?? 0} min',
            style: TextStyle(fontSize: 11.5, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
