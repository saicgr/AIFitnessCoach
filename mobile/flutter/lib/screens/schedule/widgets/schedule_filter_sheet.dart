import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/user_program_assignment.dart';
import '../../../data/models/workout.dart';
import '../../../data/models/workout_program_context.dart';
import '../../../widgets/glass_sheet.dart';
import 'program_color.dart';

/// Token for "the always-on AI program" inside the program filter (workouts
/// with no program assignment tag).
const String kAiProgramFilterToken = '__ai__';

/// Coarse workout-type buckets the schedule can filter by. Derived from the
/// workout's free-form `type` field (server-tagged), classified by
/// [scheduleTypeFor].
enum ScheduleWorkoutType { strength, cardio, mobility, hiit, core, recovery }

extension ScheduleWorkoutTypeX on ScheduleWorkoutType {
  String get label {
    switch (this) {
      case ScheduleWorkoutType.strength:
        return 'Strength';
      case ScheduleWorkoutType.cardio:
        return 'Cardio';
      case ScheduleWorkoutType.mobility:
        return 'Mobility';
      case ScheduleWorkoutType.hiit:
        return 'HIIT';
      case ScheduleWorkoutType.core:
        return 'Core';
      case ScheduleWorkoutType.recovery:
        return 'Recovery';
    }
  }

  String get emoji {
    switch (this) {
      case ScheduleWorkoutType.strength:
        return '🏋';
      case ScheduleWorkoutType.cardio:
        return '🏃';
      case ScheduleWorkoutType.mobility:
        return '🧘';
      case ScheduleWorkoutType.hiit:
        return '🔥';
      case ScheduleWorkoutType.core:
        return '💪';
      case ScheduleWorkoutType.recovery:
        return '🤸';
    }
  }
}

/// Classify a workout's free-form `type` into a [ScheduleWorkoutType] bucket.
/// Defaults to strength when unknown (the most common case).
ScheduleWorkoutType scheduleTypeFor(Workout w) {
  final t = (w.type ?? '').toLowerCase();
  if (t.contains('cardio') || t.contains('run') || t.contains('endurance')) {
    return ScheduleWorkoutType.cardio;
  }
  if (t.contains('hiit') || t.contains('interval') || t.contains('metcon')) {
    return ScheduleWorkoutType.hiit;
  }
  if (t.contains('mobility') ||
      t.contains('flex') ||
      t.contains('yoga') ||
      t.contains('stretch')) {
    return ScheduleWorkoutType.mobility;
  }
  if (t.contains('core') || t.contains('abs')) {
    return ScheduleWorkoutType.core;
  }
  if (t.contains('recovery') || t.contains('rest') || t.contains('rehab')) {
    return ScheduleWorkoutType.recovery;
  }
  return ScheduleWorkoutType.strength;
}

/// The program key a workout belongs to for filtering: its assignment id, or
/// [kAiProgramFilterToken] when it carries no program tag (AI / ad-hoc).
String scheduleProgramKeyFor(Workout w) {
  final id = w.programContext?.assignmentId;
  if (id != null && id.isNotEmpty) return id;
  return kAiProgramFilterToken;
}

/// Immutable filter state held by the schedule screen. Empty sets mean "show
/// everything" (the default). A workout renders only when it passes BOTH the
/// program filter and the type filter.
class ScheduleFilter {
  /// Selected program keys (assignment ids + [kAiProgramFilterToken]). Empty =
  /// all programs.
  final Set<String> programs;

  /// Selected type buckets. Empty = all types.
  final Set<ScheduleWorkoutType> types;

  const ScheduleFilter({this.programs = const {}, this.types = const {}});

  bool get isActive => programs.isNotEmpty || types.isNotEmpty;

  /// Does [w] pass the current filter?
  bool allows(Workout w) {
    if (programs.isNotEmpty && !programs.contains(scheduleProgramKeyFor(w))) {
      return false;
    }
    if (types.isNotEmpty && !types.contains(scheduleTypeFor(w))) {
      return false;
    }
    return true;
  }

  ScheduleFilter copyWith({
    Set<String>? programs,
    Set<ScheduleWorkoutType>? types,
  }) => ScheduleFilter(
    programs: programs ?? this.programs,
    types: types ?? this.types,
  );

  ScheduleFilter toggleType(ScheduleWorkoutType t) {
    final next = Set<ScheduleWorkoutType>.from(types);
    next.contains(t) ? next.remove(t) : next.add(t);
    return copyWith(types: next);
  }

  static const ScheduleFilter none = ScheduleFilter();
}

// ─────────────────────────────────────────────────────────────────
// Filter bar (on the agenda) — quick type chips + "Filter" launcher.
// ─────────────────────────────────────────────────────────────────

class ScheduleFilterBar extends StatelessWidget {
  final ScheduleFilter filter;
  final ThemeColors colors;
  final VoidCallback onOpenSheet;
  final ValueChanged<ScheduleWorkoutType> onToggleType;
  final VoidCallback onClear;

  const ScheduleFilterBar({
    super.key,
    required this.filter,
    required this.colors,
    required this.onOpenSheet,
    required this.onToggleType,
    required this.onClear,
  });

  static const _quickTypes = [
    ScheduleWorkoutType.strength,
    ScheduleWorkoutType.cardio,
    ScheduleWorkoutType.mobility,
    ScheduleWorkoutType.hiit,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(
            label: 'Filter',
            leadingIcon: Icons.tune,
            selected: false,
            lead: true,
            onTap: onOpenSheet,
          ),
          const SizedBox(width: 8),
          _chip(label: 'All', selected: !filter.isActive, onTap: onClear),
          for (final t in _quickTypes) ...[
            const SizedBox(width: 8),
            _chip(
              label: '${t.emoji} ${t.label}',
              selected: filter.types.contains(t),
              onTap: () => onToggleType(t),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? leadingIcon,
    bool lead = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? colors.accent.withValues(alpha: 0.16)
              : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colors.accent : colors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: 14,
                color: lead ? colors.textPrimary : colors.textSecondary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? colors.textPrimary
                    : (lead ? colors.textPrimary : colors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Filter sheet (screen H) — multi-select by program + by type.
// ─────────────────────────────────────────────────────────────────

/// Open the multi-select filter sheet. Returns the chosen [ScheduleFilter], or
/// null when dismissed without applying.
Future<ScheduleFilter?> showScheduleFilterSheet({
  required BuildContext context,
  required ScheduleFilter current,
  required List<UserProgramAssignment> assignments,
  required Set<ScheduleWorkoutType> availableTypes,
}) {
  return showGlassSheet<ScheduleFilter>(
    context: context,
    builder: (_) => GlassSheet(
      child: _FilterSheetBody(
        initial: current,
        assignments: assignments,
        availableTypes: availableTypes,
      ),
    ),
  );
}

class _FilterSheetBody extends StatefulWidget {
  final ScheduleFilter initial;
  final List<UserProgramAssignment> assignments;
  final Set<ScheduleWorkoutType> availableTypes;

  const _FilterSheetBody({
    required this.initial,
    required this.assignments,
    required this.availableTypes,
  });

  @override
  State<_FilterSheetBody> createState() => _FilterSheetBodyState();
}

class _FilterSheetBodyState extends State<_FilterSheetBody> {
  late Set<String> _programs;
  late Set<ScheduleWorkoutType> _types;

  @override
  void initState() {
    super.initState();
    _programs = Set<String>.from(widget.initial.programs);
    _types = Set<ScheduleWorkoutType>.from(widget.initial.types);
  }

  void _toggleProgram(String key) {
    setState(() {
      _programs.contains(key) ? _programs.remove(key) : _programs.add(key);
    });
  }

  void _toggleType(ScheduleWorkoutType t) {
    setState(() {
      _types.contains(t) ? _types.remove(t) : _types.add(t);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final types = (widget.availableTypes.toList()
      ..sort((a, b) => a.index.compareTo(b.index)));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GlassSheetHandle(
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tc.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.tune, color: tc.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter schedule',
                        style: ZType.disp(22, color: tc.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Show only what you want on the calendar.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: tc.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // By program
            _groupLabel('By program', tc),
            const SizedBox(height: 10),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                for (final a in widget.assignments)
                  _ProgramOption(
                    label: a.title,
                    dotColor: ProgramColors.forKey(a.id),
                    selected: _programs.contains(a.id),
                    onTap: () => _toggleProgram(a.id),
                  ),
                _ProgramOption(
                  label: 'AI program',
                  dotColor: ProgramColors.ai,
                  selected: _programs.contains(kAiProgramFilterToken),
                  onTap: () => _toggleProgram(kAiProgramFilterToken),
                ),
              ],
            ),

            if (types.isNotEmpty) ...[
              const SizedBox(height: 22),
              _groupLabel('By type', tc),
              const SizedBox(height: 10),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (final t in types)
                    _ProgramOption(
                      label: '${t.emoji} ${t.label}',
                      selected: _types.contains(t),
                      onTap: () => _toggleType(t),
                    ),
                ],
              ),
            ],

            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(ScheduleFilter.none),
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tc.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: tc.cardBorder),
                      ),
                      child: Text(
                        'Clear all',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: tc.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 6,
                  child: GestureDetector(
                    onTap: () => Navigator.of(
                      context,
                    ).pop(ScheduleFilter(programs: _programs, types: _types)),
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tc.accent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: tc.accentContrast,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupLabel(String text, ThemeColors tc) => Text(
    text.toUpperCase(),
    style: ZType.lbl(11, color: tc.textMuted, letterSpacing: 1.4),
  );
}

class _ProgramOption extends StatelessWidget {
  final String label;
  final Color? dotColor;
  final bool selected;
  final VoidCallback onTap;

  const _ProgramOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? tc.accent.withValues(alpha: 0.14) : tc.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: selected ? tc.accent : tc.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: selected ? tc.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: selected ? tc.accent : tc.textMuted,
                  width: 2,
                ),
              ),
              child: selected
                  ? Icon(Icons.check, size: 10, color: tc.accentContrast)
                  : null,
            ),
            const SizedBox(width: 8),
            if (dotColor != null) ...[
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? tc.textPrimary : tc.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
