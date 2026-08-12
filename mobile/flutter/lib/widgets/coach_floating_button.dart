/// The global ✦ coach button — **Placement D** (2026-08 nav redesign).
///
/// Coach gave up its bottom-nav tab to Health, so coach access became a small
/// icon-only ✦ circle that rides immediately **inboard of** (to the left of)
/// the Quick Log pill, in one bottom-right cluster. It is a promotion of this
/// already-shipped widget, not a new control.
///
/// ## Why one cluster and not two floats
///
/// Quick Log is not fixed-width: `quickLogFabExpandedProvider` (12 px collapse
/// / 8 px re-expand hysteresis, `main_shell.dart`) morphs it between a labelled
/// pill and a 44 pt circle the instant the tab scrolls. Anything anchored
/// beside it with its own independent `Positioned(right:)` would have the gap
/// between the two breathing open and shut on every scroll. So the two are laid
/// out as ONE right-anchored `Row` in `main_shell.dart` — the coach circle is
/// fixed at 40 pt, the gap is a constant, and Quick Log's morph slides the
/// whole cluster as a unit. That is what "shares Quick Log's collapse state"
/// means mechanically; there is no second morph provider to drift out of sync
/// (the old `coachFabExpandedProvider` was retired with this change).
///
/// ## Why bottom-RIGHT
///
/// Bottom-left is the one quadrant a right-handed one-handed user cannot reach
/// without a grip change — roughly a third of sessions. Bottom-right is also
/// the established convention for assistant entry points and the default FAB
/// corner, and it is where this widget already lived.
///
/// ## Quiet by construction
///
/// Google Health users report triggering their AI coach *accidentally* and say
/// it obstructs their data. So: icon-only (never a labelled pill competing with
/// Quick Log), the smaller of the two targets, never animated unprompted, and
/// it never opens anything on its own — one deliberate tap → `/chat`.
///
/// Two hide rules, both enforced here rather than at the call site so they hold
/// wherever the button is mounted:
///
///   * **On the coach screen itself** (`/chat…`) — a coach button floating over
///     the coach is clutter, and it would sit on the composer.
///   * **During an active workout** — that flow has its own Ask-coach pill and
///     its own docked mini player in this exact band.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/workout_mini_player_provider.dart';
import '../core/theme/theme_colors.dart';
import '../data/providers/coach_unread_provider.dart';
import '../data/services/haptic_service.dart';
import 'coach_spark_icon.dart';
// `edgeHandleEnabledProvider` — the chat-head opt-in this button defers to.
import 'main_shell.dart';

/// Diameter of the icon-only coach circle. Deliberately smaller than
/// `kQuickLogFabHeight` (44) — target size matches frequency ordering, and
/// Quick Log is the daily habitual action.
const double kCoachPillDiameter = 40.0;

/// Gap between the coach circle and the Quick Log pill inside the cluster.
/// A constant, not a computed value: the whole point of the cluster is that
/// this distance never changes while Quick Log morphs.
const double kCoachPillClusterGap = 10.0;

class CoachFloatingButton extends ConsumerWidget {
  const CoachFloatingButton({super.key});

  /// True when the coach button must stand down for this location / session
  /// state. Exposed so the shell can decide whether to reserve cluster space
  /// without duplicating the rules, and so tests can assert them directly.
  static bool isSuppressed({
    required String location,
    required bool workoutActive,
  }) =>
      // `/chat` also prefixes `/chat/sessions` — the conversation list is the
      // same coach surface, so it stands down there too.
      location.startsWith('/chat') || workoutActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (suppressedIn(context, ref)) return const SizedBox.shrink();
    final tc = ThemeColors.of(context);
    final unread = ref.watch(coachUnreadCountProvider);

    return Semantics(
      button: true,
      label: 'Ask coach',
      child: GestureDetector(
        onTap: () => _open(context),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: kCoachPillDiameter,
          height: kCoachPillDiameter,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // QUIET BY CONSTRUCTION, VISUALLY TOO — not just behaviourally.
              //
              // This was a solid accent-filled puck with an accent glow, which
              // made the smaller of the two controls the loudest thing on
              // every screen and put TWO accent-filled shapes in one cluster.
              // The mockup's `.qmini` is a raised-surface circle with a 1px
              // hairline and the accent on the GLYPH ONLY, carrying the same
              // neutral float shadow Quick Log uses so the pair reads as one
              // cluster lifted off the page rather than two competing colours.
              Container(
                width: kCoachPillDiameter,
                height: kCoachPillDiameter,
                decoration: BoxDecoration(
                  color: tc.elevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: tc.cardBorder, width: 1),
                  boxShadow: [
                    // Same float shadow as `QuickLogFabChrome` — neutral, not
                    // an accent glow.
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: tc.isDark ? 0.45 : 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: ExcludeSemantics(
                    // 15 px ✦, matching the mockup's glyph, and the ONE place
                    // the accent is spent on this control.
                    child: CoachSparkIcon(size: 15, color: tc.accent),
                  ),
                ),
              ),
              // Unread proactive coach messages. This badge used to live on the
              // Coach nav item; the nav item is gone, and this button is a
              // strictly better home for it — it is visible on EVERY tab, not
              // just while some other tab is selected. Cleared by ChatScreen on
              // open, whatever the entry point.
              if (unread > 0)
                PositionedDirectional(
                  top: -2,
                  end: -4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    constraints:
                        const BoxConstraints(minWidth: 15, minHeight: 15),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tc.accent,
                      borderRadius: BorderRadius.circular(8),
                      // Rings the badge against the accent circle behind it so
                      // the count stays legible where the two overlap.
                      border: Border.all(color: tc.background, width: 1.5),
                    ),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: TextStyle(
                        color: tc.accentContrast,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
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

  /// Resolves [isSuppressed] against the live router location and workout
  /// session. Public so the cluster can drop the inter-button gap in lockstep
  /// with the circle instead of leaving a hole where it used to be.
  static bool suppressedIn(BuildContext context, WidgetRef ref) {
    // The draggable chat-head bubble (Settings → AI Coach, default OFF) is the
    // SAME affordance in a different form, and `main_shell` mounts it into the
    // same bottom-right band. Rendering both gives an opt-in user two coach
    // entry points stacked on each other. The toggle picks one: bubble on →
    // circle off. Resolved here rather than at either mount site so the
    // cluster's inter-button gap closes in lockstep (see
    // `CoachQuickLogCluster._coachHidden`).
    if (ref.watch(edgeHandleEnabledProvider)) return true;
    // A workout is live for as long as the mini player holds its workout —
    // `close()` is the only thing that clears it.
    final workoutActive =
        ref.watch(workoutMiniPlayerProvider.select((s) => s.workout != null));
    final router = GoRouter.maybeOf(context);
    final location =
        router?.routerDelegate.currentConfiguration.uri.path ?? '';
    return isSuppressed(location: location, workoutActive: workoutActive);
  }

  void _open(BuildContext context) {
    HapticService.light();
    context.push('/chat?source=coach_fab');
  }
}

/// Corner mount for surfaces that have **no** main nav / Quick Log cluster to
/// join — a pushed full-screen route such as the Library.
///
/// Inside the shell the button is part of the cluster in `main_shell.dart`;
/// never mount both, or the two floats fight for the same band.
class CoachFloatingButtonCorner extends StatelessWidget {
  /// Extra vertical lift (pt) for screens that dock their own CTA at the
  /// bottom edge, so the circle floats clearly above it.
  final double extraBottomOffset;

  const CoachFloatingButtonCorner({super.key, this.extraBottomOffset = 0});

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      end: 16,
      bottom: MediaQuery.viewPaddingOf(context).bottom + 16 + extraBottomOffset,
      child: const CoachFloatingButton(),
    );
  }
}
