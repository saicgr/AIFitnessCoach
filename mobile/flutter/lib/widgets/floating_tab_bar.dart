import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../data/services/haptic_service.dart';

/// Canonical floating tab / options bar.
///
/// One source of truth for the bar that docks just above MainShell's
/// floating bottom nav. Replaces the four divergent implementations
/// (`GlassNutritionTabBar`, the Discover segmented bar, the You-hub bar,
/// `WorkoutsFloatingOptionsBar`) with a single component so every tab is
/// pixel-consistent.
///
/// Layout (matches the floating bottom nav — see `main_shell` D3/D4):
///   * Centered, fixed-width capsule. Width = screen width minus
///     [kFloatingTabBarSideInset] gutters, clamped to [kFloatingTabBarMaxWidth]
///     so it never stretches on tablets. The bottom nav is intrinsic-width
///     but centered identically, so the two capsules share a centerline.
///   * iOS 26 "Liquid Glass" recipe: `BackdropFilter` blur σ≈32 over a
///     translucent vertical gradient fill, hairline border, top specular
///     sheen, soft drop shadow.
///   * Items render ICON-ON-TOP / LABEL-BELOW (vertical), each in an
///     equal-width slot. Mirrors the bottom nav's item style.
///   * Supports 3–5 items with no overflow on the smallest device — labels
///     scale via [FittedBox].
///
/// Two modes ([FloatingTabBarMode]):
///   * `viewSwitcher` — persistent selected pill (Nutrition / Discover /
///     You). [selectedIndex] is required.
///   * `launcher` — momentary highlight on tap, no persistent pill
///     (Workouts). [selectedIndex] may be null.
///
/// Dock it as a `Positioned` child stacked over the screen body, e.g.
/// `bottom: MediaQuery.of(context).viewPadding.bottom + 68`.
const double kFloatingTabBarHeight = 56;

/// Horizontal screen gutter on each side (total inset = 2× this).
///
/// Tuned so the capsule width pairs visually with MainShell's bottom nav
/// bar — that bar is intrinsic-width and centered, noticeably inset from the
/// screen edges, so the floating bar uses a wide gutter to sit at a similar
/// width instead of stretching near edge-to-edge.
const double kFloatingTabBarSideInset = 30;

/// Upper bound on the capsule width so it never looks stretched on tablets
/// and stays close to the bottom nav bar's footprint.
const double kFloatingTabBarMaxWidth = 380;

enum FloatingTabBarMode {
  /// Persistent selected pill — for TabController-style view switching.
  viewSwitcher,

  /// Momentary highlight only — for action launchers (no sticky pill).
  launcher,
}

/// A single entry in [FloatingTabBar].
class FloatingTabItem {
  final String label;
  final IconData icon;

  /// Optional per-item icon override. Falls back to the bar accent.
  final Color? iconColor;

  const FloatingTabItem({
    required this.label,
    required this.icon,
    this.iconColor,
  });
}

class FloatingTabBar extends StatelessWidget {
  final List<FloatingTabItem> items;

  /// Currently-selected index. Required for [FloatingTabBarMode.viewSwitcher];
  /// may be null for [FloatingTabBarMode.launcher].
  final int? selectedIndex;

  /// Tap callback — receives the tapped item index.
  final ValueChanged<int> onTap;

  /// Accent color (per-gym). Pass `ref.colors(context).accent`.
  final Color accentColor;

  /// View-switcher (sticky pill) vs launcher (momentary highlight).
  final FloatingTabBarMode mode;

  const FloatingTabBar({
    super.key,
    required this.items,
    required this.onTap,
    required this.accentColor,
    this.selectedIndex,
    this.mode = FloatingTabBarMode.viewSwitcher,
  });

  @override
  Widget build(BuildContext context) {
    assert(items.length >= 2 && items.length <= 5,
        'FloatingTabBar supports 3–5 items (2 allowed); got ${items.length}');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Liquid Glass surface — dark mode uses a near-black tinted fill so the
    // surface recedes into the page; the active pill does the visual work.
    final outerFillTop = isDark
        ? Colors.black.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.78);
    final outerFillBottom = isDark
        ? Colors.black.withValues(alpha: 0.40)
        : Colors.white.withValues(alpha: 0.62);
    final outerBorder = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.65);
    final specular = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.85);
    final textInactive = isDark
        ? Colors.white.withValues(alpha: 0.62)
        : AppColorsLight.textSecondary;

    final radius = BorderRadius.circular(kFloatingTabBarHeight / 2);

    // Fixed width — screen minus gutters, clamped. Centered at the callsite
    // so it shares a centerline with the (centered) bottom nav bar.
    final barWidth =
        (MediaQuery.of(context).size.width - kFloatingTabBarSideInset * 2)
            .clamp(0.0, kFloatingTabBarMaxWidth);

    return SizedBox(
      width: barWidth,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: Stack(
            children: [
              // Base translucent fill — the "glass" body.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [outerFillTop, outerFillBottom],
                    ),
                    border: Border.all(color: outerBorder, width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.32 : 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.white
                            .withValues(alpha: isDark ? 0.04 : 0.18),
                        blurRadius: 1,
                        offset: const Offset(0, -1),
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                ),
              ),
              // Specular highlight band along the top half.
              PositionedDirectional(start: 1,
                end: 1,
                top: 1,
                height: kFloatingTabBarHeight * 0.55,
                       child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(kFloatingTabBarHeight / 2),
                        topRight: Radius.circular(kFloatingTabBarHeight / 2),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [specular, specular.withValues(alpha: 0.0)],
                      ),
                    ),
                  ),
                ),
              ),
              // Items — each gets an equal-width Expanded slot so 3–5 items
              // fit the fixed width without overflow.
              SizedBox(
                height: kFloatingTabBarHeight,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Row(
                    children: [
                      for (int i = 0; i < items.length; i++)
                        Expanded(
                          child: _TabItemPill(
                            item: items[i],
                            active: selectedIndex == i,
                            accentColor: accentColor,
                            textInactive: textInactive,
                            isDark: isDark,
                            onTap: () {
                              HapticService.selection();
                              onTap(i);
                            },
                          ),
                        ),
                    ],
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

/// One icon-on-top / label-below pill. Active = accent ring + tinted fill.
class _TabItemPill extends StatelessWidget {
  final FloatingTabItem item;
  final bool active;
  final Color accentColor;
  final Color textInactive;
  final bool isDark;
  final VoidCallback onTap;

  const _TabItemPill({
    required this.item,
    required this.active,
    required this.accentColor,
    required this.textInactive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pillRadius = BorderRadius.circular(16);
    final pillFill = active
        ? accentColor.withValues(alpha: isDark ? 0.18 : 0.12)
        : Colors.transparent;
    final pillBorder = active
        ? Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.95 : 0.85),
            width: 1.6,
          )
        : null;
    final iconColor =
        active ? accentColor : (item.iconColor ?? textInactive);
    final labelColor = active ? accentColor : textInactive;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: pillFill,
          borderRadius: pillRadius,
          border: pillBorder,
        ),
        child: ClipRRect(
          borderRadius: pillRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            // The whole icon+label unit scales down to whatever vertical
            // space the docked bar gives the slot — no overflow on any
            // device or text-scale setting.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, size: 19, color: iconColor),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: labelColor,
                      letterSpacing: 0.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
