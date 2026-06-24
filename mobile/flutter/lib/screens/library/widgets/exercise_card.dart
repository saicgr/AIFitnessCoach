import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/exercise_queue_provider.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/providers/week_comparison_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/utils/difficulty_utils.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout.dart';
import '../../../data/providers/exercise_alternatives_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../utils/tz.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/signature/signature.dart';
import '../components/exercise_detail_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Dense signature-v2 exercise row for the Exercise Library list.
///
/// Layout (matches `#screen-exercise .erow` in the chosen redesign):
/// `[3px difficulty stripe] [40px thumb] title / ●level · muscle · equipment
///  [♥ + ⇄]`.
/// - The 3px left stripe + level dot are colored by [DifficultyUtils.getColor].
/// - Tapping the row opens the existing [ExerciseDetailSheet] (unchanged).
/// - Inline actions: ♥ toggles [favoritesProvider]; + opens the
///   add-to-workout/queue sheet ([_AddToWorkoutSheet]); ⇄ opens the
///   Alternatives sheet ([_AlternativesSheet]).
class ExerciseCard extends ConsumerWidget {
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
    showGlassSheet(
      context: context,
      builder: (context) => ExerciseDetailSheet(exercise: exercise),
    );
  }

  void _showAddToWorkout(BuildContext context) {
    HapticService.light();
    showGlassSheet(
      context: context,
      builder: (context) => _AddToWorkoutSheet(exerciseName: exercise.name),
    );
  }

  void _showAlternatives(BuildContext context) {
    HapticService.light();
    showGlassSheet(
      context: context,
      builder: (context) => _AlternativesSheet(exercise: exercise),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final textMuted = tc.textMuted;
    final hasVideo = exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty;

    final difficulty = exercise.difficulty;
    final hasDifficulty = difficulty != null && difficulty.isNotEmpty;
    final difficultyColor =
        hasDifficulty ? DifficultyUtils.getColor(difficulty) : null;

    // Barlow subtitle: `●<level> · <muscle> · <equipment>`. Only non-empty
    // parts are joined so a sparse exercise never shows dangling separators.
    final levelLabel =
        hasDifficulty ? DifficultyUtils.getDisplayName(difficulty) : null;
    final tailParts = <String>[
      if (exercise.muscleGroup != null && exercise.muscleGroup!.isNotEmpty)
        exercise.muscleGroup!,
      if (exercise.equipment.isNotEmpty) exercise.equipment.first,
    ];

    final isFavorite = ref.watch(
      favoritesProvider.select((s) => s.isFavorite(exercise.name)),
    );
    final isQueued = ref.watch(
      exerciseQueueProvider.select((s) => s.isQueued(exercise.name)),
    );

    return ZHairlineRow(
      onTap: () => _showExerciseDetail(context),
      accentStripeColor: difficultyColor,
      verticalPadding: 9,
      leading: _Thumb(
        exercise: exercise,
        hasVideo: hasVideo,
        fallbackIcon: _getBodyPartIcon(exercise.bodyPart),
        accent: tc.accent,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              exercise.name,
              style: ZType.sans(
                13.5,
                color: tc.textPrimary,
                weight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // NEW badge for exercises new this week.
          Builder(
            builder: (context) {
              final isNew =
                  ref.watch(isExerciseNewThisWeekProvider(exercise.name));
              if (!isNew) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(left: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cyan,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      subtitle: (levelLabel != null || tailParts.isNotEmpty)
          ? Row(
              children: [
                if (levelLabel != null) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: difficultyColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    levelLabel.toUpperCase(),
                    style: ZType.lbl(9.5,
                        color: difficultyColor, letterSpacing: 1.1),
                  ),
                ],
                if (tailParts.isNotEmpty)
                  Expanded(
                    child: Text(
                      '${levelLabel != null ? ' · ' : ''}'
                      '${tailParts.join(' · ').toUpperCase()}',
                      style:
                          ZType.lbl(9.5, color: textMuted, letterSpacing: 1.1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RowAction(
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            active: isFavorite,
            tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
            onTap: () {
              HapticService.light();
              ref.read(favoritesProvider.notifier).toggleFavorite(
                    exercise.name,
                    exerciseId: exercise.id,
                  );
            },
          ),
          const SizedBox(width: 5),
          _RowAction(
            icon: isQueued ? Icons.playlist_add_check : Icons.add,
            active: isQueued,
            tooltip: 'Add to workout',
            onTap: () => _showAddToWorkout(context),
          ),
          const SizedBox(width: 5),
          _RowAction(
            icon: Icons.swap_horiz,
            tooltip: 'Alternatives',
            onTap: () => _showAlternatives(context),
          ),
        ],
      ),
    );
  }
}

/// 40×40 leading thumbnail — exercise illustration / gif with a body-part icon
/// fallback, plus a small video-play marker. Mirrors the `.erow .t` slot.
class _Thumb extends StatelessWidget {
  final LibraryExercise exercise;
  final bool hasVideo;
  final IconData fallbackIcon;
  final Color accent;

  const _Thumb({
    required this.exercise,
    required this.hasVideo,
    required this.fallbackIcon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty;

    return Hero(
      tag: 'exercise-image-${exercise.name}',
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (hasImage)
              CachedNetworkImage(
                imageUrl: exercise.imageUrl!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                placeholder: (context, url) => Icon(
                  fallbackIcon,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                errorWidget: (context, url, error) => Icon(
                  fallbackIcon,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              )
            else
              Icon(
                fallbackIcon,
                size: 18,
                color: AppColors.textMuted,
              ),
            if (hasVideo)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 8,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A 30×30 inline action button (`.erow .acts .b`). Orange-tinted when active.
class _RowAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool active;

  const _RowAction({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? AppColors.orange.withValues(alpha: 0.10)
                : AppColors.surface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? AppColors.orange.withValues(alpha: 0.55)
                  : AppColors.cardBorder,
            ),
          ),
          child: Icon(
            icon,
            size: 15,
            color: active ? AppColors.orange : tc.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet listing [exerciseAlternativesProvider] results for an exercise,
/// each row reusing the dense [ZHairlineRow] style. Tapping an alternative
/// opens its own detail sheet. Errors surface with a Retry — no fabrication.
class _AlternativesSheet extends ConsumerWidget {
  final LibraryExercise exercise;

  const _AlternativesSheet({required this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final exerciseId = exercise.id;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: tc.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: tc.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Icon(Icons.swap_horiz, color: AppColors.orange, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ZSectionKicker(label: 'Alternatives'),
                      const SizedBox(height: 2),
                      Text(
                        exercise.name,
                        style: ZType.sans(13,
                            color: tc.textSecondary, weight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: tc.textMuted),
                ),
              ],
            ),
          ),
          Flexible(
            child: (exerciseId == null || exerciseId.isEmpty)
                ? _AltMessage(
                    icon: Icons.help_outline,
                    text: 'Alternatives are unavailable for this exercise.',
                  )
                : ref.watch(exerciseAlternativesProvider(exerciseId)).when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.orange),
                        ),
                      ),
                      error: (e, _) => _AltMessage(
                        icon: Icons.error_outline,
                        text: 'Couldn\'t load alternatives.',
                        onRetry: () => ref.invalidate(
                            exerciseAlternativesProvider(exerciseId)),
                      ),
                      data: (alternatives) {
                        if (alternatives.isEmpty) {
                          return _AltMessage(
                            icon: Icons.search_off,
                            text: 'No alternatives found for this exercise.',
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: alternatives.length,
                          itemBuilder: (context, index) {
                            return _AlternativeRow(
                              alternative: alternatives[index],
                              showDivider: index < alternatives.length - 1,
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

/// One alternative exercise row — same dense [ZHairlineRow] grammar as the
/// library list. Tapping opens its detail sheet (built from the alt's fields).
class _AlternativeRow extends ConsumerWidget {
  final ExerciseAlternative alternative;
  final bool showDivider;

  const _AlternativeRow({
    required this.alternative,
    required this.showDivider,
  });

  IconData _icon(String? bodyPart) {
    switch (bodyPart?.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.airline_seat_flat;
      case 'shoulders':
        return Icons.accessibility_new;
      case 'arms':
        return Icons.sports_martial_arts;
      case 'core':
        return Icons.self_improvement;
      case 'legs':
        return Icons.directions_run;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final difficulty = alternative.difficultyLevel;
    final hasDifficulty = difficulty != null && difficulty.isNotEmpty;
    final difficultyColor =
        hasDifficulty ? DifficultyUtils.getColor(difficulty) : null;
    final levelLabel =
        hasDifficulty ? DifficultyUtils.getDisplayName(difficulty) : null;

    final tailParts = <String>[
      if (alternative.targetMuscle != null &&
          alternative.targetMuscle!.isNotEmpty)
        alternative.targetMuscle!
      else if (alternative.bodyPart != null && alternative.bodyPart!.isNotEmpty)
        alternative.bodyPart!,
      if (alternative.equipment != null && alternative.equipment!.isNotEmpty)
        alternative.equipment!,
    ];

    final imageUrl = alternative.imageUrl ?? alternative.gifUrl;

    return ZHairlineRow(
      showDivider: showDivider,
      accentStripeColor: difficultyColor,
      verticalPadding: 9,
      onTap: () {
        // Build a LibraryExercise from the alternative's fields so the standard
        // detail sheet can render it (its own id isn't returned, so the detail
        // sheet resolves media by name — matching the rest of the app).
        final alt = LibraryExercise(
          nameValue: alternative.name,
          bodyPart: alternative.bodyPart,
          targetMuscle: alternative.targetMuscle,
          equipmentValue: alternative.equipment,
          difficultyLevelValue: alternative.difficultyLevel,
          gifUrl: alternative.gifUrl,
          imageUrl: imageUrl,
        );
        Navigator.pop(context);
        showGlassSheet(
          context: context,
          builder: (context) => ExerciseDetailSheet(exercise: alt),
        );
      },
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: imageUrl != null && imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                placeholder: (context, url) => Icon(_icon(alternative.bodyPart),
                    size: 18, color: AppColors.textMuted),
                errorWidget: (context, url, error) => Icon(
                    _icon(alternative.bodyPart),
                    size: 18,
                    color: AppColors.textMuted),
              )
            : Icon(_icon(alternative.bodyPart),
                size: 18, color: AppColors.textMuted),
      ),
      title: Text(
        alternative.name,
        style: ZType.sans(13.5, color: tc.textPrimary, weight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: (levelLabel != null || tailParts.isNotEmpty)
          ? Row(
              children: [
                if (levelLabel != null) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: difficultyColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    levelLabel.toUpperCase(),
                    style: ZType.lbl(9.5,
                        color: difficultyColor, letterSpacing: 1.1),
                  ),
                ],
                if (tailParts.isNotEmpty)
                  Expanded(
                    child: Text(
                      '${levelLabel != null ? ' · ' : ''}'
                      '${tailParts.join(' · ').toUpperCase()}',
                      style: ZType.lbl(9.5,
                          color: tc.textMuted, letterSpacing: 1.1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            )
          : null,
      trailing: Icon(Icons.chevron_right, color: tc.textMuted, size: 18),
    );
  }
}

/// Centered icon + message (+ optional Retry) for the alternatives sheet's
/// empty / error / unavailable states.
class _AltMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  const _AltMessage({
    required this.icon,
    required this.text,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: tc.textMuted),
            const SizedBox(height: 14),
            Text(
              text,
              textAlign: TextAlign.center,
              style: ZType.sans(13, color: tc.textMuted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  AppLocalizations.of(context).buttonRetry,
                  style: ZType.lbl(12,
                      color: AppColors.orange, letterSpacing: 1.0),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet to select which workout to add the exercise to
class _AddToWorkoutSheet extends ConsumerStatefulWidget {
  final String exerciseName;

  const _AddToWorkoutSheet({
    required this.exerciseName,
  });

  @override
  ConsumerState<_AddToWorkoutSheet> createState() => _AddToWorkoutSheetState();
}

class _AddToWorkoutSheetState extends ConsumerState<_AddToWorkoutSheet> {
  bool _isAdding = false;
  String? _selectedWorkoutId;

  void _addToQueue() {
    HapticService.light();
    ref.read(exerciseQueueProvider.notifier).addToQueue(widget.exerciseName);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.playlist_add_check, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Added "${widget.exerciseName}" to queue'),
            ),
          ],
        ),
        backgroundColor: AppColors.cyan,
      ),
    );
  }

  Widget _buildQueueOption(
    BuildContext context, {
    required Color elevated,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isQueued = ref.watch(exerciseQueueProvider).isQueued(widget.exerciseName);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Material(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isQueued ? null : _addToQueue,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isQueued ? Icons.playlist_add_check : Icons.playlist_add,
                    color: AppColors.cyan,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isQueued ? AppLocalizations.of(context).exerciseCardAlreadyInQueue : AppLocalizations.of(context).exerciseQueueAddToQueue,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isQueued
                            ? AppLocalizations.of(context).exerciseCardWillBeIncludedIn
                            : 'AI will include in your next generated workout',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isQueued)
                  Icon(Icons.check_circle, color: AppColors.cyan)
                else
                  Icon(Icons.chevron_right, color: textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addToWorkout(Workout workout) async {
    setState(() {
      _isAdding = true;
      _selectedWorkoutId = workout.id;
    });

    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final updatedWorkout = await workoutRepo.addExercise(
        workoutId: workout.id!,
        exerciseName: widget.exerciseName,
      );

      if (mounted) {
        Navigator.pop(context);
        if (updatedWorkout != null) {
          // Refresh workout list silently (no loading flash)
          await ref.read(workoutsProvider.notifier).silentRefresh();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added "${widget.exerciseName}" to ${workout.name}'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).exerciseCardFailedToAddExercise),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAdding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final workoutsAsync = ref.watch(workoutsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.add_circle, color: AppColors.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).exerciseCardAddToWorkout,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.exerciseName,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textMuted),
                ),
              ],
            ),
          ),

          // Add to Queue option
          _buildQueueOption(
            context,
            elevated: elevated,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // Divider with label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: Divider(color: textMuted.withOpacity(0.2))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    AppLocalizations.of(context).exerciseCardOrAddToWorkout,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: textMuted.withOpacity(0.2))),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Workout list
          Flexible(
            child: workoutsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.success),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    AppLocalizations.of(context).exerciseCardFailedToLoadWorkouts,
                    style: TextStyle(color: textMuted),
                  ),
                ),
              ),
              data: (workouts) {
                // Filter to upcoming/today's incomplete workouts
                final today = Tz.localDate();
                final upcomingWorkouts = workouts.where((w) {
                  final date = w.scheduledDate?.split('T')[0] ?? '';
                  return !(w.isCompleted ?? false) && date.compareTo(today) >= 0;
                }).take(5).toList();

                if (upcomingWorkouts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 48,
                            color: textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context).exerciseCardNoUpcomingWorkouts,
                            style: TextStyle(color: textMuted),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context).exerciseCardGenerateAWorkoutPlan,
                            style: TextStyle(
                              fontSize: 12,
                              color: textMuted.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: upcomingWorkouts.length,
                  itemBuilder: (context, index) {
                    final workout = upcomingWorkouts[index];
                    final isFirst = index == 0;
                    final isLoading = _isAdding && _selectedWorkoutId == workout.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: elevated,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _isAdding ? null : () => _addToWorkout(workout),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Workout icon
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isFirst ? AppColors.success : AppColors.cyan)
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.fitness_center,
                                    color: isFirst ? AppColors.success : AppColors.cyan,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Workout info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              workout.name ?? AppLocalizations.of(context).navWorkout,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isFirst)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.success.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'NEXT',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.success,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(workout.scheduledDate),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Loading or add icon
                                if (isLoading)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.success,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.add_circle,
                                    color: isFirst ? AppColors.success : AppColors.cyan,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'No date';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final workoutDate = DateTime(date.year, date.month, date.day);

      if (workoutDate == today) {
        return 'Today';
      } else if (workoutDate == tomorrow) {
        return 'Tomorrow';
      } else {
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
      }
    } catch (e) {
      return dateStr;
    }
  }
}
