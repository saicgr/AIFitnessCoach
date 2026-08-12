/// Shared Health-tab chrome: the accent CTA pill and the 34 pt hairline icon
/// button, both of which the 2026-08 Health mockup uses in more than one place.
///
/// Extracted so `health_shell_screen.dart` and `combined_health_screen.dart`
/// cannot drift: before this, the same "Connect Health" call to action was a
/// bare themed `ElevatedButton` in both files, which rendered a Material
/// stadium button with sentence-case text where the mockup specifies an
/// accent-filled Barlow pill (`.cbtn{border-radius:99px;font-size:12px;
/// letter-spacing:1.8px;text-transform:uppercase;padding:9px 20px}`).
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/haptic_service.dart';

/// The accent-filled pill CTA (`.cbtn`). Accent fill, 999 radius, Barlow
/// uppercase 12/1.8, contrast label — the app's own accent-pill treatment.
class HealthCtaPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  /// Renders as an outlined hairline pill instead of an accent-filled one.
  /// Used where a second, quieter action sits beside a primary one so the
  /// surface never carries two accent fills.
  final bool quiet;

  const HealthCtaPill({
    super.key,
    required this.label,
    required this.onTap,
    this.quiet = false,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticService.light();
          onTap();
        },
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: BoxDecoration(
              color: quiet ? Colors.transparent : tc.accent,
              border: Border.all(color: quiet ? tc.cardBorder : tc.accent),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: ZType.lbl(
                12,
                color: quiet ? tc.accent : tc.accentContrast,
                letterSpacing: 1.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 34 pt circular hairline icon button (`.icbtn`) the mockup puts in the
/// Health masthead. Quiet by construction: hairline border, secondary-text
/// glyph, no fill — it must not compete with the source chip beside it.
class HealthIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const HealthIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticService.light();
            onTap();
          },
          child: ExcludeSemantics(
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: tc.cardBorder),
              ),
              child: Icon(icon, size: 17, color: tc.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
