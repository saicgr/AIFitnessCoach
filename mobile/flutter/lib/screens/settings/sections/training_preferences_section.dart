import 'package:flutter/material.dart';
import '../widgets/widgets.dart';

/// The training preferences section for workout-related settings.
///
/// Allows users to configure:
/// - Progression Pace: How fast to increase weights (slow/medium/fast)
/// - Workout Type: Strength, cardio, or mixed
/// - Exercise Consistency: Vary exercises or keep consistent
/// - Favorite Exercises: Manage favorite exercises for AI prioritization
/// - Exercise Queue: Queue exercises for upcoming workouts
/// - Workout Environment: Where they train (gym, home, etc.)
/// - Equipment: What equipment they have access to
class TrainingPreferencesSection extends StatelessWidget {
  const TrainingPreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'TRAINING'),
        const SizedBox(height: 12),
        SettingsCard(
          items: [
            SettingItemData(
              icon: Icons.speed,
              title: 'My 1RMs',
              subtitle: 'View and edit your max lifts',
              isMyOneRMsScreen: true,
            ),
            SettingItemData(
              icon: Icons.percent,
              title: 'Training Intensity',
              subtitle: 'Work at a percentage of your max',
              isTrainingIntensitySelector: true,
            ),
            SettingItemData(
              icon: Icons.trending_up,
              title: 'Progression Pace',
              subtitle: 'How fast to increase weights',
              isProgressionPaceSelector: true,
            ),
            SettingItemData(
              icon: Icons.fitness_center,
              title: 'Workout Type',
              subtitle: 'Strength, cardio, or mixed',
              isWorkoutTypeSelector: true,
            ),
            SettingItemData(
              icon: Icons.shuffle,
              title: 'Exercise Consistency',
              subtitle: 'Vary or keep same exercises',
              isConsistencyModeSelector: true,
            ),
            SettingItemData(
              icon: Icons.tune,
              title: 'Weekly Variety',
              subtitle: 'How much exercises change each week',
              isVariationSlider: true,
            ),
            SettingItemData(
              icon: Icons.favorite,
              title: 'Favorite Exercises',
              subtitle: 'AI will prioritize these',
              isFavoriteExercisesManager: true,
            ),
            SettingItemData(
              icon: Icons.lock,
              title: 'Staple Exercises',
              subtitle: 'Core lifts that never rotate',
              isStapleExercisesManager: true,
            ),
            SettingItemData(
              icon: Icons.queue,
              title: 'Exercise Queue',
              subtitle: 'Queue exercises for next workout',
              isExerciseQueueManager: true,
            ),
            SettingItemData(
              icon: Icons.history,
              title: 'Import Workout History',
              subtitle: 'Add past workouts for better AI weights',
              isWorkoutHistoryImport: true,
            ),
            SettingItemData(
              icon: Icons.location_on,
              title: 'Workout Environment',
              subtitle: 'Where you train',
              isWorkoutEnvironmentSelector: true,
            ),
            SettingItemData(
              icon: Icons.build,
              title: 'My Equipment',
              subtitle: 'Equipment available for workouts',
              isEquipmentSelector: true,
            ),
          ],
        ),
      ],
    );
  }
}
