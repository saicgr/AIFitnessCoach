/// Set Tracking Table Widget
///
/// MacroFactor Workouts 2026 inspired set tracking table.
/// Features:
/// - Set | Auto | Weight | Reps | Checkbox columns
/// - RIR color badges
/// - Dark input fields
/// - Checkbox completion per row
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/workout_design.dart';
import '../../../core/utils/default_weights.dart';
import '../../../core/utils/weight_utils.dart';
import '../../../widgets/app_tour/app_tour_controller.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/exercise.dart';
import '../../../widgets/glass_sheet.dart';
import '../models/workout_state.dart';

part 'set_tracking_table_part_set_number_badge.dart';


/// Data for a single set row
class SetRowData {
  final int setNumber;
  final bool isWarmup;
  final bool isCompleted;
  final bool isActive;

  // Target values (from AI)
  final double? targetWeight;
  final String? targetReps; // Can be "4-6" range
  final int? targetRir;

  // Actual values (logged)
  final double? actualWeight;
  final int? actualReps;
  final int? actualRir; // Logged RIR for completed sets

  // Previous session values
  final double? previousWeight;
  final int? previousReps;
  final int? previousRir;

  // Timing data (populated for completed sets)
  final int? durationSeconds; // How long the set took
  final int? restDurationSeconds; // Actual rest taken before this set

  const SetRowData({
    required this.setNumber,
    this.isWarmup = false,
    this.isCompleted = false,
    this.isActive = false,
    this.targetWeight,
    this.targetReps,
    this.targetRir,
    this.actualWeight,
    this.actualReps,
    this.actualRir,
    this.previousWeight,
    this.previousReps,
    this.previousRir,
    this.durationSeconds,
    this.restDurationSeconds,
  });
}

/// MacroFactor-style set tracking table
class SetTrackingTable extends StatefulWidget {
  /// Exercise being tracked
  final WorkoutExercise exercise;

  /// All sets data
  final List<SetRowData> sets;

  /// Whether using kg or lbs
  final bool useKg;

  /// Currently active set index
  final int activeSetIndex;

  /// Weight controller for active set
  final TextEditingController weightController;

  /// Reps controller for active set (or Left reps when L/R mode)
  final TextEditingController repsController;

  /// Right reps controller for L/R mode
  final TextEditingController? repsRightController;

  /// Callback when a set checkbox is tapped
  final void Function(int setIndex) onSetCompleted;

  /// Callback when weight/reps are updated for a completed set
  final void Function(int setIndex, double weight, int reps)? onSetUpdated;

  /// Callback to add a new set
  final VoidCallback onAddSet;

  /// Whether L/R (left/right) mode is enabled
  final bool isLeftRightMode;

  /// Whether to show all sets as select-all checkbox
  final bool allSetsCompleted;

  /// Callback for select-all checkbox
  final VoidCallback? onSelectAllTapped;

  /// Callback when a set is deleted via swipe
  final void Function(int setIndex)? onSetDeleted;

  /// Callback when unit toggle is tapped (kg/lbs)
  final VoidCallback? onToggleUnit;

  /// Callback when RIR badge is tapped for editing (setIndex, currentRir)
  final void Function(int setIndex, int? currentRir)? onRirTapped;

  /// Current RIR selection for the active set
  final int? activeRir;

  /// Callback when user taps an RIR button on the quick-select bar
  final ValueChanged<int>? onActiveRirChanged;

  // ========== Inline Rest Row Props ==========

  /// Whether to show inline rest row (between last completed and active set)
  final bool showInlineRest;

  /// Inline rest row widget (passed from parent to keep state management centralized)
  final Widget? inlineRestRowWidget;

  const SetTrackingTable({
    super.key,
    required this.exercise,
    required this.sets,
    required this.useKg,
    required this.activeSetIndex,
    required this.weightController,
    required this.repsController,
    this.repsRightController,
    required this.onSetCompleted,
    this.onSetUpdated,
    required this.onAddSet,
    this.isLeftRightMode = false,
    this.allSetsCompleted = false,
    this.onSelectAllTapped,
    this.onSetDeleted,
    this.onToggleUnit,
    this.onRirTapped,
    this.activeRir,
    this.onActiveRirChanged,
    this.showInlineRest = false,
    this.inlineRestRowWidget,
  });

  @override
  State<SetTrackingTable> createState() => _SetTrackingTableState();
}

class _SetTrackingTableState extends State<SetTrackingTable> {
  // Inline editing state
  int? _editingSetIndex;
  TextEditingController? _editWeightController;
  TextEditingController? _editRepsController;

  String get _unit => widget.useKg ? 'kg' : 'lb';

  @override
  void dispose() {
    _editWeightController?.dispose();
    _editRepsController?.dispose();
    super.dispose();
  }

  void _startEditing(int index) {
    final set = widget.sets[index];
    setState(() {
      _editingSetIndex = index;
      _editWeightController?.dispose();
      _editRepsController?.dispose();

      final displayWeight = widget.useKg
          ? (set.actualWeight ?? 0)
          : kgToDisplayLbs(set.actualWeight ?? 0, widget.exercise.equipment,
              exerciseName: widget.exercise.name);

      _editWeightController = TextEditingController(
        text: displayWeight.toStringAsFixed(0),
      );
      _editRepsController = TextEditingController(
        text: (set.actualReps ?? 0).toString(),
      );
    });
  }

  void _saveEditing() {
    if (_editingSetIndex == null) return;

    final weight = double.tryParse(_editWeightController?.text ?? '') ?? 0;
    final reps = int.tryParse(_editRepsController?.text ?? '') ?? 0;

    if (weight > 0 && reps > 0) {
      final weightInKg = widget.useKg ? weight : weight / 2.20462;
      widget.onSetUpdated?.call(_editingSetIndex!, weightInKg, reps);
    }

    HapticFeedback.mediumImpact();
    _cancelEditing();
  }

  void _cancelEditing() {
    setState(() {
      _editingSetIndex = null;
      _editWeightController?.dispose();
      _editRepsController?.dispose();
      _editWeightController = null;
      _editRepsController = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.workoutDesign;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Find the index where inline rest should be inserted (after last completed set)
    int? inlineRestInsertIndex;
    if (widget.showInlineRest && widget.inlineRestRowWidget != null) {
      // Find the last completed set index
      for (int i = widget.sets.length - 1; i >= 0; i--) {
        if (widget.sets[i].isCompleted) {
          inlineRestInsertIndex = i;
          break;
        }
      }
    }

    // Build set rows with inline rest inserted at the right position
    final List<Widget> setRows = [];
    for (int index = 0; index < widget.sets.length; index++) {
      final set = widget.sets[index];

      // Only allow deletion for pending sets (not completed, not active)
      // Users can swipe to remove future sets they don't want to do
      final canDelete = widget.onSetDeleted != null &&
          !set.isCompleted &&
          !set.isActive &&
          index > widget.activeSetIndex;

      Widget row = _buildSetRow(context, theme, index, set);

      // Wrap in Dismissible only if deletion is allowed
      if (canDelete) {
        row = Dismissible(
          key: ValueKey('set_dismissible_${set.setNumber}_$index'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            HapticFeedback.mediumImpact();
            return true;
          },
          onDismissed: (direction) {
            // Pass -1 to signal "remove a pending set" rather than a completed set
            widget.onSetDeleted?.call(-1);
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: WorkoutDesign.accentBlue,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 22,
                ),
              ],
            ),
          ),
          child: row,
        );
      }

      setRows.add(row);

      // Insert timing label under completed set rows
      if (set.isCompleted && set.durationSeconds != null) {
        setRows.add(_buildTimingRow(set, isDark));
      }

      // Insert RIR quick-select bar below the active set row
      if (set.isActive && !set.isCompleted && widget.onActiveRirChanged != null) {
        setRows.add(_RirQuickSelectBar(
          key: AppTourKeys.rirBarKey,
          selectedRir: widget.activeRir,
          onRirSelected: widget.onActiveRirChanged!,
          isDark: isDark,
        ));
      }

      // Insert inline rest row after the last completed set
      if (inlineRestInsertIndex != null && index == inlineRestInsertIndex) {
        setRows.add(widget.inlineRestRowWidget!);
      }
    }

    return Column(
      children: [
        // Table header
        _buildTableHeader(context, theme),

        // Set rows with inline rest inserted
        ...setRows,

        // Add set button
        _buildAddSetButton(context, theme),
      ],
    );
  }

  Widget _buildTableHeader(BuildContext context, WorkoutDesignTheme theme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? WorkoutDesign.borderSubtle : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Set column
          SizedBox(
            width: 32,
            child: Text(
              'Set',
              style: WorkoutDesign.tableHeaderStyle.copyWith(
                color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade600,
              ),
            ),
          ),

          // Previous column (last session data)
          Expanded(
            flex: 3,
            child: Text(
              'Previous',
              style: WorkoutDesign.tableHeaderStyle.copyWith(
                color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade600,
              ),
            ),
          ),

          // TARGET column - AI recommended targets
          Expanded(
            flex: 3,
            child: Text(
              'TARGET',
              style: WorkoutDesign.tableHeaderStyle.copyWith(
                color: WorkoutDesign.accentBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Weight column with toggle
          SizedBox(
            width: widget.isLeftRightMode ? 56 : 64,
            child: GestureDetector(
              onTap: widget.onToggleUnit,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onToggleUnit != null)
                    Icon(
                      Icons.swap_horiz,
                      size: 14,
                      color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade600,
                    ),
                  if (widget.onToggleUnit != null)
                    const SizedBox(width: 2),
                  Text(
                    _unit,
                    style: WorkoutDesign.tableHeaderStyle.copyWith(
                      color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Reps column - shows L/R labels when in L/R mode
          if (widget.isLeftRightMode) ...[
            // Left reps
            SizedBox(
              width: 56,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Left',
                    style: WorkoutDesign.tableHeaderStyle.copyWith(
                      color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade600,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Right reps
            SizedBox(
              width: 56,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Right',
                    style: WorkoutDesign.tableHeaderStyle.copyWith(
                      color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade600,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else
            SizedBox(
              width: 64,
              child: Text(
                'Reps',
                style: WorkoutDesign.tableHeaderStyle.copyWith(
                  color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(width: 4),

          // RIR column header
          SizedBox(
            width: 26,
            child: Text(
              'RIR',
              style: WorkoutDesign.tableHeaderStyle.copyWith(
                color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade600,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(width: 4),

          // Checkbox column
          SizedBox(
            width: 32,
            child: GestureDetector(
              onTap: widget.onSelectAllTapped,
              child: Icon(
                widget.allSetsCompleted
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                size: 20,
                color: widget.allSetsCompleted
                    ? WorkoutDesign.success
                    : (isDark ? WorkoutDesign.textMuted : Colors.grey.shade500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format seconds as "45s" or "1:22" for durations > 60s
  String _formatDuration(int seconds) {
    if (seconds >= 60) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return '$m:${s.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }

  /// Build a compact timing label + divider under a completed set row
  Widget _buildTimingRow(SetRowData set, bool isDark) {
    final textMuted = isDark ? AppColors.textMuted : const Color(0xFF9CA3AF);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06);

    final duration = _formatDuration(set.durationSeconds!);
    final setLabel = 'set ${set.setNumber}';
    String label = '$setLabel: $duration';

    if (set.restDurationSeconds != null) {
      if (set.restDurationSeconds! < 3) {
        label = '$setLabel: $duration · skipped rest';
      } else {
        label = '$setLabel: $duration · rested ${_formatDuration(set.restDurationSeconds!)}';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Divider(height: 1, thickness: 0.5, color: borderColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: textMuted, fontStyle: FontStyle.italic),
            ),
          ),
          Expanded(child: Divider(height: 1, thickness: 0.5, color: borderColor)),
        ],
      ),
    );
  }

  Widget _buildSetRow(BuildContext context, WorkoutDesignTheme theme, int index, SetRowData set) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = _editingSetIndex == index;
    final isActive = set.isActive && !set.isCompleted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: set.isCompleted && widget.onSetUpdated != null
          ? () => _startEditing(index)
          : null,
      child: Container(
        height: WorkoutDesign.setRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? WorkoutDesign.accentBlue.withOpacity(isDark ? 0.08 : 0.06)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Set number badge
            SizedBox(
              width: 32,
              child: _SetNumberBadge(
                number: set.isWarmup ? null : set.setNumber,
                isWarmup: set.isWarmup,
                isCompleted: set.isCompleted,
                isActive: isActive,
                isDark: isDark,
              ),
            ),

            // Previous session column
            Expanded(
              flex: 3,
              child: _PreviousCellWithRir(
                previousWeight: set.previousWeight,
                previousReps: set.previousReps,
                previousRir: set.previousRir,
                targetRir: null, // Don't show RIR in previous column
                useKg: widget.useKg,
                isWarmup: set.isWarmup,
                isDark: isDark,
                onRirTapped: null,
              ),
            ),

            // TARGET column - AI recommended targets with RIR badge
            Expanded(
              flex: 3,
              child: _AutoTargetCell(
                targetWeight: set.targetWeight,
                targetReps: set.targetReps,
                targetRir: set.targetRir,
                previousWeight: set.previousWeight,
                previousReps: set.previousReps,
                useKg: widget.useKg,
                isWarmup: set.isWarmup,
                isDark: isDark,
              ),
            ),

            // Weight input
            SizedBox(
              width: widget.isLeftRightMode ? 56 : 64,
              child: isEditing
                  ? _DarkInputField(
                      controller: _editWeightController!,
                      onSubmitted: (_) => _saveEditing(),
                      isDark: isDark,
                    )
                  : isActive
                      ? _DarkInputField(
                          controller: widget.weightController,
                          isDark: isDark,
                        )
                      : _CompletedValueCell(
                          value: set.actualWeight != null
                              ? (widget.useKg
                                      ? set.actualWeight!
                                      : kgToDisplayLbs(set.actualWeight!, widget.exercise.equipment,
                exerciseName: widget.exercise.name,))
                                  .toStringAsFixed(0)
                              : '',
                          isCompleted: set.isCompleted,
                          isDark: isDark,
                        ),
            ),

            const SizedBox(width: 8),

            // Reps input - shows L/R split inputs when in L/R mode
            if (widget.isLeftRightMode) ...[
              // Left reps input
              SizedBox(
                width: 56,
                child: isEditing
                    ? _DarkInputField(
                        controller: _editRepsController!,
                        onSubmitted: (_) => _saveEditing(),
                        isDark: isDark,
                        hintText: 'L',
                      )
                    : isActive
                        ? _DarkInputField(
                            controller: widget.repsController,
                            isDark: isDark,
                            hintText: 'L',
                          )
                        : _CompletedValueCell(
                            value: set.actualReps?.toString() ?? '',
                            isCompleted: set.isCompleted,
                            isDark: isDark,
                            label: 'L',
                          ),
              ),
              const SizedBox(width: 6),
              // Right reps input
              SizedBox(
                width: 56,
                child: isEditing
                    ? _DarkInputField(
                        controller: _editRepsController!, // L/R mode shares a single reps value in the model
                        onSubmitted: (_) => _saveEditing(),
                        isDark: isDark,
                        hintText: 'R',
                      )
                    : isActive
                        ? _DarkInputField(
                            controller: widget.repsRightController ?? widget.repsController,
                            isDark: isDark,
                            hintText: 'R',
                          )
                        : _CompletedValueCell(
                            value: set.actualReps?.toString() ?? '', // L/R mode shares a single reps value in the model
                            isCompleted: set.isCompleted,
                            isDark: isDark,
                            label: 'R',
                          ),
              ),
            ] else
              SizedBox(
                width: 64,
                child: isEditing
                    ? _DarkInputField(
                        controller: _editRepsController!,
                        onSubmitted: (_) => _saveEditing(),
                        isDark: isDark,
                      )
                    : isActive
                        ? _DarkInputField(
                            controller: widget.repsController,
                            isDark: isDark,
                          )
                        : _CompletedValueCell(
                            value: set.actualReps?.toString() ?? '',
                            isCompleted: set.isCompleted,
                            isDark: isDark,
                          ),
              ),

            const SizedBox(width: 4),

            // RIR badge for completed sets
            if (set.isCompleted && set.actualRir != null && !isEditing)
              GestureDetector(
                onTap: widget.onRirTapped != null
                    ? () {
                        HapticFeedback.lightImpact();
                        widget.onRirTapped!(index, set.actualRir);
                      }
                    : null,
                child: _RirBadge(rir: set.actualRir!, isDark: isDark),
              )
            else
              const SizedBox(width: 26),

            const SizedBox(width: 4),

            // Completion checkbox
            SizedBox(
              width: 32,
              child: isEditing
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.check, size: 20),
                      color: WorkoutDesign.success,
                      onPressed: _saveEditing,
                    )
                  : _CompletionCheckbox(
                      isCompleted: set.isCompleted,
                      isActive: isActive,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.onSetCompleted(index);
                      },
                      isDark: isDark,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSetButton(BuildContext context, WorkoutDesignTheme theme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Get dynamic accent color from app settings
    final accentEnum = AccentColorScope.of(context);
    final accentColor = accentEnum.getColor(isDark);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onAddSet();
      },
      child: Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              size: 22,
              color: accentColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Add Set',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
