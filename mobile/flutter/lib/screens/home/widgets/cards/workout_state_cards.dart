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
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          children: [
            Icon(
              Icons.fitness_center,
              size: 48,
              color: textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No workouts scheduled',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Complete setup to get your personalized workout plan',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onGenerate,
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
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
            TextButton(
              onPressed: onRetry,
              child: const Text('Try Again'),
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
