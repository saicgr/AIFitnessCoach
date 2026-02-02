/// AI Input Preview Sheet
///
/// Bottom sheet showing parsed sets to log AND exercises to add for user confirmation.
/// Supports the dual-mode V2 AI parsing system.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/parsed_exercise.dart';
import '../../../widgets/exercise_image.dart';

/// Result from the AI input preview sheet
class AIInputPreviewResult {
  final List<SetToLog> setsToLog;
  final List<ExerciseToAdd> exercisesToAdd;

  const AIInputPreviewResult({
    required this.setsToLog,
    required this.exercisesToAdd,
  });

  bool get hasData => setsToLog.isNotEmpty || exercisesToAdd.isNotEmpty;
}

/// Show the AI input preview sheet
Future<AIInputPreviewResult?> showAIInputPreview(
  BuildContext context,
  WidgetRef ref, {
  required ParseWorkoutInputV2Response response,
  required String? currentExerciseName,
  required bool useKg,
}) async {
  return await showModalBottomSheet<AIInputPreviewResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (context) => _AIInputPreviewSheet(
      response: response,
      currentExerciseName: currentExerciseName,
      useKg: useKg,
    ),
  );
}

class _AIInputPreviewSheet extends ConsumerStatefulWidget {
  final ParseWorkoutInputV2Response response;
  final String? currentExerciseName;
  final bool useKg;

  const _AIInputPreviewSheet({
    required this.response,
    required this.currentExerciseName,
    required this.useKg,
  });

  @override
  ConsumerState<_AIInputPreviewSheet> createState() =>
      _AIInputPreviewSheetState();
}

class _AIInputPreviewSheetState extends ConsumerState<_AIInputPreviewSheet> {
  late List<SetToLog> _sets;
  late List<ExerciseToAdd> _exercises;
  late Set<int> _selectedSetIndices;
  late Set<int> _selectedExerciseIndices;

  @override
  void initState() {
    super.initState();
    _sets = List.from(widget.response.setsToLog);
    _exercises = List.from(widget.response.exercisesToAdd);
    // Select all by default
    _selectedSetIndices = Set.from(List.generate(_sets.length, (i) => i));
    _selectedExerciseIndices =
        Set.from(List.generate(_exercises.length, (i) => i));
  }

  void _toggleSetSelection(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedSetIndices.contains(index)) {
        _selectedSetIndices.remove(index);
      } else {
        _selectedSetIndices.add(index);
      }
    });
  }

  void _toggleExerciseSelection(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedExerciseIndices.contains(index)) {
        _selectedExerciseIndices.remove(index);
      } else {
        _selectedExerciseIndices.add(index);
      }
    });
  }

  void _toggleSelectAllSets() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedSetIndices.length == _sets.length) {
        _selectedSetIndices.clear();
      } else {
        _selectedSetIndices = Set.from(List.generate(_sets.length, (i) => i));
      }
    });
  }

  void _toggleSelectAllExercises() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedExerciseIndices.length == _exercises.length) {
        _selectedExerciseIndices.clear();
      } else {
        _selectedExerciseIndices =
            Set.from(List.generate(_exercises.length, (i) => i));
      }
    });
  }

  void _editSet(int index) async {
    final set = _sets[index];
    final edited = await _showEditSetDialog(set);
    if (edited != null) {
      setState(() {
        _sets[index] = edited;
      });
    }
  }

  void _editExercise(int index) async {
    final exercise = _exercises[index];
    final edited = await _showEditExerciseDialog(exercise);
    if (edited != null) {
      setState(() {
        _exercises[index] = edited;
      });
    }
  }

  Future<SetToLog?> _showEditSetDialog(SetToLog set) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weightController = TextEditingController(
      text: set.weight > 0 ? set.weight.toString() : '',
    );
    final repsController = TextEditingController(
      text: set.reps.toString(),
    );
    bool isBodyweight = set.isBodyweight;

    return await showDialog<SetToLog>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.elevated : Colors.white,
          title: Text(
            'Edit Set',
            style: TextStyle(
              color: isDark ? AppColors.textPrimary : Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bodyweight toggle
              SwitchListTile(
                title: Text(
                  'Bodyweight',
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimary : Colors.black87,
                  ),
                ),
                value: isBodyweight,
                onChanged: (value) {
                  setDialogState(() {
                    isBodyweight = value;
                    if (value) {
                      weightController.text = '';
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              if (!isBodyweight)
                _buildEditField(
                  'Weight (${widget.useKg ? 'kg' : 'lbs'})',
                  weightController,
                  isDark,
                ),
              if (!isBodyweight) const SizedBox(height: 12),
              _buildEditField('Reps', repsController, isDark),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? AppColors.textMuted : Colors.grey.shade600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final weight =
                    double.tryParse(weightController.text) ?? set.weight;
                final reps = int.tryParse(repsController.text) ?? set.reps;

                final edited = SetToLog(
                  weight: isBodyweight ? 0 : weight,
                  reps: reps,
                  unit: set.unit,
                  isBodyweight: isBodyweight,
                  isFailure: set.isFailure,
                  isWarmup: set.isWarmup,
                  originalInput: set.originalInput,
                  notes: set.notes,
                );
                Navigator.pop(context, edited);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<ExerciseToAdd?> _showEditExerciseDialog(ExerciseToAdd exercise) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final setsController =
        TextEditingController(text: exercise.sets.toString());
    final repsController =
        TextEditingController(text: exercise.reps.toString());
    final weightController = TextEditingController(
      text: widget.useKg
          ? (exercise.weightKg?.toString() ?? '')
          : (exercise.weightLbs?.toString() ?? ''),
    );

    return await showDialog<ExerciseToAdd>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : Colors.white,
        title: Text(
          'Edit ${exercise.name}',
          style: TextStyle(
            color: isDark ? AppColors.textPrimary : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEditField('Sets', setsController, isDark),
            const SizedBox(height: 12),
            _buildEditField('Reps', repsController, isDark),
            const SizedBox(height: 12),
            _buildEditField(
              'Weight (${widget.useKg ? 'kg' : 'lbs'})',
              weightController,
              isDark,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textMuted : Colors.grey.shade600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final sets = int.tryParse(setsController.text) ?? exercise.sets;
              final reps = int.tryParse(repsController.text) ?? exercise.reps;
              final weight = double.tryParse(weightController.text);

              final edited = ExerciseToAdd(
                name: exercise.name,
                sets: sets,
                reps: reps,
                weightKg:
                    widget.useKg ? weight : weight?.let((w) => w / 2.20462),
                weightLbs:
                    widget.useKg ? weight?.let((w) => w * 2.20462) : weight,
                restSeconds: exercise.restSeconds,
                isBodyweight: exercise.isBodyweight,
                originalText: exercise.originalText,
                confidence: exercise.confidence,
                notes: exercise.notes,
              );
              Navigator.pop(context, edited);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(
      String label, TextEditingController controller, bool isDark) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        color: isDark ? AppColors.textPrimary : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? AppColors.textMuted : Colors.grey.shade600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  void _confirmSelection() {
    final selectedSets = _selectedSetIndices.map((i) => _sets[i]).toList();
    final selectedExercises =
        _selectedExerciseIndices.map((i) => _exercises[i]).toList();

    Navigator.pop(
      context,
      AIInputPreviewResult(
        setsToLog: selectedSets,
        exercisesToAdd: selectedExercises,
      ),
    );
  }

  int get _totalSelectedCount =>
      _selectedSetIndices.length + _selectedExerciseIndices.length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);
    final textPrimary = isDark ? AppColors.textPrimary : Colors.black87;
    final textMuted = isDark ? AppColors.textMuted : Colors.grey.shade600;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nearBlack : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: accentColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.response.summary,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Warnings
          if (widget.response.warnings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.yellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.yellow.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: AppColors.yellow,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.response.warnings.join('\n'),
                        style: TextStyle(
                          fontSize: 13,
                          color: textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Content
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // Sets to log section
                if (_sets.isNotEmpty) ...[
                  _buildSectionHeader(
                    icon: Icons.fitness_center,
                    title:
                        'Log ${_sets.length} set${_sets.length == 1 ? '' : 's'} for "${widget.currentExerciseName ?? 'Current Exercise'}"',
                    selectedCount: _selectedSetIndices.length,
                    totalCount: _sets.length,
                    onToggleAll: _toggleSelectAllSets,
                    accentColor: accentColor,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  ..._sets.asMap().entries.map((entry) {
                    final index = entry.key;
                    final set = entry.value;
                    final isSelected = _selectedSetIndices.contains(index);

                    return _SetPreviewTile(
                      set: set,
                      setNumber: index + 1,
                      isSelected: isSelected,
                      useKg: widget.useKg,
                      onToggle: () => _toggleSetSelection(index),
                      onEdit: () => _editSet(index),
                      isDark: isDark,
                      accentColor: accentColor,
                    );
                  }),
                  if (_exercises.isNotEmpty) const SizedBox(height: 16),
                ],

                // Exercises to add section
                if (_exercises.isNotEmpty) ...[
                  _buildSectionHeader(
                    icon: Icons.add_circle_outline,
                    title:
                        'Add ${_exercises.length} exercise${_exercises.length == 1 ? '' : 's'}',
                    selectedCount: _selectedExerciseIndices.length,
                    totalCount: _exercises.length,
                    onToggleAll: _toggleSelectAllExercises,
                    accentColor: accentColor,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  ..._exercises.asMap().entries.map((entry) {
                    final index = entry.key;
                    final exercise = entry.value;
                    final isSelected =
                        _selectedExerciseIndices.contains(index);

                    return _ExercisePreviewTile(
                      exercise: exercise,
                      isSelected: isSelected,
                      useKg: widget.useKg,
                      onToggle: () => _toggleExerciseSelection(index),
                      onEdit: () => _editExercise(index),
                      isDark: isDark,
                      accentColor: accentColor,
                    );
                  }),
                ],
              ],
            ),
          ),

          // Bottom action buttons
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.elevated : Colors.grey.shade50,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.cardBorder : Colors.grey.shade200,
                ),
              ),
            ),
            child: Row(
              children: [
                // Cancel button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textMuted,
                      side: BorderSide(
                        color:
                            isDark ? AppColors.cardBorder : Colors.grey.shade300,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                // Confirm button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed:
                        _totalSelectedCount == 0 ? null : _confirmSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _buildConfirmButtonText(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildConfirmButtonText() {
    final parts = <String>[];

    if (_selectedSetIndices.isNotEmpty) {
      parts.add(
          'Log ${_selectedSetIndices.length} set${_selectedSetIndices.length == 1 ? '' : 's'}');
    }

    if (_selectedExerciseIndices.isNotEmpty) {
      parts.add(
          'Add ${_selectedExerciseIndices.length} exercise${_selectedExerciseIndices.length == 1 ? '' : 's'}');
    }

    if (parts.isEmpty) {
      return 'Select items';
    }

    return parts.join(' & ');
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int selectedCount,
    required int totalCount,
    required VoidCallback onToggleAll,
    required Color accentColor,
    required Color textPrimary,
    required Color textMuted,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: accentColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ),
        GestureDetector(
          onTap: onToggleAll,
          child: Text(
            selectedCount == totalCount ? 'Deselect all' : 'Select all',
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _SetPreviewTile extends StatelessWidget {
  final SetToLog set;
  final int setNumber;
  final bool isSelected;
  final bool useKg;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final bool isDark;
  final Color accentColor;

  const _SetPreviewTile({
    required this.set,
    required this.setNumber,
    required this.isSelected,
    required this.useKg,
    required this.onToggle,
    required this.onEdit,
    required this.isDark,
    required this.accentColor,
  });

  String _formatWeight() {
    if (set.isBodyweight) {
      return 'Bodyweight';
    }

    final weight = set.weight;
    if (weight <= 0) {
      return 'Bodyweight';
    }

    // Convert if necessary
    if (useKg && set.unit == 'lbs') {
      return '${(weight / 2.20462).toStringAsFixed(1)} kg';
    } else if (!useKg && set.unit == 'kg') {
      return '${(weight * 2.20462).toStringAsFixed(1)} lbs';
    }

    return '${weight % 1 == 0 ? weight.toInt() : weight.toStringAsFixed(1)} ${set.unit}';
  }

  String _formatReps() {
    if (set.isFailure) {
      return '${set.reps}+ (to failure)';
    }
    return '${set.reps} reps';
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : Colors.black87;
    final textMuted = isDark ? AppColors.textMuted : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? accentColor.withOpacity(0.1)
            : (isDark ? AppColors.elevated : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? accentColor.withOpacity(0.5)
              : (isDark ? AppColors.cardBorder : Colors.grey.shade200),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? accentColor : textMuted,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: isDark ? Colors.black : Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // Set number badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$setNumber',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Set details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _formatWeight(),
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            ' × ',
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            _formatReps(),
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          // Warmup badge
                          if (set.isWarmup) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'WARMUP',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (set.originalInput.isNotEmpty)
                        Text(
                          'From: "${set.originalInput}"',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),

                // Edit button
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: textMuted,
                  ),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExercisePreviewTile extends StatelessWidget {
  final ExerciseToAdd exercise;
  final bool isSelected;
  final bool useKg;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final bool isDark;
  final Color accentColor;

  const _ExercisePreviewTile({
    required this.exercise,
    required this.isSelected,
    required this.useKg,
    required this.onToggle,
    required this.onEdit,
    required this.isDark,
    required this.accentColor,
  });

  String _formatWeight() {
    if (exercise.isBodyweight) {
      return 'Bodyweight';
    }

    final weight = useKg ? exercise.weightKg : exercise.weightLbs;
    if (weight == null || weight <= 0) {
      return 'Bodyweight';
    }

    final unit = useKg ? 'kg' : 'lbs';
    return '${weight % 1 == 0 ? weight.toInt() : weight.toStringAsFixed(1)} $unit';
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : Colors.black87;
    final textMuted = isDark ? AppColors.textMuted : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? accentColor.withOpacity(0.1)
            : (isDark ? AppColors.elevated : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? accentColor.withOpacity(0.5)
              : (isDark ? AppColors.cardBorder : Colors.grey.shade200),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? accentColor : textMuted,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: isDark ? Colors.black : Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // Exercise image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ExerciseImage(
                    exerciseName: exercise.name,
                    width: 48,
                    height: 48,
                  ),
                ),
                const SizedBox(width: 12),

                // Exercise details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.name,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Low confidence warning
                          if (exercise.confidence < 0.7) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: AppColors.yellow,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${exercise.sets}×${exercise.reps} @ ${_formatWeight()}',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Edit button
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: textMuted,
                  ),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Extension to provide let-style transformation
extension _LetExtension<T> on T {
  R let<R>(R Function(T) transform) => transform(this);
}
