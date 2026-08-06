import 'dart:ui' as ui;

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
//
//  3. COLLAPSE ON SCROLL. #16's caption and #177's icon-only shrink each fixed
//     one half of the occlusion problem but not both at once: a caption wide
//     enough to read blankets content while scrolling (#16/#177), and an
//     icon-only glyph that never explains itself regresses #16's original
//     complaint. The button now has TWO states, driven by [expanded]: the
//     labelled pill from rest (top of scroll, nothing is moving under it so
//     the width is safe) and the icon-only circle the instant the user
//     scrolls (content is moving under it, so it shrinks to the smallest
//     footprint that is still tappable). `main_shell.dart` derives
//     [expanded] from a shell-level scroll listener — see
//     `quickLogFabExpandedProvider` there. Never hidden in either state
//     (auto-hide was considered and rejected — the control must always be
//     reachable), and the [Semantics] label is identical in both states so a
//     screen-reader user never hears the control change identity.
// ─────────────────────────────────────────────────────────────────────────────

// The FAB's geometry tokens moved to `core/constants/chrome_constants.dart`
// (the file that already owns the nav pill's geometry) so non-widget chrome
// can derive from them too — specifically the app's SnackBar bottom inset,
// which has to clear this button (E2E row 125). They are re-exported here, so
// every existing `import '.../quick_log_fab_chrome.dart'` keeps resolving
// `kQuickLogFabClearance` and friends unchanged.
export '../core/constants/chrome_constants.dart'
    show
        kQuickLogFabHeight,
        kQuickLogFabGapAboveNav,
        kQuickLogFabBottomOffset,
        kQuickLogFabClearance;

/// Corner radius of the quick-log button.
///
/// Matches the shipped `.rh-plus` signature (the outlined rounded-rect already
/// drawn in `widgets/main_shell.dart`), so adding the caption changes what the
/// control SAYS without silently restyling it into a different shape.
const double kQuickLogFabRadius = 6.0;

/// The labelled quick-log button that docks above the main nav.
///
/// Two visual states, chosen by [expanded]:
///  - `true` (at rest, top of scroll): the labelled pill — icon + caption.
///  - `false` (while the user is scrolling): the icon-only 44×44 circle.
///
/// Both states share the same tap target height ([kQuickLogFabHeight]) and
/// the same outer [Semantics] node, so a screen reader announces "<label>,
/// button" identically regardless of scroll state — only the SIGHTED
/// presentation changes. Callers drive [expanded] from scroll position (see
/// `quickLogFabExpandedProvider` in `main_shell.dart`); this widget itself
/// has no scroll awareness, so it stays trivially testable with either state
/// passed directly.
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
    required this.expanded,
  });

  final VoidCallback onTap;

  /// Visible caption — pass a localised string. Rendered only when
  /// [expanded] is true; always exposed to assistive tech via [Semantics].
  final String label;

  /// `true` renders the labelled pill, `false` the icon-only circle. Never
  /// controls visibility — the button is never hidden in either state.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final isDark = tc.isDark;
    // Snap instead of animate under reduced motion, same pattern as
    // core/constants/stat_typography.dart.
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // ONE continuously-interpolated widget, not two subtrees swapped inside
    // an AnimatedSize. The previous version animated only the outer box size
    // while four things changed instantly at the switch:
    //   · corner radius jumped 22 → 6
    //   · icon jumped 20 → 24
    //   · the caption appeared at full opacity
    //   · the padding snapped 0 → 14
    // AnimatedSize cannot tween across a child swap, so the box slid while
    // its contents cut — which is exactly what reads as "not smooth".
    // Everything below is driven by a single t (0 = circle, 1 = pill).
    Widget buildAt(double t) {
      final radius =
          ui.lerpDouble(kQuickLogFabHeight / 2, kQuickLogFabRadius, t)!;
      return Container(
        height: kQuickLogFabHeight,
        // minWidth holds the 44pt circle at t=0 and releases as it expands, so
        // the pill hugs its caption at t=1. NOT `alignment:` — a Container
        // with an alignment fills bounded constraints, which is what made the
        // pill span the whole screen once already.
        constraints: BoxConstraints(
          minWidth: ui.lerpDouble(kQuickLogFabHeight, 0, t)!,
        ),
        padding: EdgeInsets.symmetric(horizontal: ui.lerpDouble(0, 14, t)!),
        decoration: BoxDecoration(
          color: tc.surface,
          borderRadius: BorderRadius.circular(radius),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Constant size in both states — a 20↔24 jump is small but it is
            // the element the eye is actually tracking through the change.
            Icon(Icons.add_rounded, size: 22, color: tc.textPrimary),
            // The caption is REVEALED rather than inserted: ClipRect + a
            // widthFactor that grows with t wipes it out from the icon, and
            // the opacity ramp keeps it from strobing at the very start.
            Flexible(
              child: ClipRect(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: t,
                  child: Opacity(
                    // Squared so the text stays faint until the box has
                    // actually made room, instead of racing the width.
                    opacity: (t * t).clamp(0.0, 1.0),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 7),
                      // ExcludeSemantics: the caption is already announced by
                      // the wrapping [Semantics] node, or a screen reader
                      // reads "Quick Log, Quick Log, button".
                      child: ExcludeSemantics(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          // Scales rather than ellipsising — clipping this to
                          // "Quick…" is the row-108 truncation defect.
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
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        // Grows and shrinks from the right edge — the button is right-anchored
        // in main_shell.dart — so the tap target's right edge never moves.
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: expanded ? 1.0 : 0.0),
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) => Align(
            alignment: AlignmentDirectional.centerEnd,
            widthFactor: 1,
            child: buildAt(t),
          ),
        ),
      ),
    );
  }
}
