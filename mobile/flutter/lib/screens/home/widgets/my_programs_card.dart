import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/models/user_program_assignment.dart';
import '../../../data/providers/program_assignments_provider.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/user_program_assignment_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/app_dialog.dart';
import '../../../widgets/design_system/section_header.dart';
import '../../../widgets/design_system/zealova_button.dart';
import '../../../widgets/glass_sheet.dart';

/// "My Programs" — lists the user's active program enrollments with progress,
/// the weekdays each occupies, and a primary/add-on badge. Tapping an item
/// opens a manage sheet (rename, change days, change slot, pause/resume, end).
///
/// Mounted on the home screen (and reusable on profile). Self-hides to zero
/// height while loading with no cached value AND when the user has no
/// assignments — except it always renders the empty-state card once loaded so
/// the user has a discovery path into the Program Library. Wired to
/// [programAssignmentsProvider] (cache-first + keepAlive); mutations refresh
/// both that provider and the today provider so the hero stays in lock-step.
class MyProgramsCard extends ConsumerWidget {
  /// When true, the section header is omitted (caller supplies its own, e.g.
  /// the profile TRAINING section). Defaults to showing the header.
  final bool showHeader;

  /// When true (home), the empty state is shown so new users discover the
  /// Program Library. When false, an empty list collapses to nothing (so it
  /// doesn't clutter a screen that already has many sections).
  final bool showEmptyState;

  const MyProgramsCard({
    super.key,
    this.showHeader = true,
    this.showEmptyState = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(programAssignmentsProvider);

    return async.when(
      // Cache-first keepAlive means a returning user paints instantly; a true
      // cold load shows nothing (no skeleton flash) — the hero carousel is the
      // primary surface, this is a secondary section.
      loading: () => const SizedBox.shrink(),
      error: (e, _) => _ErrorRow(
        onRetry: () => refreshProgramAssignmentsW(ref),
        showHeader: showHeader,
      ),
      data: (assignments) {
        final active =
            assignments.where((a) => a.status != 'completed').toList();
        if (active.isEmpty) {
          if (!showEmptyState) return const SizedBox.shrink();
          return _EmptyState(showHeader: showHeader);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showHeader) const SectionHeader(label: 'My Programs'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final a in active) ...[
                    _ProgramRow(assignment: a),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final VoidCallback onRetry;
  final bool showHeader;
  const _ErrorRow({required this.onRetry, required this.showHeader});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeader) const SectionHeader(label: 'My Programs'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tc.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tc.cardBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off_rounded, size: 18, color: tc.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Couldn't load your programs.",
                    style: TextStyle(fontSize: 13, color: tc.textSecondary),
                  ),
                ),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool showHeader;
  const _EmptyState({required this.showHeader});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeader) const SectionHeader(label: 'My Programs'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () {
              HapticService.light();
              context.push('/workout/program-library');
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tc.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tc.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tc.elevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: tc.cardBorder),
                    ),
                    child: Icon(Icons.library_books_outlined,
                        size: 20, color: tc.textMuted),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'No program yet',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: tc.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Browse the Library to follow a fixed plan.',
                          style:
                              TextStyle(fontSize: 12.5, color: tc.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 13, color: tc.textMuted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One enrolled program — title, "Week X of Y", % complete, the weekdays it
/// occupies, and a primary/add-on badge. Tap → manage sheet.
class _ProgramRow extends ConsumerWidget {
  final UserProgramAssignment assignment;
  const _ProgramRow({required this.assignment});

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final accent = tc.accent;
    final a = assignment;
    final paused = a.status == 'paused';
    final pct = (a.progressPercentage).clamp(0, 100);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticService.selection();
          showProgramManageSheet(context, ref, a);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tc.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tc.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      a.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: tc.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Badge(
                    label: a.isAddon ? 'ADD-ON' : 'PRIMARY',
                    color: a.isAddon ? tc.textMuted : accent,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    paused ? 'Paused · ${a.weekLabel}' : a.weekLabel,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: tc.textSecondary,
                    ),
                  ),
                  if (pct > 0) ...[
                    Text('  ·  ',
                        style: TextStyle(fontSize: 12.5, color: tc.textMuted)),
                    Text('$pct% complete',
                        style:
                            TextStyle(fontSize: 12.5, color: tc.textSecondary)),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              // % complete progress bar.
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 5,
                  backgroundColor: tc.elevated,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    paused ? tc.textMuted : accent,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Weekday dots the program occupies.
              Row(
                children: [
                  for (int i = 0; i < 7; i++) ...[
                    _DayDot(
                      letter: _dayLetters[i],
                      filled: a.coversWeekday(i),
                      accent: accent,
                    ),
                    if (i < 6) const SizedBox(width: 6),
                  ],
                  const Spacer(),
                  Icon(Icons.tune_rounded, size: 16, color: tc.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final String letter;
  final bool filled;
  final Color accent;
  const _DayDot(
      {required this.letter, required this.filled, required this.accent});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? accent : Colors.transparent,
        border: Border.all(
          color: filled ? accent : tc.cardBorder,
        ),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: filled ? tc.accentContrast : tc.textMuted,
        ),
      ),
    );
  }
}

// ============================================================================
// MANAGE SHEET
// ============================================================================

/// Open the manage sheet for an enrolled program: rename, change training days,
/// change slot (primary/add-on), pause/resume, end. All mutations go through
/// [UserProgramAssignmentRepository] and refresh the assignments + today
/// providers so the home hero stays in lock-step.
Future<void> showProgramManageSheet(
  BuildContext context,
  WidgetRef ref,
  UserProgramAssignment assignment,
) {
  return showGlassSheet<void>(
    context: context,
    builder: (_) => GlassSheet(
      child: _ManageSheetBody(assignment: assignment, parentRef: ref),
    ),
  );
}

class _ManageSheetBody extends ConsumerStatefulWidget {
  final UserProgramAssignment assignment;
  final WidgetRef parentRef;
  const _ManageSheetBody({required this.assignment, required this.parentRef});

  @override
  ConsumerState<_ManageSheetBody> createState() => _ManageSheetBodyState();
}

class _ManageSheetBodyState extends ConsumerState<_ManageSheetBody> {
  late final TextEditingController _nameController;
  late List<int> _days;
  late ProgramSlot _slot;
  late String _status;
  bool _busy = false;
  String? _error;

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final a = widget.assignment;
    _nameController = TextEditingController(text: a.title);
    _days = List<int>.from(a.assignedDays);
    _slot = a.slot;
    _status = a.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _dirty {
    final a = widget.assignment;
    final sortedNew = (List<int>.from(_days)..sort());
    final sortedOld = (List<int>.from(a.assignedDays)..sort());
    return _nameController.text.trim() != a.title ||
        _slot != a.slot ||
        sortedNew.join(',') != sortedOld.join(',');
  }

  /// Refresh both the assignments list and the today hero after any mutation.
  Future<void> _refreshAll() async {
    await refreshProgramAssignmentsW(widget.parentRef);
    // The schedule changed → suppress the provider's own param-less auto-gen
    // while the backend regenerates per-day program workouts, then refresh.
    TodayWorkoutNotifier.markExplicitProgramRegen();
    widget.parentRef
        .read(todayWorkoutProvider.notifier)
        .invalidateAndRefresh();
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_days.isEmpty) {
      setState(() => _error = 'Pick at least one training day.');
      return;
    }
    HapticService.medium();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(userProgramAssignmentRepositoryProvider);
      await repo.updateAssignment(
        widget.assignment.id,
        customProgramName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        assignedDays: _days,
        slot: _slot,
      );
      await _refreshAll();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not save changes. Please try again.';
        });
      }
    }
  }

  Future<void> _togglePauseResume() async {
    if (_busy) return;
    final pausing = _status == 'active';
    HapticService.medium();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(userProgramAssignmentRepositoryProvider);
      await repo.updateAssignment(
        widget.assignment.id,
        status: pausing ? 'paused' : 'active',
      );
      await _refreshAll();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not ${pausing ? 'pause' : 'resume'} the program.';
        });
      }
    }
  }

  Future<void> _end() async {
    if (_busy) return;
    final confirm = await AppDialog.destructive(
      context,
      title: 'End program?',
      message:
          'This stops scheduling new workouts from "${widget.assignment.title}". '
          'Completed workouts are kept.',
      confirmText: 'End',
      icon: Icons.stop_circle_outlined,
    );
    if (confirm != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(userProgramAssignmentRepositoryProvider);
      await repo.deleteAssignment(widget.assignment.id);
      await _refreshAll();
      // Also refresh the all-workouts list so ended-program days drop.
      widget.parentRef.read(workoutsProvider.notifier).silentRefresh();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not end the program. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final accent = tc.accent;
    final paused = _status == 'paused';

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
            Text(
              'Manage program',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: tc.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Rename
            Text('NAME',
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: tc.textMuted)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [LengthLimitingTextInputFormatter(60)],
              style: TextStyle(color: tc.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: tc.elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: tc.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: tc.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accent),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),

            // Training days
            Text('TRAINING DAYS',
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: tc.textMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < 7; i++)
                  _DayToggle(
                    label: _dayLabels[i],
                    selected: _days.contains(i),
                    accent: accent,
                    onTap: () {
                      HapticService.selection();
                      setState(() {
                        if (_days.contains(i)) {
                          _days.remove(i);
                        } else {
                          _days.add(i);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // Slot
            Text('SLOT',
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: tc.textMuted)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SlotChip(
                    label: 'Primary',
                    sub: 'The day\'s main plan',
                    selected: _slot == ProgramSlot.primary,
                    accent: accent,
                    onTap: () =>
                        setState(() => _slot = ProgramSlot.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SlotChip(
                    label: 'Add-on',
                    sub: 'Stacks on top',
                    selected: _slot == ProgramSlot.addon,
                    accent: accent,
                    onTap: () => setState(() => _slot = ProgramSlot.addon),
                  ),
                ),
              ],
            ),

            if (widget.assignment.templateId != null) ...[
              const SizedBox(height: 18),
              _SheetActionRow(
                icon: Icons.edit_note_rounded,
                label: 'Edit program plan',
                onTap: _busy
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        // Open the builder for this assignment's template.
                        context.push('/workout/program-builder');
                      },
              ),
            ],

            const SizedBox(height: 8),
            _SheetActionRow(
              icon: paused
                  ? Icons.play_circle_outline
                  : Icons.pause_circle_outline,
              label: paused ? 'Resume program' : 'Pause program',
              onTap: _busy ? null : _togglePauseResume,
            ),
            _SheetActionRow(
              icon: Icons.stop_circle_outlined,
              label: 'End program',
              destructive: true,
              onTap: _busy ? null : _end,
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error)),
            ],

            const SizedBox(height: 16),
            ZealovaButton(
              label: _busy ? 'Saving…' : 'Save changes',
              onTap: (_busy || !_dirty) ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _DayToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _DayToggle({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.14) : tc.elevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? accent : tc.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? tc.textPrimary : tc.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final String label;
  final String sub;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  const _SlotChip({
    required this.label,
    required this.sub,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.14) : tc.elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? accent : tc.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 16,
                  color: selected ? accent : tc.textMuted,
                ),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: tc.textPrimary)),
              ],
            ),
            const SizedBox(height: 2),
            Text(sub,
                style: TextStyle(fontSize: 11.5, color: tc.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _SheetActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;
  const _SheetActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final color = destructive
        ? Theme.of(context).colorScheme.error
        : tc.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
