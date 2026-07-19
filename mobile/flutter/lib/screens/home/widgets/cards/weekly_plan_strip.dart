/// F3.70 — Weekly plan strip.
///
/// Compact 7-day strip showing the week's planned + completed workouts at
/// a glance. Each day pill shows a state dot (done / planned / rest). Tap
/// any day to jump to the schedule.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/weekly_plan.dart';
import '../../../../data/providers/weekly_plan_provider.dart';
import '../../../../data/services/haptic_service.dart';

enum WeeklyPlanDayState { done, planned, rest, missed }

class WeeklyPlanDay {
  final String label; // M T W T F S S
  final WeeklyPlanDayState state;
  final bool isToday;

  const WeeklyPlanDay({
    required this.label,
    required this.state,
    this.isToday = false,
  });
}

class WeeklyPlanStrip extends ConsumerWidget {
  final bool show;
  final List<WeeklyPlanDay>? days;

  const WeeklyPlanStrip({
    super.key,
    this.show = true,
    this.days,
  });

  static const List<String> _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return const SizedBox.shrink();
    final c = ThemeColors.of(context);

    // Build the 7-day strip from the live weekly plan when the caller
    // doesn't override (production path). Constructor `days` wins for
    // previews / tests.
    final List<WeeklyPlanDay> resolvedDays;
    if (days != null && days!.isNotEmpty) {
      resolvedDays = days!;
    } else {
      final plan = ref.watch(weeklyPlanProvider.select((s) => s.currentPlan));
      if (plan == null || plan.dailyEntries.isEmpty) {
        return const SizedBox.shrink();
      }
      final today = DateTime.now();
      final todayKey = DateTime(today.year, today.month, today.day);
      resolvedDays = plan.dailyEntries.take(7).map((e) {
        final entryKey =
            DateTime(e.planDate.year, e.planDate.month, e.planDate.day);
        final isPast = entryKey.isBefore(todayKey);
        final WeeklyPlanDayState state;
        if (e.dayType == DayType.rest) {
          state = WeeklyPlanDayState.rest;
        } else if (e.workoutCompleted) {
          state = WeeklyPlanDayState.done;
        } else if (isPast) {
          state = WeeklyPlanDayState.missed;
        } else {
          state = WeeklyPlanDayState.planned;
        }
        return WeeklyPlanDay(
          label: _weekdayLabels[(e.planDate.weekday - 1) % 7],
          state: state,
          isToday: entryKey == todayKey,
        );
      }).toList();
    }
    if (resolvedDays.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticService.light();
          context.push('/schedule');
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This week',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: resolvedDays
                    .map((d) => Expanded(child: _DayPill(day: d, c: c)))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  final WeeklyPlanDay day;
  final ThemeColors c;
  const _DayPill({required this.day, required this.c});

  @override
  Widget build(BuildContext context) {
    final dotColor = switch (day.state) {
      WeeklyPlanDayState.done => c.accent,
      WeeklyPlanDayState.planned => c.textMuted,
      WeeklyPlanDayState.rest => c.cardBorder,
      WeeklyPlanDayState.missed => c.error,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          Text(
            day.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight:
                  day.isToday ? FontWeight.w900 : FontWeight.w600,
              color: day.isToday ? c.textPrimary : c.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
