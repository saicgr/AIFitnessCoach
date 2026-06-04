import 'package:flutter/material.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../exercise_preferences/excluded_muscles_screen.dart';
import '../widgets/widgets.dart';

import '../../../l10n/generated/app_localizations.dart';
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
          title: AppLocalizations.of(context).trainingPreferencesTraining,
          subtitle: AppLocalizations.of(context).trainingPreferencesCustomizeHowWorkoutsAre,
          helpTitle: 'Training Preferences Explained',
          helpItems: _trainingHelpItems,
        ),
        const SizedBox(height: 12),
        SettingsCard(
          items: [
            SettingItemData(
              icon: Icons.speed,
              title: AppLocalizations.of(context).workoutSettingsMy1rms,
              subtitle: AppLocalizations.of(context).workoutSettingsViewAndEditYour,
              isMyOneRMsScreen: true,
            ),
            SettingItemData(
              icon: Icons.percent,
              title: AppLocalizations.of(context).workoutSettingsTrainingIntensity,
              subtitle: AppLocalizations.of(context).workoutSettingsWorkAtAPercentage,
              isTrainingIntensitySelector: true,
            ),
            SettingItemData(
              icon: Icons.trending_up,
              title: AppLocalizations.of(context).workoutSettingsProgressionPace,
              subtitle: AppLocalizations.of(context).workoutSettingsHowFastToIncrease,
              isProgressionPaceSelector: true,
            ),
            SettingItemData(
              icon: Icons.fitness_center,
              title: AppLocalizations.of(context).workoutSettingsWorkoutType,
              subtitle: AppLocalizations.of(context).workoutSettingsStrengthCardioOrMixed,
              isWorkoutTypeSelector: true,
            ),
            SettingItemData(
              icon: Icons.view_week,
              title: AppLocalizations.of(context).workoutSettingsTrainingSplit,
              subtitle: AppLocalizations.of(context).workoutSettingsPushPullLegsFull,
              isTrainingSplitSelector: true,
            ),
            SettingItemData(
              icon: Icons.calendar_month,
              title: AppLocalizations.of(context).workoutSettingsWorkoutDays,
              subtitle: AppLocalizations.of(context).workoutSettingsWhichDaysYouTrain,
              isWorkoutDaysSelector: true,
            ),
            SettingItemData(
              icon: Icons.calendar_today_outlined,
              title: AppLocalizations.of(context).workoutPreferencesCardWeekStartsOn,
              subtitle: AppLocalizations.of(context).trainingPreferencesFirstDayOfThe,
              isWeekStartSelector: true,
            ),
            SettingItemData(
              icon: Icons.shuffle,
              title: AppLocalizations.of(context).trainingPreferencesExerciseConsistency,
              subtitle: AppLocalizations.of(context).trainingPreferencesVaryOrKeepSame,
              isConsistencyModeSelector: true,
            ),
            SettingItemData(
              icon: Icons.tune,
              title: AppLocalizations.of(context).workoutSettingsWeeklyVariety,
              subtitle: AppLocalizations.of(context).workoutSettingsHowMuchExercisesChange,
              isVariationSlider: true,
            ),
            SettingItemData(
              icon: Icons.favorite,
              title: AppLocalizations.of(context).trainingPreferencesFavoriteExercises,
              subtitle: AppLocalizations.of(context).trainingPreferencesBoostedInSelectionCan,
              isFavoriteExercisesManager: true,
            ),
            SettingItemData(
              icon: Icons.lock,
              title: AppLocalizations.of(context).trainingPreferencesStapleExercises,
              subtitle: AppLocalizations.of(context).trainingPreferencesGuaranteedNeverRotateOut,
              isStapleExercisesManager: true,
            ),
            SettingItemData(
              icon: Icons.queue,
              title: AppLocalizations.of(context).trainingPreferencesExerciseQueue,
              subtitle: AppLocalizations.of(context).trainingPreferencesQueueExercisesForNext,
              isExerciseQueueManager: true,
            ),
            SettingItemData(
              icon: Icons.block,
              title: AppLocalizations.of(context).trainingPreferencesExercisesToAvoid,
              subtitle: AppLocalizations.of(context).trainingPreferencesSkipSpecificExercises,
              isAvoidedExercisesManager: true,
            ),
            SettingItemData(
              icon: Icons.accessibility_new,
              title: AppLocalizations.of(context).trainingPreferencesMusclesToAvoid,
              subtitle: AppLocalizations.of(context).trainingPreferencesSkipOrReduceMuscle,
              isAvoidedMusclesManager: true,
            ),
            SettingItemData(
              icon: Icons.block,
              title: 'Excluded Muscles',
              subtitle: 'Muscle groups the AI never trains',
              onTap: () => Navigator.push(
                context,
                AppPageRoute(
                  builder: (_) => const ExcludedMusclesScreen(),
                ),
              ),
            ),
            SettingItemData(
              icon: Icons.history,
              title: AppLocalizations.of(context).workoutSettingsImportWorkoutHistory,
              subtitle: AppLocalizations.of(context).workoutSettingsAddPastWorkoutsFor,
              isWorkoutHistoryImport: true,
            ),
            SettingItemData(
              icon: Icons.show_chart,
              title: AppLocalizations.of(context).workoutSettingsProgressCharts,
              subtitle: AppLocalizations.of(context).workoutSettingsVisualizeStrengthVolumeOv,
              isProgressChartsScreen: true,
            ),
            SettingItemData(
              icon: Icons.location_on,
              title: AppLocalizations.of(context).trainingPreferencesWorkoutEnvironment,
              subtitle: AppLocalizations.of(context).trainingPreferencesWhereYouTrain,
              isWorkoutEnvironmentSelector: true,
            ),
            SettingItemData(
              icon: Icons.build,
              title: AppLocalizations.of(context).trainingPreferencesMyEquipment,
              subtitle: AppLocalizations.of(context).trainingPreferencesEquipmentAvailableForWorkou,
              isEquipmentSelector: true,
            ),
          ],
        ),
      ],
    );
  }
}
