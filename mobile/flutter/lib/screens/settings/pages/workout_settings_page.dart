import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/glass_back_button.dart';
import '../widgets/widgets.dart';

/// Sub-page for Workout Settings + Exercise Preferences.
class WorkoutSettingsPage extends ConsumerWidget {
  const WorkoutSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: Text(
          'Workout Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Workout Settings ──
              SectionHeader(
                title: 'WORKOUT SETTINGS',
                subtitle: 'Configure progression and scheduling',
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
                    icon: Icons.show_chart,
                    title: 'Progress Charts',
                    subtitle: 'Visualize strength & volume over time',
                    isProgressChartsScreen: true,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Exercise Preferences ──
              SectionHeader(
                title: 'EXERCISE PREFERENCES',
                subtitle: 'Customize which exercises appear in workouts',
              ),
              const SizedBox(height: 12),
              SettingsCard(
                items: [
                  SettingItemData(
                    icon: Icons.fitness_center,
                    title: 'My Exercises',
                    subtitle: 'Favorites, avoided, and queue',
                    onTap: () =>
                        GoRouter.of(context).push('/settings/my-exercises'),
                  ),
                  SettingItemData(
                    icon: Icons.history,
                    title: 'Import Workout History',
                    subtitle: 'Add past workouts for better AI weights',
                    isWorkoutHistoryImport: true,
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
