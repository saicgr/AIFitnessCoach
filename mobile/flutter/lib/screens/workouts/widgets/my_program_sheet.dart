import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/training_preferences_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/user_program_assignment.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/workout_program_context.dart';
import '../../../data/providers/branded_program_provider.dart';
import '../../../data/providers/program_assignments_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../home/widgets/components/training_program_selector.dart'
    show defaultTrainingPrograms;
import '../../home/widgets/edit_program_sheet.dart';
import '../../schedule/widgets/program_color.dart';
import '../../workout/widgets/program_manage_sheet.dart';

/// Opens the "My Program" detail sheet — the user's CURRENT programs in one
/// place: every active program stacked (curated assignments + the always-on AI
/// base), the weekly schedule (mirrored from the REAL scheduled workouts), and
/// the AI edit-preferences (split, session length, equipment, injuries), with
/// Edit + Browse-all actions.
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
  bool _equipExpanded = false;

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
    // "Let the coach choose" sentinels read as AI Decides, not a prettified id.
    const aiSentinels = {'ai_decide', 'ai decide', 'dont_know', 'nothing_structured'};
    if (aiSentinels.contains(id.toLowerCase())) return 'AI Decides';
    for (final p in defaultTrainingPrograms) {
      if (p.id == id) return p.name;
    }
    // Fallback: prettify the raw id ("ai" → "AI", never "Ai").
    return id.split('_').map(_word).join(' ');
  }

  /// Title-case a token, but keep "AI" all-caps (never "Ai").
  String _word(String w) {
    if (w.isEmpty) return w;
    if (w.toLowerCase() == 'ai') return 'AI';
    return w[0].toUpperCase() + w.substring(1);
  }

  String _prettyToken(String t) =>
      t.replaceAll('_', ' ').split(' ').map(_word).join(' ');

  // ── build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final user = ref.watch(authStateProvider).user;
    final style = ref.watch(trainingPreferencesProvider).workoutType.value;

    final prefs = _prefs;
    final splitId = prefs?.trainingSplit;

    // Active CURATED program assignments (primary + add-ons), running right now.
    final assignments = (ref.watch(programAssignmentsProvider).valueOrNull ??
            const <UserProgramAssignment>[])
        .where((a) => a.isActive && a.status == 'active')
        .toList()
      ..sort((a, b) => a.isPrimary == b.isPrimary ? 0 : (a.isPrimary ? -1 : 1));

    // AI overview is sourced from the user's preferences (the AI base program).
    final workoutDays = (user?.workoutDays ?? const <int>[]).toSet();
    final daysPerWeek = workoutDays.isNotEmpty
        ? workoutDays.length
        : (prefs?.workoutDays.length ?? 0);
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
            const SizedBox(height: 12),

            // ── Active programs (curated stacked over the AI base) ──
            for (final a in assignments) ...[
              _ProgramRowTile(
                tc: tc,
                title: a.title,
                subtitle: '${a.weekLabel} · ${a.isAddon ? 'Extra' : 'Primary'}',
                color: ProgramColors.forKey(a.id),
                initial: a.title.isNotEmpty ? a.title[0].toUpperCase() : '•',
                onTap: () async {
                  HapticService.light();
                  await showProgramManageSheet(context, ref, a);
                },
              ),
              const SizedBox(height: 9),
            ],
            _AiBaseRowTile(
              tc: tc,
              onTap: () async {
                HapticService.light();
                Navigator.of(context).pop();
                final changed = await showEditProgramSheet(context, ref);
                if (changed == true) ref.invalidate(activeUserProgramProvider);
              },
            ),

            const SizedBox(height: 20),

            // ── Overview grid (the AI base program) ──
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

            // ── Weekly schedule (mirrors the real /schedule) ──
            _sectionLabel(tc, 'WEEKLY SCHEDULE'),
            const SizedBox(height: 8),
            _weeklySchedule(tc, assignments),

            // ── Equipment (collapsed summary + expand) ──
            if (!_loading && (prefs?.equipment.isNotEmpty ?? false)) ...[
              const SizedBox(height: 22),
              _sectionLabel(tc, 'EQUIPMENT'),
              const SizedBox(height: 10),
              _equipmentBlock(tc, prefs!.equipment),
            ],

            // ── Injuries / training-around ──
            if (!_loading && (prefs?.injuries.isNotEmpty ?? false)) ...[
              const SizedBox(height: 22),
              _sectionLabel(tc, 'TRAINING AROUND'),
              const SizedBox(height: 10),
              _chipWrap(tc, _dedup(prefs!.injuries.map(_prettyToken)),
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

  // ── weekly schedule ────────────────────────────────────────────────────────

  /// Builds the 7-day grid from the REAL scheduled workouts for the current
  /// Mon–Sun week, so it always matches the Schedule screen day-for-day.
  Widget _weeklySchedule(
      ThemeColors tc, List<UserProgramAssignment> assignments) {
    final workoutsAsync = ref.watch(workoutsProvider);
    final workouts = workoutsAsync.valueOrNull;
    if (workouts == null) return _loadingRow(tc);

    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: (now.weekday - 1) % 7));

    return Column(
      children: [
        for (var d = 0; d < 7; d++)
          _dayRow(tc, d, _dayInfo(workouts, assignments, monday, d)),
      ],
    );
  }

  /// Resolve what runs on weekday [d] (0=Mon..6=Sun) from the real workouts.
  ({String label, String? sub, bool rest}) _dayInfo(
    List<Workout> workouts,
    List<UserProgramAssignment> assignments,
    DateTime monday,
    int d,
  ) {
    final date = monday.add(Duration(days: d));
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final dayWorkouts =
        workouts.where((w) => w.scheduledDateKey == dateStr).toList();
    if (dayWorkouts.isEmpty) return (label: 'Rest day', sub: null, rest: true);

    // Primary (non-add-on) workout drives the label; add-ons surface as "+N".
    final primary = dayWorkouts.firstWhere(
      (w) => !(w.programContext?.isAddon ?? false),
      orElse: () => dayWorkouts.first,
    );
    final ctx = primary.programContext;
    final assignment = assignmentForWeekday(assignments, d);
    final name = _programNameFor(ctx, assignment) ??
        (primary.type?.trim().isNotEmpty == true
            ? _cap(primary.type!.trim())
            : 'Workout');
    final extra = dayWorkouts.length - 1;
    return (label: name, sub: extra > 0 ? '+$extra' : null, rest: false);
  }

  /// Curated-program name for a session, preferring the workout's own context,
  /// then the matched assignment. Null for a pure AI workout.
  String? _programNameFor(
      WorkoutProgramContext? ctx, UserProgramAssignment? assignment) {
    final fromCtx = ctx?.programName?.trim();
    if (fromCtx != null && fromCtx.isNotEmpty) return fromCtx;
    final custom = assignment?.customProgramName?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    final display = assignment?.displayName?.trim();
    if (display != null && display.isNotEmpty) return display;
    return null;
  }

  Widget _dayRow(
      ThemeColors tc, int day, ({String label, String? sub, bool rest}) info) {
    final isRest = info.rest;
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
            isRest ? Icons.nightlight_round : Icons.fitness_center_rounded,
            size: 16,
            color: isRest ? tc.textMuted.withValues(alpha: 0.5) : tc.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              info.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ZType.sans(14,
                  color: isRest ? tc.textMuted : tc.textPrimary,
                  weight: FontWeight.w600),
            ),
          ),
          if (info.sub != null)
            Text(info.sub!, style: ZType.data(11, color: tc.accent)),
        ],
      ),
    );
  }

  // ── equipment ────────────────────────────────────────────────────────────

  /// De-duplicate by case-insensitive label, preserving first-seen order.
  List<String> _dedup(Iterable<String> items) {
    final seen = <String>{};
    final out = <String>[];
    for (final it in items) {
      final k = it.toLowerCase();
      if (seen.add(k)) out.add(it);
    }
    return out;
  }

  /// Collapsed one-line summary that expands to the full (deduped) chip list.
  Widget _equipmentBlock(ThemeColors tc, List<String> raw) {
    final items = _dedup(raw.map(_prettyToken));
    final hasFullGym =
        raw.any((t) => t.toLowerCase().replaceAll(' ', '_') == 'full_gym');
    final summary = hasFullGym
        ? 'Full Gym · ${items.length} items'
        : '${items.length} item${items.length == 1 ? '' : 's'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticService.light();
            setState(() => _equipExpanded = !_equipExpanded);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: tc.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tc.accent.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.fitness_center_rounded, size: 16, color: tc.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(summary,
                      style: ZType.sans(13.5,
                          color: tc.textPrimary, weight: FontWeight.w600)),
                ),
                Icon(
                  _equipExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: tc.textMuted,
                ),
              ],
            ),
          ),
        ),
        if (_equipExpanded) ...[
          const SizedBox(height: 10),
          _chipWrap(tc, items),
        ],
      ],
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

/// A tappable program row in the stacked "active programs" list (curated).
class _ProgramRowTile extends StatelessWidget {
  final ThemeColors tc;
  final String title;
  final String subtitle;
  final Color color;
  final String initial;
  final VoidCallback onTap;
  const _ProgramRowTile({
    required this.tc,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.initial,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: tc.glassSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tc.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(initial,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ZType.sans(14,
                            color: tc.textPrimary, weight: FontWeight.w700)),
                    const SizedBox(height: 1),
                    Text(subtitle,
                        style: ZType.sans(11.5, color: tc.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.tune_rounded, size: 17, color: tc.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// The always-on AI base row beneath the curated programs.
class _AiBaseRowTile extends StatelessWidget {
  final ThemeColors tc;
  final VoidCallback onTap;
  const _AiBaseRowTile({required this.tc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const cyan = ProgramColors.ai;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: cyan.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cyan.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cyan.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, size: 17, color: cyan),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Program',
                        style: ZType.sans(14,
                            color: tc.textPrimary, weight: FontWeight.w700)),
                    const SizedBox(height: 1),
                    Text('Always on · fills uncovered training days',
                        style: ZType.sans(11.5, color: tc.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.lock_outline, size: 14, color: cyan),
            ],
          ),
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
