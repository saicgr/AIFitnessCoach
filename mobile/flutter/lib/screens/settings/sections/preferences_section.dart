import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/exercise_progression.dart';
import '../../../data/providers/exercise_progression_provider.dart';
import '../widgets/widgets.dart';

class PreferencesSection extends ConsumerWidget {
  const PreferencesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final repPrefs = ref.watch(repPreferencesProvider);
    final currentFocus = repPrefs?.trainingFocus ?? TrainingFocus.hypertrophy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'PREFERENCES'),
        const SizedBox(height: 12),
        SettingsCard(
          items: [
            SettingItemData(
              icon: Icons.palette_outlined,
              title: 'Theme',
              subtitle: 'System, Light, or Dark',
              isThemeSelector: true,
            ),
            SettingItemData(
              icon: Icons.color_lens_outlined,
              title: 'Accent Color',
              subtitle: 'Choose your app accent color',
              isAccentColorSelector: true,
            ),
            SettingItemData(
              icon: Icons.travel_explore_outlined,
              title: 'Timezone',
              subtitle: 'Auto-detected, override if traveling',
              isTimezoneSelector: true,
            ),
            SettingItemData(
              icon: Icons.fitness_center_outlined,
              title: 'Weight Unit',
              subtitle: 'Kilograms or Pounds',
              isWeightUnitSelector: true,
            ),
            SettingItemData(
              icon: Icons.bolt_outlined,
              title: 'Show Daily Goals',
              subtitle: 'XP progress strip on home screen',
              isDailyXPStripToggle: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Training Focus card
        Material(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.track_changes, color: textSecondary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Training Focus', style: TextStyle(fontSize: 15)),
                          Text(
                            currentFocus.description,
                            style: TextStyle(fontSize: 12, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<TrainingFocus>(
                    segments: TrainingFocus.values.map((focus) => ButtonSegment<TrainingFocus>(
                      value: focus,
                      label: Text(focus.displayName, style: const TextStyle(fontSize: 12)),
                    )).toList(),
                    selected: {currentFocus},
                    onSelectionChanged: (selected) {
                      HapticFeedback.selectionClick();
                      ref.read(exerciseProgressionProvider.notifier).setTrainingFocus(selected.first);
                    },
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
