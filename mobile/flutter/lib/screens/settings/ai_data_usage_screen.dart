import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/glass_back_button.dart';

/// Screen explaining how AI uses user data, what it sees and doesn't see,
/// and how data is protected.
class AIDataUsageScreen extends StatelessWidget {
  const AIDataUsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: Text(
          'How AI Uses Your Data',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
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
                    'Your Privacy Matters',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We anonymize your data before any AI processing. Here\'s exactly what happens with your information.',
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

            // What AI Sees
            _buildSection(
              context,
              icon: Icons.visibility_outlined,
              iconColor: AppColors.success,
              title: 'What AI Sees',
              subtitle: 'Anonymized fitness data only',
              items: const [
                'Fitness level (beginner, intermediate, advanced)',
                'Workout goals (build muscle, lose weight, etc.)',
                'Available equipment',
                'Workout history (exercises, sets, reps, weights)',
                'Body metrics (height range, weight range)',
                'Exercise preferences and limitations',
              ],
              elevated: elevated,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

            const SizedBox(height: 16),

            // What AI Never Sees
            _buildSection(
              context,
              icon: Icons.visibility_off_outlined,
              iconColor: AppColors.error,
              title: 'What AI Never Sees',
              subtitle: 'Personal identifiers are stripped',
              items: const [
                'Your name or display name',
                'Email address',
                'Exact date of birth (only age range)',
                'Location or IP address',
                'Payment or billing information',
                'Photos or profile images',
                'Social connections or friends',
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
              subtitle: 'Multiple layers of protection',
              items: const [
                'Data is anonymized before AI processing',
                'No personal data is stored by the AI provider',
                'Real-time processing only - no data retention',
                'Encrypted connections for all data transfer',
                'Regular security audits and updates',
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
                'Toggle AI data processing on/off anytime',
                'Request full data deletion from Settings > Account',
                'Export your data in portable format',
                'Review and modify stored preferences',
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
