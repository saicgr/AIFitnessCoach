import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/workout.dart';
import '../../data/repositories/workout_repository.dart';

/// Provider for currently selected week
final selectedWeekProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return now.subtract(Duration(days: now.weekday - 1)); // Monday of current week
});

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  Workout? _draggingWorkout;
  int? _targetDayIndex;

  @override
  Widget build(BuildContext context) {
    final workoutsState = ref.watch(workoutsProvider);
    final selectedWeek = ref.watch(selectedWeekProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        title: Text('Schedule', style: TextStyle(color: colors.textPrimary)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.today, color: colors.textPrimary),
            onPressed: () => _goToToday(ref),
            tooltip: 'Go to today',
          ),
        ],
      ),
      body: Column(
        children: [
          // Week selector
          _WeekSelector(
            selectedWeek: selectedWeek,
            onPreviousWeek: () => _changeWeek(ref, -1),
            onNextWeek: () => _changeWeek(ref, 1),
            colors: colors,
          ),

          // Week view with drag & drop
          Expanded(
            child: workoutsState.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: colors.cyan),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: colors.error),
                    const SizedBox(height: 16),
                    Text('Failed to load: $e', style: TextStyle(color: colors.textPrimary)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(workoutsProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (workouts) => _buildWeekView(context, workouts, selectedWeek, colors),
            ),
          ),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: colors.elevated,
            child: Row(
              children: [
                Icon(Icons.touch_app, size: 20, color: colors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Long press and drag a workout to reschedule it',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView(BuildContext context, List<Workout> workouts, DateTime weekStart, ThemeColors colors) {
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final today = DateTime.now();

    return Row(
      children: days.asMap().entries.map((entry) {
        final index = entry.key;
        final day = entry.value;
        final isToday = day.year == today.year &&
            day.month == today.month &&
            day.day == today.day;
        final dayWorkouts = _getWorkoutsForDay(workouts, day);
        final isTargetDay = _targetDayIndex == index;

        return Expanded(
          child: DragTarget<Workout>(
            onWillAcceptWithDetails: (details) {
              setState(() => _targetDayIndex = index);
              return true;
            },
            onLeave: (_) {
              setState(() => _targetDayIndex = null);
            },
            onAcceptWithDetails: (details) async {
              setState(() => _targetDayIndex = null);
              await _rescheduleWorkout(details.data, day, colors);
            },
            builder: (context, candidateData, rejectedData) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isTargetDay
                      ? colors.cyan.withOpacity(0.1)
                      : Colors.transparent,
                  border: Border(
                    right: BorderSide(
                      color: colors.cardBorder.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Day header
                    _DayHeader(
                      day: day,
                      isToday: isToday,
                      isTargetDay: isTargetDay,
                      colors: colors,
                    ),

                    // Workouts for the day
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        child: Column(
                          children: dayWorkouts.isEmpty
                              ? [
                                  Container(
                                    height: 60,
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isTargetDay
                                            ? colors.cyan.withOpacity(0.5)
                                            : colors.cardBorder.withOpacity(0.2),
                                        style: BorderStyle.solid,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        isTargetDay ? Icons.add : Icons.remove,
                                        size: 16,
                                        color: isTargetDay
                                            ? colors.cyan
                                            : colors.textMuted.withOpacity(0.3),
                                      ),
                                    ),
                                  ),
                                ]
                              : dayWorkouts.map((workout) {
                                  return _DraggableWorkoutCard(
                                    workout: workout,
                                    onDragStarted: () {
                                      setState(() => _draggingWorkout = workout);
                                    },
                                    onDragEnd: () {
                                      setState(() {
                                        _draggingWorkout = null;
                                        _targetDayIndex = null;
                                      });
                                    },
                                    isDragging: _draggingWorkout?.id == workout.id,
                                    colors: colors,
                                  );
                                }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  List<Workout> _getWorkoutsForDay(List<Workout> workouts, DateTime day) {
    final dayStr = DateFormat('yyyy-MM-dd').format(day);
    return workouts.where((w) {
      if (w.scheduledDate == null) return false;
      return w.scheduledDate!.startsWith(dayStr);
    }).toList();
  }

  Future<void> _rescheduleWorkout(Workout workout, DateTime newDate, ThemeColors colors) async {
    final newDateStr = DateFormat('yyyy-MM-dd').format(newDate);

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text('Moving workout to ${DateFormat('MMM d').format(newDate)}...'),
          ],
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: colors.elevated,
      ),
    );

    try {
      final repository = ref.read(workoutRepositoryProvider);
      final success = await repository.rescheduleWorkout(workout.id!, newDateStr);

      if (success) {
        // Refresh workouts
        await ref.read(workoutsProvider.notifier).refresh();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Workout moved to ${DateFormat('EEEE, MMM d').format(newDate)}'),
              backgroundColor: colors.success,
            ),
          );
        }
      } else {
        throw Exception('Failed to reschedule');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reschedule: $e'),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }

  void _changeWeek(WidgetRef ref, int delta) {
    final current = ref.read(selectedWeekProvider);
    ref.read(selectedWeekProvider.notifier).state =
        current.add(Duration(days: 7 * delta));
  }

  void _goToToday(WidgetRef ref) {
    final now = DateTime.now();
    ref.read(selectedWeekProvider.notifier).state =
        now.subtract(Duration(days: now.weekday - 1));
  }
}

// ─────────────────────────────────────────────────────────────────
// Week Selector
// ─────────────────────────────────────────────────────────────────

class _WeekSelector extends StatelessWidget {
  final DateTime selectedWeek;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final ThemeColors colors;

  const _WeekSelector({
    required this.selectedWeek,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.colors,
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
          bottom: BorderSide(
            color: colors.cardBorder.withOpacity(0.3),
          ),
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
          GestureDetector(
            onTap: () {}, // Could open week picker
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${formatter.format(selectedWeek)} - ${formatter.format(weekEnd)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                if (_isCurrentWeek(selectedWeek))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.cyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'This Week',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colors.cyan,
                      ),
                    ),
                  ),
              ],
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

  bool _isCurrentWeek(DateTime weekStart) {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
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
          bottom: BorderSide(
            color: colors.cardBorder.withOpacity(0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            dayName.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isToday ? colors.cyan : colors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 28,
            height: 28,
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
                workout.name ?? 'Workout',
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
                  workout.type?.toUpperCase() ?? 'STRENGTH',
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
        child: _WorkoutCard(workout: workout, typeColor: typeColor, colors: colors),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDragging ? 0.3 : 1.0,
        child: _WorkoutCard(workout: workout, typeColor: typeColor, colors: colors),
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
        color: isCompleted
            ? colors.success.withOpacity(0.1)
            : colors.elevated,
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
                  workout.name ?? 'Workout',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? colors.success
                        : colors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isCompleted)
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: colors.success,
                ),
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
              workout.type?.toUpperCase() ?? 'STRENGTH',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: typeColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${workout.durationMinutes ?? 45}m',
            style: TextStyle(
              fontSize: 9,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
