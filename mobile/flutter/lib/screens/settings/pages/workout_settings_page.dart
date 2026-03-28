import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/weight_increments_provider.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/pill_app_bar.dart';
import '../../../widgets/weight_increments_sheet.dart';
import '../widgets/widgets.dart';

/// Sub-page for Workout Settings + Exercise Preferences.
class WorkoutSettingsPage extends ConsumerStatefulWidget {
  const WorkoutSettingsPage({super.key});

  @override
  ConsumerState<WorkoutSettingsPage> createState() => _WorkoutSettingsPageState();
}

class _WorkoutSettingsPageState extends ConsumerState<WorkoutSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PillAppBar(
        title: 'Workout Settings',
      ),
      body: SingleChildScrollView(
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
                    iconColor: isDark ? AppColors.orange : AppColorsLight.orange,
                  ),
                  SettingItemData(
                    icon: Icons.percent,
                    title: 'Training Intensity',
                    subtitle: 'Work at a percentage of your max',
                    isTrainingIntensitySelector: true,
                    iconColor: isDark ? AppColors.purple : AppColorsLight.purple,
                  ),
                  SettingItemData(
                    icon: Icons.trending_up,
                    title: 'Progression Pace',
                    subtitle: 'How fast to increase weights',
                    isProgressionPaceSelector: true,
                    iconColor: isDark ? AppColors.green : AppColorsLight.green,
                  ),
                  SettingItemData(
                    icon: Icons.fitness_center,
                    title: 'Workout Type',
                    subtitle: 'Strength, cardio, or mixed',
                    isWorkoutTypeSelector: true,
                    iconColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
                  ),
                  SettingItemData(
                    icon: Icons.view_week,
                    title: 'Training Split',
                    subtitle: 'Push/Pull/Legs, Full Body, etc.',
                    isTrainingSplitSelector: true,
                    iconColor: isDark ? AppColors.waterBlue : AppColorsLight.waterBlue,
                  ),
                  SettingItemData(
                    icon: Icons.calendar_month,
                    title: 'Workout Days',
                    subtitle: 'Which days you train',
                    isWorkoutDaysSelector: true,
                    iconColor: isDark ? AppColors.orange : AppColorsLight.orange,
                  ),
                  SettingItemData(
                    icon: Icons.tune,
                    title: 'Weekly Variety',
                    subtitle: 'How much exercises change each week',
                    isVariationSlider: true,
                    iconColor: isDark ? AppColors.purple : AppColorsLight.purple,
                  ),
                  SettingItemData(
                    icon: Icons.show_chart,
                    title: 'Progress Charts',
                    subtitle: 'Visualize strength & volume over time',
                    isProgressChartsScreen: true,
                    iconColor: isDark ? AppColors.green : AppColorsLight.green,
                  ),
                  SettingItemData(
                    icon: Icons.swap_horiz,
                    title: 'Workout Weight Unit',
                    subtitle: ref.watch(workoutWeightUnitProvider) == 'kg' ? 'Kilograms (kg)' : 'Pounds (lbs)',
                    onTap: () => _showWorkoutWeightUnitSelector(context, ref),
                    iconColor: isDark ? AppColors.orange : AppColorsLight.orange,
                  ),
                  SettingItemData(
                    icon: Icons.tune,
                    title: 'Weight Increments',
                    subtitle: 'Step size: ${ref.watch(weightIncrementsProvider).unit.toUpperCase()} · Tap to customize',
                    onTap: () => showWeightIncrementsSheet(context),
                    iconColor: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
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
                    iconColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
                  ),
                  SettingItemData(
                    icon: Icons.history,
                    title: 'Import Workout History',
                    subtitle: 'Add past workouts for better AI weights',
                    isWorkoutHistoryImport: true,
                    iconColor: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                  ),
                  SettingItemData(
                    icon: Icons.swap_horiz,
                    title: 'Workout Weight Unit',
                    subtitle: ref.watch(workoutWeightUnitProvider) == 'kg' ? 'Kilograms (kg)' : 'Pounds (lbs)',
                    onTap: () => _showWorkoutWeightUnitSelector(context, ref),
                    iconColor: isDark ? AppColors.orange : AppColorsLight.orange,
                  ),
                  SettingItemData(
                    icon: Icons.tune,
                    title: 'Weight Increments',
                    subtitle: 'Step size: ${ref.watch(weightIncrementsProvider).unit.toUpperCase()} · Tap to customize',
                    onTap: () => showWeightIncrementsSheet(context),
                    iconColor: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
    );
  }

  void _showWorkoutWeightUnitSelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUnit = ref.read(workoutWeightUnitProvider);
    final accent = isDark ? AppColors.orange : AppColorsLight.orange;
    final textPrimary = isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Workout Weight Unit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Unit for logging exercise weights during workouts',
                  style: TextStyle(fontSize: 13, color: textMuted),
                ),
              ),
              const SizedBox(height: 16),
              ...[
                {'unit': 'kg', 'label': 'Kilograms (kg)', 'desc': 'Metric system'},
                {'unit': 'lbs', 'label': 'Pounds (lbs)', 'desc': 'Imperial system'},
              ].map((opt) {
                final isSelected = currentUnit == opt['unit'];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: Icon(
                    Icons.fitness_center,
                    color: isSelected ? accent : textMuted,
                  ),
                  title: Text(
                    opt['label']!,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: Text(opt['desc']!, style: TextStyle(fontSize: 12, color: textMuted)),
                  trailing: isSelected ? Icon(Icons.check_circle, color: accent) : null,
                  selected: isSelected,
                  selectedTileColor: accent.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                    try {
                      await ref.read(authStateProvider.notifier).updateUserProfile({
                        'workout_weight_unit': opt['unit'],
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text('Workout weight unit → ${opt['label']}'),
                            backgroundColor: AppColors.cyan,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (_) {}
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
