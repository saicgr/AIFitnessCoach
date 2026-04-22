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
import '../shared/set_rail.dart';
import '../shared/set_rail_overflow_sheet.dart';
import 'pre_set_coaching_banner.dart';

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
  /// Per-set hold target in seconds (planks, hollow body, wall sits). When
  /// set, the TARGET cell renders "45s hold" instead of a weight×reps string.
  final int? targetHoldSeconds;
  /// Exercise-level duration in seconds for cardio/timed-cardio exercises
  /// (e.g., Walking 300s). Same cell rendering path as targetHoldSeconds but
  /// labeled without "hold".
  final int? targetDurationSeconds;

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

  /// True when the exercise is time/hold-based — swap reps input for a timer
  /// cell and hide the weight column visually.
  final bool isTimedExercise;
  /// True when the exercise uses no external load — skip the "kg" prefix in
  /// the TARGET cell and hide the barbell plate indicator.
  final bool isBodyweight;

  const SetRowData({
    required this.setNumber,
    this.isWarmup = false,
    this.isCompleted = false,
    this.isActive = false,
    this.targetWeight,
    this.targetReps,
    this.targetRir,
    this.targetHoldSeconds,
    this.targetDurationSeconds,
    this.actualWeight,
    this.actualReps,
    this.actualRir,
    this.previousWeight,
    this.previousReps,
    this.previousRir,
    this.durationSeconds,
    this.restDurationSeconds,
    this.isTimedExercise = false,
    this.isBodyweight = false,
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

  // ========== Pre-Set Coaching Banner Props ==========

  /// If non-null, shown above the first active set row as an AI-grounded
  /// coaching insight. Passing null (parent decides: skip / dismissed /
  /// first set already logged) hides the banner.
  final String? preSetBannerMessage;

  /// Fires when the user taps the banner's dismiss button.
  final VoidCallback? onPreSetBannerDismissed;

  /// Stable key used to drive the banner's entry animation — should change
  /// when the message content changes (e.g. different exercise).
  final String? preSetBannerAnimationKey;

  // ========== Windowed Rendering Props (no-scroll refactor) ==========

  /// Max number of full set rows to render in the fixed-height focal column.
  /// When `sets.length > maxVisibleRows`, the table switches to Rail+Window
  /// mode: a `SetRail` renders at the top and only `maxVisibleRows` rows near
  /// the focus index are rendered below. This is the mechanism that keeps the
  /// Advanced viewport scroll-free on tiny devices / long workouts.
  final int maxVisibleRows;

  /// Optional callback fired when the user taps a rail pill to "jump to" a
  /// set. The parent is free to advance/rewind its active-set state; if it
  /// doesn't, the table still re-centers its internal render window so the
  /// tapped set is visible. null = rail tap only re-centers the window.
  final void Function(int setIndex)? onJumpToSet;

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
    this.preSetBannerMessage,
    this.onPreSetBannerDismissed,
    this.preSetBannerAnimationKey,
    this.maxVisibleRows = 4,
    this.onJumpToSet,
  });

  @override
  State<SetTrackingTable> createState() => _SetTrackingTableState();
}

class _SetTrackingTableState extends State<SetTrackingTable> {
  // Inline editing state
  int? _editingSetIndex;
  TextEditingController? _editWeightController;
  TextEditingController? _editRepsController;

  /// Center of the rendered window when in Rail+Window mode. Defaults to
  /// `widget.activeSetIndex`; updated when the user taps a rail pill or opens
  /// the overflow sheet. Ignored when `sets.length <= maxVisibleRows`.
  int? _focusOverride;

  String get _unit => widget.useKg ? 'kg' : 'lb';

  /// True when ALL non-null sets report the exercise as timed — drives header
  /// labels ("Reps" → "Time"). A mixed list is rare but we fall back to false.
  bool get _isTimedExercise =>
      widget.sets.isNotEmpty && widget.sets.every((s) => s.isTimedExercise);

  /// Effective focus index for windowed rendering. Prefers the user's manual
  /// override (set via rail tap / overflow sheet); otherwise tracks the active
  /// set so the focal window follows the workout's natural progression.
  int get _focusIndex {
    final raw = _focusOverride ?? widget.activeSetIndex;
    if (widget.sets.isEmpty) return 0;
    return raw.clamp(0, widget.sets.length - 1);
  }

  @override
  void didUpdateWidget(covariant SetTrackingTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the workout advances (active set index moves forward) or the
    // exercise changes, drop the stale manual override so the focal window
    // follows the live active set.
    if (oldWidget.activeSetIndex != widget.activeSetIndex ||
        oldWidget.exercise.name != widget.exercise.name) {
      _focusOverride = null;
    }
    // If the sets list shrinks below the override, clear it so we don't render
    // a stale window that points past the end.
    if (_focusOverride != null &&
        _focusOverride! >= widget.sets.length) {
      _focusOverride = null;
    }
  }

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

    final totalSets = widget.sets.length;
    final useWindow = totalSets > widget.maxVisibleRows;

    // ── Windowing math ──────────────────────────────────────────────────
    // When the set count exceeds the fixed-height budget, we render a
    // `SetRail` at the top and only `maxVisibleRows` rows in the body. The
    // window is centered on `_focusIndex` but biased to always include the
    // active set + one row below it when possible (so the user sees both
    // "what I just did" and "what's next" without any scrolling).
    int windowStart = 0;
    int windowEnd = totalSets; // exclusive
    if (useWindow) {
      final focus = _focusIndex;
      // Prefer a window of [focus - 1 ... focus + (N-2)] so the active row
      // sits in the second slot with one "previous" slot above it.
      windowStart = (focus - 1).clamp(0, totalSets - widget.maxVisibleRows);
      windowEnd = (windowStart + widget.maxVisibleRows).clamp(0, totalSets);
    }

    // Find the index where inline rest should be inserted (after last completed set).
    // Only insert when the anchor row is inside the visible window.
    int? inlineRestInsertIndex;
    if (widget.showInlineRest && widget.inlineRestRowWidget != null) {
      for (int i = widget.sets.length - 1; i >= 0; i--) {
        if (widget.sets[i].isCompleted) {
          if (!useWindow || (i >= windowStart && i < windowEnd)) {
            inlineRestInsertIndex = i;
          }
          break;
        }
      }
    }

    // Pre-Set banner: only show once, right before the first active row
    // (so it appears above Set 1 at workout start, above Set N if Set 1..N-1
    // are already done). Parent is responsible for null'ing the message once
    // the first working set is logged — no additional guard here.
    final bool hasBanner = widget.preSetBannerMessage != null &&
        widget.preSetBannerMessage!.isNotEmpty &&
        widget.onPreSetBannerDismissed != null;
    int? bannerInsertIndex;
    if (hasBanner) {
      for (int i = 0; i < widget.sets.length; i++) {
        if (widget.sets[i].isActive && !widget.sets[i].isCompleted) {
          // Only render the banner when its anchor is in the visible window.
          if (!useWindow || (i >= windowStart && i < windowEnd)) {
            bannerInsertIndex = i;
          }
          break;
        }
      }
    }

    // Build only the rows that fall inside the render window.
    final List<Widget> setRows = [];
    for (int index = windowStart; index < windowEnd; index++) {
      final set = widget.sets[index];

      if (hasBanner && bannerInsertIndex == index) {
        final animKey = widget.preSetBannerAnimationKey ??
            (widget.exercise.id ?? widget.exercise.name);
        setRows.add(PreSetCoachingBanner(
          key: ValueKey('pre_set_banner_$animKey'),
          message: widget.preSetBannerMessage!,
          onDismiss: widget.onPreSetBannerDismissed!,
          animationKey: animKey,
        ));
      }

      // Only allow deletion for pending sets (not completed, not active)
      // Users can swipe to remove future sets they don't want to do.
      final canDelete = widget.onSetDeleted != null &&
          !set.isCompleted &&
          !set.isActive &&
          index > widget.activeSetIndex;

      Widget row = _buildSetRow(context, theme, index, set);

      if (canDelete) {
        row = Dismissible(
          key: ValueKey('set_dismissible_${set.setNumber}_$index'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            HapticFeedback.mediumImpact();
            return true;
          },
          onDismissed: (direction) {
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

      if (set.isCompleted && set.durationSeconds != null) {
        setRows.add(_buildTimingRow(set, isDark));
      }

      if (set.isActive && !set.isCompleted && widget.onActiveRirChanged != null) {
        setRows.add(_RirQuickSelectBar(
          key: AppTourKeys.rirBarKey,
          selectedRir: widget.activeRir,
          onRirSelected: widget.onActiveRirChanged!,
          isDark: isDark,
        ));
      }

      if (inlineRestInsertIndex != null && index == inlineRestInsertIndex) {
        setRows.add(widget.inlineRestRowWidget!);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rail sits above the header only when windowing is active. It gives
        // the user a compact at-a-glance view of every set (done / current /
        // upcoming) and a tap-to-focus affordance for anything that's out of
        // the currently-rendered window.
        if (useWindow) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: SetRail(
              sets: _buildRailSummaries(),
              currentIndex: _focusIndex,
              onEditSet: _handleRailTap,
              onOverflowTap: () => _handleRailOverflow(context),
            ),
          ),
        ],

        // Table header
        _buildTableHeader(context, theme),

        // Windowed set rows (header + inline rest + RIR bar + banner interleaved)
        ...setRows,

        // Add set button
        _buildAddSetButton(context, theme),
      ],
    );
  }

  // ── Rail helpers ────────────────────────────────────────────────────────

  /// Map the table's domain `SetRowData` list into the rail's lightweight
  /// `RailSetSummary` model. We lean on target/actual values so every pill
  /// renders a useful preview even before the set is logged.
  List<RailSetSummary> _buildRailSummaries() {
    final out = <RailSetSummary>[];
    for (int i = 0; i < widget.sets.length; i++) {
      final s = widget.sets[i];
      final RailSetStatus status;
      if (s.isWarmup) {
        status = RailSetStatus.warmup;
      } else if (s.isCompleted) {
        status = RailSetStatus.done;
      } else if (i == widget.activeSetIndex) {
        status = RailSetStatus.current;
      } else {
        status = RailSetStatus.upcoming;
      }

      // Pick the most informative weight/rep pair available: actual > target > previous.
      final double? rawWeight = s.actualWeight ?? s.targetWeight ?? s.previousWeight;
      final int? displayReps = s.actualReps ??
          (s.targetReps != null ? int.tryParse(s.targetReps!.split('-').first) : null) ??
          s.previousReps;

      String? label;
      if (rawWeight != null && rawWeight > 0 && !s.isBodyweight) {
        final display = widget.useKg
            ? rawWeight
            : WeightUtils.fromKgSnapped(rawWeight, displayInLbs: true);
        label = '${display.toStringAsFixed(display % 1 == 0 ? 0 : 1)} '
            '${widget.useKg ? 'kg' : 'lb'}';
      }

      out.add(RailSetSummary(
        displayIndex: s.setNumber,
        status: status,
        weight: rawWeight,
        reps: displayReps,
        weightLabel: label,
      ));
    }
    return out;
  }

  /// Rail pill tap → re-center the render window on the tapped set and let
  /// the parent optionally advance its active-set state.
  void _handleRailTap(int setIndex) {
    if (setIndex < 0 || setIndex >= widget.sets.length) return;
    setState(() {
      _focusOverride = setIndex;
    });
    widget.onJumpToSet?.call(setIndex);
  }

  /// Rail "+N" chip tap → open the overflow sheet (the sole scroll container
  /// in the system; the main active-workout surface remains scroll-free).
  Future<void> _handleRailOverflow(BuildContext context) async {
    final picked = await showSetRailOverflowSheet(
      context: context,
      sets: _buildRailSummaries(),
      currentIndex: _focusIndex,
    );
    if (picked != null) {
      _handleRailTap(picked);
    }
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
                // Swap label to "Time" for timed exercises so the rep input
                // column doesn't mislead (planks, walking, hollow holds).
                _isTimedExercise ? 'Time' : 'Reps',
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
                targetHoldSeconds: set.targetHoldSeconds,
                targetDurationSeconds: set.targetDurationSeconds,
                isTimedExercise: set.isTimedExercise,
                isBodyweight: set.isBodyweight,
                previousWeight: set.previousWeight,
                previousReps: set.previousReps,
                useKg: widget.useKg,
                isWarmup: set.isWarmup,
                isDark: isDark,
              ),
            ),

            // Weight input — skipped entirely for bodyweight/timed exercises
            // (no external load to log). We still reserve the width via a
            // `_DashCell` so the grid stays aligned with other exercises.
            SizedBox(
              width: widget.isLeftRightMode ? 56 : 64,
              child: (set.isBodyweight || set.isTimedExercise)
                  ? const _DashCell()
                  : (isEditing
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
                            )),
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
                // For timed exercises (planks, walking, holds), the rep input
                // is swapped for a compact time-target readout. The per-set
                // timer still drives logging via TimedExerciseTimer in the
                // active-set sheet; this cell just keeps the row layout
                // honest instead of showing a confusing "1" rep field.
                child: set.isTimedExercise
                    ? _TimedTargetCell(
                        targetHoldSeconds: set.targetHoldSeconds,
                        targetDurationSeconds: set.targetDurationSeconds,
                        actualDurationSeconds: set.durationSeconds,
                        isActive: isActive,
                        isCompleted: set.isCompleted,
                        isDark: isDark,
                      )
                    : (isEditing
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
                              )),
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
