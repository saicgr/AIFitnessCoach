import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise.dart';

/// Mixin providing exercise management functionality for workout screens.
/// This includes reordering, skipping, swapping, and superset management.
mixin ExerciseManagementMixin<T extends StatefulWidget> on State<T> {
  // These must be implemented by the using class
  List<WorkoutExercise> get exercises;
  int get currentExerciseIndex;
  set currentExerciseIndex(int value);
  int get viewingExerciseIndex;
  set viewingExerciseIndex(int value);
  Map<int, List<dynamic>> get completedSets;
  Map<int, int> get totalSetsPerExercise;
  Map<int, List<Map<String, dynamic>>> get previousSets;

  // Callbacks that must be provided by the implementing class
  void onExerciseChanged(WorkoutExercise exercise);
  Future<void> createSupersetPair(int index1, int index2);
  Future<void> removeFromSuperset(int index);
  Future<WorkoutExercise?> showSwapSheet(BuildContext context, WorkoutExercise exercise);
  Future<int?> showSupersetPickerSheet(int preselectedIndex); // Returns selected exercise index

  /// Reorder exercises in the list
  void reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final exercise = exercises.removeAt(oldIndex);
      exercises.insert(newIndex, exercise);

      // Reorder tracking maps
      final tempCompletedSets = Map<int, List<dynamic>>.from(completedSets);
      final tempTotalSets = Map<int, int>.from(totalSetsPerExercise);
      final tempPreviousSets = Map<int, List<Map<String, dynamic>>>.from(previousSets);

      completedSets.clear();
      totalSetsPerExercise.clear();
      previousSets.clear();

      for (int i = 0; i < exercises.length; i++) {
        int originalIndex = i;
        if (i == newIndex) {
          originalIndex = oldIndex;
        } else if (oldIndex < newIndex && i >= oldIndex && i < newIndex) {
          originalIndex = i + 1;
        } else if (oldIndex > newIndex && i > newIndex && i <= oldIndex) {
          originalIndex = i - 1;
        }

        completedSets[i] = tempCompletedSets[originalIndex] ?? [];
        totalSetsPerExercise[i] = tempTotalSets[originalIndex] ?? 3;
        previousSets[i] = tempPreviousSets[originalIndex] ?? [];
      }

      // Adjust indices
      if (currentExerciseIndex == oldIndex) {
        currentExerciseIndex = newIndex;
      } else if (oldIndex < currentExerciseIndex && newIndex >= currentExerciseIndex) {
        currentExerciseIndex--;
      } else if (oldIndex > currentExerciseIndex && newIndex <= currentExerciseIndex) {
        currentExerciseIndex++;
      }

      if (viewingExerciseIndex == oldIndex) {
        viewingExerciseIndex = newIndex;
      } else if (oldIndex < viewingExerciseIndex && newIndex >= viewingExerciseIndex) {
        viewingExerciseIndex--;
      } else if (oldIndex > viewingExerciseIndex && newIndex <= viewingExerciseIndex) {
        viewingExerciseIndex++;
      }
    });

    HapticFeedback.mediumImpact();
  }

  /// Show exercise options menu
  void showExerciseOptionsMenu(BuildContext ctx, int index) {
    final exercise = exercises[index];

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              exercise.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Start this exercise
            ExerciseOptionTile(
              icon: Icons.play_circle_outline,
              title: 'Start This Exercise',
              subtitle: 'Make this the active exercise',
              color: AppColors.cyan,
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(ctx);
                makeExerciseActive(index);
              },
            ),

            const SizedBox(height: 12),

            // Replace exercise
            ExerciseOptionTile(
              icon: Icons.swap_horiz,
              title: 'Replace Exercise',
              subtitle: 'AI-powered alternatives',
              color: AppColors.purple,
              onTap: () async {
                Navigator.pop(context);
                final replacement = await showSwapSheet(ctx, exercise);
                if (replacement != null) {
                  setState(() {
                    exercises[index] = replacement;
                  });
                  if (index == currentExerciseIndex) {
                    onExerciseChanged(replacement);
                  }
                }
              },
            ),

            const SizedBox(height: 12),

            // Skip exercise
            ExerciseOptionTile(
              icon: Icons.skip_next,
              title: 'Skip Exercise',
              subtitle: 'Remove from this workout',
              color: AppColors.orange,
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(ctx);
                skipExercise(index);
              },
            ),

            const SizedBox(height: 12),

            // Superset options
            if (exercise.isInSuperset) ...[
              ExerciseOptionTile(
                icon: Icons.link_off,
                title: 'Remove from Superset',
                subtitle: 'Break the superset pair',
                color: AppColors.error,
                onTap: () async {
                  Navigator.pop(context);
                  Navigator.pop(ctx);
                  await removeFromSuperset(index);
                },
              ),
            ] else ...[
              if (index < exercises.length - 1 && !exercises[index + 1].isInSuperset)
                ExerciseOptionTile(
                  icon: Icons.link,
                  title: 'Pair with Next Exercise',
                  subtitle: 'Create superset with ${exercises[index + 1].name}',
                  color: AppColors.purple,
                  onTap: () async {
                    Navigator.pop(context);
                    Navigator.pop(ctx);
                    await createSupersetPair(index, index + 1);
                  },
                ),
              const SizedBox(height: 12),
              ExerciseOptionTile(
                icon: Icons.add_link,
                title: 'Create Superset',
                subtitle: 'Choose exercise to pair with',
                color: AppColors.purple,
                onTap: () async {
                  Navigator.pop(context);
                  Navigator.pop(ctx);
                  await showSupersetCreationSheet(index);
                },
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Make a specific exercise active
  void makeExerciseActive(int index) {
    if (index == currentExerciseIndex) return;

    final exercise = exercises[index];
    final completedSetsCount = completedSets[index]?.length ?? 0;

    setState(() {
      currentExerciseIndex = index;
      viewingExerciseIndex = index;
    });

    onExerciseChanged(exercise);
    HapticFeedback.mediumImpact();
  }

  /// Skip a specific exercise
  void skipExercise(int index) {
    if (exercises.length <= 1) return;

    setState(() {
      exercises.removeAt(index);

      // Adjust indices
      if (index < currentExerciseIndex) {
        currentExerciseIndex--;
      } else if (index == currentExerciseIndex && currentExerciseIndex >= exercises.length) {
        currentExerciseIndex = exercises.length - 1;
      }

      if (index < viewingExerciseIndex) {
        viewingExerciseIndex--;
      } else if (index == viewingExerciseIndex && viewingExerciseIndex >= exercises.length) {
        viewingExerciseIndex = exercises.length - 1;
      }
    });

    HapticFeedback.mediumImpact();
  }

  /// Show superset creation sheet
  Future<void> showSupersetCreationSheet(int preselectedIndex) async {
    // Check if there are available exercises
    int availableCount = 0;
    for (int i = 0; i < exercises.length; i++) {
      if (i != preselectedIndex && !exercises[i].isInSuperset) {
        availableCount++;
      }
    }

    if (availableCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available exercises to pair with')),
      );
      return;
    }

    // Use the callback to show the superset picker
    final selectedIndex = await showSupersetPickerSheet(preselectedIndex);

    if (selectedIndex != null) {
      await createSupersetPair(preselectedIndex, selectedIndex);
    }
  }
}

/// Option tile for exercise menu
class ExerciseOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const ExerciseOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
