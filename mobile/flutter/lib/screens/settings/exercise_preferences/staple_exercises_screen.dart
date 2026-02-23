import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/staples_provider.dart';
import '../../../data/models/exercise.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/repositories/exercise_preferences_repository.dart';
import '../../../data/repositories/library_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/exercise_image.dart';
import '../../../widgets/glass_back_button.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/staple_choice_sheet.dart';
import '../../library/components/exercise_detail_sheet.dart';
import 'widgets/exercise_picker_sheet.dart';

/// Screen for managing staple exercises (core lifts that never rotate).
/// When [embedded] is true, renders without Scaffold/AppBar for use inside tabs.
class StapleExercisesScreen extends ConsumerWidget {
  final bool embedded;
  const StapleExercisesScreen({super.key, this.embedded = false});

  Future<void> _showAddExercisePicker(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();

    final staplesState = ref.read(staplesProvider);
    final excludeNames = staplesState.staples
        .map((s) => s.exerciseName.toLowerCase())
        .toSet();

    final result = await showExercisePickerSheet(
      context,
      ref,
      type: ExercisePickerType.staple,
      excludeExercises: excludeNames,
    );

    if (result != null && context.mounted) {
      // Show choice sheet before saving
      final choice = await showStapleChoiceSheet(
        context,
        exerciseName: result.exerciseName,
      );
      if (choice == null) return; // Cancelled

      final success = await ref.read(staplesProvider.notifier).addStaple(
        result.exerciseName,
        libraryId: result.exerciseId,
        muscleGroup: result.muscleGroup,
        reason: result.reason,
        addToCurrentWorkout: choice.addToday,
        section: choice.section,
        gymProfileId: choice.gymProfileId,
        swapExerciseId: choice.swapExerciseId,
        cardioParams: choice.cardioParams,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Added "${result.exerciseName}" as a staple'
                  : 'Failed to add exercise',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final staplesState = ref.watch(staplesProvider);

    final body = Stack(
      children: [
        staplesState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : staplesState.staples.isEmpty
                ? _buildEmptyState(context, ref, textMuted)
                : _buildStaplesList(
                    context,
                    ref,
                    staplesState.staples,
                    isDark,
                    textPrimary,
                    textMuted,
                    elevated,
                  ),

        // Regeneration overlay
        if (staplesState.isRegenerating)
          _buildRegenerationOverlay(context, staplesState.regenerationMessage, isDark),
      ],
    );

    if (embedded) return body;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        centerTitle: true,
        title: Text(
          'Staple Exercises',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ),
      floatingActionButton: staplesState.isRegenerating
          ? null
          : FloatingActionButton(
              onPressed: () {
                HapticService.light();
                _showAddExercisePicker(context, ref);
              },
              backgroundColor: AppColors.cyan,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: body,
    );
  }

  Widget _buildRegenerationOverlay(BuildContext context, String? message, bool isDark) {
    return Container(
      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
            ),
            const SizedBox(height: 24),
            Text(
              'Regenerating Workouts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message ?? 'Adding staple to upcoming workouts...',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This may take a moment',
              style: TextStyle(
                fontSize: 12,
                color: (isDark ? AppColors.textMuted : AppColorsLight.textMuted)
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, Color textMuted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.push_pin_outlined,
              size: 72,
              color: (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.purple : AppColorsLight.purple).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Staple Exercises',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Staple exercises are your core lifts that will NEVER be rotated out of your workouts.',
              style: TextStyle(
                fontSize: 14,
                color: textMuted.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddExercisePicker(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Staple'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaplesList(
    BuildContext context,
    WidgetRef ref,
    List<StapleExercise> staples,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color elevated,
  ) {
    final profileCount = ref.read(gymProfilesProvider).valueOrNull?.length ?? 1;

    return Column(
      children: [
        // Info banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.purple : AppColorsLight.purple).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isDark ? AppColors.purple : AppColorsLight.purple).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.push_pin,
                color: isDark ? AppColors.purple : AppColorsLight.purple,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'These core lifts will NEVER be rotated out of your workouts, regardless of your variety setting.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColorsLight.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Staples list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: staples.length,
            itemBuilder: (context, index) {
              final staple = staples[index];
              return _StapleExerciseTile(
                staple: staple,
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
                elevated: elevated,
                showProfileBadge: profileCount >= 2,
                onRemove: () async {
                  HapticFeedback.lightImpact();
                  final confirmed = await _showRemoveDialog(
                    context,
                    staple.exerciseName,
                    isDark,
                  );
                  if (confirmed == true) {
                    ref
                        .read(staplesProvider.notifier)
                        .removeStaple(staple.id);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<bool?> _showRemoveDialog(
    BuildContext context,
    String exerciseName,
    bool isDark,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: const Text('Remove Staple?'),
        content: Text(
          'Remove "$exerciseName" from your staples? This exercise may be rotated out in future workouts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _StapleExerciseTile extends ConsumerWidget {
  final StapleExercise staple;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final Color elevated;
  final bool showProfileBadge;
  final VoidCallback onRemove;

  const _StapleExerciseTile({
    required this.staple,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.elevated,
    this.showProfileBadge = false,
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
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: onRemove,
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

