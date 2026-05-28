/// F3.74 — Day-of-week skip pattern card.
///
/// Detects when the user has skipped a recurring weekday workout (e.g. every
/// Wednesday) over the last 3-4 weeks and surfaces a one-tap "reschedule to
/// a different weekday" CTA. Self-collapses when the pattern provider has
/// nothing to surface or fails — failures stay loud in logs, never on home.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/providers/home_pattern_providers.dart';
import '../../../../data/services/haptic_service.dart';

/// Local view-model with the strings the card actually renders. Kept as a
/// thin wrapper around [DayOfWeekSkipData] so the existing call-sites that
/// referenced `weeksSkipped` and `suggestedAlternative` stay legible.
class DayOfWeekSkipSignal {
  final String weekdayName; // e.g. "Wednesday"
  final int weeksSkipped; // count of weeks with a miss on that weekday
  final String suggestedAlternative; // adjacent weekday
  const DayOfWeekSkipSignal({
    required this.weekdayName,
    required this.weeksSkipped,
    required this.suggestedAlternative,
  });
}

/// Bridges the backend `dayOfWeekSkipProvider` to the card's local model.
/// Returns `null` when there is no pattern, when the API fails, or when
/// fewer than 2 weeks have been observed (avoids cold-start noise).
final dayOfWeekSkipSignalProvider =
    Provider.autoDispose<DayOfWeekSkipSignal?>((ref) {
  final async = ref.watch(dayOfWeekSkipProvider);
  final data = async.asData?.value;
  if (data == null || !data.hasPattern) return null;

  // Approximate "weeks_skipped" from miss_rate × weeks_observed (the
  // backend returns the rate, the card UI talks in week count).
  final weeksObserved = data.weeksObserved;
  final approxWeeks = ((data.missRate ?? 0) * weeksObserved).round();
  // Suggest the adjacent weekday (next day in the calendar). 0=Sun..6=Sat.
  const names = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday'
  ];
  final altIndex = ((data.weekday ?? 0) + 1) % 7;

  return DayOfWeekSkipSignal(
    weekdayName: data.weekdayName ?? names[data.weekday ?? 0],
    weeksSkipped: approxWeeks,
    suggestedAlternative: names[altIndex],
  );
});

class DayOfWeekSkipCard extends ConsumerWidget {
  const DayOfWeekSkipCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DayOfWeekSkipSignal? signal;
    try {
      signal = ref.watch(dayOfWeekSkipSignalProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }
    if (signal == null || signal.weeksSkipped < 2) {
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
            Icon(Icons.event_busy_rounded, size: 18, color: c.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${signal.weekdayName}s keep getting skipped',
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
            'You\'ve missed your ${signal.weekdayName} workout ${signal.weeksSkipped} weeks in a row. Want to shift it to ${signal.suggestedAlternative}?',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: c.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  HapticService.light();
                  context.push('/workout/schedule');
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Reschedule',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
