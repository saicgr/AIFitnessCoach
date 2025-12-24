import 'package:flutter/material.dart';
import 'sheet_theme_colors.dart';
import 'selectable_chip.dart';
import 'quantity_selector.dart';
import 'section_title.dart';

/// Default list of equipment options
const List<String> defaultEquipmentOptions = [
  'Full Gym',
  'Dumbbells',
  'Barbell',
  'Kettlebell',
  'Resistance Bands',
  'Pull-up Bar',
  'Bench',
  'Cable Machine',
  'Bodyweight Only',
];

/// A widget for selecting available equipment with quantity options
class EquipmentSelector extends StatelessWidget {
  /// Currently selected equipment
  final Set<String> selectedEquipment;

  /// Callback when selection changes
  final ValueChanged<Set<String>> onSelectionChanged;

  /// Custom equipment text
  final String customEquipment;

  /// Whether the custom input field is shown
  final bool showCustomInput;

  /// Callback when custom input visibility changes
  final VoidCallback onToggleCustomInput;

  /// Callback when custom equipment is saved
  final ValueChanged<String> onCustomEquipmentSaved;

  /// Dumbbell count (1 or 2)
  final int dumbbellCount;

  /// Kettlebell count (1 or 2)
  final int kettlebellCount;

  /// Callback when dumbbell count changes
  final ValueChanged<int> onDumbbellCountChanged;

  /// Callback when kettlebell count changes
  final ValueChanged<int> onKettlebellCountChanged;

  /// Whether the selector is disabled
  final bool disabled;

  /// Custom text controller for the input field
  final TextEditingController? customInputController;

  /// List of equipment options (defaults to standard options)
  final List<String> equipmentOptions;

  const EquipmentSelector({
    super.key,
    required this.selectedEquipment,
    required this.onSelectionChanged,
    required this.customEquipment,
    required this.showCustomInput,
    required this.onToggleCustomInput,
    required this.onCustomEquipmentSaved,
    required this.dumbbellCount,
    required this.kettlebellCount,
    required this.onDumbbellCountChanged,
    required this.onKettlebellCountChanged,
    this.disabled = false,
    this.customInputController,
    this.equipmentOptions = defaultEquipmentOptions,
  });

  void _handleEquipmentTap(String equipment) {
    if (disabled) return;

    final newSelection = Set<String>.from(selectedEquipment);

    if (equipment == 'Full Gym') {
      // Full Gym selects all equipment except Bodyweight Only
      if (newSelection.contains('Full Gym')) {
        newSelection.remove('Full Gym');
      } else {
        newSelection.add('Full Gym');
        newSelection.addAll(
          equipmentOptions.where(
            (e) => e != 'Bodyweight Only' && e != 'Full Gym',
          ),
        );
      }
    } else if (newSelection.contains(equipment)) {
      newSelection.remove(equipment);
      // Also remove Full Gym if any equipment is deselected
      newSelection.remove('Full Gym');
    } else {
      newSelection.add(equipment);
      // Check if all equipment selected (except Bodyweight Only and Full Gym)
      final allEquipment = equipmentOptions.where(
        (e) => e != 'Bodyweight Only' && e != 'Full Gym',
      );
      if (allEquipment.every((e) => newSelection.contains(e))) {
        newSelection.add('Full Gym');
      }
    }

    onSelectionChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;
    final selectedCount = selectedEquipment.length +
        (customEquipment.isNotEmpty ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SectionTitle(
                icon: Icons.fitness_center,
                title: 'Equipment Available',
                iconColor: colors.success,
              ),
              const Spacer(),
              if (selectedCount > 0)
                Text(
                  '$selectedCount selected',
                  style: TextStyle(color: colors.success, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Only generate exercises with selected equipment',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...equipmentOptions.map((equipment) {
                final isSelected = selectedEquipment.contains(equipment);
                final hasQuantitySelector =
                    equipment == 'Dumbbells' || equipment == 'Kettlebell';

                return SelectableChip(
                  label: equipment,
                  isSelected: isSelected,
                  accentColor: colors.success,
                  disabled: disabled,
                  onTap: () => _handleEquipmentTap(equipment),
                  trailing: hasQuantitySelector && isSelected
                      ? QuantitySelector(
                          value: equipment == 'Dumbbells'
                              ? dumbbellCount
                              : kettlebellCount,
                          onChanged: equipment == 'Dumbbells'
                              ? onDumbbellCountChanged
                              : onKettlebellCountChanged,
                          accentColor: colors.success,
                          disabled: disabled,
                        )
                      : null,
                );
              }),
              // "Other" chip
              OtherInputChip(
                isInputShown: showCustomInput,
                customValue: customEquipment,
                accentColor: colors.success,
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
                hintText: 'Enter custom equipment (e.g., "TRX Bands")',
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
                  borderSide: BorderSide(color: colors.success),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.check, color: colors.success),
                  onPressed: () {
                    final value = customInputController?.text.trim() ?? '';
                    onCustomEquipmentSaved(value);
                  },
                ),
              ),
              style: TextStyle(color: colors.textPrimary),
              onSubmitted: (value) => onCustomEquipmentSaved(value.trim()),
            ),
          ],
        ],
      ),
    );
  }
}
