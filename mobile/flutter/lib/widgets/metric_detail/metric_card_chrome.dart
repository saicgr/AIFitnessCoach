/// Shared card chrome for every metric detail screen (pillar + cardio).
///
/// Extracted from `lib/screens/pillar/pillar_detail_screen.dart` (Phase A.5)
/// so the 4 pillar detail cards + the 3 new cardio detail screens
/// (race predictor, training load, VO2max) + any future MetricDetailScreen
/// don't each maintain their own copy of the same visual treatment.
///
/// The full "MetricDetailScreen base" originally planned for Phase A.5
/// turned out NOT to fit the cardio detail screens cleanly — race
/// predictor renders 4 prediction tiles, training load renders a dual-
/// axis ACWR chart, VO2max renders a sparkline + stat row. Forcing them
/// under one base would have made the base too abstract. The card
/// chrome IS shared, however, so extracting that without forcing a
/// shared screen scaffold gives the dedup win without the over-abstraction
/// risk. Pillar detail screen golden-screenshot regression risk is also
/// minimized: this widget renders pixel-identically to the old private
/// `_Card` since the implementation is copied verbatim — only the
/// underscore prefix is removed.
library;

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// 20px-BR / elevated-surface / 1px-border card chrome used across every
/// detail screen card. Padding: 18 left/right, 16 top/bottom. Caller
/// supplies its own header + content layout inside [child].
class MetricCardChrome extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry padding;

  const MetricCardChrome({
    super.key,
    required this.child,
    required this.isDark,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 16),
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Shared header row for a metric card — colored icon chip + title.
/// Mirrors the look of the old private `_CardHeader` so existing pillar
/// cards swap in 1:1.
class MetricCardHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final bool isDark;

  /// Optional trailing widget (e.g. an expand-to-fullscreen button).
  final Widget? trailing;

  const MetricCardHeader({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.isDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
