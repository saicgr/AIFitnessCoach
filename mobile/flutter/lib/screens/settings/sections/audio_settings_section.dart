import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/audio_preferences_provider.dart';
import '../../../data/services/api_client.dart';
import '../widgets/widgets.dart';

/// The audio settings section for managing audio preferences.
///
/// Allows users to control background music behavior, TTS volume,
/// audio ducking, and video muting preferences.
class AudioSettingsSection extends StatelessWidget {
  const AudioSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'AUDIO SETTINGS'),
        SizedBox(height: 12),
        _AudioSettingsCard(),
      ],
    );
  }
}

class _AudioSettingsCard extends ConsumerStatefulWidget {
  const _AudioSettingsCard();

  @override
  ConsumerState<_AudioSettingsCard> createState() => _AudioSettingsCardState();
}

class _AudioSettingsCardState extends ConsumerState<_AudioSettingsCard> {
  bool _isInitialized = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    final apiClient = ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();
    if (userId != null && mounted) {
      _userId = userId;
      await ref.read(audioPreferencesProvider.notifier).initialize(userId);
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  Future<void> _setAllowBackgroundMusic(bool value) async {
    HapticFeedback.lightImpact();
    if (_userId != null) {
      await ref
          .read(audioPreferencesProvider.notifier)
          .setAllowBackgroundMusic(_userId!, value);
    }
  }

  Future<void> _setTtsVolume(double value) async {
    if (_userId != null) {
      await ref
          .read(audioPreferencesProvider.notifier)
          .setTtsVolume(_userId!, value);
    }
  }

  Future<void> _setAudioDucking(bool value) async {
    HapticFeedback.lightImpact();
    if (_userId != null) {
      await ref
          .read(audioPreferencesProvider.notifier)
          .setAudioDucking(_userId!, value);
    }
  }

  Future<void> _setDuckVolumeLevel(double value) async {
    if (_userId != null) {
      await ref
          .read(audioPreferencesProvider.notifier)
          .setDuckVolumeLevel(_userId!, value);
    }
  }

  Future<void> _setMuteDuringVideo(bool value) async {
    HapticFeedback.lightImpact();
    if (_userId != null) {
      await ref
          .read(audioPreferencesProvider.notifier)
          .setMuteDuringVideo(_userId!, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    final audioPrefsState = ref.watch(audioPreferencesProvider);
    final prefs = audioPrefsState.preferences;

    // Show loading state
    if (!_isInitialized || audioPrefsState.isLoading && prefs == null) {
      return Container(
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: cyan,
          ),
        ),
      );
    }

    // Show error state
    if (audioPrefsState.error != null && prefs == null) {
      return Container(
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 32),
            const SizedBox(height: 8),
            Text(
              'Failed to load audio preferences',
              style: TextStyle(color: textMuted),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _initializePreferences,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final allowBackgroundMusic = prefs?.allowBackgroundMusic ?? true;
    final ttsVolume = prefs?.ttsVolume ?? 1.0;
    final audioDucking = prefs?.audioDucking ?? true;
    final duckVolumeLevel = prefs?.duckVolumeLevel ?? 0.3;
    final muteDuringVideo = prefs?.muteDuringVideo ?? true;

    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Description text
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.music_note,
                  color: cyan,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Control how audio behaves during workouts',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cardBorder),

          // Allow Background Music toggle
          SettingSwitchTile(
            icon: Icons.queue_music,
            iconColor: AppColors.purple,
            title: 'Allow Background Music',
            subtitle: 'Keep Spotify or other music playing',
            value: allowBackgroundMusic,
            onChanged: _setAllowBackgroundMusic,
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // TTS Volume slider
          _buildSliderTile(
            context: context,
            icon: Icons.volume_up,
            iconColor: cyan,
            title: 'Voice Announcement Volume',
            value: ttsVolume,
            onChanged: _setTtsVolume,
            textMuted: textMuted,
            isDark: isDark,
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // Audio Ducking toggle
          SettingSwitchTile(
            icon: Icons.graphic_eq,
            iconColor: AppColors.orange,
            title: 'Audio Ducking',
            subtitle: 'Lower music during voice announcements',
            value: audioDucking,
            onChanged: _setAudioDucking,
          ),

          // Ducking Level slider (only shown if ducking is enabled)
          if (audioDucking) ...[
            Divider(height: 1, color: cardBorder, indent: 50),
            _buildSliderTile(
              context: context,
              icon: Icons.tune,
              iconColor: AppColors.orange.withValues(alpha: 0.7),
              title: 'Ducking Level',
              subtitle: 'How much to lower background music',
              value: duckVolumeLevel,
              onChanged: _setDuckVolumeLevel,
              textMuted: textMuted,
              isDark: isDark,
              isInverted: true,
            ),
          ],
          Divider(height: 1, color: cardBorder, indent: 50),

          // Mute During Video toggle
          SettingSwitchTile(
            icon: Icons.videocam_off,
            iconColor: AppColors.success,
            title: 'Mute Voice During Videos',
            subtitle: 'Silence announcements when watching demos',
            value: muteDuringVideo,
            onChanged: _setMuteDuringVideo,
          ),

          // Info section
          Divider(height: 1, color: cardBorder),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tips',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoItem(
                  context,
                  'Enable background music to keep Spotify playing',
                  textMuted,
                ),
                const SizedBox(height: 6),
                _buildInfoItem(
                  context,
                  'Audio ducking lowers music so you can hear announcements',
                  textMuted,
                ),
                const SizedBox(height: 6),
                _buildInfoItem(
                  context,
                  'Muting during videos prevents overlapping audio',
                  textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required double value,
    required ValueChanged<double> onChanged,
    required Color textMuted,
    required bool isDark,
    bool isInverted = false,
  }) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    // For inverted sliders (like ducking level), show percentage inversely
    final displayValue = isInverted ? (1.0 - value) * 100 : value * 100;
    final displayLabel = '${displayValue.round()}%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        color: textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: cyan,
              inactiveTrackColor: cyan.withValues(alpha: 0.2),
              thumbColor: cyan,
              overlayColor: cyan.withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              onChanged: onChanged,
              onChangeEnd: (val) {
                HapticFeedback.lightImpact();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String text, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: textColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}
