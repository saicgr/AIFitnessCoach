/// Form Comparison Result Card
///
/// Shows side-by-side form analysis comparison for multiple videos.
/// Displays per-video scores, improvements, regressions, and trends.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';

/// Card that displays a structured form comparison result from the AI.
class FormComparisonResultCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const FormComparisonResultCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;

    final videos = (data['videos'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final comparison = data['comparison'] as Map<String, dynamic>?;
    final recommendations = (data['recommendations'] as List?)?.cast<String>() ?? [];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(colors, isDark),

          // Score badges
          if (videos.isNotEmpty) _buildScoreBadges(colors, isDark, videos),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Divider(
              height: 1,
              color: isDark ? AppColors.cardBorder : Colors.grey.shade200,
            ),
          ),

          // Comparison sections
          if (comparison != null) ...[
            _buildComparisonSection(
              colors, isDark,
              label: 'Improved',
              icon: Icons.check_circle,
              color: AppColors.success,
              items: (comparison['improved'] as List?)?.cast<String>() ?? [],
            ),
            _buildComparisonSection(
              colors, isDark,
              label: 'Regressed',
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFFF9800),
              items: (comparison['regressed'] as List?)?.cast<String>() ?? [],
            ),
            _buildComparisonSection(
              colors, isDark,
              label: 'Consistent',
              icon: Icons.info_outline,
              color: AppColors.info,
              items: (comparison['consistent'] as List?)?.cast<String>() ?? [],
            ),

            // Overall trend
            _buildOverallTrend(colors, isDark, comparison),
          ],

          // Recommendations
          if (recommendations.isNotEmpty)
            _buildRecommendations(colors, recommendations),

          // Disclaimer
          _buildDisclaimer(colors),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.compare_rounded, size: 18, color: AppColors.purple),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Form Comparison',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'BETA',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.orange,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadges(ThemeColors colors, bool isDark, List<Map<String, dynamic>> videos) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: videos.map((video) {
            final label = video['label'] as String? ?? 'Video';
            final exercise = video['exercise'] as String? ?? '';
            final score = (video['form_score'] as num?)?.toDouble() ?? 0;
            final repCount = video['rep_count'] as int?;
            final scoreColor = _getScoreColor(score);

            return Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(isDark ? 0.08 : 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scoreColor.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Score circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scoreColor.withOpacity(0.15),
                      border: Border.all(color: scoreColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        score.toStringAsFixed(score == score.roundToDouble() ? 0 : 1),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Label
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),

                  // Exercise name
                  if (exercise.isNotEmpty)
                    Text(
                      exercise,
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.textMuted,
                      ),
                    ),

                  // Rep count
                  if (repCount != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '$repCount reps',
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildComparisonSection(
    ThemeColors colors,
    bool isDark, {
    required String label,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildOverallTrend(ThemeColors colors, bool isDark, Map<String, dynamic> comparison) {
    final trend = comparison['overall_trend'] as String?;
    if (trend == null || trend.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.trending_up, size: 16, color: colors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Trend',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  trend,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(ThemeColors colors, List<String> recommendations) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 14, color: colors.textMuted),
              const SizedBox(width: 6),
              Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...recommendations.map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Text(
        'AI form analysis is for educational purposes only. Consult a qualified trainer for personalized guidance.',
        style: TextStyle(
          fontSize: 10,
          fontStyle: FontStyle.italic,
          color: colors.textMuted,
          height: 1.3,
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 8) return AppColors.success;
    if (score >= 6) return const Color(0xFFFF9800);
    return AppColors.error;
  }
}
