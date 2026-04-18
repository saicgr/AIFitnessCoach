part of 'plan_preview_screen.dart';

/// Methods extracted from PlanPreviewScreen
extension _PlanPreviewScreenExt on PlanPreviewScreen {

  /// Show bottom sheet explaining personalization options
  void _showPersonalizeInfoBottomSheet(BuildContext context, bool isDark) {
    final t = OnboardingTheme.of(context);
    final textPrimary = t.textPrimary;
    final textSecondary = t.textSecondary;

    HapticFeedback.lightImpact();

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with tune icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.onboardingAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.onboardingAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Personalization',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // Explanation text
            Text(
              'Take 2 minutes to fine-tune your plan:',
              style: TextStyle(
                fontSize: 15,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Features list
            _buildInfoItem(
              icon: Icons.fitness_center,
              title: 'Muscle Targeting',
              description: 'Prioritize specific muscle groups (triceps, lats, etc.)',
              t: t,
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.view_week_rounded,
              title: 'Training Style',
              description: 'Choose PPL, Upper/Lower, Full Body, or let AI decide',
              t: t,
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.speed_rounded,
              title: 'Progression Pace',
              description: 'Set how quickly you want to increase difficulty',
              t: t,
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.health_and_safety_outlined,
              title: 'Limitations',
              description: 'Flag any injuries or joint issues to work around',
              t: t,
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textSecondary,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Maybe later',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop();
                        onContinue(); // Trigger personalization flow
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.onboardingAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Personalize',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
          ),
        ),
      ),
    );
  }

}
