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
