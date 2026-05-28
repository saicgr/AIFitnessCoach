/// F3.81 — Busy-week compressed plan card.
///
/// When calendar density (or a user-flagged "busy week" toggle) is high,
/// compress the week into shorter, higher-density sessions. Surfaces the
/// compressed plan with a one-tap accept.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/home_insights_v2_provider.dart';
import '../../../../data/services/haptic_service.dart';

class BusyWeekSignal {
  /// Repurposed: this counts low-activity days, not meetings. UI copy below
  /// reframes from "meetings this week" → "activity drop vs baseline" since
  /// we don't have calendar data; the API gives us workout-density signal.
  final int meetingsThisWeek;
  final int suggestedSessionMinutes;
  final int originalSessionMinutes;
  const BusyWeekSignal({
    required this.meetingsThisWeek,
    required this.suggestedSessionMinutes,
    required this.originalSessionMinutes,
  });
}

/// Backed by `GET /api/v1/insights/busy-week-density`. Flags busy-week when
/// the last 5 days of workout minutes are < 30% of the 28-day baseline.
final busyWeekSignalProvider =
    Provider.autoDispose<BusyWeekSignal?>((ref) {
  final async = ref.watch(busyWeekDensityApiProvider);
  return async.maybeWhen(
    data: (api) {
      if (!api.busy || api.recommendedCompressedWorkoutMin == null) {
        return null;
      }
      final original = api.baselineAvgMin.round().clamp(20, 120);
      return BusyWeekSignal(
        // Drop magnitude as "indicator number" — UI shows the % drop.
        meetingsThisWeek: ((1.0 -
                    (api.recentAvgMin /
                        (api.baselineAvgMin == 0 ? 1 : api.baselineAvgMin))) *
                100)
            .clamp(0, 100)
            .round(),
        suggestedSessionMinutes: api.recommendedCompressedWorkoutMin!,
        originalSessionMinutes: original,
      );
    },
    orElse: () => null,
  );
});

class BusyWeekCompressedCard extends ConsumerWidget {
  const BusyWeekCompressedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    BusyWeekSignal? signal;
    try {
      signal = ref.watch(busyWeekSignalProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }
    if (signal == null ||
        signal.suggestedSessionMinutes >= signal.originalSessionMinutes) {
      return const SizedBox.shrink();
    }

    final c = ThemeColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.calendar_view_week_rounded, size: 18, color: c.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Heavy week ahead',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            'Activity is down ${signal.meetingsThisWeek}% vs your baseline. Compress sessions from ${signal.originalSessionMinutes}min → ${signal.suggestedSessionMinutes}min, same stimulus.',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: c.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  HapticService.medium();
                  context.push('/workout/schedule');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Apply compressed plan',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
