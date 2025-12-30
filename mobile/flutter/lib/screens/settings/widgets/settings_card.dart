import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/consistency_mode_provider.dart';
import '../../../core/providers/environment_equipment_provider.dart';
import '../../../core/providers/exercise_queue_provider.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/providers/staples_provider.dart';
import '../../../core/providers/timezone_provider.dart';
import '../../../core/providers/training_preferences_provider.dart';
import '../../../core/providers/variation_provider.dart';
import '../../../core/providers/training_intensity_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../equipment/environment_list_screen.dart';
import 'setting_tile.dart';

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

  void _showTimezoneSelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTimezone = ref.read(timezoneProvider).timezone;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Choose Timezone',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColorsLight.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: commonTimezones.length,
                  itemBuilder: (context, index) {
                    final tz = commonTimezones[index];
                    final isSelected = tz.id == currentTimezone;
                    return _TimezoneOptionTile(
                      timezone: tz,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(timezoneProvider.notifier).setTimezone(tz.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProgressionPaceSelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPace = ref.read(trainingPreferencesProvider).progressionPace;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Progression Pace',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'How fast should we increase your weights?',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...ProgressionPace.values.map((pace) => _ProgressionPaceOptionTile(
                  pace: pace,
                  isSelected: pace == currentPace,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(trainingPreferencesProvider.notifier).setProgressionPace(pace);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showWorkoutTypeSelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentType = ref.read(trainingPreferencesProvider).workoutType;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Workout Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'What type of workouts do you prefer?',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...WorkoutType.values.map((type) => _WorkoutTypeOptionTile(
                  type: type,
                  isSelected: type == currentType,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(trainingPreferencesProvider.notifier).setWorkoutType(type);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _navigateToEnvironmentScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EnvironmentListScreen(),
      ),
    );
  }

  void _showEquipmentSelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentEquipment = ref.read(environmentEquipmentProvider).equipment;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => _EquipmentSelectorSheet(
        initialEquipment: currentEquipment,
        onSave: (equipment) {
          ref.read(environmentEquipmentProvider.notifier).setEquipment(equipment);
        },
      ),
    );
  }

  void _showConsistencyModeSelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMode = ref.read(consistencyModeProvider).mode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Exercise Consistency',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'How should the AI select exercises for your workouts?',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...ConsistencyMode.values.map((mode) => _ConsistencyModeOptionTile(
                  mode: mode,
                  isSelected: mode == currentMode,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(consistencyModeProvider.notifier).setMode(mode);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _navigateToFavoriteExercises(BuildContext context) {
    context.push('/settings/favorite-exercises');
  }

  void _navigateToExerciseQueue(BuildContext context) {
    context.push('/settings/exercise-queue');
  }

  void _navigateToWorkoutHistoryImport(BuildContext context) {
    context.push('/settings/workout-history-import');
  }

  void _navigateToStapleExercises(BuildContext context) {
    context.push('/settings/staple-exercises');
  }

  void _showVariationSlider(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPercentage = ref.read(variationProvider).percentage;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _VariationSliderSheet(
        initialValue: currentPercentage,
        onSave: (value) {
          ref.read(variationProvider.notifier).setVariation(value);
        },
      ),
    );
  }

  void _navigateToMyOneRMs(BuildContext context) {
    context.push('/settings/my-1rms');
  }

  void _navigateToCustomExercises(BuildContext context) {
    context.push('/custom-exercises');
  }

  void _navigateToAvoidedExercises(BuildContext context) {
    context.push('/settings/avoided-exercises');
  }

  void _navigateToAvoidedMuscles(BuildContext context) {
    context.push('/settings/avoided-muscles');
  }

  void _showTrainingIntensitySelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIntensity = ref.read(trainingIntensityProvider).globalIntensityPercent;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _TrainingIntensitySheet(
        initialValue: currentIntensity,
        onSave: (value) {
          ref.read(trainingIntensityProvider.notifier).setGlobalIntensity(value);
        },
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
    final variationState = ref.watch(variationProvider);
    final intensityState = ref.watch(trainingIntensityProvider);
    final oneRMsState = ref.watch(userOneRMsProvider);
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
            trailing = _InlineThemeSelector(
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
              activeColor: AppColors.cyan,
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
              activeColor: AppColors.cyan,
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
                    !item.isAvoidedMusclesManager,
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

/// A tile for timezone selection in the bottom sheet.
class _TimezoneOptionTile extends StatelessWidget {
  final TimezoneData timezone;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimezoneOptionTile({
    required this.timezone,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timezone.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isDark ? Colors.white : AppColorsLight.textPrimary,
                    ),
                  ),
                  Text(
                    '${timezone.region} • ${timezone.currentOffset}',
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.cyan,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

/// Inline theme selector with 3 buttons: System, Light, Dark
/// Provides immediate feedback without requiring a bottom sheet
class _InlineThemeSelector extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const _InlineThemeSelector({
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.pureBlack.withValues(alpha: 0.5)
        : AppColorsLight.cardBorder.withValues(alpha: 0.5);
    final selectedColor = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeButton(
            icon: Icons.smartphone_outlined,
            label: 'Auto',
            isSelected: currentMode == ThemeMode.system,
            selectedColor: selectedColor,
            textMuted: textMuted,
            onTap: () => onChanged(ThemeMode.system),
          ),
          _ThemeButton(
            icon: Icons.light_mode_outlined,
            label: 'Light',
            isSelected: currentMode == ThemeMode.light,
            selectedColor: selectedColor,
            textMuted: textMuted,
            onTap: () => onChanged(ThemeMode.light),
          ),
          _ThemeButton(
            icon: Icons.dark_mode_outlined,
            label: 'Dark',
            isSelected: currentMode == ThemeMode.dark,
            selectedColor: selectedColor,
            textMuted: textMuted,
            onTap: () => onChanged(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

/// Individual theme button for the inline selector
class _ThemeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final Color textMuted;
  final VoidCallback onTap;

  const _ThemeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.textMuted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = isSelected
        ? (isDark ? AppColors.elevated : Colors.white)
        : Colors.transparent;
    final iconColor = isSelected ? selectedColor : textMuted;
    final textColor = isSelected
        ? (isDark ? Colors.white : AppColorsLight.textPrimary)
        : textMuted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tile for progression pace selection in the bottom sheet.
class _ProgressionPaceOptionTile extends StatelessWidget {
  final ProgressionPace pace;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProgressionPaceOptionTile({
    required this.pace,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (pace) {
      case ProgressionPace.slow:
        return Icons.slow_motion_video;
      case ProgressionPace.medium:
        return Icons.speed;
      case ProgressionPace.fast:
        return Icons.flash_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.cyan.withValues(alpha: 0.15) : AppColorsLight.cyan.withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.cyan : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _icon,
              color: isSelected ? AppColors.cyan : textMuted,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pace.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isDark ? Colors.white : AppColorsLight.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pace.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pace.bestFor,
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.cyan,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

/// A tile for workout type selection in the bottom sheet.
class _WorkoutTypeOptionTile extends StatelessWidget {
  final WorkoutType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _WorkoutTypeOptionTile({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (type) {
      case WorkoutType.strength:
        return Icons.fitness_center;
      case WorkoutType.cardio:
        return Icons.directions_run;
      case WorkoutType.mixed:
        return Icons.sports_gymnastics;
      case WorkoutType.mobility:
        return Icons.self_improvement;
      case WorkoutType.recovery:
        return Icons.spa;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.cyan.withValues(alpha: 0.15) : AppColorsLight.cyan.withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.cyan : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _icon,
              color: isSelected ? AppColors.cyan : textMuted,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        type.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isDark ? Colors.white : AppColorsLight.textPrimary,
                        ),
                      ),
                      if (type == WorkoutType.mixed) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Recommended',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cyan,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.cyan,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

/// A bottom sheet for selecting equipment.
class _EquipmentSelectorSheet extends StatefulWidget {
  final List<String> initialEquipment;
  final ValueChanged<List<String>> onSave;

  const _EquipmentSelectorSheet({
    required this.initialEquipment,
    required this.onSave,
  });

  @override
  State<_EquipmentSelectorSheet> createState() => _EquipmentSelectorSheetState();
}

class _EquipmentSelectorSheetState extends State<_EquipmentSelectorSheet> {
  late Set<String> _selectedEquipment;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedEquipment = Set.from(widget.initialEquipment);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredEquipment {
    if (_searchQuery.isEmpty) {
      return commonEquipmentOptions;
    }
    return commonEquipmentOptions
        .where((e) => getEquipmentDisplayName(e).toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _toggleEquipment(String equipment) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedEquipment.contains(equipment)) {
        _selectedEquipment.remove(equipment);
      } else {
        _selectedEquipment.add(equipment);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'My Equipment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Select all equipment you have access to',
                style: TextStyle(
                  fontSize: 14,
                  color: textMuted,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search equipment...',
                  prefixIcon: Icon(Icons.search, color: textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: textMuted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.cyan),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.pureBlack.withValues(alpha: 0.3) : Colors.grey[100],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Selected count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedEquipment.length} selected',
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                  if (_selectedEquipment.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _selectedEquipment.clear()),
                      child: Text(
                        'Clear all',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.cyan,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Equipment grid
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredEquipment.length,
                itemBuilder: (context, index) {
                  final equipment = _filteredEquipment[index];
                  final isSelected = _selectedEquipment.contains(equipment);
                  return _EquipmentOptionTile(
                    equipment: equipment,
                    isSelected: isSelected,
                    onTap: () => _toggleEquipment(equipment),
                  );
                },
              ),
            ),
            // Save button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSave(_selectedEquipment.toList());
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Equipment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tile for equipment selection.
class _EquipmentOptionTile extends StatelessWidget {
  final String equipment;
  final bool isSelected;
  final VoidCallback onTap;

  const _EquipmentOptionTile({
    required this.equipment,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.cyan.withValues(alpha: 0.15) : AppColorsLight.cyan.withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.cyan : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: isSelected ? AppColors.cyan : textMuted,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                getEquipmentDisplayName(equipment),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tile for consistency mode selection in the bottom sheet.
class _ConsistencyModeOptionTile extends StatelessWidget {
  final ConsistencyMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConsistencyModeOptionTile({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (mode) {
      case ConsistencyMode.vary:
        return Icons.shuffle;
      case ConsistencyMode.consistent:
        return Icons.repeat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.cyan.withValues(alpha: 0.15) : AppColorsLight.cyan.withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.cyan : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _icon,
              color: isSelected ? AppColors.cyan : textMuted,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        mode.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isDark ? Colors.white : AppColorsLight.textPrimary,
                        ),
                      ),
                      if (mode == ConsistencyMode.consistent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'For Learning',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mode.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.cyan,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

/// A bottom sheet for selecting variation percentage.
class _VariationSliderSheet extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onSave;

  const _VariationSliderSheet({
    required this.initialValue,
    required this.onSave,
  });

  @override
  State<_VariationSliderSheet> createState() => _VariationSliderSheetState();
}

class _VariationSliderSheetState extends State<_VariationSliderSheet> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue.toDouble();
  }

  String _getDescription(int percentage) {
    if (percentage == 0) {
      return 'Same exercises every week';
    } else if (percentage <= 25) {
      return 'Minimal variety - mostly consistent';
    } else if (percentage <= 50) {
      return 'Balanced variety';
    } else if (percentage <= 75) {
      return 'High variety - frequent changes';
    } else {
      return 'Maximum variety - new exercises each week';
    }
  }

  String _getLabel(int percentage) {
    if (percentage <= 20) return 'Consistent';
    if (percentage <= 40) return 'Balanced';
    if (percentage <= 60) return 'Varied';
    if (percentage <= 80) return 'Fresh';
    return 'All New';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final percentage = _value.round();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Weekly Exercise Variety',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How much should exercises change each week?',
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 32),

            // Large percentage display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$percentage',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cyan,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cyan,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              _getLabel(percentage),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.cyan,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getDescription(percentage),
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Slider
            Slider(
              value: _value,
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: AppColors.cyan,
              inactiveColor: AppColors.cyan.withValues(alpha: 0.2),
              onChanged: (value) {
                HapticFeedback.selectionClick();
                setState(() => _value = value);
              },
            ),

            // Labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Consistent',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                  Text(
                    'Fresh',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.cyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.cyan,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Staple exercises are never affected by this setting.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : AppColorsLight.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSave(percentage);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A bottom sheet for selecting training intensity percentage.
class _TrainingIntensitySheet extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onSave;

  const _TrainingIntensitySheet({
    required this.initialValue,
    required this.onSave,
  });

  @override
  State<_TrainingIntensitySheet> createState() => _TrainingIntensitySheetState();
}

class _TrainingIntensitySheetState extends State<_TrainingIntensitySheet> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue.toDouble();
  }

  String _getLabel(int percentage) {
    if (percentage <= 60) return 'Light';
    if (percentage <= 70) return 'Moderate';
    if (percentage <= 80) return 'Working';
    if (percentage <= 90) return 'Heavy';
    return 'Max';
  }

  String _getDescription(int percentage) {
    if (percentage <= 60) return 'Recovery / Deload week';
    if (percentage <= 70) return 'Endurance / Volume focus';
    if (percentage <= 80) return 'Hypertrophy / Building muscle';
    if (percentage <= 90) return 'Strength / Power focus';
    return 'Near max / Peaking';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final percentage = _value.round();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Training Intensity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'What percentage of your 1RM do you want to train at?',
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Large percentage display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$percentage',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cyan,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cyan,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              _getLabel(percentage),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.cyan,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getDescription(percentage),
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Slider
            Slider(
              value: _value,
              min: 50,
              max: 100,
              divisions: 10,
              activeColor: AppColors.cyan,
              inactiveColor: AppColors.cyan.withValues(alpha: 0.2),
              onChanged: (value) {
                HapticFeedback.selectionClick();
                setState(() => _value = value);
              },
            ),

            // Labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '50%',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                  Text(
                    '75%',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                  Text(
                    '100%',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.cyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.cyan,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This applies to exercises where you have logged a 1RM.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : AppColorsLight.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSave(percentage);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
