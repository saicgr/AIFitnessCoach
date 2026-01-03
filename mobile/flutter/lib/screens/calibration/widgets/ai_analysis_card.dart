import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/calibration.dart';

/// Card displaying AI analysis summary from calibration
class AIAnalysisCard extends StatelessWidget {
  final CalibrationAnalysis analysis;
  final bool isDark;

  const AIAnalysisCard({
    super.key,
    required this.analysis,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final success = isDark ? AppColors.success : AppColorsLight.success;
    final warning = isDark ? AppColors.warning : AppColorsLight.warning;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with AI icon
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cyan.withValues(alpha: 0.3),
                        purple.withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: cyan,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Analysis',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Confidence: ',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                          _buildConfidenceIndicator(
                            analysis.confidenceLevel,
                            isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (analysis.isConfident)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'High Confidence',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: success,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Summary text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              analysis.analysisSummary,
              style: TextStyle(
                fontSize: 15,
                color: textSecondary,
                height: 1.5,
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 20),

          // Fitness level comparison
          if (analysis.hasFitnessLevelMismatch ||
              analysis.statedFitnessLevel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildFitnessLevelComparison(
                statedLevel: analysis.statedFitnessLevel,
                detectedLevel: analysis.detectedFitnessLevel,
                levelsMatch: analysis.levelsMatch,
                isDark: isDark,
              ),
            ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(double confidence, bool isDark) {
    final percentage = (confidence * 100).toInt();
    Color color;
    if (confidence >= 0.8) {
      color = isDark ? AppColors.success : AppColorsLight.success;
    } else if (confidence >= 0.6) {
      color = isDark ? AppColors.warning : AppColorsLight.warning;
    } else {
      color = isDark ? AppColors.error : AppColorsLight.error;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 40,
          height: 4,
          child: LinearProgressIndicator(
            value: confidence,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildFitnessLevelComparison({
    required String statedLevel,
    required String detectedLevel,
    required bool levelsMatch,
    required bool isDark,
  }) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final success = isDark ? AppColors.success : AppColorsLight.success;
    final warning = isDark ? AppColors.warning : AppColorsLight.warning;

    // Double-check: if levels are actually the same string, they match regardless of backend flag
    final actuallyMatch = levelsMatch ||
        statedLevel.toLowerCase().trim() == detectedLevel.toLowerCase().trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (actuallyMatch ? success : warning).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (actuallyMatch ? success : warning).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildLevelBox(
                  label: 'You said',
                  level: statedLevel,
                  color: cyan,
                  isDark: isDark,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: actuallyMatch
                    ? Icon(
                        Icons.check_circle,
                        color: success,
                        size: 28,
                      )
                    : Column(
                        children: [
                          Icon(
                            Icons.compare_arrows,
                            color: warning,
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'vs',
                            style: TextStyle(
                              fontSize: 10,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
              Expanded(
                child: _buildLevelBox(
                  label: 'Performance suggests',
                  level: detectedLevel,
                  color: purple,
                  isDark: isDark,
                  isHighlighted: !actuallyMatch,
                ),
              ),
            ],
          ),
          if (!actuallyMatch) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your performance indicates a different fitness level than selected',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your performance matches your selected fitness level',
                    style: TextStyle(
                      fontSize: 12,
                      color: success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelBox({
    required String label,
    required String level,
    required Color color,
    required bool isDark,
    bool isHighlighted = false,
  }) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isHighlighted ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted
            ? Border.all(color: color.withValues(alpha: 0.5), width: 2)
            : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _formatFitnessLevel(level),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatFitnessLevel(String level) {
    if (level.isEmpty) return 'Unknown';
    return level[0].toUpperCase() + level.substring(1).toLowerCase();
  }
}
