/// Set tracking overlay widget
///
/// Displays the set tracking table during active workout.
/// Hevy/Gravl-inspired design with inline editing and single CTA.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../models/workout_state.dart';
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

  /// Previous session sets for comparison
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

  /// Callback to edit a completed set
  final void Function(int setIndex) onEditSet;

  /// Callback to delete a completed set
  final void Function(int setIndex) onDeleteSet;

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
    required this.onDeleteSet,
    required this.onDoneButtonPressDown,
    required this.onDoneButtonPressUp,
    required this.onDoneButtonPressCancel,
    required this.onShowNumberInputDialog,
    this.onSkipExercise,
    this.onOpenWorkoutPlan,
  });

  @override
  State<SetTrackingOverlay> createState() => _SetTrackingOverlayState();
}

class _SetTrackingOverlayState extends State<SetTrackingOverlay> {
  bool _isMinimized = false;

  /// Current set type: null = working set, 'W' = warmup, 'D' = drop set, 'F' = failure
  String? _currentSetType;

  bool get isViewingCurrent => widget.viewingExerciseIndex == widget.currentExerciseIndex;
  int get currentSetIndex => widget.completedSets.length;
  bool get allSetsCompleted => widget.completedSets.length >= widget.totalSets;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isDark ? 12 : 10,
          sigmaY: isDark ? 12 : 10,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.pureBlack.withOpacity(0.75)
                : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : AppColorsLight.cardBorder.withOpacity(0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with exercise name and overflow menu (always visible)
              _buildHeader(context, isDark, textPrimary, textMuted),

              // Collapsible content
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _isMinimized
                    ? const SizedBox.shrink()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Table header
                          _buildTableHeader(isDark, textMuted),

                          // Set type tags row (only shown when viewing current exercise)
                          if (isViewingCurrent && !allSetsCompleted)
                            _buildSetTypeTags(isDark, textMuted),

                          // Warmup set row (always first)
                          _buildWarmupRow(context, isDark, textPrimary, textMuted),

                          // Working set rows
                          ...List.generate(widget.totalSets, (index) {
                            return _buildSetRow(context, index, isDark, textPrimary, textMuted);
                          }),

                          // Complete Set button (only CTA)
                          if (isViewingCurrent && !allSetsCompleted)
                            _buildCompleteSetButton(isDark),

                          // Back to current or rest info
                          if (!isViewingCurrent)
                            _buildBackToCurrentButton(isDark, textMuted),

                          const SizedBox(height: 12),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05);
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    return GestureDetector(
      onTap: _isMinimized
          ? () {
              setState(() => _isMinimized = false);
              HapticFeedback.selectionClick();
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.elevated.withOpacity(0.5)
              : AppColorsLight.glassSurface.withOpacity(0.7),
          borderRadius: _isMinimized
              ? BorderRadius.circular(20)
              : const BorderRadius.vertical(top: Radius.circular(20)),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${widget.viewingExerciseIndex + 1} of ${widget.totalExercises}',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!isViewingCurrent) ...[
                        const SizedBox(width: 8),
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
                      // Show set progress when minimized
                      if (_isMinimized) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${widget.completedSets.length}/${widget.totalSets} sets',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cyan,
                            ),
                          ),
                        ),
                      ],
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

            // Open workout plan button (up arrow)
            if (widget.onOpenWorkoutPlan != null)
              _buildWorkoutPlanButton(isDark, textMuted),

            const SizedBox(width: 4),

            // Minimize/Expand button
            _buildMinimizeButton(isDark, textMuted),

            const SizedBox(width: 4),

            // Overflow menu
            _buildOverflowMenu(context, isDark),
          ],
        ),
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

  Widget _buildMinimizeButton(bool isDark, Color textMuted) {
    return GestureDetector(
      onTap: () {
        setState(() => _isMinimized = !_isMinimized);
        HapticFeedback.selectionClick();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _isMinimized
              ? AppColors.cyan.withOpacity(0.15)
              : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: AnimatedRotation(
          turns: _isMinimized ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            Icons.keyboard_arrow_down,
            color: _isMinimized ? AppColors.cyan : textMuted,
            size: 22,
          ),
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

  Widget _buildOverflowMenu(BuildContext context, bool isDark) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
        size: 22,
      ),
      color: isDark ? AppColors.elevated : AppColorsLight.elevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 40),
      onSelected: (value) {
        HapticFeedback.selectionClick();
        switch (value) {
          case 'add_set':
            widget.onAddSet();
            break;
          case 'remove_set':
            if (widget.totalSets > 1) {
              // Could add a callback for remove set
            }
            break;
          case 'toggle_unit':
            widget.onToggleUnit();
            break;
          case 'skip':
            widget.onSkipExercise?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'add_set',
          child: Row(
            children: [
              Icon(Icons.add_circle_outline,
                  size: 20, color: AppColors.electricBlue),
              const SizedBox(width: 12),
              const Text('Add Set'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'toggle_unit',
          child: Row(
            children: [
              Icon(Icons.swap_horiz, size: 20, color: AppColors.purple),
              const SizedBox(width: 12),
              Text('Switch to ${widget.useKg ? 'lbs' : 'kg'}'),
            ],
          ),
        ),
        if (widget.onSkipExercise != null)
          PopupMenuItem(
            value: 'skip',
            child: Row(
              children: [
                Icon(Icons.skip_next, size: 20, color: AppColors.orange),
                const SizedBox(width: 12),
                const Text('Skip Exercise'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTableHeader(bool isDark, Color textMuted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            width: 40,
            child: Text(
              'SET',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'PREVIOUS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                widget.onToggleUnit();
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.useKg ? 'KG' : 'LBS',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.electricBlue,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Text(
              'REPS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.electricBlue,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 44), // Space for checkmark
        ],
      ),
    );
  }

  /// Build set type tags row (W/D/F)
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            width: 40,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orange.withOpacity(0.15),
              ),
              child: const Center(
                child: Text(
                  'W',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ),
          ),

          // Previous (empty for warmup)
          Expanded(
            flex: 2,
            child: Text(
              '-',
              style: TextStyle(
                fontSize: 13,
                color: textMuted.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Warmup weight suggestion
          Expanded(
            flex: 2,
            child: Text(
              warmupWeight > 0 ? warmupWeight.toStringAsFixed(0) : '-',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.orange.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Warmup reps
          Expanded(
            flex: 2,
            child: Text(
              '$warmupReps',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.orange.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Empty checkmark space
          SizedBox(
            width: 44,
            child: Icon(
              Icons.whatshot_outlined,
              size: 18,
              color: AppColors.orange.withOpacity(0.5),
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

    SetLog? completedSetData;
    if (isCompleted) {
      completedSetData = widget.completedSets[index];
    }

    // Format previous session data
    String prevDisplay = '-';
    if (previousSet != null) {
      final prevWeight = widget.useKg
          ? previousSet['weight'] as double
          : (previousSet['weight'] as double) * 2.20462;
      prevDisplay = '${prevWeight.toStringAsFixed(0)} × ${previousSet['reps']}';
    }

    final rowWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.electricBlue.withOpacity(0.08)
            : isCompleted
                ? AppColors.success.withOpacity(0.05)
                : Colors.transparent,
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
          // Set number
          SizedBox(
            width: 40,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.success.withOpacity(0.15)
                    : isCurrent
                        ? AppColors.electricBlue.withOpacity(0.15)
                        : Colors.transparent,
                border: isCurrent
                    ? Border.all(color: AppColors.electricBlue, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? AppColors.success
                        : isCurrent
                            ? AppColors.electricBlue
                            : textMuted.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),

          // Previous session
          Expanded(
            flex: 2,
            child: Text(
              prevDisplay,
              style: TextStyle(
                fontSize: 13,
                color: textMuted.withOpacity(isPending ? 0.4 : 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Weight
          Expanded(
            flex: 2,
            child: isCurrent
                ? _buildInlineInput(
                    controller: widget.weightController,
                    isDecimal: true,
                    isDark: isDark,
                  )
                : Text(
                    isCompleted
                        ? (widget.useKg
                            ? completedSetData!.weight.toStringAsFixed(0)
                            : (completedSetData!.weight * 2.20462)
                                .toStringAsFixed(0))
                        : '-',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                      color: isCompleted
                          ? AppColors.success
                          : textMuted.withOpacity(0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),

          // Reps
          Expanded(
            flex: 2,
            child: isCurrent
                ? _buildInlineInput(
                    controller: widget.repsController,
                    isDecimal: false,
                    isDark: isDark,
                  )
                : Text(
                    isCompleted ? completedSetData!.reps.toString() : '-',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                      color: isCompleted
                          ? AppColors.success
                          : textMuted.withOpacity(0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),

          // Checkmark / status
          SizedBox(
            width: 44,
            child: isCompleted
                ? _buildCompletedCheckmark(index)
                : isCurrent
                    ? const SizedBox() // No inline button, use big CTA below
                    : _buildPendingIndicator(textMuted),
          ),
        ],
      ),
    );

    // Make completed rows swipeable for edit/delete
    if (isCompleted) {
      return Dismissible(
        key: Key('set_${widget.viewingExerciseIndex}_$index'),
        background: Container(
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
        ),
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
        confirmDismiss: (direction) async {
          HapticFeedback.mediumImpact();
          if (direction == DismissDirection.startToEnd) {
            widget.onEditSet(index);
            return false;
          } else {
            return true;
          }
        },
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            widget.onDeleteSet(index);
          }
        },
        child: rowWidget,
      );
    }

    return rowWidget;
  }

  Widget _buildInlineInput({
    required TextEditingController controller,
    required bool isDecimal,
    required bool isDark,
  }) {
    return InlineNumberInput(
      controller: controller,
      isDecimal: isDecimal,
      isActive: true,
      accentColor: AppColors.electricBlue,
      onShowDialog: () => widget.onShowNumberInputDialog(controller, isDecimal),
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
