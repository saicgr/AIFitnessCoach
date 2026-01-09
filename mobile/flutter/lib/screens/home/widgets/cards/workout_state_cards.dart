import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../widgets/empty_state.dart';

/// Card shown when there are no workouts scheduled
class EmptyWorkoutCard extends StatelessWidget {
  /// Callback when the generate button is pressed
  final VoidCallback onGenerate;

  const EmptyWorkoutCard({
    super.key,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(20),
          border: Border(
            left: BorderSide(color: AppColors.teal, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large icon - simpler, no glow
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fitness_center,
                  size: 40,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(height: 16),
              // Heading
              Text(
                'Ready to Start?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              // Subtitle
              Text(
                'Get your personalized workout plan',
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // CTA Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onGenerate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for grid pattern background
class _GridPatternPainter extends CustomPainter {
  final Color color;

  _GridPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 30.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Card shown while workouts are being generated
class GeneratingWorkoutsCard extends StatelessWidget {
  /// Optional custom message
  final String? message;

  /// Optional custom subtitle
  final String? subtitle;

  const GeneratingWorkoutsCard({
    super.key,
    this.message,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message ?? 'Generating your workouts...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle ?? 'Your personalized workout plan is being created',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading card with skeleton placeholder
class LoadingCard extends StatelessWidget {
  const LoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SkeletonCard(
        height: 200,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

/// Error card with retry button
class ErrorCard extends StatelessWidget {
  /// Error message to display
  final String message;

  /// Callback when retry is pressed
  final VoidCallback onRetry;

  const ErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner shown when generating more workouts in the background
class MoreWorkoutsLoadingBanner extends StatelessWidget {
  /// Whether the current theme is dark
  final bool isDark;

  /// Start date for the workouts being generated
  final String startDate;

  /// Number of weeks being generated
  final int weeks;

  /// Total expected number of workouts
  final int totalExpected;

  /// Number of workouts generated so far
  final int totalGenerated;

  const MoreWorkoutsLoadingBanner({
    super.key,
    required this.isDark,
    required this.startDate,
    required this.weeks,
    this.totalExpected = 0,
    this.totalGenerated = 0,
  });

  String _formatDateRange() {
    final start = DateTime.parse(startDate);
    final end = start.add(Duration(days: weeks * 7));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final startMonth = months[start.month - 1];
    final endMonth = months[end.month - 1];

    if (start.month == end.month) {
      return '$startMonth ${start.day}-${end.day}';
    } else {
      return '$startMonth ${start.day} - $endMonth ${end.day}';
    }
  }

  String _formatMessage() {
    final dateRange = _formatDateRange();

    // If we have progress info, show it
    if (totalExpected > 0) {
      return 'Generating $totalGenerated of $totalExpected workouts ($dateRange)';
    }

    // Show week range
    return 'Generating $weeks weeks of workouts ($dateRange)';
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark
        ? AppColors.cyan.withOpacity(0.1)
        : AppColors.cyan.withOpacity(0.08);
    final borderColor = AppColors.cyan.withOpacity(0.3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _formatMessage(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColorsLight.textSecondary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Streaming workout generation card with animated progress
/// Shows real-time progress when generating workouts for first-time users
class StreamingWorkoutGenerationCard extends StatelessWidget {
  /// Whether the current theme is dark
  final bool isDark;

  /// Current workout number being generated
  final int currentWorkout;

  /// Total number of workouts to generate
  final int totalWorkouts;

  /// Status message
  final String message;

  /// Additional detail about current step
  final String? detail;

  const StreamingWorkoutGenerationCard({
    super.key,
    required this.isDark,
    required this.currentWorkout,
    required this.totalWorkouts,
    required this.message,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark
        ? AppColors.cyan.withOpacity(0.1)
        : AppColors.cyan.withOpacity(0.08);
    final borderColor = AppColors.cyan.withOpacity(0.3);
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final progress = totalWorkouts > 0 ? currentWorkout / totalWorkouts : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: AppColors.cyan,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Creating Your Workouts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'AI-powered personalized program',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress indicator
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            value: value > 0 ? value : null,
                            strokeWidth: 4,
                            backgroundColor: AppColors.cyan.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                          ),
                        ),
                        if (totalWorkouts > 0)
                          Text(
                            '$currentWorkout/$totalWorkouts',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.cyan,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Message with animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                message,
                key: ValueKey(message),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  detail!,
                  key: ValueKey(detail),
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Animated progress bar
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value > 0 ? value : null,
                    backgroundColor: AppColors.cyan.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                    minHeight: 6,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
