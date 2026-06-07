import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/haptic_service.dart';

/// Section header shared by the Workout "TRAINING STATS" and Nutrition
/// "NUTRITION STATS" blocks — an uppercase tracking label with an optional
/// trailing "See all" affordance, so both tabs read as one design.
class StatSectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  /// Optional trailing action (e.g. "See all" → /stats).
  final VoidCallback? onSeeAll;
  final String? seeAllLabel;

  /// Optional compact "custom trends" affordance, rendered as a small
  /// accent-tinted icon button immediately before the "See all" action.
  /// Replaces the old full-width "Custom trends" card at the bottom of the
  /// stat block — same destination (`/trends/custom`), far less vertical space.
  final VoidCallback? onTrendsTap;

  /// Accent used to tint the trends icon. Falls back to the muted text colour
  /// when null so the header still reads fine if no accent is passed.
  final Color? trendsAccent;

  /// Tooltip / a11y label for the trends icon.
  final String trendsTooltip;

  /// Optional "customize" affordance — a small tune icon (before the trends /
  /// see-all actions) that opens a reorder + show/hide sheet for the section's
  /// cards. Tinted with [trendsAccent] when provided.
  final VoidCallback? onCustomize;

  /// Tooltip / a11y label for the customize icon.
  final String customizeTooltip;

  const StatSectionHeader({
    super.key,
    required this.title,
    required this.isDark,
    this.onSeeAll,
    this.seeAllLabel,
    this.onTrendsTap,
    this.trendsAccent,
    this.trendsTooltip = 'Custom trends',
    this.onCustomize,
    this.customizeTooltip = 'Customize stats',
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: textSecondary,
              ),
            ),
          ),
          if (onCustomize != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _HeaderIconButton(
                tooltip: customizeTooltip,
                icon: Icons.tune_rounded,
                color: trendsAccent ?? textMuted,
                onTap: onCustomize!,
              ),
            ),
          if (onTrendsTap != null)
            _TrendsIconButton(
              tooltip: trendsTooltip,
              color: trendsAccent ?? textMuted,
              isDark: isDark,
              onTap: onTrendsTap!,
            ),
          if (onSeeAll != null)
            TextButton(
              onPressed: () {
                HapticService.light();
                onSeeAll!();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    seeAllLabel ?? 'See all',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: textMuted),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Generic accent-tinted square icon button used in [StatSectionHeader]
/// (e.g. the customize/tune action). Matches [_TrendsIconButton]'s footprint.
class _HeaderIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () {
          HapticService.light();
          onTap();
        },
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }
}

/// Small accent-tinted icon button used in [StatSectionHeader] to open the
/// custom-trends builder. Sized to match the "See all" tap target so the two
/// affordances sit comfortably side by side.
class _TrendsIconButton extends StatelessWidget {
  final String tooltip;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _TrendsIconButton({
    required this.tooltip,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () {
          HapticService.light();
          onTap();
        },
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(Icons.auto_graph_rounded, size: 17, color: color),
        ),
      ),
    );
  }
}

/// Consistent card container for a stat card body (elevated bg + border +
/// radius 16). Keeps every card on both tabs visually identical.
class StatCardShell extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry padding;

  const StatCardShell({
    super.key,
    required this.child,
    required this.isDark,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: child,
    );
  }
}
