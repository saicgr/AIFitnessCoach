import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/coach_persona.dart';
import '../../../screens/ai_settings/ai_settings_screen.dart';
import '../../../widgets/coach_avatar.dart';
import '../../../widgets/main_shell.dart';
import '../../../widgets/pill_app_bar.dart';
import '../sections/sections.dart';

/// Sub-page for AI Coach settings: voice, edge handle, privacy.
class AiCoachPage extends ConsumerWidget {
  const AiCoachPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const PillAppBar(title: 'AI Coach'),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Selected Coach + Voice & Personality ──
              _buildCoachCard(
                context: context,
                ref: ref,
                textPrimary: textPrimary,
                textMuted: textMuted,
                cardBorder: cardBorder,
              ),

              const SizedBox(height: 16),

              // ── Edge AI Coach Handle toggle ──
              _buildEdgeHandleToggle(
                ref: ref,
                textPrimary: textPrimary,
                textMuted: textMuted,
                cardBorder: cardBorder,
              ),

              const SizedBox(height: 16),

              // ── AI Privacy section ──
              const AIPrivacySection(),

              const SizedBox(height: 32),
            ],
          ),
        ),
    );
  }

  Widget _buildCoachCard({
    required BuildContext context,
    required WidgetRef ref,
    required Color textPrimary,
    required Color textMuted,
    required Color cardBorder,
  }) {
    final aiSettings = ref.watch(aiSettingsProvider);
    final coachId = aiSettings.coachPersonaId;
    CoachPersona? coach;
    if (coachId != null && coachId.isNotEmpty) {
      try {
        coach = CoachPersona.predefinedCoaches.firstWhere((c) => c.id == coachId);
      } catch (_) {}
    }

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        GoRouter.of(context).push('/ai-settings');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            if (coach != null)
              CoachAvatar(
                coach: coach,
                size: 48,
                showBorder: true,
                borderWidth: 2,
                showShadow: false,
                enableTapToView: false,
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.record_voice_over, color: AppColors.info, size: 24),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coach?.name ?? 'Coach Voice & Personality',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    coach != null
                        ? '${coach.tagline} · Tap to change'
                        : 'Change AI voice and style',
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textMuted, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color textPrimary,
    required Color textMuted,
    required Color cardBorder,
    required VoidCallback onTap,
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
            Icon(icon, color: color, size: 20),
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
            Icon(Icons.chevron_right, color: textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildEdgeHandleToggle({
    required WidgetRef ref,
    required Color textPrimary,
    required Color textMuted,
    required Color cardBorder,
  }) {
    final isEnabled = ref.watch(edgeHandleEnabledProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            color: AppColors.info,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Floating AI Chat Bubble',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                Text(
                  'Show floating bubble for quick AI Coach access',
                  style: TextStyle(
                    fontSize: 11,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isEnabled,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              ref.read(edgeHandleEnabledProvider.notifier).setEnabled(value);
            },
            activeColor: AppColors.info,
          ),
        ],
      ),
    );
  }
}
