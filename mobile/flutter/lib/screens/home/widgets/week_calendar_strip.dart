import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/week_start_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Persisted collapsed state for the week calendar strip.
///
/// Collapsed = strip shows a single-line summary of the selected date with
/// an expand chevron. Hidden ([weekCalendarHiddenProvider]) is different —
/// the strip isn't rendered at all.
final weekCalendarCollapsedProvider =
    StateNotifierProvider<_CollapsedNotifier, bool>((ref) {
  return _CollapsedNotifier();
});

class _CollapsedNotifier extends StateNotifier<bool> {
  static const _key = 'week_calendar_collapsed';

  _CollapsedNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}

/// Persisted fully-hidden state — when true the week calendar strip is not
/// rendered at all (no collapsed pill, nothing). The collapsed/expanded
/// state is independent and remembered for when the strip is re-shown.
final weekCalendarHiddenProvider =
    StateNotifierProvider<_HiddenNotifier, bool>((ref) {
  return _HiddenNotifier();
});

class _HiddenNotifier extends StateNotifier<bool> {
  static const _key = 'week_calendar_hidden';

  _HiddenNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}

/// Compact week calendar strip showing Mon-Sun with date numbers,
/// today highlight, and colored dots for workout status.
/// Supports collapsing into a single-line summary showing the selected date.
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
    final isCollapsed = ref.watch(weekCalendarCollapsedProvider);

    final weekConfig = ref.watch(weekDisplayConfigProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayIndex = today.weekday - 1; // 0=Mon (data model)
    final weekStart = weekConfig.weekStart(today);

    // Determine the selected date for collapsed view
    final selectedDisplayIndex = weekConfig.displayOrder.indexOf(selectedDayIndex);
    final selectedDate = weekStart.add(Duration(days: selectedDisplayIndex >= 0 ? selectedDisplayIndex : 0));

    if (isCollapsed) {
      return _CollapsedStrip(
        selectedDate: selectedDate,
        accentColor: accentColor,
        isDark: isDark,
        onExpand: () {
          HapticService.selection();
          ref.read(weekCalendarCollapsedProvider.notifier).toggle();
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (displayIndex) {
              final dataIndex = weekConfig.displayOrder[displayIndex];
              final date = weekStart.add(Duration(days: displayIndex));
              final isToday = dataIndex == todayIndex;
              final isSelected = dataIndex == selectedDayIndex;
              final status = workoutStatusMap[dataIndex];
              final isPast = date.isBefore(today);

              final prevDataIndex = (todayIndex - 1 + 7) % 7;
              final prevDayCompleted = isToday &&
                  workoutStatusMap[prevDataIndex] == true;
              final prevDayMissed = isToday &&
                  workoutStatusMap[prevDataIndex] == false;

              return _DayCell(
                dayLabel: weekConfig.dayLabels[displayIndex],
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
                  onDaySelected(dataIndex);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Collapsed single-line view showing the selected date with an expand icon.
class _CollapsedStrip extends StatelessWidget {
  final DateTime selectedDate;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onExpand;

  const _CollapsedStrip({
    required this.selectedDate,
    required this.accentColor,
    required this.isDark,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());
    final dateLabel = isToday
        ? 'Today, ${DateFormat('MMM d').format(selectedDate)}'
        : DateFormat('EEE, MMM d').format(selectedDate);

    return GestureDetector(
      onTap: onExpand,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: accentColor,
            ),
            const SizedBox(width: 8),
            Text(
              dateLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.expand_more,
              size: 18,
              color: textMuted,
            ),
          ],
        ),
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
    // Compact cell visual — matches the Nutrition tab's `NutritionDateStrip`
    // so the strip looks identical across Home, Workouts and Nutrition.
    //
    // Today (selected or not) → filled accent rounded-rect pill with white
    // label + number stacked inside. Every other day → label above a 32×32
    // circle. A small status indicator sits below all cells.

    if (isToday) {
      return _buildTodayPill();
    }

    final Color dateColor;
    final Color labelColor;
    final FontWeight dateWeight;
    Color? cellBg;
    Border? cellBorder;

    if (isSelected) {
      // Selected (non-today) — accent outline ring + accent text.
      cellBorder = Border.all(color: accentColor, width: 2);
      dateColor = accentColor;
      labelColor = accentColor;
      dateWeight = FontWeight.w700;
    } else if (workoutStatus != null) {
      dateColor = isDark ? Colors.white : Colors.black87;
      labelColor = isDark ? Colors.white70 : Colors.black54;
      dateWeight = FontWeight.w500;
    } else {
      dateColor = isDark ? Colors.white38 : Colors.black26;
      labelColor = isDark ? Colors.white38 : Colors.black26;
      dateWeight = FontWeight.w400;
    }

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dayLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cellBg,
                  border: cellBorder,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$dateNumber',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: dateWeight,
                    color: dateColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(height: 6, child: _buildStatusIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  /// Today cell: filled solid accent rounded-rect pill (matching
  /// `NutritionDateStrip`) with white label + white number stacked inside.
  Widget _buildTodayPill() {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 36),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dateNumber',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(height: 6, child: _buildStatusIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  /// Whether this day was completed
  bool get _isCompleted => workoutStatus == true;

  /// Whether this day was missed (past + scheduled but not completed)
  bool get _isMissed => workoutStatus == false && isPast;

  /// Build the compact status indicator — a single small dot, matching the
  /// Nutrition tab's `NutritionDateStrip`. Green = done, red = missed,
  /// accent = scheduled. Keeps the strip visually light (no check/X marks).
  Widget _buildStatusIndicator() {
    final Color? dotColor;
    if (_isCompleted) {
      dotColor = AppColors.success;
    } else if (_isMissed) {
      dotColor = AppColors.error;
    } else if (workoutStatus == false) {
      dotColor = accentColor;
    } else {
      dotColor = null;
    }
    if (dotColor == null) return const SizedBox.shrink();
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dotColor,
      ),
    );
  }
}
