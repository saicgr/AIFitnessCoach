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
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
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
import 'set_row_visuals.dart';

import '../../../l10n/generated/app_localizations.dart';
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

  // ── Trend / Edited / Easy-mode plumbing (parity with ActiveSetData) ─────
  /// User has progressive overload enabled in prefs. When false the trend
  /// pill is suppressed entirely.
  final bool progressiveOverloadEnabled;
  /// User manually overrode this set's target — render an "Edited" chip.
  final bool isEdited;
  /// Active training block is a deload week — colour the trend pill with
  /// the deload theme rather than red on decreases.
  final bool isDeload;
  /// AMRAP set — RIR pill renders "Target RIR · AMRAP" without a number.
  final bool isAmrap;
  /// True when there is no prior history for this exercise — render a
  /// "Starter weight" muted hint instead of a trend pill.
  final bool isFirstSetEver;
  /// Easy mode hides the RIR pill entirely.
  final bool isEasyMode;
  /// Raw set type string ('working' | 'warmup' | 'failure' | 'amrap').
  /// A 'failure' set renders the target-effort pill as "Push to failure".
  final String setType;
  /// Previous set's target (in kg, internal unit) for trend delta.
  /// Null on the first set of the exercise.
  final double? previousSetTargetWeight;
  final int? previousSetTargetReps;
  final int? previousSetTargetSeconds;

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
    this.progressiveOverloadEnabled = true,
    this.isEdited = false,
    this.isDeload = false,
    this.isAmrap = false,
    this.isFirstSetEver = false,
    this.isEasyMode = false,
    this.setType = 'working',
    this.previousSetTargetWeight,
    this.previousSetTargetReps,
    this.previousSetTargetSeconds,
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

  /// Phase 2.D — RPE/RIR captured for a completed set via long-press picker.
  /// Writes back to `set_rep_accuracy.rpe / .rir` via the backend; powers
  /// auto-regulation (3 consecutive RPE ≥ 9 → -5% next set) and the rolling
  /// 7d RPE per-exercise feed into UserState.
  final void Function(int setIndex, double rpe, int? rir)? onRpeLogged;

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

  // ── Onboarding v5: showcase mode ──────────────────────────────────
  /// True = render in display-only mode for the onboarding workout-showcase
  /// screen. Disables all input fields, suppresses keyboard, ignores tap
  /// gestures on checkboxes/RIR/swipe. The widget renders identically to a
  /// real session so the user sees the actual product UI, frozen.
  /// Wrapped externally with [AbsorbPointer] for the strongest guarantee.
  final bool showcase;

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
    this.onRpeLogged,
    this.activeRir,
    this.onActiveRirChanged,
    this.showInlineRest = false,
    this.inlineRestRowWidget,
    this.preSetBannerMessage,
    this.onPreSetBannerDismissed,
    this.preSetBannerAnimationKey,
    this.maxVisibleRows = 4,
    this.onJumpToSet,
    this.showcase = false,
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

    // Bodyweight sets legitimately have weight == 0 (no added load), so don't
    // require weight > 0 there — otherwise editing reps on a bodyweight set was
    // silently discarded. For loaded exercises we still require a real weight.
    final isBodyweight = widget.sets[_editingSetIndex!].isBodyweight;
    if (reps > 0 && (weight > 0 || isBodyweight)) {
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
            alignment: AlignmentDirectional.centerEnd,
            padding: const EdgeInsetsDirectional.only(end: 20),
            color: WorkoutDesign.accentBlue,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  AppLocalizations.of(context).buttonDelete,
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

    // Wrap in a SingleChildScrollView so the table can scroll internally when
    // the parent's Expanded budget is smaller than the table's natural height
    // (e.g., 4-set strength block + header + add-set button on phones with
    // tall hydration / thumbnail strips eating bottom real estate). Without
    // this, the table renders past its constraint and Flutter logs a 60px
    // "RenderFlex overflowed by …" error from the parent column.
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
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
      ),
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
        isBodyweight: s.isBodyweight || rawWeight == null || rawWeight <= 0,
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
    final colors = ThemeColors.of(context);
    // Signature column-header: Barlow Condensed, uppercase, tiny + letter-spaced.
    final headerColor = isDark ? AppColors.textMuted : Colors.grey.shade600;
    final TextStyle headerStyle = ZType.lbl(9.5, color: headerColor, letterSpacing: 1.5);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.hairline : Colors.grey.shade200,
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
              AppLocalizations.of(context).workoutSummaryAdvancedSet.toUpperCase(),
              style: headerStyle,
            ),
          ),

          // Previous column (last session data)
          Expanded(
            flex: 3,
            child: Text(
              AppLocalizations.of(context).summaryExerciseTablePrevious.toUpperCase(),
              style: headerStyle,
            ),
          ),

          // TARGET column - AI recommended targets
          Expanded(
            flex: 3,
            child: Text(
              AppLocalizations.of(context).summaryExerciseTableTarget.toUpperCase(),
              style: ZType.lbl(9.5, color: colors.accent, letterSpacing: 1.5),
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
                      color: headerColor,
                    ),
                  if (widget.onToggleUnit != null)
                    const SizedBox(width: 2),
                  Text(
                    _unit.toUpperCase(),
                    style: headerStyle,
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
                    AppLocalizations.of(context).setTrackingTableLeft.toUpperCase(),
                    style: ZType.lbl(10, color: headerColor, letterSpacing: 1.5),
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
                    AppLocalizations.of(context).setTrackingTableRight.toUpperCase(),
                    style: ZType.lbl(10, color: headerColor, letterSpacing: 1.5),
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
                (_isTimedExercise ? 'Time' : 'Reps').toUpperCase(),
                style: headerStyle,
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(width: 4),

          // RIR column header
          SizedBox(
            width: 26,
            child: Text(
              'RIR',
              style: ZType.lbl(9, color: headerColor, letterSpacing: 1.2),
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
                    ? const Color(0xFF5BE49B)
                    : headerColor,
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

  Future<void> _showRpePicker(BuildContext context, int setIndex) async {
    // Lazy import via showModalBottomSheet — keeps the existing import block
    // untouched and zero-risk to compile. RpePill itself is built but its
    // _RpePicker is private; we re-render the same 3×3 grid here inline so
    // the same UX ships without exposing the private widget.
    const grid = [
      [6.0, 6.5, 7.0],
      [7.5, 8.0, 8.5],
      [9.0, 9.5, 10.0],
    ];
    String hint(double rpe) {
      if (rpe <= 6.0) return 'Very light';
      if (rpe <= 6.5) return 'Light';
      if (rpe <= 7.0) return 'Easy';
      if (rpe <= 7.5) return 'Moderate';
      if (rpe <= 8.0) return '2 reps left';
      if (rpe <= 8.5) return '1–2 reps left';
      if (rpe <= 9.0) return '1 rep left';
      if (rpe <= 9.5) return 'Just made it';
      return 'Failure';
    }
    double selected = 8.0;
    final picked = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (innerCtx, setStateLocal) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(innerCtx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text('RPE — set ${setIndex + 1}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(hint(selected),
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(innerCtx).colorScheme.onSurface.withValues(alpha: 0.65),
                      )),
                  const SizedBox(height: 12),
                  for (final row in grid)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: row.map((rpe) {
                          final isSel = (rpe - selected).abs() < 0.01;
                          return ChoiceChip(
                            label: Text(
                              rpe.toStringAsFixed(rpe == rpe.roundToDouble() ? 0 : 1),
                            ),
                            selected: isSel,
                            onSelected: (_) => setStateLocal(() => selected = rpe),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetCtx, selected),
                      child: Text(AppLocalizations.of(context).buttonSave),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
    if (picked != null) {
      // RIR = 10 - RPE (industry convention; clamped to int).
      final rirEstimate = (10 - picked).round().clamp(0, 5);
      widget.onRpeLogged?.call(setIndex, picked, rirEstimate);
    }
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
      // Phase 2.D: long-press a completed set to log RPE/RIR. Kept off the
      // primary tap so the existing edit-weight flow isn't shadowed. The
      // pill UI for inline rendering lives in rpe_pill.dart — long-press
      // surfaces the same picker without touching this 1100-line layout.
      onLongPress: set.isCompleted && widget.onRpeLogged != null
          ? () => _showRpePicker(context, index)
          : null,
      child: Container(
        height: WorkoutDesign.setRowHeight,
        // Active row gets a 3px accent LEFT border; the 9px left padding (vs
        // 12px) compensates so cell content keeps its alignment. Every row
        // sits on a 1px bottom hairline — no boxed/tinted cards.
        padding: EdgeInsets.only(left: isActive ? 9 : 12, right: 12),
        decoration: BoxDecoration(
          border: Border(
            left: isActive
                ? BorderSide(color: ThemeColors.of(context).accent, width: 3)
                : BorderSide.none,
            bottom: BorderSide(
              color: isDark ? AppColors.hairline : Colors.grey.shade200,
              width: 1,
            ),
          ),
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
                // Trend pill / Edited chip plumbing — passes through the
                // optional fields on SetRowData. Existing callers that don't
                // yet supply these get the safe defaults (PO=true, no edit).
                progressiveOverloadEnabled: set.progressiveOverloadEnabled,
                isEdited: set.isEdited,
                isDeload: set.isDeload,
                isFirstSetEver: set.isFirstSetEver,
                previousSetTargetWeight: set.previousSetTargetWeight,
                previousSetTargetReps: set.previousSetTargetReps,
                previousSetTargetSeconds: set.previousSetTargetSeconds,
                isEasyMode: set.isEasyMode,
                isAmrap: set.isAmrap,
                actualRir: set.actualRir,
                setType: set.setType,
              ),
            ),

            // Weight input. Timed exercises (planks/holds/walks) have no weight
            // row — the reps cell becomes a time target — so they keep an inert
            // `_DashCell`. Bodyweight exercises now show an OPTIONAL, editable
            // weight field (placeholder "–") so users can log added/loaded
            // weight on a bodyweight move (weighted vest, dumbbell, etc.)
            // instead of a dead dash they couldn't tap.
            SizedBox(
              width: widget.isLeftRightMode ? 56 : 64,
              child: set.isTimedExercise
                  ? const _DashCell()
                  : (isEditing
                      ? _DarkInputField(
                          controller: _editWeightController!,
                          onSubmitted: (_) => _saveEditing(),
                          isDark: isDark,
                          hintText: set.isBodyweight ? '–' : null,
                        )
                      : isActive
                          ? _DarkInputField(
                              controller: widget.weightController,
                              isDark: isDark,
                              hintText: set.isBodyweight ? '–' : null,
                            )
                          : _CompletedValueCell(
                              value: set.actualWeight != null && set.actualWeight! > 0
                                  ? (widget.useKg
                                          ? set.actualWeight!
                                          : kgToDisplayLbs(set.actualWeight!, widget.exercise.equipment,
                    exerciseName: widget.exercise.name,))
                                      .toStringAsFixed(0)
                                  : (set.isBodyweight ? '–' : ''),
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
      // Signature "+ ADD SET" affordance — a hairline-led row, no boxed card.
      // Barlow Condensed uppercase, letter-spaced, in the reserved accent.
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.hairline : Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              size: 18,
              color: accentColor,
            ),
            const SizedBox(width: 7),
            Text(
              AppLocalizations.of(context).setTrackingTableAddSet.toUpperCase(),
              style: ZType.lbl(11, color: accentColor, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}
