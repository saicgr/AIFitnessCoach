import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/pill_app_bar.dart';
import '../../core/providers/user_provider.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/schedule_item.dart';
import '../../data/models/workout.dart';
import '../../data/providers/schedule_provider.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../core/services/posthog_service.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/glass_sheet.dart';
import '../profile/synced_workout_detail_screen.dart';
import 'widgets/add_schedule_item_sheet.dart';
import 'widgets/schedule_item_card.dart';
import 'widgets/timeline_view.dart';

import '../../l10n/generated/app_localizations.dart';
part 'schedule_screen_part_week_selector.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'schedule_viewed');
    });
  }

  @override
  Widget build(BuildContext context) {
    final workoutsState = ref.watch(workoutsProvider);
    final selectedWeek = ref.watch(selectedWeekProvider);
    final colors = ref.colors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: PillAppBar(
        title: AppLocalizations.of(context).scheduleWorkoutSchedule,
        actions: [
          PillAppBarAction(
            icon: _viewModeIcon,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _viewMode = _nextViewMode;
              });
            },
          ),
          PillAppBarAction(
            icon: Icons.today,
            onTap: () => _goToToday(ref),
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
            child: Builder(
              builder: (context) {
                // Instant-load: keep showing the last-known workouts while a
                // silent revalidate runs, so a refresh never blanks the
                // agenda back to a spinner.
                final workouts = workoutsState.valueOrNull;
                if (workouts != null) {
                  switch (_viewMode) {
                    case 'timeline':
                      return _buildTimelineView(context, selectedWeek, colors);
                    case 'week':
                      return _buildWeekView(
                          context, workouts, selectedWeek, colors);
                    case 'agenda':
                    default:
                      return _buildAgendaView(
                          context, workouts, selectedWeek, colors);
                  }
                }
                // Error with no cached data to fall back to.
                if (workoutsState.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: colors.error),
                        const SizedBox(height: 16),
                        Text('Failed to load: ${workoutsState.error}',
                            style: TextStyle(color: colors.textPrimary)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              ref.read(workoutsProvider.notifier).refresh(),
                          child: Text(AppLocalizations.of(context).buttonRetry),
                        ),
                      ],
                    ),
                  );
                }
                // Cold start, nothing cached yet — layout-matched skeleton
                // instead of a blocking spinner.
                return _buildAgendaSkeleton(colors);
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
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      final repository = ref.read(scheduleRepositoryProvider);
      await repository.createItem(userId, item);
      // Refresh the schedule
      ref.read(scheduleRefreshProvider.notifier).state++;
      if (mounted) {
        AppSnackBar.success(context, 'Added "${item.title}" to schedule');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed to add item: $e');
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
                DateFormat('EEEE, MMM d').format(selectedDate).toUpperCase(),
                style: ZType.lbl(
                  14,
                  color: colors.textPrimary,
                  letterSpacing: 1.4,
                ),
              ),
              if (selectedDate.year == now.year &&
                  selectedDate.month == now.month &&
                  selectedDate.day == now.day) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.accent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    AppLocalizations.of(context).todayScoreCardToday,
                    style: ZType.lbl(9, color: colors.accent, letterSpacing: 1.6),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              // Keep the timeline visible while a silent revalidate runs.
              final schedule = scheduleAsync.valueOrNull;
              if (schedule != null) {
                return TimelineView(
                  items: schedule.items,
                  isDark: colors.isDark,
                  onItemTap: (item) => _showAddItemSheet(context, colors,
                      prefilledTime: item.startTime),
                  onEmptyTap: (time) =>
                      _showAddItemSheet(context, colors, prefilledTime: time),
                );
              }
              if (scheduleAsync.hasError) {
                return Center(
                  child: Text(
                      'Failed to load timeline: ${scheduleAsync.error}',
                      style: TextStyle(color: colors.error)),
                );
              }
              // Cold start — layout-matched skeleton list of time-slot rows.
              return const SkeletonList(
                scrollable: true,
                itemCount: 8,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              );
            },
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
        final dayAccent = _accentForWeekday(day.weekday);

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
                      color: isToday ? dayAccent : colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday
                          ? null
                          : Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(day).toUpperCase(),
                          style: ZType.lbl(
                            9,
                            color: isToday
                                ? colors.accentContrast
                                : (isPast ? colors.textMuted : colors.textSecondary),
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          '${day.day}',
                          style: ZType.disp(
                            18,
                            color: isToday
                                ? colors.accentContrast
                                : (isPast ? colors.textMuted : colors.textPrimary),
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
                          DateFormat('EEEE').format(day).toUpperCase(),
                          style: ZType.lbl(
                            15,
                            color: isToday ? dayAccent : (isPast ? colors.textMuted : colors.textPrimary),
                            letterSpacing: 1.5,
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
                        color: dayAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: dayAccent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'TODAY',
                        style: ZType.lbl(10, color: dayAccent, letterSpacing: 1.8),
                      ),
                    ),
                ],
              ),
            ),

            // Schedule items for the day. Read via valueOrNull so a silent
            // background revalidate never blanks already-rendered items.
            Builder(
              builder: (context) {
                final schedule = scheduleAsync.valueOrNull;
                if (schedule != null && schedule.items.isNotEmpty) {
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
                      return _buildEmptyDayTile(leftMargin, dayAccent, isPast, colors);
                    },
                    orElse: () => _buildEmptyDayTile(leftMargin, dayAccent, isPast, colors),
                  );
                },
              )
            else
              ...dayWorkouts.asMap().entries.map((entry) {
                final workoutCard = _AgendaWorkoutCard(
                  workout: entry.value,
                  colors: colors,
                  onTap: () {
                    if (entry.value.generationMethod == 'health_connect_import') {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => SyncedWorkoutDetailScreen(workout: entry.value),
                      ));
                    } else if (entry.value.isCompleted == true) {
                      // Completed workouts open the summary (Detail/Summary/Advanced)
                      // instead of the active "Start workout" detail.
                      context.push('/workout-summary/${entry.value.id}', extra: entry.value);
                    } else {
                      context.push('/workout/${entry.value.id}', extra: entry.value);
                    }
                  },
                );
                return workoutCard;
              }),

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
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      final repository = ref.read(scheduleRepositoryProvider);
      await repository.completeItem(userId, item.id);
      ref.read(scheduleRefreshProvider.notifier).state++;
      if (mounted) {
        AppSnackBar.success(context, 'Completed "${item.title}"');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed to complete: $e');
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

  /// Signature: accent is reserved — the agenda reads as a hairline-led list
  /// with a single resolved accent, not a per-weekday rainbow. Kept as a method
  /// so every caller threads the one accent through unchanged.
  Color _accentForWeekday(int weekday) {
    return ThemeColors.of(context).accent;
  }

  /// Layout-matched skeleton for the agenda view — a vertical list of
  /// day-header + content placeholders, mirroring [_buildAgendaView] so the
  /// skeleton -> content cross-fade does not reflow. Cold-start only; once
  /// workouts are cached the real list renders instantly.
  Widget _buildAgendaSkeleton(ThemeColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 7,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day-header placeholder: 48x48 date chip + two text lines.
              Row(
                children: [
                  const SkeletonBox(width: 48, height: 48, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonBox(width: 120, height: 16),
                        SizedBox(height: 6),
                        SkeletonBox(width: 90, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Day content placeholder card.
              Padding(
                padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width < 380 ? 40.0 : 60.0,
                ),
                child: const SkeletonBox(height: 56, radius: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyDayTile(double leftMargin, Color dayAccent, bool isPast, ThemeColors colors) {
    return Container(
      margin: EdgeInsets.only(left: leftMargin, bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(
            isPast ? Icons.bedtime_outlined : Icons.event_available,
            size: 20,
            color: isPast ? colors.textMuted : dayAccent,
          ),
          const SizedBox(width: 12),
          Text(
            isPast ? AppLocalizations.of(context).scheduleRestDay : AppLocalizations.of(context).scheduleNoItemsScheduled,
            style: ZType.lbl(
              12,
              color: isPast ? colors.textMuted : colors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
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
        await ref.read(workoutsProvider.notifier).silentRefresh();

        if (mounted) {
          AppSnackBar.success(context, 'Workout moved to ${DateFormat('EEEE, MMM d').format(newDate)}');
        }
      } else {
        throw Exception('Failed to reschedule');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed to reschedule: $e');
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
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: colors.accent, width: 3),
              top: BorderSide(color: AppColors.cardBorder),
              right: BorderSide(color: AppColors.cardBorder),
              bottom: BorderSide(color: AppColors.cardBorder),
            ),
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
                              color: colors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: colors.accent.withValues(alpha: 0.35)),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: colors.accent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context).scheduleGenerateThisWeek,
                                  style: ZType.lbl(
                                    14,
                                    color: colors.textPrimary,
                                    letterSpacing: 1.2,
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
                            color: colors.accent,
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
