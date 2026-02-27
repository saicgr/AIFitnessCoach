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

    const shortDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Day cells (Mon-Sun)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final date = monday.add(Duration(days: index));
              final isToday = index == todayIndex;
              final isSelected = index == selectedDayIndex;
              final status = workoutStatusMap[index]; // null, true, or false
              final isPast = index < todayIndex;

              // Check if previous day's workout was completed or missed (for today's badge)
              final prevDayCompleted = isToday &&
                  index > 0 &&
                  workoutStatusMap[index - 1] == true;
              final prevDayMissed = isToday &&
                  index > 0 &&
                  workoutStatusMap[index - 1] == false;

              return _DayCell(
                dayLabel: shortDays[index],
                dateNumber: date.day,
                isToday: isToday,
                isSelected: isSelected,
                workoutStatus: status,
                previousDayCompleted: prevDayCompleted,
                previousDayMissed: prevDayMissed,
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

/// Individual day cell in the week strip.
///
/// Today's date is wrapped in a vertical rounded rectangle (pill) containing
/// the day label + date number, with a small checkmark overlay when the
/// previous day's workout is done. All other days keep a minimal layout.
class _DayCell extends StatelessWidget {
  final String dayLabel;
  final int dateNumber;
  final bool isToday;
  final bool isSelected;
  /// null = not a workout day, true = completed, false = scheduled/missed
  final bool? workoutStatus;
  /// Whether the *previous* day's workout was completed (drives checkmark)
  final bool previousDayCompleted;
  /// Whether the *previous* day's workout was missed (drives X mark)
  final bool previousDayMissed;
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
    this.previousDayCompleted = false,
    this.previousDayMissed = false,
    required this.isPast,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // --- Today: outlined rounded-rect pill wrapping day + date ---
    if (isToday) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 42,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentColor, width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dayLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$dateNumber',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Checkmark badge when previous day's workout is complete
                  if (previousDayCompleted)
                    Positioned(
                      bottom: -4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.background : AppColorsLight.background,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // X mark badge when previous day's workout was missed
                  if (previousDayMissed)
                    Positioned(
                      bottom: -4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.background : AppColorsLight.background,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              // Status indicator below pill
              _buildStatusIndicator(),
            ],
          ),
        ),
      );
    }

    // --- Non-today cells: original minimal layout ---
    Color dateColor;
    Color dayLabelColor;
    FontWeight dateFontWeight;
    Color? cellBg;

    if (isSelected) {
      cellBg = accentColor.withValues(alpha: 0.15);
      dateColor = isDark ? Colors.white : Colors.black87;
      dayLabelColor = isDark ? Colors.white : Colors.black87;
      dateFontWeight = FontWeight.w600;
    } else if (workoutStatus != null) {
      cellBg = null;
      dateColor = isDark ? Colors.white : Colors.black87;
      dayLabelColor = isDark ? Colors.white70 : Colors.black54;
      dateFontWeight = FontWeight.w500;
    } else {
      cellBg = null;
      dateColor = isDark ? Colors.white38 : Colors.black26;
      dayLabelColor = isDark ? Colors.white38 : Colors.black26;
      dateFontWeight = FontWeight.normal;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 42,
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
                color: cellBg,
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
            // Status indicator: X for missed, dot for others
            _buildStatusIndicator(),
          ],
        ),
      ),
    );
  }

  /// Whether this day was missed (past + scheduled but not completed)
  bool get _isMissed => workoutStatus == false && isPast;

  /// Dot/indicator color for workout status
  Color? get _dotColor {
    if (workoutStatus == true) return AppColors.success;
    if (_isMissed) return AppColors.error;
    if (workoutStatus == false) return accentColor;
    return null;
  }

  /// Build the status indicator: X mark for missed, dot for others
  Widget _buildStatusIndicator() {
    if (_isMissed) {
      // X mark instead of red dot for missed workouts
      return Icon(Icons.close, size: 10, color: AppColors.error);
    }
    final color = _dotColor;
    if (color != null) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      );
    }
    return const SizedBox(height: 6);
  }
}
