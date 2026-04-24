import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/body_analyzer.dart';

/// List of posture issues detected by Gemini + CTA to queue correctives.
class PostureFindingsCard extends StatelessWidget {
  final List<PostureFinding> findings;
  final VoidCallback? onApplyCorrectives;
  final bool isApplying;
  final bool isDark;

  const PostureFindingsCard({
    super.key,
    required this.findings,
    required this.isDark,
    this.onApplyCorrectives,
    this.isApplying = false,
  });

  @override
  Widget build(BuildContext context) {
    if (findings.isEmpty) return const SizedBox.shrink();
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF5A623).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.accessibility_new_rounded,
                color: Color(0xFFF5A623),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Posture findings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...findings.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _severityDot(f.severity),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _prettyIssue(f.issue),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            f.description,
                            style: TextStyle(fontSize: 12, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          if (onApplyCorrectives != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isApplying ? null : onApplyCorrectives,
                icon: isApplying
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.auto_fix_high_rounded, size: 18),
                label: Text(
                  isApplying ? 'Queuing…' : 'Add corrective exercises',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A623),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _severityDot(int severity) {
    final color = severity >= 3
        ? const Color(0xFFE74C3C)
        : severity == 2
            ? const Color(0xFFF5A623)
            : const Color(0xFFF8C971);
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  String _prettyIssue(String raw) {
    const map = {
      'forward_head_posture': 'Forward head posture',
      'rounded_shoulders': 'Rounded shoulders',
      'anterior_pelvic_tilt': 'Anterior pelvic tilt',
      'uneven_shoulders': 'Uneven shoulders',
      'knee_valgus': 'Knee valgus',
      'scapular_winging': 'Scapular winging',
    };
    return map[raw] ?? raw.replaceAll('_', ' ');
  }
}
