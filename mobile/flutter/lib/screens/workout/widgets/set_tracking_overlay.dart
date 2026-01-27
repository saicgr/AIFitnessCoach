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
import '../../../data/models/exercise.dart';
import '../models/workout_state.dart';
import 'exercise_analytics_page.dart';
import 'inline_rest_row.dart';
import 'number_input_widgets.dart';

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
        : setData.weight * 2.20462;

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

  /// Show sheet to edit target (Auto column) for a set
  void _showTargetEditSheet(int setIndex) {
    final exercise = widget.exercise;
    final existingTarget = exercise.getTargetForSet(setIndex + 1); // 1-indexed
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final weightController = TextEditingController(
      text: existingTarget?.targetWeightKg?.toStringAsFixed(0) ?? '',
    );
    final repsController = TextEditingController(
      text: existingTarget?.targetReps.toString() ?? '8',
    );
    int selectedRir = existingTarget?.targetRir ?? 2;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 16,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Set Target',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Weight & Reps inputs
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: widget.useKg ? 'Weight (kg)' : 'Weight (lbs)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: repsController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Reps',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // RIR selector label
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Target RIR',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // RIR selector pills (5 to 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (i) {
                  final rir = 5 - i; // 5, 4, 3, 2, 1, 0
                  final isSelected = selectedRir == rir;
                  return GestureDetector(
                    onTap: () {
                      setSheetState(() => selectedRir = rir);
                      HapticFeedback.selectionClick();
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getTargetRirColor(rir)
                            : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.15)),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.15)
                                    : Colors.grey.withOpacity(0.3),
                              ),
                      ),
                      child: Center(
                        child: Text(
                          '$rir',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? _getTargetRirTextColor(rir)
                                : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    // Convert weight to kg if using lbs
                    final weightValue = double.tryParse(weightController.text);
                    final weightInKg = weightValue != null && !widget.useKg
                        ? weightValue / 2.20462
                        : weightValue;
                    widget.onEditTarget?.call(
                      setIndex,
                      weightInKg,
                      int.tryParse(repsController.text) ?? 8,
                      selectedRir,
                    );
                    HapticFeedback.mediumImpact();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Target',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Get RIR color for target edit sheet
  Color _getTargetRirColor(int rir) {
    if (rir <= 0) return const Color(0xFFEF4444); // Red - failure
    if (rir == 1) return const Color(0xFFF97316); // Orange
    if (rir == 2) return const Color(0xFFEAB308); // Yellow
    return const Color(0xFF22C55E); // Green for 3+
  }

  /// Get RIR text color for contrast
  Color _getTargetRirTextColor(int rir) {
    if (rir == 2) return Colors.black87; // Dark text on yellow
    return Colors.white;
  }

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

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.elevated.withOpacity(0.5)
            : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
          ),
        ),
      ),
      child: Row(
          children: [
            // Previous exercise button
            _buildNavButton(
              icon: Icons.chevron_left,
              enabled: widget.viewingExerciseIndex > 0,
              onTap: widget.onPreviousExercise,
              isDark: isDark,
            ),

            const SizedBox(width: 12),

            // Exercise name and position
            Expanded(
              child: Column(
                children: [
                  Text(
                    widget.exercise.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  // Wrap in Flexible to prevent overflow
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        '${widget.viewingExerciseIndex + 1} of ${widget.totalExercises}',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!isViewingCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.viewingExerciseIndex < widget.currentExerciseIndex
                                ? 'DONE'
                                : 'UPCOMING',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.orange,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Next exercise button
            _buildNavButton(
              icon: Icons.chevron_right,
              enabled: widget.viewingExerciseIndex < widget.totalExercises - 1,
              onTap: widget.onNextExercise,
              isDark: isDark,
            ),

            const SizedBox(width: 8),

            // Open workout plan button
            if (widget.onOpenWorkoutPlan != null)
              _buildWorkoutPlanButton(isDark, textMuted),

            // 3-dot menu button for exercise options
            if (widget.onOpenExerciseOptions != null)
              _buildExerciseOptionsButton(isDark, textMuted),
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
              onTap: () => _openAnalyticsPage(context),
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
              onTap: () => _showWeightIncrementSheet(isDark, textPrimary, textMuted),
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

  /// Open full analytics page
  void _openAnalyticsPage(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExerciseAnalyticsPage(
          exercise: widget.exercise,
          useKg: widget.useKg,
          lastSessionData: widget.lastSessionData,
          prData: widget.prData,
        ),
      ),
    );
  }

  Widget _buildQuickStatButton({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required Color textMuted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show history bottom sheet
  void _showHistorySheet(bool isDark, Color textPrimary, Color textMuted) {
    // Format last session data
    String lastDisplay = 'No previous data';
    String lastDate = '';
    if (widget.lastSessionData != null) {
      final weight = widget.lastSessionData!['weight'] as double?;
      final reps = widget.lastSessionData!['reps'] as int?;
      final date = widget.lastSessionData!['date'] as String?;
      if (weight != null && reps != null) {
        final displayWeight = widget.useKg ? weight : weight * 2.20462;
        lastDisplay = '${displayWeight.toStringAsFixed(0)} $_unit × $reps reps';
        if (date != null) {
          lastDate = date;
        }
      }
    }

    // Format PR data
    String prDisplay = 'No PR yet';
    if (widget.prData != null) {
      final weight = widget.prData!['weight'] as double?;
      final reps = widget.prData!['reps'] as int?;
      if (weight != null && reps != null) {
        final displayWeight = widget.useKg ? weight : weight * 2.20462;
        prDisplay = '${displayWeight.toStringAsFixed(0)} $_unit × $reps reps';
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              children: [
                Icon(Icons.history_rounded, color: AppColors.electricBlue, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Exercise History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Last session
            _buildHistoryItem(
              label: 'Last Session',
              value: lastDisplay,
              subtitle: lastDate.isNotEmpty ? lastDate : null,
              color: AppColors.electricBlue,
              isDark: isDark,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
            const SizedBox(height: 16),

            // Personal Record
            _buildHistoryItem(
              label: 'Personal Record',
              value: prDisplay,
              color: AppColors.success,
              isDark: isDark,
              textPrimary: textPrimary,
              textMuted: textMuted,
              showTrophy: widget.prData != null,
            ),

            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem({
    required String label,
    required String value,
    String? subtitle,
    required Color color,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    bool showTrophy = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              showTrophy ? Icons.emoji_events_rounded : Icons.fitness_center_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show analytics bottom sheet
  void _showAnalyticsSheet(bool isDark, Color textPrimary, Color textMuted) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: AppColors.success, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Exercise Analytics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Coming soon placeholder
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.08),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.show_chart_rounded,
                    size: 48,
                    color: textMuted.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Progress Charts Coming Soon',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your strength gains over time',
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  /// Show weight increment picker sheet
  void _showWeightIncrementSheet(bool isDark, Color textPrimary, Color textMuted) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      enableDrag: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar (draggable indicator)
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title with close button
            Row(
              children: [
                Icon(Icons.tune_rounded, color: AppColors.orange, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weight Increment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Amount to adjust weight by',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Increment options
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _incrementOptions.map((increment) {
                final isSelected = _selectedIncrement == increment;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedIncrement = increment);
                    widget.onWeightIncrementChanged?.call(increment);
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.orange.withOpacity(0.2)
                          : (isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.05)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.orange
                            : (isDark
                                ? Colors.white.withOpacity(0.15)
                                : Colors.black.withOpacity(0.1)),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '${increment.toStringAsFixed(increment % 1 == 0 ? 0 : 2)} $_unit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? AppColors.orange
                            : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
          ],
        ),
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

  Widget _buildTableHeader(bool isDark, Color textMuted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
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
          const SizedBox(
            width: 36,
            child: Text(
              'SET',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // LAST column - previous session data
          Expanded(
            flex: 3,
            child: Text(
              'LAST',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // TARGET column - AI recommended
          Expanded(
            flex: 3,
            child: Text(
              'TARGET',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.purple.withOpacity(0.9),
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Weight input column with unit toggle
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () {
                widget.onToggleUnit();
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.useKg ? 'KG' : 'LBS',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.electricBlue,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          // Reps input column
          const Expanded(
            flex: 2,
            child: Text(
              'REPS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.electricBlue,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 36), // Space for checkmark
        ],
      ),
    );
  }

  /// Build set type tags row with + Set button (W/D/F + Add)
  Widget _buildSetTypeTagsWithAddButton(bool isDark, Color textMuted) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Use compact mode on narrow screens
    final isCompact = screenWidth < 340;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: isCompact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.elevated.withOpacity(0.3)
            : Colors.grey.shade100.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.04),
          ),
        ),
      ),
      child: Row(
        children: [
          // Set type label - hide on very compact screens
          if (!isCompact) ...[
            Text(
              'Set Type:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Tag buttons
          _buildSetTypeTag('W', 'Warmup', AppColors.orange, isDark, textMuted, isCompact),
          SizedBox(width: isCompact ? 4 : 6),
          _buildSetTypeTag('D', 'Drop Set', AppColors.purple, isDark, textMuted, isCompact),
          SizedBox(width: isCompact ? 4 : 6),
          _buildSetTypeTag('F', 'Failure', AppColors.error, isDark, textMuted, isCompact),

          SizedBox(width: isCompact ? 4 : 8),

          // Info button (right after set types)
          GestureDetector(
            onTap: () => _showSetTypeInfoSheet(context),
            child: Container(
              width: isCompact ? 24 : 28,
              height: isCompact ? 24 : 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                size: isCompact ? 14 : 16,
                color: textMuted,
              ),
            ),
          ),

          const Spacer(),

          // + Set button (at the end)
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onAddSet();
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 10,
                vertical: isCompact ? 4 : 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.electricBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.electricBlue.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: isCompact ? 14 : 16,
                    color: AppColors.electricBlue,
                  ),
                  SizedBox(width: isCompact ? 2 : 4),
                  Text(
                    'Set',
                    style: TextStyle(
                      fontSize: isCompact ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.electricBlue,
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

  /// Build set type tags row (W/D/F) - legacy, replaced by _buildSetTypeTagsWithAddButton
  Widget _buildSetTypeTags(bool isDark, Color textMuted) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Use compact mode on narrow screens
    final isCompact = screenWidth < 340;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: isCompact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.elevated.withOpacity(0.3)
            : Colors.grey.shade100.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.04),
          ),
        ),
      ),
      child: Row(
        children: [
          // Set type label - hide on very compact screens
          if (!isCompact) ...[
            Text(
              'Set Type:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
            const SizedBox(width: 12),
          ],
          // Tag buttons with flexible spacing
          Expanded(
            child: Row(
              mainAxisAlignment: isCompact ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.start,
              children: [
                _buildSetTypeTag('W', 'Warmup', AppColors.orange, isDark, textMuted, isCompact),
                SizedBox(width: isCompact ? 4 : 8),
                _buildSetTypeTag('D', 'Drop Set', AppColors.purple, isDark, textMuted, isCompact),
                SizedBox(width: isCompact ? 4 : 8),
                _buildSetTypeTag('F', 'Failure', AppColors.error, isDark, textMuted, isCompact),
              ],
            ),
          ),
          SizedBox(width: isCompact ? 4 : 8),
          // Info button
          GestureDetector(
            onTap: () => _showSetTypeInfoSheet(context),
            child: Container(
              width: isCompact ? 24 : 28,
              height: isCompact ? 24 : 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                size: isCompact ? 14 : 16,
                color: textMuted,
              ),
            ),
          ),
        ],
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

  /// Show info sheet explaining set types
  void _showSetTypeInfoSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Set Types',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // Warmup
            _buildSetTypeInfoRow(
              icon: Icons.whatshot_outlined,
              tag: 'W',
              title: 'Warmup',
              description: 'Light weight to prepare muscles. Not counted in workout volume.',
              color: AppColors.orange,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Drop Set
            _buildSetTypeInfoRow(
              icon: Icons.trending_down_rounded,
              tag: 'D',
              title: 'Drop Set',
              description: 'Immediately reduce weight after failure and continue repping. Great for muscle growth!',
              color: AppColors.purple,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Failure
            _buildSetTypeInfoRow(
              icon: Icons.fitness_center_rounded,
              tag: 'F',
              title: 'Failure',
              description: "Mark when you couldn't complete target reps. Helps track intensity.",
              color: AppColors.error,
              isDark: isDark,
            ),

            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSetTypeInfoRow({
    required IconData icon,
    required String tag,
    required String title,
    required String description,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build section header (Hevy-style)
  Widget _buildSectionHeader({
    required String title,
    bool isCollapsed = false,
    VoidCallback? onToggle,
    required bool isDark,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 0.3,
            ),
          ),
          if (onToggle != null)
            GestureDetector(
              onTap: onToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isCollapsed ? 'Show' : 'Hide',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.electricBlue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: isCollapsed ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        size: 14,
                        color: AppColors.electricBlue,
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

  /// Build notes section (Hevy-style)
  Widget _buildNotesSection(bool isDark, Color textMuted) {
    final hasNotes = _notesController.text.isNotEmpty;

    return GestureDetector(
      onTap: () => _showNotesDialog(isDark),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.sticky_note_2_outlined,
              size: 18,
              color: hasNotes ? AppColors.purple : textMuted.withOpacity(0.6),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasNotes ? _notesController.text : 'Tap to add notes...',
                style: TextStyle(
                  fontSize: 13,
                  color: hasNotes
                      ? (isDark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.8))
                      : textMuted.withOpacity(0.6),
                  fontStyle: hasNotes ? FontStyle.normal : FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: textMuted.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  /// Show notes editing dialog
  void _showNotesDialog(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Exercise Notes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (_notesController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() => _notesController.clear());
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes text field
              TextField(
                controller: _notesController,
                focusNode: _notesFocusNode,
                maxLines: 4,
                autofocus: true,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Add notes about form, adjustments, or how this set felt...',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.purple,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Done button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Build warmup set row
  Widget _buildWarmupRow(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    // Calculate warmup weight (50% of target weight for first working set)
    final targetWeight = double.tryParse(widget.weightController.text) ?? widget.exercise.weight ?? 0;
    final warmupWeight = targetWeight * 0.5;
    final warmupReps = 10; // Standard warmup reps

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Warmup row (orange styled - no separate label needed since section header says "Warmup sets")
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.orange.withOpacity(0.06)
                : AppColors.orange.withOpacity(0.04),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.04),
              ),
            ),
          ),
          child: Row(
            children: [
              // Warmup indicator
              SizedBox(
                width: 36,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.orange.withOpacity(0.15),
                  ),
                  child: const Center(
                    child: Text(
                      'W',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                ),
              ),

              // LAST column (empty for warmup)
              Expanded(
                flex: 3,
                child: Text(
                  '—',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // TARGET column - warmup suggestion
              Expanded(
                flex: 3,
                child: Text(
                  warmupWeight > 0 ? '${warmupWeight.toStringAsFixed(0)} × $warmupReps' : '—',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.orange.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Weight column (empty for warmup)
              Expanded(
                flex: 3,
                child: Text(
                  '—',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted.withOpacity(0.4),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Reps column (empty for warmup)
              Expanded(
                flex: 2,
                child: Text(
                  '—',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted.withOpacity(0.4),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Warmup indicator icon
              SizedBox(
                width: 36,
                child: Icon(
                  Icons.whatshot_outlined,
                  size: 16,
                  color: AppColors.orange.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
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
      onShowRpeInfo: _showRpeInfoSheet,
      achievementPrompt: widget.achievementPrompt,
      aiTip: widget.aiTip,
      isLoadingAiTip: widget.isLoadingAiTip,
      currentRpe: widget.currentRpe,
    );
  }

  /// Show RPE info bottom sheet
  void _showRpeInfoSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'What is RPE?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'Rate of Perceived Exertion measures how hard a set felt:',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // RPE scale
            _buildRpeScaleRow('1-4', 'Very easy, lots left in tank', AppColors.success, isDark),
            _buildRpeScaleRow('5-6', 'Moderate effort', AppColors.cyan, isDark),
            _buildRpeScaleRow('7-8', 'Hard, could do 2-3 more reps', AppColors.orange, isDark),
            _buildRpeScaleRow('9', 'Very hard, maybe 1 more rep', AppColors.orange, isDark),
            _buildRpeScaleRow('10', 'Maximum effort, couldn\'t do more', AppColors.error, isDark),

            const SizedBox(height: 24),

            // Got it button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildRpeScaleRow(String range, String description, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              range,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(
    BuildContext context,
    int index,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    final isCompleted = index < widget.completedSets.length;
    final isCurrent = isViewingCurrent && index == widget.completedSets.length;
    final isPending = index > widget.completedSets.length;
    final previousSet = index < widget.previousSets.length ? widget.previousSets[index] : null;
    final isLastSet = index == widget.totalSets - 1;
    final isEditing = _editingSetIndex == index && isCompleted;

    SetLog? completedSetData;
    if (isCompleted) {
      completedSetData = widget.completedSets[index];
    }

    // Format previous session data (LAST column)
    String lastDisplay = '—';
    double? lastWeight;
    int? lastReps;
    if (previousSet != null) {
      lastWeight = previousSet['weight'] as double?;
      lastReps = previousSet['reps'] as int?;
      if (lastWeight != null && lastReps != null) {
        final displayWeight = widget.useKg
            ? lastWeight
            : lastWeight * 2.20462;
        lastDisplay = '${displayWeight.toStringAsFixed(0)} × $lastReps';
      }
    }

    // Format AI target data (TARGET column) - use per-set targets if available
    // Include unit label so user knows if weight is in kg or lbs
    final unit = widget.useKg ? 'kg' : 'lbs';
    String targetDisplay = '—';
    final setTarget = widget.exercise.getTargetForSet(index + 1); // 1-indexed
    if (setTarget != null) {
      // Use per-set AI target (Gravl/Hevy style)
      final targetWeight = setTarget.targetWeightKg;
      final targetReps = setTarget.targetReps;
      if (targetWeight != null && targetWeight > 0) {
        final displayTargetWeight = widget.useKg
            ? targetWeight
            : targetWeight * 2.20462;
        // Show AMRAP for failure/amrap sets
        if (setTarget.isFailure) {
          targetDisplay = '${displayTargetWeight.toStringAsFixed(0)} $unit × AMRAP';
        } else {
          targetDisplay = '${displayTargetWeight.toStringAsFixed(0)} $unit × $targetReps';
        }
      } else if (targetReps > 0) {
        // Bodyweight exercise - just show reps (no weight/unit needed)
        if (setTarget.isFailure) {
          targetDisplay = 'AMRAP';
        } else {
          targetDisplay = '$targetReps reps';
        }
      }
    } else {
      // Fallback to exercise-level target
      final targetWeight = widget.exercise.weight;
      final targetReps = widget.exercise.reps;
      if (targetWeight != null && targetWeight > 0 && targetReps != null) {
        final displayTargetWeight = widget.useKg
            ? targetWeight
            : targetWeight * 2.20462;
        // For failure set, show AMRAP on last set
        if (isLastSet && widget.exercise.isFailureSet == true) {
          targetDisplay = '${displayTargetWeight.toStringAsFixed(0)} $unit × AMRAP';
        } else {
          targetDisplay = '${displayTargetWeight.toStringAsFixed(0)} $unit × $targetReps';
        }
      }
    }

    // Determine set type label from AI targets or exercise-level flags
    String? setTypeLabel;
    Color? setTypeLabelColor;
    String setNumberDisplay = '${index + 1}'; // Default: show set number

    if (setTarget != null) {
      // Use per-set type from AI targets
      final typeLabel = setTarget.setTypeLabel;
      if (typeLabel.isNotEmpty) {
        setNumberDisplay = typeLabel; // W, D, F, A
        if (setTarget.isWarmup) {
          setTypeLabel = 'WARMUP';
          setTypeLabelColor = AppColors.orange;
        } else if (setTarget.isDropSet) {
          setTypeLabel = 'DROP SET';
          setTypeLabelColor = AppColors.purple;
        } else if (setTarget.isFailure) {
          setTypeLabel = 'FAILURE';
          setTypeLabelColor = AppColors.error;
        }
      }
    } else {
      // Fallback to exercise-level flags
      if (widget.exercise.isDropSet == true && isLastSet) {
        setTypeLabel = 'DROP SET';
        setTypeLabelColor = AppColors.purple;
      } else if (widget.exercise.isFailureSet == true && isLastSet) {
        setTypeLabel = 'FAILURE';
        setTypeLabelColor = AppColors.error;
      }
    }

    // Build the set type label widget if needed
    Widget? setTypeLabelWidget;
    if (setTypeLabel != null && setTypeLabelColor != null && isCurrent) {
      setTypeLabelWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        margin: const EdgeInsets.only(left: 44, bottom: 4, top: 4),
        decoration: BoxDecoration(
          color: setTypeLabelColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          setTypeLabel,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: setTypeLabelColor,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    final rowWidget = Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: (isCurrent || isEditing) ? 14 : 10),
      decoration: BoxDecoration(
        color: isEditing
            ? AppColors.orange.withOpacity(0.15)
            : isCurrent
                ? AppColors.electricBlue.withOpacity(0.15)
                : isCompleted
                    ? AppColors.success.withOpacity(0.05)
                    : Colors.transparent,
        border: isEditing
            ? Border.all(
                color: AppColors.orange.withOpacity(0.5),
                width: 2,
              )
            : isCurrent
                ? Border.all(
                    color: AppColors.electricBlue.withOpacity(0.4),
                    width: 2,
                  )
                : Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.04),
                    ),
                  ),
        borderRadius: (isCurrent || isEditing) ? BorderRadius.circular(12) : null,
      ),
      margin: (isCurrent || isEditing) ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4) : EdgeInsets.zero,
      child: Row(
        children: [
          // Set number with NOW label for current set - tappable to edit/complete
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              if (isEditing) {
                // Tap while editing → Save changes
                _saveEditingSet();
              } else if (isCompleted) {
                // Tap on completed set → Start inline editing
                _startEditingSet(index);
              } else if (isCurrent) {
                // Complete the current set using existing callback
                widget.onCompleteSet();
              } else if (isPending && widget.onQuickCompleteSet != null) {
                // Quick complete a pending set
                widget.onQuickCompleteSet?.call(index, true);
              }
            },
            child: SizedBox(
              width: (isCurrent || isEditing) ? 50 : 36,
              child: isEditing
                  // Editing state: show EDIT badge and save icon
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'EDIT',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.orange.withOpacity(0.2),
                            border: Border.all(color: AppColors.orange, width: 2),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: AppColors.orange,
                            ),
                          ),
                        ),
                      ],
                    )
                  : isCurrent
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.electricBlue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'NOW',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.electricBlue.withOpacity(0.2),
                                border: Border.all(color: AppColors.electricBlue, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  setNumberDisplay,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.electricBlue,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : isCompleted
                          // Completed set: show green set number (tappable to edit)
                          ? Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.success.withOpacity(0.2),
                                border: Border.all(color: AppColors.success, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  setNumberDisplay,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            )
                          // Pending set: show number (tappable to complete)
                          : Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: textMuted.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  setNumberDisplay,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textMuted.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
            ),
          ),

          // LAST column - previous session (tappable to auto-fill)
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: (isCurrent && lastWeight != null && lastReps != null)
                  ? () {
                      // Auto-fill with previous session data
                      HapticFeedback.selectionClick();
                      final displayWeight = widget.useKg
                          ? lastWeight!
                          : lastWeight! * 2.20462;
                      widget.weightController.text = displayWeight.toStringAsFixed(0);
                      widget.repsController.text = lastReps.toString();
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: (isCurrent && lastWeight != null)
                    ? BoxDecoration(
                        color: textMuted.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      )
                    : null,
                child: Text(
                  lastDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted.withOpacity(isPending ? 0.4 : 0.7),
                    fontWeight: (isCurrent && lastWeight != null) ? FontWeight.w500 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // TARGET column - AI recommended weight × reps (tappable for current row)
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: isCurrent ? () => _showTargetEditSheet(index) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                decoration: isCurrent && (targetDisplay == '—' || targetDisplay.isEmpty)
                    ? BoxDecoration(
                        color: AppColors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.purple.withOpacity(0.3)),
                      )
                    : null,
                child: Text(
                  isCurrent && (targetDisplay == '—' || targetDisplay.isEmpty)
                      ? 'Tap to set'
                      : targetDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color: isCurrent
                        ? AppColors.purple
                        : isPending
                            ? AppColors.purple.withOpacity(0.4)
                            : AppColors.purple.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Weight input - tap on completed weight to edit inline
          Expanded(
            flex: 3,
            child: (isCurrent || isEditing)
                ? _buildTappableInput(
                    controller: isEditing ? _editWeightController! : widget.weightController,
                    isDecimal: true,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    accentColor: isEditing ? AppColors.orange : AppColors.electricBlue,
                  )
                : GestureDetector(
                    onTap: isCompleted
                        ? () {
                            HapticFeedback.mediumImpact();
                            _startEditingSet(index);
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        isCompleted
                            ? (widget.useKg
                                ? completedSetData!.weight.toStringAsFixed(0)
                                : (completedSetData!.weight * 2.20462)
                                    .toStringAsFixed(0))
                            : '—',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                          color: isCompleted
                              ? AppColors.success
                              : textMuted.withOpacity(0.4),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
          ),

          // Reps input - tap on completed reps to edit inline
          Expanded(
            flex: 2,
            child: (isCurrent || isEditing)
                ? _buildTappableInput(
                    controller: isEditing ? _editRepsController! : widget.repsController,
                    isDecimal: false,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    accentColor: isEditing ? AppColors.orange : AppColors.electricBlue,
                  )
                : GestureDetector(
                    onTap: isCompleted
                        ? () {
                            HapticFeedback.mediumImpact();
                            _startEditingSet(index);
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        isCompleted ? completedSetData!.reps.toString() : '—',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                          color: isCompleted
                              ? AppColors.success
                              : textMuted.withOpacity(0.4),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
          ),

          // Checkmark / status / cancel editing
          SizedBox(
            width: 36,
            child: isEditing
                ? GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _cancelEditingSet();
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: textMuted.withOpacity(0.15),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: textMuted,
                      ),
                    ),
                  )
                : isCompleted
                    ? _buildCompletedCheckmark(index)
                    : isCurrent
                        ? const SizedBox() // No inline button, use big CTA below
                        : _buildPendingIndicator(textMuted),
          ),
        ],
      ),
    );

    // Can delete this row if there's more than 1 total set
    final canDelete = widget.totalSets > 1;

    // Build the final widget - wrap with swipe-to-delete for all rows
    Widget finalWidget = rowWidget;

    // Add set type label above if needed
    if (setTypeLabelWidget != null) {
      finalWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          setTypeLabelWidget,
          rowWidget,
        ],
      );
    }

    // Wrap ALL rows with Dismissible for swipe-to-delete
    // Completed rows: swipe left = edit, swipe right = delete
    // Pending/current rows: swipe right only = delete
    if (canDelete) {
      return Dismissible(
        key: Key('set_${widget.viewingExerciseIndex}_$index'),
        // Left swipe background (Edit) - only for completed sets
        background: isCompleted
            ? Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 24),
                color: AppColors.electricBlue.withOpacity(0.15),
                child: const Row(
                  children: [
                    Icon(Icons.edit, color: AppColors.electricBlue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Edit',
                      style: TextStyle(
                        color: AppColors.electricBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : Container(color: Colors.transparent),
        // Right swipe background (Delete) - for all sets
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          color: AppColors.error.withOpacity(0.15),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Delete',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            ],
          ),
        ),
        // Only allow right-to-left swipe for non-completed rows
        direction: isCompleted
            ? DismissDirection.horizontal
            : DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          HapticFeedback.mediumImpact();
          if (direction == DismissDirection.startToEnd && isCompleted) {
            // Edit completed set
            widget.onEditSet(index);
            return false;
          } else if (direction == DismissDirection.endToStart) {
            // Delete - show confirmation for current/pending sets
            if (!isCompleted) {
              // For pending sets, just delete the row (reduce total)
              return true;
            }
            return true;
          }
          return false;
        },
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            if (isCompleted) {
              // Delete completed set
              widget.onDeleteSet(index);
            } else {
              // Delete pending/current row - signal to reduce total
              widget.onDeleteSet(-1);
            }
          }
        },
        child: finalWidget,
      );
    }

    return finalWidget;
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

  Widget _buildCompletedCheckmark(int index) {
    final isJustCompleted = widget.justCompletedSetIndex == index;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulse ring animation
        if (isJustCompleted) ...[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success, width: 2),
            ),
          )
              .animate()
              .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.5, 1.5),
                  duration: 400.ms,
                  curve: Curves.easeOutBack)
              .fadeOut(duration: 400.ms, delay: 100.ms),
          // Second pulse ring for extra satisfaction
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withOpacity(0.2),
            ),
          )
              .animate()
              .scale(
                  begin: const Offset(0.3, 0.3),
                  end: const Offset(1.3, 1.3),
                  duration: 350.ms,
                  delay: 50.ms,
                  curve: Curves.easeOut)
              .fadeOut(duration: 300.ms, delay: 150.ms),
        ],
        // Main checkmark container
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withOpacity(0.15),
          ),
          child: isJustCompleted
              ? const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: AppColors.success,
                )
                  .animate()
                  .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1.0, 1.0),
                      duration: 300.ms,
                      curve: Curves.elasticOut)
                  .then(delay: 50.ms)
                  .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.0, 1.0),
                      duration: 100.ms)
              : const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: AppColors.success,
                ),
        ),
      ],
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

  /// Build individual set modifier button
  Widget _buildSetModifierButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    bool isDisabled = false,
    VoidCallback? onTap,
  }) {
    final effectiveColor = isDisabled ? color.withOpacity(0.3) : color;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDisabled
              ? color.withOpacity(0.05)
              : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDisabled
                ? color.withOpacity(0.15)
                : color.withOpacity(0.35),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: effectiveColor, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: effectiveColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
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
