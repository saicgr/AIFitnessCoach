/// The bottom-right FAB cluster — **Placement D** (2026-08 nav redesign).
///
/// ONE right-anchored row holding the global ✦ coach circle inboard of (to the
/// left of) the Quick Log pill. Not two independent floats: Quick Log's width
/// morphs on scroll (`quickLogFabExpandedProvider`, 12 px collapse / 8 px
/// re-expand hysteresis, driven by the shell-level scroll listener in
/// `main_shell.dart`), so a separately-anchored coach button would have the gap
/// between the two breathing open and shut on every scroll. Laid out as one Row
/// with a constant [kCoachPillClusterGap], the morph slides the pair as a unit
/// and the gap is structurally incapable of changing.
///
/// Size encodes frequency: Quick Log is the larger, captioned, expanding target
/// (the daily habitual action); coach is the quiet 40 pt icon-only secondary.
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
        // inside the right-thumb arc. `CoachFloatingButton` owns its own hide
        // rules (coach screen / active workout) and renders a zero-size box
        // when suppressed, so the cluster collapses cleanly to Quick Log alone
        // instead of leaving a hole where the circle was.
        const CoachFloatingButton(),
        if (!_coachHidden(context, ref))
          const SizedBox(width: kCoachPillClusterGap),
        // Anchor for nav-tour step 3 ("Quick Log") — the spotlight must ring
        // THIS always-visible button. The key used to live on the home
        // QuickActionsRow section, which is opt-in (hidden for new users), so
        // the tour showed a dim with no cutout.
        KeyedSubtree(
          key: AppTourKeys.quickLogKey,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  (maxWidth - kCoachPillDiameter - kCoachPillClusterGap)
                      .clamp(kQuickLogFabHeight, double.infinity),
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
  /// with the circle — a 10 px hole hanging off Quick Log's left edge on the
  /// chat screen would be a visible artefact of a control that isn't there.
  bool _coachHidden(BuildContext context, WidgetRef ref) =>
      CoachFloatingButton.suppressedIn(context, ref);
}
