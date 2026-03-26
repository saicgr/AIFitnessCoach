import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/context_logging_service.dart';
import '../providers/library_providers.dart';
import '../providers/muscle_group_images_provider.dart';

/// Bottom sheet for filtering exercises — all sections open with pills, no dropdowns.
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
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final success = isDark ? AppColors.success : AppColorsLight.success;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.92),
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

                const SizedBox(height: 4),

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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── BODY PART — muscle image pills ──
                            _SectionHeader(
                              title: 'Body Part',
                              icon: Icons.accessibility_new,
                              color: purple,
                              count: selectedMuscles.length,
                            ),
                            const SizedBox(height: 10),
                            _MuscleImageGrid(
                              options: filterOptions.bodyParts.map((o) => o.name).toList(),
                              selectedValues: selectedMuscles,
                              color: purple,
                              isDark: isDark,
                              onToggle: (value) {
                                final newSet = Set<String>.from(selectedMuscles);
                                final existing = newSet.firstWhere(
                                  (v) => v.toLowerCase() == value.toLowerCase(),
                                  orElse: () => '',
                                );
                                if (existing.isNotEmpty) {
                                  newSet.remove(existing);
                                } else {
                                  newSet.add(value);
                                  ref.read(contextLoggingServiceProvider).logExerciseFilterUsed(
                                    filterType: 'body_part',
                                    filterValues: [value],
                                  );
                                }
                                ref.read(selectedMuscleGroupsProvider.notifier).state = newSet;
                              },
                            ),

                            const SizedBox(height: 20),

                            // ── EQUIPMENT — pills ──
                            _SectionHeader(
                              title: 'Equipment',
                              icon: Icons.fitness_center,
                              color: cyan,
                              count: selectedEquipments.length,
                            ),
                            const SizedBox(height: 10),
                            _PillWrap(
                              options: filterOptions.equipment.map((o) => o.name).toList(),
                              selectedValues: selectedEquipments,
                              color: cyan,
                              isDark: isDark,
                              onToggle: (value) {
                                final newSet = Set<String>.from(selectedEquipments);
                                final existing = newSet.firstWhere(
                                  (v) => v.toLowerCase() == value.toLowerCase(),
                                  orElse: () => '',
                                );
                                if (existing.isNotEmpty) {
                                  newSet.remove(existing);
                                } else {
                                  newSet.add(value);
                                  ref.read(contextLoggingServiceProvider).logExerciseFilterUsed(
                                    filterType: 'equipment',
                                    filterValues: [value],
                                  );
                                }
                                ref.read(selectedEquipmentsProvider.notifier).state = newSet;
                              },
                            ),

                            const SizedBox(height: 20),

                            // ── EXERCISE TYPE — pills ──
                            _SectionHeader(
                              title: 'Exercise Type',
                              icon: Icons.category,
                              color: success,
                              count: selectedTypes.length,
                            ),
                            const SizedBox(height: 10),
                            _PillWrap(
                              options: filterOptions.exerciseTypes.map((o) => o.name).toList(),
                              selectedValues: selectedTypes,
                              color: success,
                              isDark: isDark,
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
                                  ref.read(contextLoggingServiceProvider).logExerciseFilterUsed(
                                    filterType: 'exercise_type',
                                    filterValues: [value],
                                  );
                                }
                                ref.read(selectedExerciseTypesProvider.notifier).state = newSet;
                              },
                            ),

                            const SizedBox(height: 20),

                            // ── GOALS — pills ──
                            _SectionHeader(
                              title: 'Goals',
                              icon: Icons.track_changes,
                              color: Colors.orange,
                              count: selectedGoals.length,
                            ),
                            const SizedBox(height: 10),
                            _PillWrap(
                              options: filterOptions.goals.map((o) => o.name).toList(),
                              selectedValues: selectedGoals,
                              color: Colors.orange,
                              isDark: isDark,
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
                                  ref.read(contextLoggingServiceProvider).logExerciseFilterUsed(
                                    filterType: 'goals',
                                    filterValues: [value],
                                  );
                                }
                                ref.read(selectedGoalsProvider.notifier).state = newSet;
                              },
                            ),

                            const SizedBox(height: 20),

                            // ── SUITABLE FOR — pills ──
                            if (filterOptions.suitableFor.isNotEmpty) ...[
                              _SectionHeader(
                                title: 'Suitable For',
                                icon: Icons.person_outline,
                                color: Colors.teal,
                                count: selectedSuitableFor.length,
                              ),
                              const SizedBox(height: 10),
                              _PillWrap(
                                options: filterOptions.suitableFor.map((o) => o.name).toList(),
                                selectedValues: selectedSuitableFor,
                                color: Colors.teal,
                                isDark: isDark,
                                onToggle: (value) {
                                  final newSet = Set<String>.from(selectedSuitableFor);
                                  final existing = newSet.firstWhere(
                                    (v) => v.toLowerCase() == value.toLowerCase(),
                                    orElse: () => '',
                                  );
                                  if (existing.isNotEmpty) {
                                    newSet.remove(existing);
                                  } else {
                                    newSet.add(value);
                                  }
                                  ref.read(selectedSuitableForSetProvider.notifier).state = newSet;
                                },
                              ),
                              const SizedBox(height: 20),
                            ],

                            // ── AVOID IF YOU HAVE — pills ──
                            if (filterOptions.avoidIf.isNotEmpty) ...[
                              _SectionHeader(
                                title: 'Avoid If You Have',
                                icon: Icons.warning_amber_rounded,
                                color: Colors.redAccent,
                                count: selectedAvoid.length,
                              ),
                              const SizedBox(height: 10),
                              _PillWrap(
                                options: filterOptions.avoidIf.map((o) => o.name).toList(),
                                selectedValues: selectedAvoid,
                                color: Colors.redAccent,
                                isDark: isDark,
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
                                  ref.read(selectedAvoidSetProvider.notifier).state = newSet;
                                },
                              ),
                              const SizedBox(height: 20),
                            ],

                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Apply button
                Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: 12 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cyan,
                        foregroundColor: Colors.white,
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

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Muscle Image Grid — circular anatomy images with labels
// ─────────────────────────────────────────────────────────────────────────────

class _MuscleImageGrid extends StatelessWidget {
  final List<String> options;
  final Set<String> selectedValues;
  final Color color;
  final bool isDark;
  final Function(String) onToggle;

  const _MuscleImageGrid({
    required this.options,
    required this.selectedValues,
    required this.color,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Wrap(
      spacing: 10,
      runSpacing: 12,
      children: options.map((name) {
        final isSelected = selectedValues.any(
          (v) => v.toLowerCase() == name.toLowerCase(),
        );
        final imagePath = muscleGroupAssets[name];

        return GestureDetector(
          onTap: () => onToggle(name),
          child: SizedBox(
            width: 68,
            child: Column(
              children: [
                // Circular avatar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? color.withOpacity(0.2) : elevated,
                    border: Border.all(
                      color: isSelected ? color : cardBorder,
                      width: isSelected ? 2.5 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (imagePath != null)
                        Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          width: 52,
                          height: 52,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.fitness_center,
                            size: 20,
                            color: isSelected ? color : textMuted,
                          ),
                        )
                      else
                        Icon(
                          Icons.fitness_center,
                          size: 20,
                          color: isSelected ? color : textMuted,
                        ),
                      // Selected check overlay
                      if (isSelected)
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.4),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Label
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? color : textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill Wrap — directly visible pills with no dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _PillWrap extends StatelessWidget {
  final List<String> options;
  final Set<String> selectedValues;
  final Color color;
  final bool isDark;
  final Function(String) onToggle;

  const _PillWrap({
    required this.options,
    required this.selectedValues,
    required this.color,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((name) {
        final isSelected = selectedValues.any(
          (v) => v.toLowerCase() == name.toLowerCase(),
        );

        return GestureDetector(
          onTap: () => onToggle(name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : glassSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(Icons.check, size: 14, color: color),
                  const SizedBox(width: 4),
                ],
                Text(
                  _shortenName(name),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? color : textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _shortenName(String name) {
    if (name.length <= 22) return name;
    final replacements = {
      'Hammer Strength': 'HS',
      'Iso-Lateral': 'Iso',
      'MTS ': '',
      'Machine': 'Mach.',
      'Resistance Band': 'Res. Band',
      'Cable Pulley Machine': 'Cable',
      'Dual Cable Pulley Machine': 'Dual Cable',
      'Plate-Loaded': 'Plate',
      'Plate Loaded': 'Plate',
    };
    String shortened = name;
    for (final entry in replacements.entries) {
      shortened = shortened.replaceAll(entry.key, entry.value);
    }
    if (shortened.length > 25) {
      shortened = '${shortened.substring(0, 22)}...';
    }
    return shortened;
  }
}
