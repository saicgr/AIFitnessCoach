import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/consistency_mode_provider.dart';
import '../../../../core/providers/training_intensity_provider.dart';
import '../../../../core/providers/variation_provider.dart';
import '../../../../data/models/exercise_progression.dart';
import '../../../../data/providers/exercise_progression_provider.dart';
import '../beast_mode_constants.dart';
import 'shared/beast_card.dart';

class RepProgressionCard extends ConsumerWidget {
  final BeastThemeData theme;
  const RepProgressionCard({super.key, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repPrefs = ref.watch(repPreferencesProvider);
    final prefs = repPrefs ?? UserRepPreferences.defaultFor('');
    final intensityState = ref.watch(trainingIntensityProvider);
    final variationState = ref.watch(variationProvider);
    final consistencyState = ref.watch(consistencyModeProvider);

    return BeastCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rep & Progression', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimary)),
          const SizedBox(height: 4),
          Text('Fine-tune rep ranges and progression style', style: TextStyle(fontSize: 11, color: theme.textMuted)),
          const SizedBox(height: 16),

          // Rep Range
          _sectionLabel('Rep Range', '${prefs.preferredMinReps}-${prefs.preferredMaxReps} reps'),
          const SizedBox(height: 8),
          RangeSlider(
            values: RangeValues(prefs.preferredMinReps.toDouble(), prefs.preferredMaxReps.toDouble()),
            min: 1,
            max: 30,
            divisions: 29,
            labels: RangeLabels('${prefs.preferredMinReps}', '${prefs.preferredMaxReps}'),
            activeColor: AppColors.orange,
            onChanged: (values) {
              ref.read(exerciseProgressionProvider.notifier).setRepRange(values.start.round(), values.end.round());
            },
          ),
          const SizedBox(height: 12),

          // Sets Range
          _sectionLabel('Sets Range', '${prefs.minSetsPerExercise}-${prefs.maxSetsPerExercise} sets'),
          const SizedBox(height: 8),
          RangeSlider(
            values: RangeValues(prefs.minSetsPerExercise.toDouble(), prefs.maxSetsPerExercise.toDouble()),
            min: 1,
            max: 8,
            divisions: 7,
            labels: RangeLabels('${prefs.minSetsPerExercise}', '${prefs.maxSetsPerExercise}'),
            activeColor: AppColors.orange,
            onChanged: (values) {
              ref.read(exerciseProgressionProvider.notifier).setSetsRange(values.start.round(), values.end.round());
            },
          ),
          const SizedBox(height: 12),

          // Progression Style
          _sectionLabel('Progression Style', prefs.progressionStyle.displayName),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ProgressionStyle.values.map((style) => ChoiceChip(
              label: Text(style.displayName, style: const TextStyle(fontSize: 12)),
              selected: prefs.progressionStyle == style,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                ref.read(exerciseProgressionProvider.notifier).setProgressionStyle(style);
              },
              selectedColor: AppColors.orange.withValues(alpha: 0.2),
              checkmarkColor: AppColors.orange,
            )).toList(),
          ),
          const SizedBox(height: 12),

          // Avoid high reps toggle
          _buildToggle('Avoid high rep sets', prefs.avoidHighReps, (v) {
            ref.read(exerciseProgressionProvider.notifier).setAvoidHighReps(v);
          }),
          const SizedBox(height: 8),

          // Enforce rep ceiling toggle
          _buildToggle('Enforce rep ceiling', prefs.enforceRepCeiling, (v) {
            ref.read(exerciseProgressionProvider.notifier).setEnforceRepCeiling(v);
          }),

          const SizedBox(height: 16),
          Divider(color: theme.cardBorder),
          const SizedBox(height: 16),

          // Training Intensity slider
          _sectionLabel('Training Intensity', '${intensityState.globalIntensityPercent}%'),
          const SizedBox(height: 4),
          Text(intensityState.globalDescription, style: TextStyle(fontSize: 11, color: theme.textMuted)),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.orange,
              inactiveTrackColor: AppColors.orange.withValues(alpha: 0.2),
              thumbColor: AppColors.orange,
              overlayColor: AppColors.orange.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: intensityState.globalIntensityPercent.toDouble(),
              min: 50,
              max: 100,
              divisions: 50,
              onChanged: (value) {
                ref.read(trainingIntensityProvider.notifier).setGlobalIntensity(value.round());
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('50%', style: TextStyle(fontSize: 11, color: theme.textMuted)),
                Text('75%', style: TextStyle(fontSize: 11, color: theme.textMuted)),
                Text('100%', style: TextStyle(fontSize: 11, color: theme.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Weekly Variety slider
          _sectionLabel('Weekly Variety', '${variationState.percentage}%'),
          const SizedBox(height: 4),
          Text(variationState.description, style: TextStyle(fontSize: 11, color: theme.textMuted)),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.orange,
              inactiveTrackColor: AppColors.orange.withValues(alpha: 0.2),
              thumbColor: AppColors.orange,
              overlayColor: AppColors.orange.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: variationState.percentage.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (value) {
                ref.read(variationProvider.notifier).setVariation(value.round());
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0%', style: TextStyle(fontSize: 11, color: theme.textMuted)),
                Text('50%', style: TextStyle(fontSize: 11, color: theme.textMuted)),
                Text('100%', style: TextStyle(fontSize: 11, color: theme.textMuted)),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Divider(color: theme.cardBorder),
          const SizedBox(height: 16),

          // Exercise Consistency Mode
          _sectionLabel('Exercise Consistency', consistencyState.mode.displayName),
          const SizedBox(height: 4),
          Text(consistencyState.mode.description, style: TextStyle(fontSize: 11, color: theme.textMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ConsistencyMode.values.map((mode) => ChoiceChip(
              label: Text(mode.displayName, style: const TextStyle(fontSize: 12)),
              selected: consistencyState.mode == mode,
              onSelected: consistencyState.isLoading ? null : (_) {
                HapticFeedback.selectionClick();
                ref.read(consistencyModeProvider.notifier).setMode(mode);
              },
              selectedColor: AppColors.orange.withValues(alpha: 0.2),
              checkmarkColor: AppColors.orange,
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: theme.textPrimary)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.orange)),
        ),
      ],
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: theme.textPrimary)),
        Switch(
          value: value,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            onChanged(v);
          },
          activeThumbColor: AppColors.orange,
          activeTrackColor: AppColors.orange.withValues(alpha: 0.4),
        ),
      ],
    );
  }
}
