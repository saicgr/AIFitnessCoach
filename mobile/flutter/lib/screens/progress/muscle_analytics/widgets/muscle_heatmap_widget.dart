import 'package:flutter/material.dart';
import '../../../../data/models/muscle_analytics.dart';

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
    final theme = Theme.of(context);

    // Group muscles into upper and lower body
    final upperBodyMuscles = ['chest', 'back', 'shoulders', 'biceps', 'triceps', 'forearms'];
    final coreMuscles = ['abs', 'core', 'obliques'];
    final lowerBodyMuscles = ['quadriceps', 'quads', 'hamstrings', 'glutes', 'calves', 'legs'];

    final sortedMuscles = heatmap.sortedByIntensity;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: _getIntensityColor(0.9), label: 'High'),
                const SizedBox(width: 16),
                _LegendItem(color: _getIntensityColor(0.5), label: 'Medium'),
                const SizedBox(width: 16),
                _LegendItem(color: _getIntensityColor(0.2), label: 'Low'),
                const SizedBox(width: 16),
                _LegendItem(color: _getIntensityColor(0.0), label: 'None'),
              ],
            ),
            const SizedBox(height: 24),

            // Upper Body Section
            Text(
              'Upper Body',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
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
            const Divider(),
            const SizedBox(height: 16),

            // Core Section
            Text(
              'Core',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
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
            const Divider(),
            const SizedBox(height: 16),

            // Lower Body Section
            Text(
              'Lower Body',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
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
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Other',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
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
      ),
    );
  }

  Color _getIntensityColor(double intensity) {
    if (intensity >= 0.75) {
      return Colors.red.shade400;
    } else if (intensity >= 0.5) {
      return Colors.orange.shade400;
    } else if (intensity >= 0.25) {
      return Colors.yellow.shade600;
    } else if (intensity > 0) {
      return Colors.green.shade300;
    } else {
      return Colors.grey.shade300;
    }
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall,
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
    final theme = Theme.of(context);
    final normalizedIntensity = maxIntensity > 0 ? muscle.intensity / maxIntensity : 0.0;
    final color = _getIntensityColor(normalizedIntensity);

    return Material(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                muscle.formattedMuscleName,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color.computeLuminance() > 0.5
                      ? Colors.black87
                      : theme.colorScheme.onSurface,
                ),
              ),
              Text(
                muscle.formattedVolume,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getIntensityColor(double intensity) {
    if (intensity >= 0.75) {
      return Colors.red.shade400;
    } else if (intensity >= 0.5) {
      return Colors.orange.shade400;
    } else if (intensity >= 0.25) {
      return Colors.yellow.shade700;
    } else if (intensity > 0) {
      return Colors.green.shade400;
    } else {
      return Colors.grey.shade400;
    }
  }
}
