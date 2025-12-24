import 'package:flutter/material.dart';
import 'sheet_theme_colors.dart';
import 'selectable_chip.dart';
import 'section_title.dart';

/// Default list of focus area options
const List<String> defaultFocusAreas = [
  'Chest',
  'Back',
  'Shoulders',
  'Arms',
  'Core',
  'Legs',
  'Glutes',
  'Full Body',
];

/// A widget for selecting muscle groups / focus areas
class FocusAreasSelector extends StatelessWidget {
  /// Currently selected focus areas
  final Set<String> selectedAreas;

  /// Callback when selection changes
  final ValueChanged<Set<String>> onSelectionChanged;

  /// Custom focus area text
  final String customFocusArea;

  /// Whether the custom input field is shown
  final bool showCustomInput;

  /// Callback when custom input visibility changes
  final VoidCallback onToggleCustomInput;

  /// Callback when custom focus area is saved
  final ValueChanged<String> onCustomFocusAreaSaved;

  /// Whether the selector is disabled
  final bool disabled;

  /// Custom text controller for the input field
  final TextEditingController? customInputController;

  /// List of focus area options (defaults to standard options)
  final List<String> focusAreaOptions;

  const FocusAreasSelector({
    super.key,
    required this.selectedAreas,
    required this.onSelectionChanged,
    required this.customFocusArea,
    required this.showCustomInput,
    required this.onToggleCustomInput,
    required this.onCustomFocusAreaSaved,
    this.disabled = false,
    this.customInputController,
    this.focusAreaOptions = defaultFocusAreas,
  });

  void _handleAreaTap(String area) {
    if (disabled) return;

    final newSelection = Set<String>.from(selectedAreas);
    if (newSelection.contains(area)) {
      newSelection.remove(area);
    } else {
      newSelection.add(area);
    }
    onSelectionChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;
    final selectedCount =
        selectedAreas.length + (customFocusArea.isNotEmpty ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SectionTitle(
                icon: Icons.track_changes,
                title: 'Focus Areas',
                iconColor: colors.purple,
              ),
              const Spacer(),
              if (selectedCount > 0)
                Text(
                  '$selectedCount selected',
                  style: TextStyle(color: colors.purple, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...focusAreaOptions.map((area) {
                final isSelected = selectedAreas.contains(area);
                return SelectableChip(
                  label: area,
                  isSelected: isSelected,
                  accentColor: colors.purple,
                  disabled: disabled,
                  onTap: () => _handleAreaTap(area),
                );
              }),
              // "Other" chip
              OtherInputChip(
                isInputShown: showCustomInput,
                customValue: customFocusArea,
                accentColor: colors.purple,
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
                hintText: 'Enter custom focus area (e.g., "Rotator cuff")',
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
                  borderSide: BorderSide(color: colors.purple),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.check, color: colors.purple),
                  onPressed: () {
                    final value = customInputController?.text.trim() ?? '';
                    onCustomFocusAreaSaved(value);
                  },
                ),
              ),
              style: TextStyle(color: colors.textPrimary),
              onSubmitted: (value) => onCustomFocusAreaSaved(value.trim()),
            ),
          ],
        ],
      ),
    );
  }
}
