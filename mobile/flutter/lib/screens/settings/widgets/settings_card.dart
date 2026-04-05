import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/animations/app_animations.dart';
import 'inline_theme_selector.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/consistency_mode_provider.dart';
import '../../../core/providers/environment_equipment_provider.dart';
import '../../../core/providers/exercise_queue_provider.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/providers/staples_provider.dart';
import '../../../core/providers/avoided_provider.dart';
import '../../../core/providers/timezone_provider.dart';
import '../../../core/providers/training_preferences_provider.dart';
import '../../../core/providers/variation_provider.dart';
import '../../../core/providers/training_intensity_provider.dart';
import '../../../core/providers/video_cache_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/providers/week_start_provider.dart';
import '../../../core/providers/weight_increments_provider.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../widgets/weight_increments_sheet.dart';
import '../../../data/models/ai_split_preset.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../library/components/ai_split_preset_detail_sheet.dart';
import '../../library/widgets/compact_split_card.dart';
import '../../../core/providers/user_provider.dart';
import '../equipment/environment_list_screen.dart';
import '../offline/downloaded_videos_screen.dart';
import 'setting_tile.dart';
import '../../../widgets/glass_sheet.dart';

part 'settings_card_part_accent_color_grid.dart';
part 'settings_card_part_workout_days_selector_sheet_state.dart';

part 'settings_card_ui.dart';


/// A card container for grouping related settings items.
///
/// Handles theme toggles and provides consistent styling for settings groups.
class SettingsCard extends ConsumerWidget {
  /// The list of setting items to display.
  final List<SettingItemData> items;

  const SettingsCard({
    super.key,
    required this.items,
  });

  void _navigateToEnvironmentScreen(BuildContext context) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (context) => const EnvironmentListScreen(),
      ),
    );
  }

  void _showEquipmentSelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentEquipment = ref.read(environmentEquipmentProvider).equipment;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: _EquipmentSelectorSheet(
        initialEquipment: currentEquipment,
        onSave: (equipment) {
          ref.read(environmentEquipmentProvider.notifier).setEquipment(equipment);
        },
      ),
      ),
    );
  }

  void _navigateToFavoriteExercises(BuildContext context) {
    context.push('/settings/my-exercises?tab=0');
  }

  void _navigateToExerciseQueue(BuildContext context) {
    context.push('/settings/my-exercises?tab=2');
  }

  void _navigateToWorkoutHistoryImport(BuildContext context) {
    context.push('/settings/workout-history-import');
  }

  void _navigateToStapleExercises(BuildContext context) {
    context.push('/settings/my-exercises?tab=0');
  }

  void _showVariationSlider(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPercentage = ref.read(variationProvider).percentage;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Weekly Variety', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColorsLight.textPrimary)),
                const SizedBox(height: 8),
                Text('How much exercise variety each week?', style: TextStyle(fontSize: 14, color: isDark ? AppColors.textMuted : AppColorsLight.textMuted)),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _varietyChip('Low', 25, currentPercentage, context, ref),
                    _varietyChip('Medium', 50, currentPercentage, context, ref),
                    _varietyChip('High', 75, currentPercentage, context, ref),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _varietyChip(String label, int value, int current, BuildContext context, WidgetRef ref) {
    final presets = [25, 50, 75];
    final closestPreset = presets.reduce((a, b) => (a - current).abs() < (b - current).abs() ? a : b);
    final isSelected = value == closestPreset;
    return ChoiceChip(
      label: Text('$label ($value%)'),
      selected: isSelected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        ref.read(variationProvider.notifier).setVariation(value);
        Navigator.pop(context);
      },
      selectedColor: AppColors.cyan.withValues(alpha: 0.2),
      checkmarkColor: AppColors.cyan,
    );
  }

  void _navigateToMyOneRMs(BuildContext context) {
    context.push('/settings/my-1rms');
  }

  void _navigateToCustomExercises(BuildContext context) {
    context.push('/custom-exercises');
  }

  void _navigateToAvoidedExercises(BuildContext context) {
    context.push('/settings/my-exercises?tab=1');
  }

  void _navigateToAvoidedMuscles(BuildContext context) {
    context.push('/settings/my-exercises?tab=1');
  }

  void _navigateToDownloadedVideos(BuildContext context) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (context) => const DownloadedVideosScreen(),
      ),
    );
  }

  void _navigateToProgressCharts(BuildContext context) {
    context.push('/progress-charts');
  }

  Widget _intensityChip(String label, int value, int current, BuildContext context, WidgetRef ref) {
    final presets = [60, 70, 80, 90];
    final closestPreset = presets.reduce((a, b) => (a - current).abs() < (b - current).abs() ? a : b);
    final isSelected = value == closestPreset;
    return ChoiceChip(
      label: Text('$label ($value%)'),
      selected: isSelected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        ref.read(trainingIntensityProvider.notifier).setGlobalIntensity(value);
        Navigator.pop(context);
      },
      selectedColor: AppColors.cyan.withValues(alpha: 0.2),
      checkmarkColor: AppColors.cyan,
    );
  }

  Future<void> _updateWeightUnit(BuildContext context, WidgetRef ref, String unit) async {
    try {
      await ref.read(authStateProvider.notifier).updateUserProfile({'weight_unit': unit});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Body weight unit → ${unit == 'kg' ? 'kilograms' : 'pounds'}'),
            backgroundColor: AppColors.cyan,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Failed to update'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _updateWorkoutWeightUnit(BuildContext context, WidgetRef ref, String unit) async {
    try {
      await ref.read(authStateProvider.notifier).updateUserProfile({'workout_weight_unit': unit});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workout weight unit → ${unit == 'kg' ? 'kilograms' : 'pounds'}'),
            backgroundColor: AppColors.cyan,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Failed to update'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showWorkoutDaysSelector(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authStateProvider);
    final user = authState.user;
    final currentDays = user?.workoutDays ?? [];

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: _WorkoutDaysSelectorSheet(
        initialDays: currentDays,
        userId: user?.id ?? '',
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final timezoneState = ref.watch(timezoneProvider);
    final trainingPrefs = ref.watch(trainingPreferencesProvider);
    final envEquipState = ref.watch(environmentEquipmentProvider);
    final consistencyModeState = ref.watch(consistencyModeProvider);
    final favoritesState = ref.watch(favoritesProvider);
    final queueState = ref.watch(exerciseQueueProvider);
    final staplesState = ref.watch(staplesProvider);
    final avoidedState = ref.watch(avoidedProvider);
    final variationState = ref.watch(variationProvider);
    final intensityState = ref.watch(trainingIntensityProvider);
    final oneRMsState = ref.watch(userOneRMsProvider);
    final videoCacheState = ref.watch(videoCacheProvider);
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDarkModeActive = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final isFollowingSystem = themeMode == ThemeMode.system;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          Widget? trailing;
          VoidCallback? onTap = item.onTap;

          if (item.isThemeSelector) {
            // Inline theme selector buttons for better UX - one tap to change
            trailing = InlineThemeSelector(
              currentMode: themeMode,
              onChanged: (mode) {
                HapticFeedback.selectionClick();
                ref.read(themeModeProvider.notifier).setTheme(mode);
              },
            );
            onTap = null; // Disable row tap since buttons handle selection
          } else if (item.isTimezoneSelector) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timezoneState.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _showTimezoneSelector(context, ref);
          } else if (item.isFollowSystemToggle) {
            trailing = Switch(
              value: isFollowingSystem,
              onChanged: (value) {
                if (value) {
                  ref.read(themeModeProvider.notifier).setTheme(ThemeMode.system);
                } else {
                  ref.read(themeModeProvider.notifier).setTheme(
                    isDark ? ThemeMode.dark : ThemeMode.light,
                  );
                }
              },
              activeThumbColor: AppColors.cyan,
            );
          } else if (item.isThemeToggle) {
            trailing = Switch(
              value: isDarkModeActive,
              onChanged: isFollowingSystem
                  ? null
                  : (value) {
                      ref.read(themeModeProvider.notifier).setTheme(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
              activeThumbColor: AppColors.cyan,
            );
          } else if (item.isProgressionPaceSelector) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trainingPrefs.progressionPace.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _showProgressionPaceSelector(context, ref);
          } else if (item.isWorkoutTypeSelector) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trainingPrefs.workoutType.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _showWorkoutTypeSelector(context, ref);
          } else if (item.isWorkoutEnvironmentSelector) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  envEquipState.environment.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            // Navigate to full environment screen instead of bottom sheet
            onTap = () => _navigateToEnvironmentScreen(context);
          } else if (item.isEquipmentSelector) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  envEquipState.equipmentCountDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _showEquipmentSelector(context, ref);
          } else if (item.isConsistencyModeSelector) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  consistencyModeState.mode.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _showConsistencyModeSelector(context, ref);
          } else if (item.isTrainingSplitSelector) {
            // Get display name for training split
            final splitDisplayNames = {
              'full_body': 'Full Body',
              'upper_lower': 'Upper/Lower',
              'push_pull_legs': 'Push/Pull/Legs',
              'body_part': 'Body Part Split',
              'phul': 'PHUL',
              'arnold_split': 'Arnold Split',
              'hyrox': 'HYROX',
              'dont_know': 'AI Decides',
            };
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  splitDisplayNames[trainingPrefs.trainingSplit] ?? trainingPrefs.trainingSplit,
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _showTrainingSplitSelector(context, ref);
          } else if (item.isFavoriteExercisesManager) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${favoritesState.favorites.length} exercises',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _navigateToFavoriteExercises(context);
          } else if (item.isExerciseQueueManager) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${queueState.activeQueue.length} queued',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _navigateToExerciseQueue(context);
          } else if (item.isWorkoutHistoryImport) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _navigateToWorkoutHistoryImport(context);
          } else if (item.isStapleExercisesManager) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${staplesState.staples.length} exercises',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _navigateToStapleExercises(context);
          } else if (item.isVariationSlider) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${variationState.percentage}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _showVariationSlider(context, ref);
          } else if (item.isMyOneRMsScreen) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${oneRMsState.oneRMs.length} lifts',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _navigateToMyOneRMs(context);
          } else if (item.isTrainingIntensitySelector) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${intensityState.globalIntensityPercent}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _showTrainingIntensitySelector(context, ref);
          } else if (item.isCustomExercisesScreen) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _navigateToCustomExercises(context);
          } else if (item.isAvoidedExercisesManager) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${avoidedState.activeAvoided.length} avoided',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _navigateToAvoidedExercises(context);
          } else if (item.isAvoidedMusclesManager) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _navigateToAvoidedMuscles(context);
          } else if (item.isDownloadedVideosManager) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  videoCacheState.cachedVideoCount > 0
                      ? '${videoCacheState.cachedVideoCount} videos'
                      : 'None',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _navigateToDownloadedVideos(context);
          } else if (item.isWorkoutDaysSelector) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentUser?.workoutDaysFormatted ?? 'Not set',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _showWorkoutDaysSelector(context, ref);
          } else if (item.isProgressChartsScreen) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _navigateToProgressCharts(context);
          } else if (item.isWeightUnitSelector) {
            final bodyUnit = ref.watch(weightUnitProvider);
            final workoutUnit = ref.watch(workoutWeightUnitProvider);
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Body ${bodyUnit.toUpperCase()} · Workout ${workoutUnit.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _showWeightUnitSelector(context, ref);
          } else if (item.isAccentColorSelector) {
            // Show current accent color preview and open full grid on tap
            final accentColor = ref.watch(accentColorProvider);
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: accentColor.previewColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor == AccentColor.black
                          ? (isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3))
                          : Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  accentColor.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => _showAccentColorPicker(context, ref);
          } else if (item.isWeightIncrementsSelector) {
            final weightIncrementsState = ref.watch(weightIncrementsProvider);
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  weightIncrementsState.unit.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () => showWeightIncrementsSheet(context);
          } else if (item.isWeekStartSelector) {
            final startsSunday = ref.watch(weekStartsSundayProvider);
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  startsSunday ? 'Sunday' : 'Monday',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: textMuted,
                  size: 20,
                ),
              ],
            );
            onTap = () {
              HapticFeedback.lightImpact();
              ref.read(weekStartsSundayProvider.notifier).toggle();
            };
          } else if (item.isDailyXPStripToggle) {
            final isEnabled = ref.watch(dailyXPStripEnabledProvider);
            final accentEnum = ref.watch(accentColorProvider);
            final switchColor = accentEnum.getColor(isDark);
            trailing = Switch.adaptive(
              value: isEnabled,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                ref.read(dailyXPStripEnabledProvider.notifier).setEnabled(value);
              },
              activeTrackColor: switchColor.withValues(alpha: 0.5),
              activeThumbColor: switchColor,
            );
            onTap = () {
              HapticFeedback.lightImpact();
              ref.read(dailyXPStripEnabledProvider.notifier).toggle();
            };
          } else {
            trailing = item.trailing;
          }

          return Column(
            children: [
              SettingTile(
                icon: item.icon,
                title: item.title,
                subtitle: item.subtitle,
                onTap: onTap,
                trailing: trailing,
                iconColor: item.iconColor,
                showChevron: !item.isThemeToggle &&
                    !item.isFollowSystemToggle &&
                    !item.isThemeSelector &&
                    !item.isTimezoneSelector &&
                    !item.isProgressionPaceSelector &&
                    !item.isWorkoutTypeSelector &&
                    !item.isWorkoutEnvironmentSelector &&
                    !item.isEquipmentSelector &&
                    !item.isConsistencyModeSelector &&
                    !item.isFavoriteExercisesManager &&
                    !item.isExerciseQueueManager &&
                    !item.isWorkoutHistoryImport &&
                    !item.isStapleExercisesManager &&
                    !item.isVariationSlider &&
                    !item.isMyOneRMsScreen &&
                    !item.isTrainingIntensitySelector &&
                    !item.isCustomExercisesScreen &&
                    !item.isAvoidedExercisesManager &&
                    !item.isAvoidedMusclesManager &&
                    !item.isDownloadedVideosManager &&
                    !item.isTrainingSplitSelector &&
                    !item.isWorkoutDaysSelector &&
                    !item.isProgressChartsScreen &&
                    !item.isWeightUnitSelector &&
                    !item.isAccentColorSelector && // Has custom trailing with chevron
                    !item.isWeightIncrementsSelector &&
                    !item.isDailyXPStripToggle &&
                    !item.isWeekStartSelector, // Has custom trailing
                borderRadius: index == 0
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : index == items.length - 1
                        ? const BorderRadius.vertical(bottom: Radius.circular(16))
                        : null,
              ),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  color: cardBorder,
                  indent: 50,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

