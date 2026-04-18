import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../data/providers/cosmetics_provider.dart';
import '../data/services/haptic_service.dart';
import '../data/services/tts_service.dart';
import '../screens/ai_settings/ai_settings_screen.dart';

/// Coach voice selector.
/// - "Default" is always available.
/// - "Coach Chad" / "Coach Serena" require owning the matching cosmetic
///   (unlocked at Level 50 via the cosmetics system).
/// On selection: persists via AI Settings API + applies the new voice live.
class CoachVoicePicker extends ConsumerWidget {
  const CoachVoicePicker({super.key});

  static const _options = [
    _VoiceOption(
      id: 'default',
      label: 'Default',
      subtitle: "Your device's default voice",
      emoji: '🗣️',
      cosmeticId: null,
    ),
    _VoiceOption(
      id: 'coach_voice_chad',
      label: 'Coach Chad',
      subtitle: 'Deeper, high-energy voice',
      emoji: '💪',
      cosmeticId: 'coach_voice_chad',
    ),
    _VoiceOption(
      id: 'coach_voice_serena',
      label: 'Coach Serena',
      subtitle: 'Calm, precise voice',
      emoji: '✨',
      cosmeticId: 'coach_voice_serena',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final settings = ref.watch(aiSettingsProvider);
    final selected = settings.coachVoiceId;
    final cosmetics = ref.watch(cosmeticsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.record_voice_over, color: textMuted, size: 18),
              const SizedBox(width: 8),
              Text(
                'Coach voice',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Plays during workout announcements',
            style: TextStyle(fontSize: 12, color: textMuted),
          ),
          const SizedBox(height: 12),
          ..._options.map((opt) {
            final isSelected = selected == opt.id;
            final isLocked = opt.cosmeticId != null && !cosmetics.ownsCosmetic(opt.cosmeticId!);
            return _buildVoiceRow(
              opt: opt,
              selected: isSelected,
              locked: isLocked,
              textPrimary: textPrimary,
              textMuted: textMuted,
              border: border,
              isDark: isDark,
              onTap: () async {
                if (isLocked) {
                  HapticService.light();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unlocks at Level 50 — keep leveling up!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                HapticService.light();
                try {
                  // Apply voice live, then persist
                  await TTSService().applyVoice(opt.id);
                  ref.read(aiSettingsProvider.notifier).updateCoachVoice(opt.id);
                  // Preview — uses the new voice/pitch/rate
                  await TTSService().speak("Let's crush this workout!");
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to switch voice: $e')),
                    );
                  }
                }
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVoiceRow({
    required _VoiceOption opt,
    required bool selected,
    required bool locked,
    required Color textPrimary,
    required Color textMuted,
    required Color border,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.cyan : border,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? AppColors.cyan.withValues(alpha: isDark ? 0.12 : 0.08)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Opacity(
              opacity: locked ? 0.45 : 1.0,
              child: Text(opt.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        opt.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: locked ? textMuted : textPrimary,
                        ),
                      ),
                      if (locked) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.lock, size: 12, color: textMuted),
                      ],
                    ],
                  ),
                  Text(
                    locked ? 'Unlocks at Level 50' : opt.subtitle,
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.cyan, size: 22),
          ],
        ),
      ),
    );
  }
}

class _VoiceOption {
  final String id;
  final String label;
  final String subtitle;
  final String emoji;
  final String? cosmeticId;

  const _VoiceOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.emoji,
    this.cosmeticId,
  });
}
