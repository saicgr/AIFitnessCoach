import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/custom_exercise.dart';
import '../../../data/services/haptic_service.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Card widget for displaying a custom exercise — signature-v2: near-black
/// surface with a hairline border (not a raised Material card), orange accent
/// for composites, Anton/Barlow/Archivo typography.
class CustomExerciseCard extends StatelessWidget {
  final CustomExercise exercise;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CustomExerciseCard({
    super.key,
    required this.exercise,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface2 : AppColorsLight.surface;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accent = AppColors.orange;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap?.call();
      },
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Thumbnail — user-uploaded photo if available, else type-icon fallback.
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cardBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (exercise.imageUrl != null &&
                            exercise.imageUrl!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: exercise.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: isDark
                                  ? AppColors.surface
                                  : AppColorsLight.surface,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: isDark
                                  ? AppColors.surface
                                  : AppColorsLight.surface,
                              child: Icon(Icons.fitness_center,
                                  color: textSecondary, size: 22),
                            ),
                          )
                        : Container(
                            color: exercise.isComposite
                                ? accent.withValues(alpha: 0.12)
                                : (isDark
                                    ? AppColors.surface
                                    : AppColorsLight.surface),
                            child: Center(
                              child: Icon(
                                exercise.isComposite
                                    ? Icons.layers
                                    : Icons.fitness_center,
                                color: exercise.isComposite
                                    ? accent
                                    : textSecondary,
                                size: 22,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Name and type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: ZType.sans(15,
                              color: textPrimary, weight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildTag(
                              context,
                              exercise.typeLabel,
                              exercise.isComposite ? accent : textSecondary,
                            ),
                            const SizedBox(width: 8),
                            _buildTag(
                              context,
                              exercise.primaryMuscle,
                              textSecondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Delete button
                  if (onDelete != null)
                    IconButton(
                      onPressed: () {
                        HapticService.light();
                        onDelete?.call();
                      },
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppColors.error.withValues(alpha: 0.8),
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                ],
              ),

              // Component exercises preview (for composites)
              if (exercise.isComposite && exercise.componentExercises != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surface
                        : AppColorsLight.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.list,
                            size: 13,
                            color: accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context).customExerciseCardExercises(exercise.componentCount).toUpperCase(),
                            style: ZType.lbl(10, color: accent, letterSpacing: 1.2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        exercise.componentExercises!
                            .map((c) => c.name)
                            .join(' → '),
                        style: ZType.sans(13,
                            color: textSecondary, weight: FontWeight.w500, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],

              // Details row
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildDetailChip(
                    context,
                    Icons.repeat,
                    '${exercise.defaultSets} SETS',
                    isDark,
                  ),
                  if (exercise.defaultReps != null) ...[
                    const SizedBox(width: 14),
                    _buildDetailChip(
                      context,
                      Icons.fitness_center,
                      '${exercise.defaultReps} REPS',
                      isDark,
                    ),
                  ],
                  const Spacer(),
                  // Equipment
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surface
                          : AppColorsLight.surface,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getEquipmentIcon(exercise.equipment),
                          size: 13,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatEquipment(exercise.equipment).toUpperCase(),
                          style: ZType.lbl(10, color: textSecondary, letterSpacing: 1.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Usage stats (if used)
              if (exercise.hasBeenUsed) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 13,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context).customExerciseCardUsedTimes(exercise.usageCount).toUpperCase(),
                      style: ZType.lbl(10, color: textSecondary, letterSpacing: 1.0),
                    ),
                    if (exercise.lastUsedFormatted != null) ...[
                      Text(
                        ' · ',
                        style: ZType.lbl(10, color: textSecondary, letterSpacing: 1.0),
                      ),
                      Text(
                        exercise.lastUsedFormatted!.toUpperCase(),
                        style: ZType.lbl(10, color: textSecondary, letterSpacing: 1.0),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text.toUpperCase(),
        style: ZType.lbl(9.5, color: color, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildDetailChip(
    BuildContext context,
    IconData icon,
    String text,
    bool isDark,
  ) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: textSecondary),
        const SizedBox(width: 5),
        Text(
          text.toUpperCase(),
          style: ZType.lbl(10.5, color: textSecondary, letterSpacing: 1.0),
        ),
      ],
    );
  }

  IconData _getEquipmentIcon(String equipment) {
    switch (equipment.toLowerCase()) {
      case 'barbell':
        return Icons.sports_gymnastics;
      case 'dumbbell':
        return Icons.fitness_center;
      case 'cable':
        return Icons.swap_vert;
      case 'machine':
        return Icons.settings;
      case 'bodyweight':
        return Icons.accessibility_new;
      case 'kettlebell':
        return Icons.fitness_center;
      case 'resistance band':
      case 'band':
        return Icons.linear_scale;
      default:
        return Icons.sports;
    }
  }

  String _formatEquipment(String equipment) {
    // Capitalize first letter
    if (equipment.isEmpty) return 'Bodyweight';
    return equipment[0].toUpperCase() + equipment.substring(1);
  }
}
