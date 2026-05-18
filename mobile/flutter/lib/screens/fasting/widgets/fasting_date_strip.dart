import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/fasting.dart';
import '../../../data/services/haptic_service.dart';

/// Per-day fasting status used to render the date strip's status dot.
enum FastingDayStatus {
  /// A fast that reached its goal that day.
  completed,

  /// A fast that day but the goal was not reached.
  partial,

  /// No fast that day.
  none,
}

/// Compact week date strip for the Fasting screen (Section B).
///
/// Mirrors the Home/Workouts/Nutrition strips: seven day cells, the selected
/// day highlighted, plus a per-day fasting status dot. Tapping a day calls
/// [onDaySelected] so the parent can swap the timer for that day's summary.
class FastingDateStrip extends StatelessWidget {
  /// The currently-selected day (date-only).
  final DateTime selectedDay;

  /// All known fasting records (active + completed) used to derive day status.
  final List<FastingRecord> records;

  /// Called with the date-only [DateTime] when a day is tapped.
  final ValueChanged<DateTime> onDaySelected;

  const FastingDateStrip({
    super.key,
    required this.selectedDay,
    required this.records,
    required this.onDaySelected,
  });

  /// All fasts that started on [day] (date-only). Supports multiple/day.
  static List<FastingRecord> fastsForDay(
    List<FastingRecord> records,
    DateTime day,
  ) {
    final d = DateTime(day.year, day.month, day.day);
    return records.where((r) {
      final s = r.startTime.toLocal();
      return DateTime(s.year, s.month, s.day) == d;
    }).toList();
  }

  FastingDayStatus _statusFor(DateTime day) {
    final fasts = fastsForDay(records, day);
    if (fasts.isEmpty) return FastingDayStatus.none;
    // If any fast that day completed its goal, treat the day as completed.
    final anyCompleted = fasts.any((f) {
      if (f.completedGoal) return true;
      final actual = f.actualDurationMinutes;
      return actual != null &&
          f.goalDurationMinutes > 0 &&
          actual >= f.goalDurationMinutes;
    });
    return anyCompleted
        ? FastingDayStatus.completed
        : FastingDayStatus.partial;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Monday-start week containing today.
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final selected =
        DateTime(selectedDay.year, selectedDay.month, selectedDay.day);

    return SizedBox(
      height: 70,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final day = weekStart.add(Duration(days: i));
          final isToday = day == today;
          final isSelected = day == selected;
          final isFuture = day.isAfter(today);
          final status = isFuture ? FastingDayStatus.none : _statusFor(day);
          return Expanded(
            child: _DayCell(
              day: day,
              isToday: isToday,
              isSelected: isSelected,
              isFuture: isFuture,
              status: status,
              colors: colors,
              onTap: () {
                HapticService.light();
                onDaySelected(day);
              },
            ),
          );
        }),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final bool isFuture;
  final FastingDayStatus status;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isFuture,
    required this.status,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = colors.accent;
    final weekdayLabel = DateFormat('E').format(day).substring(0, 1);

    final Color labelColor;
    if (isSelected) {
      labelColor = colors.accentContrast;
    } else if (isFuture) {
      labelColor = colors.textMuted.withValues(alpha: 0.55);
    } else {
      labelColor = colors.textSecondary;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isToday && !isSelected
                ? Border.all(color: accent.withValues(alpha: 0.5))
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weekdayLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? colors.accentContrast
                      : (isFuture
                          ? colors.textMuted.withValues(alpha: 0.55)
                          : colors.textPrimary),
                ),
              ),
              const SizedBox(height: 4),
              _StatusDot(
                status: status,
                isSelected: isSelected,
                colors: colors,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Per-day fasting status indicator: filled = completed, faint = partial,
/// hollow ring = no fast.
class _StatusDot extends StatelessWidget {
  final FastingDayStatus status;
  final bool isSelected;
  final ThemeColors colors;

  const _StatusDot({
    required this.status,
    required this.isSelected,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final onAccent = isSelected;
    switch (status) {
      case FastingDayStatus.completed:
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onAccent ? colors.accentContrast : colors.accent,
          ),
        );
      case FastingDayStatus.partial:
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (onAccent ? colors.accentContrast : colors.accent)
                .withValues(alpha: 0.4),
          ),
        );
      case FastingDayStatus.none:
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: (onAccent ? colors.accentContrast : colors.textMuted)
                  .withValues(alpha: 0.35),
              width: 1,
            ),
          ),
        );
    }
  }
}
