import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/context_logging_service.dart';

/// Calibration Intro Screen
/// Shown before the calibration workout to explain the purpose and process
class CalibrationIntroScreen extends ConsumerStatefulWidget {
  /// Whether this is from onboarding flow (shows skip option) or settings (shows back)
  final bool fromOnboarding;

  const CalibrationIntroScreen({
    super.key,
    this.fromOnboarding = false,
  });

  @override
  ConsumerState<CalibrationIntroScreen> createState() => _CalibrationIntroScreenState();
}

class _CalibrationIntroScreenState extends ConsumerState<CalibrationIntroScreen> {
  void _startCalibration() {
    HapticFeedback.mediumImpact();
    context.push('/calibration/workout', extra: {'fromOnboarding': widget.fromOnboarding});
  }

  void _skipCalibration() {
    HapticFeedback.lightImpact();

    // Log the skip event
    ref.read(contextLoggingServiceProvider).logCalibrationSkipped();

    // Navigate to workout loading (paywall is already completed if fromOnboarding)
    if (widget.fromOnboarding) {
      context.go('/workout-loading');
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (!widget.fromOnboarding)
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: textSecondary,
                        size: 20,
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.purple.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, color: AppColors.purple, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '15 min',
                          style: TextStyle(
                            color: AppColors.purple,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),

                    // Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.purple,
                            AppColors.electricBlue,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withOpacity(0.4),
                            blurRadius: 24,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.assessment_outlined,
                        color: Colors.white,
                        size: 48,
                      ),
                    ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.8, 0.8)),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Calibration Workout',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'Get more accurate workouts by testing your current fitness level',
                      style: TextStyle(
                        fontSize: 16,
                        color: textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                    const SizedBox(height: 32),

                    // What to expect card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
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
                                  color: AppColors.cyan.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.checklist_outlined,
                                  color: AppColors.cyan,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'What to Expect',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildExpectationItem(
                            isDark: isDark,
                            icon: Icons.fitness_center,
                            title: '3-4 Basic Exercises',
                            subtitle: 'Push-ups, squats, and core work',
                          ),
                          const SizedBox(height: 12),
                          _buildExpectationItem(
                            isDark: isDark,
                            icon: Icons.timer_outlined,
                            title: 'About 15 Minutes',
                            subtitle: 'Quick but comprehensive',
                          ),
                          const SizedBox(height: 12),
                          _buildExpectationItem(
                            isDark: isDark,
                            icon: Icons.trending_up,
                            title: 'Max Rep Tests',
                            subtitle: 'Find your true capacity',
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

                    const SizedBox(height: 20),

                    // Benefits card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.purple.withOpacity(0.1),
                            AppColors.electricBlue.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.purple.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: AppColors.purple,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Why Calibrate?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.purple,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Calibration helps the AI understand your exact starting point, so every workout is perfectly matched to your ability - not too easy, not too hard.',
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Container(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(
                  top: BorderSide(color: cardBorder.withOpacity(0.5)),
                ),
              ),
              child: Row(
                children: [
                  // Skip button (only in onboarding)
                  if (widget.fromOnboarding)
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 56,
                        child: TextButton(
                          onPressed: _skipCalibration,
                          style: TextButton.styleFrom(
                            foregroundColor: textMuted,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Skip for now',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 350.ms),
                    ),
                  if (widget.fromOnboarding) const SizedBox(width: 12),
                  // Start button
                  Expanded(
                    flex: widget.fromOnboarding ? 5 : 1,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _startCalibration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: AppColors.purple.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow_rounded, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Start Calibration',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpectationItem({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.cyan,
          size: 20,
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
                  fontSize: 12,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
