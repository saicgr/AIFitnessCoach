import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/context_logging_service.dart';
import '../providers/library_providers.dart';
import 'filter_section.dart';

/// Bottom sheet for filtering exercises by various categories
class ExerciseFilterSheet extends ConsumerWidget {
  const ExerciseFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterOptionsAsync = ref.watch(filterOptionsProvider);
    final selectedMuscles = ref.watch(selectedMuscleGroupsProvider);
    final selectedEquipments = ref.watch(selectedEquipmentsProvider);
    final selectedTypes = ref.watch(selectedExerciseTypesProvider);
    final selectedGoals = ref.watch(selectedGoalsProvider);
    final selectedSuitableFor = ref.watch(selectedSuitableForSetProvider);
    final selectedAvoid = ref.watch(selectedAvoidSetProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBackground =
        isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final success = isDark ? AppColors.success : AppColorsLight.success;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () => clearAllFilters(ref),
                    child: Text(
                      'Clear all',
                      style: TextStyle(color: cyan),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Filter content
            Expanded(
              child: filterOptionsAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: cyan),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: textMuted, size: 48),
                      const SizedBox(height: 16),
                      Text('Failed to load filters',
                          style: TextStyle(color: textMuted)),
                      TextButton(
                        onPressed: () => ref.refresh(filterOptionsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (filterOptions) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Body Part / Muscle Group section
                        FilterSection(
                          title: 'BODY PART',
                          icon: Icons.accessibility_new,
                          color: purple,
                          options: filterOptions.bodyParts,
                          selectedValues: selectedMuscles,
                          onToggle: (value) {
                            final newSet = Set<String>.from(selectedMuscles);
                            // Case-insensitive check for existing value
                            final existing = newSet.firstWhere(
                              (v) => v.toLowerCase() == value.toLowerCase(),
                              orElse: () => '',
                            );
                            if (existing.isNotEmpty) {
                              newSet.remove(existing);
                            } else {
                              newSet.add(value);
                              // Log filter usage for AI preference learning
                              ref.read(contextLoggingServiceProvider).logExerciseFilterUsed(
                                filterType: 'body_part',
                                filterValues: [value],
                              );
                            }
                            ref.read(selectedMuscleGroupsProvider.notifier)
                                .state = newSet;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Equipment section
                        FilterSection(
                          title: 'EQUIPMENT',
                          icon: Icons.fitness_center,
                          color: cyan,
                          options: filterOptions.equipment,
                          selectedValues: selectedEquipments,
                          onToggle: (value) {
                            final newSet =
                                Set<String>.from(selectedEquipments);
                            final existing = newSet.firstWhere(
                              (v) => v.toLowerCase() == value.toLowerCase(),
                              orElse: () => '',
                            );
                            if (existing.isNotEmpty) {
                              newSet.remove(existing);
                            } else {
                              newSet.add(value);
                              // Log filter usage for AI preference learning
                              ref.read(contextLoggingServiceProvider).logExerciseFilterUsed(
                                filterType: 'equipment',
                                filterValues: [value],
                              );
                            }
                            ref.read(selectedEquipmentsProvider.notifier)
                                .state = newSet;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Exercise Type section
                        FilterSection(
                          title: 'EXERCISE TYPE',
                          icon: Icons.category,
                          color: success,
                          options: filterOptions.exerciseTypes,
                          selectedValues: selectedTypes,
                          onToggle: (value) {
                            final newSet = Set<String>.from(selectedTypes);
                            final existing = newSet.firstWhere(
                              (v) => v.toLowerCase() == value.toLowerCase(),
                              orElse: () => '',
                            );
                            if (existing.isNotEmpty) {
                              newSet.remove(existing);
                            } else {
                              newSet.add(value);
                              // Log filter usage for AI preference learning
                              ref.read(contextLoggingServiceProvider).logExerciseFilterUsed(
                                filterType: 'exercise_type',
                                filterValues: [value],
                              );
                            }
                            ref.read(selectedExerciseTypesProvider.notifier)
                                .state = newSet;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Goals section
                        FilterSection(
                          title: 'GOALS',
                          icon: Icons.track_changes,
                          color: Colors.orange,
                          options: filterOptions.goals,
                          selectedValues: selectedGoals,
                          onToggle: (value) {
                            final newSet = Set<String>.from(selectedGoals);
                            final existing = newSet.firstWhere(
                              (v) => v.toLowerCase() == value.toLowerCase(),
                              orElse: () => '',
                            );
                            if (existing.isNotEmpty) {
                              newSet.remove(existing);
                            } else {
                              newSet.add(value);
                              // Log filter usage for AI preference learning
                              ref.read(contextLoggingServiceProvider).logExerciseFilterUsed(
                                filterType: 'goals',
                                filterValues: [value],
                              );
                            }
                            ref.read(selectedGoalsProvider.notifier).state =
                                newSet;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Suitable For section
                        FilterSection(
                          title: 'SUITABLE FOR',
                          icon: Icons.person_outline,
                          color: Colors.teal,
                          options: filterOptions.suitableFor,
                          selectedValues: selectedSuitableFor,
                          onToggle: (value) {
                            final newSet =
                                Set<String>.from(selectedSuitableFor);
                            final existing = newSet.firstWhere(
                              (v) => v.toLowerCase() == value.toLowerCase(),
                              orElse: () => '',
                            );
                            if (existing.isNotEmpty) {
                              newSet.remove(existing);
                            } else {
                              newSet.add(value);
                            }
                            ref.read(selectedSuitableForSetProvider.notifier)
                                .state = newSet;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Avoid If section
                        FilterSection(
                          title: 'AVOID IF YOU HAVE',
                          icon: Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                          options: filterOptions.avoidIf,
                          selectedValues: selectedAvoid,
                          onToggle: (value) {
                            final newSet = Set<String>.from(selectedAvoid);
                            final existing = newSet.firstWhere(
                              (v) => v.toLowerCase() == value.toLowerCase(),
                              orElse: () => '',
                            );
                            if (existing.isNotEmpty) {
                              newSet.remove(existing);
                            } else {
                              newSet.add(value);
                            }
                            ref.read(selectedAvoidSetProvider.notifier).state =
                                newSet;
                          },
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Apply button - extra bottom padding for floating nav bar
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 +
                    MediaQuery.of(context).padding.bottom +
                    88, // 88 = nav bar (56) + margins (32)
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
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
