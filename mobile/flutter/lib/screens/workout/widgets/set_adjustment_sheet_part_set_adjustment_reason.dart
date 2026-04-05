part of 'set_adjustment_sheet.dart';



/// Reasons for adjusting sets during a workout
enum SetAdjustmentReason {
  fatigue('Fatigue', 'Too tired to continue', Icons.battery_1_bar),
  time('Time constraint', 'Running out of time', Icons.schedule),
  pain('Pain/discomfort', 'Feeling pain or discomfort', Icons.healing),
  equipment('Equipment unavailable', 'Equipment not available', Icons.fitness_center),
  other('Other', 'Different reason', Icons.more_horiz);

  final String label;
  final String description;
  final IconData icon;

  const SetAdjustmentReason(this.label, this.description, this.icon);
}


/// Represents a single set's data for editing
class EditableSetData {
  int reps;
  double weight;
  bool isCompleted;

  EditableSetData({
    required this.reps,
    required this.weight,
    this.isCompleted = false,
  });

  EditableSetData copyWith({int? reps, double? weight, bool? isCompleted}) {
    return EditableSetData(
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}


/// Data class for set adjustment
class SetAdjustment {
  final SetAdjustmentReason reason;
  final String? notes;
  final int exerciseIndex;
  final int originalSets;
  final int newSets;
  final DateTime timestamp;

  SetAdjustment({
    required this.reason,
    this.notes,
    required this.exerciseIndex,
    required this.originalSets,
    required this.newSets,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'reason': reason.name,
    'notes': notes,
    'exercise_index': exerciseIndex,
    'original_sets': originalSets,
    'new_sets': newSets,
    'timestamp': timestamp.toIso8601String(),
  };
}


/// Skip remaining sets confirmation sheet
class SkipRemainingSetsSheet extends StatefulWidget {
  /// Exercise name
  final String exerciseName;

  /// Current completed sets count
  final int completedSets;

  /// Total sets planned
  final int totalSets;

  /// Callback when skip is confirmed
  final void Function(SetAdjustmentReason reason, String? notes) onConfirm;

  /// Callback when cancelled
  final VoidCallback? onCancel;

  const SkipRemainingSetsSheet({
    super.key,
    required this.exerciseName,
    required this.completedSets,
    required this.totalSets,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  State<SkipRemainingSetsSheet> createState() => _SkipRemainingSetsSheetState();
}


class _SkipRemainingSetsSheetState extends State<SkipRemainingSetsSheet> {
  SetAdjustmentReason? _selectedReason;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    if (_selectedReason == null) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    widget.onConfirm(
      _selectedReason!,
      _notesController.text.isNotEmpty ? _notesController.text : null,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final remainingSets = widget.totalSets - widget.completedSets;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with icon
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.skip_next_rounded,
                          color: AppColors.orange,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Done with this exercise?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Skip $remainingSets remaining set${remainingSets > 1 ? 's' : ''} of ${widget.exerciseName}',
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
              ),
            ),

            // Progress indicator
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.completedSets} sets completed',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'of ${widget.totalSets} planned',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.orange.withOpacity(0.15),
                    ),
                    child: Center(
                      child: Text(
                        '-$remainingSets',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.orange,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Reason selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why are you stopping early?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...SetAdjustmentReason.values.map((reason) {
                    final isSelected = _selectedReason == reason;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedReason = reason;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.orange.withOpacity(0.15)
                              : cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.orange
                                : isDark
                                    ? AppColors.cardBorder
                                    : AppColorsLight.cardBorder,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.orange.withOpacity(0.2)
                                    : textMuted.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                reason.icon,
                                size: 20,
                                color: isSelected
                                    ? AppColors.orange
                                    : textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reason.label,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.orange
                                          : textPrimary,
                                    ),
                                  ),
                                  Text(
                                    reason.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.orange,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Notes field
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: TextField(
                controller: _notesController,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 14,
                  color: textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Additional notes (optional)',
                  hintStyle: TextStyle(
                    color: textMuted,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        widget.onCancel?.call();
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.cardBorder
                                : AppColorsLight.cardBorder,
                          ),
                        ),
                      ),
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _selectedReason != null ? _handleConfirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: isDark
                            ? AppColors.elevated
                            : AppColorsLight.elevated,
                        disabledForegroundColor: textMuted,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Skip & Continue',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
            ),
          ),
    );
  }
}


/// Result from in-workout set editing
class InWorkoutSetEditResult {
  final List<EditableSetData> sets;
  final int originalSetCount;
  final int newSetCount;
  final SetAdjustmentReason? adjustmentReason;
  final String? notes;

  const InWorkoutSetEditResult({
    required this.sets,
    required this.originalSetCount,
    required this.newSetCount,
    this.adjustmentReason,
    this.notes,
  });

  /// Whether sets were reduced (requires reason)
  bool get wasReduced => newSetCount < originalSetCount;

  /// Whether sets were added
  bool get wasIncreased => newSetCount > originalSetCount;
}


/// Comprehensive in-workout set editing sheet
/// Allows users to:
/// - Add/remove sets for the current exercise
/// - Adjust reps for each set
/// - Adjust weight for each set
/// - Quick buttons: "+1 set", "-1 set", "Copy last set"
/// - Reason dropdown when reducing sets
class InWorkoutSetEditingSheet extends StatefulWidget {
  /// Exercise name being edited
  final String exerciseName;

  /// Current sets data (completed + remaining)
  final List<EditableSetData> initialSets;

  /// Original prescribed number of sets
  final int originalSetCount;

  /// Index of current set being worked on (0-based)
  final int currentSetIndex;

  /// Default weight for new sets
  final double defaultWeight;

  /// Default reps for new sets
  final int defaultReps;

  /// Whether using kg (true) or lbs (false)
  final bool useKg;

  /// Callback when editing is confirmed
  final void Function(InWorkoutSetEditResult result) onConfirm;

  /// Callback when cancelled
  final VoidCallback? onCancel;

  const InWorkoutSetEditingSheet({
    super.key,
    required this.exerciseName,
    required this.initialSets,
    required this.originalSetCount,
    required this.currentSetIndex,
    required this.defaultWeight,
    required this.defaultReps,
    required this.useKg,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  State<InWorkoutSetEditingSheet> createState() => _InWorkoutSetEditingSheetState();
}

