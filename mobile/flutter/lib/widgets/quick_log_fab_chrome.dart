import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/chrome_constants.dart';
import '../core/theme/theme_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Quick-log FAB chrome (E2E register row 16).
//
// The always-on "+" button that docks above the bottom nav on Home, Workout,
// Nutrition and You was PHYSICALLY COVERING real controls: "Log water" on Home,
// the YOUR HABITS row on You, the LUNCH header on Nutrition. Two independent
// causes, both fixed here:
//
//  1. OCCLUSION. Every tab reserved `kMainNavClearance` (68 = nav pill + gap)
//     at the bottom of its scroll extent, but the FAB is drawn ABOVE the nav —
//     it occupies another 58 logical pixels that nothing accounted for. So the
//     last row of every list was, by construction, unreachable under the
//     button. [kQuickLogFabClearance] is the corrected figure and is derived
//     from the same tokens the FAB itself is positioned with, so the two can
//     never drift apart again.
//
//  2. NO LABEL. A bare circular "+" with no caption forces the user to guess.
//     It opens the SAME quick-actions sheet on every tab, so the honest fix is
//     one stable, legible caption — not a per-tab label that would imply the
//     action changes when it does not.
// ─────────────────────────────────────────────────────────────────────────────

/// Height of the quick-log FAB.
const double kQuickLogFabHeight = 44.0;

/// Gap between the top of the nav pill and the bottom of the FAB.
const double kQuickLogFabGapAboveNav = 14.0;

/// Distance from the bottom safe-area inset to the BOTTOM of the FAB.
/// This is the value `Positioned(bottom:)` must use, minus the inset itself.
const double kQuickLogFabBottomOffset =
    kMainNavBarHeight + kMainNavBottomGap + kQuickLogFabGapAboveNav;

/// Vertical space (above the safe-area inset) a tab screen must reserve so its
/// content can scroll clear of BOTH the floating nav pill and the quick-log
/// FAB that floats above it.
///
/// Use this instead of [kMainNavClearance] on any tab that renders the FAB
/// (Home, Workout, Nutrition, You). [kMainNavClearance] remains correct for
/// surfaces with no FAB — the Coach tab, and full-screen pushed routes.
const double kQuickLogFabClearance =
    kQuickLogFabBottomOffset + kQuickLogFabHeight + 12;

/// Corner radius of the quick-log button.
///
/// Matches the shipped `.rh-plus` signature (the outlined rounded-rect already
/// drawn in `widgets/main_shell.dart`), so adding the caption changes what the
/// control SAYS without silently restyling it into a different shape.
const double kQuickLogFabRadius = 6.0;

/// The labelled quick-log button that docks above the main nav.
///
/// Replaces the unlabelled 44×44 square. Same tap target, same destination —
/// but it now says what it does, and it exposes proper [Semantics] so a
/// screen-reader user gets "<label>, button" instead of an anonymous glyph.
///
/// [label] is REQUIRED and has no English default on purpose: the caption is
/// user-facing copy, so it must come from `AppLocalizations` at the call site
/// (`lib/l10n/app_en.arb`), never be baked into the widget. It is also
/// deliberately ONE caption for all four tabs — the button opens the identical
/// quick-actions grid (Scan menu · Log workout · Log water · …) from every tab,
/// and four different labels would advertise four actions that do not exist.
class QuickLogFabChrome extends StatelessWidget {
  const QuickLogFabChrome({
    super.key,
    required this.onTap,
    required this.label,
  });

  final VoidCallback onTap;

  /// Visible caption — pass a localised string.
  final String label;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final isDark = tc.isDark;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          height: kQuickLogFabHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: tc.surface,
            borderRadius: BorderRadius.circular(kQuickLogFabRadius),
            // Single accent source — never a literal. See
            // core/theme/accent_color_provider.dart.
            border: Border.all(color: tc.accent, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 20, color: tc.textPrimary),
              const SizedBox(width: 6),
              // Flexible + ellipsis: a `maxLines: 1` Text inside a Row with no
              // Flexible overflows (yellow-stripe) the moment the localised
              // caption is wider than the remaining space.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: tc.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
