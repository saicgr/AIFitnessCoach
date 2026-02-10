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
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/exercise.dart';
import '../models/workout_state.dart';

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
          : ((set.actualWeight ?? 0) * 2.20462);

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

      // Insert RIR quick-select bar below the active set row
      if (set.isActive && !set.isCompleted && widget.onActiveRirChanged != null) {
        setRows.add(_RirQuickSelectBar(
          key: const ValueKey('rir_quick_select'),
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
            width: widget.isLeftRightMode ? 60 : 72,
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
              width: 72,
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
              width: widget.isLeftRightMode ? 60 : 72,
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
                                      : set.actualWeight! * 2.20462)
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
                        controller: _editRepsController!, // TODO: use right controller
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
                            value: set.actualReps?.toString() ?? '', // TODO: use right reps
                            isCompleted: set.isCompleted,
                            isDark: isDark,
                            label: 'R',
                          ),
              ),
            ] else
              SizedBox(
                width: 72,
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

/// Set number badge widget
class _SetNumberBadge extends StatelessWidget {
  final int? number;
  final bool isWarmup;
  final bool isCompleted;
  final bool isActive;
  final bool isDark;

  const _SetNumberBadge({
    this.number,
    this.isWarmup = false,
    this.isCompleted = false,
    this.isActive = false,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: isActive
            ? WorkoutDesign.accentBlue.withOpacity(0.2)
            : isCompleted
                ? (isDark ? WorkoutDesign.textMuted.withOpacity(0.15) : Colors.grey.shade200)
                : (isDark ? WorkoutDesign.surface : Colors.grey.shade50),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive
              ? WorkoutDesign.accentBlue
              : isCompleted
                  ? (isDark ? WorkoutDesign.textMuted.withOpacity(0.3) : Colors.grey.shade400)
                  : (isDark ? WorkoutDesign.border : Colors.grey.shade300),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          isWarmup ? 'W' : (number?.toString() ?? ''),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive
                ? WorkoutDesign.accentBlue
                : isCompleted
                    ? (isDark ? WorkoutDesign.textMuted : Colors.grey.shade500)
                    : (isDark ? WorkoutDesign.textPrimary : Colors.grey.shade800),
          ),
        ),
      ),
    );
  }
}

/// Auto target cell showing AI recommendation with RIR pill
class _AutoTargetCell extends StatelessWidget {
  final double? targetWeight;
  final String? targetReps;
  final int? targetRir;
  final double? previousWeight;
  final int? previousReps;
  final bool useKg;
  final bool isWarmup;
  final bool isDark;

  const _AutoTargetCell({
    this.targetWeight,
    this.targetReps,
    this.targetRir,
    this.previousWeight,
    this.previousReps,
    required this.useKg,
    this.isWarmup = false,
    this.isDark = true,
  });

  void _showRirExplanation(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkTheme ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDarkTheme ? Colors.grey.shade700 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header with close button
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        size: 24,
                        color: isDarkTheme ? Colors.white : Colors.black,
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'What is RIR?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24), // Balance the close button
                  ],
                ),
                const SizedBox(height: 24),

                // Scale labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hardest',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkTheme ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Easiest',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkTheme ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'No reps in reserve',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'Many reps in reserve',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // RIR scale with colored circles
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRirCircle('0', WorkoutDesign.rirMax, isDarkTheme),
                    _buildRirCircle('1', WorkoutDesign.rir1, isDarkTheme),
                    _buildRirCircle('2', WorkoutDesign.rir2, isDarkTheme),
                    _buildRirCircle('3', WorkoutDesign.rir3, isDarkTheme),
                    _buildRirCircle('4', const Color(0xFF3B82F6), isDarkTheme), // Blue
                    _buildRirCircle('5', const Color(0xFF3B82F6), isDarkTheme),
                    _buildRirCircle('6+', const Color(0xFF3B82F6), isDarkTheme),
                  ],
                ),
                const SizedBox(height: 24),

                // Divider
                Divider(
                  color: isDarkTheme ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
                const SizedBox(height: 16),

                // Explanation text
                Text(
                  'What you see above is an RIR scale',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkTheme ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'RIR stands for Reps in Reserve—a simple way to describe how challenging a set felt.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDarkTheme ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'A lower RIR (0–1) means you pushed to your limit. A higher RIR (like 4–6+) means the set felt easier and you had plenty left in the tank.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDarkTheme ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You are not required to track RIR, but we strongly recommend it. Understanding your proximity to failure will help the app better accommodate your current strength levels and rates of fatigue.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDarkTheme ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRirCircle(String label, Color color, bool isDark) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: (color == WorkoutDesign.rir2)
                ? Colors.black87 // Dark text on yellow
                : Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build target string
    String targetString = '';

    if (isWarmup) {
      targetString = targetReps ?? '4-6 reps';
    } else if (targetWeight != null && targetReps != null) {
      final displayWeight = useKg ? targetWeight! : targetWeight! * 2.20462;
      targetString = '${displayWeight.toStringAsFixed(0)} ${useKg ? 'kg' : 'lb'} x $targetReps';
    } else if (previousWeight != null && previousReps != null) {
      // Fall back to previous session
      final displayWeight = useKg ? previousWeight! : previousWeight! * 2.20462;
      targetString = '${displayWeight.toStringAsFixed(0)} ${useKg ? 'kg' : 'lb'} x $previousReps';
    } else {
      targetString = targetReps ?? '—';
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Target weight x reps (no truncation - important to see full target)
          Text(
            targetString,
            style: WorkoutDesign.autoTargetStyle.copyWith(
              color: isDark ? WorkoutDesign.textSecondary : Colors.grey.shade700,
              fontSize: 12, // Slightly smaller to fit
            ),
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
          // RIR pill with info icon - only ? icon is tappable
          if (targetRir != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: WorkoutDesign.getRirColor(targetRir!),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      WorkoutDesign.getRirLabel(targetRir!),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: WorkoutDesign.getRirTextColor(targetRir!),
                      ),
                    ),
                    const SizedBox(width: 2),
                    // Only the ? icon triggers the explanation - larger tap area
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showRirExplanation(context),
                      child: Padding(
                        padding: const EdgeInsets.all(4), // Larger tap target
                        child: Icon(
                          Icons.help_outline,
                          size: 14,
                          color: WorkoutDesign.getRirTextColor(targetRir!).withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Previous session cell showing weight x reps + RIR from last workout
class _PreviousCell extends StatelessWidget {
  final double? previousWeight;
  final int? previousReps;
  final int? previousRir;
  final bool useKg;
  final bool isDark;

  const _PreviousCell({
    this.previousWeight,
    this.previousReps,
    this.previousRir,
    required this.useKg,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    // If no previous data, show dash
    if (previousWeight == null && previousReps == null) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(
          '—',
          style: WorkoutDesign.autoTargetStyle.copyWith(
            color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade400,
          ),
        ),
      );
    }

    // Build previous string
    String previousString = '';
    if (previousWeight != null && previousReps != null) {
      final displayWeight = useKg ? previousWeight! : previousWeight! * 2.20462;
      previousString = '${displayWeight.toStringAsFixed(0)} x $previousReps';
    } else if (previousReps != null) {
      previousString = '$previousReps reps';
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Previous weight x reps
          Text(
            previousString,
            style: WorkoutDesign.autoTargetStyle.copyWith(
              color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade500,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // RIR pill (if available)
          if (previousRir != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: WorkoutDesign.getRirColor(previousRir!).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'RIR $previousRir',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? WorkoutDesign.getRirColor(previousRir!)
                        : WorkoutDesign.getRirColor(previousRir!).withOpacity(0.8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Previous cell with RIR badge - combines previous data with target RIR
/// Used when Target column is removed
class _PreviousCellWithRir extends StatelessWidget {
  final double? previousWeight;
  final int? previousReps;
  final int? previousRir;
  final int? targetRir;
  final bool useKg;
  final bool isWarmup;
  final bool isDark;
  /// Callback when RIR badge text is tapped (for editing)
  final VoidCallback? onRirTapped;

  const _PreviousCellWithRir({
    this.previousWeight,
    this.previousReps,
    this.previousRir,
    this.targetRir,
    required this.useKg,
    this.isWarmup = false,
    this.isDark = true,
    this.onRirTapped,
  });

  void _showRirExplanation(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkTheme ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDarkTheme ? Colors.grey.shade700 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        size: 24,
                        color: isDarkTheme ? Colors.white : Colors.black,
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'What is RIR?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'RIR stands for Reps in Reserve—a simple way to describe how challenging a set felt.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDarkTheme ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'A lower RIR (0–1) means you pushed close to your limit. A higher RIR (like 3–4) means you had more reps in the tank.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDarkTheme ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build previous string
    String previousString = '—';
    if (previousWeight != null && previousReps != null) {
      final displayWeight = useKg ? previousWeight! : previousWeight! * 2.20462;
      previousString = '${displayWeight.toStringAsFixed(0)} ${useKg ? 'kg' : 'lb'} x $previousReps';
    } else if (previousReps != null) {
      previousString = '$previousReps reps';
    } else if (previousWeight != null) {
      final displayWeight = useKg ? previousWeight! : previousWeight! * 2.20462;
      previousString = '${displayWeight.toStringAsFixed(0)} ${useKg ? 'kg' : 'lb'}';
    }

    // Determine which RIR to show (target takes priority for current set guidance)
    final displayRir = targetRir ?? previousRir;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Previous weight x reps
          Flexible(
            child: Text(
              previousString,
              style: WorkoutDesign.autoTargetStyle.copyWith(
                color: isDark ? WorkoutDesign.textSecondary : Colors.grey.shade600,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // RIR pill with ? icon (if available and not warmup)
          // RIR text is tappable to edit, ? icon shows explanation
          if (displayRir != null && !isWarmup) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.only(left: 6, top: 2, bottom: 2),
              decoration: BoxDecoration(
                color: WorkoutDesign.getRirColor(displayRir).withOpacity(isDark ? 0.25 : 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // RIR text - tappable to edit
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onRirTapped != null
                        ? () {
                            HapticFeedback.lightImpact();
                            onRirTapped!();
                          }
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                      child: Text(
                        'RIR $displayRir',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? WorkoutDesign.getRirColor(displayRir)
                              : WorkoutDesign.getRirColor(displayRir).withOpacity(0.9),
                        ),
                      ),
                    ),
                  ),
                  // ? icon triggers the explanation - larger tap area
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showRirExplanation(context),
                    child: Padding(
                      padding: const EdgeInsets.all(4), // Larger tap target
                      child: Icon(
                        Icons.help_outline,
                        size: 14,
                        color: isDark
                            ? WorkoutDesign.getRirColor(displayRir).withOpacity(0.7)
                            : WorkoutDesign.getRirColor(displayRir).withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Input field for weight/reps (theme-aware)
class _DarkInputField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String)? onSubmitted;
  final bool isDark;
  final String? hintText;

  const _DarkInputField({
    required this.controller,
    this.onSubmitted,
    this.isDark = true,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: WorkoutDesign.inputFieldHeight,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: WorkoutDesign.inputStyle.copyWith(
          color: isDark ? WorkoutDesign.textPrimary : Colors.grey.shade800,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: isDark ? WorkoutDesign.inputField : Colors.grey.shade100,
          hintText: hintText,
          hintStyle: WorkoutDesign.inputStyle.copyWith(
            color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade400,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(WorkoutDesign.radiusSmall),
            borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(WorkoutDesign.radiusSmall),
            borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(WorkoutDesign.radiusSmall),
            borderSide: const BorderSide(color: WorkoutDesign.accentBlue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
          isDense: true,
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }
}

/// Cell showing completed value (not editable inline)
class _CompletedValueCell extends StatelessWidget {
  final String value;
  final bool isCompleted;
  final bool isDark;
  final String? label; // Optional label like "L" or "R" for L/R mode

  const _CompletedValueCell({
    required this.value,
    required this.isCompleted,
    this.isDark = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: WorkoutDesign.inputFieldHeight,
      decoration: BoxDecoration(
        color: isDark
            ? WorkoutDesign.inputField.withOpacity(isCompleted ? 0.5 : 0.3)
            : (isCompleted ? Colors.grey.shade200 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(WorkoutDesign.radiusSmall),
        border: isDark ? null : Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: label != null && value.isEmpty
            ? Text(
                label!,
                style: WorkoutDesign.inputStyle.copyWith(
                  color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade400,
                  fontSize: 12,
                ),
              )
            : Text(
                value.isEmpty ? '—' : value,
                style: WorkoutDesign.inputStyle.copyWith(
                  color: isDark
                      ? (isCompleted ? WorkoutDesign.textSecondary : WorkoutDesign.textMuted)
                      : (isCompleted ? Colors.grey.shade700 : Colors.grey.shade500),
                ),
              ),
      ),
    );
  }
}

/// Completion checkbox widget
class _CompletionCheckbox extends StatelessWidget {
  final bool isCompleted;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _CompletionCheckbox({
    required this.isCompleted,
    required this.isActive,
    required this.onTap,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isCompleted
              ? WorkoutDesign.success
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isCompleted
                ? WorkoutDesign.success
                : isActive
                    ? (isDark ? WorkoutDesign.textSecondary : Colors.grey.shade600)
                    : (isDark ? WorkoutDesign.border : Colors.grey.shade400),
            width: 2,
          ),
        ),
        child: isCompleted
            ? const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}

/// Small colored RIR badge shown on completed set rows
class _RirBadge extends StatelessWidget {
  final int rir;
  final bool isDark;

  const _RirBadge({
    required this.rir,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = WorkoutDesign.getRirColor(rir);
    final textColor = WorkoutDesign.getRirTextColor(rir);

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$rir',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

/// RIR quick-select bar shown below the active set row
class _RirQuickSelectBar extends StatelessWidget {
  final int? selectedRir;
  final ValueChanged<int> onRirSelected;
  final bool isDark;

  const _RirQuickSelectBar({
    super.key,
    this.selectedRir,
    required this.onRirSelected,
    this.isDark = true,
  });

  static const _rirOptions = [0, 1, 2, 3, 4, 5];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'RIR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 8),
          ..._rirOptions.map((rir) {
            final isSelected = selectedRir == rir;
            final color = WorkoutDesign.getRirColor(rir);
            final label = rir == 5 ? '5+' : '$rir';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onRirSelected(rir);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? color : color.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? WorkoutDesign.getRirTextColor(rir)
                            : color,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
