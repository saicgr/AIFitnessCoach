import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/difficulty_utils.dart';
import '../../../data/services/context_logging_service.dart';
import '../../../widgets/body_muscle_selector.dart';
import '../../../widgets/signature/signature.dart';
import '../providers/library_providers.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Signature-v2 filter sheet for the Exercise Library.
///
/// Restyled to the chosen redesign (`#screen-exercise` Filter frame): a near-black
/// glass sheet, a MUSCLE body-map section at the top (front/back tappable
/// silhouette → toggles `selectedMuscleGroupsProvider`), then Equipment / Type /
/// Goal / Suitable-for / Avoid facet rows rendered as [ZChip] pills. The filter
/// source of truth (the `selected*Provider`s) is unchanged, and the Exercises
/// tab refreshes itself when those providers change — so Apply simply closes.
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
    const accent = AppColors.orange;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

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
                  ? const Color(0xFF09090B).withValues(alpha: 0.92)
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
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

                // Header — Anton-flavoured title + a "RESET" link (signature v2
                // `.filt-head`).
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context).recipesFilters,
                        style: ZType.disp(26,
                            color: isDark
                                ? AppColors.textPrimary
                                : AppColorsLight.textPrimary),
                      ),
                      TextButton(
                        onPressed: () => clearAllFilters(ref),
                        child: Text(
                          AppLocalizations.of(context)
                              .settingsCardPartClearAll
                              .toUpperCase(),
                          style:
                              ZType.lbl(12, color: accent, letterSpacing: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Filter content
                Expanded(
                  child: filterOptionsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: accent),
                    ),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: textMuted, size: 48),
                          const SizedBox(height: 16),
                          Text(
                              AppLocalizations.of(context)
                                  .exerciseFilterFailedToLoadFilters,
                              style: TextStyle(color: textMuted)),
                          TextButton(
                            onPressed: () => ref.refresh(filterOptionsProvider),
                            child:
                                Text(AppLocalizations.of(context).buttonRetry),
                          ),
                        ],
                      ),
                    ),
                    data: (filterOptions) {
                      return SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── MUSCLE — tappable front/back body map ──
                            _FacetKicker(
                              label: AppLocalizations.of(context)
                                  .exerciseFilterBodyPart,
                              count: selectedMuscles.length,
                            ),
                            const SizedBox(height: 10),
                            _MuscleBodyMapSection(
                              selectedMuscles: selectedMuscles,
                              onToggle: (value) {
                                final newSet =
                                    Set<String>.from(selectedMuscles);
                                final existing = newSet.firstWhere(
                                  (v) =>
                                      v.toLowerCase() == value.toLowerCase(),
                                  orElse: () => '',
                                );
                                if (existing.isNotEmpty) {
                                  newSet.remove(existing);
                                } else {
                                  newSet.add(value);
                                  ref
                                      .read(contextLoggingServiceProvider)
                                      .logExerciseFilterUsed(
                                    filterType: 'body_part',
                                    filterValues: [value],
                                  );
                                }
                                ref
                                    .read(selectedMuscleGroupsProvider.notifier)
                                    .state = newSet;
                              },
                            ),

                            const SizedBox(height: 22),

                            // ── EQUIPMENT — pills ──
                            _FacetKicker(
                              label: AppLocalizations.of(context)
                                  .trainingSetupCardEquipment,
                              count: selectedEquipments.length,
                            ),
                            const SizedBox(height: 10),
                            _ChipFacet(
                              options: filterOptions.equipment
                                  .map((o) => o.name)
                                  .toList(),
                              selectedValues: selectedEquipments,
                              onToggle: (value) {
                                final newSet =
                                    Set<String>.from(selectedEquipments);
                                final existing = newSet.firstWhere(
                                  (v) =>
                                      v.toLowerCase() == value.toLowerCase(),
                                  orElse: () => '',
                                );
                                if (existing.isNotEmpty) {
                                  newSet.remove(existing);
                                } else {
                                  newSet.add(value);
                                  ref
                                      .read(contextLoggingServiceProvider)
                                      .logExerciseFilterUsed(
                                    filterType: 'equipment',
                                    filterValues: [value],
                                  );
                                }
                                ref
                                    .read(selectedEquipmentsProvider.notifier)
                                    .state = newSet;
                              },
                            ),

                            const SizedBox(height: 22),

                            // ── EXERCISE TYPE — pills ──
                            _FacetKicker(
                              label: AppLocalizations.of(context)
                                  .exerciseFilterExerciseType,
                              count: selectedTypes.length,
                            ),
                            const SizedBox(height: 10),
                            _ChipFacet(
                              options: filterOptions.exerciseTypes
                                  .map((o) => o.name)
                                  .toList(),
                              selectedValues: selectedTypes,
                              onToggle: (value) {
                                final newSet =
                                    Set<String>.from(selectedTypes);
                                final existing = newSet.firstWhere(
                                  (v) =>
                                      v.toLowerCase() == value.toLowerCase(),
                                  orElse: () => '',
                                );
                                if (existing.isNotEmpty) {
                                  newSet.remove(existing);
                                } else {
                                  newSet.add(value);
                                  ref
                                      .read(contextLoggingServiceProvider)
                                      .logExerciseFilterUsed(
                                    filterType: 'exercise_type',
                                    filterValues: [value],
                                  );
                                }
                                ref
                                    .read(
                                        selectedExerciseTypesProvider.notifier)
                                    .state = newSet;
                              },
                            ),

                            const SizedBox(height: 22),

                            // ── GOALS — pills ──
                            _FacetKicker(
                              label: AppLocalizations.of(context)
                                  .fastingCalendarGoals,
                              count: selectedGoals.length,
                            ),
                            const SizedBox(height: 10),
                            _ChipFacet(
                              options: filterOptions.goals
                                  .map((o) => o.name)
                                  .toList(),
                              selectedValues: selectedGoals,
                              onToggle: (value) {
                                final newSet =
                                    Set<String>.from(selectedGoals);
                                final existing = newSet.firstWhere(
                                  (v) =>
                                      v.toLowerCase() == value.toLowerCase(),
                                  orElse: () => '',
                                );
                                if (existing.isNotEmpty) {
                                  newSet.remove(existing);
                                } else {
                                  newSet.add(value);
                                  ref
                                      .read(contextLoggingServiceProvider)
                                      .logExerciseFilterUsed(
                                    filterType: 'goals',
                                    filterValues: [value],
                                  );
                                }
                                ref
                                    .read(selectedGoalsProvider.notifier)
                                    .state = newSet;
                              },
                            ),

                            // ── SUITABLE FOR — pills ──
                            if (filterOptions.suitableFor.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _FacetKicker(
                                label: AppLocalizations.of(context)
                                    .exerciseFilterSuitableFor,
                                count: selectedSuitableFor.length,
                              ),
                              const SizedBox(height: 10),
                              _ChipFacet(
                                options: filterOptions.suitableFor
                                    .map((o) => o.name)
                                    .toList(),
                                selectedValues: selectedSuitableFor,
                                onToggle: (value) {
                                  final newSet =
                                      Set<String>.from(selectedSuitableFor);
                                  final existing = newSet.firstWhere(
                                    (v) =>
                                        v.toLowerCase() == value.toLowerCase(),
                                    orElse: () => '',
                                  );
                                  if (existing.isNotEmpty) {
                                    newSet.remove(existing);
                                  } else {
                                    newSet.add(value);
                                  }
                                  ref
                                      .read(selectedSuitableForSetProvider
                                          .notifier)
                                      .state = newSet;
                                },
                              ),
                            ],

                            // ── AVOID IF YOU HAVE — pills ──
                            if (filterOptions.avoidIf.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _FacetKicker(
                                label: AppLocalizations.of(context)
                                    .exerciseFilterAvoidIfYouHave,
                                count: selectedAvoid.length,
                              ),
                              const SizedBox(height: 10),
                              _ChipFacet(
                                options: filterOptions.avoidIf
                                    .map((o) => o.name)
                                    .toList(),
                                selectedValues: selectedAvoid,
                                onToggle: (value) {
                                  final newSet =
                                      Set<String>.from(selectedAvoid);
                                  final existing = newSet.firstWhere(
                                    (v) =>
                                        v.toLowerCase() == value.toLowerCase(),
                                    orElse: () => '',
                                  );
                                  if (existing.isNotEmpty) {
                                    newSet.remove(existing);
                                  } else {
                                    newSet.add(value);
                                  }
                                  ref
                                      .read(selectedAvoidSetProvider.notifier)
                                      .state = newSet;
                                },
                              ),
                            ],

                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Apply button — signature primary CTA: accent fill,
                // dark-on-orange condensed label.
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: 16,
                    end: 16,
                    top: 12,
                    bottom: 12 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: const Color(0xFF160B03),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)
                            .exerciseFilterApplyFilters
                            .toUpperCase(),
                        style: ZType.lbl(
                          15,
                          color: const Color(0xFF160B03),
                          letterSpacing: 2.0,
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
// Facet kicker — Barlow-Condensed uppercase section label + a count pill.
// (signature v2 `.fsec .fk`)
// ─────────────────────────────────────────────────────────────────────────────

class _FacetKicker extends StatelessWidget {
  final String label;
  final int count;

  const _FacetKicker({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final faint = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: ZType.lbl(11.5, color: faint, letterSpacing: 2.2),
        ),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: ZType.lbl(10.5,
                  color: AppColors.orange, letterSpacing: 0.5),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip facet — a wrap of signature [ZChip] pills.
// ─────────────────────────────────────────────────────────────────────────────

class _ChipFacet extends StatelessWidget {
  final List<String> options;
  final Set<String> selectedValues;
  final void Function(String) onToggle;

  const _ChipFacet({
    required this.options,
    required this.selectedValues,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((name) {
        final isSelected = selectedValues.any(
          (v) => v.toLowerCase() == name.toLowerCase(),
        );
        return ZChip(
          label: _shortenName(name),
          selected: isSelected,
          onTap: () => onToggle(name),
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

// ─────────────────────────────────────────────────────────────────────────────
// Muscle body-map section — front/back tappable silhouette wired to the muscle
// filter provider. A tapped muscle region maps (via [packageGroupToBackendMuscle]
// inside [BodyMuscleSelectorWidget]) to a backend muscle string, which we toggle
// into `selectedMuscleGroupsProvider`.
// ─────────────────────────────────────────────────────────────────────────────

class _MuscleBodyMapSection extends StatelessWidget {
  final Set<String> selectedMuscles;
  final void Function(String muscle) onToggle;

  const _MuscleBodyMapSection({
    required this.selectedMuscles,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedSelected = selectedMuscles.toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected-muscle chips so a tapped region is also legible as text and
        // can be removed without hunting the silhouette.
        if (mutedSelected.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: mutedSelected.map((m) {
              return ZChip(
                label: getMuscleDisplayName(m),
                selected: true,
                leadingDot: DifficultyUtils.getColor('hard'),
                onTap: () => onToggle(m),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: BodyMuscleSelectorWidget(
            selectedMuscles: selectedMuscles,
            onMuscleToggle: onToggle,
            height: 320,
          ),
        ),
      ],
    );
  }
}
