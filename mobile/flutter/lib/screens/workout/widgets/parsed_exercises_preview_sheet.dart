/// Parsed Exercises Preview Sheet
///
/// Bottom sheet showing parsed exercises for user confirmation before adding.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/parsed_exercise.dart';
import '../../../widgets/exercise_image.dart';

/// Show the parsed exercises preview sheet
Future<List<ParsedExercise>?> showParsedExercisesPreview(
  BuildContext context,
  WidgetRef ref, {
  required List<ParsedExercise> exercises,
  required bool useKg,
}) async {
  return await showModalBottomSheet<List<ParsedExercise>>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (context) => _ParsedExercisesPreviewSheet(
      exercises: exercises,
      useKg: useKg,
    ),
  );
}

class _ParsedExercisesPreviewSheet extends ConsumerStatefulWidget {
  final List<ParsedExercise> exercises;
  final bool useKg;

  const _ParsedExercisesPreviewSheet({
    required this.exercises,
    required this.useKg,
  });

  @override
  ConsumerState<_ParsedExercisesPreviewSheet> createState() =>
      _ParsedExercisesPreviewSheetState();
}

class _ParsedExercisesPreviewSheetState
    extends ConsumerState<_ParsedExercisesPreviewSheet> {
  late List<ParsedExercise> _exercises;
  late Set<int> _selectedIndices;

  @override
  void initState() {
    super.initState();
    _exercises = List.from(widget.exercises);
    // Select all by default
    _selectedIndices = Set.from(List.generate(_exercises.length, (i) => i));
  }

  void _toggleSelection(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _selectAll() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedIndices.length == _exercises.length) {
        // Deselect all
        _selectedIndices.clear();
      } else {
        // Select all
        _selectedIndices = Set.from(List.generate(_exercises.length, (i) => i));
      }
    });
  }

  void _editExercise(int index) async {
    final exercise = _exercises[index];
    final edited = await _showEditDialog(exercise);
    if (edited != null) {
      setState(() {
        _exercises[index] = edited;
      });
    }
  }

  Future<ParsedExercise?> _showEditDialog(ParsedExercise exercise) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final setsController =
        TextEditingController(text: exercise.sets.toString());
    final repsController =
        TextEditingController(text: exercise.reps.toString());
    final weightController = TextEditingController(
      text: exercise.getWeight(useKg: widget.useKg)?.toString() ?? '',
    );

    return await showDialog<ParsedExercise>(
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

              final edited = exercise.copyWith(
                sets: sets,
                reps: reps,
                weightKg: widget.useKg ? weight : weight?.let((w) => w / 2.20462),
                weightLbs: widget.useKg ? weight?.let((w) => w * 2.20462) : weight,
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
    final selected = _selectedIndices.map((i) => _exercises[i]).toList();
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);
    final textPrimary = isDark ? AppColors.textPrimary : Colors.black87;
    final textMuted = isDark ? AppColors.textMuted : Colors.grey.shade600;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: accentColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Parsed ${_exercises.length} exercises',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                // Select all toggle
                GestureDetector(
                  onTap: _selectAll,
                  child: Text(
                    _selectedIndices.length == _exercises.length
                        ? 'Deselect all'
                        : 'Select all',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Exercises list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _exercises.length,
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
                final isSelected = _selectedIndices.contains(index);

                return _ExercisePreviewTile(
                  exercise: exercise,
                  isSelected: isSelected,
                  useKg: widget.useKg,
                  onToggle: () => _toggleSelection(index),
                  onEdit: () => _editExercise(index),
                  isDark: isDark,
                  accentColor: accentColor,
                );
              },
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
                // Add selected button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed:
                        _selectedIndices.isEmpty ? null : _confirmSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Add ${_selectedIndices.length} exercise${_selectedIndices.length == 1 ? '' : 's'}',
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
}

class _ExercisePreviewTile extends StatelessWidget {
  final ParsedExercise exercise;
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
                          if (exercise.isLowConfidence) ...[
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
                        '${exercise.formattedSetsReps} @ ${exercise.getFormattedWeight(useKg: useKg)}',
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
