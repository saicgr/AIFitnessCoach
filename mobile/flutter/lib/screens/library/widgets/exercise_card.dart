import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';
import 'info_badge.dart';
import '../components/exercise_detail_sheet.dart';

/// Card widget displaying exercise info in a list format
class ExerciseCard extends StatelessWidget {
  final LibraryExercise exercise;

  const ExerciseCard({
    super.key,
    required this.exercise,
  });

  IconData _getBodyPartIcon(String? bodyPart) {
    switch (bodyPart?.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.airline_seat_flat;
      case 'shoulders':
        return Icons.accessibility_new;
      case 'biceps':
      case 'triceps':
      case 'arms':
        return Icons.sports_martial_arts;
      case 'core':
      case 'abdominals':
        return Icons.self_improvement;
      case 'quadriceps':
      case 'legs':
      case 'glutes':
      case 'hamstrings':
      case 'calves':
        return Icons.directions_run;
      case 'cardio':
      case 'other':
        return Icons.monitor_heart;
      case 'neck':
        return Icons.face;
      default:
        return Icons.fitness_center;
    }
  }

  void _showExerciseDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseDetailSheet(exercise: exercise),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final hasVideo = exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => _showExerciseDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border:
              isDark ? null : Border.all(color: AppColorsLight.cardBorder),
        ),
        child: Row(
          children: [
            // Thumbnail with video indicator
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    purple.withOpacity(0.3),
                    cyan.withOpacity(0.2),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Body part icon
                  Icon(
                    _getBodyPartIcon(exercise.bodyPart),
                    size: 36,
                    color: purple.withOpacity(0.8),
                  ),
                  // Video play indicator
                  if (hasVideo)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cyan,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          size: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (exercise.muscleGroup != null) ...[
                          InfoBadge(
                            icon: Icons.accessibility_new,
                            text: exercise.muscleGroup!,
                            color: purple,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (exercise.difficulty != null)
                          InfoBadge(
                            icon: Icons.signal_cellular_alt,
                            text: exercise.difficulty!,
                            color: AppColors.getDifficultyColor(
                                exercise.difficulty!),
                          ),
                      ],
                    ),
                    if (exercise.equipment != null &&
                        exercise.equipment!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        exercise.equipment!.take(2).join(', '),
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Arrow
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
