/// Chrome geometry tokens — single source of truth for the floating
/// bottom-nav pill and the clearances every tab screen must reserve for it.
///
/// Before 2026-06 these lived as scattered literals (`56.0` in the nav bar,
/// `+ 68` in Workouts/Discover/You bottom insets, `56 + 32` in home's final
/// sliver), which meant a nav-height change required hunting five files.
/// Values are unchanged — this file only names them.
library;

/// Height of the floating main nav pill itself (excludes safe-area inset).
const double kMainNavBarHeight = 56.0;

/// Gap between the nav pill and the bottom safe-area edge.
const double kMainNavBottomGap = 10.0;

/// Height of the scrim gradient faded in above the nav pill.
const double kMainNavFadeHeight = 36.0;

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
const double kQuickLogFabHeight = 44.0;

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
    kQuickLogFabBottomOffset + kQuickLogFabHeight + 12;

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
