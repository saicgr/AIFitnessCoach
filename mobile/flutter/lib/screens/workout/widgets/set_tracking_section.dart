/// Set Tracking Section Widget
///
/// A modular widget that displays the set tracking UI for active workouts.
/// Uses FuturisticSetCard for the active set and compact rows for completed sets.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/smart_weight_suggestion.dart';
import 'futuristic_set_card.dart';

/// Data for a completed set
class CompletedSetData {
  final int reps;
  final double weight;
  final int targetReps;
  final bool isEdited;
  final String setType;

  const CompletedSetData({
    required this.reps,
    required this.weight,
    this.targetReps = 0,
    this.isEdited = false,
    this.setType = 'working',
  });
}

/// Set tracking section for active workouts
class SetTrackingSection extends StatefulWidget {
  /// Current exercise being tracked
  final WorkoutExercise exercise;

  /// Index of exercise in workout
  final int exerciseIndex;

  /// Total exercises in workout
  final int totalExercises;

  /// Current set number (1-indexed)
  final int currentSetNumber;

  /// Total sets for this exercise
  final int totalSets;

  /// List of completed sets
  final List<CompletedSetData> completedSets;

  /// Previous session data (for comparison)
  final List<Map<String, dynamic>> previousSets;

  /// Current weight value
  final double currentWeight;

  /// Current reps value
  final int currentReps;

  /// Weight increment step
  final double weightStep;

  /// Whether using kg or lbs
  final bool useKg;

  /// Current set type
  final String setType;

  /// Smart weight suggestion from AI
  final SmartWeightSuggestion? smartWeightSuggestion;

  /// Whether current weight was auto-filled from AI
  final bool isWeightFromAiSuggestion;

  /// Whether this is the current exercise being worked on
  final bool isCurrentExercise;

  /// Whether the active row is expanded
  final bool isExpanded;

  /// Callbacks
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onCompleteSet;
  final VoidCallback? onSkipExercise;
  final ValueChanged<String>? onSetTypeChanged;
  final VoidCallback? onToggleExpand;
  final VoidCallback? onPreviousExercise;
  final VoidCallback? onNextExercise;
  final Function(int index)? onEditSet;

  /// Callback to add another set
  final VoidCallback? onAddSet;

  /// Callback to toggle weight unit (kg/lbs)
  final VoidCallback? onUnitToggle;

  /// Next exercise for preview
  final WorkoutExercise? nextExercise;

  /// Index of just-completed set for animation
  final int? justCompletedSetIndex;

  const SetTrackingSection({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.totalExercises,
    required this.currentSetNumber,
    required this.totalSets,
    required this.completedSets,
    this.previousSets = const [],
    required this.currentWeight,
    required this.currentReps,
    this.weightStep = 2.5,
    this.useKg = true,
    this.setType = 'working',
    this.smartWeightSuggestion,
    this.isWeightFromAiSuggestion = false,
    this.isCurrentExercise = true,
    this.isExpanded = true,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onCompleteSet,
    this.onSkipExercise,
    this.onSetTypeChanged,
    this.onToggleExpand,
    this.onPreviousExercise,
    this.onNextExercise,
    this.onEditSet,
    this.onAddSet,
    this.onUnitToggle,
    this.nextExercise,
    this.justCompletedSetIndex,
  });

  @override
  State<SetTrackingSection> createState() => _SetTrackingSectionState();
}

class _SetTrackingSectionState extends State<SetTrackingSection> {
  bool _isMinimized = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark
        ? AppColors.elevated.withOpacity(0.6)
        : AppColorsLight.glassSurface.withOpacity(0.8);
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with exercise navigation and minimize button
              _buildHeader(headerBg, textPrimary, textMuted, isDark),

              // Collapsible content
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _isMinimized
                    ? const SizedBox.shrink()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Completed sets summary (compact)
                          if (widget.completedSets.isNotEmpty)
                            _buildCompletedSetsSummary(isDark, textMuted),

                          // Active set card (FuturisticSetCard)
                          if (widget.isCurrentExercise && widget.currentSetNumber <= widget.totalSets)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: FuturisticSetCard(
                                exerciseName: widget.exercise.name,
                                currentSetNumber: widget.currentSetNumber,
                                totalSets: widget.totalSets,
                                weight: widget.currentWeight,
                                reps: widget.currentReps,
                                weightStep: widget.weightStep,
                                useKg: widget.useKg,
                                onUnitToggle: widget.onUnitToggle,
                                previousWeight: _getPreviousWeight(),
                                previousReps: _getPreviousReps(),
                                onWeightChanged: widget.onWeightChanged,
                                onRepsChanged: widget.onRepsChanged,
                                onComplete: widget.onCompleteSet,
                                onSkip: widget.onSkipExercise,
                                completedSets: widget.completedSets
                                    .map((s) => {'weight': s.weight, 'reps': s.reps})
                                    .toList(),
                                isLastSet: widget.currentSetNumber >= widget.totalSets,
                                setType: widget.setType,
                                onSetTypeChanged: widget.onSetTypeChanged,
                                smartWeightSuggestion: widget.smartWeightSuggestion,
                                isWeightFromAiSuggestion: widget.isWeightFromAiSuggestion,
                              ),
                            ),

                          // Exercise completed state
                          if (widget.isCurrentExercise && widget.currentSetNumber > widget.totalSets)
                            _buildExerciseCompleteState(isDark, textPrimary),

                          // Next exercise preview
                          if (widget.nextExercise != null)
                            _buildNextExercisePreview(isDark, textMuted),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    Color headerBg,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: headerBg,
        borderRadius: _isMinimized
            ? BorderRadius.circular(20)
            : const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          // Previous exercise button
          _buildNavButton(
            icon: Icons.chevron_left,
            enabled: widget.exerciseIndex > 0,
            onTap: widget.onPreviousExercise,
            textMuted: textMuted,
          ),
          const SizedBox(width: 4),
          // Exercise name and position (tappable to expand when minimized)
          Expanded(
            child: GestureDetector(
              onTap: _isMinimized
                  ? () {
                      setState(() => _isMinimized = false);
                      HapticFeedback.lightImpact();
                    }
                  : null,
              child: Column(
                children: [
                  Text(
                    widget.exercise.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: widget.isCurrentExercise ? AppColors.cyan : textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!_isMinimized) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Exercise ${widget.exerciseIndex + 1} of ${widget.totalExercises}',
                      style: TextStyle(
                        fontSize: 10,
                        color: textMuted,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Set ${widget.currentSetNumber}/${widget.totalSets} • Tap to expand',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.cyan,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Next exercise button
          _buildNavButton(
            icon: Icons.chevron_right,
            enabled: widget.exerciseIndex < widget.totalExercises - 1,
            onTap: widget.onNextExercise,
            textMuted: textMuted,
          ),
          const SizedBox(width: 8),
          // Minimize/Expand button - more visible
          _buildMinimizeButton(isDark, textMuted),
        ],
      ),
    );
  }

  Widget _buildMinimizeButton(bool isDark, Color textMuted) {
    return GestureDetector(
      onTap: () {
        setState(() => _isMinimized = !_isMinimized);
        HapticFeedback.mediumImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _isMinimized
              ? AppColors.cyan.withOpacity(0.2)
              : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isMinimized
                ? AppColors.cyan.withOpacity(0.5)
                : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
          ),
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
    required Color textMuted,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled
          ? () {
              onTap?.call();
              HapticFeedback.selectionClick();
            }
          : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.cyan.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 24,
          color: enabled ? AppColors.cyan : textMuted.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildCompletedSetsSummary(bool isDark, Color textMuted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                ...widget.completedSets.asMap().entries.map((entry) {
                  final index = entry.key;
                  final set = entry.value;
                  final isJustCompleted = widget.justCompletedSetIndex == index;

                  return GestureDetector(
                    onTap: () => widget.onEditSet?.call(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: set.isEdited
                            ? AppColors.orange.withOpacity(0.15)
                            : AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: isJustCompleted
                            ? Border.all(color: AppColors.success, width: 1.5)
                            : null,
                      ),
                      child: Text(
                        'S${index + 1}: ${set.weight.toStringAsFixed(0)}${widget.useKg ? 'kg' : 'lbs'}×${set.reps}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: set.isEdited ? AppColors.orange : AppColors.success,
                        ),
                      ),
                    ),
                  )
                      .animate(
                        target: isJustCompleted ? 1 : 0,
                      )
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        duration: 200.ms,
                      )
                      .then()
                      .scale(
                        begin: const Offset(1.1, 1.1),
                        end: const Offset(1, 1),
                        duration: 200.ms,
                      );
                }),
                // Add Set button
                if (widget.onAddSet != null)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onAddSet?.call();
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cyan, width: 1.5),
                        color: AppColors.cyan.withOpacity(0.1),
                      ),
                      child: const Icon(Icons.add, size: 16, color: AppColors.cyan),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCompleteState(bool isDark, Color textPrimary) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withOpacity(0.2),
              border: Border.all(color: AppColors.success, width: 2),
            ),
            child: const Icon(
              Icons.check,
              size: 32,
              color: AppColors.success,
            ),
          )
              .animate()
              .scale(duration: 300.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            'Exercise Complete!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.completedSets.length} sets completed',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  double? _getPreviousWeight() {
    if (widget.previousSets.isEmpty) return null;
    final setIndex = widget.currentSetNumber - 1;
    if (setIndex >= widget.previousSets.length) return null;
    return (widget.previousSets[setIndex]['weight'] as num?)?.toDouble();
  }

  int? _getPreviousReps() {
    if (widget.previousSets.isEmpty) return null;
    final setIndex = widget.currentSetNumber - 1;
    if (setIndex >= widget.previousSets.length) return null;
    return widget.previousSets[setIndex]['reps'] as int?;
  }

  Widget _buildNextExercisePreview(bool isDark, Color textMuted) {
    if (widget.nextExercise == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cyan.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.arrow_forward_rounded,
            size: 14,
            color: textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            'NEXT:',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: textMuted,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              widget.nextExercise!.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.cyan,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Next exercise sets info
          Text(
            '${widget.nextExercise!.sets ?? 3} sets',
            style: TextStyle(
              fontSize: 10,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
