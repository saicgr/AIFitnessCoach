import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/services/weight_suggestion_service.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/glow_button.dart';
import '../../../widgets/number_stepper.dart';
import 'set_dial.dart';
import 'set_row_visuals.dart';
import 'voice_set_logging.dart';


part 'set_row_part_weight_increments.dart';
part 'set_row_part_rpe_rir_selector_state.dart';
part 'set_row_part_increment_button.dart';


/// A row widget for tracking individual sets during workout
class SetRow extends StatefulWidget {
  final ActiveSetData setData;
  final bool isCurrentSet;
  final ValueChanged<ActiveSetData> onDataChanged;
  final VoidCallback onComplete;
  final VoidCallback? onDelete;
  final bool showPrevious;

  const SetRow({
    super.key,
    required this.setData,
    required this.isCurrentSet,
    required this.onDataChanged,
    required this.onComplete,
    this.onDelete,
    this.showPrevious = true,
  });

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late FocusNode _weightFocus;
  late FocusNode _repsFocus;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.setData.actualWeight.toStringAsFixed(1),
    );
    _repsController = TextEditingController(
      text: widget.setData.actualReps.toString(),
    );
    _weightFocus = FocusNode();
    _repsFocus = FocusNode();
  }

  @override
  void didUpdateWidget(SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers if data changed externally
    if (oldWidget.setData.actualWeight != widget.setData.actualWeight) {
      _weightController.text = widget.setData.actualWeight.toStringAsFixed(1);
    }
    if (oldWidget.setData.actualReps != widget.setData.actualReps) {
      _repsController.text = widget.setData.actualReps.toString();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    super.dispose();
  }

  void _updateWeight(String value) {
    final weight = double.tryParse(value) ?? widget.setData.actualWeight;
    widget.onDataChanged(widget.setData.copyWith(actualWeight: weight));
  }

  void _updateReps(String value) {
    final reps = int.tryParse(value) ?? widget.setData.actualReps;
    widget.onDataChanged(widget.setData.copyWith(actualReps: reps));
  }

  void _incrementWeight() {
    // Use equipment-aware increment (e.g., 2.5kg for dumbbells, 5kg for machines)
    final increment = widget.setData.weightIncrement;
    final newWeight = widget.setData.actualWeight + increment;
    _weightController.text = newWeight.toStringAsFixed(1);
    widget.onDataChanged(widget.setData.copyWith(actualWeight: newWeight));
  }

  void _decrementWeight() {
    // Use equipment-aware increment (e.g., 2.5kg for dumbbells, 5kg for machines)
    final increment = widget.setData.weightIncrement;
    final newWeight = (widget.setData.actualWeight - increment).clamp(0.0, 999.0);
    _weightController.text = newWeight.toStringAsFixed(1);
    widget.onDataChanged(widget.setData.copyWith(actualWeight: newWeight.toDouble()));
  }

  void _incrementReps() {
    final newReps = widget.setData.actualReps + 1;
    _repsController.text = newReps.toString();
    widget.onDataChanged(widget.setData.copyWith(actualReps: newReps));
  }

  void _decrementReps() {
    final newReps = (widget.setData.actualReps - 1).clamp(0, 999);
    _repsController.text = newReps.toString();
    widget.onDataChanged(widget.setData.copyWith(actualReps: newReps));
  }

  void _cycleSetType() {
    final types = ['working', 'warmup', 'failure'];
    final currentIndex = types.indexOf(widget.setData.setType);
    final nextType = types[(currentIndex + 1) % types.length];
    widget.onDataChanged(widget.setData.copyWith(setType: nextType));
    HapticFeedback.lightImpact();
  }

  /// "Same as last time" — copy the previous session's weight/reps into this
  /// set's ACTUAL fields in one tap (Hevy/Strong-style). No-op on completed
  /// sets or when there's no history. Copies whichever values exist.
  void _copyPrevious() {
    final prevW = widget.setData.previousWeight;
    final prevR = widget.setData.previousReps;
    if (prevW == null && prevR == null) return;

    var next = widget.setData;
    if (prevW != null) {
      _weightController.text = prevW.toStringAsFixed(1);
      next = next.copyWith(actualWeight: prevW);
    }
    if (prevR != null) {
      _repsController.text = prevR.toString();
      next = next.copyWith(actualReps: prevR);
    }
    widget.onDataChanged(next);
    HapticFeedback.selectionClick();
  }

  /// Apply a voice-parsed set ("225 for 8") into this set's actual fields.
  /// Weight arrives in the same display unit the row already uses (lb).
  void _applyVoice(ParsedVoiceSet parsed) {
    if (parsed.isEmpty) return;
    var next = widget.setData;
    if (parsed.weight != null) {
      _weightController.text = parsed.weight!.toStringAsFixed(1);
      next = next.copyWith(actualWeight: parsed.weight);
    }
    if (parsed.reps != null) {
      _repsController.text = parsed.reps.toString();
      next = next.copyWith(actualReps: parsed.reps);
    }
    widget.onDataChanged(next);
  }

  Color get _setTypeColor {
    switch (widget.setData.setType) {
      case 'warmup':
        return AppColors.orange;
      case 'failure':
        return AppColors.error;
      default:
        return AppColors.cyan;
    }
  }

  String get _setTypeLabel {
    switch (widget.setData.setType) {
      case 'warmup':
        return 'W';
      case 'failure':
        return 'F';
      default:
        return widget.setData.setNumber.toString();
    }
  }

  // ── Fix #5 / #6 helpers ──────────────────────────────────────────────
  // The TARGET cell of every set row now carries:
  //   • a trend pill (↑/↓/·) comparing this set's target to the prior set's
  //     target (suppressed when progressive overload is disabled OR the
  //     exercise has no prior history → "Starter weight" hint instead).
  //   • an "Edited" chip when the user manually overrode the planned target.
  // The RIR cell carries an outline pill for the planned (target) RIR and a
  // separate filled pill for the logged (actual) RIR. AMRAP renders as
  // "Target RIR · AMRAP" (no number). Easy mode hides RIR entirely.
  //
  // Visual parity is shipped: identical pills render in the canonical
  // `set_tracking_table_part_set_number_badge.dart` via shared helpers in
  // `set_row_visuals.dart`. Exercise-header "Progression: $pattern • $delta"
  // subtitle lives in `workout_ui_builders_mixin_ui_2.dart`.

  // Thin wrappers that delegate to [SetRowVisuals] so the same visuals are
  // reused by `set_tracking_table.dart` (canonical active-workout renderer).
  Widget? _buildTrendPill() {
    final data = widget.setData;
    return SetRowVisuals.buildTrendPill(
      progressiveOverloadEnabled: data.progressiveOverloadEnabled,
      isFirstSetEver: data.isFirstSetEver,
      isDeload: data.isDeload,
      metric: data.metric,
      targetWeightDisplay: data.targetWeight,
      targetReps: data.targetReps,
      durationSeconds: data.durationSeconds,
      previousSetTargetWeightDisplay: data.previousSetTargetWeight,
      previousSetTargetReps: data.previousSetTargetReps,
      previousSetTargetSeconds: data.previousSetTargetSeconds,
      // SetRow assumes lb display (its data already arrives in display units);
      // SetTrackingTable converts via WeightUtils and passes its actual unit.
      unitLabel: 'lb',
    );
  }

  Widget? _buildEditedChip() {
    return SetRowVisuals.buildEditedChip(isEdited: widget.setData.isEdited);
  }

  /// [sheetContext] is the live BuildContext from the enclosing [Builder] —
  /// passing it makes the target-effort pill tappable and opens the
  /// plain-English RIR / "push to failure" explainer sheet. The set's raw
  /// [ActiveSetData.setType] is forwarded so a 'failure' set reads
  /// "Push to failure" instead of a numeric RIR target.
  Widget? _buildRirPills(BuildContext sheetContext) {
    final data = widget.setData;
    return SetRowVisuals.buildRirPills(
      isEasyMode: data.isEasyMode,
      isAmrap: data.isAmrap,
      targetRir: data.targetRir,
      actualRir: data.actualRir,
      setType: data.setType,
      context: sheetContext,
    );
  }

  /// Build the 1RM target label showing target weight and percentage
  Widget _buildOneRMTargetLabel() {
    final oneRM = widget.setData.oneRepMax!;
    final targetPercent = widget.setData.intensityPercent!;
    final actualPercent = widget.setData.actualPercentOfMax ?? 0;
    final isOnTarget = widget.setData.isOnTarget;

    // Determine color based on how close to target
    Color percentColor;
    if (isOnTarget) {
      percentColor = AppColors.success;
    } else if (actualPercent > targetPercent) {
      percentColor = AppColors.orange; // Going heavier than target
    } else {
      percentColor = AppColors.cyan; // Going lighter than target
    }

    return Row(
      children: [
        // Target info
        Text(
          'Target: $targetPercent%',
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 4),
        // Actual percentage (dynamic)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: percentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '→ $actualPercent%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: percentColor,
            ),
          ),
        ),
        const SizedBox(width: 4),
        // 1RM reference
        Text(
          '(1RM: ${oneRM.toStringAsFixed(0)})',
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.setData.isCompleted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isCurrentSet && !isCompleted
            ? AppColors.cyan.withOpacity(0.1)
            : isCompleted
                ? AppColors.success.withOpacity(0.1)
                : AppColors.glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isCurrentSet && !isCompleted
              ? AppColors.cyan
              : isCompleted
                  ? AppColors.success
                  : AppColors.cardBorder,
          width: widget.isCurrentSet ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
          // Set number/type badge
          GestureDetector(
            onTap: isCompleted ? null : _cycleSetType,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success
                    : _setTypeColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? AppColors.success : _setTypeColor,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : Text(
                        _setTypeLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _setTypeColor,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Weight input
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show 1RM percentage target if available
                if (widget.setData.oneRepMax != null &&
                    widget.setData.intensityPercent != null)
                  _buildOneRMTargetLabel()
                else if (widget.showPrevious && widget.setData.previousWeight != null)
                  // Tap-to-copy "same as last time" reference (Hevy/Strong
                  // style). Greyed last-session weight; tap fills this set's
                  // actual weight + reps. Disabled once the set is completed.
                  GestureDetector(
                    onTap: isCompleted ? null : _copyPrevious,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Prev: ${widget.setData.previousWeight?.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (!isCompleted) ...[
                          const SizedBox(width: 3),
                          Icon(Icons.replay_rounded,
                              size: 10, color: AppColors.cyan.withOpacity(0.8)),
                        ],
                      ],
                    ),
                  ),
                // Fix #5 — trend pill (↑/↓ vs prior set's target) and Edited
                // chip live on the same line so they stay anchored to the
                // TARGET column even on narrow rows.
                Builder(builder: (context) {
                  final trend = _buildTrendPill();
                  final edited = _buildEditedChip();
                  if (trend == null && edited == null) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (trend != null) trend,
                        if (trend != null && edited != null)
                          const SizedBox(width: 4),
                        if (edited != null) edited,
                      ],
                    ),
                  );
                }),
                Row(
                  children: [
                    _IncrementButton(
                      icon: Icons.remove,
                      onPressed: isCompleted ? null : _decrementWeight,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        focusNode: _weightFocus,
                        enabled: !isCompleted,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          suffix: const Text(
                            'kg',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: AppColors.elevated,
                        ),
                        onChanged: _updateWeight,
                        onSubmitted: (_) => _repsFocus.requestFocus(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _IncrementButton(
                      icon: Icons.add,
                      onPressed: isCompleted ? null : _incrementWeight,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Reps input
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showPrevious && widget.setData.previousReps != null)
                  GestureDetector(
                    onTap: isCompleted ? null : _copyPrevious,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      'Prev: ${widget.setData.previousReps} reps',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    _IncrementButton(
                      icon: Icons.remove,
                      onPressed: isCompleted ? null : _decrementReps,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _repsController,
                        focusNode: _repsFocus,
                        enabled: !isCompleted,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          suffix: const Text(
                            'reps',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: AppColors.elevated,
                        ),
                        onChanged: _updateReps,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _IncrementButton(
                      icon: Icons.add,
                      onPressed: isCompleted ? null : _incrementReps,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Fix #6 — target vs logged RIR pills (outline = target, filled =
          // logged). Wrapped in a fixed-width column so it doesn't push the
          // complete button off-screen on narrow phones; renders empty when
          // Easy mode is on or no target/actual RIR data is present.
          Builder(builder: (context) {
            final pills = _buildRirPills(context);
            if (pills == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: pills,
            );
          }),

          // Voice "225 for 8" mic — hands-free set entry. Hidden once the set
          // is completed (nothing left to fill).
          if (!isCompleted)
            VoiceSetMicButton(
              onParsed: _applyVoice,
              useKg: false,
              size: 20,
            ),

          // Complete button
          if (!isCompleted)
            IconButton(
              onPressed: widget.onComplete,
              icon: const Icon(Icons.check_circle_outline),
              color: AppColors.success,
              iconSize: 28,
            )
          else
            const SizedBox(
              width: 44,
              child: Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 28,
              ),
            ),
            ],
          ),
          // Visual goal/last/range dials (Dr-Yaad audit #9) — under the inputs
          // for the active working set, so logging is "read the dial, swipe".
          if (_showDials) _buildDials(),
          // On-set adaptive caption (Dr-Yaad audit #9) — the progression
          // stakes shown right under the dials, not buried in the rest row.
          if (_onSetCaption != null) _buildOnSetCaption(),
        ],
      ),
    );
  }

  /// Show the dials only on the active, not-completed working set, and only
  /// when there's a reference value to plot (a goal or a last-session number).
  bool get _showDials {
    final s = widget.setData;
    if (!widget.isCurrentSet || s.isCompleted) return false;
    if (s.setType.toLowerCase() == 'warmup') return false;
    if (s.metric == 'time') return false; // time holds use the caption only
    final hasWeightRef = (s.targetWeight > 0) || (s.previousWeight ?? 0) > 0;
    final hasRepsRef = s.targetReps > 0 || (s.previousReps ?? 0) > 0;
    return hasWeightRef || hasRepsRef;
  }

  Widget _buildDials() {
    final s = widget.setData;
    final showWeight = s.metric != 'reps' &&
        ((s.targetWeight > 0) || (s.previousWeight ?? 0) > 0);
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 44, right: 4),
      child: Column(
        children: [
          if (showWeight)
            SetDial(
              label: 'LOAD',
              unit: 'kg',
              current: s.actualWeight,
              goal: s.targetWeight > 0 ? s.targetWeight : null,
              last: (s.previousWeight ?? 0) > 0 ? s.previousWeight : null,
            ),
          if (showWeight) const SizedBox(height: 8),
          SetDial(
            label: 'REPS',
            unit: 'reps',
            current: s.actualReps.toDouble(),
            goal: s.targetReps > 0 ? s.targetReps.toDouble() : null,
            last: (s.previousReps ?? 0) > 0 ? s.previousReps!.toDouble() : null,
          ),
        ],
      ),
    );
  }

  /// One-line progression-stakes caption for the ACTIVE working set, derived
  /// from its own prev/target data. Null for warmups, completed/non-current
  /// sets, when progressive overload is off, or with no weighted history.
  String? get _onSetCaption {
    final s = widget.setData;
    if (!widget.isCurrentSet || s.isCompleted) return null;
    if (s.setType.toLowerCase() == 'warmup') return null;
    if (!s.progressiveOverloadEnabled) return null;
    final prevW = s.previousWeight;
    if (prevW == null || prevW <= 0) {
      if (s.isFirstSetEver) {
        return 'Set your baseline here — next session builds on it.';
      }
      return null;
    }
    String fmt(double w) =>
        w % 1 == 0 ? w.toStringAsFixed(0) : w.toStringAsFixed(1);
    if (s.targetWeight > prevW + 0.01) {
      return 'Up from last time (${fmt(prevW)}→${fmt(s.targetWeight)} kg). '
          'Clear all reps and next week steps up again.';
    }
    return 'Match last session (${fmt(prevW)} kg × ${s.previousReps ?? s.targetReps}), '
        'then beat it — next week goes heavier.';
  }

  Widget _buildOnSetCaption() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 44, right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up_rounded,
              size: 12, color: AppColors.cyan.withOpacity(0.9)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _onSetCaption!,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.25,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
