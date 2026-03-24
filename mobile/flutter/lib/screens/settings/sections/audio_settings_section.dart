import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/tts_provider.dart';
import '../../../data/providers/audio_preferences_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/glass_sheet.dart';
import '../widgets/widgets.dart';

/// Combined workout audio section: voice announcements + audio behavior.
class AudioSettingsSection extends StatelessWidget {
  const AudioSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'WORKOUT AUDIO'),
        SizedBox(height: 12),
        _AudioCard(),
      ],
    );
  }
}

class _AudioCard extends ConsumerStatefulWidget {
  const _AudioCard();

  @override
  ConsumerState<_AudioCard> createState() => _AudioCardState();
}

class _AudioCardState extends ConsumerState<_AudioCard> {
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
      if (mounted) setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    final voiceState = ref.watch(voiceAnnouncementsProvider);
    final audioPrefsState = ref.watch(audioPreferencesProvider);
    final prefs = audioPrefsState.preferences;

    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Voice Announcements toggle
          SwitchListTile(
            secondary: Icon(
              Icons.record_voice_over,
              color: voiceState.isEnabled ? cyan : textSecondary,
              size: 22,
            ),
            title: const Text('Voice Announcements', style: TextStyle(fontSize: 15)),
            subtitle: Text(
              'Announce exercises during rest periods',
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
            value: voiceState.isEnabled,
            activeThumbColor: cyan,
            onChanged: voiceState.isLoading
                ? null
                : (value) async {
                    HapticFeedback.selectionClick();
                    await ref.read(voiceAnnouncementsProvider.notifier).setEnabled(value);
                  },
          ),

          Divider(height: 1, color: cardBorder, indent: 50),

          // Background Music toggle
          if (_isInitialized && prefs != null) ...[
            SettingSwitchTile(
              icon: Icons.queue_music,
              iconColor: AppColors.purple,
              title: 'Background Music',
              subtitle: 'Keep Spotify/music playing during workouts',
              value: prefs.allowBackgroundMusic,
              onChanged: (value) async {
                HapticFeedback.lightImpact();
                if (_userId != null) {
                  await ref.read(audioPreferencesProvider.notifier)
                      .setAllowBackgroundMusic(_userId!, value);
                }
              },
            ),
            Divider(height: 1, color: cardBorder, indent: 50),

            // Audio Ducking toggle
            SettingSwitchTile(
              icon: Icons.graphic_eq,
              iconColor: AppColors.orange,
              title: 'Audio Ducking',
              subtitle: 'Lower music during voice announcements',
              value: prefs.audioDucking,
              onChanged: (value) async {
                HapticFeedback.lightImpact();
                if (_userId != null) {
                  await ref.read(audioPreferencesProvider.notifier)
                      .setAudioDucking(_userId!, value);
                }
              },
            ),
            Divider(height: 1, color: cardBorder, indent: 50),

            // Advanced audio settings
            InkWell(
              onTap: () => _showAdvancedAudioSheet(context, isDark, textMuted, cardBorder, cyan, prefs),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.tune, color: textSecondary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Advanced Audio', style: TextStyle(fontSize: 15)),
                          Text('Volume, ducking level, video mute', style: TextStyle(fontSize: 12, color: textMuted)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: textMuted, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAdvancedAudioSheet(
    BuildContext context, bool isDark, Color textMuted, Color cardBorder, Color cyan,
    dynamic prefs,
  ) {
    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: Consumer(
          builder: (_, ref, __) {
            final audioState = ref.watch(audioPreferencesProvider);
            final p = audioState.preferences;
            if (p == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Advanced Audio Settings',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // TTS Volume slider
                  _buildVolumeSlider(
                    'Voice Volume',
                    Icons.volume_up,
                    cyan,
                    p.ttsVolume,
                    (v) {
                      if (_userId != null) {
                        ref.read(audioPreferencesProvider.notifier).setTtsVolume(_userId!, v);
                      }
                    },
                    textMuted,
                    isDark,
                  ),
                  const SizedBox(height: 12),

                  // Ducking Level slider
                  if (p.audioDucking) ...[
                    _buildVolumeSlider(
                      'Ducking Level',
                      Icons.graphic_eq,
                      AppColors.orange,
                      p.duckVolumeLevel,
                      (v) {
                        if (_userId != null) {
                          ref.read(audioPreferencesProvider.notifier).setDuckVolumeLevel(_userId!, v);
                        }
                      },
                      textMuted,
                      isDark,
                      subtitle: 'How much to lower background music',
                      isInverted: true,
                    ),
                    const SizedBox(height: 12),
                  ],

                  Divider(height: 1, color: cardBorder),

                  // Mute During Video toggle
                  SwitchListTile(
                    secondary: Icon(Icons.videocam_off, color: p.muteDuringVideo ? AppColors.success : Colors.grey, size: 20),
                    title: const Text('Mute Voice During Videos', style: TextStyle(fontSize: 14)),
                    subtitle: Text('Silence announcements when watching demos', style: TextStyle(fontSize: 11, color: textMuted)),
                    value: p.muteDuringVideo,
                    activeThumbColor: AppColors.cyan,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) {
                      HapticFeedback.lightImpact();
                      if (_userId != null) {
                        ref.read(audioPreferencesProvider.notifier).setMuteDuringVideo(_userId!, v);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVolumeSlider(
    String title, IconData icon, Color color, double value,
    ValueChanged<double> onChanged, Color textMuted, bool isDark, {
    String? subtitle,
    bool isInverted = false,
  }) {
    final displayPct = isInverted ? ((1.0 - value) * 100).round() : (value * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  if (subtitle != null)
                    Text(subtitle, style: TextStyle(fontSize: 11, color: textMuted)),
                ],
              ),
            ),
            Text('$displayPct%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.2),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.1),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: onChanged,
            onChangeEnd: (_) => HapticFeedback.lightImpact(),
          ),
        ),
      ],
    );
  }
}
