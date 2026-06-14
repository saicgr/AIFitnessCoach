import 'package:flutter/material.dart';
import '../../../../widgets/design_system/zealova.dart';

import '../../../../l10n/generated/app_localizations.dart';
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
    if (muscleGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: muscleGroups.length + 1, // +1 for "All" option
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" option
            final isSelected = selectedMuscleGroup == null;
            return ZealovaChip(
              label: AppLocalizations.of(context).muscleGroupFilterAllMuscles,
              selected: isSelected,
              onTap: () => onMuscleGroupSelected(null),
            );
          }

          final muscleGroup = muscleGroups[index - 1];
          final isSelected = selectedMuscleGroup == muscleGroup;

          return ZealovaChip(
            label: _formatMuscleGroup(muscleGroup),
            selected: isSelected,
            onTap: () => onMuscleGroupSelected(muscleGroup),
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
