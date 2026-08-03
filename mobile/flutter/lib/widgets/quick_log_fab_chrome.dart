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
// causes:
//
//  1. OCCLUSION. Every tab reserved `kMainNavClearance` (68 = nav pill + gap)
//     at the bottom of its scroll extent, but the button is drawn ABOVE the nav
//     — its top edge sits `kQuickLogFabBottomOffset + kQuickLogFabHeight` = 124
//     px above the safe-area inset, so the last 56 px of every tab's scroll
//     extent was, by construction, underneath it. [kQuickLogFabClearance] is
//     the corrected figure and is derived from the same tokens the button is
//     positioned with (see `widgets/main_shell.dart`), so the two can never
//     drift apart again.
//
//     ADOPTION STATUS: the four tab screens still reserve nav-only clearance
//     and must switch to [kQuickLogFabClearance] — see the shortfall per screen
//     in the E2E register, row 16. Those files are owned elsewhere; this
//     constant is the single value they must all use, and
//     `test/widgets/quick_log_fab_chrome_test.dart` fails if it is ever
//     hand-edited away from the button's real geometry.
//
//  2. NO LABEL. A bare circular "+" with no caption forces the user to guess.
//     It opens the SAME quick-actions sheet on every tab, so the honest fix is
//     one stable, legible caption — not a per-tab label that would imply the
//     action changes when it does not. Fixed: `main_shell.dart` now renders
//     [QuickLogFabChrome] with the localised `quickLogOverlayQuickLog` caption.
// ─────────────────────────────────────────────────────────────────────────────

/// Height of the quick-log FAB.
const double kQuickLogFabHeight = 44.0;

/// Gap between the top of the nav pill and the bottom of the FAB.
///
/// Register #177 (a #16 recurrence): #16 fixed the FAB covering content it
/// scrolls PAST (the trailing `kQuickLogFabClearance` reservation below).
/// It did not fix — because it's a different failure mode — the FAB
/// covering content it floats ON TOP of at rest: on Home it clipped the
/// hero card's title ("LOWER BODY STRE▮"), and on the Workout tab it
/// visually covered the PROGRAMS tile. Both are the SAME fixed
/// `Positioned(bottom:)` pill painted over whatever the scroll view happens
/// to render at that screen offset, independent of scroll position, on
/// every tab that shows it. Raised from 14 → 26 (docs/planning/mockups/
/// home-density-2026-08-01.html "after" panel: fab bottom 52 → 64, the same
/// +12 delta) — the single shared token every tab's FAB position derives
/// from, so the extra clearance applies everywhere the button floats, not
/// just Home. Only the resting offset moved; size, styling, tap target and
/// always-on-top behaviour are unchanged.
const double kQuickLogFabGapAboveNav = 26.0;

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
              // Adaptive, never truncated (E2E register row 16 + 108). A bare
              // `maxLines: 1` Text in a Row overflows (yellow stripe) as soon
              // as the localised caption or the user's text scale outgrows the
              // remaining width — and the obvious patch, `TextOverflow
              // .ellipsis`, would clip the caption to "Quick…", which is
              // exactly the truncation-on-the-identifying-word defect row 108
              // is about. Flexible bounds the width, FittedBox.scaleDown
              // shrinks the glyphs to fit instead of deleting them, so every
              // letter survives at every locale and every text scale.
              Flexible(
                // ExcludeSemantics: the caption is already announced by the
                // wrapping [Semantics] node. Without this a screen reader
                // reads "Quick Log, Quick Log, button".
                child: ExcludeSemantics(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: tc.textPrimary,
                      ),
                    ),
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
