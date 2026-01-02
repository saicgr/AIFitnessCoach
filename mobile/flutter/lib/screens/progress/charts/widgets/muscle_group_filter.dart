import 'package:flutter/material.dart';

/// Dropdown filter for selecting muscle group
class MuscleGroupFilter extends StatelessWidget {
  final List<String> muscleGroups;
  final String? selectedMuscleGroup;
  final ValueChanged<String?> onMuscleGroupSelected;

  const MuscleGroupFilter({
    super.key,
    required this.muscleGroups,
    this.selectedMuscleGroup,
    required this.onMuscleGroupSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (muscleGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: muscleGroups.length + 1, // +1 for "All" option
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" option
            final isSelected = selectedMuscleGroup == null;
            return FilterChip(
              label: const Text('All Muscles'),
              selected: isSelected,
              onSelected: (_) => onMuscleGroupSelected(null),
              selectedColor: colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
              backgroundColor: colorScheme.surfaceContainerHighest,
              side: BorderSide(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withOpacity(0.3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            );
          }

          final muscleGroup = muscleGroups[index - 1];
          final isSelected = selectedMuscleGroup == muscleGroup;

          return FilterChip(
            label: Text(_formatMuscleGroup(muscleGroup)),
            selected: isSelected,
            onSelected: (_) => onMuscleGroupSelected(muscleGroup),
            selectedColor: colorScheme.primary,
            labelStyle: TextStyle(
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 12,
            ),
            backgroundColor: colorScheme.surfaceContainerHighest,
            side: BorderSide(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.3),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          );
        },
      ),
    );
  }

  String _formatMuscleGroup(String name) {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
