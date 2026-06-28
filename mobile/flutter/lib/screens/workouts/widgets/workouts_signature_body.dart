import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/workout_screen_summary.dart';
import '../../../data/providers/branded_program_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/tooltips/tooltip_anchors.dart';
import '../../../widgets/design_system/zealova.dart';
import '../../home/widgets/edit_program_sheet.dart';
import '../../workout/widgets/quick_workout_sheet.dart';
import 'exercise_preferences_card.dart';
import 'my_program_sheet.dart';
import 'workout_library_grid.dart';
import 'workout_planner_section.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // TODAY — the image-backed workout carousel + the nutrition-style
        // date strip (swipeable, date numbers + today pill + logged dots),
        // self-contained with two-way strip↔carousel sync. Rendered full-bleed
        // (outside the body's 20px gutter) so the carousel can peek the next
        // card exactly like Home. Replaces the old flat _TodayBlock + the
        // letter-only _ThisWeekStrip.
        const WorkoutPlannerSection(),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // QUICK GENERATE — one-tap AI workout for "I just want to train
              // now" days. Launches the existing quick-workout sheet (5–30 min,
              // built around equipment + recovery) and jumps to the result.
              // Tour anchor: "Quick generate" step targets this (eagerly built,
              // above the fold — unlike the deep "+ BUILD A WORKOUT" affordance).
              KeyedSubtree(
                key: TooltipAnchors.workoutsQuickGenerate,
                child: const _QuickGenerateBlock(),
              ),
              const SizedBox(height: 26),
              const _ProgramBlock(),
              const SizedBox(height: 24),
              // BROWSE BY TYPE — the 3×2 category grid (Strength / Cardio /
              // Mobility / HIIT / Yoga / Saved), each tile deep-links into the
              // library pre-filtered to that category.
              const _BrowseByTypeBlock(),
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
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 1b. QUICK GENERATE block
// ─────────────────────────────────────────────────────────────────────────

/// One-tap "make me a workout right now" affordance. Opens the existing
/// quick-workout sheet (`showQuickWorkoutSheet`) — 5–30 min, built around the
/// user's equipment + muscle recovery — then routes straight to the generated
/// workout's preview so they can start it. A leading accent-tinted bolt makes
/// it read as the fast lane next to the program-driven TODAY block above.
class _QuickGenerateBlock extends ConsumerWidget {
  const _QuickGenerateBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          HapticService.medium();
          final workout = await showQuickWorkoutSheet(context, ref);
          if (workout != null && context.mounted) {
            context.push('/workout/${workout.id}', extra: workout);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tc.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.bolt_rounded, size: 22, color: tc.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QUICK GENERATE',
                      style: ZType.lbl(13, color: tc.textPrimary,
                          letterSpacing: 1.8),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'A 5–30 min workout, built around your day',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ZType.lbl(11, color: tc.textMuted,
                          letterSpacing: 0.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: tc.textMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 1c. BROWSE BY TYPE block (3×2 category grid)
// ─────────────────────────────────────────────────────────────────────────

/// Section wrapper for the restored 3×2 `WorkoutLibraryGrid`. Renders a
/// hairline "BROWSE BY TYPE" label + an "ALL ›" link into the full library,
/// then the six category tiles (zero outer gutter — the body already supplies
/// the 20px horizontal padding).
class _BrowseByTypeBlock extends StatelessWidget {
  const _BrowseByTypeBlock();

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('BROWSE BY TYPE',
                  style: ZType.lbl(11, color: tc.textMuted, letterSpacing: 2.4)),
            ),
            _ProgramLink(
              label: 'ALL',
              onTap: () {
                HapticService.light();
                context.push('/library');
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        const WorkoutLibraryGrid(padding: EdgeInsets.zero),
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

    final bool hasProgram = program?.displayName.trim().isNotEmpty == true;
    final String programLabel =
        hasProgram ? program!.displayName.trim().toUpperCase() : 'MY PROGRAM';
    final int? currentWeek = program?.currentWeek;
    final int totalWeeks = program?.totalWeeks ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tappable title — opens the "My Program" detail sheet (current
            // split + weekly schedule + all edit-prefs + Edit + Browse-all).
            // This is a DIFFERENT destination from the PROGRAMS tile
            // (browse-all), so it no longer duplicates that link.
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticService.light();
                  showMyProgramSheet(context, ref);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        programLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ZType.disp(20, color: tc.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('›',
                        style: TextStyle(
                            color: tc.textMuted,
                            fontSize: 20,
                            height: 1.0,
                            fontWeight: FontWeight.w300)),
                  ],
                ),
              ),
            ),
            if (currentWeek != null && totalWeeks > 0) ...[
              const SizedBox(width: 10),
              Text(
                'WEEK $currentWeek OF $totalWeeks',
                style: ZType.lbl(11, color: tc.accent, letterSpacing: 1.6),
              ),
            ],
            const SizedBox(width: 12),
            // Edit affordance — opens the unified program editor for the
            // ACTIVE program (kept beside the program label it acts on).
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                HapticService.light();
                final changed = await showEditProgramSheet(context, ref);
                if (changed == true) {
                  ref.invalidate(activeUserProgramProvider);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 15, color: tc.textSecondary),
                  const SizedBox(width: 4),
                  Text('EDIT PROGRAM',
                      style: ZType.lbl(12,
                          color: tc.textSecondary, letterSpacing: 1.4)),
                ],
              ),
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
        // LIBRARY / BUILDER / PROGRAMS — promoted from weak left-aligned text
        // links to an evenly-distributed 3-up icon+label tile row so they read
        // as deliberate navigation, not a footer. PROGRAMS owns "browse all
        // programs" now that the title is a plain label.
        // Tour anchor: "Build & browse" step spotlights the whole 3-up row.
        KeyedSubtree(
          key: TooltipAnchors.workoutsPrograms,
          child: Row(
            children: [
              Expanded(
                child: _ProgramToolTile(
                  icon: Icons.calendar_month_rounded,
                  label: 'SCHEDULE',
                  onTap: () {
                    HapticService.light();
                    context.push('/schedule');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProgramToolTile(
                  icon: Icons.menu_book_rounded,
                  label: 'LIBRARY',
                  onTap: () {
                    HapticService.light();
                    context.push('/library');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProgramToolTile(
                  icon: Icons.handyman_rounded,
                  label: 'BUILDER',
                  onTap: () {
                    HapticService.light();
                    context.push('/workout/build');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProgramToolTile(
                  icon: Icons.list_alt_rounded,
                  label: 'PROGRAMS',
                  onTap: () {
                    HapticService.light();
                    context.push('/workout/program-library');
                  },
                ),
              ),
            ],
          ),
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

/// A single training-tool tile in the LIBRARY / BUILDER / PROGRAMS row —
/// icon over an uppercase label inside a hairline card. Designed to sit inside
/// an [Expanded] so the three tiles share the width evenly.
class _ProgramToolTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ProgramToolTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: tc.glassSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tc.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: tc.accent),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ZType.lbl(11, color: tc.textSecondary, letterSpacing: 1.2),
            ),
          ],
        ),
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
              style: ZType.ser(12.5, color: tc.textSecondary),
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
