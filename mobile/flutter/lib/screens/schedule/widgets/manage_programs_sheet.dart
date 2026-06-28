import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/user_program_assignment.dart';
import '../../../data/providers/program_assignments_provider.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/user_program_assignment_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/app_dialog.dart';
import '../../../widgets/glass_sheet.dart';
import '../../workout/widgets/program_manage_sheet.dart';
import 'program_color.dart';

/// Open the "Your Programs" management sheet (screen E of the v9 mockup):
/// list every active program with its color + "Week X of Y" + slot, a ✕ to
/// remove each, a non-removable AI-program base row, and "＋ Add a program" →
/// the Program Library. Tapping a row opens the full per-program manage sheet.
Future<void> showManageProgramsSheet(BuildContext context, WidgetRef ref) {
  return showGlassSheet<void>(
    context: context,
    builder: (_) => const GlassSheet(child: _ManageProgramsBody()),
  );
}

class _ManageProgramsBody extends ConsumerStatefulWidget {
  const _ManageProgramsBody();

  @override
  ConsumerState<_ManageProgramsBody> createState() =>
      _ManageProgramsBodyState();
}

class _ManageProgramsBodyState extends ConsumerState<_ManageProgramsBody> {
  bool _busy = false;

  Future<void> _remove(UserProgramAssignment a) async {
    if (_busy) return;
    final confirm = await AppDialog.destructive(
      context,
      title: 'Remove program?',
      message:
          'This stops scheduling new workouts from "${a.title}". Completed '
          'workouts are kept.',
      confirmText: 'Remove',
      icon: Icons.stop_circle_outlined,
    );
    if (confirm != true) return;
    HapticService.medium();
    setState(() => _busy = true);
    try {
      final repo = ref.read(userProgramAssignmentRepositoryProvider);
      await repo.deleteAssignment(a.id);
      await refreshProgramAssignmentsW(ref);
      // Drop the removed program's future days from the merged calendar +
      // keep the home hero in lock-step.
      ref.read(workoutsProvider.notifier).silentRefresh();
      TodayWorkoutNotifier.markExplicitProgramRegen();
      ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not remove the program.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _togglePause(UserProgramAssignment a) async {
    if (_busy) return;
    final pausing = a.status != 'paused';
    HapticService.light();
    setState(() => _busy = true);
    try {
      final repo = ref.read(userProgramAssignmentRepositoryProvider);
      await repo.updateAssignment(a.id, status: pausing ? 'paused' : 'active');
      await refreshProgramAssignmentsW(ref);
      // Pausing hides the program's future workouts; resuming restores them.
      // Keep the merged calendar + home hero in lock-step either way.
      ref.read(workoutsProvider.notifier).silentRefresh();
      TodayWorkoutNotifier.markExplicitProgramRegen();
      ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pausing ? '"${a.title}" paused' : '"${a.title}" resumed',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not ${pausing ? 'pause' : 'resume'} the program.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openManage(UserProgramAssignment a) async {
    // Close this sheet first, then open the full per-program manage sheet.
    Navigator.of(context).pop();
    await showProgramManageSheet(context, ref, a);
  }

  void _addProgram() {
    Navigator.of(context).pop();
    context.push('/workout/program-library');
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final assignmentsAsync = ref.watch(programAssignmentsProvider);
    // Include paused programs (is_active=false) so they can be resumed here.
    final assignments =
        assignmentsAsync.valueOrNull
            ?.where((a) => a.isActive || a.status == 'paused')
            .toList() ??
        const <UserProgramAssignment>[];

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tc.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.dashboard_customize_outlined,
                    color: tc.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Programs',
                        style: ZType.disp(24, color: tc.textPrimary),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Pause to hide a program\'s workouts (resume keeps your '
                        'progress); ✕ removes it. Removing all leaves the AI '
                        'program.',
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
            const SizedBox(height: 16),

            if (assignments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No curated programs yet — you\'re on the AI program.',
                  style: TextStyle(fontSize: 13, color: tc.textSecondary),
                ),
              )
            else
              ...assignments.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _ProgramRow(
                    assignment: a,
                    color: ProgramColors.forKey(a.id),
                    colors: tc,
                    onTap: _busy ? null : () => _openManage(a),
                    onRemove: _busy ? null : () => _remove(a),
                    onTogglePause: _busy ? null : () => _togglePause(a),
                  ),
                ),
              ),

            // Always-on AI program base row (non-removable).
            const SizedBox(height: 2),
            _AiBaseRow(colors: tc),

            const SizedBox(height: 14),
            GestureDetector(
              onTap: _busy ? null : _addProgram,
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: tc.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tc.accent.withValues(alpha: 0.55)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 18, color: tc.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Add a program',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: tc.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Removing a program stops scheduling its future workouts '
              '(completed ones are kept).',
              style: TextStyle(fontSize: 11.5, color: tc.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramRow extends StatelessWidget {
  final UserProgramAssignment assignment;
  final Color color;
  final ThemeColors colors;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final VoidCallback? onTogglePause;

  const _ProgramRow({
    required this.assignment,
    required this.color,
    required this.colors,
    required this.onTap,
    required this.onRemove,
    required this.onTogglePause,
  });

  bool get _isPaused => assignment.status == 'paused';

  String get _subtitle {
    final parts = <String>[];
    if (_isPaused) parts.add('Paused');
    parts.add(assignment.weekLabel);
    parts.add(assignment.isAddon ? 'Extra' : 'Primary');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final initial = assignment.title.isNotEmpty
        ? assignment.title[0].toUpperCase()
        : '•';
    // Paused programs read as dimmed; the swatch desaturates to a muted tone.
    final swatch = _isPaused ? colors.textMuted : color;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Opacity(
          opacity: _isPaused ? 0.62 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: swatch,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Pause / resume toggle.
                GestureDetector(
                  onTap: onTogglePause,
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: colors.cardBorder),
                    ),
                    child: Icon(
                      _isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      size: 17,
                      color: _isPaused ? colors.accent : colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: colors.cardBorder),
                    ),
                    child: Icon(Icons.close, size: 15, color: colors.warning),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiBaseRow extends StatelessWidget {
  final ThemeColors colors;
  const _AiBaseRow({required this.colors});

  @override
  Widget build(BuildContext context) {
    const cyan = ProgramColors.ai;
    return Container(
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
                Text(
                  'AI Program',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Always on · fills uncovered training days',
                  style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 13, color: cyan),
              const SizedBox(width: 4),
              Text(
                'Base',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
