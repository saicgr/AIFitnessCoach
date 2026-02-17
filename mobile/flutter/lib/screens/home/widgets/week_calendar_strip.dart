import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Compact week calendar strip showing Mon-Sun with date numbers,
/// today highlight, and colored dots for workout status.
/// Placed above the hero workout carousel to provide date context.
class WeekCalendarStrip extends ConsumerWidget {
  /// User's workout day indices (0=Mon..6=Sun)
  final List<int> workoutDays;

  /// Map from weekday index (0=Mon) to completion status:
  /// null = not a workout day, true = completed, false = scheduled/missed
  final Map<int, bool?> workoutStatusMap;

  /// Currently selected day index (0=Mon..6=Sun)
  final int selectedDayIndex;

  /// Called when user taps any day
  final ValueChanged<int> onDaySelected;

  const WeekCalendarStrip({
    super.key,
    required this.workoutDays,
    required this.workoutStatusMap,
    required this.selectedDayIndex,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayIndex = today.weekday - 1; // 0=Mon

    // Compute the Monday of this week
    final monday = today.subtract(Duration(days: todayIndex));

    // Month/year for header
    final months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    final dayAbbrevs = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final shortDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    // Header date: "Tue, 16"
    final headerDay = dayAbbrevs[todayIndex];
    final headerDate = today.day.toString();
    final headerMonth = '${months[today.month - 1]} ${today.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Row 1: Date header + Today chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '$headerDay, $headerDate',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    headerMonth,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
              // "Today" chip
              if (selectedDayIndex != todayIndex)
                GestureDetector(
                  onTap: () {
                    HapticService.light();
                    onDaySelected(todayIndex);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Day cells (Mon-Sun)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final date = monday.add(Duration(days: index));
              final isToday = index == todayIndex;
              final isSelected = index == selectedDayIndex;
              final status = workoutStatusMap[index]; // null, true, or false
              final isPast = index < todayIndex;

              return _DayCell(
                dayLabel: shortDays[index],
                dateNumber: date.day,
                isToday: isToday,
                isSelected: isSelected,
                workoutStatus: status,
                isPast: isPast,
                accentColor: accentColor,
                isDark: isDark,
                onTap: () {
                  HapticService.selection();
                  onDaySelected(index);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Individual day cell in the week strip
class _DayCell extends StatelessWidget {
  final String dayLabel;
  final int dateNumber;
  final bool isToday;
  final bool isSelected;
  /// null = not a workout day, true = completed, false = scheduled/missed
  final bool? workoutStatus;
  final bool isPast;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const _DayCell({
    required this.dayLabel,
    required this.dateNumber,
    required this.isToday,
    required this.isSelected,
    required this.workoutStatus,
    required this.isPast,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine styling
    Color? circleBg;
    Color dateColor;
    Color dayLabelColor;
    FontWeight dateFontWeight;

    if (isToday) {
      // Today: filled accent circle
      circleBg = accentColor;
      dateColor = isDark ? Colors.black : Colors.white;
      dayLabelColor = accentColor;
      dateFontWeight = FontWeight.bold;
    } else if (isSelected) {
      // Selected but not today: subtle tint
      circleBg = accentColor.withValues(alpha: 0.15);
      dateColor = isDark ? Colors.white : Colors.black87;
      dayLabelColor = isDark ? Colors.white : Colors.black87;
      dateFontWeight = FontWeight.w600;
    } else if (workoutStatus != null) {
      // Workout day (not selected, not today)
      circleBg = null;
      dateColor = isDark ? Colors.white : Colors.black87;
      dayLabelColor = isDark ? Colors.white70 : Colors.black54;
      dateFontWeight = FontWeight.w500;
    } else {
      // Non-workout day
      circleBg = null;
      dateColor = isDark ? Colors.white38 : Colors.black26;
      dayLabelColor = isDark ? Colors.white38 : Colors.black26;
      dateFontWeight = FontWeight.normal;
    }

    // Dot color for workout status
    Color? dotColor;
    if (workoutStatus == true) {
      // Completed
      dotColor = AppColors.success;
    } else if (workoutStatus == false && isPast) {
      // Missed (past + incomplete)
      dotColor = AppColors.error;
    } else if (workoutStatus == false) {
      // Future/today scheduled
      dotColor = accentColor;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Day abbreviation
            Text(
              dayLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: dayLabelColor,
              ),
            ),
            const SizedBox(height: 4),
            // Date number with optional circle background
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleBg,
              ),
              alignment: Alignment.center,
              child: Text(
                '$dateNumber',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: dateFontWeight,
                  color: dateColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Status dot (6px)
            if (dotColor != null)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              )
            else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
