/// Form Check Result Card
///
/// Renders the AI's form analysis result inside an assistant chat bubble.
/// Shows exercise name, overall score, rep count, safety warnings,
/// strengths, and areas to improve.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';

/// Card that displays a structured form check result from the AI.
class FormCheckResultCard extends StatefulWidget {
  final Map<String, dynamic> result;

  const FormCheckResultCard({super.key, required this.result});

  @override
  State<FormCheckResultCard> createState() => _FormCheckResultCardState();
}

class _FormCheckResultCardState extends State<FormCheckResultCard> {
  bool _isExpanded = false;

  // How many items to show before collapsing
  static const _collapsedItemCount = 3;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;

    // Check if this is a non-exercise video
    final contentType = widget.result['content_type'] as String? ?? 'exercise';
    if (contentType == 'not_exercise') {
      return _buildNotExerciseCard(colors, isDark);
    }

    final exerciseName = widget.result['exercise_name'] as String?
        ?? widget.result['exercise_identified'] as String?
        ?? 'Exercise';
    final score = (widget.result['overall_score'] as num?)?.toDouble()
        ?? (widget.result['form_score'] as num?)?.toDouble()
        ?? 0;
    final repCount = widget.result['rep_count'] as int?;
    final safetyWarning = widget.result['safety_warning'] as String?;
    final strengths = (widget.result['strengths'] as List<dynamic>?)?.cast<String>()
        ?? (widget.result['positives'] as List<dynamic>?)?.cast<String>()
        ?? [];
    final improvements = (widget.result['areas_to_improve'] as List<dynamic>?)
        ?? (widget.result['issues'] as List<dynamic>?)
        ?? [];
    final breathingAnalysis = widget.result['breathing_analysis'] as Map<String, dynamic>?;
    final tempoAnalysis = widget.result['tempo_analysis'] as Map<String, dynamic>?;
    final videoQuality = widget.result['video_quality'] as Map<String, dynamic>?;

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
          // Header: exercise name + score + BETA badge
          _buildHeader(colors, isDark, exerciseName, score),

          // Rep count
          if (repCount != null)
            _buildRepCount(colors, repCount),

          // Safety warning
          if (safetyWarning != null && safetyWarning.isNotEmpty)
            _buildSafetyWarning(colors, isDark, safetyWarning),

          // Strengths
          if (strengths.isNotEmpty)
            _buildStrengths(colors, isDark, strengths),

          // Areas to improve
          if (improvements.isNotEmpty)
            _buildImprovements(colors, isDark, improvements),

          // Breathing analysis
          if (breathingAnalysis != null)
            _buildBreathingAnalysis(colors, isDark, breathingAnalysis),

          // Tempo analysis
          if (tempoAnalysis != null)
            _buildTempoAnalysis(colors, isDark, tempoAnalysis),

          // Video quality / re-record suggestion
          if (videoQuality != null && videoQuality['confidence'] != 'high')
            _buildVideoQuality(colors, isDark, videoQuality),

          // Disclaimer footer
          _buildDisclaimer(colors),
        ],
      ),
    );
  }

  Widget _buildNotExerciseCard(ThemeColors colors, bool isDark) {
    final reason = widget.result['not_exercise_reason'] as String?
        ?? "I couldn't identify an exercise in this video. Try sending a video of your workout and I'll analyze your form!";

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
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
          Row(
            children: [
              Icon(Icons.videocam_outlined, size: 18, color: colors.textMuted),
              const SizedBox(width: 8),
              Text(
                'Form Check',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
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
          const SizedBox(height: 10),
          Text(
            reason,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Send a video of your exercise and I\'ll check your form, count reps, and give corrections.',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: colors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors, bool isDark, String exerciseName, double score) {
    final scoreColor = _getScoreColor(score);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          // Exercise name
          Expanded(
            child: Text(
              exerciseName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),

          // BETA chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(right: 8),
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

          // Score badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scoreColor.withOpacity(0.3)),
            ),
            child: Text(
              '${score.toStringAsFixed(1)}/10',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepCount(ThemeColors colors, int repCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(Icons.repeat, size: 14, color: colors.textMuted),
          const SizedBox(width: 6),
          Text(
            '~$repCount estimated reps',
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyWarning(ThemeColors colors, bool isDark, String warning) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(isDark ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              warning,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.error,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengths(ThemeColors colors, bool isDark, List<String> strengths) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, size: 14, color: AppColors.success),
              const SizedBox(width: 6),
              Text(
                'Doing Well',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...strengths.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.check, size: 12, color: AppColors.success),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s,
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

  Widget _buildImprovements(ThemeColors colors, bool isDark, List<dynamic> improvements) {
    final visible = _isExpanded || improvements.length <= _collapsedItemCount
        ? improvements
        : improvements.take(_collapsedItemCount).toList();
    final hasMore = improvements.length > _collapsedItemCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, size: 14, color: AppColors.warning),
              const SizedBox(width: 6),
              Text(
                'Areas to Improve',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...visible.map((item) {
            final Map<String, dynamic> improvement = item is Map<String, dynamic>
                ? item
                : {'description': item.toString(), 'severity': 'medium'};
            return _buildImprovementCard(colors, isDark, improvement);
          }),
          if (hasMore && !_isExpanded)
            GestureDetector(
              onTap: () => setState(() => _isExpanded = true),
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  'Show ${improvements.length - _collapsedItemCount} more...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.accent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImprovementCard(ThemeColors colors, bool isDark, Map<String, dynamic> improvement) {
    final description = improvement['description'] as String? ?? '';
    final severity = improvement['severity'] as String? ?? 'medium';
    final severityColor = _getSeverityColor(severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: severityColor.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: severityColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingAnalysis(ThemeColors colors, bool isDark, Map<String, dynamic> breathing) {
    final pattern = breathing['pattern_observed'] as String? ?? '';
    final isCorrect = breathing['is_correct'] as bool? ?? true;
    final recommendation = breathing['recommendation'] as String? ?? '';
    final color = isCorrect ? AppColors.success : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.air, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                'Breathing',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isCorrect ? 'Good' : 'Needs Work',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ],
          ),
          if (pattern.isNotEmpty && pattern.toLowerCase() != 'not observable') ...[
            const SizedBox(height: 4),
            Text(
              'Observed: $pattern',
              style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4),
            ),
          ],
          if (recommendation.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              recommendation,
              style: TextStyle(fontSize: 12, color: colors.textMuted, fontStyle: FontStyle.italic, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTempoAnalysis(ThemeColors colors, bool isDark, Map<String, dynamic> tempo) {
    final observed = tempo['observed_tempo'] as String? ?? '';
    final isAppropriate = tempo['is_appropriate'] as bool? ?? true;
    final recommendation = tempo['recommendation'] as String? ?? '';
    final color = isAppropriate ? AppColors.success : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                'Tempo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isAppropriate ? 'Good' : 'Adjust',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ],
          ),
          if (observed.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Observed: $observed',
              style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4),
            ),
          ],
          if (recommendation.isNotEmpty && !isAppropriate) ...[
            const SizedBox(height: 2),
            Text(
              recommendation,
              style: TextStyle(fontSize: 12, color: colors.textMuted, fontStyle: FontStyle.italic, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoQuality(ThemeColors colors, bool isDark, Map<String, dynamic> quality) {
    final rerecord = quality['rerecord_suggestion'] as String? ?? '';

    // Only show if there's actually a tip to display
    if (rerecord.isEmpty) return const SizedBox.shrink();

    // Gentle, muted styling — this is a helpful hint, not a warning
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 13, color: colors.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              rerecord,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: colors.textMuted,
                height: 1.4,
              ),
            ),
          ),
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
    if (score < 4) return AppColors.error;
    if (score <= 7) return AppColors.warning;
    return AppColors.success;
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'critical':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }
}
