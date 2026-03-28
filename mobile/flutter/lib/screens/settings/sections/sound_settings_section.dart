/// Sound settings section for customizing workout sounds.
///
/// This addresses user feedback: "countdown timer sux plus cheesy applause smh.
/// sounds should be customizable."
///
/// Sound Categories:
/// - Countdown (3, 2, 1): beep, chime, voice, tick, none
/// - Rest Timer End: beep, chime, gong, none
/// - Exercise Complete: chime, bell, ding, pop, whoosh, none
/// - Workout Complete: chime, bell, success, fanfare, none (NO APPLAUSE!)
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/sound_preferences_provider.dart';
import '../../../data/services/sound_service.dart';
import '../widgets/setting_tile.dart';
import '../widgets/section_header.dart';

/// Available countdown sound types
const List<String> countdownSoundTypes = [
  'beep',
  'chime',
  'voice',
  'tick',
  'custom',
  'none',
];

/// Available rest timer sound types
const List<String> restTimerSoundTypes = ['beep', 'chime', 'gong', 'custom', 'none'];

/// Available exercise completion sound types
const List<String> exerciseCompletionSoundTypes = [
  'chime',
  'bell',
  'ding',
  'pop',
  'whoosh',
  'custom',
  'none',
];

/// Available workout completion sound types (NO APPLAUSE)
const List<String> workoutCompletionSoundTypes = [
  'chime',
  'bell',
  'success',
  'fanfare',
  'custom',
  'none',
];

class SoundSettingsSection extends ConsumerWidget {
  const SoundSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(soundPreferencesProvider);
    final notifier = ref.read(soundPreferencesProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Sound Effects',
          subtitle: 'Customize workout sounds',
        ),
        Material(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Countdown sounds (3, 2, 1)
              SettingTile(
                icon: Icons.timer_outlined,
                iconColor: AppColors.cyan,
                title: 'Countdown Sounds',
                subtitle: 'Play sounds during countdown (3, 2, 1)',
                trailing: Switch.adaptive(
                  value: prefs.countdownSoundEnabled,
                  onChanged: (enabled) => notifier.setCountdownEnabled(enabled),
                ),
              ),
              if (prefs.countdownSoundEnabled) ...[
                _buildSoundTypeSelector(
                  context: context,
                  value: prefs.countdownSoundType,
                  options: countdownSoundTypes,
                  category: 'countdown',
                  onChanged: (type) => notifier.setCountdownType(type),
                  onPreview: (type) => notifier.playPreview('countdown', type),
                  isDark: isDark,
                ),
              ],
              Divider(height: 1, color: cardBorder),

              // Rest timer end sounds
              SettingTile(
                icon: Icons.hourglass_empty,
                iconColor: AppColors.warning,
                title: 'Rest Timer End',
                subtitle: 'Play sound when rest period ends',
                trailing: Switch.adaptive(
                  value: prefs.restTimerSoundEnabled,
                  onChanged: (enabled) => notifier.setRestTimerEnabled(enabled),
                ),
              ),
              if (prefs.restTimerSoundEnabled) ...[
                _buildSoundTypeSelector(
                  context: context,
                  value: prefs.restTimerSoundType,
                  options: restTimerSoundTypes,
                  category: 'rest_end',
                  onChanged: (type) => notifier.setRestTimerType(type),
                  onPreview: (type) => notifier.playPreview('rest_end', type),
                  isDark: isDark,
                ),
              ],
              Divider(height: 1, color: cardBorder),

              // Exercise completion sounds (NEW)
              SettingTile(
                icon: Icons.fitness_center,
                iconColor: AppColors.textPrimary,
                title: 'Exercise Completion',
                subtitle: 'Play sound when all sets of exercise done',
                trailing: Switch.adaptive(
                  value: prefs.exerciseCompletionSoundEnabled,
                  onChanged: (enabled) =>
                      notifier.setExerciseCompletionEnabled(enabled),
                ),
              ),
              if (prefs.exerciseCompletionSoundEnabled) ...[
                _buildSoundTypeSelector(
                  context: context,
                  value: prefs.exerciseCompletionSoundType,
                  options: exerciseCompletionSoundTypes,
                  category: 'exercise_complete',
                  onChanged: (type) => notifier.setExerciseCompletionType(type),
                  onPreview: (type) =>
                      notifier.playPreview('exercise_complete', type),
                  isDark: isDark,
                ),
              ],
              Divider(height: 1, color: cardBorder),

              // Workout completion sounds (NO APPLAUSE)
              SettingTile(
                icon: Icons.celebration_outlined,
                iconColor: AppColors.success,
                title: 'Workout Completion',
                subtitle: 'Play sound when entire workout ends',
                trailing: Switch.adaptive(
                  value: prefs.workoutCompletionSoundEnabled,
                  onChanged: (enabled) =>
                      notifier.setWorkoutCompletionEnabled(enabled),
                ),
              ),
              if (prefs.workoutCompletionSoundEnabled) ...[
                _buildSoundTypeSelector(
                  context: context,
                  value: prefs.workoutCompletionSoundType,
                  options: workoutCompletionSoundTypes,
                  category: 'workout_complete',
                  onChanged: (type) => notifier.setWorkoutCompletionType(type),
                  onPreview: (type) =>
                      notifier.playPreview('workout_complete', type),
                  isDark: isDark,
                ),
              ],
              Divider(height: 1, color: cardBorder),

              // Volume slider
              SettingTile(
                icon: Icons.volume_up,
                iconColor: AppColors.textSecondary,
                title: 'Sound Volume',
                subtitle: '${(prefs.soundEffectsVolume * 100).round()}%',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Slider(
                  value: prefs.soundEffectsVolume,
                  onChanged: (volume) => notifier.setVolume(volume),
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSoundTypeSelector({
    required BuildContext context,
    required String value,
    required List<String> options,
    required String category,
    required void Function(String) onChanged,
    required void Function(String) onPreview,
    required bool isDark,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final leftPadding = screenWidth < 380 ? 32.0 : 56.0;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final soundService = SoundService();
    final hasCustom = soundService.getCustomSoundPath(category) != null;

    return Padding(
      padding: EdgeInsets.only(left: leftPadding, right: 16, bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) {
          final isSelected = option == value;
          final isCustom = option == 'custom';

          return GestureDetector(
            onLongPress: () {
              if (option == 'none') return;
              if (isCustom && !hasCustom) return;
              onPreview(option);
            },
            child: ChoiceChip(
              avatar: isCustom
                  ? Icon(
                      hasCustom ? Icons.music_note : Icons.upload_file,
                      size: 16,
                      color: isSelected ? Colors.white : textSecondary,
                    )
                  : null,
              label: Text(
                isCustom
                    ? (hasCustom ? 'Custom' : 'Upload')
                    : _formatSoundTypeName(option),
                style: TextStyle(
                  color: isSelected ? Colors.white : textSecondary,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (_) async {
                if (isCustom) {
                  // Pick an audio file
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
                  );
                  if (result != null && result.files.single.path != null) {
                    final file = result.files.single;
                    final fileSizeKb = (file.size / 1024).round();

                    // Max 2MB - these are short sound effects, not music
                    if (file.size > 2 * 1024 * 1024) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'File too large (${(file.size / (1024 * 1024)).toStringAsFixed(1)}MB). Max 2MB for sound effects.',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                      return;
                    }

                    final path = await soundService.setCustomSound(
                      category,
                      file.path!,
                    );
                    if (path != null && context.mounted) {
                      onChanged('custom');
                      onPreview('custom');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Custom sound set (${fileSizeKb}KB)'),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } else if (hasCustom) {
                    // Already has a custom file, just select it
                    onChanged('custom');
                    onPreview('custom');
                  }
                } else {
                  onChanged(option);
                  if (option != 'none') {
                    onPreview(option);
                  }
                }
              },
              selectedColor: isCustom ? AppColors.orange : AppColors.cyan,
              backgroundColor: surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? (isCustom ? AppColors.orange : AppColors.cyan)
                      : cardBorder,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatSoundTypeName(String type) {
    switch (type) {
      case 'beep':
        return 'Beep';
      case 'chime':
        return 'Chime';
      case 'voice':
        return 'Voice';
      case 'tick':
        return 'Tick';
      case 'gong':
        return 'Gong';
      case 'bell':
        return 'Bell';
      case 'ding':
        return 'Ding';
      case 'pop':
        return 'Pop';
      case 'whoosh':
        return 'Whoosh';
      case 'success':
        return 'Success';
      case 'fanfare':
        return 'Fanfare';
      case 'none':
        return 'None';
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }
}
