part of 'schedule_screen.dart';

// ─────────────────────────────────────────────────────────────────
// Week Selector
// ─────────────────────────────────────────────────────────────────

class _WeekSelector extends StatelessWidget {
  final DateTime selectedWeek;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final ThemeColors colors;
  final int weekStartDay; // 1=Mon, 7=Sun
  final VoidCallback onToggleWeekStart;

  const _WeekSelector({
    required this.selectedWeek,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.colors,
    required this.weekStartDay,
    required this.onToggleWeekStart,
  });

  @override
  Widget build(BuildContext context) {
    final weekEnd = selectedWeek.add(const Duration(days: 6));
    final formatter = DateFormat('MMM d');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: colors.elevated,
        border: Border(
          bottom: BorderSide(color: colors.cardBorder.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPreviousWeek,
            icon: const Icon(Icons.chevron_left),
            color: colors.textSecondary,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      '${formatter.format(selectedWeek)} - ${formatter.format(weekEnd)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (_isCurrentWeek(selectedWeek))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.cyan.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        AppLocalizations.of(context).workoutCompleteThisWeek,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.cyan,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  // Week-start toggle — a two-segment "Mon | Sun" pill so it
                  // reads as an interactive control, not a static label. The
                  // active side is highlighted; tapping flips weekStartDay.
                  Tooltip(
                    message: 'Week starts on',
                    child: GestureDetector(
                      onTap: onToggleWeekStart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.textMuted.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colors.textMuted.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swap_horiz,
                              size: 12,
                              color: colors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            _weekStartSegment(
                              AppLocalizations.of(context).workoutPlannerMon,
                              active: weekStartDay == 1,
                            ),
                            const SizedBox(width: 2),
                            _weekStartSegment(
                              AppLocalizations.of(context).workoutPlannerSun,
                              active: weekStartDay != 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onNextWeek,
            icon: const Icon(Icons.chevron_right),
            color: colors.textSecondary,
          ),
        ],
      ),
    );
  }

  /// One side of the Mon|Sun segmented toggle. The active side is filled with
  /// the accent so the current week-start choice is obvious at a glance.
  Widget _weekStartSegment(String label, {required bool active}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? colors.accent.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: active ? FontWeight.w700 : FontWeight.w600,
          color: active ? colors.accent : colors.textMuted,
        ),
      ),
    );
  }

  bool _isCurrentWeek(DateTime weekStart) {
    final now = DateTime.now();
    final currentWeekStart = _weekStartFor(now, weekStartDay);
    return weekStart.year == currentWeekStart.year &&
        weekStart.month == currentWeekStart.month &&
        weekStart.day == currentWeekStart.day;
  }
}

// ─────────────────────────────────────────────────────────────────
// Day Header
// ─────────────────────────────────────────────────────────────────

class _DayHeader extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool isTargetDay;
  final ThemeColors colors;

  const _DayHeader({
    required this.day,
    required this.isToday,
    required this.isTargetDay,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('E').format(day);
    final dayNumber = day.day.toString();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isToday
            ? colors.cyan.withOpacity(0.1)
            : isTargetDay
            ? colors.cyan.withOpacity(0.05)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: colors.cardBorder.withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          Text(
            dayName.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isToday ? colors.cyan : colors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isToday ? colors.cyan : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                dayNumber,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  color: isToday ? Colors.white : colors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Draggable Workout Card
// ─────────────────────────────────────────────────────────────────

class _DraggableWorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;
  final bool isDragging;
  final ThemeColors colors;

  const _DraggableWorkoutCard({
    required this.workout,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.isDragging,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = AppColors.getWorkoutTypeColor(workout.type ?? 'strength');

    return LongPressDraggable<Workout>(
      data: workout,
      onDragStarted: onDragStarted,
      onDragEnd: (_) => onDragEnd(),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.elevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.cyan, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workout.name ?? AppLocalizations.of(context).navWorkout,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  workout.type?.toUpperCase() ??
                      AppLocalizations.of(context).workoutsStrength,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: typeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _WorkoutCard(
          workout: workout,
          typeColor: typeColor,
          colors: colors,
        ),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDragging ? 0.3 : 1.0,
        child: _WorkoutCard(
          workout: workout,
          typeColor: typeColor,
          colors: colors,
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final Workout workout;
  final Color typeColor;
  final ThemeColors colors;

  const _WorkoutCard({
    required this.workout,
    required this.typeColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = workout.isCompleted ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCompleted ? colors.success.withOpacity(0.1) : colors.elevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted
              ? colors.success.withOpacity(0.3)
              : typeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  workout.name ?? AppLocalizations.of(context).navWorkout,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? colors.success : colors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isCompleted)
                Icon(Icons.check_circle, size: 14, color: colors.success),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              workout.type?.toUpperCase() ??
                  AppLocalizations.of(context).workoutsStrength,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: typeColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            workout.formattedDurationShort,
            style: TextStyle(fontSize: 9, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}
