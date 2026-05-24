import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/repositories/cardio_phase_repository.dart';

/// Subtle pastel banner that surfaces a period-aware cardio intensity
/// recommendation on the cardio plan + log-cardio start screens.
///
/// Placement is intentionally NOT decided here — this widget is owned by the
/// `SLICE_PHASE` slice; the later cardio composer agent wires it into
/// `cardio_plan_screen.dart` / `log_cardio_screen.dart`. It is a stateless
/// presentational widget: callers fetch via
/// `cardioPhaseRecommendationProvider` and pass the (non-null) recommendation
/// in. When the provider returns null (opted out / pregnant / etc.) the
/// caller must render nothing.
///
/// Visual rules:
///   * single line of copy, tiny evidence citation under it
///   * pastel background derived from the user's chosen accent color
///   * tap → dialog with full rationale + citation
///   * calibration variant uses a softer label, no intensity color cue
class PhaseRecommendationBanner extends StatelessWidget {
  final PhaseRecommendation recommendation;

  /// Optional override for the outer margin. Defaults to a small vertical gap
  /// so the banner can drop into any vertical scroll list without surgery.
  final EdgeInsetsGeometry? margin;

  const PhaseRecommendationBanner({
    super.key,
    required this.recommendation,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final isCalibration = recommendation.isCalibration;
    // Intensity dot color: low=soft accent, moderate=mid, high=strong. We
    // stick with accent shades (no red/green) so the banner stays pastel and
    // non-alarming, per "subtle, not aggressive" spec.
    final double dotOpacity = switch (recommendation.recommendedIntensity) {
      'high' => 0.95,
      'moderate' => 0.7,
      'low' => 0.45,
      _ => 0.35,
    };
    final dotColor = accent.withValues(alpha: dotOpacity);

    final bgAlpha = isDark ? 0.08 : 0.06;
    final borderAlpha = isDark ? 0.22 : 0.18;

    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showDetailDialog(context, accent, isDark),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: bgAlpha),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: borderAlpha)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phase + intensity indicator. Calibration uses a hollow ring.
                _PhaseDot(color: dotColor, hollow: isCalibration),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _headline(),
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        recommendation.evidenceCitation.isEmpty
                            ? 'Tap for details'
                            : 'Evidence: ${recommendation.evidenceCitation}',
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.3,
                          color: textMuted,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: accent.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One-line headline: "{Phase}: {short hint}". Calibration uses a softer
  /// "still learning your cycle" tone with no intensity claim.
  String _headline() {
    if (recommendation.isCalibration) {
      return 'Cycle tracking calibrating — train by feel today.';
    }
    final intensity = recommendation.recommendedIntensity;
    final shortHint = switch (intensity) {
      'low' => 'recovery mode, gentle Z2 today',
      'moderate' => 'solid Z2 endurance day',
      'high' => 'great day for intervals or a tempo',
      _ => 'train by feel today',
    };
    return '${recommendation.phaseLabel}: $shortHint';
  }

  void _showDetailDialog(BuildContext context, Color accent, bool isDark) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final textPrimary =
            isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
        final textMuted =
            isDark ? AppColors.textMuted : AppColorsLight.textMuted;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              _PhaseDot(
                color: accent,
                hollow: recommendation.isCalibration,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  recommendation.phaseLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recommendation.recommendedIntensity != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _IntensityChip(
                    intensity: recommendation.recommendedIntensity!,
                    accent: accent,
                  ),
                ),
              Text(
                recommendation.rationale,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              if (recommendation.evidenceCitation.isNotEmpty)
                Text(
                  'Based on: ${recommendation.evidenceCitation}',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              if (recommendation.cycleDay != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Cycle day ${recommendation.cycleDay}'
                  '${recommendation.confidence != null ? " · ${recommendation.confidence}-confidence estimate" : ""}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: textMuted,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'Cycle predictions are estimates — not contraception or '
                'medical advice.',
                style: TextStyle(
                  fontSize: 11,
                  color: textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Got it',
                style: TextStyle(color: accent, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PhaseDot extends StatelessWidget {
  final Color color;
  final bool hollow;
  const _PhaseDot({required this.color, this.hollow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: hollow ? Colors.transparent : color,
        shape: BoxShape.circle,
        border: hollow ? Border.all(color: color, width: 1.5) : null,
      ),
    );
  }
}

class _IntensityChip extends StatelessWidget {
  final String intensity;
  final Color accent;
  const _IntensityChip({required this.intensity, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = switch (intensity) {
      'low' => 'Low intensity recommended',
      'moderate' => 'Moderate intensity recommended',
      'high' => 'High intensity green-light',
      _ => intensity,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
    );
  }
}
