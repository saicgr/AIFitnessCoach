import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../ai_settings/ai_settings_screen.dart';
import '../widgets/widgets.dart';

/// The Privacy & Data section — surfaces real, server-enforced consent
/// toggles (personalization + chat history) plus the medical disclaimer.
///
/// Prior versions wrote to SharedPreferences keys that no code ever read,
/// which made the toggles placebo controls (a GDPR Art. 7(4) dark pattern).
/// All toggles here are now backed by `user_ai_settings` and enforced by
/// `services.consent_guard` on the backend.
class AIPrivacySection extends ConsumerWidget {
  const AIPrivacySection({super.key});

  Future<void> _togglePersonalization(WidgetRef ref, bool value) async {
    HapticFeedback.lightImpact();
    final notifier = ref.read(aiSettingsProvider.notifier);
    await notifier.updateAiDataProcessingEnabled(value);
  }

  Future<void> _toggleSaveChatHistory(WidgetRef ref, bool value) async {
    HapticFeedback.lightImpact();
    final notifier = ref.read(aiSettingsProvider.notifier);
    await notifier.updateSaveChatHistory(value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final settings = ref.watch(aiSettingsProvider);
    final personalizationEnabled = settings.aiDataProcessingEnabled;
    final saveChatHistory = settings.saveChatHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'PRIVACY & DATA',
          subtitle: 'Control how your data is used',
        ),
        const SizedBox(height: 12),

        // Data usage explainer — navigation tile
        _buildNavigationTile(
          icon: Icons.info_outlined,
          title: 'How Your Data Is Used',
          subtitle: 'See what data is processed and how',
          color: AppColors.info,
          onTap: () => context.push('/settings/ai-data-usage'),
          textPrimary: textPrimary,
          textMuted: textMuted,
          cardBorder: cardBorder,
        ),

        const SizedBox(height: 10),

        // Personalization toggle — server-enforced kill switch
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.psychology_outlined,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personalization',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      personalizationEnabled
                          ? 'Your coach personalizes workouts and chat'
                          : 'Personalization is paused — coach chat is disabled',
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: personalizationEnabled,
                onChanged: (v) => _togglePersonalization(ref, v),
                activeColor: AppColors.success,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Save chat history toggle — server-enforced
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Save Chat History',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      saveChatHistory
                          ? 'Messages are stored so your coach remembers context'
                          : 'Messages are discarded after each reply',
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: saveChatHistory,
                onChanged: (v) => _toggleSaveChatHistory(ref, v),
                activeColor: AppColors.info,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Medical Disclaimer - navigation tile
        _buildNavigationTile(
          icon: Icons.medical_information_outlined,
          title: 'Medical Disclaimer',
          subtitle: 'Important health information',
          color: AppColors.warning,
          onTap: () => context.push('/settings/medical-disclaimer'),
          textPrimary: textPrimary,
          textMuted: textMuted,
          cardBorder: cardBorder,
        ),

      ],
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color textMuted,
    required Color cardBorder,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, color: textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
