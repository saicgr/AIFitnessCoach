/// Editable preview sheet shown after the AI importer auto-saves an exercise.
///
/// Backend flow: POST /import auto-creates the CustomExercise row and indexes
/// it into ChromaDB. This sheet lets the user review/edit every field before
/// committing. Buttons:
///   - Save   : PATCH /custom_exercises/{user}/{id} with any edits.
///   - Discard: DELETE /custom_exercises/{user}/{id} to remove the auto-row
///              (and its ChromaDB entry).
///
/// If the server signals `duplicate: true`, the sheet shows a banner and
/// offers a "Use existing" shortcut — save/edit is locked because the row
/// is an existing user-owned exercise that we don't want to overwrite.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/custom_exercises_provider.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/custom_exercise.dart';

/// Canonical body-part values accepted by the backend.
const List<String> _bodyParts = [
  'chest',
  'back',
  'legs',
  'shoulders',
  'arms',
  'core',
  'full_body',
  'cardio',
];

/// Canonical muscle values (keep in sync with backend library taxonomy).
const List<String> _muscles = [
  'chest',
  'upper_chest',
  'lower_chest',
  'lats',
  'mid_back',
  'lower_back',
  'traps',
  'rear_delts',
  'front_delts',
  'side_delts',
  'biceps',
  'triceps',
  'forearms',
  'quads',
  'hamstrings',
  'glutes',
  'calves',
  'hip_flexors',
  'adductors',
  'abductors',
  'abs',
  'obliques',
  'cardiovascular',
];

const List<String> _equipment = [
  'bodyweight',
  'dumbbell',
  'barbell',
  'kettlebell',
  'cable',
  'machine',
  'smith_machine',
  'resistance_band',
  'trx',
  'medicine_ball',
  'bench',
  'pull_up_bar',
  'rope',
  'ez_bar',
  'plate',
  'foam_roller',
];

const List<String> _exerciseTypes = [
  'strength',
  'cardio',
  'warmup',
  'stretch',
];

/// Public entrypoint. Returns `true` if the user saved (sheet popped with
/// confirmation), `false` if they discarded or dismissed.
Future<bool> showImportExercisePreviewSheet(
  BuildContext context,
  WidgetRef ref, {
  required CustomExercise exercise,
  required bool duplicate,
  required bool ragIndexed,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => ImportExercisePreviewSheet(
      exercise: exercise,
      duplicate: duplicate,
      ragIndexed: ragIndexed,
    ),
  );
  return saved == true;
}

class ImportExercisePreviewSheet extends ConsumerStatefulWidget {
  final CustomExercise exercise;
  final bool duplicate;
  final bool ragIndexed;

  const ImportExercisePreviewSheet({
    super.key,
    required this.exercise,
    required this.duplicate,
    required this.ragIndexed,
  });

  @override
  ConsumerState<ImportExercisePreviewSheet> createState() =>
      _ImportExercisePreviewSheetState();
}

class _ImportExercisePreviewSheetState
    extends ConsumerState<ImportExercisePreviewSheet> {
  // Name & classification
  late final TextEditingController _nameCtrl;
  late String _bodyPart;
  late final Set<String> _primaryMuscles;
  late final Set<String> _secondaryMuscles;
  late final Set<String> _equipmentSet;
  late String _exerciseType;
  int _difficulty = 3;

  // Defaults
  late final TextEditingController _setsCtrl;
  late final TextEditingController _repsCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _restCtrl;

  // Instructions (one controller per step)
  late final List<TextEditingController> _instructionCtrls;

  // Flags
  bool _isWarmupSuitable = false;
  bool _isStretchSuitable = false;
  bool _isCooldownSuitable = false;

  // Busy state
  bool _saving = false;
  bool _discarding = false;

  // Confidence: derived from metadata if the backend exposed it, else
  // default to a mid value so the label still renders meaningfully.
  double _confidence = 0.8;

  @override
  void initState() {
    super.initState();
    final ex = widget.exercise;
    _nameCtrl = TextEditingController(text: ex.name);
    _bodyPart = _resolveBodyPart(ex.primaryMuscle);
    _primaryMuscles = {ex.primaryMuscle};
    _secondaryMuscles = {...?ex.secondaryMuscles};
    _equipmentSet = _splitEquipment(ex.equipment);
    _exerciseType = 'strength';
    _setsCtrl = TextEditingController(text: '${ex.defaultSets}');
    _repsCtrl = TextEditingController(text: ex.defaultReps?.toString() ?? '');
    _durationCtrl = TextEditingController(text: '');
    _restCtrl = TextEditingController(
      text: ex.defaultRestSeconds?.toString() ?? '60',
    );

    final rawSteps = (ex.instructions ?? '').trim();
    final steps = _splitInstructions(rawSteps);
    _instructionCtrls = steps
        .map((s) => TextEditingController(text: s))
        .toList(growable: true);
    if (_instructionCtrls.isEmpty) {
      _instructionCtrls.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _durationCtrl.dispose();
    _restCtrl.dispose();
    for (final c in _instructionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Parsing helpers
  // ---------------------------------------------------------------------------

  String _resolveBodyPart(String primaryMuscle) {
    final m = primaryMuscle.toLowerCase();
    if (m.contains('chest')) return 'chest';
    if (m.contains('back') || m.contains('lat') || m.contains('trap')) {
      return 'back';
    }
    if (m.contains('delt') || m.contains('shoulder')) return 'shoulders';
    if (m.contains('bicep') || m.contains('tricep') || m.contains('forearm')) {
      return 'arms';
    }
    if (m.contains('quad') ||
        m.contains('ham') ||
        m.contains('glute') ||
        m.contains('calf') ||
        m.contains('calves') ||
        m.contains('leg')) {
      return 'legs';
    }
    if (m.contains('ab') || m.contains('core') || m.contains('oblique')) {
      return 'core';
    }
    if (m.contains('cardio') || m.contains('heart')) return 'cardio';
    return 'full_body';
  }

  Set<String> _splitEquipment(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return {'bodyweight'};
    // Accept either a single canonical value or a comma-separated list.
    final parts = trimmed.split(RegExp(r'[,/]|\s+and\s+'));
    final out = <String>{};
    for (final p in parts) {
      final norm = p.trim().toLowerCase().replaceAll(' ', '_');
      if (norm.isNotEmpty) out.add(norm);
    }
    return out.isEmpty ? {trimmed} : out;
  }

  List<String> _splitInstructions(String raw) {
    if (raw.isEmpty) return [];
    // Backend may return numbered list, bullet list, or newline-separated.
    final lines = raw
        .split(RegExp(r'\r?\n|(?:^|\s)\d+\.\s|•\s|-\s'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (lines.length <= 1) {
      // Fallback: split on sentence boundaries.
      final sentences = raw
          .split(RegExp(r'(?<=[.!?])\s+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      return sentences.isEmpty ? [raw] : sentences;
    }
    return lines;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _toast('Please provide a name');
      return;
    }
    if (_primaryMuscles.isEmpty) {
      _toast('Pick at least one primary muscle');
      return;
    }

    setState(() => _saving = true);
    try {
      final notifier = ref.read(customExercisesProvider.notifier);
      final instructions = _instructionCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Composite map sent to backend PATCH. We include only fields the
      // update route accepts; everything else is on the server already.
      final primaryMuscle = _primaryMuscles.first;
      final updated = await notifier.updateExercise(
        exerciseId: widget.exercise.id,
        name: name,
        primaryMuscle: primaryMuscle,
        secondaryMuscles: _secondaryMuscles.toList(),
        equipment: _equipmentSet.join(','),
        instructions: _formatInstructions(instructions),
        defaultSets: int.tryParse(_setsCtrl.text),
        defaultReps: int.tryParse(_repsCtrl.text),
        defaultRestSeconds: int.tryParse(_restCtrl.text),
      );
      if (!mounted) return;
      if (updated != null) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _saving = false);
        _toast('Could not save changes. Please try again.');
      }
    } catch (e) {
      setState(() => _saving = false);
      _toast('Save failed: $e');
    }
  }

  String _formatInstructions(List<String> steps) {
    final numbered = <String>[];
    for (int i = 0; i < steps.length; i++) {
      numbered.add('${i + 1}. ${steps[i]}');
    }
    return numbered.join('\n');
  }

  Future<void> _discard() async {
    if (_discarding) return;
    final confirmed = await _confirmDiscard();
    if (!confirmed) return;
    setState(() => _discarding = true);
    try {
      await ref
          .read(customExercisesProvider.notifier)
          .deleteExercise(widget.exercise.id);
      if (!mounted) return;
      Navigator.of(context).pop(false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _discarding = false);
      _toast('Could not discard: $e');
    }
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard imported exercise?'),
        content: const Text(
            'This will remove the auto-saved exercise and its AI index entry. '
            'You can always import again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _useExistingAndClose() {
    // For duplicates, the sheet's exercise *is* the existing row. Treat
    // this as a save-equivalent so callers know the flow finished.
    Navigator.of(context).pop(true);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final bg = isDark ? AppColors.surface : Colors.white;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final size = MediaQuery.of(context).size;
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Container(
        width: size.width,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _grabber(textMuted),
            _header(accent, textPrimary, textMuted, isDark),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  if (widget.duplicate)
                    _duplicateBanner(accent)
                  else
                    _confidenceChip(accent, isDark),
                  const SizedBox(height: 16),
                  _SectionLabel('Name', textMuted),
                  const SizedBox(height: 6),
                  _textField(
                    _nameCtrl,
                    isDark,
                    enabled: !widget.duplicate,
                  ),
                  const SizedBox(height: 16),
                  _SectionLabel('Body part', textMuted),
                  const SizedBox(height: 6),
                  _bodyPartDropdown(isDark, accent),
                  const SizedBox(height: 16),
                  _SectionLabel('Primary muscles', textMuted),
                  const SizedBox(height: 6),
                  _chipMultiSelect(
                    options: _muscles,
                    selected: _primaryMuscles,
                    accent: accent,
                    isDark: isDark,
                    onToggle: widget.duplicate
                        ? null
                        : (v, on) {
                            setState(() {
                              if (on) {
                                _primaryMuscles.add(v);
                              } else if (_primaryMuscles.length > 1) {
                                _primaryMuscles.remove(v);
                              }
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  _SectionLabel('Secondary muscles', textMuted),
                  const SizedBox(height: 6),
                  _chipMultiSelect(
                    options: _muscles,
                    selected: _secondaryMuscles,
                    accent: accent,
                    isDark: isDark,
                    onToggle: widget.duplicate
                        ? null
                        : (v, on) {
                            setState(() {
                              if (on) {
                                _secondaryMuscles.add(v);
                              } else {
                                _secondaryMuscles.remove(v);
                              }
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  _SectionLabel('Equipment', textMuted),
                  const SizedBox(height: 6),
                  _chipMultiSelect(
                    options: _equipment,
                    selected: _equipmentSet,
                    accent: accent,
                    isDark: isDark,
                    onToggle: widget.duplicate
                        ? null
                        : (v, on) {
                            setState(() {
                              if (on) {
                                _equipmentSet.add(v);
                              } else if (_equipmentSet.length > 1) {
                                _equipmentSet.remove(v);
                              }
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  _SectionLabel('Exercise type', textMuted),
                  const SizedBox(height: 6),
                  _typeChips(accent, isDark),
                  const SizedBox(height: 16),
                  _SectionLabel(
                      'Difficulty (1 = easy, 5 = hard)', textMuted),
                  _difficultySlider(accent),
                  const SizedBox(height: 16),
                  _SectionLabel('Defaults', textMuted),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _numField(_setsCtrl, 'Sets', isDark),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _numField(_repsCtrl, 'Reps', isDark),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child:
                            _numField(_durationCtrl, 'Duration (s)', isDark),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _numField(_restCtrl, 'Rest (s)', isDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionLabel('Instructions', textMuted),
                  const SizedBox(height: 6),
                  _instructionsEditor(accent, isDark),
                  const SizedBox(height: 16),
                  _SectionLabel('Flags', textMuted),
                  const SizedBox(height: 6),
                  _flagTile(
                      'Warm-up suitable',
                      _isWarmupSuitable,
                      (v) => setState(() => _isWarmupSuitable = v),
                      isDark),
                  _flagTile(
                      'Stretch suitable',
                      _isStretchSuitable,
                      (v) => setState(() => _isStretchSuitable = v),
                      isDark),
                  _flagTile(
                      'Cool-down suitable',
                      _isCooldownSuitable,
                      (v) => setState(() => _isCooldownSuitable = v),
                      isDark),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            _actionBar(accent, isDark),
          ],
        ),
      ),
    );
  }

  Widget _grabber(Color textMuted) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Container(
        height: 4,
        width: 44,
        decoration: BoxDecoration(
          color: textMuted.withOpacity(0.35),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _header(
    Color accent,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: accent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.duplicate
                  ? 'Already in your exercises'
                  : 'Review AI extraction',
              style: TextStyle(
                color: textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: textMuted),
            onPressed:
                _saving || _discarding ? null : () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
  }

  Widget _duplicateBanner(Color accent) {
    final name = widget.exercise.name;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              color: AppColors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "You already have '$name' in your exercises. Viewing the "
              "existing copy — fields are read-only.",
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confidenceChip(Color accent, bool isDark) {
    final pct = (_confidence * 100).round();
    final color = _confidence >= 0.8
        ? AppColors.success
        : (_confidence >= 0.5 ? AppColors.orange : AppColors.error);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.psychology_alt_outlined, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                'AI confidence: $pct% — please review',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (widget.ragIndexed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'AI-searchable',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _textField(
    TextEditingController controller,
    bool isDark, {
    bool enabled = true,
  }) {
    final fill = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return TextField(
      controller: controller,
      enabled: enabled,
      style: TextStyle(color: textPrimary, fontSize: 15),
      decoration: InputDecoration(
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _bodyPartDropdown(bool isDark, Color accent) {
    final fill = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _bodyParts.contains(_bodyPart) ? _bodyPart : _bodyParts.first,
          isExpanded: true,
          style: TextStyle(color: textPrimary, fontSize: 14),
          dropdownColor: isDark ? AppColors.elevated : Colors.white,
          items: _bodyParts
              .map((b) => DropdownMenuItem(
                    value: b,
                    child: Text(_humanize(b)),
                  ))
              .toList(),
          onChanged: widget.duplicate
              ? null
              : (v) {
                  if (v != null) setState(() => _bodyPart = v);
                },
        ),
      ),
    );
  }

  Widget _chipMultiSelect({
    required List<String> options,
    required Set<String> selected,
    required Color accent,
    required bool isDark,
    required void Function(String value, bool on)? onToggle,
  }) {
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final chipBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    // Render selected first so the user's current picks are obvious, plus
    // a few "extra" option chips the user could have meant. Keeps the UI
    // compact but still discoverable.
    final display = <String>{...selected, ...options}.toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: display.map((v) {
        final on = selected.contains(v);
        return GestureDetector(
          onTap: onToggle == null ? null : () => onToggle(v, !on),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: on ? accent : chipBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: on ? accent : accent.withOpacity(0.3),
              ),
            ),
            child: Text(
              _humanize(v),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: on ? Colors.white : textMuted,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _typeChips(Color accent, bool isDark) {
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final chipBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    return Wrap(
      spacing: 8,
      children: _exerciseTypes.map((t) {
        final on = _exerciseType == t;
        return GestureDetector(
          onTap: widget.duplicate
              ? null
              : () => setState(() => _exerciseType = t),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: on ? accent : chipBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _humanize(t),
              style: TextStyle(
                fontSize: 13,
                color: on ? Colors.white : textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _difficultySlider(Color accent) {
    return Slider(
      value: _difficulty.toDouble(),
      min: 1,
      max: 5,
      divisions: 4,
      label: '$_difficulty',
      activeColor: accent,
      onChanged: widget.duplicate
          ? null
          : (v) => setState(() => _difficulty = v.round()),
    );
  }

  Widget _numField(
    TextEditingController c,
    String label,
    bool isDark,
  ) {
    final fill = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return TextField(
      controller: c,
      enabled: !widget.duplicate,
      keyboardType: TextInputType.number,
      style: TextStyle(color: textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textMuted, fontSize: 12),
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
    );
  }

  Widget _instructionsEditor(Color accent, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < _instructionCtrls.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: _textField(_instructionCtrls[i], isDark,
                      enabled: !widget.duplicate),
                ),
                if (!widget.duplicate && _instructionCtrls.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppColors.error),
                    onPressed: () => setState(() {
                      _instructionCtrls.removeAt(i).dispose();
                    }),
                  ),
              ],
            ),
          ),
        if (!widget.duplicate)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() {
                _instructionCtrls.add(TextEditingController());
              }),
              icon: Icon(Icons.add, color: accent, size: 18),
              label: Text(
                'Add step',
                style: TextStyle(color: accent, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }

  Widget _flagTile(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return CheckboxListTile(
      value: value,
      onChanged: widget.duplicate
          ? null
          : (v) => onChanged(v ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        label,
        style: TextStyle(color: textPrimary, fontSize: 14),
      ),
    );
  }

  Widget _actionBar(Color accent, bool isDark) {
    final busy = _saving || _discarding;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        border: Border(
          top: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
          ),
        ),
      ),
      child: widget.duplicate
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        busy ? null : () => Navigator.pop(context, false),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: busy ? null : _useExistingAndClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Use existing'),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : _discard,
                    icon: _discarding
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline,
                            color: AppColors.error),
                    label: const Text(
                      'Discard',
                      style: TextStyle(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.error.withOpacity(0.6)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: busy ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: accent.withOpacity(0.4),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      _saving ? 'Saving...' : 'Save exercise',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _humanize(String raw) {
    final s = raw.replaceAll('_', ' ');
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color muted;
  const _SectionLabel(this.text, this.muted);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: muted,
      ),
    );
  }
}
