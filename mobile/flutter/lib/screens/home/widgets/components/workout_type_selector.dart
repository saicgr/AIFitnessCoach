import 'package:flutter/material.dart';
import 'sheet_theme_colors.dart';
import 'selectable_chip.dart';
import 'section_title.dart';

/// Default list of workout type options
const List<String> defaultWorkoutTypes = [
  'Strength',
  'HIIT',
  'Cardio',
  'Flexibility',
  'Full Body',
  'Upper Body',
  'Lower Body',
  'Core',
  'Push',
  'Pull',
  'Legs',
];

/// A widget for selecting workout type
class WorkoutTypeSelector extends StatelessWidget {
  /// Currently selected workout type (null means none selected)
  final String? selectedType;

  /// Callback when selection changes
  final ValueChanged<String?> onSelectionChanged;

  /// Custom workout type text
  final String customWorkoutType;

  /// Whether the custom input field is shown
  final bool showCustomInput;

  /// Callback when custom input visibility changes
  final VoidCallback onToggleCustomInput;

  /// Callback when custom workout type is saved
  final ValueChanged<String> onCustomTypeSaved;

  /// Whether the selector is disabled
  final bool disabled;

  /// Custom text controller for the input field
  final TextEditingController? customInputController;

  /// List of workout type options (defaults to standard options)
  final List<String> workoutTypes;

  /// Whether to allow deselection (single select toggle)
  final bool allowDeselect;

  const WorkoutTypeSelector({
    super.key,
    required this.selectedType,
    required this.onSelectionChanged,
    required this.customWorkoutType,
    required this.showCustomInput,
    required this.onToggleCustomInput,
    required this.onCustomTypeSaved,
    this.disabled = false,
    this.customInputController,
    this.workoutTypes = defaultWorkoutTypes,
    this.allowDeselect = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            icon: Icons.category,
            title: 'Workout Type',
            iconColor: colors.cyan,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...workoutTypes.map((type) {
                final isSelected =
                    selectedType?.toLowerCase() == type.toLowerCase() &&
                        customWorkoutType.isEmpty;
                return GestureDetector(
                  onTap: disabled
                      ? null
                      : () {
                          if (isSelected && allowDeselect) {
                            onSelectionChanged(null);
                          } else {
                            onSelectionChanged(type);
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.cyan.withOpacity(0.2)
                          : colors.glassSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? colors.cyan
                            : colors.cardBorder.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: isSelected ? colors.cyan : colors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }),
              // "Other" chip
              OtherInputChip(
                isInputShown: showCustomInput,
                customValue: customWorkoutType,
                accentColor: colors.cyan,
                onTap: onToggleCustomInput,
                disabled: disabled,
              ),
            ],
          ),
          // Custom input field
          if (showCustomInput) ...[
            const SizedBox(height: 12),
            TextField(
              controller: customInputController,
              decoration: InputDecoration(
                hintText: 'Enter custom workout type (e.g., "Mobility")',
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                filled: true,
                fillColor: colors.glassSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cyan),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.check, color: colors.cyan),
                  onPressed: () {
                    final value = customInputController?.text.trim() ?? '';
                    onCustomTypeSaved(value);
                  },
                ),
              ),
              style: TextStyle(color: colors.textPrimary),
              onSubmitted: (value) => onCustomTypeSaved(value.trim()),
            ),
          ],
        ],
      ),
    );
  }
}
