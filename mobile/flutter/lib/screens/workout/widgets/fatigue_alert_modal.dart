/// Fatigue Alert Modal Widget
///
/// Displays a warning modal when fatigue is detected during a workout.
/// Shows performance decline summary with options to accept weight
/// reduction or continue as planned.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';

/// Severity level of fatigue detection
enum FatigueSeverity {
  none,
  low,
  moderate,
  high,
  critical,
}

/// Data class representing a fatigue alert from the backend
class FatigueAlertData {
  final bool fatigueDetected;
  final FatigueSeverity severity;
  final int suggestedWeightReduction;
  final double suggestedWeight;
  final String reasoning;
  final List<String> indicators;
  final double confidence;

  const FatigueAlertData({
    required this.fatigueDetected,
    required this.severity,
    required this.suggestedWeightReduction,
    required this.suggestedWeight,
    required this.reasoning,
    required this.indicators,
    required this.confidence,
  });

  factory FatigueAlertData.fromJson(Map<String, dynamic> json) {
    return FatigueAlertData(
      fatigueDetected: json['fatigue_detected'] as bool? ?? false,
      severity: _parseSeverity(json['severity'] as String?),
      suggestedWeightReduction: json['suggested_weight_reduction'] as int? ?? 0,
      suggestedWeight: (json['suggested_weight'] as num?)?.toDouble() ?? 0.0,
      reasoning: json['reasoning'] as String? ?? '',
      indicators: (json['indicators'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static FatigueSeverity _parseSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return FatigueSeverity.critical;
      case 'high':
        return FatigueSeverity.high;
      case 'moderate':
        return FatigueSeverity.moderate;
      case 'low':
        return FatigueSeverity.low;
      default:
        return FatigueSeverity.none;
    }
  }

  /// Get severity color
  Color get severityColor {
    switch (severity) {
      case FatigueSeverity.critical:
        return AppColors.error;
      case FatigueSeverity.high:
        return AppColors.coral;
      case FatigueSeverity.moderate:
        return AppColors.orange;
      case FatigueSeverity.low:
        return AppColors.warning;
      case FatigueSeverity.none:
        return AppColors.success;
    }
  }

  /// Get severity label
  String get severityLabel {
    switch (severity) {
      case FatigueSeverity.critical:
        return 'CRITICAL';
      case FatigueSeverity.high:
        return 'HIGH';
      case FatigueSeverity.moderate:
        return 'MODERATE';
      case FatigueSeverity.low:
        return 'LOW';
      case FatigueSeverity.none:
        return 'NONE';
    }
  }

  /// Get severity icon
  IconData get severityIcon {
    switch (severity) {
      case FatigueSeverity.critical:
        return Icons.error;
      case FatigueSeverity.high:
        return Icons.warning_amber;
      case FatigueSeverity.moderate:
        return Icons.info_outline;
      case FatigueSeverity.low:
        return Icons.lightbulb_outline;
      case FatigueSeverity.none:
        return Icons.check_circle_outline;
    }
  }
}

/// Modal widget for displaying fatigue alerts during active workouts
class FatigueAlertModal extends StatelessWidget {
  /// The fatigue alert data to display
  final FatigueAlertData alertData;

  /// Current weight being used
  final double currentWeight;

  /// Exercise name
  final String exerciseName;

  /// Callback when user accepts the weight reduction suggestion
  final VoidCallback onAcceptSuggestion;

  /// Callback when user chooses to continue with current weight
  final VoidCallback onContinueAsPlanned;

  /// Optional callback when user wants to stop the exercise
  final VoidCallback? onStopExercise;

  const FatigueAlertModal({
    super.key,
    required this.alertData,
    required this.currentWeight,
    required this.exerciseName,
    required this.onAcceptSuggestion,
    required this.onContinueAsPlanned,
    this.onStopExercise,
  });

  @override
  Widget build(BuildContext context) {
    // Heavy haptic feedback when modal appears
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.mediumImpact();
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700 || screenWidth < 380;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 24,
              vertical: isSmallScreen ? 24 : 40,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: screenHeight * 0.85,
              ),
              child: SingleChildScrollView(
                child: _buildAlertCard(context, isDark, isSmallScreen),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, bool isDark, bool isSmallScreen) {
    final severityColor = alertData.severityColor;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: severityColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: severityColor.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with severity indicator
          _buildHeader(severityColor, textPrimary, isSmallScreen),

          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Performance summary
                _buildPerformanceSummary(
                  textPrimary,
                  textSecondary,
                  severityColor,
                  isSmallScreen,
                ),

                SizedBox(height: isSmallScreen ? 16 : 24),

                // Indicators list
                if (alertData.indicators.isNotEmpty) ...[
                  _buildIndicatorsList(
                    textPrimary,
                    textMuted,
                    severityColor,
                    isSmallScreen,
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                ],

                // Weight suggestion
                _buildWeightSuggestion(
                  isDark,
                  textPrimary,
                  textSecondary,
                  textMuted,
                  severityColor,
                  isSmallScreen,
                ),

                SizedBox(height: isSmallScreen ? 20 : 28),

                // Action buttons
                _buildActionButtons(context, isDark, isSmallScreen),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0));
  }

  Widget _buildHeader(Color severityColor, Color textPrimary, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            severityColor.withValues(alpha: 0.3),
            severityColor.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Row(
        children: [
          // Animated icon
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              alertData.severityIcon,
              color: severityColor,
              size: isSmallScreen ? 24 : 28,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
                duration: 800.ms,
              ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FATIGUE DETECTED',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 11,
                    fontWeight: FontWeight.w700,
                    color: severityColor,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${alertData.severityLabel} Alert',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Confidence badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${(alertData.confidence * 100).round()}%',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: severityColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSummary(
    Color textPrimary,
    Color textSecondary,
    Color severityColor,
    bool isSmallScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exerciseName,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 15,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: severityColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: severityColor.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            alertData.reasoning,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 15,
              color: textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicatorsList(
    Color textPrimary,
    Color textMuted,
    Color severityColor,
    bool isSmallScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DETECTED ISSUES',
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 11,
            fontWeight: FontWeight.w600,
            color: textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: alertData.indicators.map((indicator) {
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 10 : 12,
                vertical: isSmallScreen ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getIndicatorIcon(indicator),
                    size: isSmallScreen ? 14 : 16,
                    color: severityColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatIndicator(indicator),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      fontWeight: FontWeight.w500,
                      color: severityColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWeightSuggestion(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color severityColor,
    bool isSmallScreen,
  ) {
    final weightDiff = currentWeight - alertData.suggestedWeight;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.fitness_center,
                color: AppColors.cyan,
                size: isSmallScreen ? 20 : 24,
              ),
              const SizedBox(width: 10),
              Text(
                'SUGGESTED ADJUSTMENT',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cyan,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Current weight
              Column(
                children: [
                  Text(
                    currentWeight.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 22 : 26,
                      fontWeight: FontWeight.bold,
                      color: textMuted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  Text(
                    'kg',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      color: AppColors.cyan,
                      size: isSmallScreen ? 24 : 28,
                    ),
                    Text(
                      '-${weightDiff.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: severityColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Suggested weight
              Column(
                children: [
                  Text(
                    alertData.suggestedWeight.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 28 : 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cyan,
                    ),
                  ),
                  Text(
                    'kg',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            '${alertData.suggestedWeightReduction}% reduction',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 13,
              color: textSecondary,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 300.ms)
        .shimmer(
          delay: 500.ms,
          duration: 1000.ms,
          color: AppColors.cyan.withValues(alpha: 0.2),
        );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark, bool isSmallScreen) {
    final isCritical = alertData.severity == FatigueSeverity.critical;

    return Column(
      children: [
        // Primary action - Accept suggestion
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              onAcceptSuggestion();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
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
              'Accept Suggestion',
              style: TextStyle(
                fontSize: isSmallScreen ? 15 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        SizedBox(height: isSmallScreen ? 10 : 12),

        // Secondary action - Continue as planned
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onContinueAsPlanned();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark
                  ? AppColors.textSecondary
                  : AppColorsLight.textSecondary,
              side: BorderSide(
                color: isDark
                    ? AppColors.cardBorder
                    : AppColorsLight.cardBorder,
              ),
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 14 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Continue as Planned',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Stop exercise button (only for critical)
        if (isCritical && onStopExercise != null) ...[
          SizedBox(height: isSmallScreen ? 10 : 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.heavyImpact();
                onStopExercise!();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 14 : 16,
                ),
              ),
              icon: const Icon(Icons.stop_circle_outlined, size: 20),
              label: Text(
                'Stop Exercise',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  IconData _getIndicatorIcon(String indicator) {
    switch (indicator.toLowerCase()) {
      case 'rep_decline':
      case 'severe_rep_decline':
        return Icons.trending_down;
      case 'rpe_spike':
      case 'sustained_high_rpe':
        return Icons.speed;
      case 'failed_set':
        return Icons.cancel_outlined;
      case 'weight_reduced':
        return Icons.fitness_center;
      case 'high_effort_rir':
        return Icons.battery_alert;
      default:
        return Icons.warning_amber;
    }
  }

  String _formatIndicator(String indicator) {
    switch (indicator.toLowerCase()) {
      case 'rep_decline':
        return 'Rep Decline';
      case 'severe_rep_decline':
        return 'Severe Rep Decline';
      case 'rpe_spike':
        return 'RPE Spike';
      case 'sustained_high_rpe':
        return 'High RPE';
      case 'failed_set':
        return 'Failed Set';
      case 'weight_reduced':
        return 'Weight Reduced';
      case 'high_effort_rir':
        return 'Low Reserve';
      default:
        return indicator.replaceAll('_', ' ').toUpperCase();
    }
  }
}

/// Helper function to show the fatigue alert modal
Future<void> showFatigueAlertModal({
  required BuildContext context,
  required FatigueAlertData alertData,
  required double currentWeight,
  required String exerciseName,
  required VoidCallback onAcceptSuggestion,
  required VoidCallback onContinueAsPlanned,
  VoidCallback? onStopExercise,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    builder: (context) => FatigueAlertModal(
      alertData: alertData,
      currentWeight: currentWeight,
      exerciseName: exerciseName,
      onAcceptSuggestion: () {
        Navigator.of(context).pop();
        onAcceptSuggestion();
      },
      onContinueAsPlanned: () {
        Navigator.of(context).pop();
        onContinueAsPlanned();
      },
      onStopExercise: onStopExercise != null
          ? () {
              Navigator.of(context).pop();
              onStopExercise();
            }
          : null,
    ),
  );
}
