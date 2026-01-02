import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Progress indicator showing current exercise position in calibration workout
class CalibrationProgressIndicator extends StatelessWidget {
  /// Current exercise index (0-based)
  final int currentIndex;

  /// Total number of exercises
  final int totalCount;

  /// Number of completed exercises
  final int completedExercises;

  /// Whether to show detailed progress with dots
  final bool showDots;

  const CalibrationProgressIndicator({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    this.completedExercises = 0,
    this.showDots = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Calculate progress percentage
    final progress = totalCount > 0 ? (currentIndex + 1) / totalCount : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with exercise count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Exercise ${currentIndex + 1} of $totalCount',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purple,
                      ),
                    ),
                  ),
                  if (completedExercises > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check,
                            size: 12,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$completedExercises done',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cyan,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                // Background track
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: cardBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Progress fill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: 6,
                  width: MediaQuery.of(context).size.width * progress - 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.cyan, AppColors.purple],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),

          // Progress dots (optional)
          if (showDots && totalCount <= 10) ...[
            const SizedBox(height: 12),
            _buildProgressDots(isDark, cardBorder),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressDots(bool isDark, Color cardBorder) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalCount, (index) {
        final isCompleted = index < currentIndex;
        final isCurrent = index == currentIndex;
        final isUpcoming = index > currentIndex;

        Color dotColor;
        double size;
        if (isCurrent) {
          dotColor = AppColors.cyan;
          size = 10;
        } else if (isCompleted) {
          dotColor = AppColors.success;
          size = 8;
        } else {
          dotColor = cardBorder;
          size = 8;
        }

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: totalCount > 6 ? 3 : 5,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isCurrent ? dotColor : dotColor.withOpacity(0.8),
              shape: BoxShape.circle,
              border: isCurrent
                  ? Border.all(color: AppColors.cyan.withOpacity(0.3), width: 2)
                  : null,
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: AppColors.cyan.withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isCompleted
                ? Center(
                    child: Icon(
                      Icons.check,
                      size: 6,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        );
      }),
    );
  }
}

/// Compact progress indicator for limited space
class CalibrationProgressCompact extends StatelessWidget {
  final int currentIndex;
  final int totalCount;

  const CalibrationProgressCompact({
    super.key,
    required this.currentIndex,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fitness_center,
            size: 14,
            color: AppColors.purple,
          ),
          const SizedBox(width: 6),
          Text(
            '${currentIndex + 1}/$totalCount',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.purple,
            ),
          ),
        ],
      ),
    );
  }
}
