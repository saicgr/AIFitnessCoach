import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Generic confirm card for AI-coach mutations that need explicit user
/// confirmation before mutating the workout (Issue 3).
///
/// Used for: ``log_set``, ``swap_exercise`` (when issued mid-workout),
/// ``create_superset`` (override scenario), ``break_superset``,
/// ``reorder_exercises``.
///
/// The card auto-cancels after 90 s. On Apply it dispatches to the
/// appropriate WorkoutRepository method. On failure it surfaces the
/// backend's human-readable detail (no silent fallbacks). When the
/// backend reports ``exercise list changed`` the card morphs into a
/// "workout changed — coach is re-thinking" state and emits a callback
/// so the chat thread can request a fresh proposal.
class ChatActionConfirmCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> actionData;
  final String summaryText;
  final VoidCallback? onCancelled;
  final VoidCallback? onAppliedRefresh;
  final void Function(String reason)? onStaleListed;

  const ChatActionConfirmCard({
    super.key,
    required this.actionData,
    required this.summaryText,
    this.onCancelled,
    this.onAppliedRefresh,
    this.onStaleListed,
  });

  @override
  ConsumerState<ChatActionConfirmCard> createState() =>
      ChatActionConfirmCardState();
}

@visibleForTesting
class ChatActionConfirmCardState
    extends ConsumerState<ChatActionConfirmCard> {
  static const _autoCancelDuration = Duration(seconds: 90);

  Timer? _autoCancelTimer;
  bool _busy = false;
  bool _applied = false;
  bool _cancelled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _autoCancelTimer = Timer(_autoCancelDuration, _onAutoCancel);
  }

  @override
  void dispose() {
    _autoCancelTimer?.cancel();
    super.dispose();
  }

  void _onAutoCancel() {
    if (!mounted || _applied || _cancelled || _busy) return;
    setState(() => _cancelled = true);
    widget.onCancelled?.call();
  }

  String get _action => (widget.actionData['action'] as String?) ?? '';
  String get _workoutId => (widget.actionData['workout_id'] as String?) ?? '';

  Future<void> _onApply() async {
    if (_busy || _applied || _cancelled) return;
    HapticService.medium();
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(workoutRepositoryProvider);

    try {
      late (bool, String?) result;
      switch (_action) {
        case 'swap_exercise':
          final (workout, err) = await repo.swapExercise(
            workoutId: _workoutId,
            oldExerciseName: widget.actionData['old'] as String,
            newExerciseName: widget.actionData['new'] as String,
            reason: widget.actionData['reason'] as String?,
            swapSource: 'ai_chat_action',
          );
          result = (workout != null, err);
          break;
        case 'log_set':
          final unit = ref.read(workoutWeightUnitProvider);
          result = await repo.logSet(
            workoutId: _workoutId,
            exerciseId: widget.actionData['exercise_id'] as String,
            setIndex: widget.actionData['set_index'] as int,
            weight: (widget.actionData['weight'] as num?)?.toDouble(),
            reps: widget.actionData['reps'] as int?,
            rir: widget.actionData['rir'] as int?,
            side: widget.actionData['side'] as String?,
            weightUnit: (widget.actionData['weight_unit'] as String?) ?? unit,
            override: widget.actionData['is_override'] == true,
          );
          break;
        case 'create_superset':
          final ids = List<String>.from(
            (widget.actionData['exercise_ids'] as List?) ?? const [],
          );
          result = await repo.createSuperset(
            workoutId: _workoutId,
            exerciseIds: ids,
          );
          break;
        case 'break_superset':
          result = await repo.breakSuperset(
            workoutId: _workoutId,
            supersetGroupId:
                widget.actionData['superset_group_id'] as String,
          );
          break;
        case 'reorder_exercises':
          final ids = List<String>.from(
            (widget.actionData['exercise_ids'] as List?) ??
                (widget.actionData['new_order'] as List?) ??
                const [],
          );
          result = await repo.reorderExercises(
            workoutId: _workoutId,
            exerciseIds: ids,
          );
          break;
        case 'add_set':
          result = await repo.addSet(
            workoutId: _workoutId,
            exerciseName: widget.actionData['exercise_name'] as String,
            exerciseId: widget.actionData['exercise_id'] as String?,
            isDropSet: widget.actionData['is_drop_set'] == true,
          );
          break;
        default:
          result = (false, 'Unknown action: $_action');
      }

      if (!mounted) return;
      final (ok, err) = result;
      if (ok) {
        setState(() {
          _busy = false;
          _applied = true;
        });
        // Refresh today_workout provider so the workout screen mirrors
        // the change immediately.
        // ignore: unused_result
        ref.invalidate(todayWorkoutProvider);
        widget.onAppliedRefresh?.call();
      } else if (err == 'exercise list changed') {
        setState(() {
          _busy = false;
          _error = 'Workout changed since suggestion — coach is re-thinking.';
        });
        widget.onStaleListed?.call(err!);
      } else {
        setState(() {
          _busy = false;
          _error = err ?? 'Action failed.';
        });
      }
    } catch (e, st) {
      debugPrint('❌ [ChatActionConfirmCard] $e\n$st');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  void _onCancel() {
    if (_applied || _cancelled || _busy) return;
    HapticService.light();
    setState(() => _cancelled = true);
    widget.onCancelled?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Signature: the in-bubble action chip ("SWAP → MACHINE PRESS ✓") is the
    // ONE place the reserved gym-aware accent is allowed in the thread.
    final accent = ThemeColors.of(context).accent;
    final muted = theme.textTheme.bodySmall?.color?.withOpacity(0.7);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: accent.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(_action), color: accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.summaryText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_applied)
            Row(children: [
              Icon(Icons.check_circle, color: accent, size: 16),
              const SizedBox(width: 6),
              Text(AppLocalizations.of(context).proposedChangeCardApplied, style: theme.textTheme.bodySmall),
            ])
          else if (_cancelled)
            Text(AppLocalizations.of(context).proposedChangeCardDismissed,
                style: theme.textTheme.bodySmall?.copyWith(color: muted))
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _busy ? null : _onCancel,
                  child: Text(AppLocalizations.of(context).buttonCancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : _onApply,
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  child: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(AppLocalizations.of(context).setAdjustmentSheetApply),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static IconData _iconFor(String action) {
    switch (action) {
      case 'swap_exercise':
        return Icons.swap_horiz;
      case 'log_set':
        return Icons.check_circle_outline;
      case 'create_superset':
        return Icons.link;
      case 'break_superset':
        return Icons.link_off;
      case 'reorder_exercises':
        return Icons.reorder;
      case 'add_set':
        return Icons.playlist_add;
      default:
        return Icons.info_outline;
    }
  }
}
