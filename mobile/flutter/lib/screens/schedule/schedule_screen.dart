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
import '../../data/models/user_program_assignment.dart';
import '../../data/models/workout_program_context.dart';
import '../../data/providers/program_assignments_provider.dart';
import '../../data/providers/schedule_provider.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../core/services/posthog_service.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/glass_sheet.dart';
import '../profile/synced_workout_detail_screen.dart';
import '../workout/widgets/program_manage_sheet.dart';
import 'widgets/active_programs_strip.dart';
import 'widgets/add_schedule_item_sheet.dart';
import 'widgets/manage_programs_sheet.dart';
import 'widgets/program_color.dart';
import 'widgets/program_session_card.dart';
import 'widgets/schedule_filter_sheet.dart';
import 'widgets/schedule_item_card.dart';
import 'widgets/timeline_view.dart';

import '../../l10n/generated/app_localizations.dart';
part 'schedule_screen_part_week_selector.dart';

/// Helper: compute start of week for a given date, using weekStartDay (1=Mon, 7=Sun)
DateTime _weekStartFor(DateTime date, int weekStartDay) {
  // DateTime.weekday: 1=Mon..7=Sun
  final diff = (date.weekday - weekStartDay + 7) % 7;
  return DateTime(
    date.year,
    date.month,
    date.day,
  ).subtract(Duration(days: diff));
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

  // Program-aware agenda filter (by program + by type). Empty = show all.
  ScheduleFilter _filter = ScheduleFilter.none;

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
          PillAppBarAction(icon: Icons.today, onTap: () => _goToToday(ref)),
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
              ref.read(selectedWeekProvider.notifier).state = _weekStartFor(
                now,
                newStartDay,
              );
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
                        context,
                        workouts,
                        selectedWeek,
                        colors,
                      );
                    case 'agenda':
                    default:
                      return _buildAgendaView(
                        context,
                        workouts,
                        selectedWeek,
                        colors,
                      );
                  }
                }
                // Error with no cached data to fall back to.
                if (workoutsState.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: colors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load: ${workoutsState.error}',
                          style: TextStyle(color: colors.textPrimary),
                        ),
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
                      style: TextStyle(fontSize: 14, color: colors.textMuted),
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

  void _showAddItemSheet(
    BuildContext context,
    ThemeColors colors, {
    String? prefilledTime,
  }) {
    final selectedWeek = ref.read(selectedWeekProvider);
    // Use today if within the selected week, otherwise use Monday of selected week
    final now = DateTime.now();
    final weekEnd = selectedWeek.add(const Duration(days: 6));
    final selectedDate =
        (now.isAfter(selectedWeek) &&
            now.isBefore(weekEnd.add(const Duration(days: 1))))
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

  Future<void> _createScheduleItem(
    ScheduleItemCreate item,
    ThemeColors colors,
  ) async {
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
  Widget _buildTimelineView(
    BuildContext context,
    DateTime weekStart,
    ThemeColors colors,
  ) {
    // Use today if within the selected week
    final now = DateTime.now();
    final weekEnd = weekStart.add(const Duration(days: 6));
    final selectedDate =
        (now.isAfter(weekStart.subtract(const Duration(days: 1))) &&
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.accent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).todayScoreCardToday,
                    style: ZType.lbl(
                      9,
                      color: colors.accent,
                      letterSpacing: 1.6,
                    ),
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
                  onItemTap: (item) => _showAddItemSheet(
                    context,
                    colors,
                    prefilledTime: item.startTime,
                  ),
                  onEmptyTap: (time) =>
                      _showAddItemSheet(context, colors, prefilledTime: time),
                );
              }
              if (scheduleAsync.hasError) {
                return Center(
                  child: Text(
                    'Failed to load timeline: ${scheduleAsync.error}',
                    style: TextStyle(color: colors.error),
                  ),
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

  /// Agenda view - vertical scrolling list grouped by day. Program-aware:
  /// renders a merged multi-program calendar (curated photo-forward cards, AI
  /// placeholders on uncovered training days), an active-programs strip + filter
  /// bar header, and a soft recovery caution on heavy days.
  Widget _buildAgendaView(
    BuildContext context,
    List<Workout> workouts,
    DateTime weekStart,
    ThemeColors colors,
  ) {
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final today = DateTime.now();

    // Active program enrollments (drive the strip, card colors, AI ghosting).
    final assignments =
        ref
            .watch(programAssignmentsProvider)
            .valueOrNull
            ?.where((a) => a.isActive)
            .toList() ??
        const <UserProgramAssignment>[];
    final userWorkoutDays =
        ref.watch(currentUserProvider).valueOrNull?.workoutDays ??
        const <int>[];

    final hasPrograms = assignments.isNotEmpty;
    final headerCount = hasPrograms ? 1 : 0;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: headerCount + 7,
      itemBuilder: (context, rawIndex) {
        // Header row: active-programs strip + filter bar (only with programs).
        if (hasPrograms && rawIndex == 0) {
          return Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ActiveProgramsStrip(
                  assignments: assignments,
                  colors: colors,
                  onManage: _openManagePrograms,
                  onTapProgram: _onTapProgramChip,
                ),
                const SizedBox(height: 12),
                ScheduleFilterBar(
                  filter: _filter,
                  colors: colors,
                  onOpenSheet: () => _openFilterSheet(assignments, workouts),
                  onToggleType: (t) =>
                      setState(() => _filter = _filter.toggleType(t)),
                  onClear: () => setState(() => _filter = ScheduleFilter.none),
                ),
              ],
            ),
          );
        }

        final index = rawIndex - headerCount;
        final day = days[index];
        final isToday =
            day.year == today.year &&
            day.month == today.month &&
            day.day == today.day;
        final isPast = day.isBefore(
          DateTime(today.year, today.month, today.day),
        );
        final dayWorkouts = _getWorkoutsForDay(workouts, day);
        final dayAccent = _accentForWeekday(day.weekday);

        // Watch schedule items for this day
        final dayDate = DateTime(day.year, day.month, day.day);
        final scheduleAsync = ref.watch(dailyScheduleProvider(dayDate));

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
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
                                  : (isPast
                                        ? colors.textMuted
                                        : colors.textSecondary),
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            '${day.day}',
                            style: ZType.disp(
                              18,
                              color: isToday
                                  ? colors.accentContrast
                                  : (isPast
                                        ? colors.textMuted
                                        : colors.textPrimary),
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
                              color: isToday
                                  ? dayAccent
                                  : (isPast
                                        ? colors.textMuted
                                        : colors.textPrimary),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: dayAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: dayAccent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'TODAY',
                          style: ZType.lbl(
                            10,
                            color: dayAccent,
                            letterSpacing: 1.8,
                          ),
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
                        left: MediaQuery.of(context).size.width < 380
                            ? 40.0
                            : 60.0,
                      ),
                      child: Column(
                        children: schedule.items
                            .map(
                              (item) => ScheduleItemCard(
                                item: item,
                                isDark: colors.isDark,
                                onTap: () => _showAddItemSheet(
                                  context,
                                  colors,
                                  prefilledTime: item.startTime,
                                ),
                                onComplete: () => _completeItem(item, colors),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Program-aware sessions (curated cards + AI placeholders +
              // recovery caution), or the empty/rest tile.
              _buildDaySessions(
                context,
                day,
                isPast,
                dayWorkouts,
                assignments,
                userWorkoutDays,
                scheduleAsync.valueOrNull?.items.isNotEmpty ?? false,
                dayAccent,
                colors,
              ),

              // Divider between days
              if (index < 6)
                Divider(color: colors.cardBorder.withOpacity(0.3), height: 24),
            ],
          ),
        );
      },
    );
  }

  /// Build a single day's session list: filtered + ordered program/AI/ad-hoc
  /// workout cards, an AI placeholder on uncovered training days, and a soft
  /// recovery caption on heavy days. Falls back to the empty/rest tile.
  Widget _buildDaySessions(
    BuildContext context,
    DateTime day,
    bool isPast,
    List<Workout> dayWorkouts,
    List<UserProgramAssignment> assignments,
    List<int> userWorkoutDays,
    bool hasScheduleItems,
    Color dayAccent,
    ThemeColors colors,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final leftMargin = screenWidth < 380 ? 40.0 : 60.0;

    // Filter, then order primary (Main) first, add-ons after, each group
    // keeping its existing order (stable). Time-of-day ordering is a follow-up.
    final visible = dayWorkouts.where(_filter.allows).toList();
    final primary = visible
        .where((w) => !(w.programContext?.isAddon ?? false))
        .toList();
    final addon = visible
        .where((w) => (w.programContext?.isAddon ?? false))
        .toList();
    final ordered = [...primary, ...addon];
    final multiSession = ordered.length > 1;

    // AI placeholder: an uncovered training day with nothing materialized yet.
    final weekday0 = (day.weekday - 1) % 7;
    final covered = assignmentForWeekday(assignments, weekday0) != null;
    final isTrainingDay = userWorkoutDays.contains(weekday0);
    final filterAllowsAi =
        _filter.programs.isEmpty ||
        _filter.programs.contains(kAiProgramFilterToken);
    final showGhost =
        isTrainingDay &&
        !isPast &&
        !covered &&
        dayWorkouts.isEmpty &&
        filterAllowsAi;

    // Recovery caution (client-side heuristic, never blocks).
    final totalMin = ordered.fold<int>(0, (s, w) => s + w.bestDurationMinutes);
    final bigDay = ordered.length >= 3 || totalMin >= 120;

    final children = <Widget>[];
    for (final w in ordered) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 8));
      children.add(_sessionCard(context, w, day, assignments, multiSession));
    }
    if (showGhost) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 8));
      children.add(AiPlaceholderCard(onTap: () => _generateForDate(day)));
    }
    if (bigDay && ordered.isNotEmpty) {
      children.add(const SizedBox(height: 8));
      children.add(_recoveryCaution(ordered.length, totalMin, colors));
    }

    if (children.isEmpty) {
      // No sessions, no ghost: empty/rest tile (unless custom items fill it).
      if (hasScheduleItems) return const SizedBox.shrink();
      return _buildEmptyDayTile(leftMargin, dayAccent, isPast, colors);
    }

    return Padding(
      padding: EdgeInsets.only(left: leftMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  /// One program-aware session card. Curated workouts resolve a stable program
  /// color + "NAME · W{w}D{n}" tag; non-program (AI / synced / ad-hoc) workouts
  /// fall back to a type color + type label.
  Widget _sessionCard(
    BuildContext context,
    Workout w,
    DateTime day,
    List<UserProgramAssignment> assignments,
    bool multiSession,
  ) {
    final ctx = w.programContext;
    final assignmentId = ctx?.assignmentId;
    UserProgramAssignment? assignment;
    if (assignmentId != null) {
      for (final a in assignments) {
        if (a.id == assignmentId) {
          assignment = a;
          break;
        }
      }
    }

    final Color accent = (assignmentId != null && assignmentId.isNotEmpty)
        ? ProgramColors.forKey(assignmentId)
        : AppColors.getWorkoutTypeColor(w.type ?? 'strength');

    final isAddon = ctx?.isAddon ?? false;
    String? slotBadge;
    if (multiSession) {
      slotBadge = isAddon ? 'Extra' : 'Main';
    } else if (isAddon) {
      slotBadge = 'Extra';
    }

    // AI when there's no curated-program name to attribute (after the
    // assignment fallback) — mirrors the home hero's program/AI vocabulary.
    final isAi = _programNameFor(ctx, assignment) == null;

    // The curated program to open from the tag pill — prefer the assignment's
    // authoritative `sourceProgramId`, fall back to the workout's context id.
    final openId = _firstNonEmpty([
      assignment?.sourceProgramId,
      ctx?.programId,
    ]);

    return ProgramSessionCard(
      workout: w,
      tagLabel: _tagFor(w, ctx, assignment, day),
      accent: accent,
      slotBadge: slotBadge,
      isAi: isAi,
      compact: isAddon,
      onTap: () => _openWorkout(context, w),
      onOpenProgram: (!isAi && openId != null)
          ? () {
              HapticService.selection();
              context.push(
                '/workout/program-detail',
                extra: {'programId': openId},
              );
            }
          : null,
    );
  }

  /// First trimmed non-empty string in [values], or null.
  String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      final t = v?.trim();
      if (t != null && t.isNotEmpty) return t;
    }
    return null;
  }

  /// The curated-program name for a session, preferring the workout's own
  /// program context, then the matched assignment (renamed → editorial name).
  /// Null when the session has no program provenance (a pure AI workout).
  String? _programNameFor(
    WorkoutProgramContext? ctx,
    UserProgramAssignment? assignment,
  ) {
    final fromCtx = ctx?.programName?.trim();
    if (fromCtx != null && fromCtx.isNotEmpty) return fromCtx;
    final custom = assignment?.customProgramName?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    final display = assignment?.displayName?.trim();
    if (display != null && display.isNotEmpty) return display;
    return null;
  }

  /// "HYROX · W1D3" for program workouts; a type label otherwise.
  String _tagFor(
    Workout w,
    WorkoutProgramContext? ctx,
    UserProgramAssignment? assignment,
    DateTime day,
  ) {
    final name = _programNameFor(ctx, assignment);
    if (name != null && name.isNotEmpty) {
      final sb = StringBuffer(name);
      final wk = ctx?.programWeek ?? assignment?.currentWeek;
      if (wk != null && wk > 0) {
        sb.write(' · W$wk');
        final dn = _dayNumberInProgram(assignment, day);
        if (dn != null) sb.write('D$dn');
      }
      return sb.toString();
    }
    final type = w.type?.trim();
    if (type != null && type.isNotEmpty) return type;
    return 'Workout';
  }

  /// Which numbered session of the program's week this day is (1-based), from
  /// the assignment's training days. Null when unknown.
  int? _dayNumberInProgram(UserProgramAssignment? assignment, DateTime day) {
    if (assignment == null || assignment.assignedDays.isEmpty) return null;
    final weekday0 = (day.weekday - 1) % 7;
    final sorted = [...assignment.assignedDays]..sort();
    final idx = sorted.indexOf(weekday0);
    return idx >= 0 ? idx + 1 : null;
  }

  /// Soft, non-blocking recovery caption for heavy days.
  Widget _recoveryCaution(int sessions, int minutes, ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: colors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: colors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$sessions sessions today (~$minutes min). Big day — recover well.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: colors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Route a workout tap (synced import → detail, completed → summary, else
  /// active detail). Mirrors the legacy agenda card tap behavior.
  void _openWorkout(BuildContext context, Workout w) {
    if (w.generationMethod == 'health_connect_import') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SyncedWorkoutDetailScreen(workout: w),
        ),
      );
    } else if (w.isCompleted == true) {
      context.push('/workout-summary/${w.id}', extra: w);
    } else {
      context.push('/workout/${w.id}', extra: w);
    }
  }

  /// Generate the AI workout for a specific (uncovered) training day, triggered
  /// from the ghosted AI placeholder card.
  Future<void> _generateForDate(DateTime date) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Generating ${DateFormat('EEEE').format(date)}\'s workout…',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    try {
      final workout = await ref
          .read(workoutsProvider.notifier)
          .generateWorkoutForDate(date);
      if (!mounted) return;
      if (workout != null) {
        AppSnackBar.success(
          context,
          'Generated ${DateFormat('EEEE, MMM d').format(date)}',
        );
      } else {
        AppSnackBar.error(context, 'Could not generate that workout.');
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Could not generate: $e');
    }
  }

  void _openManagePrograms() {
    showManageProgramsSheet(context, ref);
  }

  Future<void> _openFilterSheet(
    List<UserProgramAssignment> assignments,
    List<Workout> workouts,
  ) async {
    final available = <ScheduleWorkoutType>{};
    for (final w in workouts) {
      available.add(scheduleTypeFor(w));
    }
    final result = await showScheduleFilterSheet(
      context: context,
      current: _filter,
      assignments: assignments,
      availableTypes: available,
    );
    if (result != null && mounted) {
      setState(() => _filter = result);
    }
  }

  void _onTapProgramChip(UserProgramAssignment assignment) {
    // TODO(full-program-view): open the all-weeks view (screen F). For now,
    // open the existing per-program manage sheet.
    showProgramManageSheet(context, ref, assignment);
  }

  Widget _buildWeekView(
    BuildContext context,
    List<Workout> workouts,
    DateTime weekStart,
    ThemeColors colors,
  ) {
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final today = DateTime.now();

    return Row(
      children: days.asMap().entries.map((entry) {
        final index = entry.key;
        final day = entry.value;
        final isToday =
            day.year == today.year &&
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
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isTargetDay
                                            ? colors.cyan.withOpacity(0.5)
                                            : colors.cardBorder.withOpacity(
                                                0.2,
                                              ),
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
                                      setState(
                                        () => _draggingWorkout = workout,
                                      );
                                    },
                                    onDragEnd: () {
                                      setState(() {
                                        _draggingWorkout = null;
                                        _targetDayIndex = null;
                                      });
                                    },
                                    isDragging:
                                        _draggingWorkout?.id == workout.id,
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

  Widget _buildEmptyDayTile(
    double leftMargin,
    Color dayAccent,
    bool isPast,
    ThemeColors colors,
  ) {
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
            isPast
                ? AppLocalizations.of(context).scheduleRestDay
                : AppLocalizations.of(context).scheduleNoItemsScheduled,
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

  Future<void> _rescheduleWorkout(
    Workout workout,
    DateTime newDate,
    ThemeColors colors,
  ) async {
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
      final success = await repository.rescheduleWorkout(
        workout.id!,
        newDateStr,
      );

      if (success) {
        await ref.read(workoutsProvider.notifier).silentRefresh();

        if (mounted) {
          AppSnackBar.success(
            context,
            'Workout moved to ${DateFormat('EEEE, MMM d').format(newDate)}',
          );
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
    ref.read(selectedWeekProvider.notifier).state = current.add(
      Duration(days: 7 * delta),
    );
  }

  void _goToToday(WidgetRef ref) {
    final weekStartDay = ref.read(weekStartDayProvider);
    final now = DateTime.now();
    ref.read(selectedWeekProvider.notifier).state = _weekStartFor(
      now,
      weekStartDay,
    );
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
            border: Border.all(color: AppColors.cardBorder, width: 1),
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
                                color: colors.accent.withValues(alpha: 0.35),
                              ),
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
                                  AppLocalizations.of(
                                    context,
                                  ).scheduleGenerateThisWeek,
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
        backgroundColor: successCount == missingDates.length
            ? colors.success
            : colors.warning,
      ),
    );
  }
}
