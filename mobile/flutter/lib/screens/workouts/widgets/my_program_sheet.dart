import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/training_preferences_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/user.dart';
import '../../../data/models/user_program_assignment.dart';
import '../../../data/providers/branded_program_provider.dart';
import '../../../data/providers/program_assignments_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../home/widgets/components/training_program_selector.dart'
    show defaultTrainingPrograms;
import '../../home/widgets/edit_program_sheet.dart';
import '../../workout/widgets/per_day_focus_chips.dart' show kFocusOptions;

/// Opens the "My Program" detail sheet — the user's CURRENT program in one
/// place: the AI-chosen training split, the weekly schedule (per-day focus),
/// and the edit-preferences (session length, intensity, equipment, injuries),
/// with Edit + Browse-all actions.
///
/// Sourced primarily from [ProgramPreferences] + the user's per-day overrides,
/// because for most users the program IS their preference set (the AI-decided
/// split), not a branded [UserProgram]. The branded program — when present —
/// only enriches the header (name + week/progress).
Future<void> showMyProgramSheet(BuildContext context, WidgetRef ref) {
  return showGlassSheet<void>(
    context: context,
    builder: (_) => const GlassSheet(child: _MyProgramSheet()),
  );
}

class _MyProgramSheet extends ConsumerStatefulWidget {
  const _MyProgramSheet();

  @override
  ConsumerState<_MyProgramSheet> createState() => _MyProgramSheetState();
}

class _MyProgramSheetState extends ConsumerState<_MyProgramSheet> {
  ProgramPreferences? _prefs;
  bool _loading = true;

  static const List<String> _dayNames = [
    'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final prefs = await ref.read(workoutRepositoryProvider).getProgramPreferences(userId);
      if (mounted) {
        setState(() {
          _prefs = prefs;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── label helpers ──────────────────────────────────────────────────────────

  String _cap(String? s) {
    if (s == null || s.isEmpty) return '—';
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Human label for a training-split id (e.g. 'push_pull_legs' → 'Push/Pull/Legs').
  String _splitLabel(String? id) {
    if (id == null || id.isEmpty) return '—';
    for (final p in defaultTrainingPrograms) {
      if (p.id == id) return p.name;
    }
    // Fallback: prettify the raw id.
    return id
        .split('_')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  ({String label, IconData icon}) _focus(String? value) {
    for (final f in kFocusOptions) {
      if (f.value == value) return (label: f.label, icon: f.icon);
    }
    return (label: 'AI decides', icon: Icons.auto_awesome_rounded);
  }

  // ── build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final program = ref.watch(activeUserProgramProvider);
    final user = ref.watch(authStateProvider).user;
    final style = ref.watch(trainingPreferencesProvider).workoutType.value;

    final prefs = _prefs;
    final splitId = prefs?.trainingSplit;
    final title = (program?.displayName.trim().isNotEmpty == true)
        ? program!.displayName.trim()
        : (splitId != null && splitId.isNotEmpty
            ? '${_splitLabel(splitId)} Program'
            : 'Your Program');

    final currentWeek = program?.currentWeek;
    final totalWeeks = program?.totalWeeks ?? 0;

    // Which weekdays are training days (0=Mon..6=Sun) + their focus overrides.
    final workoutDays = (user?.workoutDays ?? const <int>[]).toSet();
    final overrides = user?.workoutDayOverrides ?? const <int, WorkoutDayOverride>{};

    // Active CURATED program assignments (primary + add-ons). When present, the
    // weekly schedule below reflects the program's REAL training days — not just
    // the AI-preference days — so a started program (e.g. HYROX on Wed–Sun) no
    // longer shows the stale AI Fri/Sat grid. AI-preference days that no program
    // covers still render (the merged-calendar reality).
    // /assignments also returns paused/completed rows — the weekly grid should
    // only reflect programs that are actively running right now.
    final assignments = (ref.watch(programAssignmentsProvider).valueOrNull ??
            const <UserProgramAssignment>[])
        .where((a) => a.isActive && a.status == 'active')
        .toList();
    final hasCurated = assignments.isNotEmpty;

    // Union of every training day across curated assignments + AI prefs.
    final trainingDays = <int>{...workoutDays};
    for (final a in assignments) {
      trainingDays.addAll(a.assignedDays);
    }

    final daysPerWeek = hasCurated
        ? trainingDays.length
        : (workoutDays.isNotEmpty
            ? workoutDays.length
            : (prefs?.workoutDays.length ?? 0));
    final sessionMin = prefs?.durationMinutes;
    final level = prefs?.difficulty ?? user?.fitnessLevel;
    final focusAreas = prefs?.focusAreas ?? const <String>[];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Text('MY PROGRAM',
                style: ZType.lbl(11, color: tc.textMuted, letterSpacing: 2)),
            const SizedBox(height: 6),
            Text(title,
                style: ZType.disp(26, color: tc.textPrimary)),
            if (currentWeek != null && totalWeeks > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('WEEK $currentWeek OF $totalWeeks',
                      style: ZType.lbl(11, color: tc.accent, letterSpacing: 1.6)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (currentWeek / totalWeeks).clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: tc.cardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(tc.accent),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Overview grid ──
            _sectionLabel(tc, 'OVERVIEW'),
            const SizedBox(height: 10),
            if (_loading)
              _loadingRow(tc)
            else
              Column(
                children: [
                  Row(children: [
                    Expanded(child: _MetaCell(tc, 'SPLIT', _splitLabel(splitId))),
                    const SizedBox(width: 10),
                    Expanded(child: _MetaCell(tc, 'DAYS / WK',
                        daysPerWeek > 0 ? '$daysPerWeek' : '—')),
                    const SizedBox(width: 10),
                    Expanded(child: _MetaCell(tc, 'SESSION',
                        sessionMin != null ? '$sessionMin min' : '—')),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _MetaCell(tc, 'STYLE', _cap(style))),
                    const SizedBox(width: 10),
                    Expanded(child: _MetaCell(tc, 'LEVEL', _cap(level))),
                    const SizedBox(width: 10),
                    Expanded(child: _MetaCell(tc, 'FOCUS',
                        focusAreas.isNotEmpty ? focusAreas.first : '—')),
                  ]),
                ],
              ),

            const SizedBox(height: 22),

            // ── Weekly schedule ──
            _sectionLabel(tc, 'WEEKLY SCHEDULE'),
            const SizedBox(height: 8),
            for (var d = 0; d < 7; d++)
              _dayRow(
                tc,
                d,
                workoutDays.contains(d),
                overrides[d],
                sessionMin,
                _curatedForDay(assignments, d),
              ),

            // ── Equipment ──
            if (!_loading && (prefs?.equipment.isNotEmpty ?? false)) ...[
              const SizedBox(height: 22),
              _sectionLabel(tc, 'EQUIPMENT'),
              const SizedBox(height: 10),
              _chipWrap(tc, prefs!.equipment.map(_prettyToken).toList()),
            ],

            // ── Injuries / training-around ──
            if (!_loading && (prefs?.injuries.isNotEmpty ?? false)) ...[
              const SizedBox(height: 22),
              _sectionLabel(tc, 'TRAINING AROUND'),
              const SizedBox(height: 10),
              _chipWrap(tc, prefs!.injuries.map(_prettyToken).toList(),
                  warn: true),
            ],

            const SizedBox(height: 26),

            // ── Actions ──
            _primaryButton(tc, 'EDIT PROGRAM', Icons.tune_rounded, () async {
              HapticService.light();
              Navigator.of(context).pop();
              final changed = await showEditProgramSheet(context, ref);
              if (changed == true) ref.invalidate(activeUserProgramProvider);
            }),
            const SizedBox(height: 10),
            _ghostButton(tc, 'VIEW ALL PROGRAMS', () {
              HapticService.light();
              Navigator.of(context).pop();
              context.push('/workout/program-library');
            }),
          ],
        ),
      ),
    );
  }

  // ── sub-widgets ──────────────────────────────────────────────────────────

  Widget _sectionLabel(ThemeColors tc, String text) => Text(text,
      style: ZType.lbl(10.5, color: tc.textMuted, letterSpacing: 2));

  Widget _loadingRow(ThemeColors tc) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(tc.accent)),
          ),
        ),
      );

  /// The curated label for [day] (0=Mon..6=Sun), or null if no active program
  /// covers it. Primary program drives the label; add-ons append "+N". Returns
  /// the busiest match so a covered day is never shown as an AI/rest day.
  ({String label, String? sub})? _curatedForDay(
      List<UserProgramAssignment> assignments, int day) {
    if (assignments.isEmpty) return null;
    String? primaryName;
    final addonNames = <String>[];
    for (final a in assignments) {
      if (!a.coversWeekday(day)) continue;
      final name = (a.displayName?.trim().isNotEmpty == true)
          ? a.displayName!.trim()
          : 'Program';
      if (a.isPrimary) {
        primaryName ??= name;
      } else {
        addonNames.add(name);
      }
    }
    final label = primaryName ?? (addonNames.isNotEmpty ? addonNames.first : null);
    if (label == null) return null;
    // If primary + add-on(s) stack, or multiple add-ons, surface the extra count.
    final extras = primaryName != null
        ? addonNames.length
        : (addonNames.length - 1);
    return (label: label, sub: extras > 0 ? '+$extras' : null);
  }

  Widget _dayRow(ThemeColors tc, int day, bool isWorkout,
      WorkoutDayOverride? override, int? sessionMin,
      [({String label, String? sub})? curated]) {
    // A curated program covering this day always wins over the AI-preference
    // view — show the program name, not "Rest day" or an AI focus.
    if (curated != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(_dayNames[day],
                  style: ZType.lbl(11,
                      color: tc.textSecondary, letterSpacing: 1.2)),
            ),
            const SizedBox(width: 8),
            Icon(Icons.fitness_center_rounded, size: 16, color: tc.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                curated.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ZType.sans(14,
                    color: tc.textPrimary, weight: FontWeight.w600),
              ),
            ),
            if (curated.sub != null)
              Text(curated.sub!, style: ZType.data(11, color: tc.accent)),
          ],
        ),
      );
    }

    final isRest = !isWorkout;
    final focus = isWorkout ? _focus(override?.focus) : null;
    final dur = override?.durationMin ?? (isWorkout ? sessionMin : null);
    final intensity = override?.intensity;
    final sub = <String>[
      if (dur != null) '${dur}m',
      if (intensity != null) _cap(intensity),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(_dayNames[day],
                style: ZType.lbl(11,
                    color: isRest ? tc.textMuted : tc.textSecondary,
                    letterSpacing: 1.2)),
          ),
          const SizedBox(width: 8),
          Icon(
            isRest ? Icons.nightlight_round : focus!.icon,
            size: 16,
            color: isRest ? tc.textMuted.withValues(alpha: 0.5) : tc.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isRest ? 'Rest day' : focus!.label,
              style: ZType.sans(14,
                  color: isRest ? tc.textMuted : tc.textPrimary,
                  weight: FontWeight.w600),
            ),
          ),
          if (!isRest && sub.isNotEmpty)
            Text(sub, style: ZType.data(11, color: tc.textMuted)),
        ],
      ),
    );
  }

  String _prettyToken(String t) => t
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');

  Widget _chipWrap(ThemeColors tc, List<String> items, {bool warn = false}) {
    final color = warn ? Colors.orange : tc.accent;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final it in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.30)),
            ),
            child: Text(it,
                style: ZType.lbl(11, color: color, letterSpacing: 0.6)),
          ),
      ],
    );
  }

  Widget _primaryButton(
      ThemeColors tc, String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tc.accent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: tc.accentContrast),
            const SizedBox(width: 8),
            Text(label,
                style: ZType.lbl(13,
                    color: tc.accentContrast, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _ghostButton(ThemeColors tc, String label, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tc.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: ZType.lbl(12,
                    color: tc.textSecondary, letterSpacing: 1.5)),
            const SizedBox(width: 4),
            Text('›',
                style: TextStyle(
                    color: tc.textMuted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// A single labelled value cell in the overview grid (label over value, inside
/// a hairline card). Designed for an [Expanded] so cells share width evenly.
class _MetaCell extends StatelessWidget {
  final ThemeColors tc;
  final String label;
  final String value;
  const _MetaCell(this.tc, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: tc.glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tc.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ZType.lbl(9.5, color: tc.textMuted, letterSpacing: 1)),
          const SizedBox(height: 5),
          Text(value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ZType.sans(14,
                  color: tc.textPrimary, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}
