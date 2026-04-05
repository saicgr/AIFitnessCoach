part of 'staple_exercises_screen.dart';


class _StapleExerciseTile extends ConsumerWidget {
  final StapleExercise staple;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final Color elevated;
  final bool showProfileBadge;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _StapleExerciseTile({
    required this.staple,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.elevated,
    this.showProfileBadge = false,
    required this.onEdit,
    required this.onRemove,
  });

  Future<void> _showDetail(BuildContext context, WidgetRef ref) async {
    // Try to fetch full exercise data from library API
    final repo = ref.read(libraryRepositoryProvider);
    LibraryExercise libraryExercise;

    try {
      LibraryExerciseItem? fullExercise;

      // First try by library ID if available
      if (staple.libraryId != null) {
        fullExercise = await repo.getExercise(staple.libraryId!);
      }

      // Fallback: search by name
      if (fullExercise == null) {
        final results = await repo.searchExercises(
          query: staple.exerciseName,
          limit: 1,
        );
        if (results.isNotEmpty) {
          fullExercise = results.first;
        }
      }

      if (fullExercise != null) {
        libraryExercise = LibraryExercise(
          id: fullExercise.id,
          nameValue: fullExercise.name,
          bodyPart: fullExercise.bodyPart,
          equipmentValue: fullExercise.equipment,
          targetMuscle: fullExercise.targetMuscle,
          gifUrl: fullExercise.gifUrl,
          videoUrl: fullExercise.videoUrl,
          imageUrl: fullExercise.imageUrl,
          difficultyLevelValue: fullExercise.difficulty,
          instructionsValue: fullExercise.instructions,
        );
      } else {
        // Use minimal data from staple as last resort
        libraryExercise = LibraryExercise(
          id: staple.libraryId,
          nameValue: staple.exerciseName,
          bodyPart: staple.bodyPart,
          equipmentValue: staple.equipment,
          gifUrl: staple.gifUrl,
          category: staple.category,
        );
      }
    } catch (e) {
      debugPrint('Error fetching exercise details: $e');
      libraryExercise = LibraryExercise(
        id: staple.libraryId,
        nameValue: staple.exerciseName,
        bodyPart: staple.bodyPart,
        equipmentValue: staple.equipment,
        gifUrl: staple.gifUrl,
        category: staple.category,
      );
    }

    if (!context.mounted) return;
    showGlassSheet(
      context: context,
      builder: (context) => ExerciseDetailSheet(exercise: libraryExercise),
    );
  }

  Color _badgeColor(String? reason) {
    switch (reason) {
      case 'core_compound':
        return AppColors.cyan;
      case 'favorite':
        return Colors.redAccent;
      case 'rehab':
        return Colors.green;
      case 'strength_focus':
        return Colors.orange;
      default:
        return AppColors.cyan;
    }
  }

  IconData _badgeIcon(String? reason) {
    switch (reason) {
      case 'core_compound':
        return Icons.fitness_center;
      case 'favorite':
        return Icons.favorite;
      case 'rehab':
        return Icons.healing;
      case 'strength_focus':
        return Icons.trending_up;
      default:
        return Icons.push_pin;
    }
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.cyan;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _badgeColor(staple.reason);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _showDetail(context, ref),
        leading: SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ExerciseImage(
                exerciseName: staple.exerciseName,
                width: 56,
                height: 56,
                borderRadius: 12,
              ),
              // Play icon overlay to indicate tappable for video
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              // Reason badge
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: elevated, width: 1.5),
                  ),
                  child: Icon(_badgeIcon(staple.reason), color: Colors.white, size: 10),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          staple.exerciseName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section badge + muscle group row
            Row(
              children: [
                if (staple.section != 'main')
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: staple.section == 'warmup'
                            ? Colors.orange.withValues(alpha: 0.15)
                            : Colors.teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        staple.section == 'warmup' ? 'Warmup' : 'Stretch',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: staple.section == 'warmup' ? Colors.orange : Colors.teal,
                        ),
                      ),
                    ),
                  ),
                if (staple.muscleGroup != null)
                  Flexible(
                    child: Text(
                      staple.muscleGroup!,
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            if (staple.isCardioEquipment)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  staple.cardioParamsDisplay,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (staple.reason != null)
              Text(
                _formatReason(staple.reason!),
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            if (showProfileBadge && (staple.gymProfileName != null || staple.gymProfileId == null))
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: staple.gymProfileColor != null
                            ? _parseColor(staple.gymProfileColor!)
                            : textMuted.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      staple.gymProfileName ?? 'All Profiles',
                      style: TextStyle(
                        fontSize: 10,
                        color: textMuted.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: AppColors.cyan),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: onRemove,
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }

  String _formatReason(String reason) {
    switch (reason) {
      case 'core_compound':
        return 'Core Compound';
      case 'favorite':
        return 'Personal Favorite';
      case 'rehab':
        return 'Rehab / Recovery';
      case 'strength_focus':
        return 'Strength Focus';
      default:
        return reason.replaceAll('_', ' ').split(' ').map((w) =>
          w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
    }
  }
}


/// Exercise type classification for edit sheet field selection
enum _ExerciseType {
  strength,
  timed,
  treadmill,
  bike,
  rower,
  elliptical,
  cardioGeneric,
}

