/// Set tracking overlay widget
///
/// Displays the set tracking table during active workout.
/// Hevy/Gravl-inspired design with inline editing and single CTA.
/// Features:
/// - LAST column: Previous session weight × reps (tappable to auto-fill)
/// - TARGET column: AI-recommended weight × reps
/// - Set type labels: DROP SET, FAILURE, WARMUP above rows when AI recommends
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/default_weights.dart';
import '../../../data/models/exercise.dart';
import '../../../widgets/glass_sheet.dart';
import '../models/workout_state.dart';
import 'enhanced_notes_sheet.dart';
import 'exercise_analytics_page.dart';
import 'inline_rest_row.dart';
import 'number_input_widgets.dart';
import 'set_tracking_sheets.dart' as sheets;

part 'set_tracking_overlay_ui_1.dart';
part 'set_tracking_overlay_ui_2.dart';


/// Set tracking overlay for logging sets during workout
class SetTrackingOverlay extends StatefulWidget {
  /// Current exercise being tracked
  final WorkoutExercise exercise;

  /// Index of exercise being viewed (may differ from current)
  final int viewingExerciseIndex;

  /// Index of current exercise
  final int currentExerciseIndex;

  /// Total exercises count
  final int totalExercises;

  /// Total sets for this exercise
  final int totalSets;

  /// List of completed sets for this exercise
  final List<SetLog> completedSets;

  /// Previous session sets for comparison (LAST column)
  final List<Map<String, dynamic>> previousSets;

  /// Whether using kg or lbs
  final bool useKg;

  /// Weight input controller
  final TextEditingController weightController;

  /// Reps input controller
  final TextEditingController repsController;

  /// Whether active row is expanded (kept for compatibility)
  final bool isActiveRowExpanded;

  /// Index of just-completed set for animation
  final int? justCompletedSetIndex;

  /// Whether done button is pressed
  final bool isDoneButtonPressed;

  /// Callback to toggle row expansion (kept for compatibility)
  final VoidCallback onToggleRowExpansion;

  /// Callback to complete current set
  final VoidCallback onCompleteSet;

  /// Callback to toggle unit (kg/lbs)
  final VoidCallback onToggleUnit;

  /// Callback to close overlay
  final VoidCallback onClose;

  /// Callback to navigate to previous exercise
  final VoidCallback? onPreviousExercise;

  /// Callback to navigate to next exercise
  final VoidCallback? onNextExercise;

  /// Callback when add set is pressed
  final VoidCallback onAddSet;

  /// Callback to go back to current exercise
  final VoidCallback onBackToCurrentExercise;

  /// Callback to edit a completed set (opens dialog - fallback)
  final void Function(int setIndex) onEditSet;

  /// Callback to update a completed set inline (weight, reps)
  final void Function(int setIndex, double weight, int reps)? onUpdateSet;

  /// Callback to delete a completed set
  final void Function(int setIndex) onDeleteSet;

  /// Callback to quick-complete a set by tapping the set number
  /// Pass the setIndex and whether to complete (true) or uncomplete (false)
  final void Function(int setIndex, bool complete)? onQuickCompleteSet;

  /// Callback for done button press down
  final VoidCallback onDoneButtonPressDown;

  /// Callback for done button press up
  final VoidCallback onDoneButtonPressUp;

  /// Callback for done button press cancel
  final VoidCallback onDoneButtonPressCancel;

  /// Callback to show number input dialog
  final void Function(TextEditingController controller, bool isDecimal)
      onShowNumberInputDialog;

  /// Callback to skip exercise (optional, for overflow menu)
  final VoidCallback? onSkipExercise;

  /// Callback to open workout plan drawer
  final VoidCallback? onOpenWorkoutPlan;

  /// Callback to open exercise options sheet
  final VoidCallback? onOpenExerciseOptions;

  /// Whether the overlay is minimized (controlled externally)
  final bool isMinimized;

  /// Callback when minimized state changes
  final void Function(bool isMinimized)? onMinimizedChanged;

  /// Last session data for history display
  final Map<String, dynamic>? lastSessionData;

  /// Personal record data for history display
  final Map<String, dynamic>? prData;

  /// Current weight increment value
  final double? currentWeightIncrement;

  /// Callback when weight increment changes
  final void Function(double)? onWeightIncrementChanged;

  /// Current rep progression type for this exercise
  final String? currentProgressionType;

  /// Callback to open rep progression picker
  final VoidCallback? onOpenProgressionPicker;

  /// Callback to edit target (Auto column) for a set
  final void Function(int setIndex, double? weight, int reps, int? rir)? onEditTarget;

  // ========== Inline Rest Row Props ==========

  /// Whether to show inline rest row (between completed and active set)
  final bool showInlineRest;

  /// Remaining rest time in seconds
  final int restTimeRemaining;

  /// Total rest duration in seconds (for progress calculation)
  final int restDurationTotal;

  /// Callback when rest timer completes
  final VoidCallback? onRestComplete;

  /// Callback when user skips rest
  final VoidCallback? onSkipRest;

  /// Callback when user adjusts time (+/- seconds)
  final void Function(int adjustment)? onAdjustTime;

  /// Callback when user rates the set (RPE 1-10)
  final void Function(int rpe)? onRateRpe;

  /// Callback when user adds a note
  final void Function(String note)? onAddSetNote;

  /// Current RPE value (null if not rated yet)
  final int? currentRpe;

  /// Achievement prompt to display during rest
  final String? achievementPrompt;

  /// AI-generated tip to display during rest
  final String? aiTip;

  /// Whether AI tip is loading
  final bool isLoadingAiTip;

  const SetTrackingOverlay({
    super.key,
    required this.exercise,
    required this.viewingExerciseIndex,
    required this.currentExerciseIndex,
    required this.totalExercises,
    required this.totalSets,
    required this.completedSets,
    required this.previousSets,
    required this.useKg,
    required this.weightController,
    required this.repsController,
    required this.isActiveRowExpanded,
    required this.justCompletedSetIndex,
    required this.isDoneButtonPressed,
    required this.onToggleRowExpansion,
    required this.onCompleteSet,
    required this.onToggleUnit,
    required this.onClose,
    this.onPreviousExercise,
    this.onNextExercise,
    required this.onAddSet,
    required this.onBackToCurrentExercise,
    required this.onEditSet,
    this.onUpdateSet,
    required this.onDeleteSet,
    this.onQuickCompleteSet,
    required this.onDoneButtonPressDown,
    required this.onDoneButtonPressUp,
    required this.onDoneButtonPressCancel,
    required this.onShowNumberInputDialog,
    this.onSkipExercise,
    this.onOpenWorkoutPlan,
    this.onOpenExerciseOptions,
    this.isMinimized = false,
    this.onMinimizedChanged,
    this.lastSessionData,
    this.prData,
    this.currentWeightIncrement,
    this.onWeightIncrementChanged,
    this.currentProgressionType,
    this.onOpenProgressionPicker,
    this.onEditTarget,
    this.showInlineRest = false,
    this.restTimeRemaining = 0,
    this.restDurationTotal = 120,
    this.onRestComplete,
    this.onSkipRest,
    this.onAdjustTime,
    this.onRateRpe,
    this.onAddSetNote,
    this.currentRpe,
    this.achievementPrompt,
    this.aiTip,
    this.isLoadingAiTip = false,
  });

  @override
  State<SetTrackingOverlay> createState() => _SetTrackingOverlayState();
}

class _SetTrackingOverlayState extends State<SetTrackingOverlay> {
  /// Current set type: null = working set, 'W' = warmup, 'D' = drop set, 'F' = failure
  String? _currentSetType;

  /// Whether warmup section is collapsed
  bool _isWarmupCollapsed = false;

  /// Notes text controller
  final TextEditingController _notesController = TextEditingController();

  /// Focus node for notes
  final FocusNode _notesFocusNode = FocusNode();

  /// Index of completed set being edited inline (null = not editing)
  int? _editingSetIndex;

  /// Controllers for inline editing of completed sets
  TextEditingController? _editWeightController;
  TextEditingController? _editRepsController;

  /// Selected weight increment
  late double _selectedIncrement;

  // Weight increment options in kg
  static const List<double> _kgIncrements = [1.0, 1.25, 2.5, 5.0, 10.0];
  // Weight increment options in lbs
  static const List<double> _lbsIncrements = [2.5, 5.0, 10.0, 15.0, 20.0];

  List<double> get _incrementOptions =>
      widget.useKg ? _kgIncrements : _lbsIncrements;

  String get _unit => widget.useKg ? 'kg' : 'lbs';

  bool get isViewingCurrent => widget.viewingExerciseIndex == widget.currentExerciseIndex;
  int get currentSetIndex => widget.completedSets.length;
  bool get allSetsCompleted => widget.completedSets.length >= widget.totalSets;

  @override
  void initState() {
    super.initState();
    _selectedIncrement = widget.currentWeightIncrement ??
        (widget.useKg ? 2.5 : 5.0);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _notesFocusNode.dispose();
    _editWeightController?.dispose();
    _editRepsController?.dispose();
    super.dispose();
  }

  /// Start inline editing for a completed set
  void _startEditingSet(int index) {
    final setData = widget.completedSets[index];
    final displayWeight = widget.useKg
        ? setData.weight
        : kgToDisplayLbs(setData.weight, widget.exercise.equipment,
                exerciseName: widget.exercise.name,);

    setState(() {
      _editingSetIndex = index;
      _editWeightController?.dispose();
      _editRepsController?.dispose();
      _editWeightController = TextEditingController(
        text: displayWeight.toStringAsFixed(0),
      );
      _editRepsController = TextEditingController(
        text: setData.reps.toString(),
      );
    });
  }

  /// Save inline edits and close editing mode
  void _saveEditingSet() {
    if (_editingSetIndex == null) return;

    final newWeight = double.tryParse(_editWeightController?.text ?? '') ?? 0;
    final newReps = int.tryParse(_editRepsController?.text ?? '') ?? 0;

    if (newWeight > 0 && newReps > 0) {
      // Convert back to kg if displaying in lbs
      final weightInKg = widget.useKg ? newWeight : newWeight / 2.20462;

      // Update the completed set via callback
      if (widget.onUpdateSet != null) {
        widget.onUpdateSet!(_editingSetIndex!, weightInKg, newReps);
      }
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _editingSetIndex = null;
      _editWeightController?.dispose();
      _editRepsController?.dispose();
      _editWeightController = null;
      _editRepsController = null;
    });
  }

  /// Cancel inline editing
  void _cancelEditingSet() {
    setState(() {
      _editingSetIndex = null;
      _editWeightController?.dispose();
      _editRepsController?.dispose();
      _editWeightController = null;
      _editRepsController = null;
    });
  }

  // _showTargetEditSheet, _getTargetRirColor, _getTargetRirTextColor
  // moved to set_tracking_sheets.dart

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Full screen layout - no floating card, no blur
    return Container(
      color: isDark ? AppColors.pureBlack : Colors.grey.shade50,
      child: Column(
        children: [
          // Header with exercise name and overflow menu
          _buildHeader(context, isDark, textPrimary, textMuted),

          // Quick stats row (History, Analytics, Increment) - Hevy style
          _buildQuickStatsRow(isDark, textPrimary, textMuted),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Table header
                  _buildTableHeader(isDark, textMuted),

                  // Set type tags row with + Set button (only shown when viewing current exercise)
                  if (isViewingCurrent && !allSetsCompleted)
                    _buildSetTypeTagsWithAddButton(isDark, textMuted),

                  // Warmup section header with collapse toggle
                  _buildSectionHeader(
                    title: 'Warmup sets',
                    isCollapsed: _isWarmupCollapsed,
                    onToggle: () {
                      setState(() => _isWarmupCollapsed = !_isWarmupCollapsed);
                      HapticFeedback.selectionClick();
                    },
                    isDark: isDark,
                    textMuted: textMuted,
                  ),

                  // Warmup set row (collapsible)
                  if (!_isWarmupCollapsed)
                    _buildWarmupRow(context, isDark, textPrimary, textMuted),

                  // Effective sets section header
                  _buildSectionHeader(
                    title: 'Effective sets',
                    isDark: isDark,
                    textMuted: textMuted,
                  ),

                  // Working set rows with inline rest row
                  ..._buildSetRowsWithInlineRest(context, isDark, textPrimary, textMuted),

                  // Complete Set button (only CTA)
                  if (isViewingCurrent && !allSetsCompleted)
                    _buildCompleteSetButton(isDark),

                  // Back to current or rest info
                  if (!isViewingCurrent)
                    _buildBackToCurrentButton(isDark, textMuted),

                  // Notes section
                  _buildNotesSection(isDark, textMuted),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutPlanButton(bool isDark, Color textMuted) {
    return GestureDetector(
      onTap: () {
        widget.onOpenWorkoutPlan?.call();
        HapticFeedback.selectionClick();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.list_alt_rounded,
          color: AppColors.purple,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildExerciseOptionsButton(bool isDark, Color textMuted) {
    return GestureDetector(
      onTap: () {
        widget.onOpenExerciseOptions?.call();
        HapticFeedback.selectionClick();
      },
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.more_vert_rounded,
          color: textMuted,
          size: 20,
        ),
      ),
    );
  }

  /// Quick stats row with buttons for Analytics, Weight Increment, and Options (Hevy-style)
  Widget _buildQuickStatsRow(bool isDark, Color textPrimary, Color textMuted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          // Analytics button - opens full page
          Expanded(
            child: _buildQuickStatButton(
              icon: Icons.analytics_outlined,
              label: 'Analytics',
              value: widget.prData != null ? 'View PR' : 'View',
              color: AppColors.success,
              isDark: isDark,
              textMuted: textMuted,
              onTap: () => sheets.openExerciseAnalyticsPage(
              context: context,
              exercise: widget.exercise,
              useKg: widget.useKg,
              lastSessionData: widget.lastSessionData,
              prData: widget.prData,
            ),
            ),
          ),
          const SizedBox(width: 10),
          // Weight Increment button
          Expanded(
            child: _buildQuickStatButton(
              icon: Icons.tune_rounded,
              label: 'Increment',
              value: '${_selectedIncrement.toStringAsFixed(_selectedIncrement % 1 == 0 ? 0 : 1)} $_unit',
              color: AppColors.orange,
              isDark: isDark,
              textMuted: textMuted,
              onTap: () => sheets.showWeightIncrementSheet(
              context: context,
              isDark: isDark,
              textPrimary: textPrimary,
              textMuted: textMuted,
              useKg: widget.useKg,
              selectedIncrement: _selectedIncrement,
              incrementOptions: _incrementOptions,
              onSelect: (inc) {
                setState(() => _selectedIncrement = inc);
                widget.onWeightIncrementChanged?.call(inc);
              },
            ),
            ),
          ),
          // Progression button (beside increment)
          if (widget.onOpenProgressionPicker != null) ...[
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickStatButton(
                icon: Icons.trending_up_rounded,
                label: 'Progression',
                value: widget.currentProgressionType ?? 'Straight',
                color: AppColors.purple,
                isDark: isDark,
                textMuted: textMuted,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onOpenProgressionPicker?.call();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: enabled
          ? () {
              onTap?.call();
              HapticFeedback.selectionClick();
            }
          : null,
      child: Container(
        // WCAG accessibility: 48px minimum touch targets
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: enabled
              ? (isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 28,
          color: enabled
              ? (isDark ? Colors.white : AppColorsLight.textPrimary)
              : (isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.15)),
        ),
      ),
    );
  }


  Widget _buildSetTypeTag(String tag, String label, Color color, bool isDark, Color textMuted, [bool isCompact = false]) {
    final isSelected = _currentSetType == tag;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_currentSetType == tag) {
            _currentSetType = null; // Deselect if already selected
          } else {
            _currentSetType = tag;
            // Auto-adjust values based on set type
            _applySetTypeDefaults(tag);
          }
        });
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 12,
          vertical: isCompact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontSize: isCompact ? 11 : 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? color : textMuted,
          ),
        ),
      ),
    );
  }

  /// Apply default values when selecting a set type
  void _applySetTypeDefaults(String type) {
    final currentWeight = double.tryParse(widget.weightController.text) ?? 0;

    switch (type) {
      case 'W': // Warmup - 50% of current weight
        if (currentWeight > 0) {
          widget.weightController.text = (currentWeight * 0.5).toStringAsFixed(0);
        }
        break;
      case 'D': // Drop set - 80% of current weight (20% reduction)
        if (currentWeight > 0) {
          widget.weightController.text = (currentWeight * 0.8).toStringAsFixed(0);
        }
        break;
      case 'F': // Failure - keep same weight
        // No change to weight
        break;
    }
  }

  /// Show enhanced notes editing dialog with audio, photo, and voice-to-text
  void _showNotesDialog(bool isDark) {
    showEnhancedNotesSheet(
      context,
      initialNotes: _notesController.text,
      onSave: (notes, audioPath, photoPaths) {
        setState(() {
          _notesController.text = notes;
          // Audio and photo paths can be stored in exercise metadata if needed
          // For now, we just update the text notes
        });
      },
    );
  }

  /// Build set rows with inline rest row inserted between completed and active sets
  List<Widget> _buildSetRowsWithInlineRest(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    final widgets = <Widget>[];
    final completedCount = widget.completedSets.length;

    debugPrint('🔵 [InlineRest] showInlineRest=${widget.showInlineRest}, completedCount=$completedCount, totalSets=${widget.totalSets}, isViewingCurrent=$isViewingCurrent');

    for (int index = 0; index < widget.totalSets; index++) {
      // Add the set row
      widgets.add(_buildSetRow(context, index, isDark, textPrimary, textMuted));

      // Insert inline rest row after the last completed set (before the active set)
      // Only show when resting and viewing current exercise
      if (widget.showInlineRest &&
          isViewingCurrent &&
          index == completedCount - 1 &&
          completedCount < widget.totalSets) {
        debugPrint('🟢 [InlineRest] SHOWING inline rest row after set index $index');
        widgets.add(_buildInlineRestRow(isDark));
      }
    }

    return widgets;
  }

  /// Build the inline rest row widget
  Widget _buildInlineRestRow(bool isDark) {
    return InlineRestRow(
      restDurationSeconds: widget.restDurationTotal,
      onRestComplete: widget.onRestComplete ?? () {},
      onSkipRest: widget.onSkipRest ?? () {},
      onAdjustTime: widget.onAdjustTime ?? (_) {},
      onRateSet: widget.onRateRpe ?? (_) {},
      onAddNote: widget.onAddSetNote ?? (_) {},
      onShowRpeInfo: () => sheets.showRpeInfoSheet(context),
      achievementPrompt: widget.achievementPrompt,
      aiTip: widget.aiTip,
      isLoadingAiTip: widget.isLoadingAiTip,
      currentRpe: widget.currentRpe,
    );
  }

  /// Hevy-style inline editable input - direct text field in table
  Widget _buildTappableInput({
    required TextEditingController controller,
    required bool isDecimal,
    required bool isDark,
    required Color textPrimary,
    Color? accentColor,
  }) {
    final color = accentColor ?? AppColors.electricBlue;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? color.withOpacity(0.12)
            : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          isDense: true,
        ),
        onTap: () => HapticFeedback.selectionClick(),
      ),
    );
  }

  Widget _buildPendingIndicator(Color textMuted) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: textMuted.withOpacity(0.2),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildCompleteSetButton(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: GestureDetector(
        onTapDown: (_) => widget.onDoneButtonPressDown(),
        onTapUp: (_) => widget.onDoneButtonPressUp(),
        onTapCancel: widget.onDoneButtonPressCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: double.infinity,
          height: widget.isDoneButtonPressed ? 52 : 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.electricBlue,
            boxShadow: [
              BoxShadow(
                color: AppColors.electricBlue.withOpacity(widget.isDoneButtonPressed ? 0.4 : 0.25),
                blurRadius: widget.isDoneButtonPressed ? 16 : 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_rounded, size: 24, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'Complete Set ${currentSetIndex + 1}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build + Set button (after reps column, swipe to delete individual sets)
  Widget _buildSetModifierButtons(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Add Set button only - swipe left on any set to delete
          _buildSetModifierButton(
            icon: Icons.add_circle_outline,
            label: '+ Set',
            color: AppColors.electricBlue,
            isDark: isDark,
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onAddSet();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackToCurrentButton(bool isDark, Color textMuted) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: GestureDetector(
        onTap: () {
          widget.onBackToCurrentExercise();
          HapticFeedback.selectionClick();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
            border: Border.all(
              color: AppColors.electricBlue.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.keyboard_return,
                  size: 20, color: AppColors.electricBlue),
              const SizedBox(width: 10),
              Text(
                'Back to Current Exercise',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.electricBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
