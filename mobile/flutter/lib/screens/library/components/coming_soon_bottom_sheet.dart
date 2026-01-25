import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/branded_program.dart';

/// Bottom sheet that shows when user taps a "Coming Soon" program
class ComingSoonBottomSheet extends StatelessWidget {
  final BrandedProgram program;

  const ComingSoonBottomSheet({
    super.key,
    required this.program,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.cyan : AppColorsLight.cyan)
                    .withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                size: 48,
                color: isDark ? AppColors.cyan : AppColorsLight.cyan,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Program name
          Center(
            child: Text(
              program.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),

          // Duration info
          Center(
            child: Text(
              '${program.durationWeeks} weeks • ${program.sessionsPerWeek} sessions per week',
              style: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Coming soon message
          Text(
            'This program is coming soon! 🎉',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),

          // What to expect
          Text(
            'What you can expect:',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          _buildFeatureItem(
            icon: Icons.calendar_today,
            text: 'Complete ${program.durationWeeks}-week structured program',
            isDark: isDark,
          ),
          _buildFeatureItem(
            icon: Icons.video_library,
            text: 'Professional exercise demonstration videos',
            isDark: isDark,
          ),
          _buildFeatureItem(
            icon: Icons.description,
            text: 'Detailed form cues and instructions',
            isDark: isDark,
          ),
          _buildFeatureItem(
            icon: Icons.trending_up,
            text: 'Progress tracking and workout history',
            isDark: isDark,
          ),
          _buildFeatureItem(
            icon: Icons.timer,
            text: 'Built-in rest timer and exercise timer',
            isDark: isDark,
          ),

          const SizedBox(height: 32),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Got it!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.cyan : AppColorsLight.cyan,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
