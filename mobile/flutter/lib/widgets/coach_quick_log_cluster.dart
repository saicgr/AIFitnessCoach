/// The bottom-right FAB cluster — **Placement D** (2026-08 nav redesign).
///
/// ONE right-anchored row holding the global ✦ coach circle inboard of (to the
/// left of) the Quick Log pill. Not two independent floats: Quick Log's width
/// morphs on scroll (`quickLogFabExpandedProvider`, 12 px collapse / 8 px
/// re-expand hysteresis, driven by the shell-level scroll listener in
/// `main_shell.dart`), so a separately-anchored coach button would have the gap
/// between the two breathing open and shut on every scroll. Laid out as one Row
/// with a constant [kFloatClusterGap], the morph slides the pair as a unit and
/// the gap is structurally incapable of changing.
///
/// ## Exactly two slots — this widget owns the whole band
///
/// The trailing-edge band `[safeArea + kQuickLogFabBottomOffset,
/// safeArea + kQuickLogFabClearance]` belongs to this Row and to nothing else.
/// Both members are [kFloatCircleDiameter]; hierarchy is carried by fill and
/// caption (Quick Log expands into a labelled pill, coach never does), NOT by
/// making one circle smaller — D4 (2026-08) is what mismatched float diameters
/// look like on a real device.
///
/// A new floating affordance may only (a) REPLACE a slot under mutual
/// exclusion — `CoachFloatingButton.suppressedIn` ↔ `FloatingChatBubble`
/// already does exactly that — or (b) become a row inside the Quick Log sheet.
/// Never a third `Positioned`.
/// `test/widgets/coach_pill_placement_test.dart` fails if a third float is
/// added here or if the two stop sharing a diameter.
///
/// Returns a plain [Row] — the caller owns the anchoring, so the shell can
/// position it against the nav pill and a nav-less surface can position it
/// against the screen edge without this widget knowing about either.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_tour/app_tour_controller.dart';
import 'coach_floating_button.dart';
import 'quick_log_fab_chrome.dart';

class CoachQuickLogCluster extends ConsumerWidget {
  /// Quick Log's morph state — `true` = labelled pill (at rest, top of
  /// scroll), `false` = icon-only circle (content moving underneath).
  final bool quickLogExpanded;

  /// Localised Quick Log caption. Required, and never defaulted to English —
  /// it is user-facing copy and must come from `AppLocalizations`.
  final String quickLogLabel;

  final VoidCallback onQuickLog;

  /// Width budget for the whole cluster. The caption scales down inside
  /// Quick Log rather than pushing the coach circle off the leading edge at a
  /// large text scale.
  final double maxWidth;

  const CoachQuickLogCluster({
    super.key,
    required this.quickLogExpanded,
    required this.quickLogLabel,
    required this.onQuickLog,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Inboard of Quick Log — further from the screen edge, still deep
        // inside the right-thumb arc. SLOT 1 of exactly two. `CoachFloatingButton` owns its own hide
        // rules (coach screen / active workout) and renders a zero-size box
        // when suppressed, so the cluster collapses cleanly to Quick Log alone
        // instead of leaving a hole where the circle was.
        const CoachFloatingButton(),
        if (!_coachHidden(context, ref))
          const SizedBox(width: kFloatClusterGap),
        // Anchor for nav-tour step 3 ("Quick Log") — the spotlight must ring
        // THIS always-visible button. The key used to live on the home
        // QuickActionsRow section, which is opt-in (hidden for new users), so
        // the tour showed a dim with no cutout.
        KeyedSubtree(
          key: AppTourKeys.quickLogKey,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  (maxWidth - kFloatCircleDiameter - kFloatClusterGap)
                      .clamp(kFloatCircleDiameter, double.infinity),
            ),
            child: QuickLogFabChrome(
              label: quickLogLabel,
              onTap: onQuickLog,
              expanded: quickLogExpanded,
            ),
          ),
        ),
      ],
    );
  }

  /// Mirrors [CoachFloatingButton]'s own suppression so the gap disappears
  /// with the circle — a [kFloatClusterGap] hole hanging off Quick Log's
  /// leading edge on the chat screen would be a visible artefact of a control
  /// that isn't there.
  bool _coachHidden(BuildContext context, WidgetRef ref) =>
      CoachFloatingButton.suppressedIn(context, ref);
}
