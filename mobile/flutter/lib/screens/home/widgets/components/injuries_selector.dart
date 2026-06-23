import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sheet_theme_colors.dart';
import 'selectable_chip.dart';
import 'section_title.dart';
import '../../../../widgets/body_muscle_selector.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// Default head-to-toe injury options — SAME labels/order as the onboarding
/// limitation step (`quiz_limitations.dart` `_limitationOptions`), minus the
/// `None`/`Other` bookends. The editor models "no injuries" as an empty
/// selection (so no "None" chip is needed), and "Other" is rendered as a
/// dedicated custom-input chip below (see [OtherInputChip]).
const List<String> defaultInjuries = [
  'Neck',
  'Shoulders',
  'Upper Back',
  'Chest',
  'Biceps',
  'Triceps',
  'Elbows',
  'Forearms',
  'Wrists',
  'Abs',
  'Lower Back',
  'Hips',
  'Glutes',
  'Groin',
  'Quads',
  'Hamstrings',
  'Knees',
  'Calves',
  'Ankles',
];

/// Forward map: injury chip label → backend muscle-group names the body map
/// (via [BodyMuscleSelectorWidget]) highlights for that region. Mirrors the
/// onboarding `_injuryToMuscles` table but keyed by the editor's display
/// labels. Joint labels (Knees, Elbows, …) highlight the adjacent muscles.
const Map<String, List<String>> _injuryLabelToMuscles = {
  // Joint labels → the adjacent muscle region(s).
  'Knees': ['quadriceps', 'calves'],
  'Shoulders': ['shoulders'],
  'Lower Back': ['lower_back'],
  'Wrists': ['forearms'],
  'Elbows': ['forearms', 'triceps'],
  'Hips': ['glutes', 'adductors'],
  'Ankles': ['calves'],
  'Neck': ['traps'],
  // Muscle labels → themselves (1:1 with the body map).
  'Upper Back': ['upper_back', 'lats', 'traps'],
  'Chest': ['chest'],
  'Biceps': ['biceps'],
  'Triceps': ['triceps'],
  'Forearms': ['forearms'],
  'Abs': ['abs', 'obliques'],
  'Glutes': ['glutes'],
  'Groin': ['adductors'],
  'Quads': ['quadriceps'],
  'Hamstrings': ['hamstrings'],
  'Calves': ['calves'],
};

/// Reverse map: backend muscle-group name → the injury chip label a body tap
/// should toggle. Each muscle resolves to its dedicated muscle chip (the
/// literal tap target). Joint labels have no body region to tap, so they're
/// chip-only and intentionally absent.
const Map<String, String> _muscleToInjuryLabel = {
  'quadriceps': 'Quads',
  'hamstrings': 'Hamstrings',
  'glutes': 'Glutes',
  'calves': 'Calves',
  'adductors': 'Groin',
  'abductors': 'Groin',
  'chest': 'Chest',
  'shoulders': 'Shoulders',
  'biceps': 'Biceps',
  'triceps': 'Triceps',
  'forearms': 'Forearms',
  'abs': 'Abs',
  'obliques': 'Abs',
  'core': 'Abs',
  'lats': 'Upper Back',
  'upper_back': 'Upper Back',
  'traps': 'Upper Back',
  'lower_back': 'Lower Back',
};

/// A widget for selecting injuries to avoid in workouts.
///
/// Now matches the onboarding limitation step: a compact interactive body map
/// sits above the head-to-toe chip grid. Tapping a region toggles the mapped
/// injury chip and toggling a chip re-highlights the body. The chips remain the
/// canonical, complete control (they cover joints the body can't represent).
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

  /// List of injury options (defaults to the head-to-toe standard set)
  final List<String> injuryOptions;

  /// Whether to show the subtitle explaining the purpose
  final bool showSubtitle;

  /// Optional section title override. Defaults to the existing localized
  /// "Injuries to Consider" getter when omitted.
  final String? title;

  /// Whether to show the interactive body map above the chips. Defaults to
  /// `false` so existing consumers are visually unchanged; opt in where the
  /// onboarding-style body map is wanted (the Edit Program → Injuries tab).
  final bool showBodyMap;

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
    this.title,
    this.showBodyMap = false,
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

  /// Backend muscle-group names the body map should highlight, derived purely
  /// from the current selection. Joint labels contribute their adjacent
  /// muscles; any free-text custom injury contributes nothing.
  Set<String> get _highlightedMuscles {
    final muscles = <String>{};
    for (final label in selectedInjuries) {
      final mapped = _injuryLabelToMuscles[label];
      if (mapped != null) muscles.addAll(mapped);
    }
    return muscles;
  }

  /// Map a body-map muscle toggle back to an injury chip label and apply it.
  /// The body map fires one muscle at a time; we resolve it to the canonical
  /// injury label for that muscle (see [_muscleToInjuryLabel]). Unmapped
  /// muscles are ignored.
  void _onBodyMuscleToggle(String muscle) {
    if (disabled) return;
    HapticFeedback.selectionClick();
    final injury = _muscleToInjuryLabel[muscle];
    if (injury != null) _handleInjuryTap(injury);
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
                title: title ??
                    AppLocalizations.of(context)
                        .injuriesSelectorInjuriesToConsider,
                iconColor: colors.error,
              ),
              const Spacer(),
              if (selectedCount > 0)
                Text(
                  AppLocalizations.of(context)!
                      .injuriesSelectorSelected(selectedCount),
                  style: TextStyle(color: colors.error, fontSize: 12),
                ),
            ],
          ),
          if (showSubtitle) ...[
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).injuriesSelectorAiWillAvoidExercises,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ],
          if (showBodyMap) ...[
            const SizedBox(height: 16),
            _buildBodyMap(colors),
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
                hintText: AppLocalizations.of(context).injuriesSelectorEnterCustomInjuryE,
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

  /// Compact interactive body diagram. Highlights are driven entirely by the
  /// current selection; tapping a region toggles the mapped chip.
  ///
  /// [BodyMuscleSelectorWidget] only reads its highlight set at construction
  /// (via `selectedMuscles`), so a [ValueKey] over the sorted highlight set
  /// forces a clean rebuild whenever a chip changes the selection — the same
  /// pattern onboarding uses.
  Widget _buildBodyMap(SheetColors colors) {
    final highlighted = _highlightedMuscles;
    final keySig = (highlighted.toList()..sort()).join(',');

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: colors.glassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder.withOpacity(0.4)),
      ),
      child: BodyMuscleSelectorWidget(
        key: ValueKey('injury_body_$keySig'),
        height: 240,
        selectedMuscles: highlighted,
        onMuscleToggle: _onBodyMuscleToggle,
      ),
    );
  }
}
