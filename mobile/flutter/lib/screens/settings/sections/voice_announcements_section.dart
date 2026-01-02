import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/tts_provider.dart';
import '../widgets/section_header.dart';

/// The voice announcements section for configuring TTS settings.
///
/// Allows users to enable/disable voice announcements during workouts.
class VoiceAnnouncementsSection extends StatelessWidget {
  const VoiceAnnouncementsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'VOICE ANNOUNCEMENTS'),
        SizedBox(height: 12),
        _VoiceAnnouncementsCard(),
      ],
    );
  }
}

class _VoiceAnnouncementsCard extends ConsumerWidget {
  const _VoiceAnnouncementsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final voiceState = ref.watch(voiceAnnouncementsProvider);
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Main toggle
          SwitchListTile(
            secondary: Icon(
              Icons.record_voice_over,
              color: voiceState.isEnabled ? cyan : textSecondary,
              size: 22,
            ),
            title: const Text(
              'Voice Announcements',
              style: TextStyle(fontSize: 15),
            ),
            subtitle: Text(
              voiceState.isEnabled
                  ? 'Announcing exercise names during transitions'
                  : 'Enable to hear exercise announcements',
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
            value: voiceState.isEnabled,
            activeThumbColor: cyan,
            onChanged: voiceState.isLoading
                ? null
                : (value) async {
                    HapticFeedback.selectionClick();
                    await ref
                        .read(voiceAnnouncementsProvider.notifier)
                        .setEnabled(value);
                  },
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // Info section
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
                      'When enabled, you will hear:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  context,
                  'Next exercise announcements during rest',
                  textMuted,
                ),
                const SizedBox(height: 6),
                _buildFeatureItem(
                  context,
                  'Rest period notifications',
                  textMuted,
                ),
                const SizedBox(height: 6),
                _buildFeatureItem(
                  context,
                  'Workout completion celebration',
                  textMuted,
                ),
              ],
            ),
          ),

          // Test button
          if (voiceState.isEnabled) ...[
            Divider(height: 1, color: cardBorder),
            InkWell(
              onTap: () async {
                HapticFeedback.lightImpact();
                await ref
                    .read(voiceAnnouncementsProvider.notifier)
                    .announceIfEnabled('Testing voice announcements. Get ready for bench press!');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      color: cyan,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Test Voice',
                      style: TextStyle(
                        fontSize: 15,
                        color: cyan,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String text, Color textColor) {
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
