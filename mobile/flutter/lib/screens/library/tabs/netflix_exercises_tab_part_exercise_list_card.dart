part of 'netflix_exercises_tab.dart';


/// Exercise list card (for search results)
class _ExerciseListCard extends StatelessWidget {
  final LibraryExercise exercise;
  final bool isDark;
  final VoidCallback onTap;
  final bool isAiMatch;

  const _ExerciseListCard({
    required this.exercise,
    required this.isDark,
    required this.onTap,
    this.isAiMatch = false,
  });

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'beginner':
        return AppColors.green;
      case 'intermediate':
        return AppColors.yellow;
      case 'advanced':
        return AppColors.orange;
      default:
        return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final difficultyColor = _getDifficultyColor(exercise.difficulty);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // Exercise image or fallback icon
            Container(
              width: 48,
              height: 48,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: difficultyColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: exercise.imageUrl!,
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                      memCacheWidth: 96,
                      memCacheHeight: 96,
                      placeholder: (_, __) => Icon(
                        Icons.fitness_center,
                        color: difficultyColor,
                        size: 24,
                      ),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.fitness_center,
                        color: difficultyColor,
                        size: 24,
                      ),
                    )
                  : Icon(
                      Icons.fitness_center,
                      color: difficultyColor,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isAiMatch) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.cyan,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (exercise.bodyPart != null) ...[
                        Text(
                          exercise.bodyPart!,
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                        Text(' • ', style: TextStyle(color: textMuted)),
                      ],
                      Text(
                        exercise.equipment.isNotEmpty
                            ? exercise.equipment.first
                            : 'Bodyweight',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.chevron_right,
              color: textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}


/// Circular muscle group pill — image on top, label below.
class _MuscleGroupPill extends StatelessWidget {
  final String muscleName;
  final int exerciseCount;
  final String? assetPath;
  final bool isDark;
  final VoidCallback onTap;

  const _MuscleGroupPill({
    required this.muscleName,
    required this.exerciseCount,
    this.assetPath,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final bgColor = isDark ? Colors.grey.shade900 : Colors.grey.shade100;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular image
              Container(
                width: 60,
                height: 60,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  border: Border.all(
                    color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                  ),
                ),
                child: assetPath != null
                    ? Image.asset(
                        assetPath!,
                        fit: BoxFit.cover,
                        cacheWidth: 120,
                        cacheHeight: 120,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.fitness_center,
                          size: 24,
                          color: textMuted,
                        ),
                      )
                    : Icon(
                        Icons.fitness_center,
                        size: 24,
                        color: textMuted,
                      ),
              ),
              const SizedBox(height: 6),
              // Label
              Text(
                muscleName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              Text(
                '$exerciseCount',
                style: TextStyle(
                  fontSize: 10,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Circular equipment pill — icon on top, label below. Matches _MuscleGroupPill style.
class _EquipmentPill extends StatelessWidget {
  final String equipmentName;
  final int exerciseCount;
  final bool isDark;
  final VoidCallback onTap;

  const _EquipmentPill({
    required this.equipmentName,
    required this.exerciseCount,
    required this.isDark,
    required this.onTap,
  });

  IconData _getEquipmentIcon(String name) {
    switch (name) {
      case 'Weights':
        return Icons.fitness_center;
      case 'Bodyweight':
        return Icons.accessibility_new;
      case 'Machines':
        return Icons.precision_manufacturing;
      case 'Cardio':
        return Icons.directions_run;
      default:
        return Icons.fitness_center;
    }
  }

  Color _getEquipmentColor(String name, bool isDark) {
    switch (name) {
      case 'Weights':
        return isDark ? AppColors.orange : AppColorsLight.orange;
      case 'Bodyweight':
        return isDark ? AppColors.green : AppColorsLight.green;
      case 'Machines':
        return isDark ? AppColors.cyan : AppColorsLight.cyan;
      case 'Cardio':
        return AppColors.yellow;
      default:
        return isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final iconColor = _getEquipmentColor(equipmentName, isDark);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.15),
                  border: Border.all(
                    color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                  ),
                ),
                child: Icon(
                  _getEquipmentIcon(equipmentName),
                  size: 26,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 6),
              // Label
              Text(
                equipmentName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              Text(
                '$exerciseCount',
                style: TextStyle(
                  fontSize: 10,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Card widget for Gravl Split Preset
class _GravlSplitCard extends StatelessWidget {
  final AISplitPreset preset;
  final bool isDark;
  final VoidCallback onTap;

  const _GravlSplitCard({
    required this.preset,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;

    // Get gradient colors based on preset category
    final gradientColors = _getGradientColors(preset.category, isDark);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140, // Smaller width
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                _getPresetIcon(preset.id),
                size: 100,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI badge if applicable
                  if (preset.isAIPowered) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 10,
                            color: Colors.white,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  const Spacer(),

                  // Preset name
                  Text(
                    preset.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Days and duration
                  Text(
                    preset.daysPerWeek == 0
                        ? 'Flexible • ${preset.duration}'
                        : '${preset.daysPerWeek} days/week • ${preset.duration}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Difficulty
                  Text(
                    preset.difficulty.first,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradientColors(String category, bool isDark) {
    switch (category) {
      case 'ai_powered':
        return [
          const Color(0xFFEA580C), // Orange
          const Color(0xFFDC2626), // Red
        ];
      case 'specialty':
        return [
          const Color(0xFF7C3AED), // Purple
          const Color(0xFF4F46E5), // Indigo
        ];
      case 'classic':
      default:
        return isDark
            ? [
                const Color(0xFF374151), // Gray 700
                const Color(0xFF1F2937), // Gray 800
              ]
            : [
                const Color(0xFF4B5563), // Gray 600
                const Color(0xFF374151), // Gray 700
              ];
    }
  }

  IconData _getPresetIcon(String id) {
    switch (id) {
      case 'hell_week':
        return Icons.local_fire_department;
      case 'ai_adaptive':
        return Icons.psychology;
      case 'quick_gains':
        return Icons.bolt;
      case 'home_warrior':
        return Icons.home;
      case 'deload_recover':
        return Icons.spa;
      case 'strength_builder':
        return Icons.fitness_center;
      case 'mood_based':
        return Icons.emoji_emotions;
      case 'hybrid_athlete':
        return Icons.directions_run;
      case 'weak_point_destroyer':
        return Icons.gps_fixed;
      case 'senior_strength':
        return Icons.accessibility_new;
      case 'comeback_program':
        return Icons.replay;
      case 'arnold_split':
        return Icons.star;
      case 'ppl_6day':
      case 'ppl_3day':
        return Icons.view_column;
      case 'upper_lower':
        return Icons.swap_vert;
      case 'full_body':
      case 'full_body_minimal':
        return Icons.accessibility_new;
      default:
        return Icons.fitness_center;
    }
  }
}


/// Compact horizontal chip for custom exercises in the library
class _CustomExerciseChip extends StatelessWidget {
  final CustomExercise exercise;
  final bool isDark;

  const _CustomExerciseChip({required this.exercise, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.07);

    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Exercise icon based on equipment
          Icon(
            _equipmentIcon(exercise.equipment),
            size: 22,
            color: isDark ? AppColors.cyan : AppColorsLight.cyan,
          ),
          const SizedBox(height: 8),
          Text(
            exercise.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            exercise.primaryMuscle,
            style: TextStyle(
              fontSize: 11,
              color: textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _equipmentIcon(String equipment) {
    switch (equipment.toLowerCase()) {
      case 'barbell': return Icons.fitness_center;
      case 'dumbbell': return Icons.fitness_center;
      case 'cable': return Icons.swap_vert;
      case 'machine': return Icons.precision_manufacturing;
      case 'bodyweight': return Icons.accessibility_new;
      case 'kettlebell': return Icons.sports_martial_arts;
      case 'resistance band': return Icons.all_inclusive;
      default: return Icons.fitness_center;
    }
  }
}

