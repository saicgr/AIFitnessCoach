/// Persistent coach-access FAB rendered by `MainShell` above the floating
/// nav bar on every main tab. Adapts its shape to the active tab:
///
///   * **Home** (no sub-tab strip on screen): renders as an extended pill
///     ("Ask coach" + sparkle) at the top of scroll, collapses to icon
///     once the user scrolls past ~24pt. Scroll-driven morph state lives
///     in [coachFabExpandedProvider], driven by a NotificationListener
///     in `main_shell.dart`.
///   * **Workout / Nutrition / Discover / You** (sub-tab strips exist):
///     always renders icon-only (44pt circle) so the FAB never obscures
///     a strip tab behind it.
///
/// In both cases tap → `/chat?source=coach_fab`. Light haptic + explicit
/// hero tag. Rendered BEFORE the nav in the Stack so any downward shadow
/// bleed is covered by the nav's paint area.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme_colors.dart';
import '../data/services/haptic_service.dart';

/// Whether the FAB is in extended ("Ask coach" pill) state. Owned by
/// `MainShell` (NotificationListener writes it on scroll threshold cross);
/// read by [CoachFloatingButton]. Only consulted on Home; other tabs
/// force icon-only regardless of this flag.
///
/// Surface 1.8 — defaults to collapsed (icon-only). The FAB expands to
/// the "Ask coach" pill after the user idles at scroll position 0 for
/// 800ms (driven by the scroll listener in `main_shell.dart`). Any scroll
/// collapses it immediately.
final coachFabExpandedProvider = StateProvider<bool>((ref) => false);

class CoachFloatingButton extends ConsumerWidget {
  /// True when the active tab is Home — drives the pill-vs-icon decision.
  /// Set by `MainShell` from its `selectedIndex`. Defaults to false so a
  /// stale construction never accidentally shows the wide pill on a
  /// strip-having tab.
  final bool isHomeTab;

  /// When true (default), the FAB is lifted to clear the floating bottom nav
  /// (`bottomInset + nav + gap`). Screens pushed ON TOP of the shell that have
  /// NO bottom nav (e.g. the Library) pass `false` so the FAB sits near the
  /// real bottom edge instead of floating ~100pt up over content (issue 10).
  final bool liftAboveNav;

  const CoachFloatingButton({
    super.key,
    this.isHomeTab = false,
    this.liftAboveNav = true,
  });

  /// Vertical gap between the top of the floating nav and the bottom of
  /// the FAB. Surface 1.8 tucks the FAB up 24pt so it sits in the empty
  /// gap above the Workout hero on Home rather than over the Reports /
  /// Today rings card. Previously 20pt.
  static const double _gapAboveNav = 44.0;
  static const double _navHeight = 56.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    // Only Home tab is allowed to extend; other tabs force the FAB to
    // its icon-only form regardless of scroll-position state.
    final isExtended = isHomeTab && ref.watch(coachFabExpandedProvider);

    return Positioned(
      right: 16,
      bottom: liftAboveNav
          ? bottomInset + _navHeight + _gapAboveNav
          // No nav on this screen — sit just above the home indicator.
          : bottomInset + 16,
      child: GestureDetector(
        onTap: () => _open(context),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          // Pill (extended) ↔ 36pt circle (collapsed). The collapsed
          // form is intentionally the SAME visual as the strip's coach
          // slot (`_FloatingTabBarCoachSlot` in floating_tab_bar.dart)
          // — same 36pt diameter, same accent fill, same accent shadow.
          // When the user scrolls on Home, the FAB shrinks into that
          // exact look so the affordance reads identically across
          // tabs.
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          height: isExtended ? 48 : 36,
          padding: EdgeInsets.symmetric(
            horizontal: isExtended ? 12 : 0,
          ),
          decoration: BoxDecoration(
            color: c.accent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: c.accent.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container sized to 36pt always — matches the strip
              // slot exactly. When extended, this 36pt circle sits at
              // the left of the pill alongside the label; when
              // collapsed it IS the entire FAB.
              SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: c.accentContrast,
                    semanticLabel: 'Ask coach',
                  ),
                ),
              ),
              // Label area — slides + fades horizontally as it appears
              // / disappears, so the morph reads as the pill growing
              // out from / contracting into the small circle rather
              // than a hard pop.
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(-0.25, 0),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: isExtended
                        ? Padding(
                            key: const ValueKey('label'),
                            padding: const EdgeInsets.only(left: 4, right: 4),
                            child: Text(
                              'Ask coach',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.1,
                                color: c.accentContrast,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('empty'),
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

  void _open(BuildContext context) {
    HapticService.light();
    try {
      context.push('/chat?source=coach_fab');
    } catch (_) {
      context.go('/chat');
    }
  }
}

// `_ExtendedPill` and `_IconOnly` helper widgets were removed — the
// build method now uses a single `FloatingActionButton.extended` with
// `isExtended` toggling between states, so Flutter's native morph
// animation handles the smooth pill↔icon transition.
