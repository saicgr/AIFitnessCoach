import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../data/services/haptic_service.dart';

/// Floating iOS 26 "Liquid Glass" action bar.
///
/// Same visual recipe as `screens/nutrition/widgets/glass_nutrition_tab_bar.dart`
/// (full capsule, heavy `BackdropFilter` blur, vertical surface gradient,
/// hairline white-tinted border, top specular sheen, soft drop shadow) but
/// for navigation-style action lists where each item just fires an `onTap`
/// (no persistent active item / no `TabController`).
///
/// Use it as a `Positioned` child stacked over the screen body. Add bottom
/// padding to the scrollable content equal to `kLiquidGlassActionBarHeight +
/// floatingNavBarHeight + safeAreaBottom` so the last list item isn't
/// hidden behind the bar.
const double kLiquidGlassActionBarHeight = 56;

class LiquidGlassActionBar extends StatelessWidget {
  final List<LiquidGlassAction> items;

  /// Optional accent override. Falls back to the active app accent at the
  /// callsite if you wire one in there. Used for the icon tint on each pill.
  final Color? accentColor;

  /// When set, renders the matching item as the "active" pill (Liquid
  /// Glass accent outline + tinted fill + specular sheen). Use this for
  /// tab-style usage where the bar reflects which view is currently
  /// shown. Leave null for action-list usage where every tap is a
  /// fresh navigation event with no persistent state.
  final int? selectedIndex;

  const LiquidGlassActionBar({
    super.key,
    required this.items,
    this.accentColor,
    this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Dark mode uses near-black tinted fill (white-on-dark reads as a
    // milky grey slab and kills the glass illusion). Surface should
    // recede; the active pill does the visual work. See
    // glass_nutrition_tab_bar.dart for the matching treatment.
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
    final textColor = isDark
        ? Colors.white.withValues(alpha: 0.62)
        : AppColorsLight.textSecondary;
    final iconAccent = accentColor ??
        (isDark ? AppColors.accent : AppColorsLight.accent);
    final radius = BorderRadius.circular(kLiquidGlassActionBarHeight / 2);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Stack(
          children: [
            // Base fill is Positioned.fill so it doesn't claim intrinsic
            // width — the items Row drives the bar's width so the bar
            // hugs its labels and matches the floating bottom nav.
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
                    color:
                        Colors.black.withValues(alpha: isDark ? 0.32 : 0.12),
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
            Positioned(
              left: 1,
              right: 1,
              top: 1,
              height: kLiquidGlassActionBarHeight * 0.55,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft:
                          Radius.circular(kLiquidGlassActionBarHeight / 2),
                      topRight:
                          Radius.circular(kLiquidGlassActionBarHeight / 2),
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
            // Items sized to content (not Expanded) so the whole bar is
            // intrinsic-width and matches the floating bottom nav.
            SizedBox(
              height: kLiquidGlassActionBarHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < items.length; i++)
                      _ActionPill(
                        item: items[i],
                        textColor: textColor,
                        iconAccent: items[i].iconColor ?? iconAccent,
                        isDark: isDark,
                        active: selectedIndex == i,
                        activeAccent: iconAccent,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LiquidGlassAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  /// Per-pill icon override (e.g. red heart for Favorites). Falls back to
  /// the bar's [accentColor] when null.
  final Color? iconColor;

  const LiquidGlassAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });
}

class _ActionPill extends StatelessWidget {
  final LiquidGlassAction item;
  final Color textColor;
  final Color iconAccent;
  final bool isDark;
  final bool active;
  final Color activeAccent;

  const _ActionPill({
    required this.item,
    required this.textColor,
    required this.iconAccent,
    required this.isDark,
    this.active = false,
    required this.activeAccent,
  });

  @override
  Widget build(BuildContext context) {
    // Clean accent ring + subtle accent-tinted fill on active. No outer
    // glow shadow, no inner white specular — the user explicitly does
    // not want the foggy/halo treatment. Bold accent text + crisp ring
    // carries the "selected" weight on its own.
    final pillRadius = BorderRadius.circular(999);
    final pillFill = active
        ? activeAccent.withValues(alpha: isDark ? 0.18 : 0.12)
        : Colors.transparent;
    final pillBorder = active
        ? Border.all(
            color: activeAccent.withValues(alpha: isDark ? 0.95 : 0.85),
            width: 1.6,
          )
        : null;
    final activeText = activeAccent;

    final inner = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 16,
              color: active ? activeText : iconAccent,
            ),
            const SizedBox(width: 5),
            Text(
              item.label,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active ? activeText : textColor,
                letterSpacing: 0.0,
              ),
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticService.selection();
        item.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: pillFill,
          borderRadius: pillRadius,
          border: pillBorder,
        ),
        child: ClipRRect(
          borderRadius: pillRadius,
          child: Center(child: inner),
        ),
      ),
    );
  }
}
