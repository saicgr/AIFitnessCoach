import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import 'package:fitwiz/core/constants/branding.dart';
import 'package:fitwiz/widgets/design_system/zealova.dart';

import '../../l10n/generated/app_localizations.dart';
/// Screen explaining how AI uses user data, what it sees and doesn't see,
/// and how data is protected.
class AIDataUsageScreen extends ConsumerWidget {
  const AIDataUsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(posthogServiceProvider).capture(eventName: 'ai_data_usage_viewed');
    final tc = ThemeColors.of(context);
    final backgroundColor =
        tc.isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: ZealovaAppBar(
        kicker: 'PRIVACY',
        title: AppLocalizations.of(context).aiPrivacyHowYourDataIs,
        titleSize: 24,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            ZealovaCard(
              variant: ZealovaCardVariant.hero,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.cardBorder),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: tc.accent,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).aiPrivacyHowYourDataIs,
                    textAlign: TextAlign.center,
                    style: ZType.disp(20, color: tc.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!
                        .aiDataUsageScreenSendsYourFitnessProfile(
                            Branding.appName),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: tc.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.05),

            const SizedBox(height: 24),

            // What the models receive
            _buildSection(
              context,
              icon: Icons.visibility_outlined,
              title: AppLocalizations.of(context).aiDataUsageWhatModelsReceive,
              subtitle:
                  AppLocalizations.of(context).aiDataUsageEverythingNeededToCoach,
              items: const [
                'Your fitness profile (age, height, weight, goals, equipment)',
                'Workout history (exercises, sets, reps, weights, RPE)',
                'Body metrics, injuries, and stated limitations',
                'Full chat messages you send to your coach',
                'Food photos you upload for calorie and macro estimation',
                'Exercise form videos you upload for technique feedback',
                'Your account ID (so your coach can retrieve your history and context)',
              ],
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

            const SizedBox(height: 16),

            // What never leaves
            _buildSection(
              context,
              icon: Icons.visibility_off_outlined,
              title: AppLocalizations.of(context).aiDataUsageWhatNeverLeavesOur,
              subtitle: AppLocalizations.of(context).aiDataUsageDataWeDoNot,
              items: const [
                'Your email address and full name',
                'Payment or billing information',
                'Device location and IP address',
                'Profile photos (unless you share one in chat)',
                'Social connections or friends',
                'Authentication credentials and tokens',
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

            const SizedBox(height: 16),

            // How Data is Protected
            _buildSection(
              context,
              icon: Icons.lock_outlined,
              title: AppLocalizations.of(context).aiDataUsageHowDataIsProtected,
              subtitle: AppLocalizations.of(context)
                  .aiDataUsageTechnicalSafeguardsInPlace,
              items: const [
                'TLS/HTTPS encryption for all data in transit',
                'Encryption at rest in our database',
                'Production traffic runs in zero-retention mode — your messages are not retained or used to train outside models',
                'Row-level security and signed tokens on every request',
                'Chat history retained up to 12 months, then auto-deleted',
                'You can clear chat history or delete your account at any time',
              ],
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),

            const SizedBox(height: 16),

            // Your Controls
            _buildSection(
              context,
              icon: Icons.tune,
              title: AppLocalizations.of(context).aiDataUsageYourControls,
              subtitle: AppLocalizations.of(context).aiDataUsageYouAreInCharge,
              items: const [
                'Toggle personalization on or off in Settings → Privacy',
                'When off, chats and photos stop being sent to the models',
                'Turn off "Save chat history" to stop storing transcripts',
                'Export all your data (JSON / CSV / Excel) from Settings',
                'Delete your account — personal data is removed within 30 days',
                'Revoke Health Connect / HealthKit permission anytime',
              ],
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> items,
  }) {
    final tc = ThemeColors.of(context);
    return ZealovaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: tc.textSecondary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ZType.lbl(14,
                          color: tc.textPrimary, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: tc.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: tc.accent.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          color: tc.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
