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


part 'set_adjustment_sheet_part_set_adjustment_reason.dart';
part 'set_adjustment_sheet_part_in_workout_set_editing_sheet_state.dart';


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
