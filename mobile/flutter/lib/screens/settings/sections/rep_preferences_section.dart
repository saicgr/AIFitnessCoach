import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise_progression.dart';
import '../../../data/providers/exercise_progression_provider.dart';
import '../widgets/section_header.dart';
import '../widgets/setting_tile.dart';

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
    );
  }

  void _showRepRangeSelector(
    BuildContext context,
    WidgetRef ref,
    UserRepPreferences prefs,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RepRangeSliderSheet(
        initialMin: prefs.preferredMinReps,
        initialMax: prefs.preferredMaxReps,
        onSave: (min, max) {
          ref
              .read(exerciseProgressionProvider.notifier)
              .setRepRange(min, max);
        },
      ),
    );
  }

  void _showProgressionStyleSelector(
    BuildContext context,
    WidgetRef ref,
    UserRepPreferences prefs,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
    );
  }

  void _showSetsRangeSelector(
    BuildContext context,
    WidgetRef ref,
    UserRepPreferences prefs,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SetsRangeSliderSheet(
        initialMin: prefs.minSetsPerExercise,
        initialMax: prefs.maxSetsPerExercise,
        onSave: (min, max) {
          ref
              .read(exerciseProgressionProvider.notifier)
              .setSetsRange(min, max);
        },
      ),
    );
  }
}

/// Option tile for training focus selection
class _TrainingFocusOptionTile extends StatelessWidget {
  final TrainingFocus focus;
  final bool isSelected;
  final VoidCallback onTap;

  const _TrainingFocusOptionTile({
    required this.focus,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (focus) {
      case TrainingFocus.strength:
        return Icons.fitness_center;
      case TrainingFocus.hypertrophy:
        return Icons.accessibility_new;
      case TrainingFocus.endurance:
        return Icons.timer;
      case TrainingFocus.power:
        return Icons.bolt;
    }
  }

  Color get _color {
    switch (focus) {
      case TrainingFocus.strength:
        return AppColors.coral;
      case TrainingFocus.hypertrophy:
        return AppColors.purple;
      case TrainingFocus.endurance:
        return AppColors.cyan;
      case TrainingFocus.power:
        return AppColors.orange;
    }
  }

  String get _repRange {
    final range = focus.repRange;
    return '${range.$1}-${range.$2} reps';
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
              ? _color.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _color : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _icon,
                color: _color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        focus.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isDark ? Colors.white : AppColorsLight.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _repRange,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    focus.description,
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
                color: _color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

/// Option tile for progression style selection
class _ProgressionStyleOptionTile extends StatelessWidget {
  final ProgressionStyle style;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProgressionStyleOptionTile({
    required this.style,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (style) {
      case ProgressionStyle.leverageFirst:
        return Icons.swap_vert;
      case ProgressionStyle.loadFirst:
        return Icons.fitness_center;
      case ProgressionStyle.balanced:
        return Icons.auto_awesome;
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
              ? AppColors.cyan.withOpacity(0.15)
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
                        style.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isDark ? Colors.white : AppColorsLight.textPrimary,
                        ),
                      ),
                      if (style == ProgressionStyle.balanced) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withOpacity(0.2),
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
                    style.description,
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

/// Bottom sheet for selecting rep range with dual slider
class _RepRangeSliderSheet extends StatefulWidget {
  final int initialMin;
  final int initialMax;
  final Function(int min, int max) onSave;

  const _RepRangeSliderSheet({
    required this.initialMin,
    required this.initialMax,
    required this.onSave,
  });

  @override
  State<_RepRangeSliderSheet> createState() => _RepRangeSliderSheetState();
}

class _RepRangeSliderSheetState extends State<_RepRangeSliderSheet> {
  late RangeValues _values;

  @override
  void initState() {
    super.initState();
    _values = RangeValues(
      widget.initialMin.toDouble(),
      widget.initialMax.toDouble(),
    );
  }

  String _getDescription(int min, int max) {
    if (max <= 5) {
      return 'Heavy strength focus - maximum muscle tension';
    } else if (min <= 5 && max <= 8) {
      return 'Strength & size - great for beginners';
    } else if (min >= 6 && max <= 12) {
      return 'Hypertrophy zone - optimal for muscle growth';
    } else if (min >= 10 && max <= 15) {
      return 'Muscle endurance & definition';
    } else if (min >= 15) {
      return 'High endurance - muscular stamina focus';
    } else {
      return 'Balanced approach - variety of adaptations';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final min = _values.start.round();
    final max = _values.end.round();

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
              'Rep Range Preference',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set your preferred reps per set',
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 32),

            // Large rep display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RepBadge(value: min, label: 'Min'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'to',
                    style: TextStyle(
                      fontSize: 18,
                      color: textMuted,
                    ),
                  ),
                ),
                _RepBadge(value: max, label: 'Max'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _getDescription(min, max),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.cyan,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Range slider
            RangeSlider(
              values: _values,
              min: 1,
              max: 30,
              divisions: 29,
              activeColor: AppColors.cyan,
              inactiveColor: AppColors.cyan.withOpacity(0.2),
              onChanged: (values) {
                HapticFeedback.selectionClick();
                setState(() => _values = values);
              },
            ),

            // Labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '1',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                  Text(
                    '15',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                  Text(
                    '30',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PresetChip(
                    label: 'Strength (1-5)',
                    isSelected: min == 1 && max == 5,
                    onTap: () => setState(() => _values = const RangeValues(1, 5)),
                  ),
                  const SizedBox(width: 8),
                  _PresetChip(
                    label: 'Hypertrophy (8-12)',
                    isSelected: min == 8 && max == 12,
                    onTap: () => setState(() => _values = const RangeValues(8, 12)),
                  ),
                  const SizedBox(width: 8),
                  _PresetChip(
                    label: 'Endurance (15-20)',
                    isSelected: min == 15 && max == 20,
                    onTap: () => setState(() => _values = const RangeValues(15, 20)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.cyan.withOpacity(0.3),
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
                      'The AI will try to keep exercises in this range by adjusting weight or suggesting progressions.',
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
                  widget.onSave(min, max);
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

/// Badge displaying a rep value
class _RepBadge extends StatelessWidget {
  final int value;
  final String label;

  const _RepBadge({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.cyan.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.cyan.withOpacity(0.3),
            ),
          ),
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.cyan,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Quick preset chip for rep ranges
class _PresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan
              : (isDark
                  ? AppColors.pureBlack.withOpacity(0.5)
                  : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for selecting sets range with dual sliders
class _SetsRangeSliderSheet extends StatefulWidget {
  final int initialMin;
  final int initialMax;
  final Function(int min, int max) onSave;

  const _SetsRangeSliderSheet({
    required this.initialMin,
    required this.initialMax,
    required this.onSave,
  });

  @override
  State<_SetsRangeSliderSheet> createState() => _SetsRangeSliderSheetState();
}

class _SetsRangeSliderSheetState extends State<_SetsRangeSliderSheet> {
  late double _minSets;
  late double _maxSets;

  // Constants for sets range
  static const double kMinSetsLower = 1;
  static const double kMinSetsUpper = 4;
  static const double kMaxSetsLower = 2;
  static const double kMaxSetsUpper = 8;

  @override
  void initState() {
    super.initState();
    _minSets = widget.initialMin.toDouble().clamp(kMinSetsLower, kMinSetsUpper);
    _maxSets = widget.initialMax.toDouble().clamp(kMaxSetsLower, kMaxSetsUpper);
  }

  String _getVolumeDescription(int minSets, int maxSets) {
    if (maxSets <= 2) {
      return 'Minimal volume - great for maintenance or time-crunched';
    } else if (maxSets <= 3) {
      return 'Low volume - efficient training for intermediates';
    } else if (maxSets <= 4) {
      return 'Moderate volume - balanced approach for most goals';
    } else if (maxSets <= 6) {
      return 'High volume - great for hypertrophy and building size';
    } else {
      return 'Very high volume - advanced bodybuilding style';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final minSets = _minSets.round();
    final maxSets = _maxSets.round();

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
              'Sets Per Exercise',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure your set volume for each exercise',
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 32),

            // Sets display badges
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SetsBadge(value: minSets, label: 'Min Sets'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'to',
                    style: TextStyle(
                      fontSize: 18,
                      color: textMuted,
                    ),
                  ),
                ),
                _SetsBadge(value: maxSets, label: 'Max Sets'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _getVolumeDescription(minSets, maxSets),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.purple,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Min Sets Slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Minimum Sets: $minSets',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColorsLight.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Minimum sets to ensure adequate volume',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                ),
                Slider(
                  value: _minSets,
                  min: kMinSetsLower,
                  max: kMinSetsUpper,
                  divisions: (kMinSetsUpper - kMinSetsLower).toInt(),
                  activeColor: AppColors.purple,
                  inactiveColor: AppColors.purple.withOpacity(0.2),
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _minSets = value;
                      // Ensure max is always >= min
                      if (_maxSets < _minSets) {
                        _maxSets = _minSets;
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Max Sets Slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Maximum Sets: $maxSets',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColorsLight.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Maximum number of sets for each exercise',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                ),
                Slider(
                  value: _maxSets,
                  min: kMaxSetsLower,
                  max: kMaxSetsUpper,
                  divisions: (kMaxSetsUpper - kMaxSetsLower).toInt(),
                  activeColor: AppColors.purple,
                  inactiveColor: AppColors.purple.withOpacity(0.2),
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _maxSets = value;
                      // Ensure min is always <= max
                      if (_minSets > _maxSets) {
                        _minSets = _maxSets;
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PresetChip(
                    label: 'Minimal (1-2)',
                    isSelected: minSets == 1 && maxSets == 2,
                    onTap: () => setState(() {
                      _minSets = 1;
                      _maxSets = 2;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _PresetChip(
                    label: 'Standard (2-4)',
                    isSelected: minSets == 2 && maxSets == 4,
                    onTap: () => setState(() {
                      _minSets = 2;
                      _maxSets = 4;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _PresetChip(
                    label: 'High Volume (3-6)',
                    isSelected: minSets == 3 && maxSets == 6,
                    onTap: () => setState(() {
                      _minSets = 3;
                      _maxSets = 6;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.purple.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.purple,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'The AI will generate workouts with this set range. More sets = more volume = more muscle stimulus.',
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
                  widget.onSave(minSets, maxSets);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
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

/// Badge displaying a sets value
class _SetsBadge extends StatelessWidget {
  final int value;
  final String label;

  const _SetsBadge({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.purple.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.purple.withOpacity(0.3),
            ),
          ),
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.purple,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          ),
        ),
      ],
    );
  }
}
