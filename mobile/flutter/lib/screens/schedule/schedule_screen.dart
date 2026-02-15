import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/user_provider.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/schedule_item.dart';
import '../../data/models/workout.dart';
import '../../data/providers/schedule_provider.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../widgets/glass_sheet.dart';
import 'widgets/add_schedule_item_sheet.dart';
import 'widgets/schedule_item_card.dart';
import 'widgets/timeline_view.dart';

/// Helper: compute start of week for a given date, using weekStartDay (1=Mon, 7=Sun)
DateTime _weekStartFor(DateTime date, int weekStartDay) {
  // DateTime.weekday: 1=Mon..7=Sun
  final diff = (date.weekday - weekStartDay + 7) % 7;
  return DateTime(date.year, date.month, date.day).subtract(Duration(days: diff));
}

/// Provider for currently selected week (respects week start day preference)
final selectedWeekProvider = StateProvider<DateTime>((ref) {
  final weekStartDay = ref.watch(weekStartDayProvider);
  final now = DateTime.now();
  return _weekStartFor(now, weekStartDay);
});

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  Workout? _draggingWorkout;
  int? _targetDayIndex;
  bool _showDragHint = true;

  // View mode: 'agenda', 'week', or 'timeline'
  String _viewMode = 'agenda';

  // Generate week state
  bool _isGeneratingWeek = false;
  int _generatedCount = 0;
  int _totalToGenerate = 0;

  @override
  Widget build(BuildContext context) {
    final workoutsState = ref.watch(workoutsProvider);
    final selectedWeek = ref.watch(selectedWeekProvider);
    final colors = ref.colors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        title: Text('Schedule', style: TextStyle(color: colors.textPrimary)),
        centerTitle: true,
        actions: [
          // View toggle button - cycles through agenda -> week -> timeline
          IconButton(
            icon: Icon(
              _viewModeIcon,
              color: colors.textPrimary,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _viewMode = _nextViewMode;
              });
            },
            tooltip: _viewModeTooltip,
          ),
          IconButton(
            icon: Icon(Icons.today, color: colors.textPrimary),
            onPressed: () => _goToToday(ref),
            tooltip: 'Go to today',
          ),
        ],
      ),
      body: Column(
        children: [
          // Week selector with Sun/Mon toggle
          _WeekSelector(
            selectedWeek: selectedWeek,
            onPreviousWeek: () => _changeWeek(ref, -1),
            onNextWeek: () => _changeWeek(ref, 1),
            colors: colors,
            weekStartDay: ref.watch(weekStartDayProvider),
            onToggleWeekStart: () {
              ref.read(weekStartDayProvider.notifier).toggle();
              // Re-compute selected week with new start day
              final now = DateTime.now();
              final newStartDay = ref.read(weekStartDayProvider);
              ref.read(selectedWeekProvider.notifier).state =
                  _weekStartFor(now, newStartDay);
            },
          ),

          // Generate This Week banner
          _buildGenerateWeekBanner(workoutsState, selectedWeek, colors),

          // Content
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
              data: (workouts) {
                switch (_viewMode) {
                  case 'timeline':
                    return _buildTimelineView(context, selectedWeek, colors);
                  case 'week':
                    return _buildWeekView(context, workouts, selectedWeek, colors);
                  case 'agenda':
                  default:
                    return _buildAgendaView(context, workouts, selectedWeek, colors);
                }
              },
            ),
          ),

          // Instructions - dismissible
          if (_showDragHint)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: colors.elevated,
              child: Row(
                children: [
                  Icon(Icons.touch_app, size: 20, color: colors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _hintText,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showDragHint = false),
                    child: Icon(Icons.close, size: 18, color: colors.textMuted),
                  ),
                ],
              ),
            ),
        ],
      ),
      // FAB for adding new schedule items
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemSheet(context, colors),
        backgroundColor: colors.isDark ? Colors.white : Colors.black,
        foregroundColor: colors.isDark ? Colors.black : Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // View mode cycling helpers
  String get _nextViewMode {
    switch (_viewMode) {
      case 'agenda':
        return 'week';
      case 'week':
        return 'timeline';
      case 'timeline':
        return 'agenda';
      default:
        return 'agenda';
    }
  }

  IconData get _viewModeIcon {
    switch (_viewMode) {
      case 'agenda':
        return Icons.calendar_view_week;
      case 'week':
        return Icons.schedule;
      case 'timeline':
        return Icons.view_agenda;
      default:
        return Icons.calendar_view_week;
    }
  }

  String get _viewModeTooltip {
    switch (_viewMode) {
      case 'agenda':
        return 'Week view';
      case 'week':
        return 'Timeline view';
      case 'timeline':
        return 'Agenda view';
      default:
        return 'Switch view';
    }
  }

  String get _hintText {
    switch (_viewMode) {
      case 'agenda':
        return 'Tap an item to view details';
      case 'week':
        return 'Long press and drag to reschedule';
      case 'timeline':
        return 'Tap empty space to add, tap an item to edit';
      default:
        return '';
    }
  }

  void _showAddItemSheet(BuildContext context, ThemeColors colors, {String? prefilledTime}) {
    final selectedWeek = ref.read(selectedWeekProvider);
    // Use today if within the selected week, otherwise use Monday of selected week
    final now = DateTime.now();
    final weekEnd = selectedWeek.add(const Duration(days: 6));
    final selectedDate = (now.isAfter(selectedWeek) && now.isBefore(weekEnd.add(const Duration(days: 1))))
        ? DateTime(now.year, now.month, now.day)
        : selectedWeek;

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: AddScheduleItemSheet(
          selectedDate: selectedDate,
          prefilledTime: prefilledTime,
          onSave: (item) => _createScheduleItem(item, colors),
        ),
      ),
    );
  }

  Future<void> _createScheduleItem(ScheduleItemCreate item, ThemeColors colors) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final repository = ref.read(scheduleRepositoryProvider);
      await repository.createItem(userId, item);
      // Refresh the schedule
      ref.read(scheduleRefreshProvider.notifier).state++;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${item.title}" to schedule'),
            backgroundColor: colors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add item: $e'),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }

  /// Timeline view showing a vertical 24-hour timeline for today/selected day
  Widget _buildTimelineView(BuildContext context, DateTime weekStart, ThemeColors colors) {
    // Use today if within the selected week
    final now = DateTime.now();
    final weekEnd = weekStart.add(const Duration(days: 6));
    final selectedDate = (now.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            now.isBefore(weekEnd.add(const Duration(days: 1))))
        ? DateTime(now.year, now.month, now.day)
        : weekStart;

    final scheduleAsync = ref.watch(dailyScheduleProvider(selectedDate));

    return Column(
      children: [
        // Date label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.schedule, size: 18, color: colors.textMuted),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, MMM d').format(selectedDate),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              if (selectedDate.year == now.year &&
                  selectedDate.month == now.month &&
                  selectedDate.day == now.day) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.cyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colors.cyan,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: scheduleAsync.when(
            loading: () => Center(
              child: CircularProgressIndicator(color: colors.cyan),
            ),
            error: (e, _) => Center(
              child: Text('Failed to load timeline: $e',
                  style: TextStyle(color: colors.error)),
            ),
            data: (schedule) => TimelineView(
              items: schedule.items,
              isDark: colors.isDark,
              onItemTap: (item) => _showAddItemSheet(context, colors, prefilledTime: item.startTime),
              onEmptyTap: (time) => _showAddItemSheet(context, colors, prefilledTime: time),
            ),
          ),
        ),
      ],
    );
  }

  /// Agenda view - vertical scrolling list grouped by day
  Widget _buildAgendaView(BuildContext context, List<Workout> workouts, DateTime weekStart, ThemeColors colors) {
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final today = DateTime.now();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 7,
      itemBuilder: (context, index) {
        final day = days[index];
        final isToday = day.year == today.year &&
            day.month == today.month &&
            day.day == today.day;
        final isPast = day.isBefore(DateTime(today.year, today.month, today.day));
        final dayWorkouts = _getWorkoutsForDay(workouts, day);

        // Watch schedule items for this day
        final dayDate = DateTime(day.year, day.month, day.day);
        final scheduleAsync = ref.watch(dailyScheduleProvider(dayDate));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day header
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isToday ? colors.cyan : colors.elevated,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday ? null : Border.all(color: colors.cardBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(day).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isToday ? Colors.white : colors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isToday ? Colors.white : colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE').format(day),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isToday ? colors.cyan : (isPast ? colors.textMuted : colors.textPrimary),
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, yyyy').format(day),
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.cyan.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'TODAY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colors.cyan,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Schedule items for the day
            scheduleAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (schedule) {
                if (schedule.items.isNotEmpty) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: MediaQuery.of(context).size.width < 380 ? 40.0 : 60.0,
                    ),
                    child: Column(
                      children: schedule.items.map((item) => ScheduleItemCard(
                        item: item,
                        isDark: colors.isDark,
                        onTap: () => _showAddItemSheet(context, colors, prefilledTime: item.startTime),
                        onComplete: () => _completeItem(item, colors),
                      )).toList(),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Workouts for the day (legacy support)
            if (dayWorkouts.isEmpty)
              Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final leftMargin = screenWidth < 380 ? 40.0 : 60.0;
                  return scheduleAsync.maybeWhen(
                    data: (schedule) {
                      if (schedule.items.isNotEmpty) return const SizedBox.shrink();
                      return Container(
                        margin: EdgeInsets.only(left: leftMargin, bottom: 8),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: colors.elevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.cardBorder.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event_available, size: 20, color: colors.textMuted),
                            const SizedBox(width: 12),
                            Text(
                              isPast ? 'Rest day' : 'No items scheduled',
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    orElse: () => Container(
                      margin: EdgeInsets.only(left: leftMargin, bottom: 8),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        color: colors.elevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.cardBorder.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_available, size: 20, color: colors.textMuted),
                          const SizedBox(width: 12),
                          Text(
                            isPast ? 'Rest day' : 'No items scheduled',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              ...dayWorkouts.map((workout) => _AgendaWorkoutCard(
                workout: workout,
                colors: colors,
                onTap: () => context.push('/workout/${workout.id}'),
              )),

            // Divider between days
            if (index < 6)
              Divider(
                color: colors.cardBorder.withOpacity(0.3),
                height: 24,
              ),
          ],
        );
      },
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

  Future<void> _completeItem(ScheduleItem item, ThemeColors colors) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final repository = ref.read(scheduleRepositoryProvider);
      await repository.completeItem(userId, item.id);
      ref.read(scheduleRefreshProvider.notifier).state++;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Completed "${item.title}"'),
            backgroundColor: colors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete: $e'),
            backgroundColor: colors.error,
          ),
        );
      }
    }
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
        await ref.read(workoutsProvider.notifier).refresh();
        ref.invalidate(workoutsProvider);

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
    final weekStartDay = ref.read(weekStartDayProvider);
    final now = DateTime.now();
    ref.read(selectedWeekProvider.notifier).state =
        _weekStartFor(now, weekStartDay);
  }

  /// Compute which training dates in this week still need workouts
  List<DateTime> _getMissingTrainingDates(
    List<Workout> workouts,
    DateTime weekStart,
    List<int> userWorkoutDays,
  ) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final missing = <DateTime>[];

    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      // Convert day to 0-indexed (Mon=0..Sun=6)
      final dayIndex = (day.weekday - 1) % 7; // weekday 1=Mon → 0, 7=Sun → 6

      // Skip if not a training day
      if (!userWorkoutDays.contains(dayIndex)) continue;

      // Skip past days
      if (day.isBefore(todayDate)) continue;

      // Skip if day already has a workout
      final hasWorkout = _getWorkoutsForDay(workouts, day).isNotEmpty;
      if (hasWorkout) continue;

      missing.add(day);
    }
    return missing;
  }

  Widget _buildGenerateWeekBanner(
    AsyncValue<List<Workout>> workoutsState,
    DateTime selectedWeek,
    ThemeColors colors,
  ) {
    // Get user's workout days
    final userState = ref.watch(currentUserProvider);
    final user = userState.valueOrNull;
    final workoutDays = user?.workoutDays ?? [];

    // Don't show if no training days configured
    if (workoutDays.isEmpty) return const SizedBox.shrink();

    return workoutsState.maybeWhen(
      data: (workouts) {
        final missingDates = _getMissingTrainingDates(
          workouts,
          selectedWeek,
          workoutDays,
        );

        // Don't show if all training days filled
        if (missingDates.isEmpty && !_isGeneratingWeek) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.cyan.withOpacity(0.15),
                colors.cyan.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.cyan.withOpacity(0.3)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _isGeneratingWeek
                  ? null
                  : () => _generateThisWeek(missingDates, colors),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isGeneratingWeek
                    ? _buildGeneratingProgress(colors)
                    : Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colors.cyan.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: colors.cyan,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Generate This Week',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${missingDates.length} workout${missingDates.length == 1 ? '' : 's'} to generate',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: colors.cyan,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildGeneratingProgress(ThemeColors colors) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.cyan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Generating $_generatedCount/$_totalToGenerate...',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _totalToGenerate > 0
                ? _generatedCount / _totalToGenerate
                : 0,
            backgroundColor: colors.cyan.withOpacity(0.1),
            color: colors.cyan,
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Future<void> _generateThisWeek(
    List<DateTime> missingDates,
    ThemeColors colors,
  ) async {
    if (missingDates.isEmpty) return;

    setState(() {
      _isGeneratingWeek = true;
      _generatedCount = 0;
      _totalToGenerate = missingDates.length;
    });

    int successCount = 0;

    for (final date in missingDates) {
      try {
        final workout = await ref
            .read(workoutsProvider.notifier)
            .generateWorkoutForDate(date);

        if (workout != null) {
          successCount++;
        }
      } catch (e) {
        debugPrint('❌ [Schedule] Error generating for $date: $e');
      }

      if (!mounted) return;
      setState(() {
        _generatedCount++;
      });
    }

    if (!mounted) return;
    setState(() {
      _isGeneratingWeek = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          successCount == missingDates.length
              ? 'Generated $successCount workout${successCount == 1 ? '' : 's'} for this week'
              : 'Generated $successCount of ${missingDates.length} workouts',
        ),
        backgroundColor:
            successCount == missingDates.length ? colors.success : colors.warning,
      ),
    );
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
                  const SizedBox(width: 6),
                  // Sun/Mon toggle chip
                  GestureDetector(
                    onTap: onToggleWeekStart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.textMuted.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colors.textMuted.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        weekStartDay == 1 ? 'Mon' : 'Sun',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.textMuted,
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
                    fontSize: 11,
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
            workout.formattedDurationShort,
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

// ─────────────────────────────────────────────────────────────────
// Agenda View Workout Card (larger, phone-friendly)
// ─────────────────────────────────────────────────────────────────

class _AgendaWorkoutCard extends StatelessWidget {
  final Workout workout;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _AgendaWorkoutCard({
    required this.workout,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = AppColors.getWorkoutTypeColor(workout.type ?? 'strength');
    final isCompleted = workout.isCompleted ?? false;
    final screenWidth = MediaQuery.of(context).size.width;
    final leftMargin = screenWidth < 380 ? 40.0 : 60.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(left: leftMargin, bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted
              ? colors.success.withOpacity(0.1)
              : colors.elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? colors.success.withOpacity(0.4)
                : typeColor.withOpacity(0.3),
            width: isCompleted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Workout type icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getWorkoutIcon(workout.type),
                color: typeColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Workout details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.name ?? 'Workout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? colors.success
                          : colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          workout.type?.toUpperCase() ?? 'STRENGTH',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: typeColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: colors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${workout.durationMinutes ?? 45} min',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fitness_center, size: 14, color: colors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${workout.exerciseCount} ex',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Status indicator
            if (isCompleted)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.success.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: colors.success,
                  size: 20,
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                color: colors.textMuted,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getWorkoutIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'strength':
        return Icons.fitness_center;
      case 'cardio':
        return Icons.directions_run;
      case 'hiit':
        return Icons.flash_on;
      case 'flexibility':
        return Icons.self_improvement;
      case 'yoga':
        return Icons.self_improvement;
      default:
        return Icons.fitness_center;
    }
  }
}
