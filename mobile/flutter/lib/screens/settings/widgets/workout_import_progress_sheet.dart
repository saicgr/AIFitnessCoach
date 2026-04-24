/// Progress sheet for the async workout-history-import job.
///
/// Polls `GET /api/v1/media-jobs/{job_id}` every [pollInterval] and renders
/// human-friendly status copy. The sheet is NOT dismissible while the job is
/// still in flight (PopScope blocks back-gestures / drag-to-close) so users
/// don't accidentally drop progress visibility while a big import runs.
///
/// When the job reaches a terminal state ([WorkoutImportJobStatus.isTerminal])
/// the sheet auto-pops with the final [WorkoutImportJob]. Callers typically
/// chain into the summary sheet right after.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/workout_import_job.dart';
import '../../../data/repositories/workout_history_import_file_repository.dart';
import '../../../widgets/glass_sheet.dart';

/// Show the polling progress sheet. Returns the final [WorkoutImportJob] on
/// completion / failure. Returns `null` only if the user forcibly dismissed
/// the sheet AFTER the job entered a terminal state.
Future<WorkoutImportJob?> showWorkoutImportProgressSheet({
  required BuildContext context,
  required String jobId,
  required WorkoutHistoryImportFileRepository repository,
  Duration pollInterval = const Duration(milliseconds: 1500),
  String? sourceAppLabel,
}) async {
  return showGlassSheet<WorkoutImportJob>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) => GlassSheet(
      showHandle: false,
      maxHeightFraction: 0.65,
      child: _ProgressSheetBody(
        jobId: jobId,
        repository: repository,
        pollInterval: pollInterval,
        sourceAppLabel: sourceAppLabel,
      ),
    ),
  );
}

class _ProgressSheetBody extends StatefulWidget {
  const _ProgressSheetBody({
    required this.jobId,
    required this.repository,
    required this.pollInterval,
    this.sourceAppLabel,
  });

  final String jobId;
  final WorkoutHistoryImportFileRepository repository;
  final Duration pollInterval;
  final String? sourceAppLabel;

  @override
  State<_ProgressSheetBody> createState() => _ProgressSheetBodyState();
}

class _ProgressSheetBodyState extends State<_ProgressSheetBody>
    with SingleTickerProviderStateMixin {
  Timer? _pollTimer;
  WorkoutImportJob? _job;
  String? _error;
  late final AnimationController _pulse;

  /// Step index advances even while status == in_progress so the copy looks
  /// alive while we wait on the backend. Values: 0 queued → 1 parsing →
  /// 2 matching → 3 writing → 4 indexing.
  int _narrationStep = 0;
  DateTime _lastAdvance = DateTime.now();

  bool get _isTerminal => _job?.status.isTerminal ?? false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollOnce();
    _pollTimer = Timer.periodic(widget.pollInterval, (_) => _pollOnce());
  }

  Future<void> _pollOnce() async {
    try {
      final job = await widget.repository.pollJob(widget.jobId);
      if (!mounted) return;
      setState(() {
        _job = job;
        _error = null;
      });

      // Advance narration step every ~4s while we're in progress so the copy
      // doesn't freeze on "Parsing…" for 20+ seconds during AI fallback.
      final now = DateTime.now();
      if (job.status == WorkoutImportJobStatus.inProgress &&
          now.difference(_lastAdvance).inMilliseconds > 4000 &&
          _narrationStep < 3) {
        setState(() {
          _narrationStep = math.min(_narrationStep + 1, 3);
          _lastAdvance = now;
        });
      }

      if (job.status.isTerminal) {
        _pollTimer?.cancel();
        // Auto-pop with the final job after a short beat so the user sees the
        // completion state before the summary sheet takes over.
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          Navigator.of(context).pop(job);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    // Block back-gesture while the job is active so the user can't lose the
    // polling window. Once terminal, PopScope releases the gate.
    return PopScope(
      canPop: _isTerminal,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isTerminal) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Import is still in progress — please wait.'),
          ));
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Importing workout history', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              widget.sourceAppLabel ?? 'This usually finishes in 10–30 seconds.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _ProgressCenter(
              accent: accent,
              pulse: _pulse,
              job: _job,
              narrationStep: _narrationStep,
              sourceAppLabel: widget.sourceAppLabel,
              errorMessage: _error,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progressFraction(),
              minHeight: 6,
              backgroundColor: accent.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
            const SizedBox(height: 8),
            Text(
              'Job ID: ${widget.jobId}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Map job state → progress fraction for the bar.
  double _progressFraction() {
    final status = _job?.status ?? WorkoutImportJobStatus.pending;
    switch (status) {
      case WorkoutImportJobStatus.pending:
        return 0.08;
      case WorkoutImportJobStatus.inProgress:
        // Advance with narration step, capped at 0.85 until server confirms.
        return 0.25 + (_narrationStep * 0.18).clamp(0.0, 0.6);
      case WorkoutImportJobStatus.completed:
        return 1.0;
      case WorkoutImportJobStatus.failed:
      case WorkoutImportJobStatus.cancelled:
        return 1.0;
      case WorkoutImportJobStatus.unknown:
        return 0.1;
    }
  }
}

class _ProgressCenter extends StatelessWidget {
  const _ProgressCenter({
    required this.accent,
    required this.pulse,
    required this.job,
    required this.narrationStep,
    required this.sourceAppLabel,
    required this.errorMessage,
  });

  final Color accent;
  final Animation<double> pulse;
  final WorkoutImportJob? job;
  final int narrationStep;
  final String? sourceAppLabel;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = job?.status ?? WorkoutImportJobStatus.pending;

    IconData icon = Icons.hourglass_bottom_rounded;
    Color tint = accent;
    String title = 'Queued…';
    String detail = 'Waiting for a worker to pick up your job.';

    if (errorMessage != null) {
      icon = Icons.warning_amber_rounded;
      tint = Colors.orange;
      title = 'Network hiccup';
      detail = 'Retrying — the import is still running on the server.';
    }

    switch (status) {
      case WorkoutImportJobStatus.pending:
        break;
      case WorkoutImportJobStatus.inProgress:
        icon = Icons.auto_awesome_motion_rounded;
        tint = accent;
        switch (narrationStep) {
          case 0:
            title = 'Parsing your ${sourceAppLabel ?? "export"}…';
            detail = 'Reading rows and detecting the file structure.';
            break;
          case 1:
            title = 'Matching exercises…';
            detail = 'Aligning names with our library (aliases + semantic search).';
            break;
          case 2:
            title = 'Writing rows…';
            detail = 'Storing your strength history and cardio sessions.';
            break;
          case 3:
            title = 'Indexing for AI coach…';
            detail = 'Updating personalized weight suggestions.';
            break;
        }
        break;
      case WorkoutImportJobStatus.completed:
        icon = Icons.check_circle_rounded;
        tint = Colors.green.shade600;
        title = 'Import complete!';
        detail = 'Opening summary…';
        break;
      case WorkoutImportJobStatus.failed:
        icon = Icons.error_outline_rounded;
        tint = Colors.red.shade500;
        title = 'Import failed';
        detail = job?.errorMessage ?? 'An unexpected error stopped the import.';
        break;
      case WorkoutImportJobStatus.cancelled:
        icon = Icons.cancel_rounded;
        tint = Colors.grey.shade600;
        title = 'Cancelled';
        detail = 'The job was cancelled. Your data is unchanged.';
        break;
      case WorkoutImportJobStatus.unknown:
        break;
    }

    return Row(
      children: [
        FadeTransition(
          opacity: Tween(begin: 0.55, end: 1.0).animate(pulse),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: tint, size: 28),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              )),
              const SizedBox(height: 2),
              Text(
                detail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
