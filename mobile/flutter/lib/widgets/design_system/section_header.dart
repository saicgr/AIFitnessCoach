import 'package:flutter/material.dart';

import '../../core/theme/theme_colors.dart';

/// Single-style section header used across the redesigned tabs (Home, Workout,
/// Nutrition, Leaderboard, You/Profile/Stats).
///
/// Replaces the previous rainbow of colored section headers (FITNESS blue,
/// TRAINING in user accent, SYNCED purple, NUTRITION green, ACCOUNT cyan,
/// DATA & PRIVACY blue). The visual language was fragmented without adding
/// meaning. One muted small-caps style applies everywhere now.
///
/// Tokens (per the minimalist redesign design-system block in the plan):
///   font-size: 12pt
///   letter-spacing: 1.2
///   transform: uppercase (we uppercase the input ourselves so callers can
///                         pass natural casing)
///   color: ThemeColors.of(context).textMuted
///   weight: w700 — enough to read as a heading without dominating
class SectionHeader extends StatelessWidget {
  final String label;

  /// Optional trailing widget (rare — most headers don't have one). Reserved
  /// for `Edit` / `View all` style affordances that need to sit on the same
  /// line as the title.
  final Widget? trailing;

  /// Top + bottom padding. Defaults match the 24/12 vertical rhythm used in
  /// the redesigned screens.
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.label,
    this.trailing,
    this.padding = const EdgeInsets.only(top: 24, bottom: 12, left: 16, right: 16),
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: c.textMuted,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
