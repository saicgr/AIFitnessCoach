import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
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

  /// Help items explaining each training preference
  static const List<Map<String, dynamic>> _trainingHelpItems = [
    {
      'icon': Icons.speed,
      'title': 'My 1RMs (One Rep Max)',
      'description': 'Your maximum weight for one rep on key lifts. The AI uses this to calculate appropriate weights for your workouts.',
      'color': AppColors.purple,
    },
    {
      'icon': Icons.percent,
      'title': 'Training Intensity',
      'description': 'The percentage of your max weight you train at. Lower percentages (60-70%) for endurance, higher (80-90%) for strength.',
      'color': AppColors.orange,
    },
    {
      'icon': Icons.trending_up,
      'title': 'Progression Pace',
      'description': 'How quickly the AI increases your weights. "Slow" for beginners or recovery, "Fast" for experienced lifters pushing limits.',
      'color': AppColors.cyan,
    },
    {
      'icon': Icons.fitness_center,
      'title': 'Workout Type',
      'description': 'Choose between strength training, cardio, or mixed workouts based on your fitness goals.',
      'color': AppColors.purple,
    },
    {
      'icon': Icons.calendar_month,
      'title': 'Workout Days',
      'description': 'Select which days of the week you want to work out. The AI will schedule workouts on your chosen days.',
      'color': AppColors.cyan,
    },
    {
      'icon': Icons.shuffle,
      'title': 'Exercise Consistency',
      'description': 'Control how often exercises change. "Consistent" repeats exercises for progressive overload, "Varied" keeps workouts fresh.',
      'color': AppColors.success,
    },
    {
      'icon': Icons.tune,
      'title': 'Weekly Variety',
      'description': 'Adjust how much your weekly exercises differ. Higher variety prevents boredom but may slow muscle adaptation.',
      'color': AppColors.cyan,
    },
    {
      'icon': Icons.favorite,
      'title': 'Favorite Exercises',
      'description': 'Exercises you enjoy. The AI gives these a priority boost so they appear more often — but they can still be rotated out for variety.',
      'color': AppColors.error,
    },
    {
      'icon': Icons.lock,
      'title': 'Staple Exercises',
      'description': 'Core lifts that are GUARANTEED in every workout for their muscle group. They never rotate out and can be scoped to specific gym profiles.',
      'color': AppColors.purple,
    },
    {
      'icon': Icons.queue,
      'title': 'Exercise Queue',
      'description': 'Request specific exercises for your next workout. The AI will incorporate them when possible.',
      'color': AppColors.cyan,
    },
    {
      'icon': Icons.block,
      'title': 'Exercises to Avoid',
      'description': 'Exercises that cause pain or you dislike. The AI will never include these in your workouts.',
      'color': AppColors.error,
    },
    {
      'icon': Icons.accessibility_new,
      'title': 'Muscles to Avoid',
      'description': 'Muscle groups with injuries or that you want to rest. The AI will skip or reduce exercises targeting them.',
      'color': AppColors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'TRAINING',
          subtitle: 'Customize how workouts are generated',
          helpTitle: 'Training Preferences Explained',
          helpItems: _trainingHelpItems,
        ),
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
              icon: Icons.view_week,
              title: 'Training Split',
              subtitle: 'Push/Pull/Legs, Full Body, etc.',
              isTrainingSplitSelector: true,
            ),
            SettingItemData(
              icon: Icons.calendar_month,
              title: 'Workout Days',
              subtitle: 'Which days you train',
              isWorkoutDaysSelector: true,
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
              subtitle: 'Boosted in selection, can rotate',
              isFavoriteExercisesManager: true,
            ),
            SettingItemData(
              icon: Icons.lock,
              title: 'Staple Exercises',
              subtitle: 'Guaranteed, never rotate out',
              isStapleExercisesManager: true,
            ),
            SettingItemData(
              icon: Icons.queue,
              title: 'Exercise Queue',
              subtitle: 'Queue exercises for next workout',
              isExerciseQueueManager: true,
            ),
            SettingItemData(
              icon: Icons.block,
              title: 'Exercises to Avoid',
              subtitle: 'Skip specific exercises',
              isAvoidedExercisesManager: true,
            ),
            SettingItemData(
              icon: Icons.accessibility_new,
              title: 'Muscles to Avoid',
              subtitle: 'Skip or reduce muscle groups',
              isAvoidedMusclesManager: true,
            ),
            SettingItemData(
              icon: Icons.history,
              title: 'Import Workout History',
              subtitle: 'Add past workouts for better AI weights',
              isWorkoutHistoryImport: true,
            ),
            SettingItemData(
              icon: Icons.show_chart,
              title: 'Progress Charts',
              subtitle: 'Visualize strength & volume over time',
              isProgressChartsScreen: true,
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
