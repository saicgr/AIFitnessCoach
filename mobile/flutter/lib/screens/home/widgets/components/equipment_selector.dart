import 'package:flutter/material.dart';
import '../../../../core/providers/environment_equipment_provider.dart'
    show commonEquipmentOptions, getEquipmentDisplayName;
import '../../../../widgets/glass_sheet.dart';
import 'sheet_theme_colors.dart';
import 'selectable_chip.dart';
import 'quantity_selector.dart';
import 'section_title.dart';

import '../../../../l10n/generated/app_localizations.dart';
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
class EquipmentSelector extends StatefulWidget {
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

  @override
  State<EquipmentSelector> createState() => _EquipmentSelectorState();
}

class _EquipmentSelectorState extends State<EquipmentSelector> {
  /// Live search query over the combined preset + taxonomy chip list.
  String _query = '';

  /// The full chip universe shown by this selector: the pinned presets first
  /// (kept verbatim so the global tab's persistence is unchanged), followed by
  /// the canonical [commonEquipmentOptions] taxonomy rendered with
  /// human-readable labels. De-duplicated so a preset that already covers a
  /// taxonomy entry isn't shown twice.
  ///
  /// Each entry is `(value, label)`. For the presets `value == label` (the
  /// chips store the capitalized preset string, as before). For taxonomy
  /// entries `value` is the snake_case canonical token and `label` is its
  /// human-readable form — but to preserve the existing global-tab persistence
  /// (capitalized presets), taxonomy chips that DON'T map to a preset still
  /// store their human-readable label, matching how the parent treats the set.
  List<({String value, String label})> get _allOptions {
    final out = <({String value, String label})>[];
    final seenLabels = <String>{};

    // Pinned presets first, in their declared order.
    for (final preset in widget.equipmentOptions) {
      final key = preset.toLowerCase();
      if (seenLabels.add(key)) {
        out.add((value: preset, label: preset));
      }
    }

    // Full canonical taxonomy, human-readable, skipping anything a preset
    // already covers (by case-insensitive label match).
    for (final token in commonEquipmentOptions) {
      final label = getEquipmentDisplayName(token);
      final key = label.toLowerCase();
      if (seenLabels.add(key)) {
        out.add((value: label, label: label));
      }
    }

    return out;
  }

  List<({String value, String label})> get _filteredOptions {
    final q = _query.trim().toLowerCase();
    final all = _allOptions;
    if (q.isEmpty) return all;
    return all
        .where((o) => o.label.toLowerCase().contains(q))
        .toList(growable: false);
  }

  void _handleEquipmentTap(String equipment) {
    if (widget.disabled) return;

    final newSelection = Set<String>.from(widget.selectedEquipment);

    if (equipment == 'Full Gym') {
      // Full Gym selects all preset equipment except Bodyweight Only
      if (newSelection.contains('Full Gym')) {
        newSelection.remove('Full Gym');
      } else {
        newSelection.add('Full Gym');
        newSelection.addAll(
          widget.equipmentOptions.where(
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
      // Check if all preset equipment selected (except Bodyweight Only / Full Gym)
      final allEquipment = widget.equipmentOptions.where(
        (e) => e != 'Bodyweight Only' && e != 'Full Gym',
      );
      if (allEquipment.every((e) => newSelection.contains(e))) {
        newSelection.add('Full Gym');
      }
    }

    widget.onSelectionChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;
    final selectedCount = widget.selectedEquipment.length +
        (widget.customEquipment.isNotEmpty ? 1 : 0);
    final filtered = _filteredOptions;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SectionTitle(
                icon: Icons.fitness_center,
                title: AppLocalizations.of(context).equipmentSelectorEquipmentAvailable,
                iconColor: colors.success,
              ),
              const Spacer(),
              if (selectedCount > 0)
                Text(
                  AppLocalizations.of(context).equipmentSelectorSelected(selectedCount),
                  style: TextStyle(color: colors.success, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).equipmentSelectorOnlyGenerateExercisesWith,
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          const SizedBox(height: 12),
          // Search field — filters the combined preset + taxonomy chip list.
          TextField(
            enabled: !widget.disabled,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search equipment…',
              hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: colors.textMuted, size: 20),
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
                horizontal: 12,
                vertical: 10,
              ),
            ),
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No equipment matches "$_query"',
                style: TextStyle(fontSize: 13, color: colors.textMuted),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...filtered.map((opt) {
                  final equipment = opt.value;
                  final isSelected =
                      widget.selectedEquipment.contains(equipment);
                  final hasQuantitySelector =
                      equipment == 'Dumbbells' || equipment == 'Kettlebell';

                  return SelectableChip(
                    label: opt.label,
                    isSelected: isSelected,
                    accentColor: colors.success,
                    disabled: widget.disabled,
                    onTap: () => _handleEquipmentTap(equipment),
                    trailing: hasQuantitySelector && isSelected
                        ? QuantitySelector(
                            value: equipment == 'Dumbbells'
                                ? widget.dumbbellCount
                                : widget.kettlebellCount,
                            onChanged: equipment == 'Dumbbells'
                                ? widget.onDumbbellCountChanged
                                : widget.onKettlebellCountChanged,
                            accentColor: colors.success,
                            disabled: widget.disabled,
                          )
                        : null,
                  );
                }),
                // "Other" chip — only when not actively filtering, so the
                // custom-entry affordance stays where users expect it.
                if (_query.trim().isEmpty)
                  OtherInputChip(
                    isInputShown: widget.showCustomInput,
                    customValue: widget.customEquipment,
                    accentColor: colors.success,
                    onTap: widget.onToggleCustomInput,
                    disabled: widget.disabled,
                  ),
              ],
            ),
          // Custom input field
          if (widget.showCustomInput) ...[
            const SizedBox(height: 12),
            TextField(
              controller: widget.customInputController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).equipmentSelectorEnterCustomEquipmentE,
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
                    final value =
                        widget.customInputController?.text.trim() ?? '';
                    widget.onCustomEquipmentSaved(value);
                  },
                ),
              ),
              style: TextStyle(color: colors.textPrimary),
              onSubmitted: (value) =>
                  widget.onCustomEquipmentSaved(value.trim()),
            ),
          ],
        ],
      ),
    );
  }
}

/// Equipment presets pinned to the top of the searchable picker, expressed as
/// canonical snake_case tokens (the values [showEquipmentPickerSheet] stores).
///
/// These mirror the most common gym setups so the per-day picker leads with
/// the equipment people reach for first, then exposes the full taxonomy below.
const List<String> _pinnedPickerPresets = [
  'dumbbells',
  'barbell',
  'kettlebells',
  'resistance_bands',
  'pull_up_bar',
  'cable_machine',
  'bench_press',
  'squat_rack',
];

/// A reusable searchable multi-select equipment picker.
///
/// Stores and returns the CANONICAL snake_case values from
/// [commonEquipmentOptions] so the backend can match exercises. The pinned
/// presets ([_pinnedPickerPresets]) float to the top; the rest of the taxonomy
/// follows. Returns the selected canonical tokens on confirm, or `null` if the
/// user dismisses without confirming.
///
/// Used by the per-day equipment override flow (`PerDayControls`).
Future<List<String>?> showEquipmentPickerSheet(
  BuildContext context, {
  required List<String> initial,
  String title = 'Equipment for this day',
}) {
  return showGlassSheet<List<String>>(
    context: context,
    builder: (ctx) => _EquipmentPickerSheet(
      initial: initial,
      title: title,
    ),
  );
}

class _EquipmentPickerSheet extends StatefulWidget {
  const _EquipmentPickerSheet({
    required this.initial,
    required this.title,
  });

  final List<String> initial;
  final String title;

  @override
  State<_EquipmentPickerSheet> createState() => _EquipmentPickerSheetState();
}

class _EquipmentPickerSheetState extends State<_EquipmentPickerSheet> {
  late final Set<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = widget.initial.toSet();
  }

  /// Canonical tokens, presets first then the remaining taxonomy, de-duped.
  List<String> get _orderedTokens {
    final out = <String>[];
    final seen = <String>{};
    for (final t in _pinnedPickerPresets) {
      if (commonEquipmentOptions.contains(t) && seen.add(t)) out.add(t);
    }
    for (final t in commonEquipmentOptions) {
      if (seen.add(t)) out.add(t);
    }
    return out;
  }

  List<String> get _filteredTokens {
    final q = _query.trim().toLowerCase();
    final all = _orderedTokens;
    if (q.isEmpty) return all;
    return all
        .where((t) => getEquipmentDisplayName(t).toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;
    final filtered = _filteredTokens;

    return GlassSheet(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: colors.success, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${_selected.length} selected',
                  style: TextStyle(color: colors.success, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              autofocus: false,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search equipment…',
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                prefixIcon:
                    Icon(Icons.search, color: colors.textMuted, size: 20),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No equipment matches "$_query"',
                        style:
                            TextStyle(fontSize: 13, color: colors.textMuted),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final token in filtered)
                            SelectableChip(
                              label: getEquipmentDisplayName(token),
                              isSelected: _selected.contains(token),
                              accentColor: colors.success,
                              onTap: () => setState(() {
                                if (!_selected.add(token)) {
                                  _selected.remove(token);
                                }
                              }),
                            ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(_selected.clear),
                  child: Text(
                    'Clear',
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.success,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () =>
                      Navigator.of(context).pop(_selected.toList()),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
