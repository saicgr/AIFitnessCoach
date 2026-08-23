/// Chrome geometry tokens — single source of truth for the floating
/// bottom-nav pill and the clearances every tab screen must reserve for it.
///
/// Before 2026-06 these lived as scattered literals (`56.0` in the nav bar,
/// `+ 68` in Workouts/Discover/You bottom insets, `56 + 32` in home's final
/// sliver), which meant a nav-height change required hunting five files.
/// Values are unchanged — this file only names them.
///
/// ## THE FLOAT BAND HAS EXACTLY ONE OWNER AND EXACTLY TWO SLOTS
///
/// The trailing-edge band between `safeArea + kQuickLogFabBottomOffset` (92)
/// and `safeArea + kQuickLogFabClearance` (148) belongs to
/// `CoachQuickLogCluster` and to nothing else. It holds the ✦ coach circle and
/// the Quick Log FAB, both [kFloatCircleDiameter] wide, separated by
/// [kFloatClusterGap].
///
/// A new floating affordance may only:
///   (a) REPLACE a slot under mutual exclusion — which
///       `CoachFloatingButton.suppressedIn` ↔ `FloatingChatBubble` already
///       does (chat-head on ⇒ coach circle off), or
///   (b) become a ROW INSIDE the Quick Log sheet.
///
/// Never a third `Positioned`. D4 (2026-08) is what a third one looks like on
/// a real device: three circles, three diameters, stacked on the founder's
/// content. `test/widgets/coach_pill_placement_test.dart` fails if a third
/// float appears in the cluster or if the two stop sharing a diameter.
library;

/// Height of the floating main nav pill itself (excludes safe-area inset).
const double kMainNavBarHeight = 56.0;

/// Gap between the nav pill and the bottom safe-area edge.
const double kMainNavBottomGap = 10.0;

/// ── The float family ────────────────────────────────────────────────────────
///
/// ONE diameter for every circular floating control in the app, no exceptions.
///
/// D4 (2026-08, real device): the founder photographed three floating controls
/// in the bottom-right band at three visibly different diameters. Root cause
/// was three independent literals — the coach circle's own `kCoachPillDiameter`
/// (40), the quick-log FAB's [kQuickLogFabHeight] (44) and the opt-in
/// chat-head's hardcoded `56` — none of which derived from each other, so
/// "they should match" was a convention nobody could enforce. Naming the
/// diameter once makes a mismatch impossible to write by accident: there is no
/// second number to disagree with.
///
/// 44 (not 40) because it is the platform minimum touch target on both iOS and
/// Android, and it is the diameter of the control that is actually tapped
/// daily. The coach circle used to be deliberately 4 pt smaller to encode
/// "secondary"; that hierarchy is now carried by fill and label (raised surface
/// + icon-only vs. accent glyph + caption) rather than by shrinking one member
/// of the pair below the touch-target floor.
const double kFloatCircleDiameter = 44.0;

/// Optical size of the glyph inside a [kFloatCircleDiameter] float.
///
/// `round(44 * 0.41)`. Both floats in the cluster must share it — matched
/// circles with mismatched glyphs (the coach ✦ was 15, the quick-log + was 16)
/// still read as two different controls.
const double kFloatGlyphSize = 18.0;

/// Gap between two floats inside the bottom-right cluster.
///
/// A constant, not a computed value: the whole point of the cluster is that
/// this distance never changes while Quick Log morphs pill↔circle. Renamed
/// from `kCoachPillClusterGap` (which lived in `coach_floating_button.dart`)
/// so the gap and the diameter it sits between are declared side by side.
const double kFloatClusterGap = 10.0;

/// Vertical bleed of a float's drop shadow past its own box.
///
/// Names the `+ 12` that [kQuickLogFabClearance] used to carry as a bare magic
/// number. The float shadow is `blurRadius: 24, offset: (0, 10)`; 12 is the
/// visually-significant portion above the box.
const double kFloatShadowBleed = 12.0;

/// Height of the scrim gradient faded in above the nav pill.
///
/// Derived, not chosen: the scrim must start ABOVE the float band, or the
/// floats sit on raw fully-opaque content. At the old literal 36 the scrim's
/// top edge landed at `bottomPadding + 92` — exactly the FAB's BOTTOM edge —
/// so the entire 44 pt cluster plus its shadow floated on unveiled content.
/// That is why the coach circle sat on top of the Connect Health card in the
/// founder's screenshot. Sized so the scrim's top sits 10 pt clear of
/// [kQuickLogFabClearance] (the top of the float band including shadow bleed).
const double kMainNavFadeHeight =
    kQuickLogFabClearance - kMainNavBarHeight + 10;

/// Horizontal inset of the ✦-coach + Quick-Log cluster from the screen's
/// trailing edge.
///
/// 14, per the 2026-08 nav mockup's `.fabband{right:14px}`. It used to be a
/// bare `24` inside `main_shell.dart`, which parked the cluster 10 px inboard
/// of the nav's own 6 px gutter so the two right edges never lined up. Named
/// here because both the cluster's `PositionedDirectional(end:)` and the
/// `maxWidth` bound it grows into have to agree.
const double kFabClusterEdgeInset = 14.0;

/// Vertical space (above the safe-area inset) a screen must clear so content
/// can scroll fully out from under the floating nav: pill height + the gap
/// below it, rounded up by 2 for the pill shadow. Historically written as
/// the bare literal `68`.
const double kMainNavClearance = kMainNavBarHeight + kMainNavBottomGap + 2;

/// Extra breathing room home adds beneath its last sliver (Surface 1.9).
const double kHomeBottomBreathingRoom = 32.0;

/// Height of the quick-log FAB that floats above the nav pill.
///
/// Lives here rather than in `widgets/quick_log_fab_chrome.dart` (which
/// re-exports it, so nothing that imports it today has to change) because
/// non-widget chrome has to reason about the button's footprint too — see
/// [kSnackBarBottomInset].
const double kQuickLogFabHeight = kFloatCircleDiameter;

/// Gap between the top of the nav pill and the bottom of the quick-log FAB.
///
/// Register #177 (a #16 recurrence): #16 fixed the FAB covering content it
/// scrolls PAST (the trailing [kQuickLogFabClearance] reservation below).
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

/// Distance from the bottom safe-area inset to the BOTTOM of the quick-log FAB.
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
    kQuickLogFabBottomOffset + kFloatCircleDiameter + kFloatShadowBleed;

/// Horizontal space a right-anchored CTA/row must reserve so the FAB cluster
/// (coach circle + expanded Quick Log pill, see [CoachQuickLogCluster]) never
/// clips its trailing edge. [kQuickLogFabClearance] only reserves VERTICAL
/// scroll room at the end of a list — it does nothing for a primary CTA that
/// happens to render at the cluster's fixed on-screen vertical band (e.g. an
/// empty state near the top of a short tab), where the fix is horizontal, not
/// scroll position. Sized for two [kFloatCircleDiameter] circles + the gap
/// between them + a generous expanded-pill label allowance + the edge inset.
const double kFabClusterHorizontalReserve =
    kFloatCircleDiameter * 2 + kFloatClusterGap + 90 + kFabClusterEdgeInset;

/// Bottom inset a floating `SnackBar` must use.
///
/// E2E row 125: this was the literal `80`, which put the toast band squarely
/// across the quick-log FAB (whose box is `[92, 136]` above the safe-area
/// inset). The FAB is a `Positioned` child of the shell Stack added AFTER the
/// tab content, and the SnackBar is shown through the tab's own Scaffold, so
/// the button always paints ON TOP of the toast — and because the button uses
/// `HitTestBehavior.opaque` and Stack hit-tests last-child-first, a tap in the
/// overlap opened the quick-log sheet instead of firing the toast's action.
/// That made "UNDO" (the app's ONLY caller of `undoEndFast`) both unreadable
/// and untappable for the whole life of the toast.
///
/// Deriving it from the FAB's own geometry — rather than picking another
/// literal — is what keeps the two from drifting apart the next time the
/// button moves.
const double kSnackBarBottomInset = kQuickLogFabClearance;
