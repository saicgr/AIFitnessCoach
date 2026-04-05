import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise_progression.dart';
import '../../../data/providers/exercise_progression_provider.dart';
import '../widgets/section_header.dart';
import '../widgets/setting_tile.dart';
import '../../../widgets/glass_sheet.dart';

part 'rep_preferences_section_part_training_focus_option_tile.dart';


/// Settings section for rep range and progression preferences.
///
/// Allows users to configure:
/// - Training focus (Strength/Hypertrophy/Endurance/Power)
/// - Preferred rep range (min-max slider)
/// - Avoid high rep sets toggle
/// - Progression style (Leverage First/Load First/Balanced)
class RepPreferencesSection extends ConsumerWidget {
  const RepPreferencesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final repPrefs = ref.watch(repPreferencesProvider);
    final isLoading = ref.watch(exerciseProgressionLoadingProvider);

    // Use defaults if not loaded
    final prefs = repPrefs ?? UserRepPreferences.defaultFor('');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Rep & Progression Preferences',
          helpTitle: 'Rep & Progression Preferences',
          helpItems: [
            {
              'icon': Icons.fitness_center,
              'title': 'Training Focus',
              'description':
                  'Choose your primary training goal. This affects the rep ranges suggested for your workouts.',
              'color': AppColors.cyan,
            },
            {
              'icon': Icons.repeat,
              'title': 'Rep Range',
              'description':
                  'Set your preferred minimum and maximum reps per set. The AI will try to keep exercises within this range.',
              'color': AppColors.purple,
            },
            {
              'icon': Icons.format_list_numbered,
              'title': 'Sets Per Exercise',
              'description':
                  'Configure how many sets you want per exercise. Min sets ensures adequate volume, max sets prevents overtraining.',
              'color': AppColors.coral,
            },
            {
              'icon': Icons.vertical_align_top,
              'title': 'Enforce Rep Ceiling',
              'description':
                  'When enabled, the AI will strictly enforce your maximum rep limit and never exceed it.',
              'color': AppColors.orange,
            },
            {
              'icon': Icons.trending_up,
              'title': 'Progression Style',
              'description':
                  'Leverage First: Master harder positions before adding weight. Load First: Add weight before changing exercises. Balanced: Let AI decide.',
              'color': AppColors.green,
            },
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Training Focus
              _buildTrainingFocusTile(context, ref, prefs, textMuted, isLoading),
              Divider(height: 1, color: cardBorder, indent: 50),

              // Rep Range
              _buildRepRangeTile(context, ref, prefs, textMuted, isLoading),
              Divider(height: 1, color: cardBorder, indent: 50),

              // Sets Range
              _buildSetsRangeTile(context, ref, prefs, textMuted, isLoading),
              Divider(height: 1, color: cardBorder, indent: 50),

              // Avoid High Reps
              _buildAvoidHighRepsTile(context, ref, prefs, textMuted, isLoading),
              Divider(height: 1, color: cardBorder, indent: 50),

              // Enforce Rep Ceiling
              _buildEnforceRepCeilingTile(context, ref, prefs, textMuted, isLoading),
              Divider(height: 1, color: cardBorder, indent: 50),

              // Progression Style
              _buildProgressionStyleTile(context, ref, prefs, textMuted, isLoading),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Workout Summary
        _buildWorkoutSummary(context, prefs),
      ],
    );
  }

  Widget _buildSetsRangeTile(
    BuildContext context,
    WidgetRef ref,
    UserRepPreferences prefs,
    Color textMuted,
    bool isLoading,
  ) {
    return SettingTile(
      icon: Icons.format_list_numbered,
      title: 'Sets Per Exercise',
      subtitle: 'Configure your set volume',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            prefs.setsRangeDisplay,
            style: TextStyle(fontSize: 14, color: textMuted),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: textMuted, size: 20),
        ],
      ),
      showChevron: false,
      onTap: () => _showSetsRangeSelector(context, ref, prefs),
    );
  }

  Widget _buildEnforceRepCeilingTile(
    BuildContext context,
    WidgetRef ref,
    UserRepPreferences prefs,
    Color textMuted,
    bool isLoading,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SettingTile(
      icon: Icons.vertical_align_top,
      title: 'Enforce Rep Ceiling',
      subtitle: 'Strictly enforce your maximum rep limit',
      trailing: Switch(
        value: prefs.enforceRepCeiling,
        onChanged: isLoading
            ? null
            : (value) {
                HapticFeedback.selectionClick();
                ref
                    .read(exerciseProgressionProvider.notifier)
                    .setEnforceRepCeiling(value);
              },
        activeThumbColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
      ),
      showChevron: false,
    );
  }

  Widget _buildWorkoutSummary(BuildContext context, UserRepPreferences prefs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.cyan : AppColorsLight.cyan).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? AppColors.cyan : AppColorsLight.cyan).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.summarize,
            color: isDark ? AppColors.cyan : AppColorsLight.cyan,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              prefs.workoutSummary,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColorsLight.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingFocusTile(
    BuildContext context,
    WidgetRef ref,
    UserRepPreferences prefs,
    Color textMuted,
    bool isLoading,
  ) {
    return SettingTile(
      icon: Icons.fitness_center,
      title: 'Training Focus',
      subtitle: prefs.trainingFocus.description,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              prefs.trainingFocus.displayName,
              style: TextStyle(fontSize: 14, color: textMuted),
            ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: textMuted, size: 20),
        ],
      ),
      showChevron: false,
      onTap: () => _showTrainingFocusSelector(context, ref, prefs),
    );
  }

  Widget _buildRepRangeTile(
    BuildContext context,
    WidgetRef ref,
    UserRepPreferences prefs,
    Color textMuted,
    bool isLoading,
  ) {
    return SettingTile(
      icon: Icons.repeat,
      title: 'Rep Range',
      subtitle: 'Your preferred reps per set',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            prefs.repRangeDisplay,
            style: TextStyle(fontSize: 14, color: textMuted),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: textMuted, size: 20),
        ],
      ),
      showChevron: false,
      onTap: () => _showRepRangeSelector(context, ref, prefs),
    );
  }

  Widget _buildAvoidHighRepsTile(
    BuildContext context,
    WidgetRef ref,
    UserRepPreferences prefs,
    Color textMuted,
    bool isLoading,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SettingTile(
      icon: Icons.block,
      title: 'Avoid High-Rep Sets',
      subtitle: 'Prevent boring 15+ rep sets',
      trailing: Switch(
        value: prefs.avoidHighReps,
        onChanged: isLoading
            ? null
            : (value) {
                HapticFeedback.selectionClick();
                ref
                    .read(exerciseProgressionProvider.notifier)
                    .setAvoidHighReps(value);
              },
        activeThumbColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
      ),
      showChevron: false,
    );
  }

  Widget _buildProgressionStyleTile(
    BuildContext context,
    WidgetRef ref,
    UserRepPreferences prefs,
    Color textMuted,
    bool isLoading,
  ) {
    return SettingTile(
      icon: Icons.trending_up,
      title: 'Progression Style',
      subtitle: prefs.progressionStyle.description,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            prefs.progressionStyle.displayName,
            style: TextStyle(fontSize: 14, color: textMuted),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: textMuted, size: 20),
        ],
      ),
      showChevron: false,
      onTap: () => _showProgressionStyleSelector(context, ref, prefs),
    );
  }

  void _showTrainingFocusSelector(
    BuildContext context,
    WidgetRef ref,
    UserRepPreferences prefs,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Training Focus',
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
                  'Choose your primary training goal',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...TrainingFocus.values.map(
                (focus) => _TrainingFocusOptionTile(
                  focus: focus,
                  isSelected: focus == prefs.trainingFocus,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(exerciseProgressionProvider.notifier)
                        .setTrainingFocus(focus);
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showRepRangeSelector(
    BuildContext context,
    WidgetRef ref,
    UserRepPreferences prefs,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: _RepRangeSliderSheet(
          initialMin: prefs.preferredMinReps,
          initialMax: prefs.preferredMaxReps,
          onSave: (min, max) {
            ref
                .read(exerciseProgressionProvider.notifier)
                .setRepRange(min, max);
          },
        ),
      ),
    );
  }

  void _showProgressionStyleSelector(
    BuildContext context,
    WidgetRef ref,
    UserRepPreferences prefs,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Progression Style',
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
                  'How should we progress your exercises?',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...ProgressionStyle.values.map(
                (style) => _ProgressionStyleOptionTile(
                  style: style,
                  isSelected: style == prefs.progressionStyle,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(exerciseProgressionProvider.notifier)
                        .setProgressionStyle(style);
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showSetsRangeSelector(
    BuildContext context,
    WidgetRef ref,
    UserRepPreferences prefs,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: _SetsRangeSliderSheet(
          initialMin: prefs.minSetsPerExercise,
          initialMax: prefs.maxSetsPerExercise,
          onSave: (min, max) {
            ref
                .read(exerciseProgressionProvider.notifier)
                .setSetsRange(min, max);
          },
        ),
      ),
    );
  }
}
