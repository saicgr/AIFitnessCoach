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
import '../../../core/providers/avoided_provider.dart';
import '../../../core/providers/timezone_provider.dart';
import '../../../core/providers/training_preferences_provider.dart';
import '../../../core/providers/variation_provider.dart';
import '../../../core/providers/training_intensity_provider.dart';
import '../../../core/providers/video_cache_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/providers/weight_increments_provider.dart';
import '../../../data/providers/daily_xp_strip_provider.dart';
import '../../../widgets/weight_increments_sheet.dart';
import '../../../widgets/schedule_mismatch_dialog.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../core/providers/user_provider.dart';
import '../equipment/environment_list_screen.dart';
import '../offline/downloaded_videos_screen.dart';
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
      useRootNavigator: true,
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
      useRootNavigator: true,
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
      useRootNavigator: true,
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

  // Split info with required days for schedule mismatch validation
  static const _splitInfo = {
    'full_body': (name: 'Full Body', days: 3, desc: '3 days • All muscle groups each workout', icon: Icons.accessibility_new),
    'full_body_minimal': (name: 'Full Body (2-Day)', days: 2, desc: '2 days • For busy schedules', icon: Icons.accessibility_new),
    'upper_lower': (name: 'Upper/Lower', days: 4, desc: '4 days • Alternating upper and lower body', icon: Icons.swap_vert),
    'push_pull_legs': (name: 'Push/Pull/Legs', days: 3, desc: '3 days • Classic PPL split', icon: Icons.fitness_center),
    'ppl_6day': (name: 'PPL (6-Day)', days: 6, desc: '6 days • Maximum hypertrophy', icon: Icons.fitness_center),
    'body_part': (name: 'Bro Split', days: 5, desc: '5 days • One muscle group per day', icon: Icons.person),
    'phul': (name: 'PHUL', days: 4, desc: '4 days • Power Hypertrophy Upper Lower', icon: Icons.bolt),
    'pplul': (name: 'PPLUL', days: 5, desc: '5 days • Push/Pull/Legs + Upper/Lower hybrid', icon: Icons.auto_graph),
    'arnold_split': (name: 'Arnold Split', days: 6, desc: '6 days • Chest/Back, Shoulders/Arms, Legs', icon: Icons.military_tech),
    'hyrox': (name: 'HYROX', days: 4, desc: '4 days • Hybrid running + functional', icon: Icons.directions_run),
    'ai_adaptive': (name: 'AI Adaptive', days: 0, desc: 'AI adjusts based on your recovery', icon: Icons.auto_awesome),
    'dont_know': (name: 'Let AI Decide', days: 0, desc: 'Auto-select based on your schedule', icon: Icons.auto_awesome),
  };

  void _showTrainingSplitSelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trainingPrefs = ref.read(trainingPreferencesProvider);
    final currentSplit = trainingPrefs.trainingSplit;
    final authState = ref.read(authStateProvider);
    final currentWorkoutDays = authState.user?.workoutDays ?? [];

    // Splits to show in the selector
    final splits = [
      'full_body',
      'upper_lower',
      'push_pull_legs',
      'pplul',
      'phul',
      'arnold_split',
      'body_part',
      'hyrox',
      'dont_know',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      useRootNavigator: true,
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
                  'Training Split',
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
                  'Choose how to structure your weekly workouts',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: splits.length,
                  itemBuilder: (context, index) {
                    final splitKey = splits[index];
                    final splitData = _splitInfo[splitKey];
                    if (splitData == null) return const SizedBox.shrink();

                    final isSelected = splitKey == currentSplit;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: isSelected
                            ? (isDark ? AppColors.cyan.withOpacity(0.15) : AppColorsLight.cyan.withOpacity(0.15))
                            : (isDark ? AppColors.elevated : AppColorsLight.elevated),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => _handleSplitSelection(
                            context,
                            ref,
                            splitKey,
                            splitData.name,
                            splitData.days,
                            currentWorkoutDays,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark ? AppColors.cyan : AppColorsLight.cyan)
                                        : (isDark ? AppColors.elevated : AppColorsLight.elevated),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    splitData.icon,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        splitData.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : AppColorsLight.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        splitData.desc,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  /// Handle split selection with schedule mismatch validation
  void _handleSplitSelection(
    BuildContext context,
    WidgetRef ref,
    String splitKey,
    String splitName,
    int requiredDays,
    List<int> currentWorkoutDays,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // If split is flexible (AI modes) or days match, just save directly
    if (requiredDays == 0 || currentWorkoutDays.length == requiredDays) {
      _saveSplitAndClose(context, ref, splitKey, splitName, isDark);
      return;
    }

    // Schedule mismatch - show choice dialog
    Navigator.pop(context); // Close the split selector
    _showScheduleMismatchDialog(
      context,
      ref,
      splitKey,
      splitName,
      requiredDays,
      currentWorkoutDays,
    );
  }

  /// Show dialog when workout days don't match split requirements
  void _showScheduleMismatchDialog(
    BuildContext context,
    WidgetRef ref,
    String splitKey,
    String splitName,
    int requiredDays,
    List<int> currentWorkoutDays,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentDayNames = ScheduleMismatchHelper.formatDayNames(currentWorkoutDays);
    final newDays = ScheduleMismatchHelper.getDefaultDaysForCount(requiredDays);
    final newDayNames = ScheduleMismatchHelper.formatDayNames(newDays);
    final compatibleSplit = ScheduleMismatchHelper.getCompatibleSplitForDays(currentWorkoutDays.length);
    final compatibleSplitName = _splitInfo[compatibleSplit]?.name ?? 'Full Body';

    showDialog(
      context: context,
      builder: (dialogContext) => ScheduleMismatchDialog(
        splitName: splitName,
        requiredDays: requiredDays,
        currentDayCount: currentWorkoutDays.length,
        currentDayNames: currentDayNames,
        newDays: newDays,
        newDayNames: newDayNames,
        compatibleSplitName: compatibleSplitName,
        onKeepDays: () {
          Navigator.pop(dialogContext);
          // Save the compatible split for current days
          _saveSplitDirectly(context, ref, compatibleSplit, compatibleSplitName, isDark);
        },
        onUpdateDays: () async {
          Navigator.pop(dialogContext);
          // Save the selected split AND update workout days
          await _saveSplitAndUpdateDays(context, ref, splitKey, splitName, newDays, isDark);
        },
      ),
    );
  }

  /// Save split without closing bottom sheet (already closed)
  void _saveSplitDirectly(
    BuildContext context,
    WidgetRef ref,
    String splitKey,
    String splitName,
    bool isDark,
  ) {
    HapticFeedback.selectionClick();
    ref.read(trainingPreferencesProvider.notifier).setTrainingSplit(splitKey);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Training split updated to $splitName. Regenerate workouts to apply.'),
        backgroundColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Save split and close the bottom sheet
  void _saveSplitAndClose(
    BuildContext context,
    WidgetRef ref,
    String splitKey,
    String splitName,
    bool isDark,
  ) {
    Navigator.pop(context);
    _saveSplitDirectly(context, ref, splitKey, splitName, isDark);
  }

  /// Save split and update workout days
  Future<void> _saveSplitAndUpdateDays(
    BuildContext context,
    WidgetRef ref,
    String splitKey,
    String splitName,
    List<int> newDays,
    bool isDark,
  ) async {
    HapticFeedback.selectionClick();

    try {
      // Update the training split
      ref.read(trainingPreferencesProvider.notifier).setTrainingSplit(splitKey);

      // Update workout days via API
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId != null) {
        final repo = ref.read(workoutRepositoryProvider);
        final dayNamesList = newDays.map((idx) {
          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          return days[idx];
        }).toList();

        await repo.quickDayChange(userId, dayNamesList);
        await ref.read(authStateProvider.notifier).refreshUser();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated to $splitName with ${newDays.length}-day schedule. Regenerate workouts to apply.'),
            backgroundColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
      useRootNavigator: true,
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
      useRootNavigator: true,
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
      useRootNavigator: true,
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

  void _navigateToDownloadedVideos(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DownloadedVideosScreen(),
      ),
    );
  }

  void _navigateToProgressCharts(BuildContext context) {
    context.push('/progress-charts');
  }

  void _showTrainingIntensitySelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIntensity = ref.read(trainingIntensityProvider).globalIntensityPercent;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      useRootNavigator: true,
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

  void _showWeightUnitSelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUnit = ref.read(weightUnitProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      useRootNavigator: true,
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
                'Weight Unit',
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
                'Choose your preferred unit for displaying weights',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _WeightUnitOptionTile(
              unit: 'kg',
              displayName: 'Kilograms (kg)',
              description: 'Metric system • Used in most countries',
              icon: Icons.straighten,
              isSelected: currentUnit == 'kg',
              onTap: () async {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                await _updateWeightUnit(context, ref, 'kg');
              },
            ),
            _WeightUnitOptionTile(
              unit: 'lbs',
              displayName: 'Pounds (lbs)',
              description: 'Imperial system • Used in USA & UK',
              icon: Icons.fitness_center,
              isSelected: currentUnit == 'lbs',
              onTap: () async {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                await _updateWeightUnit(context, ref, 'lbs');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _updateWeightUnit(BuildContext context, WidgetRef ref, String unit) async {
    try {
      // Update user profile via API
      await ref.read(authStateProvider.notifier).updateUserProfile({'weight_unit': unit});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Weight unit changed to ${unit == 'kg' ? 'kilograms' : 'pounds'}'),
            backgroundColor: AppColors.cyan,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update weight unit'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAccentColorPicker(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentAccent = ref.read(accentColorProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      useRootNavigator: true,
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
                'Accent Color',
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
                'Choose an accent color for buttons and highlights',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Color Palette
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AccentColorPalette(
                currentAccent: currentAccent,
                onColorSelected: (accent) {
                  ref.read(accentColorProvider.notifier).setAccent(accent);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showWorkoutDaysSelector(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authStateProvider);
    final user = authState.user;
    final currentDays = user?.workoutDays ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.elevated
          : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => _WorkoutDaysSelectorSheet(
        initialDays: currentDays,
        userId: user?.id ?? '',
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
          } else if (item.isCalibrationTestScreen) {
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
            onTap = () => context.push('/calibration/intro');
          } else if (item.isWeightUnitSelector) {
            final weightUnit = ref.watch(weightUnitProvider);
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  weightUnit == 'kg' ? 'Kilograms' : 'Pounds',
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
                    !item.isCalibrationTestScreen &&
                    !item.isWeightUnitSelector &&
                    !item.isAccentColorSelector && // Has custom trailing with chevron
                    !item.isWeightIncrementsSelector &&
                    !item.isDailyXPStripToggle, // Toggle has no chevron
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

/// HSV Color Picker with saturation/brightness area and hue slider
class _AccentColorPalette extends StatefulWidget {
  final AccentColor currentAccent;
  final ValueChanged<AccentColor> onColorSelected;

  const _AccentColorPalette({
    required this.currentAccent,
    required this.onColorSelected,
  });

  @override
  State<_AccentColorPalette> createState() => _AccentColorPaletteState();
}

class _AccentColorPaletteState extends State<_AccentColorPalette> {
  late double _hue;        // 0-360
  late double _saturation; // 0-1
  late double _brightness; // 0-1
  late AccentColor? _matchedPreset;

  @override
  void initState() {
    super.initState();
    _initFromAccentColor(widget.currentAccent);
  }

  void _initFromAccentColor(AccentColor accent) {
    final color = accent.previewColor;
    final hsv = HSVColor.fromColor(color);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _brightness = hsv.value;
    _matchedPreset = accent;
  }

  Color get _currentColor => HSVColor.fromAHSV(1.0, _hue, _saturation, _brightness).toColor();

  /// Find the closest AccentColor preset to the current HSV selection
  AccentColor _findClosestPreset() {
    final currentColor = _currentColor;
    AccentColor closest = AccentColor.orange;
    double minDistance = double.infinity;

    for (final accent in AccentColor.values) {
      final presetColor = accent.previewColor;
      // Calculate color distance (simple RGB distance using new API)
      final dr = ((currentColor.r - presetColor.r) * 255).abs();
      final dg = ((currentColor.g - presetColor.g) * 255).abs();
      final db = ((currentColor.b - presetColor.b) * 255).abs();
      final distance = dr + dg + db;

      if (distance < minDistance) {
        minDistance = distance;
        closest = accent;
      }
    }

    return closest;
  }

  void _onColorChanged() {
    final closest = _findClosestPreset();
    setState(() => _matchedPreset = closest);
    widget.onColorSelected(closest);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      children: [
        // Saturation/Brightness picker area
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanStart: (details) => _updateSaturationBrightness(details.localPosition, constraints),
                onPanUpdate: (details) => _updateSaturationBrightness(details.localPosition, constraints),
                onTapDown: (details) => _updateSaturationBrightness(details.localPosition, constraints),
                child: Stack(
                  children: [
                    // Background: saturation/brightness gradient
                    CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _SaturationBrightnessPainter(hue: _hue),
                    ),
                    // Selection indicator (circle)
                    Positioned(
                      left: _saturation * constraints.maxWidth - 12,
                      top: (1 - _brightness) * constraints.maxHeight - 12,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentColor,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Hue slider with preview circle
        Row(
          children: [
            // Color preview circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _currentColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _currentColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Hue slider
            Expanded(
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onPanStart: (details) => _updateHue(details.localPosition.dx, constraints.maxWidth),
                      onPanUpdate: (details) => _updateHue(details.localPosition.dx, constraints.maxWidth),
                      onTapDown: (details) => _updateHue(details.localPosition.dx, constraints.maxWidth),
                      child: Stack(
                        children: [
                          // Hue gradient background
                          CustomPaint(
                            size: Size(constraints.maxWidth, 32),
                            painter: _HueGradientPainter(),
                          ),
                          // Hue indicator
                          Positioned(
                            left: (_hue / 360) * constraints.maxWidth - 8,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Container(
                                width: 16,
                                height: 28,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: HSVColor.fromAHSV(1.0, _hue, 1.0, 1.0).toColor(),
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Matched preset indicator
        if (_matchedPreset != null)
          Text(
            'Matched: ${_matchedPreset!.displayName}',
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
            ),
          ),
      ],
    );
  }

  void _updateSaturationBrightness(Offset position, BoxConstraints constraints) {
    HapticFeedback.selectionClick();
    setState(() {
      _saturation = (position.dx / constraints.maxWidth).clamp(0.0, 1.0);
      _brightness = 1.0 - (position.dy / constraints.maxHeight).clamp(0.0, 1.0);
    });
    _onColorChanged();
  }

  void _updateHue(double x, double width) {
    HapticFeedback.selectionClick();
    setState(() {
      _hue = ((x / width) * 360).clamp(0.0, 360.0);
    });
    _onColorChanged();
  }
}

/// Painter for the saturation/brightness gradient area
class _SaturationBrightnessPainter extends CustomPainter {
  final double hue;

  _SaturationBrightnessPainter({required this.hue});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base color (full saturation, full brightness at the given hue)
    final baseColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();

    // Horizontal gradient: white to base color (saturation)
    final saturationGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.white, baseColor],
    );

    // Vertical gradient: transparent to black (brightness)
    final brightnessGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Colors.black],
    );

    // Draw saturation gradient first
    final satPaint = Paint()..shader = saturationGradient.createShader(rect);
    canvas.drawRect(rect, satPaint);

    // Overlay brightness gradient
    final brightPaint = Paint()..shader = brightnessGradient.createShader(rect);
    canvas.drawRect(rect, brightPaint);
  }

  @override
  bool shouldRepaint(_SaturationBrightnessPainter oldDelegate) {
    return oldDelegate.hue != hue;
  }
}

/// Custom painter for the rainbow hue gradient strip
class _HueGradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Create hue gradient (full spectrum)
    final colors = List.generate(
      13,
      (i) => HSVColor.fromAHSV(1.0, i * 30.0, 1.0, 1.0).toColor(),
    );

    final gradient = LinearGradient(colors: colors);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

/// A bottom sheet for selecting workout days with quick change capability.
class _WorkoutDaysSelectorSheet extends ConsumerStatefulWidget {
  final List<int> initialDays;
  final String userId;

  const _WorkoutDaysSelectorSheet({
    required this.initialDays,
    required this.userId,
  });

  @override
  ConsumerState<_WorkoutDaysSelectorSheet> createState() =>
      _WorkoutDaysSelectorSheetState();
}

class _WorkoutDaysSelectorSheetState
    extends ConsumerState<_WorkoutDaysSelectorSheet> {
  late Set<int> _selectedDays;
  bool _isLoading = false;
  String? _errorMessage;

  static const _days = [
    (label: 'M', full: 'Monday', short: 'Mon', value: 0),
    (label: 'T', full: 'Tuesday', short: 'Tue', value: 1),
    (label: 'W', full: 'Wednesday', short: 'Wed', value: 2),
    (label: 'T', full: 'Thursday', short: 'Thu', value: 3),
    (label: 'F', full: 'Friday', short: 'Fri', value: 4),
    (label: 'S', full: 'Saturday', short: 'Sat', value: 5),
    (label: 'S', full: 'Sunday', short: 'Sun', value: 6),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDays = Set.from(widget.initialDays);
    if (_selectedDays.isEmpty) {
      // Default to Mon, Wed, Fri if no days set
      _selectedDays = {0, 2, 4};
    }
  }

  void _toggleDay(int dayValue) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedDays.contains(dayValue)) {
        // Don't allow removing if only 1 day selected
        if (_selectedDays.length > 1) {
          _selectedDays.remove(dayValue);
        }
      } else {
        _selectedDays.add(dayValue);
      }
      _errorMessage = null;
    });
  }

  Future<void> _saveWorkoutDays() async {
    if (_selectedDays.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one workout day';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(workoutRepositoryProvider);

      // Convert day indices to day names
      final sortedDays = _selectedDays.toList()..sort();
      final dayNamesList = sortedDays
          .map((idx) => _days.firstWhere((d) => d.value == idx).short)
          .toList();

      // Call the quick day change API
      await repo.quickDayChange(widget.userId, dayNamesList);

      // Refresh user data
      await ref.read(authStateProvider.notifier).refreshUser();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workout days updated to ${dayNamesList.join(", ")}'),
            backgroundColor: AppColors.cyan,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update workout days. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final hasChanges =
        !_setEquals(_selectedDays, Set.from(widget.initialDays));

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
              'Workout Days',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select which days you want to work out',
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 24),

            // Day selector grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _days.map((day) {
                final isSelected = _selectedDays.contains(day.value);

                return GestureDetector(
                  onTap: () => _toggleDay(day.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.cyan
                          : (isDark ? AppColors.elevated : AppColorsLight.elevated),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.cyan : cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.cyan.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? Colors.white
                                    : AppColorsLight.textPrimary),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Selected count
            Text(
              '${_selectedDays.length} day${_selectedDays.length != 1 ? 's' : ''} selected',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.cyan,
                fontWeight: FontWeight.w500,
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
                      'Changing days will reschedule your upcoming workouts automatically.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : AppColorsLight.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Error message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.error,
                  ),
                ),
              ),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isLoading || !hasChanges) ? null : _saveWorkoutDays,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.cyan.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        hasChanges ? 'Save Changes' : 'No Changes',
                        style: const TextStyle(
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

  /// Helper to compare sets
  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
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

/// A tile for weight unit selection in the bottom sheet.
class _WeightUnitOptionTile extends StatelessWidget {
  final String unit;
  final String displayName;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _WeightUnitOptionTile({
    required this.unit,
    required this.displayName,
    required this.description,
    required this.icon,
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
              icon,
              color: isSelected ? AppColors.cyan : textMuted,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isDark ? Colors.white : AppColorsLight.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
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
