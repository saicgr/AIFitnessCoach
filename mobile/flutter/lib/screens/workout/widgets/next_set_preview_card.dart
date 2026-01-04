/// Next Set Preview Card Widget
///
/// Displays AI-recommended weight and reps for the upcoming set
/// during rest periods. Features glassmorphic styling and
/// integrates with the workout's 1RM and intensity data.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';

/// Data class for next set preview from the backend
class NextSetPreviewData {
  final double recommendedWeight;
  final int recommendedReps;
  final double intensityPercentage;
  final String reasoning;
  final double confidence;
  final bool isFinalSet;

  const NextSetPreviewData({
    required this.recommendedWeight,
    required this.recommendedReps,
    required this.intensityPercentage,
    required this.reasoning,
    required this.confidence,
    required this.isFinalSet,
  });

  factory NextSetPreviewData.fromJson(Map<String, dynamic> json) {
    return NextSetPreviewData(
      recommendedWeight:
          (json['recommended_weight'] as num?)?.toDouble() ?? 0.0,
      recommendedReps: json['recommended_reps'] as int? ?? 10,
      intensityPercentage:
          (json['intensity_percentage'] as num?)?.toDouble() ?? 75.0,
      reasoning: json['reasoning'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.75,
      isFinalSet: json['is_final_set'] as bool? ?? false,
    );
  }

  /// Whether there's a weight change from current
  bool hasWeightChange(double currentWeight) {
    return (recommendedWeight - currentWeight).abs() > 0.1;
  }

  /// Get the weight delta
  double getWeightDelta(double currentWeight) {
    return recommendedWeight - currentWeight;
  }
}

/// Glassmorphic card showing AI-recommended parameters for the next set
class NextSetPreviewCard extends StatelessWidget {
  /// The preview data from the backend
  final NextSetPreviewData previewData;

  /// Current weight being used
  final double currentWeight;

  /// Current target reps
  final int currentReps;

  /// Current set number (1-indexed)
  final int currentSetNumber;

  /// Total sets in the exercise
  final int totalSets;

  /// Callback when user accepts the recommendation
  final VoidCallback? onUseThis;

  /// Callback to dismiss the preview
  final VoidCallback? onDismiss;

  /// Whether this card is compact (for smaller rest overlays)
  final bool isCompact;

  const NextSetPreviewCard({
    super.key,
    required this.previewData,
    required this.currentWeight,
    required this.currentReps,
    required this.currentSetNumber,
    required this.totalSets,
    this.onUseThis,
    this.onDismiss,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    return ClipRRect(
      borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.04),
                    ]
                  : [
                      AppColorsLight.elevated.withValues(alpha: 0.9),
                      AppColorsLight.elevated.withValues(alpha: 0.7),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
            border: Border.all(
              color: AppColors.glowCyan.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.glowCyan.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: isCompact
              ? _buildCompactContent(isDark, isSmallScreen)
              : _buildFullContent(isDark, isSmallScreen),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms);
  }

  Widget _buildCompactContent(bool isDark, bool isSmallScreen) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final hasChange = previewData.hasWeightChange(currentWeight);
    final weightDelta = previewData.getWeightDelta(currentWeight);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // AI Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.glowCyan.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.glowCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'NEXT SET',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.glowCyan,
                        letterSpacing: 1,
                      ),
                    ),
                    if (previewData.isFinalSet) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'FINAL',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.purple,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${previewData.recommendedWeight.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    if (hasChange) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: weightDelta > 0
                              ? AppColors.success.withValues(alpha: 0.2)
                              : AppColors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${weightDelta > 0 ? '+' : ''}${weightDelta.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: weightDelta > 0
                                ? AppColors.success
                                : AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      'x ${previewData.recommendedReps}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Use This button
          if (onUseThis != null)
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onUseThis!();
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.glowCyan.withValues(alpha: 0.2),
                foregroundColor: AppColors.glowCyan,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Use',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFullContent(bool isDark, bool isSmallScreen) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final hasChange = previewData.hasWeightChange(currentWeight);
    final weightDelta = previewData.getWeightDelta(currentWeight);

    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.glowCyan.withValues(alpha: 0.3),
                      AppColors.glowPurple.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.glowCyan,
                  size: isSmallScreen ? 22 : 26,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(
                    duration: 2000.ms,
                    color: AppColors.glowCyan.withValues(alpha: 0.3),
                  ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'AI RECOMMENDATION',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.glowCyan,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${(previewData.confidence * 100).round()}%',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Set ${currentSetNumber + 1} of $totalSets${previewData.isFinalSet ? ' (Final)' : ''}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(
                    Icons.close,
                    color: textMuted,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
            ],
          ),

          SizedBox(height: isSmallScreen ? 16 : 20),

          // Weight and Reps display
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // Weight section
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            previewData.recommendedWeight.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 32 : 38,
                              fontWeight: FontWeight.bold,
                              color: AppColors.glowCyan,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              ' kg',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (hasChange) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: weightDelta > 0
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                weightDelta > 0
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                size: 14,
                                color: weightDelta > 0
                                    ? AppColors.success
                                    : AppColors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${weightDelta > 0 ? '+' : ''}${weightDelta.toStringAsFixed(1)} kg',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: weightDelta > 0
                                      ? AppColors.success
                                      : AppColors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Divider
                Container(
                  width: 1,
                  height: 50,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                ),
                // Reps section
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${previewData.recommendedReps}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 32 : 38,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              ' reps',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${previewData.intensityPercentage.toStringAsFixed(0)}% intensity',
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
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Reasoning
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.purple.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: AppColors.purple,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    previewData.reasoning,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isSmallScreen ? 14 : 18),

          // Action button
          if (onUseThis != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onUseThis!();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.glowCyan,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 14 : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check, size: 20),
                label: Text(
                  'Use This',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms)
                .shimmer(
                  delay: 600.ms,
                  duration: 1000.ms,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
        ],
      ),
    );
  }
}

/// Loading state placeholder for next set preview
class NextSetPreviewLoading extends StatelessWidget {
  final bool isCompact;

  const NextSetPreviewLoading({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 16 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.04),
                    ]
                  : [
                      AppColorsLight.elevated.withValues(alpha: 0.9),
                      AppColorsLight.elevated.withValues(alpha: 0.7),
                    ],
            ),
            borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
            border: Border.all(
              color: AppColors.glowCyan.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.glowCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.glowCyan,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ANALYZING PERFORMANCE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.glowCyan,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Calculating optimal next set...',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColorsLight.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}
