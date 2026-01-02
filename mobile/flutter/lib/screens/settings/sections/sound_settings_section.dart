/// Sound settings section for customizing workout sounds.
///
/// This addresses user feedback: "countdown timer sux plus cheesy applause smh.
/// sounds should be customizable."
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/setting_tile.dart';
import '../widgets/section_header.dart';

/// Available countdown sound types
enum CountdownSoundType { beep, chime, voice, tick, none }

/// Available completion sound types (NO APPLAUSE)
enum CompletionSoundType { chime, bell, success, fanfare, none }

/// Provider for sound preferences (simplified state)
final soundPreferencesProvider = StateNotifierProvider<SoundPreferencesNotifier, SoundPreferencesState>((ref) {
  return SoundPreferencesNotifier();
});

class SoundPreferencesState {
  final bool countdownSoundEnabled;
  final CountdownSoundType countdownSoundType;
  final bool completionSoundEnabled;
  final CompletionSoundType completionSoundType;
  final bool restTimerSoundEnabled;
  final CountdownSoundType restTimerSoundType;
  final double soundEffectsVolume;

  SoundPreferencesState({
    this.countdownSoundEnabled = true,
    this.countdownSoundType = CountdownSoundType.beep,
    this.completionSoundEnabled = true,
    this.completionSoundType = CompletionSoundType.chime,
    this.restTimerSoundEnabled = true,
    this.restTimerSoundType = CountdownSoundType.beep,
    this.soundEffectsVolume = 0.8,
  });

  SoundPreferencesState copyWith({
    bool? countdownSoundEnabled,
    CountdownSoundType? countdownSoundType,
    bool? completionSoundEnabled,
    CompletionSoundType? completionSoundType,
    bool? restTimerSoundEnabled,
    CountdownSoundType? restTimerSoundType,
    double? soundEffectsVolume,
  }) {
    return SoundPreferencesState(
      countdownSoundEnabled: countdownSoundEnabled ?? this.countdownSoundEnabled,
      countdownSoundType: countdownSoundType ?? this.countdownSoundType,
      completionSoundEnabled: completionSoundEnabled ?? this.completionSoundEnabled,
      completionSoundType: completionSoundType ?? this.completionSoundType,
      restTimerSoundEnabled: restTimerSoundEnabled ?? this.restTimerSoundEnabled,
      restTimerSoundType: restTimerSoundType ?? this.restTimerSoundType,
      soundEffectsVolume: soundEffectsVolume ?? this.soundEffectsVolume,
    );
  }
}

class SoundPreferencesNotifier extends StateNotifier<SoundPreferencesState> {
  SoundPreferencesNotifier() : super(SoundPreferencesState());

  void setCountdownEnabled(bool enabled) {
    state = state.copyWith(countdownSoundEnabled: enabled);
  }

  void setCountdownType(CountdownSoundType type) {
    state = state.copyWith(countdownSoundType: type);
  }

  void setCompletionEnabled(bool enabled) {
    state = state.copyWith(completionSoundEnabled: enabled);
  }

  void setCompletionType(CompletionSoundType type) {
    state = state.copyWith(completionSoundType: type);
  }

  void setRestTimerEnabled(bool enabled) {
    state = state.copyWith(restTimerSoundEnabled: enabled);
  }

  void setRestTimerType(CountdownSoundType type) {
    state = state.copyWith(restTimerSoundType: type);
  }

  void setVolume(double volume) {
    state = state.copyWith(soundEffectsVolume: volume);
  }
}

class SoundSettingsSection extends ConsumerWidget {
  const SoundSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(soundPreferencesProvider);
    final notifier = ref.read(soundPreferencesProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

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
              // Countdown sounds
              SettingTile(
                icon: Icons.timer_outlined,
                iconColor: AppColors.cyan,
                title: 'Countdown Sounds',
                subtitle: 'Play sounds during countdown (3, 2, 1)',
                trailing: Switch.adaptive(
                  value: prefs.countdownSoundEnabled,
                  onChanged: notifier.setCountdownEnabled,
                  activeColor: AppColors.cyan,
                ),
              ),
              if (prefs.countdownSoundEnabled) ...[
                Builder(
                  builder: (context) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final leftPadding = screenWidth < 380 ? 32.0 : 56.0;
                    return Padding(
                      padding: EdgeInsets.only(left: leftPadding, right: 16, bottom: 12),
                      child: _SoundTypeSelector<CountdownSoundType>(
                        value: prefs.countdownSoundType,
                        options: CountdownSoundType.values,
                        onChanged: notifier.setCountdownType,
                        getName: _getCountdownTypeName,
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              ],
              Divider(height: 1, color: cardBorder),

              // Completion sounds (NO APPLAUSE)
              SettingTile(
                icon: Icons.celebration_outlined,
                iconColor: AppColors.success,
                title: 'Completion Sounds',
                subtitle: 'Play sound when workout ends',
                trailing: Switch.adaptive(
                  value: prefs.completionSoundEnabled,
                  onChanged: notifier.setCompletionEnabled,
                  activeColor: AppColors.cyan,
                ),
              ),
              if (prefs.completionSoundEnabled) ...[
                Builder(
                  builder: (context) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final leftPadding = screenWidth < 380 ? 32.0 : 56.0;
                    return Padding(
                      padding: EdgeInsets.only(left: leftPadding, right: 16, bottom: 12),
                      child: _SoundTypeSelector<CompletionSoundType>(
                        value: prefs.completionSoundType,
                        options: CompletionSoundType.values,
                        onChanged: notifier.setCompletionType,
                        getName: _getCompletionTypeName,
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              ],
              Divider(height: 1, color: cardBorder),

              // Rest timer sounds
              SettingTile(
                icon: Icons.hourglass_empty,
                iconColor: AppColors.warning,
                title: 'Rest Timer Sounds',
                subtitle: 'Play sound when rest period ends',
                trailing: Switch.adaptive(
                  value: prefs.restTimerSoundEnabled,
                  onChanged: notifier.setRestTimerEnabled,
                  activeColor: AppColors.cyan,
                ),
              ),
              if (prefs.restTimerSoundEnabled) ...[
                Builder(
                  builder: (context) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final leftPadding = screenWidth < 380 ? 32.0 : 56.0;
                    return Padding(
                      padding: EdgeInsets.only(left: leftPadding, right: 16, bottom: 12),
                      child: _SoundTypeSelector<CountdownSoundType>(
                        value: prefs.restTimerSoundType,
                        options: CountdownSoundType.values,
                        onChanged: notifier.setRestTimerType,
                        getName: _getCountdownTypeName,
                        isDark: isDark,
                      ),
                    );
                  },
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
                  onChanged: notifier.setVolume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  activeColor: AppColors.cyan,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  String _getCountdownTypeName(CountdownSoundType type) {
    switch (type) {
      case CountdownSoundType.beep:
        return 'Beep';
      case CountdownSoundType.chime:
        return 'Chime';
      case CountdownSoundType.voice:
        return 'Voice';
      case CountdownSoundType.tick:
        return 'Tick';
      case CountdownSoundType.none:
        return 'None';
    }
  }

  String _getCompletionTypeName(CompletionSoundType type) {
    switch (type) {
      case CompletionSoundType.chime:
        return 'Chime';
      case CompletionSoundType.bell:
        return 'Bell';
      case CompletionSoundType.success:
        return 'Success';
      case CompletionSoundType.fanfare:
        return 'Fanfare';
      case CompletionSoundType.none:
        return 'None';
      // NOTE: No 'applause' - user specifically hated it
    }
  }
}

class _SoundTypeSelector<T> extends StatelessWidget {
  final T value;
  final List<T> options;
  final void Function(T) onChanged;
  final String Function(T) getName;
  final bool isDark;

  const _SoundTypeSelector({
    required this.value,
    required this.options,
    required this.onChanged,
    required this.getName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option == value;
        return ChoiceChip(
          label: Text(
            getName(option),
            style: TextStyle(
              color: isSelected ? Colors.white : textSecondary,
              fontSize: 13,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onChanged(option),
          selectedColor: AppColors.cyan,
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? AppColors.cyan : cardBorder,
            ),
          ),
        );
      }).toList(),
    );
  }
}
