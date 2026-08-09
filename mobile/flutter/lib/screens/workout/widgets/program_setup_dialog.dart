/// Blocking "setting up your program" dialog shown while the server expands a
/// started program into scheduled workouts (5-15s for a multi-week plan).
///
/// Replaces the old snackbar lifecycle ("Setting up…" toast → success toast),
/// which had two structural bugs on top of being visually weak:
///   * Floating SnackBars shown via the ROOT messenger render one copy per
///     registered Scaffold — the main shell's IndexedStack keeps all five tab
///     Scaffolds alive, so identical copies collided on the SnackBar's derived
///     Hero tag during route transitions ("multiple heroes share the same
///     tag") and the broken transition left the toast permanently stuck.
///   * A snackbar under-communicates a multi-second, plan-changing operation.
///
/// The dialog owns the whole lifecycle: working (animated step list) →
/// success (what was created + tailoring summary + View schedule) → error.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/program_template.dart' show ProgramParseException;
import '../../../data/repositories/program_template_repository.dart'
    show AssignResult;
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/theme/theme_colors.dart';

enum _Phase { working, success, error }

class ProgramSetupDialog extends StatefulWidget {
  const ProgramSetupDialog({
    super.key,
    required this.programName,
    required this.future,
    this.durationWeeks,
    this.timesPerWeek,
    this.fitEquipment = false,
  });

  /// The in-flight assign call. The dialog renders working/success/error off
  /// this future; it never starts work itself.
  final Future<AssignResult> future;
  final String programName;
  final int? durationWeeks;
  final int? timesPerWeek;
  final bool fitEquipment;

  @override
  State<ProgramSetupDialog> createState() => _ProgramSetupDialogState();
}

class _ProgramSetupDialogState extends State<ProgramSetupDialog> {
  _Phase _phase = _Phase.working;
  AssignResult? _result;
  String _errorMessage = '';

  /// Cosmetic pacing through the step list while the server works. The last
  /// step never "completes" until the future resolves, so the UI stays honest.
  int _stepIndex = 0;
  Timer? _stepTimer;

  late final List<String> _steps = [
    widget.durationWeeks != null
        ? 'Expanding your ${widget.durationWeeks}-week plan'
        : 'Expanding your plan',
    widget.timesPerWeek != null
        ? 'Scheduling ${widget.timesPerWeek}×/week sessions'
        : 'Scheduling your sessions',
    if (widget.fitEquipment) 'Fitting exercises to your gear',
    'Finishing touches',
  ];

  @override
  void initState() {
    super.initState();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (_stepIndex < _steps.length - 1) {
        setState(() => _stepIndex++);
      }
    });
    widget.future.then((r) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.success;
        _result = r;
      });
    }, onError: (Object e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMessage = e is ProgramParseException
            ? e.message
            : 'Could not start this program. Please try again.';
      });
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // No backing out mid-assign — the server call is already in flight.
      canPop: _phase != _Phase.working,
      child: Dialog(
        backgroundColor: ThemeColors.of(context).elevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: ThemeColors.of(context).cardBorder),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: switch (_phase) {
              _Phase.working => _buildWorking(),
              _Phase.success => _buildSuccess(),
              _Phase.error => _buildError(),
            },
          ),
        ),
      ),
    );
  }

  // ── Working ─────────────────────────────────────────────────────────

  Widget _buildWorking() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SETTING UP',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: context.accentColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.programName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.15,
            color: ThemeColors.of(context).textPrimary,
          ),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < _steps.length; i++) ...[
          _StepRow(
            label: _steps[i],
            state: i < _stepIndex
                ? _StepState.done
                : i == _stepIndex
                    ? _StepState.active
                    : _StepState.pending,
          ),
          if (i < _steps.length - 1) const SizedBox(height: 12),
        ],
        const SizedBox(height: 18),
        Text(
          'This can take a few seconds for multi-week programs.',
          style: TextStyle(fontSize: 12, color: ThemeColors.of(context).textMuted),
        ),
      ],
    );
  }

  // ── Success ─────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    final r = _result!;
    final cs = r.customizeSummary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.15),  // accent-allowlist: success/positive state — same value as AppColors.success, must stay green regardless of accent
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.check_rounded,
              color: AppColors.green, size: 28),  // accent-allowlist: success/positive state — same value as AppColors.success, must stay green regardless of accent
        ),
        const SizedBox(height: 14),
        Text(
          '${widget.programName} is ready',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.15,
            color: ThemeColors.of(context).textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          r.workoutsCreated > 0
              ? '${r.workoutsCreated} workouts are on your calendar.'
              : 'Your program is on your calendar.',
          style: TextStyle(
              fontSize: 13.5, height: 1.4, color: ThemeColors.of(context).textSecondary),
        ),
        if (cs.isApplied || cs.isFailed) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ThemeColors.of(context).surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ThemeColors.of(context).cardBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  cs.isApplied
                      ? Icons.auto_awesome
                      : Icons.info_outline_rounded,
                  size: 16,
                  color: cs.isApplied ? context.accentColor : ThemeColors.of(context).textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cs.isApplied
                        ? cs.humanPhrase
                        : "Tailoring couldn't run — started with the standard plan.",
                    style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: ThemeColors.of(context).textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: ThemeColors.of(context).textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: const Text('Done',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: () {
                  final nav = Navigator.of(context);
                  final router = GoRouter.of(context);
                  nav.pop();
                  router.push('/schedule');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: context.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View schedule',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Error ───────────────────────────────────────────────────────────

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),  // accent-allowlist: error/destructive — must stay red
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 28),  // accent-allowlist: error/destructive — must stay red
        ),
        const SizedBox(height: 14),
        Text(
          "Couldn't start the program",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.15,
            color: ThemeColors.of(context).textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage,
          style: TextStyle(
              fontSize: 13.5, height: 1.4, color: ThemeColors.of(context).textSecondary),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: ThemeColors.of(context).surface,
              foregroundColor: ThemeColors.of(context).textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: ThemeColors.of(context).cardBorder),
              ),
            ),
            child: const Text('Close',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

enum _StepState { pending, active, done }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.state});
  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final Widget leading = switch (state) {
      _StepState.done => const Icon(Icons.check_circle_rounded,
          size: 18, color: AppColors.green),  // accent-allowlist: success/positive state — same value as AppColors.success, must stay green regardless of accent
      _StepState.active => SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: context.accentColor),
        ),
      _StepState.pending => Icon(Icons.circle_outlined,
          size: 18, color: ThemeColors.of(context).textMuted.withValues(alpha: 0.5)),
    };
    return Row(
      children: [
        leading,
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight:
                  state == _StepState.active ? FontWeight.w700 : FontWeight.w500,
              color: state == _StepState.pending
                  ? ThemeColors.of(context).textMuted
                  : ThemeColors.of(context).textPrimary,
            ),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}
