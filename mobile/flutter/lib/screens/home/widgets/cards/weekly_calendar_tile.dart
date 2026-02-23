import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/home_layout.dart';
import '../../../../data/repositories/workout_repository.dart';
import '../../../../data/services/haptic_service.dart';

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
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = ref.colors(context).accent;

    // Read the workouts notifier for scheduled/completed data
    final workoutsNotifier = ref.read(workoutsProvider.notifier);
    final allWorkouts = ref.watch(workoutsProvider).valueOrNull ?? [];

    // Calculate this week's dates (Mon-Sun)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1)); // Monday

    // Build day data
    final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final days = List.generate(7, (i) {
      final date = weekStart.add(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      bool isScheduled = false;
      bool isCompleted = false;

      for (final w in allWorkouts) {
        final wDate = w.scheduledDate?.split('T')[0] ?? '';
        if (wDate == dateStr) {
          isScheduled = true;
          if (w.isCompleted == true) {
            isCompleted = true;
          }
        }
      }

      return _DayData(
        label: dayNames[i],
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
                Text(
                  'This Week',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
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
                    color: AppColors.success,
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
