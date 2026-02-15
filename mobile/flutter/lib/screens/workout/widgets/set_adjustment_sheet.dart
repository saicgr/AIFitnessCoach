/// Set adjustment sheet widget
///
/// Bottom sheet for choosing adjustment reason when modifying sets during workout.
/// Provides comprehensive UI for adding/removing sets, adjusting reps/weight,
/// and quick action buttons for common adjustments.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/glass_sheet.dart';

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

/// Bottom sheet for choosing adjustment reason
class SetAdjustmentSheet extends StatefulWidget {
  /// Title for the sheet
  final String title;

  /// Subtitle/description
  final String? subtitle;

  /// Callback when adjustment is confirmed
  final void Function(SetAdjustmentReason reason, String? notes) onConfirm;

  /// Callback when cancelled
  final VoidCallback? onCancel;

  /// Whether to show notes field
  final bool showNotesField;

  const SetAdjustmentSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.onConfirm,
    this.onCancel,
    this.showNotesField = true,
  });

  @override
  State<SetAdjustmentSheet> createState() => _SetAdjustmentSheetState();
}

class _SetAdjustmentSheetState extends State<SetAdjustmentSheet> {
  SetAdjustmentReason? _selectedReason;
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _notesFocus = FocusNode();

  @override
  void dispose() {
    _notesController.dispose();
    _notesFocus.dispose();
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

  void _handleCancel() {
    HapticFeedback.lightImpact();
    widget.onCancel?.call();
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
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit_note,
                              color: AppColors.orange,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                if (widget.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _handleCancel,
                        icon: Icon(Icons.close, color: textMuted),
                        style: IconButton.styleFrom(
                          backgroundColor: cardBg,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Reason chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why are you adjusting?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SetAdjustmentReason.values.map((reason) {
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                reason.icon,
                                size: 18,
                                color: isSelected
                                    ? AppColors.orange
                                    : textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                reason.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.orange
                                      : textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Notes field
            if (widget.showNotesField) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional notes (optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      focusNode: _notesFocus,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 15,
                        color: textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'E.g., shoulder feels tight...',
                        hintStyle: TextStyle(
                          color: textMuted,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.cardBorder
                                : AppColorsLight.cardBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.cardBorder
                                : AppColorsLight.cardBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.orange,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _handleCancel,
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
                        'Cancel',
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
                        'Confirm',
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

/// Show the set adjustment sheet as a modal bottom sheet
Future<(SetAdjustmentReason, String?)?> showSetAdjustmentSheet({
  required BuildContext context,
  required String title,
  String? subtitle,
  bool showNotesField = true,
}) async {
  (SetAdjustmentReason, String?)? result;

  await showGlassSheet(
    context: context,
    builder: (context) => GlassSheet(
      showHandle: false,
      child: SetAdjustmentSheet(
        title: title,
        subtitle: subtitle,
        showNotesField: showNotesField,
        onConfirm: (reason, notes) {
          result = (reason, notes);
        },
      ),
    ),
  );

  return result;
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

/// Show skip remaining sets sheet
Future<(SetAdjustmentReason, String?)?> showSkipRemainingSetsSheet({
  required BuildContext context,
  required String exerciseName,
  required int completedSets,
  required int totalSets,
}) async {
  (SetAdjustmentReason, String?)? result;

  await showGlassSheet(
    context: context,
    builder: (context) => GlassSheet(
      showHandle: false,
      child: SkipRemainingSetsSheet(
        exerciseName: exerciseName,
        completedSets: completedSets,
        totalSets: totalSets,
        onConfirm: (reason, notes) {
          result = (reason, notes);
        },
      ),
    ),
  );

  return result;
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

class _InWorkoutSetEditingSheetState extends State<InWorkoutSetEditingSheet> {
  late List<EditableSetData> _sets;
  SetAdjustmentReason? _selectedReason;
  final TextEditingController _notesController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Deep copy initial sets
    _sets = widget.initialSets.map((s) => EditableSetData(
      reps: s.reps,
      weight: s.weight,
      isCompleted: s.isCompleted,
    )).toList();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Add a new set with default or copied values
  void _addSet({bool copyLast = false}) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (copyLast && _sets.isNotEmpty) {
        final lastSet = _sets.last;
        _sets.add(EditableSetData(
          reps: lastSet.reps,
          weight: lastSet.weight,
        ));
      } else {
        _sets.add(EditableSetData(
          reps: widget.defaultReps,
          weight: widget.defaultWeight,
        ));
      }
    });
    // Scroll to show new set
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Remove the last incomplete set
  void _removeSet() {
    if (_sets.isEmpty) return;
    // Only remove incomplete sets
    final lastIncompleteIndex = _sets.lastIndexWhere((s) => !s.isCompleted);
    if (lastIncompleteIndex >= 0) {
      HapticFeedback.mediumImpact();
      setState(() {
        _sets.removeAt(lastIncompleteIndex);
      });
    }
  }

  /// Update reps for a specific set
  void _updateReps(int setIndex, int reps) {
    if (setIndex >= _sets.length) return;
    setState(() {
      _sets[setIndex] = _sets[setIndex].copyWith(reps: reps.clamp(1, 100));
    });
  }

  /// Update weight for a specific set
  void _updateWeight(int setIndex, double weight) {
    if (setIndex >= _sets.length) return;
    setState(() {
      _sets[setIndex] = _sets[setIndex].copyWith(weight: weight.clamp(0, 1000));
    });
  }

  /// Whether a reason is required (sets were reduced)
  bool get _requiresReason => _sets.length < widget.originalSetCount;

  /// Whether confirm can be pressed
  bool get _canConfirm => !_requiresReason || _selectedReason != null;

  void _handleConfirm() {
    if (!_canConfirm) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    widget.onConfirm(InWorkoutSetEditResult(
      sets: _sets,
      originalSetCount: widget.originalSetCount,
      newSetCount: _sets.length,
      adjustmentReason: _requiresReason ? _selectedReason : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    ));
    Navigator.of(context).pop();
  }

  void _handleCancel() {
    HapticFeedback.lightImpact();
    widget.onCancel?.call();
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
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final weightUnit = widget.useKg ? 'kg' : 'lbs';

    final completedCount = _sets.where((s) => s.isCompleted).length;
    final remainingCount = _sets.length - completedCount;

    return Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.tune,
                      color: AppColors.cyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Sets',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.exerciseName,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _handleCancel,
                    icon: Icon(Icons.close, color: textMuted),
                    style: IconButton.styleFrom(
                      backgroundColor: cardBg,
                    ),
                  ),
                ],
              ),
            ),

            // Quick action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  // +1 Set button
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.add,
                      label: '+1 Set',
                      color: AppColors.cyan,
                      onTap: () => _addSet(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // -1 Set button (only if we have incomplete sets)
                  if (remainingCount > 0)
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.remove,
                        label: '-1 Set',
                        color: AppColors.orange,
                        onTap: _removeSet,
                      ),
                    ),
                  if (remainingCount > 0) const SizedBox(width: 8),
                  // Copy Last Set button
                  if (_sets.isNotEmpty)
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.content_copy,
                        label: 'Copy Last',
                        color: AppColors.purple,
                        onTap: () => _addSet(copyLast: true),
                      ),
                    ),
                ],
              ),
            ),

            // Sets count indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          '$completedCount done',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: textMuted.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$remainingCount remaining',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_sets.length != widget.originalSetCount)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _sets.length < widget.originalSetCount
                            ? AppColors.orange.withOpacity(0.1)
                            : AppColors.cyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _sets.length < widget.originalSetCount
                            ? '${widget.originalSetCount - _sets.length} removed'
                            : '+${_sets.length - widget.originalSetCount} added',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _sets.length < widget.originalSetCount
                              ? AppColors.orange
                              : AppColors.cyan,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Sets list
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shrinkWrap: true,
                itemCount: _sets.length,
                itemBuilder: (context, index) {
                  final set = _sets[index];
                  final isCompleted = set.isCompleted;
                  final isCurrent = index == widget.currentSetIndex && !isCompleted;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.success.withOpacity(0.1)
                          : isCurrent
                              ? AppColors.cyan.withOpacity(0.1)
                              : cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCompleted
                            ? AppColors.success.withOpacity(0.3)
                            : isCurrent
                                ? AppColors.cyan.withOpacity(0.5)
                                : isDark
                                    ? AppColors.cardBorder
                                    : AppColorsLight.cardBorder,
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Set number
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? AppColors.success.withOpacity(0.2)
                                : isCurrent
                                    ? AppColors.cyan.withOpacity(0.2)
                                    : textMuted.withOpacity(0.1),
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check, size: 16, color: AppColors.success)
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isCurrent ? AppColors.cyan : textSecondary,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Reps input
                        Expanded(
                          child: _SetValueEditor(
                            label: 'Reps',
                            value: set.reps.toDouble(),
                            unit: '',
                            isInteger: true,
                            enabled: !isCompleted,
                            onChanged: (v) => _updateReps(index, v.toInt()),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Weight input
                        Expanded(
                          child: _SetValueEditor(
                            label: 'Weight',
                            value: set.weight,
                            unit: weightUnit,
                            isInteger: false,
                            enabled: !isCompleted,
                            onChanged: (v) => _updateWeight(index, v),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Reason selector (only if sets were reduced)
            if (_requiresReason) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why are you reducing sets?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SetAdjustmentReason.values.map((reason) {
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.orange.withOpacity(0.15)
                                  : cardBg,
                              borderRadius: BorderRadius.circular(10),
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  reason.icon,
                                  size: 16,
                                  color: isSelected
                                      ? AppColors.orange
                                      : textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  reason.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.orange
                                        : textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 1,
                      style: TextStyle(fontSize: 14, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Additional notes (optional)',
                        hintStyle: TextStyle(color: textMuted, fontSize: 13),
                        filled: true,
                        fillColor: cardBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _handleCancel,
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
                        'Cancel',
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
                      onPressed: _canConfirm ? _handleConfirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
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
                      child: Text(
                        _requiresReason ? 'Save Changes' : 'Apply',
                        style: const TextStyle(
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

/// Quick action button widget
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Set value editor with +/- buttons
class _SetValueEditor extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final bool isInteger;
  final bool enabled;
  final void Function(double) onChanged;

  const _SetValueEditor({
    required this.label,
    required this.value,
    required this.unit,
    required this.isInteger,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final step = isInteger ? 1.0 : 2.5;
    final displayValue = isInteger
        ? value.toInt().toString()
        : value.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            // Decrease button
            GestureDetector(
              onTap: enabled
                  ? () {
                      HapticFeedback.selectionClick();
                      onChanged(value - step);
                    }
                  : null,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: enabled
                      ? AppColors.orange.withOpacity(0.15)
                      : textMuted.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.remove,
                  size: 16,
                  color: enabled ? AppColors.orange : textMuted,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '$displayValue${unit.isNotEmpty ? ' $unit' : ''}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: enabled ? textPrimary : textMuted,
                  ),
                ),
              ),
            ),
            // Increase button
            GestureDetector(
              onTap: enabled
                  ? () {
                      HapticFeedback.selectionClick();
                      onChanged(value + step);
                    }
                  : null,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: enabled
                      ? AppColors.cyan.withOpacity(0.15)
                      : textMuted.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.add,
                  size: 16,
                  color: enabled ? AppColors.cyan : textMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Show in-workout set editing sheet
Future<InWorkoutSetEditResult?> showInWorkoutSetEditingSheet({
  required BuildContext context,
  required String exerciseName,
  required List<EditableSetData> initialSets,
  required int originalSetCount,
  required int currentSetIndex,
  required double defaultWeight,
  required int defaultReps,
  bool useKg = true,
}) async {
  InWorkoutSetEditResult? result;

  await showGlassSheet(
    context: context,
    builder: (context) => GlassSheet(
      showHandle: false,
      child: InWorkoutSetEditingSheet(
        exerciseName: exerciseName,
        initialSets: initialSets,
        originalSetCount: originalSetCount,
        currentSetIndex: currentSetIndex,
        defaultWeight: defaultWeight,
        defaultReps: defaultReps,
        useKg: useKg,
        onConfirm: (r) {
          result = r;
        },
      ),
    ),
  );

  return result;
}
