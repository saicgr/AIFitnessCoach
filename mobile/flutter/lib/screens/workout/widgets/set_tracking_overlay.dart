/// Set tracking overlay widget
///
/// Displays the set tracking table during active workout.
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

  /// Whether active row is expanded
  final bool isActiveRowExpanded;

  /// Index of just-completed set for animation
  final int? justCompletedSetIndex;

  /// Whether done button is pressed
  final bool isDoneButtonPressed;

  /// Callback to toggle row expansion
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
  });

  bool get isViewingCurrent => viewingExerciseIndex == currentExerciseIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final headerBg = isDark
        ? AppColors.elevated.withOpacity(0.6)
        : AppColorsLight.glassSurface.withOpacity(0.8);
    final rowBorder = isDark
        ? AppColors.cardBorder.withOpacity(0.2)
        : AppColorsLight.cardBorder.withOpacity(0.3);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isDark ? 10 : 8,
          sigmaY: isDark ? 10 : 8,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.pureBlack.withOpacity(0.65)
                : Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : AppColorsLight.cardBorder.withOpacity(0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row with exercise navigation
              _buildHeader(
                context,
                headerBg: headerBg,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),

              // Table header
              _buildTableHeader(isDark, textMuted),

              // Warmup set rows
              _buildWarmupSetRow(
                setLabel: 'W',
                repRange: _getRepRange(exercise),
                rowBorder: rowBorder,
                textMuted: textMuted,
                textSecondary: textSecondary,
              ),
              _buildWarmupSetRow(
                setLabel: 'W',
                repRange: _getRepRange(exercise),
                rowBorder: rowBorder,
                textMuted: textMuted,
                textSecondary: textSecondary,
              ),

              // Working set rows
              ...List.generate(totalSets, (index) {
                return _buildSetRow(
                  context,
                  index: index,
                  rowBorder: rowBorder,
                  textMuted: textMuted,
                  textSecondary: textSecondary,
                  textPrimary: textPrimary,
                  isDark: isDark,
                );
              }),

              // Add Set button
              _buildAddSetButton(isDark),

              const SizedBox(height: 24),

              // Rest timer info / back to current
              _buildBottomInfo(isDark),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1);
  }

  Widget _buildHeader(
    BuildContext context, {
    required Color headerBg,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: headerBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          // Previous exercise button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: viewingExerciseIndex > 0
                ? () {
                    onPreviousExercise?.call();
                    HapticFeedback.selectionClick();
                  }
                : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: viewingExerciseIndex > 0
                    ? AppColors.cyan.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_left,
                size: 24,
                color: viewingExerciseIndex > 0
                    ? AppColors.cyan
                    : textMuted.withOpacity(0.3),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Exercise name and position
          Expanded(
            child: Column(
              children: [
                Text(
                  exercise.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isViewingCurrent ? AppColors.cyan : textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${viewingExerciseIndex + 1}/$totalExercises',
                      style: TextStyle(
                        fontSize: 10,
                        color: textMuted,
                      ),
                    ),
                    if (!isViewingCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          viewingExerciseIndex < currentExerciseIndex
                              ? 'PAST'
                              : 'UPCOMING',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Next exercise button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: viewingExerciseIndex < totalExercises - 1
                ? () {
                    onNextExercise?.call();
                    HapticFeedback.selectionClick();
                  }
                : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: viewingExerciseIndex < totalExercises - 1
                    ? AppColors.cyan.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_right,
                size: 24,
                color: viewingExerciseIndex < totalExercises - 1
                    ? AppColors.cyan
                    : textMuted.withOpacity(0.3),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Unit toggle
          GestureDetector(
            onTap: () {
              onToggleUnit();
              HapticFeedback.selectionClick();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                useKg ? 'KG' : 'LBS',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cyan,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Close button
          GestureDetector(
            onTap: onClose,
            child: const Icon(
              Icons.close,
              size: 18,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(bool isDark, Color textMuted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.elevated.withOpacity(0.3)
            : AppColorsLight.glassSurface.withOpacity(0.6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Center(
              child: Text(
                'SET',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                'PREVIOUS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Center(
              child: Text(
                useKg ? 'KG' : 'LBS',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cyan,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            flex: 4,
            child: Center(
              child: Text(
                'REPS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.purple,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 50),
        ],
      ),
    );
  }

  Widget _buildWarmupSetRow({
    required String setLabel,
    required String repRange,
    required Color rowBorder,
    required Color textMuted,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: rowBorder),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            child: Center(
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
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
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                '-',
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted.withOpacity(0.5),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Center(
              child: Text(
                '-',
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted.withOpacity(0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Center(
              child: Text(
                repRange,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 50),
        ],
      ),
    );
  }

  Widget _buildSetRow(
    BuildContext context, {
    required int index,
    required Color rowBorder,
    required Color textMuted,
    required Color textSecondary,
    required Color textPrimary,
    required bool isDark,
  }) {
    final isCompleted = index < completedSets.length;
    final isCurrent = isViewingCurrent && index == completedSets.length;
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
      prevDisplay = '${prevWeight.toStringAsFixed(0)} x ${previousSet['reps']}';
    }

    final isExpanded = isCurrent && isActiveRowExpanded;
    final rowOpacity = (isCurrent || !isActiveRowExpanded) ? 1.0 : 0.5;
    final inputBg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textColor = isDark ? Colors.white : AppColorsLight.textPrimary;

    final rowWidget = GestureDetector(
      onTap: isCurrent
          ? () {
              onToggleRowExpansion();
              HapticFeedback.mediumImpact();
            }
          : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: rowOpacity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: isCurrent
              ? EdgeInsets.symmetric(
                  horizontal: 2, vertical: isExpanded ? 6 : 3)
              : EdgeInsets.zero,
          padding: EdgeInsets.symmetric(
            horizontal: isCurrent ? 8 : 10,
            vertical: isExpanded ? 16 : (isCurrent ? 8 : 5),
          ),
          decoration: BoxDecoration(
            gradient: isCurrent
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.cyan.withOpacity(isExpanded ? 0.18 : 0.12),
                      AppColors.electricBlue.withOpacity(isExpanded ? 0.12 : 0.08),
                      AppColors.cyan.withOpacity(isExpanded ? 0.08 : 0.05),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  )
                : null,
            color: isCompleted
                ? AppColors.success.withOpacity(0.08)
                : isCurrent
                    ? null
                    : Colors.transparent,
            borderRadius:
                isCurrent ? BorderRadius.circular(isExpanded ? 16 : 12) : null,
            border: isCurrent
                ? Border.all(
                    color: AppColors.cyan.withOpacity(isExpanded ? 0.4 : 0.3),
                    width: isExpanded ? 1.5 : 1,
                  )
                : Border(
                    bottom: BorderSide(color: rowBorder),
                  ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color:
                          AppColors.cyan.withOpacity(isExpanded ? 0.15 : 0.1),
                      blurRadius: isExpanded ? 16 : 10,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: AppColors.electricBlue.withOpacity(0.05),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: isExpanded
                ? _buildExpandedRow(inputBg, textColor)
                : _buildCompactRow(
                    index: index,
                    isCompleted: isCompleted,
                    isCurrent: isCurrent,
                    completedSetData: completedSetData,
                    prevDisplay: prevDisplay,
                    textMuted: textMuted,
                    textSecondary: textSecondary,
                    textColor: textColor,
                    inputBg: inputBg,
                  ),
          ),
        ),
      ),
    );

    if (isCompleted) {
      return _buildDismissibleRow(rowWidget, index);
    } else if (isCurrent) {
      return rowWidget
          .animate()
          .shimmer(duration: 2000.ms, color: AppColors.cyan.withOpacity(0.1));
    }
    return rowWidget;
  }

  Widget _buildExpandedRow(Color inputBg, Color textColor) {
    return Column(
      key: const ValueKey('expanded'),
      children: [
        // Collapse hint
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.keyboard_arrow_up,
                size: 16, color: AppColors.cyan.withOpacity(0.6)),
            const SizedBox(width: 4),
            Text(
              'Tap to collapse',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.cyan.withOpacity(0.6),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 50.ms, duration: 200.ms),
        const SizedBox(height: 12),
        // Large KG and REPS side by side
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    useKg ? 'WEIGHT (KG)' : 'WEIGHT (LBS)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cyan,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ExpandedNumberInput(
                    controller: weightController,
                    isDecimal: true,
                    accentColor: AppColors.cyan,
                    onShowDialog: () =>
                        onShowNumberInputDialog(weightController, true),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'REPS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.purple,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ExpandedNumberInput(
                    controller: repsController,
                    isDecimal: false,
                    accentColor: AppColors.purple,
                    onShowDialog: () =>
                        onShowNumberInputDialog(repsController, false),
                  ),
                ],
              ),
            ),
          ],
        ).animate().fadeIn(delay: 80.ms, duration: 200.ms),
        const SizedBox(height: 16),
        // Large complete button
        _buildExpandedCompleteButton()
            .animate()
            .fadeIn(delay: 100.ms, duration: 200.ms)
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.0, 1.0),
              delay: 100.ms,
              duration: 300.ms,
              curve: Curves.elasticOut,
            ),
      ],
    );
  }

  Widget _buildCompactRow({
    required int index,
    required bool isCompleted,
    required bool isCurrent,
    required SetLog? completedSetData,
    required String prevDisplay,
    required Color textMuted,
    required Color textSecondary,
    required Color textColor,
    required Color inputBg,
  }) {
    return Row(
      key: const ValueKey('compact'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Set number
        SizedBox(
          width: 36,
          child: Center(
            child: Container(
              width: isCurrent ? 28 : 22,
              height: isCurrent ? 28 : 22,
              decoration: isCurrent
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cyan.withOpacity(0.2),
                      border: Border.all(color: AppColors.cyan, width: 1.5),
                    )
                  : null,
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: isCurrent ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? AppColors.success
                        : isCurrent
                            ? AppColors.cyan
                            : textMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Previous session
        Expanded(
          flex: 3,
          child: Center(
            child: Text(
              prevDisplay,
              style: TextStyle(
                fontSize: isCurrent ? 13 : 12,
                color: isCurrent ? textSecondary : textMuted.withOpacity(0.7),
              ),
            ),
          ),
        ),
        // Weight
        Expanded(
          flex: 4,
          child: Center(
            child: isCurrent
                ? InlineNumberInput(
                    controller: weightController,
                    isDecimal: true,
                    isActive: true,
                    accentColor: AppColors.cyan,
                    onShowDialog: () =>
                        onShowNumberInputDialog(weightController, true),
                  )
                : Text(
                    isCompleted
                        ? (useKg
                            ? completedSetData!.weight.toStringAsFixed(0)
                            : (completedSetData!.weight * 2.20462)
                                .toStringAsFixed(0))
                        : '-',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: isCompleted ? AppColors.success : textMuted,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        // Reps
        Expanded(
          flex: 4,
          child: Center(
            child: isCurrent
                ? InlineNumberInput(
                    controller: repsController,
                    isDecimal: false,
                    isActive: true,
                    accentColor: AppColors.purple,
                    onShowDialog: () =>
                        onShowNumberInputDialog(repsController, false),
                  )
                : Text(
                    isCompleted ? completedSetData!.reps.toString() : '-',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: isCompleted ? AppColors.success : textMuted,
                    ),
                  ),
          ),
        ),
        // Checkmark / Complete button
        SizedBox(
          width: 50,
          child: isCompleted
              ? _buildCompletedCheckmark(index)
              : isCurrent
                  ? _buildActiveCompleteButton()
                  : _buildPendingIndicator(textMuted),
        ),
      ],
    );
  }

  Widget _buildCompletedCheckmark(int index) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (justCompletedSetIndex == index) ...[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success, width: 2),
            ),
          )
              .animate()
              .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.4, 1.4),
                  duration: 400.ms)
              .fadeOut(duration: 400.ms),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withOpacity(0.3),
            ),
          )
              .animate()
              .scale(
                  begin: const Offset(0.3, 0.3),
                  end: const Offset(1.8, 1.8),
                  duration: 500.ms,
                  delay: 50.ms)
              .fadeOut(duration: 400.ms, delay: 100.ms),
        ],
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withOpacity(0.15),
            border: Border.all(color: AppColors.success, width: 2),
          ),
          child: const Icon(Icons.check_rounded,
              size: 20, color: AppColors.success),
        )
            .animate()
            .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                duration: 300.ms,
                curve: Curves.elasticOut),
      ],
    );
  }

  Widget _buildActiveCompleteButton() {
    return GestureDetector(
      onTapDown: (_) => onDoneButtonPressDown(),
      onTapUp: (_) => onDoneButtonPressUp(),
      onTapCancel: onDoneButtonPressCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: isDoneButtonPressed ? 40 : 44,
        height: isDoneButtonPressed ? 40 : 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDoneButtonPressed
                ? [AppColors.electricBlue, AppColors.cyan]
                : [AppColors.cyan, AppColors.electricBlue],
          ),
          boxShadow: [
            BoxShadow(
              color:
                  AppColors.cyan.withOpacity(isDoneButtonPressed ? 0.35 : 0.2),
              blurRadius: isDoneButtonPressed ? 12 : 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: const Icon(Icons.check_rounded, size: 26, color: Colors.white),
      ),
    );
  }

  Widget _buildPendingIndicator(Color textMuted) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: textMuted.withOpacity(0.2),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildExpandedCompleteButton() {
    return GestureDetector(
      onTapDown: (_) => onDoneButtonPressDown(),
      onTapUp: (_) => onDoneButtonPressUp(),
      onTapCancel: onDoneButtonPressCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        height: isDoneButtonPressed ? 52 : 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDoneButtonPressed
                ? [AppColors.electricBlue, AppColors.cyan]
                : [AppColors.cyan, AppColors.electricBlue],
          ),
          boxShadow: [
            BoxShadow(
              color:
                  AppColors.cyan.withOpacity(isDoneButtonPressed ? 0.3 : 0.18),
              blurRadius: isDoneButtonPressed ? 14 : 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_rounded, size: 28, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'COMPLETE SET',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissibleRow(Widget rowWidget, int index) {
    return Dismissible(
      key: Key('set_${viewingExerciseIndex}_$index'),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.cyan.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.edit, color: AppColors.cyan, size: 20),
            SizedBox(width: 8),
            Text(
              'Edit',
              style: TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete, color: AppColors.error, size: 20),
          ],
        ),
      ),
      onUpdate: (details) {
        if (details.reached && details.previousReached == false) {
          HapticFeedback.mediumImpact();
        }
      },
      confirmDismiss: (direction) async {
        HapticFeedback.selectionClick();
        if (direction == DismissDirection.startToEnd) {
          onEditSet(index);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          // Show delete confirmation
          return true;
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDeleteSet(index);
        }
      },
      child: Opacity(
        opacity: 0.6,
        child: rowWidget,
      ),
    );
  }

  Widget _buildAddSetButton(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: GestureDetector(
        onTap: () {
          onAddSet();
          HapticFeedback.mediumImpact();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.elevated : AppColorsLight.glassSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.cyan.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cyan.withOpacity(0.15),
                  border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                ),
                child:
                    const Icon(Icons.add, size: 16, color: AppColors.cyan),
              ),
              const SizedBox(width: 10),
              const Text(
                'Add Set',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cyan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInfo(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.glassSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.purple.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: isViewingCurrent
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.purple.withOpacity(0.15),
                  ),
                  child: const Icon(Icons.timer_outlined,
                      size: 14, color: AppColors.purple),
                ),
                const SizedBox(width: 10),
                Text(
                  'Rest: ${exercise.restSeconds ?? 90}s between sets',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.purple,
                  ),
                ),
              ],
            )
          : GestureDetector(
              onTap: () {
                onBackToCurrentExercise();
                HapticFeedback.selectionClick();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cyan.withOpacity(0.15),
                    ),
                    child: const Icon(Icons.keyboard_return,
                        size: 14, color: AppColors.cyan),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Back to Current Exercise',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cyan,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getRepRange(WorkoutExercise exercise) {
    if (exercise.reps != null) {
      final reps = exercise.reps!;
      if (reps <= 6) return '${reps - 1}-${reps + 1}';
      if (reps <= 12) return '${reps - 2}-${reps + 2}';
      return '${reps - 3}-${reps + 3}';
    } else if (exercise.durationSeconds != null) {
      return '${exercise.durationSeconds}s';
    }
    return '8-12';
  }
}
