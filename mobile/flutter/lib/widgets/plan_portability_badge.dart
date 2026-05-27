import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/theme_colors.dart';

/// Reusable "Yours forever, even after trial" badge.
///
/// Renders the plan-portability guarantee — a Zealova differentiator vs
/// Fitbit/Whoop/MFP/Strava where the plan disappears when the subscription
/// ends. Plan data is portable in code (full export at any time); this badge
/// surfaces the guarantee visually.
///
/// Three variants by [size]:
///   * [PortabilitySize.inline] — small pill suitable for a workout-card
///     corner or a paywall sub-line.
///   * [PortabilitySize.banner] — full-width row with icon + 2-line copy,
///     suitable for the paywall pricing screen + the trial-end sheet.
///   * [PortabilitySize.compact] — between the two; icon + single-line
///     headline. Suitable for the trial-progress widget on Home.
///
/// Tap (optional) opens a sheet explaining what portability means in
/// concrete terms (full data export, plan you generated stays accessible,
/// no lock-in).
class PlanPortabilityBadge extends StatelessWidget {
  const PlanPortabilityBadge({
    super.key,
    this.size = PortabilitySize.banner,
    this.onTap,
  });

  final PortabilitySize size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;
    final accent = isDark ? AppColors.teal : AppColorsLight.teal;
    final textPrimary = colors.textPrimary;
    final textSecondary = colors.textSecondary;

    switch (size) {
      case PortabilitySize.inline:
        return _buildInline(accent, textPrimary);
      case PortabilitySize.compact:
        return _buildCompact(accent, textPrimary);
      case PortabilitySize.banner:
        return _buildBanner(accent, textPrimary, textSecondary, isDark);
    }
  }

  Widget _buildInline(Color accent, Color textPrimary) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_outlined, size: 10, color: accent),
              const SizedBox(width: 4),
              Text(
                'Yours forever',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(Color accent, Color textPrimary) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_outlined, size: 16, color: accent),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Your plan is yours forever, even after trial',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner(
    Color accent,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.18),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.verified_outlined, size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your plan is yours forever',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Cancel anytime. Export your full history any time. '
                      'No lock-in.',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum PortabilitySize { inline, compact, banner }
