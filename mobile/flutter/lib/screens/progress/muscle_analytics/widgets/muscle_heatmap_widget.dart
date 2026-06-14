import 'package:flutter/material.dart';
import '../../../../data/models/muscle_analytics.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/design_system/zealova.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// Sequential intensity ramp routed through theme colors (NOT hardcoded
/// Material palette swatches). High intensity reads as the screen accent;
/// lower tiers fade toward the hairline so the grid stays single-accent.
Color _intensityColor(ThemeColors tc, double intensity) {
  if (intensity >= 0.75) {
    return tc.accent;
  } else if (intensity >= 0.5) {
    return tc.accent.withValues(alpha: 0.65);
  } else if (intensity >= 0.25) {
    return tc.accent.withValues(alpha: 0.38);
  } else if (intensity > 0) {
    return tc.accent.withValues(alpha: 0.18);
  } else {
    return AppColors.hairlineStrong;
  }
}
/// Widget displaying a simplified muscle heatmap visualization
/// Shows muscle groups as a grid with color intensity based on training volume
class MuscleHeatmapWidget extends StatelessWidget {
  final MuscleHeatmapData heatmap;
  final Function(String muscleId)? onMuscleTap;

  const MuscleHeatmapWidget({
    super.key,
    required this.heatmap,
    this.onMuscleTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    // Group muscles into upper and lower body
    final upperBodyMuscles = ['chest', 'back', 'shoulders', 'biceps', 'triceps', 'forearms'];
    final coreMuscles = ['abs', 'core', 'obliques'];
    final lowerBodyMuscles = ['quadriceps', 'quads', 'hamstrings', 'glutes', 'calves', 'legs'];

    final sortedMuscles = heatmap.sortedByIntensity;

    return ZealovaCard(
      variant: ZealovaCardVariant.outlined,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Legend — intensity ramp routed through the accent.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 6,
            children: [
              _LegendItem(color: _intensityColor(tc, 0.9), label: AppLocalizations.of(context).scoreExplainHigh),
              _LegendItem(color: _intensityColor(tc, 0.5), label: AppLocalizations.of(context).scoreExplainMedium),
              _LegendItem(color: _intensityColor(tc, 0.2), label: AppLocalizations.of(context).scoreExplainLow),
              _LegendItem(color: _intensityColor(tc, 0.0), label: AppLocalizations.of(context).recipeCreateNone),
            ],
          ),
          const SizedBox(height: 20),

          // Upper Body Section
          ZealovaSectionKicker(AppLocalizations.of(context).quizMuscleFocusUpperBody),
          const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: sortedMuscles
                  .where((m) => upperBodyMuscles.any((u) => m.muscleId.toLowerCase().contains(u)))
                  .map((muscle) => _MuscleChip(
                        muscle: muscle,
                        maxIntensity: heatmap.maxIntensity ?? 1,
                        onTap: onMuscleTap != null ? () => onMuscleTap!(muscle.muscleId) : null,
                      ))
                  .toList(),
            ),

            const SizedBox(height: 16),
            const ZealovaRule(),
            const SizedBox(height: 16),

            // Core Section
            ZealovaSectionKicker(AppLocalizations.of(context).quizMuscleFocusCore),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: sortedMuscles
                  .where((m) => coreMuscles.any((c) => m.muscleId.toLowerCase().contains(c)))
                  .map((muscle) => _MuscleChip(
                        muscle: muscle,
                        maxIntensity: heatmap.maxIntensity ?? 1,
                        onTap: onMuscleTap != null ? () => onMuscleTap!(muscle.muscleId) : null,
                      ))
                  .toList(),
            ),

            const SizedBox(height: 16),
            const ZealovaRule(),
            const SizedBox(height: 16),

            // Lower Body Section
            ZealovaSectionKicker(AppLocalizations.of(context).quizMuscleFocusLowerBody),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: sortedMuscles
                  .where((m) => lowerBodyMuscles.any((l) => m.muscleId.toLowerCase().contains(l)))
                  .map((muscle) => _MuscleChip(
                        muscle: muscle,
                        maxIntensity: heatmap.maxIntensity ?? 1,
                        onTap: onMuscleTap != null ? () => onMuscleTap!(muscle.muscleId) : null,
                      ))
                  .toList(),
            ),

            // Other muscles not in categories
            Builder(
              builder: (context) {
                final otherMuscles = sortedMuscles.where((m) {
                  final id = m.muscleId.toLowerCase();
                  return !upperBodyMuscles.any((u) => id.contains(u)) &&
                         !coreMuscles.any((c) => id.contains(c)) &&
                         !lowerBodyMuscles.any((l) => id.contains(l));
                }).toList();

                if (otherMuscles.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: [
                    const SizedBox(height: 16),
                    const ZealovaRule(),
                    const SizedBox(height: 16),
                    ZealovaSectionKicker(AppLocalizations.of(context).selectableChipOther),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: otherMuscles
                          .map((muscle) => _MuscleChip(
                                muscle: muscle,
                                maxIntensity: heatmap.maxIntensity ?? 1,
                                onTap: onMuscleTap != null ? () => onMuscleTap!(muscle.muscleId) : null,
                              ))
                          .toList(),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
    );
  }

}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label.toUpperCase(),
          style: ZType.lbl(9, color: tc.textMuted, letterSpacing: 1.0),
        ),
      ],
    );
  }
}

class _MuscleChip extends StatelessWidget {
  final MuscleIntensity muscle;
  final double maxIntensity;
  final VoidCallback? onTap;

  const _MuscleChip({
    required this.muscle,
    required this.maxIntensity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final normalizedIntensity =
        maxIntensity > 0 ? muscle.intensity / maxIntensity : 0.0;
    final intensityColor = _intensityColor(tc, normalizedIntensity);

    return Material(
      color: tc.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(color: tc.cardBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Intensity dot routed through the accent ramp.
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: intensityColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    muscle.formattedMuscleName.toUpperCase(),
                    style: ZType.lbl(11,
                        color: tc.textPrimary, letterSpacing: 1.2),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                muscle.formattedVolume,
                style: ZType.disp(14, color: tc.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
