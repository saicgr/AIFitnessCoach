part of 'set_tracking_overlay.dart';

/// UI builder methods extracted from _SetTrackingOverlayState
extension _SetTrackingOverlayStateUI2 on _SetTrackingOverlayState {

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
    final isTimedExercise = widget.exercise.isTimedExercise;

    if (setTarget != null) {
      // Use per-set AI target (Gravl/Hevy style)
      final targetWeight = setTarget.targetWeightKg;
      final targetReps = setTarget.targetReps;
      final targetHoldSeconds = setTarget.targetHoldSeconds;

      // Check if this is a timed exercise with per-set hold times
      if (isTimedExercise && targetHoldSeconds != null && targetHoldSeconds > 0) {
        // Display hold time for timed exercises (planks, wall sits, etc.)
        targetDisplay = setTarget.holdTimeDisplay;
      } else if (targetWeight != null && targetWeight > 0) {
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

      // Check for timed exercise with hold_seconds
      if (isTimedExercise) {
        final holdSeconds = widget.exercise.holdSeconds;
        if (holdSeconds != null && holdSeconds > 0) {
          // Format hold time display
          if (holdSeconds >= 60) {
            final minutes = holdSeconds ~/ 60;
            final seconds = holdSeconds % 60;
            if (seconds > 0) {
              targetDisplay = '${minutes}m ${seconds}s';
            } else {
              targetDisplay = '${minutes}m';
            }
          } else {
            targetDisplay = '${holdSeconds}s';
          }
        }
      } else if (targetWeight != null && targetWeight > 0 && targetReps != null) {
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
              onTap: isCurrent ? () => sheets.showTargetEditSheet(
                      context: context,
                      exercise: widget.exercise,
                      setIndex: index,
                      useKg: widget.useKg,
                      onEditTarget: widget.onEditTarget,
                    ) : null,
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

}
