import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/library_providers.dart';

/// Single active filter chip with remove button
class ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const ActiveFilterChip({
    super.key,
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: cyan.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cyan),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: cyan,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close,
                size: 14,
                color: cyan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal scrollable list of active filter chips with clear all button
class ActiveFilterChipsList extends ConsumerWidget {
  const ActiveFilterChipsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMuscles = ref.watch(selectedMuscleGroupsProvider);
    final selectedEquipments = ref.watch(selectedEquipmentsProvider);
    final selectedTypes = ref.watch(selectedExerciseTypesProvider);
    final selectedGoals = ref.watch(selectedGoalsProvider);
    final selectedSuitableFor = ref.watch(selectedSuitableForSetProvider);
    final selectedAvoid = ref.watch(selectedAvoidSetProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final activeFilters = getActiveFilterCount(ref);

    if (activeFilters == 0) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Body part chips
          ...selectedMuscles.map((muscle) => ActiveFilterChip(
                label: muscle,
                onRemove: () {
                  final newSet = Set<String>.from(selectedMuscles)
                    ..remove(muscle);
                  ref.read(selectedMuscleGroupsProvider.notifier).state =
                      newSet;
                },
              )),
          // Equipment chips
          ...selectedEquipments.map((equip) => ActiveFilterChip(
                label: equip,
                onRemove: () {
                  final newSet = Set<String>.from(selectedEquipments)
                    ..remove(equip);
                  ref.read(selectedEquipmentsProvider.notifier).state = newSet;
                },
              )),
          // Type chips
          ...selectedTypes.map((type) => ActiveFilterChip(
                label: type,
                onRemove: () {
                  final newSet = Set<String>.from(selectedTypes)..remove(type);
                  ref.read(selectedExerciseTypesProvider.notifier).state =
                      newSet;
                },
              )),
          // Goal chips
          ...selectedGoals.map((goal) => ActiveFilterChip(
                label: goal,
                onRemove: () {
                  final newSet = Set<String>.from(selectedGoals)..remove(goal);
                  ref.read(selectedGoalsProvider.notifier).state = newSet;
                },
              )),
          // Suitable for chips
          ...selectedSuitableFor.map((suitable) => ActiveFilterChip(
                label: suitable,
                onRemove: () {
                  final newSet = Set<String>.from(selectedSuitableFor)
                    ..remove(suitable);
                  ref.read(selectedSuitableForSetProvider.notifier).state =
                      newSet;
                },
              )),
          // Avoid chips
          ...selectedAvoid.map((avoid) => ActiveFilterChip(
                label: 'Avoid: $avoid',
                onRemove: () {
                  final newSet = Set<String>.from(selectedAvoid)
                    ..remove(avoid);
                  ref.read(selectedAvoidSetProvider.notifier).state = newSet;
                },
              )),
          // Clear all button
          if (activeFilters > 1)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: GestureDetector(
                onTap: () => clearAllFilters(ref),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: textMuted.withOpacity(0.5)),
                  ),
                  child: Text(
                    'Clear all',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
