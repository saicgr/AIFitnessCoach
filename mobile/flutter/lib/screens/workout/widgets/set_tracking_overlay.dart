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
class SetTrackingOverlay extends StatelessWidget {
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
  });

  bool get isViewingCurrent => viewingExerciseIndex == currentExerciseIndex;
  int get currentSetIndex => completedSets.length;
  bool get allSetsCompleted => completedSets.length >= totalSets;

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
              // Header with exercise name and overflow menu
              _buildHeader(context, isDark, textPrimary, textMuted),

              // Table header
              _buildTableHeader(isDark, textMuted),

              // Warmup set row (always first)
              _buildWarmupRow(context, isDark, textPrimary, textMuted),

              // Working set rows
              ...List.generate(totalSets, (index) {
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
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05);
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
            : AppColorsLight.glassSurface.withOpacity(0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          // Previous exercise button
          _buildNavButton(
            icon: Icons.chevron_left,
            enabled: viewingExerciseIndex > 0,
            onTap: onPreviousExercise,
            isDark: isDark,
          ),

          const SizedBox(width: 12),

          // Exercise name and position
          Expanded(
            child: Column(
              children: [
                Text(
                  exercise.name,
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
                      '${viewingExerciseIndex + 1} of $totalExercises',
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
                          viewingExerciseIndex < currentExerciseIndex
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
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Next exercise button
          _buildNavButton(
            icon: Icons.chevron_right,
            enabled: viewingExerciseIndex < totalExercises - 1,
            onTap: onNextExercise,
            isDark: isDark,
          ),

          const SizedBox(width: 8),

          // Overflow menu
          _buildOverflowMenu(context, isDark),
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
            onAddSet();
            break;
          case 'remove_set':
            if (totalSets > 1) {
              // Could add a callback for remove set
            }
            break;
          case 'toggle_unit':
            onToggleUnit();
            break;
          case 'skip':
            onSkipExercise?.call();
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
              Text('Switch to ${useKg ? 'lbs' : 'kg'}'),
            ],
          ),
        ),
        if (onSkipExercise != null)
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
            child: Text(
              useKg ? 'KG' : 'LBS',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.electricBlue,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
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

  /// Build warmup set row
  Widget _buildWarmupRow(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    // Calculate warmup weight (50% of target weight for first working set)
    final targetWeight = double.tryParse(weightController.text) ?? exercise.weight ?? 0;
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
    final isCompleted = index < completedSets.length;
    final isCurrent = isViewingCurrent && index == completedSets.length;
    final isPending = index > completedSets.length;
    final previousSet = index < previousSets.length ? previousSets[index] : null;

    SetLog? completedSetData;
    if (isCompleted) {
      completedSetData = completedSets[index];
    }

    // Format previous session data
    String prevDisplay = '-';
    if (previousSet != null) {
      final prevWeight = useKg
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
                    controller: weightController,
                    isDecimal: true,
                    isDark: isDark,
                  )
                : Text(
                    isCompleted
                        ? (useKg
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
                    controller: repsController,
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
        key: Key('set_${viewingExerciseIndex}_$index'),
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
            onEditSet(index);
            return false;
          } else {
            return true;
          }
        },
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            onDeleteSet(index);
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
      onShowDialog: () => onShowNumberInputDialog(controller, isDecimal),
    );
  }

  Widget _buildCompletedCheckmark(int index) {
    final isJustCompleted = justCompletedSetIndex == index;

    return Stack(
      alignment: Alignment.center,
      children: [
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
                  end: const Offset(1.3, 1.3),
                  duration: 350.ms)
              .fadeOut(duration: 350.ms),
        ],
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withOpacity(0.15),
          ),
          child: const Icon(
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
        onTapDown: (_) => onDoneButtonPressDown(),
        onTapUp: (_) => onDoneButtonPressUp(),
        onTapCancel: onDoneButtonPressCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: double.infinity,
          height: isDoneButtonPressed ? 52 : 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.electricBlue,
            boxShadow: [
              BoxShadow(
                color: AppColors.electricBlue.withOpacity(isDoneButtonPressed ? 0.4 : 0.25),
                blurRadius: isDoneButtonPressed ? 16 : 12,
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
          onBackToCurrentExercise();
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
