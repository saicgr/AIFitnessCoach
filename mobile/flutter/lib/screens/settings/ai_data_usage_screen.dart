import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/pill_app_bar.dart';

/// Screen explaining how AI uses user data, what it sees and doesn't see,
/// and how data is protected.
class AIDataUsageScreen extends ConsumerWidget {
  const AIDataUsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(posthogServiceProvider).capture(eventName: 'ai_data_usage_viewed');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const PillAppBar(
        title: 'How Your Data Is Used',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: AppColors.info,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'How Your Data Is Used',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'FitWiz sends your fitness profile, chats, food photos, and form videos to models that generate personalized guidance. Here is exactly what happens.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
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
              iconColor: AppColors.success,
              title: 'What Models Receive',
              subtitle: 'Everything needed to coach you',
              items: const [
                'Your fitness profile (age, height, weight, goals, equipment)',
                'Workout history (exercises, sets, reps, weights, RPE)',
                'Body metrics, injuries, and stated limitations',
                'Full chat messages you send to your coach',
                'Food photos you upload for calorie and macro estimation',
                'Exercise form videos you upload for technique feedback',
                'Your account ID (so your coach can retrieve your history and context)',
              ],
              elevated: elevated,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

            const SizedBox(height: 16),

            // What never leaves
            _buildSection(
              context,
              icon: Icons.visibility_off_outlined,
              iconColor: AppColors.error,
              title: 'What Never Leaves Our Servers',
              subtitle: 'Data we do not share with the models',
              items: const [
                'Your email address and full name',
                'Payment or billing information',
                'Device location and IP address',
                'Profile photos (unless you share one in chat)',
                'Social connections or friends',
                'Authentication credentials and tokens',
              ],
              elevated: elevated,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

            const SizedBox(height: 16),

            // How Data is Protected
            _buildSection(
              context,
              icon: Icons.lock_outlined,
              iconColor: AppColors.info,
              title: 'How Data is Protected',
              subtitle: 'Technical safeguards in place',
              items: const [
                'TLS/HTTPS encryption for all data in transit',
                'Encryption at rest in our database',
                'Production traffic runs in zero-retention mode — your messages are not retained or used to train outside models',
                'Row-level security and signed tokens on every request',
                'Chat history retained up to 12 months, then auto-deleted',
                'You can clear chat history or delete your account at any time',
              ],
              elevated: elevated,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),

            const SizedBox(height: 16),

            // Your Controls
            _buildSection(
              context,
              icon: Icons.tune,
              iconColor: AppColors.purple,
              title: 'Your Controls',
              subtitle: 'You are in charge of your data',
              items: const [
                'Toggle personalization on or off in Settings → Privacy',
                'When off, chats and photos stop being sent to the models',
                'Turn off "Save chat history" to stop storing transcripts',
                'Export all your data (JSON / CSV / Excel) from Settings',
                'Delete your account — personal data is removed within 30 days',
                'Revoke Health Connect / HealthKit permission anytime',
              ],
              elevated: elevated,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
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
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<String> items,
    required Color elevated,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
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
                        color: iconColor.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
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
