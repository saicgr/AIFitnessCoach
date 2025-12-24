import 'package:flutter/material.dart';
import 'sheet_theme_colors.dart';
import 'selectable_chip.dart';
import 'section_title.dart';

/// Default list of injury options
const List<String> defaultInjuries = [
  'Shoulder',
  'Lower Back',
  'Knee',
  'Elbow',
  'Wrist',
  'Ankle',
  'Hip',
  'Neck',
];

/// A widget for selecting injuries to avoid in workouts
class InjuriesSelector extends StatelessWidget {
  /// Currently selected injuries
  final Set<String> selectedInjuries;

  /// Callback when selection changes
  final ValueChanged<Set<String>> onSelectionChanged;

  /// Custom injury text
  final String customInjury;

  /// Whether the custom input field is shown
  final bool showCustomInput;

  /// Callback when custom input visibility changes
  final VoidCallback onToggleCustomInput;

  /// Callback when custom injury is saved
  final ValueChanged<String> onCustomInjurySaved;

  /// Whether the selector is disabled
  final bool disabled;

  /// Custom text controller for the input field
  final TextEditingController? customInputController;

  /// List of injury options (defaults to standard options)
  final List<String> injuryOptions;

  /// Whether to show the subtitle explaining the purpose
  final bool showSubtitle;

  const InjuriesSelector({
    super.key,
    required this.selectedInjuries,
    required this.onSelectionChanged,
    required this.customInjury,
    required this.showCustomInput,
    required this.onToggleCustomInput,
    required this.onCustomInjurySaved,
    this.disabled = false,
    this.customInputController,
    this.injuryOptions = defaultInjuries,
    this.showSubtitle = true,
  });

  void _handleInjuryTap(String injury) {
    if (disabled) return;

    final newSelection = Set<String>.from(selectedInjuries);
    if (newSelection.contains(injury)) {
      newSelection.remove(injury);
    } else {
      newSelection.add(injury);
    }
    onSelectionChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;
    final selectedCount =
        selectedInjuries.length + (customInjury.isNotEmpty ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SectionTitle(
                icon: Icons.healing,
                title: 'Injuries to Consider',
                iconColor: colors.error,
              ),
              const Spacer(),
              if (selectedCount > 0)
                Text(
                  '$selectedCount selected',
                  style: TextStyle(color: colors.error, fontSize: 12),
                ),
            ],
          ),
          if (showSubtitle) ...[
            const SizedBox(height: 8),
            Text(
              'AI will avoid exercises that may aggravate these areas',
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...injuryOptions.map((injury) {
                final isSelected = selectedInjuries.contains(injury);
                return SelectableChip(
                  label: injury,
                  isSelected: isSelected,
                  accentColor: colors.error,
                  disabled: disabled,
                  onTap: () => _handleInjuryTap(injury),
                );
              }),
              // "Other" chip
              OtherInputChip(
                isInputShown: showCustomInput,
                customValue: customInjury,
                accentColor: colors.error,
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
                hintText: 'Enter custom injury (e.g., "Tennis elbow")',
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
                  borderSide: BorderSide(color: colors.error),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.check, color: colors.error),
                  onPressed: () {
                    final value = customInputController?.text.trim() ?? '';
                    onCustomInjurySaved(value);
                  },
                ),
              ),
              style: TextStyle(color: colors.textPrimary),
              onSubmitted: (value) => onCustomInjurySaved(value.trim()),
            ),
          ],
        ],
      ),
    );
  }
}
