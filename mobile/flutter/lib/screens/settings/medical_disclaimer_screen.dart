import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/glass_back_button.dart';

/// Screen displaying the medical disclaimer for AI-generated fitness content.
class MedicalDisclaimerScreen extends StatelessWidget {
  const MedicalDisclaimerScreen({super.key});

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
          'Medical Disclaimer',
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
            // Header warning
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.medical_information_outlined,
                      color: AppColors.warning,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Important Health Notice',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please read this disclaimer carefully before using FitWiz.',
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

            // Not Medical Advice
            _buildDisclaimerCard(
              icon: Icons.info_outlined,
              iconColor: AppColors.info,
              title: 'Not Medical Advice',
              content: 'FitWiz provides AI-generated fitness recommendations for informational and educational purposes only. The content provided by this app is not intended to be a substitute for professional medical advice, diagnosis, or treatment.',
              elevated: elevated,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

            const SizedBox(height: 16),

            // Consult Your Doctor
            _buildDisclaimerCard(
              icon: Icons.local_hospital_outlined,
              iconColor: AppColors.error,
              title: 'Consult Your Doctor',
              content: 'Always seek the advice of your physician or other qualified health provider before starting any new exercise program, especially if you have any pre-existing medical conditions, injuries, or health concerns. Never disregard professional medical advice or delay seeking it because of something you read in this app.',
              elevated: elevated,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

            const SizedBox(height: 16),

            // Listen to Your Body
            _buildDisclaimerCard(
              icon: Icons.monitor_heart_outlined,
              iconColor: AppColors.success,
              title: 'Listen to Your Body',
              content: 'Stop exercising immediately if you experience pain, dizziness, shortness of breath, nausea, or any discomfort beyond normal exertion. The AI cannot assess your physical condition in real-time, so it is your responsibility to exercise within your limits.',
              elevated: elevated,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),

            const SizedBox(height: 16),

            // AI Limitations
            _buildDisclaimerCard(
              icon: Icons.psychology_outlined,
              iconColor: AppColors.purple,
              title: 'AI Recommendations',
              content: 'Workout recommendations are generated based on the information you provide (fitness level, goals, equipment, etc.). While the AI strives for accuracy, it cannot account for all individual factors. Recommendations may not be suitable for everyone.',
              elevated: elevated,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05),

            const SizedBox(height: 16),

            // Assumption of Risk
            _buildDisclaimerCard(
              icon: Icons.warning_amber_outlined,
              iconColor: AppColors.warning,
              title: 'Assumption of Risk',
              content: 'Physical exercise involves inherent risks. By using FitWiz, you acknowledge that you are voluntarily participating in physical activities and assume all risks associated with such activities, including but not limited to injury, illness, or death.',
              elevated: elevated,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.05),

            const SizedBox(height: 24),

            // Footer
            Center(
              child: Text(
                'By continuing to use FitWiz, you acknowledge that you have read and understood this disclaimer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                  height: 1.5,
                ),
              ),
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    required Color elevated,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
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
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
