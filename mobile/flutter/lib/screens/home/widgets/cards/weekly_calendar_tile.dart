import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/week_start_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/home_layout.dart';
import '../../../../data/repositories/workout_repository.dart';
import '../../../../data/services/haptic_service.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../home_schedule_dates.dart';
/// Weekly Calendar Card - Shows 7-day workout overview
class WeeklyCalendarCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const WeeklyCalendarCard({
    super.key,
    this.size = TileSize.full,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = ThemeColors.of(context).elevated;
    final textColor = ThemeColors.of(context).textPrimary;
    final textMuted = ThemeColors.of(context).textMuted;
    final cardBorder = ThemeColors.of(context).cardBorder;
    final accentColor = ref.colors(context).accent;

    // Read the workouts notifier for scheduled/completed data
    final workoutsNotifier = ref.read(workoutsProvider.notifier);
    final allWorkouts = ref.watch(workoutsProvider).valueOrNull ?? [];

    final weekConfig = ref.watch(weekDisplayConfigProvider);

    // Calculate this week's dates
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = weekConfig.weekStart(today);

    // Build day data in display order
    final days = List.generate(7, (i) {
      final date = weekStart.add(Duration(days: i));

      bool isScheduled = false;
      bool isCompleted = false;

      for (final w in allWorkouts) {
        // LOCAL-day match (chokepoint). `split('T')[0]` gave the UTC date of a
        // timestamptz and mis-dayed the strip for tz-shifted users (#21/#65).
        if (isScheduledOnLocalDay(w.scheduledDate, date)) {
          isScheduled = true;
          if (w.isCompleted == true) {
            isCompleted = true;
          }
        }
      }

      return _DayData(
        label: weekConfig.dayLabels[i],
        date: date,
        isToday: date == today,
        isScheduled: isScheduled,
        isCompleted: isCompleted,
      );
    });

    // Count workouts this week
    final weeklyProgress = workoutsNotifier.weeklyProgress;
    final completedThisWeek = weeklyProgress.$1;
    final totalThisWeek = weeklyProgress.$2;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('/schedule');
      },
      child: Container(
        margin: size == TileSize.full
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
            : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.calendar_today, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context).workoutCompleteThisWeek,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$completedThisWeek${totalThisWeek > 0 ? '/$totalThisWeek' : ''} workouts',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 7-day row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: days.map((day) => _buildDayColumn(
                day,
                accentColor: accentColor,
                textColor: textColor,
                textMuted: textMuted,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayColumn(
    _DayData day, {
    required Color accentColor,
    required Color textColor,
    required Color textMuted,
  }) {
    return Column(
      children: [
        // Day label
        Text(
          day.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: day.isToday ? FontWeight.bold : FontWeight.w400,
            color: day.isToday ? accentColor : textMuted,
          ),
        ),
        const SizedBox(height: 6),

        // Day number with today highlight
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: day.isToday ? accentColor.withValues(alpha: 0.15) : null,
            border: day.isToday
                ? Border.all(color: accentColor, width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '${day.date.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: day.isToday ? FontWeight.bold : FontWeight.w400,
              color: day.isToday ? accentColor : textColor,
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Dot indicators
        SizedBox(
          height: 8,
          child: day.isCompleted
              ? Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,  // accent-allowlist: success/positive state -- must stay green regardless of accent
                  ),
                )
              : day.isScheduled
                  ? Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor,
                      ),
                    )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _DayData {
  final String label;
  final DateTime date;
  final bool isToday;
  final bool isScheduled;
  final bool isCompleted;

  const _DayData({
    required this.label,
    required this.date,
    required this.isToday,
    required this.isScheduled,
    required this.isCompleted,
  });
}
