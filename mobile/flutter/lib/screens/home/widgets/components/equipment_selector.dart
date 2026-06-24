import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/environment_equipment_provider.dart'
    show
        WorkoutEnvironment,
        commonEquipmentOptions,
        environmentEquipmentProvider,
        getEquipmentDisplayName;
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

/// Canonical snake_case tokens for cardio-machine equipment. When one of these
/// is shown in the picker we tag it with a small "· cardio" badge, and — on a
/// strength-style day — hint that picking it adds a cardio finisher rather than
/// reshaping the whole session. Deterministic + client-side so the badge is
/// instant and never waits on the backend.
const Set<String> _cardioEquipmentTokens = {
  'rowing_machine',
  'treadmill',
  'stationary_bike',
  'elliptical',
  'ski_erg',
  'stair_climber',
  'assault_bike',
};

/// True when [token] (already canonical, or canonicalizable) names a cardio
/// machine. Tolerant of a few common label variants the taxonomy doesn't pin
/// (e.g. "rower", "exercise bike", "stairmaster") so the badge still lands.
bool _isCardioEquipment(String token) {
  final t = _canonicalEquipmentToken(token);
  if (_cardioEquipmentTokens.contains(t)) return true;
  // A handful of synonym tokens that map onto the same machines.
  const synonyms = {
    'rower': 'rowing_machine',
    'exercise_bike': 'stationary_bike',
    'spin_bike': 'stationary_bike',
    'spinning_bike': 'stationary_bike',
    'air_bike': 'assault_bike',
    'fan_bike': 'assault_bike',
    'skierg': 'ski_erg',
    'stairmaster': 'stair_climber',
    'stepmill': 'stair_climber',
    'cross_trainer': 'elliptical',
  };
  return synonyms.containsKey(t);
}

/// Whether a workout focus reads as strength-style — i.e. NOT a cardio or
/// full-body day — for the "added as a finisher" hint. Anything we can't
/// confidently classify (or a missing focus) suppresses the hint, so we never
/// over-claim.
bool _isStrengthStyleFocus(String? focus) {
  if (focus == null) return false;
  final f = focus.toLowerCase().trim();
  if (f.isEmpty) return false;
  if (f.contains('cardio') ||
      f.contains('full_body') ||
      f.contains('full body') ||
      f.contains('conditioning') ||
      f.contains('hiit') ||
      f.contains('mobility') ||
      f.contains('recovery')) {
    return false;
  }
  return true;
}

/// A reusable searchable multi-select equipment picker.
///
/// Stores and returns the CANONICAL snake_case values from
/// [commonEquipmentOptions] so the backend can match exercises. The pinned
/// presets ([_pinnedPickerPresets]) float to the top; the rest of the taxonomy
/// follows. Returns the selected canonical tokens on confirm, or `null` if the
/// user dismisses without confirming.
///
/// [focus] is the optional day/workout focus (e.g. `'upper'`, `'cardio'`). When
/// it reads as strength-style, cardio-machine chips show a one-line "added as a
/// finisher on strength days" hint so the user knows the pick is appended, not
/// substituted.
///
/// Used by the per-day equipment override flow (`PerDayControls`).
Future<List<String>?> showEquipmentPickerSheet(
  BuildContext context, {
  required List<String> initial,
  String title = 'Equipment for this day',
  String? focus,
}) {
  return showGlassSheet<List<String>>(
    context: context,
    builder: (ctx) => _EquipmentPickerSheet(
      initial: initial,
      title: title,
      focus: focus,
    ),
  );
}

/// Canonicalize a raw equipment string (which may be a human label like
/// "Rowing Machine" or "tire, sledgehammer") into the snake_case token form the
/// picker stores and the backend matches on.
String _canonicalEquipmentToken(String raw) {
  return raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[(),]'), ' ')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

class _EquipmentPickerSheet extends ConsumerStatefulWidget {
  const _EquipmentPickerSheet({
    required this.initial,
    required this.title,
    this.focus,
  });

  final List<String> initial;
  final String title;
  final String? focus;

  @override
  ConsumerState<_EquipmentPickerSheet> createState() =>
      _EquipmentPickerSheetState();
}

class _EquipmentPickerSheetState extends ConsumerState<_EquipmentPickerSheet> {
  late final Set<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = widget.initial.toSet();
  }

  /// Canonical tokens to show, in this order (de-duped, snake_case):
  ///   1. pinned presets
  ///   2. the user's actual profile equipment (so a full-gym user sees what
  ///      they really have, not just the 37-item common taxonomy)
  ///   3. the fuller Commercial Gym master list (~88 items)
  ///   4. the common taxonomy (covers anything the above miss)
  ///   5. any currently-selected token not otherwise present
  ///
  /// A full-gym user therefore sees ~80+ items rather than ~37.
  List<String> get _orderedTokens {
    final out = <String>[];
    final seen = <String>{};

    void add(String raw) {
      final t = _canonicalEquipmentToken(raw);
      if (t.isEmpty) return;
      if (seen.add(t)) out.add(t);
    }

    for (final t in _pinnedPickerPresets) {
      if (commonEquipmentOptions.contains(t)) add(t);
    }
    // User's real profile equipment.
    for (final t in ref.read(environmentEquipmentProvider).equipment) {
      add(t);
    }
    // Fuller commercial-gym master list.
    for (final t in WorkoutEnvironment.commercialGym.defaultEquipment) {
      add(t);
    }
    // Common taxonomy backstop.
    for (final t in commonEquipmentOptions) {
      add(t);
    }
    // Never drop an already-selected token.
    for (final t in _selected) {
      add(t);
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final token in filtered)
                                SelectableChip(
                                  label: getEquipmentDisplayName(token),
                                  isSelected: _selected.contains(token),
                                  accentColor: colors.success,
                                  // Tag cardio machines so the user knows a
                                  // rower/treadmill/etc. isn't a strength move.
                                  trailing: _isCardioEquipment(token)
                                      ? _CardioBadge(color: colors.textMuted)
                                      : null,
                                  onTap: () => setState(() {
                                    if (!_selected.add(token)) {
                                      _selected.remove(token);
                                    }
                                  }),
                                ),
                            ],
                          ),
                          // On a strength-style day, a single hint that any
                          // cardio machine the user picks is appended as a
                          // finisher rather than reshaping the whole session.
                          if (_isStrengthStyleFocus(widget.focus) &&
                              filtered.any(_isCardioEquipment)) ...[
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.bolt,
                                    size: 13, color: colors.textMuted),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Added as a finisher on strength days.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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

/// Small muted "· cardio" badge rendered in a [SelectableChip]'s trailing slot
/// to flag cardio-machine equipment in the picker.
class _CardioBadge extends StatelessWidget {
  const _CardioBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '· cardio',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}
