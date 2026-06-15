import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/week_start_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/workout_screen_summary.dart';
import '../../../data/providers/branded_program_provider.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/design_system/zealova.dart';
import 'exercise_preferences_card.dart';

/// Signature v2 body for the Workouts tab.
///
/// A single scrolling column rendered top-to-bottom under the Anton
/// "WORKOUTS" masthead:
///   1. TODAY block — kicker + Anton workout name + muted meta line + a
///      solid-accent "START WORKOUT →" + a ghost "PREVIEW PLAN ›". On a rest
///      day: "REST DAY" + ghost "PREVIEW TOMORROW ›".
///   2. THIS WEEK — a 7-column hairline strip (M T W T F S S) with each day's
///      workout-type label + a dot; today highlighted with the accent.
///   3. PROGRAM — label + hairline "WEEK n OF m" rule + LIBRARY/BUILDER/
///      PROGRAMS text links.
///   4. EXERCISE PREFERENCES — a ZealovaListRow.
///   5. HISTORY — hairline rows (weekday + name + mono duration · volume) +
///      "ALL HISTORY ›".
///
/// All routes/providers/callbacks preserved from the old body:
///   START WORKOUT  → context.push('/active-workout', extra: workout)
///   PREVIEW PLAN   → context.push('/workout/[id]', extra: workout)
///   LIBRARY        → context.push('/library')
///   BUILDER / "+"  → context.push('/workout/build')
///   PROGRAMS       → context.push('/workout/program-library')
///   EXERCISE PREFS → context.push('/settings/my-exercises')
///   ALL HISTORY    → context.push('/schedule')
class WorkoutsSignatureBody extends ConsumerWidget {
  /// Tour anchor for the exercise-preferences surface (preserved from the old
  /// body's `_exercisePreferencesKey`).
  final Key? exercisePreferencesKey;

  const WorkoutsSignatureBody({
    super.key,
    this.exercisePreferencesKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TodayBlock(),
          const SizedBox(height: 26),
          const _ThisWeekStrip(),
          const SizedBox(height: 26),
          const _ProgramBlock(),
          const SizedBox(height: 22),
          // EXERCISE PREFERENCES — the real expandable card (its header is a
          // label + chevron row). Kept inline so every preference sub-route
          // (favorites / staples / avoided / queue / warmup / increments)
          // stays reachable; margin zeroed to align with the body's padding.
          KeyedSubtree(
            key: exercisePreferencesKey,
            child: const ExercisePreferencesCard(
              margin: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 24),
          const _HistoryBlock(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 1. TODAY block
// ─────────────────────────────────────────────────────────────────────────

class _TodayBlock extends ConsumerWidget {
  const _TodayBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final today = ref.watch(todayWorkoutProvider).valueOrNull;

    // Resolve the displayable workout summary for today (or the next one).
    final TodayWorkoutSummary? summary = today?.completedWorkout ??
        today?.todayWorkout ??
        today?.nextWorkout;

    // Rest-day branch — no scheduled workout today, but there may be a next.
    final bool isRestDay = summary == null ||
        (today?.todayWorkout == null &&
            today?.completedWorkout == null &&
            (today?.restDayMessage != null || today?.nextWorkout != null));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRestDay && today?.nextWorkout != null ? 'NEXT UP' : 'TODAY',
          style: ZType.lbl(11, color: tc.accent, letterSpacing: 2.6),
        ),
        const SizedBox(height: 8),
        if (isRestDay && today?.nextWorkout == null) ...[
          // True rest day with nothing scheduled next.
          Text('REST DAY', style: ZType.disp(34, color: tc.textPrimary)),
          const SizedBox(height: 8),
          Text(
            today?.restDayMessage?.trim().isNotEmpty == true
                ? today!.restDayMessage!.trim()
                : 'Recovery is part of the program. Let the work land.',
            style: ZType.ser(15, color: tc.textSecondary),
          ),
        ] else ...[
          Text(
            (summary?.name ?? 'WORKOUT').toUpperCase(),
            style: ZType.disp(34, color: tc.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            _metaLine(summary),
            style: ZType.lbl(12.5, color: tc.textMuted, letterSpacing: 0.6),
          ),
        ],
        const SizedBox(height: 18),
        _TodayActions(
          summary: summary,
          isRestDay: isRestDay && today?.todayWorkout == null,
          alreadyCompleted: today?.completedToday == true,
        ),
      ],
    );
  }

  /// "Chest & Triceps · 8 exercises · 52 min" — muscles + count + duration,
  /// all from real summary fields. Each segment is omitted if it has no data
  /// so the line never reads "· 0 exercises ·".
  String _metaLine(TodayWorkoutSummary? s) {
    if (s == null) return '';
    final parts = <String>[];
    final muscles = _muscleLabel(s.primaryMuscles);
    if (muscles != null) parts.add(muscles);
    if (s.exerciseCount > 0) {
      parts.add('${s.exerciseCount} exercise${s.exerciseCount == 1 ? '' : 's'}');
    }
    final dur = s.formattedDurationShort.replaceAll('m', ' min');
    parts.add(dur);
    return parts.join('  ·  ');
  }

  String? _muscleLabel(List<String> muscles) {
    if (muscles.isEmpty) return null;
    final cleaned = muscles
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .map((m) => '${m[0].toUpperCase()}${m.substring(1).toLowerCase()}')
        .toSet()
        .take(2)
        .toList();
    if (cleaned.isEmpty) return null;
    return cleaned.join(' & ');
  }
}

class _TodayActions extends ConsumerWidget {
  final TodayWorkoutSummary? summary;
  final bool isRestDay;
  final bool alreadyCompleted;

  const _TodayActions({
    required this.summary,
    required this.isRestDay,
    required this.alreadyCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = summary?.toWorkout();

    // Rest day with a next workout queued → single ghost preview link.
    if (isRestDay) {
      if (workout == null) return const SizedBox.shrink();
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: _GhostLinkButton(
          label: 'PREVIEW TOMORROW',
          onTap: () {
            HapticService.light();
            context.push('/workout/${workout.id}', extra: workout);
          },
        ),
      );
    }

    if (workout == null) return const SizedBox.shrink();

    // Completed today → no "Start", just a recap link.
    if (alreadyCompleted) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: _GhostLinkButton(
          label: 'VIEW RECAP',
          onTap: () {
            HapticService.light();
            context.push('/workout-summary/${workout.id}?tab=summary');
          },
        ),
      );
    }

    return Row(
      children: [
        // THE one reserved-accent CTA on this screen.
        Flexible(
          child: ZealovaButton(
            label: 'Start workout',
            trailingIcon: Icons.arrow_forward,
            variant: ZealovaButtonVariant.primary,
            expand: false,
            height: 50,
            onTap: () {
              HapticService.medium();
              context.push('/active-workout', extra: workout);
            },
          ),
        ),
        const SizedBox(width: 12),
        _GhostLinkButton(
          label: 'PREVIEW PLAN',
          onTap: () {
            HapticService.light();
            context.push('/workout/${workout.id}', extra: workout);
          },
        ),
      ],
    );
  }
}

/// A hairline ghost text link with a trailing › — used for secondary actions
/// (preview plan / preview tomorrow / view recap).
class _GhostLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GhostLinkButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: ZType.lbl(12.5,
                    color: tc.textSecondary, letterSpacing: 1.8),
              ),
              const SizedBox(width: 5),
              Text('›',
                  style: TextStyle(
                      color: tc.textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 2. THIS WEEK strip
// ─────────────────────────────────────────────────────────────────────────

class _ThisWeekStrip extends ConsumerWidget {
  const _ThisWeekStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final weekConfig = ref.watch(weekDisplayConfigProvider);

    final activeGymProfile = ref.watch(activeGymProfileProvider);
    final workoutDays = (activeGymProfile?.workoutDays.isNotEmpty == true)
        ? activeGymProfile!.workoutDays
        : (user?.workoutDays ?? const <int>[]);

    final workouts = ref.watch(workoutsProvider).valueOrNull ?? const <Workout>[];
    // Merge the live /today response so completion/type flips show immediately.
    final todayResp = ref.watch(todayWorkoutProvider).valueOrNull;
    final merged = <Workout>[...workouts];
    void mergeIfNew(Workout? w) {
      if (w == null || w.id == null) return;
      if (merged.any((e) => e.id == w.id)) return;
      merged.add(w);
    }
    mergeIfNew(todayResp?.todayWorkout?.toWorkout());
    mergeIfNew(todayResp?.completedWorkout?.toWorkout());
    mergeIfNew(todayResp?.nextWorkout?.toWorkout());

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayWeekday = today.weekday - 1; // 0 = Mon
    final weekStart = weekConfig.weekStart(today);

    final cells = <Widget>[];
    for (int displayIndex = 0; displayIndex < 7; displayIndex++) {
      final dataIndex = weekConfig.displayOrder[displayIndex];
      final dayDate = weekStart.add(Duration(days: displayIndex));
      final dateKey =
          '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';

      // Find a scheduled (non-synced) workout for this day.
      Workout? dayWorkout;
      for (final w in merged) {
        final raw = w.scheduledDate;
        if (raw == null || raw.length < 10) continue;
        if (raw.substring(0, 10) != dateKey) continue;
        if (w.isSyncedFromHealthApp) continue;
        dayWorkout = w;
        break;
      }

      final bool isWorkoutDay =
          workoutDays.contains(dataIndex) || dayWorkout != null;
      final String label = dayWorkout != null
          ? _typeLabel(dayWorkout)
          : (isWorkoutDay ? 'TRAIN' : 'REST');
      final bool completed = dayWorkout?.isCompleted == true;
      final bool isToday = dataIndex == todayWeekday;

      cells.add(
        Expanded(
          child: _WeekDayCell(
            weekdayLetter: _weekdayLetter(dataIndex),
            typeLabel: label,
            isWorkoutDay: isWorkoutDay,
            completed: completed,
            isToday: isToday,
            accent: tc.accent,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('THIS WEEK',
            style: ZType.lbl(11, color: tc.textMuted, letterSpacing: 2.4)),
        const SizedBox(height: 12),
        const ZealovaRule(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: cells),
        ),
        const ZealovaRule(),
      ],
    );
  }

  String _weekdayLetter(int dataIndex) {
    // 0=Mon .. 6=Sun
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return letters[dataIndex.clamp(0, 6)];
  }

  String _typeLabel(Workout w) {
    final name = w.name?.trim() ?? '';
    final upper = name.toUpperCase();
    // Prefer a recognizable split token baked into the workout name.
    for (final token in const [
      'PUSH',
      'PULL',
      'LEGS',
      'UPPER',
      'LOWER',
      'FULL',
      'CORE',
      'ARMS',
      'CHEST',
      'BACK',
    ]) {
      if (upper.contains(token)) return token;
    }
    final type = w.type?.trim();
    if (type != null && type.isNotEmpty) {
      return type.toUpperCase();
    }
    return 'TRAIN';
  }
}

class _WeekDayCell extends StatelessWidget {
  final String weekdayLetter;
  final String typeLabel;
  final bool isWorkoutDay;
  final bool completed;
  final bool isToday;
  final Color accent;

  const _WeekDayCell({
    required this.weekdayLetter,
    required this.typeLabel,
    required this.isWorkoutDay,
    required this.completed,
    required this.isToday,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final Color letterColor = isToday ? accent : tc.textMuted;
    final Color labelColor = !isWorkoutDay
        ? tc.textMuted.withValues(alpha: 0.55)
        : (isToday ? tc.textPrimary : tc.textSecondary);
    final Color dotColor = !isWorkoutDay
        ? AppColors.hairlineStrong
        : completed
            ? accent
            : (isToday ? accent : tc.textSecondary);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          weekdayLetter,
          style: ZType.lbl(11, color: letterColor, letterSpacing: 0.5),
        ),
        const SizedBox(height: 7),
        // Small status dot — filled accent for completed/today, hollow ring
        // for scheduled, faint for rest.
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (completed || (isToday && isWorkoutDay))
                ? dotColor
                : Colors.transparent,
            border: Border.all(color: dotColor, width: 1.2),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          typeLabel,
          maxLines: 1,
          overflow: TextOverflow.clip,
          textAlign: TextAlign.center,
          style: ZType.lbl(8.5, color: labelColor, letterSpacing: 0.3),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 3. PROGRAM block
// ─────────────────────────────────────────────────────────────────────────

class _ProgramBlock extends ConsumerWidget {
  const _ProgramBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final program = ref.watch(activeUserProgramProvider);

    final String programLabel =
        (program?.displayName.trim().isNotEmpty == true)
            ? program!.displayName.trim().toUpperCase()
            : 'YOUR PROGRAM';
    final int? currentWeek = program?.currentWeek;
    final int totalWeeks = program?.totalWeeks ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                programLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ZType.disp(20, color: tc.textPrimary),
              ),
            ),
            if (currentWeek != null && totalWeeks > 0)
              Text(
                'WEEK $currentWeek OF $totalWeeks',
                style: ZType.lbl(11, color: tc.accent, letterSpacing: 1.6),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Hairline progress rule — accent fill proportional to weeks done.
        if (currentWeek != null && totalWeeks > 0)
          _ProgressRule(
            progress: (currentWeek / totalWeeks).clamp(0.0, 1.0),
            accent: tc.accent,
          )
        else
          const ZealovaRule(),
        const SizedBox(height: 14),
        // Inline LIBRARY › BUILDER › PROGRAMS › links — replaces the old
        // floating launcher bar + the gradient library grid.
        Row(
          children: [
            _ProgramLink(
              label: 'LIBRARY',
              onTap: () {
                HapticService.light();
                context.push('/library');
              },
            ),
            const SizedBox(width: 22),
            _ProgramLink(
              label: 'BUILDER',
              onTap: () {
                HapticService.light();
                context.push('/workout/build');
              },
            ),
            const SizedBox(width: 22),
            _ProgramLink(
              label: 'PROGRAMS',
              onTap: () {
                HapticService.light();
                context.push('/workout/program-library');
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressRule extends StatelessWidget {
  final double progress;
  final Color accent;
  const _ProgressRule({required this.progress, required this.accent});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(height: 2, color: AppColors.hairlineStrong),
            Container(
              height: 2,
              width: constraints.maxWidth * progress,
              color: accent,
            ),
          ],
        );
      },
    );
  }
}

class _ProgramLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ProgramLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: ZType.lbl(12.5, color: tc.textSecondary, letterSpacing: 1.4),
          ),
          const SizedBox(width: 3),
          Text('›',
              style: TextStyle(
                  color: tc.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 5. HISTORY block
// ─────────────────────────────────────────────────────────────────────────

class _HistoryBlock extends ConsumerWidget {
  const _HistoryBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final summary = ref.watch(workoutScreenSummaryProvider).valueOrNull;

    // Prefer the lightweight previous-sessions summary; fall back to the full
    // workouts list filtered to completed, non-synced sessions.
    final List<WorkoutMiniSummary> sessions =
        summary?.previousSessions ?? const [];

    final List<_HistoryRowData> rows;
    if (sessions.isNotEmpty) {
      rows = sessions
          .take(4)
          .map((s) => _HistoryRowData(
                weekday: _weekdayShort(s.scheduledDate),
                name: s.name,
                durationMinutes: s.durationMinutes,
                volumeLbs: null,
                workoutId: s.id,
              ))
          .toList();
    } else {
      final workouts =
          ref.watch(workoutsProvider).valueOrNull ?? const <Workout>[];
      final completed = workouts
          .where((w) =>
              w.isCompleted == true && !w.isSyncedFromHealthApp)
          .toList()
        ..sort((a, b) {
          final da =
              DateTime.tryParse(a.scheduledDate ?? '') ?? DateTime(1900);
          final db =
              DateTime.tryParse(b.scheduledDate ?? '') ?? DateTime(1900);
          return db.compareTo(da);
        });
      rows = completed
          .take(4)
          .map((w) => _HistoryRowData(
                weekday: _weekdayShort(w.scheduledDate),
                name: w.name ?? 'Workout',
                durationMinutes: w.durationMinutes,
                volumeLbs: null,
                workoutId: w.id,
              ))
          .toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HISTORY',
            style: ZType.lbl(11, color: tc.textMuted, letterSpacing: 2.4)),
        const SizedBox(height: 6),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No completed sessions yet. Finish today\'s workout to start your log.',
              style: ZType.ser(14, color: tc.textSecondary),
            ),
          )
        else
          ...rows.map((r) => _HistoryRow(data: r)),
        const SizedBox(height: 12),
        _ProgramLink(
          label: 'ALL HISTORY',
          onTap: () {
            HapticService.light();
            context.push('/schedule');
          },
        ),
      ],
    );
  }

  String _weekdayShort(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const names = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return names[(dt.weekday - 1).clamp(0, 6)];
  }
}

class _HistoryRowData {
  final String weekday;
  final String name;
  final int? durationMinutes;
  final double? volumeLbs;
  final String? workoutId;

  const _HistoryRowData({
    required this.weekday,
    required this.name,
    required this.durationMinutes,
    required this.volumeLbs,
    required this.workoutId,
  });
}

class _HistoryRow extends StatelessWidget {
  final _HistoryRowData data;
  const _HistoryRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    // Right-aligned Space-Mono telemetry: "48:12 · 9,120 LB" when both are
    // present; otherwise show whichever real datum exists.
    final segments = <String>[];
    if (data.durationMinutes != null && data.durationMinutes! > 0) {
      final m = data.durationMinutes!;
      segments.add('${m ~/ 60 > 0 ? '${m ~/ 60}:' : ''}'
          '${(m % 60).toString().padLeft(m ~/ 60 > 0 ? 2 : 1, '0')}'
          '${m ~/ 60 > 0 ? '' : ' MIN'}');
    }
    if (data.volumeLbs != null && data.volumeLbs! > 0) {
      segments.add('${_formatVolume(data.volumeLbs!)} LB');
    }
    final telemetry = segments.join('  ·  ');

    return InkWell(
      onTap: data.workoutId == null
          ? null
          : () {
              HapticService.light();
              context.push('/workout-summary/${data.workoutId}?tab=summary');
            },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.hairline)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Text(
                data.weekday,
                style: ZType.lbl(11, color: tc.textMuted, letterSpacing: 1.2),
              ),
            ),
            Expanded(
              child: Text(
                data.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  color: tc.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (telemetry.isNotEmpty) ...[
              const SizedBox(width: 10),
              Text(
                telemetry,
                style: ZType.data(11, color: tc.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatVolume(double v) {
    final i = v.round();
    final s = i.toString();
    final buf = StringBuffer();
    for (int idx = 0; idx < s.length; idx++) {
      if (idx > 0 && (s.length - idx) % 3 == 0) buf.write(',');
      buf.write(s[idx]);
    }
    return buf.toString();
  }
}
