/// Exercise info bottom sheet widget
///
/// Shows exercise setup instructions, target muscles, and form tips
/// when user taps the exercise name in the bottom bar.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';

/// Show the exercise info bottom sheet
Future<void> showExerciseInfoSheet({
  required BuildContext context,
  required WorkoutExercise exercise,
}) {
  HapticFeedback.mediumImpact();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ExerciseInfoSheet(exercise: exercise),
  );
}

/// Exercise info bottom sheet
class ExerciseInfoSheet extends StatelessWidget {
  final WorkoutExercise exercise;

  const ExerciseInfoSheet({
    super.key,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header with image/GIF
              _buildHeader(isDark, textPrimary, textMuted),
              const SizedBox(height: 20),

              // Target Muscles section
              _buildSection(
                title: 'Target Muscles',
                icon: Icons.accessibility_new,
                color: AppColors.orange,
                isDark: isDark,
                textPrimary: textPrimary,
                child: _buildMuscleChips(isDark),
              ),
              const SizedBox(height: 16),

              // Equipment section
              _buildSection(
                title: 'Equipment',
                icon: Icons.fitness_center,
                color: AppColors.purple,
                isDark: isDark,
                textPrimary: textPrimary,
                child: Text(
                  exercise.equipment ?? 'Bodyweight',
                  style: TextStyle(
                    fontSize: 14,
                    color: textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Setup Instructions
              _buildSection(
                title: 'Setup',
                icon: Icons.checklist,
                color: AppColors.cyan,
                isDark: isDark,
                textPrimary: textPrimary,
                child: _buildSetupInstructions(isDark, textPrimary, textMuted),
              ),
              const SizedBox(height: 16),

              // Form Tips
              _buildSection(
                title: 'Form Tips',
                icon: Icons.tips_and_updates,
                color: AppColors.success,
                isDark: isDark,
                textPrimary: textPrimary,
                child: _buildFormTips(isDark, textPrimary, textMuted),
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, Color textPrimary, Color textMuted) {
    final hasImage = exercise.gifUrl != null && exercise.gifUrl!.isNotEmpty;

    return Column(
      children: [
        // Exercise image/GIF
        if (hasImage)
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark
                  ? AppColors.elevated
                  : Colors.grey.shade100,
            ),
            clipBehavior: Clip.antiAlias,
            child: CachedNetworkImage(
              imageUrl: exercise.gifUrl!,
              fit: BoxFit.contain,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(
                  color: AppColors.electricBlue,
                  strokeWidth: 2,
                ),
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.fitness_center_rounded,
                size: 64,
                color: textMuted.withOpacity(0.5),
              ),
            ),
          )
        else
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark
                  ? AppColors.elevated
                  : Colors.grey.shade100,
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              size: 64,
              color: textMuted.withOpacity(0.5),
            ),
          ),
        const SizedBox(height: 16),

        // Exercise name
        Text(
          exercise.name,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          textAlign: TextAlign.center,
        ),

        // Body part badge - show muscle group, not equipment type
        Builder(
          builder: (context) {
            final badgeText = _getBodyPartBadge();
            if (badgeText == null) return const SizedBox.shrink();
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.electricBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeText.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.electricBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMuscleChips(bool isDark) {
    // Get target muscles from exercise or use bodyPart as fallback
    final muscles = _getTargetMuscles();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate max width for chips (account for section padding)
        final maxChipWidth = constraints.maxWidth - 20;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: muscles.map((muscle) {
            final isPrimary = muscle == muscles.first;
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxChipWidth),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? AppColors.orange.withOpacity(0.15)
                      : (isDark ? AppColors.elevated : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(16),
                  border: isPrimary
                      ? Border.all(color: AppColors.orange.withOpacity(0.3))
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPrimary)
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppColors.orange,
                      ),
                    if (isPrimary) const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        muscle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
                          color: isPrimary
                              ? AppColors.orange
                              : (isDark ? AppColors.textPrimary : AppColorsLight.textPrimary),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  List<String> _getTargetMuscles() {
    final muscles = <String>[];

    // 1. First try to use primaryMuscle field (most accurate)
    if (exercise.primaryMuscle != null && exercise.primaryMuscle!.isNotEmpty) {
      final primary = exercise.primaryMuscle!;
      // Handle comma-separated list in primaryMuscle field
      if (primary.contains(',')) {
        for (final muscle in primary.split(',')) {
          if (muscle.trim().isNotEmpty) {
            muscles.add(_capitalize(muscle.trim()));
          }
        }
      } else {
        muscles.add(_capitalize(primary));
      }
    }

    // 2. Add secondary muscles if available
    if (exercise.secondaryMuscles != null) {
      if (exercise.secondaryMuscles is List) {
        for (final muscle in exercise.secondaryMuscles as List) {
          if (muscle is String && muscle.isNotEmpty) {
            muscles.add(_capitalize(muscle));
          }
        }
      } else if (exercise.secondaryMuscles is String) {
        final secondary = exercise.secondaryMuscles as String;
        if (secondary.isNotEmpty) {
          // Handle comma-separated list
          for (final muscle in secondary.split(',')) {
            if (muscle.trim().isNotEmpty) {
              muscles.add(_capitalize(muscle.trim()));
            }
          }
        }
      }
    }

    // 3. If we have muscles from fields, return them
    if (muscles.isNotEmpty) {
      return muscles;
    }

    // 4. Try muscleGroup field
    if (exercise.muscleGroup != null && exercise.muscleGroup!.isNotEmpty) {
      final muscleGroup = exercise.muscleGroup!.toLowerCase();
      return _getMusclesFromGroup(muscleGroup);
    }

    // 5. Try to infer from exercise name
    final inferredMuscles = _inferMusclesFromName(exercise.name);
    if (inferredMuscles.isNotEmpty) {
      return inferredMuscles;
    }

    // 6. Fallback - try bodyPart but filter out equipment types
    if (exercise.bodyPart != null && exercise.bodyPart!.isNotEmpty) {
      final bodyPart = exercise.bodyPart!.toLowerCase();
      // Skip if bodyPart is actually equipment category
      if (!_isEquipmentType(bodyPart)) {
        return _getMusclesFromGroup(bodyPart);
      }
    }

    return ['Full Body'];
  }

  /// Get body part badge text (returns null if it would be an equipment type)
  String? _getBodyPartBadge() {
    // Prefer muscleGroup or primaryMuscle over bodyPart
    if (exercise.muscleGroup != null && exercise.muscleGroup!.isNotEmpty) {
      return exercise.muscleGroup;
    }
    if (exercise.primaryMuscle != null && exercise.primaryMuscle!.isNotEmpty) {
      return exercise.primaryMuscle;
    }
    // Use bodyPart only if it's not an equipment type
    if (exercise.bodyPart != null && exercise.bodyPart!.isNotEmpty) {
      if (!_isEquipmentType(exercise.bodyPart!)) {
        return exercise.bodyPart;
      }
    }
    // Infer from exercise name
    final inferredMuscles = _inferMusclesFromName(exercise.name);
    if (inferredMuscles.isNotEmpty) {
      return inferredMuscles.first;
    }
    return null;
  }

  /// Check if the value is an equipment type, not a muscle group
  bool _isEquipmentType(String value) {
    const equipmentTypes = [
      'free weights',
      'freeweights',
      'machine',
      'machines',
      'cable',
      'cables',
      'barbell',
      'dumbbell',
      'dumbbells',
      'kettlebell',
      'bodyweight',
      'body weight',
      'resistance band',
      'bands',
      'smith machine',
      'ez bar',
      'trap bar',
    ];
    return equipmentTypes.contains(value.toLowerCase());
  }

  /// Get muscles from a muscle group name
  List<String> _getMusclesFromGroup(String group) {
    final muscleMap = {
      'chest': ['Chest', 'Triceps', 'Front Delts'],
      'back': ['Lats', 'Rhomboids', 'Biceps'],
      'shoulders': ['Deltoids', 'Triceps', 'Upper Back'],
      'arms': ['Biceps', 'Triceps', 'Forearms'],
      'biceps': ['Biceps', 'Forearms'],
      'triceps': ['Triceps', 'Shoulders'],
      'legs': ['Quadriceps', 'Hamstrings', 'Glutes'],
      'quadriceps': ['Quadriceps', 'Glutes'],
      'quads': ['Quadriceps', 'Glutes'],
      'hamstrings': ['Hamstrings', 'Glutes'],
      'glutes': ['Glutes', 'Hamstrings'],
      'calves': ['Calves', 'Tibialis'],
      'core': ['Abs', 'Obliques', 'Lower Back'],
      'abs': ['Abs', 'Obliques'],
      'cardio': ['Full Body', 'Heart'],
      'full body': ['Full Body'],
    };

    return muscleMap[group] ?? [_capitalize(group)];
  }

  /// Infer target muscles from exercise name
  List<String> _inferMusclesFromName(String name) {
    final lowerName = name.toLowerCase();

    // Chest exercises
    if (lowerName.contains('bench press') ||
        lowerName.contains('chest press') ||
        lowerName.contains('fly') ||
        lowerName.contains('flye') ||
        lowerName.contains('push up') ||
        lowerName.contains('pushup') ||
        lowerName.contains('pec')) {
      return ['Chest', 'Triceps', 'Front Delts'];
    }

    // Shoulder exercises
    if (lowerName.contains('shoulder press') ||
        lowerName.contains('overhead press') ||
        lowerName.contains('military press') ||
        lowerName.contains('push press') ||
        lowerName.contains('arnold') ||
        lowerName.contains('lateral raise') ||
        lowerName.contains('front raise') ||
        lowerName.contains('rear delt')) {
      return ['Shoulders', 'Triceps', 'Upper Back'];
    }

    // Back exercises
    if (lowerName.contains('row') ||
        lowerName.contains('pull up') ||
        lowerName.contains('pullup') ||
        lowerName.contains('pulldown') ||
        lowerName.contains('pull down') ||
        lowerName.contains('lat ')) {
      return ['Back', 'Biceps', 'Rear Delts'];
    }

    // Biceps exercises
    if (lowerName.contains('curl') && !lowerName.contains('leg curl')) {
      return ['Biceps', 'Forearms'];
    }

    // Triceps exercises
    if (lowerName.contains('tricep') ||
        lowerName.contains('pushdown') ||
        lowerName.contains('skull crusher') ||
        lowerName.contains('dip') ||
        lowerName.contains('extension') && lowerName.contains('arm')) {
      return ['Triceps', 'Shoulders'];
    }

    // Leg exercises
    if (lowerName.contains('squat') ||
        lowerName.contains('leg press') ||
        lowerName.contains('lunge')) {
      return ['Quadriceps', 'Glutes', 'Hamstrings'];
    }

    if (lowerName.contains('deadlift') ||
        lowerName.contains('hip thrust') ||
        lowerName.contains('glute')) {
      return ['Glutes', 'Hamstrings', 'Lower Back'];
    }

    if (lowerName.contains('leg curl') || lowerName.contains('hamstring')) {
      return ['Hamstrings', 'Glutes'];
    }

    if (lowerName.contains('leg extension') || lowerName.contains('quad')) {
      return ['Quadriceps'];
    }

    if (lowerName.contains('calf') || lowerName.contains('calve')) {
      return ['Calves'];
    }

    // Core exercises
    if (lowerName.contains('crunch') ||
        lowerName.contains('sit up') ||
        lowerName.contains('situp') ||
        lowerName.contains('plank') ||
        lowerName.contains('ab ') ||
        lowerName.contains('core')) {
      return ['Abs', 'Obliques', 'Core'];
    }

    return [];
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _buildSetupInstructions(bool isDark, Color textPrimary, Color textMuted) {
    final instructions = _getSetupInstructions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: instructions.asMap().entries.map((entry) {
        final index = entry.key;
        final instruction = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cyan,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  instruction,
                  style: TextStyle(
                    fontSize: 14,
                    color: textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<String> _getSetupInstructions() {
    // Generate setup instructions based on exercise type
    final name = exercise.name.toLowerCase();

    if (name.contains('bench') || name.contains('press')) {
      return [
        'Set up the bench at the appropriate angle (flat, incline, or decline).',
        'Grip the bar slightly wider than shoulder-width.',
        'Plant your feet firmly on the ground.',
        'Retract your shoulder blades and maintain a slight arch in your lower back.',
      ];
    } else if (name.contains('squat')) {
      return [
        'Position the bar on your upper back (not your neck).',
        'Stand with feet shoulder-width apart, toes slightly pointed out.',
        'Brace your core before descending.',
        'Keep your knees tracking over your toes.',
      ];
    } else if (name.contains('deadlift')) {
      return [
        'Stand with feet hip-width apart, bar over mid-foot.',
        'Grip the bar just outside your legs.',
        'Keep your back flat and chest up.',
        'Drive through your heels and push hips forward.',
      ];
    } else if (name.contains('row')) {
      return [
        'Hinge at the hips with a slight knee bend.',
        'Keep your back flat and core engaged.',
        'Pull the weight toward your lower chest/upper abs.',
        'Squeeze your shoulder blades together at the top.',
      ];
    } else if (name.contains('curl')) {
      return [
        'Stand with feet shoulder-width apart.',
        'Keep your elbows close to your sides.',
        'Control the weight on both the up and down phases.',
        'Avoid swinging or using momentum.',
      ];
    } else if (name.contains('pull') && (name.contains('up') || name.contains('down'))) {
      return [
        'Grip the bar slightly wider than shoulder-width.',
        'Engage your lats before pulling.',
        'Pull your elbows down and back.',
        'Lower with control to full arm extension.',
      ];
    }

    // Default generic instructions
    return [
      'Set up your equipment and check your form in a mirror if available.',
      'Warm up with lighter weight first.',
      'Focus on controlled movements throughout.',
      'Breathe consistently - exhale on exertion.',
    ];
  }

  Widget _buildFormTips(bool isDark, Color textPrimary, Color textMuted) {
    final tips = _getFormTips();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tips.map((tip) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 18,
                color: AppColors.success,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tip,
                  style: TextStyle(
                    fontSize: 14,
                    color: textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<String> _getFormTips() {
    final name = exercise.name.toLowerCase();

    if (name.contains('bench') || name.contains('press')) {
      return [
        'Keep your wrists straight and stacked over your elbows.',
        'Lower the bar to your mid-chest with control.',
        'Press through your chest, not just your arms.',
        'Maintain tension at the bottom - no bouncing.',
      ];
    } else if (name.contains('squat')) {
      return [
        'Keep your weight in your heels and mid-foot.',
        'Go as deep as your mobility allows with good form.',
        'Don\'t let your knees cave inward.',
        'Stand up by driving your hips forward.',
      ];
    } else if (name.contains('deadlift')) {
      return [
        'Never round your lower back.',
        'Keep the bar close to your body throughout.',
        'Lock out by squeezing your glutes, not hyperextending.',
        'Lower with control - don\'t drop the weight.',
      ];
    } else if (name.contains('row')) {
      return [
        'Initiate the pull with your back, not your arms.',
        'Keep your core tight to protect your lower back.',
        'Avoid jerky movements - stay controlled.',
        'Focus on the muscle contraction at the top.',
      ];
    } else if (name.contains('curl')) {
      return [
        'Keep your upper arms stationary.',
        'Don\'t swing the weight or use your back.',
        'Squeeze at the top of the movement.',
        'Lower slowly for maximum tension.',
      ];
    }

    // Default generic tips
    return [
      'Focus on mind-muscle connection.',
      'Control the weight through the full range of motion.',
      'Avoid using momentum - let the target muscle do the work.',
      'If form breaks down, reduce the weight.',
    ];
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Color textPrimary,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 42),
          child: child,
        ),
      ],
    );
  }
}
