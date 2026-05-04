import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/haptic_service.dart';

/// Floating glassmorphic pill bar for switching between the four Nutrition
/// sub-screens (Daily / Recipes / Patterns / Fuel).
///
/// Replaces the inline `SegmentedTabBar` that sat at the top of the screen.
/// Docks just above the bottom nav so the user's thumb always lands on it
/// without reaching to the top, mirroring iOS 17 / Apple Music's floating
/// tab pattern.
///
/// Glass recipe lifted from `widgets/glass_circle_fab.dart`:
/// `BackdropFilter(blur σ≈20)` over a translucent surface (8-12% white in
/// dark mode, 6-10% black in light) wrapped in a 28px ClipRRect.
class GlassNutritionTabBar extends StatelessWidget {
  final TabController controller;
  final List<NutritionTabItem> items;
  final Color accentColor;
  final ValueChanged<int>? onTap;

  const GlassNutritionTabBar({
    super.key,
    required this.controller,
    required this.items,
    required this.accentColor,
    this.onTap,
  });

  /// Vertical space the floating bar occupies — content above must add this
  /// (plus the bottom safe area + bottom nav height) as bottom padding so
  /// the last list item isn't hidden under the bar.
  static const double kBarHeight = 56;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // iOS 26 "Liquid Glass" surface treatment.
    //
    // Recipe (matches Apple Calendar's category pill bar):
    //   1. Outer container = full capsule (radius = height/2)
    //   2. BackdropFilter with high sigma (≈ 32) + chromatic-aberration-ish
    //      brightness boost via a subtle top→bottom gradient on the fill.
    //   3. Hairline white-tinted border that catches "light" along the top.
    //   4. Specular highlight: thin bright gradient stroke along the top
    //      half of the capsule (linear, top-bright → midline-transparent).
    //   5. Each item is its OWN capsule. Active = thick (1.6px) accent
    //      outline + accent-tinted fill + accent text/icon. Inactive =
    //      no border, transparent fill, muted text.
    //   6. Drop shadow softer + tighter than a standard card so the bar
    //      reads as a floating layer, not a stacked card.
    // Fills are deliberately opaque enough that colored content behind
    // (e.g. the Recipes "Build" FAB's red gradient) doesn't tint the
    // glass through the BackdropFilter. Previously (light: 0.55→0.28)
    // the bottom of the bar picked up the red of any FAB sitting near it.
    //
    // Dark mode uses a near-black tinted fill (not white-on-dark, which
    // reads as a milky grey slab and kills the glass illusion). The
    // surface should disappear into the page; the active pill does the
    // visual work.
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
    final textActive = accentColor;

    final radius = BorderRadius.circular(kBarHeight / 2);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Stack(
          children: [
            // Base translucent fill — the "glass" body. Vertical gradient
            // so the top edge reads brighter (light from above), bottom
            // settles into the page. Positioned.fill so it doesn't claim
            // intrinsic width (the items Row below should drive bar width
            // so the whole bar hugs its labels).
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
                  // Faint inner glow at the top so the rim catches "light".
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
            // Specular highlight band along the top half — the bright
            // "liquid" sheen that defines the iOS 26 look. Drawn ABOVE the
            // base fill but BELOW the items so the active capsule's
            // outline still reads cleanly.
            Positioned(
              left: 1,
              right: 1,
              top: 1,
              height: kBarHeight * 0.55,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(kBarHeight / 2),
                      topRight: Radius.circular(kBarHeight / 2),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        specular,
                        specular.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Items — each its own capsule. Sized to content (not Expanded)
            // so the whole bar hugs its labels and matches the floating
            // bottom nav's intrinsic-width pattern instead of stretching
            // edge-to-edge.
            SizedBox(
              height: kBarHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: AnimatedBuilder(
                  animation: controller.animation ?? controller,
                  builder: (_, __) {
                    final activeIdx = controller.index;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < items.length; i++)
                          _PillButton(
                            item: items[i],
                            active: i == activeIdx,
                            textInactive: textInactive,
                            textActive: textActive,
                            accentColor: accentColor,
                            isDark: isDark,
                            onTap: () {
                              if (controller.index != i) {
                                HapticService.selection();
                                controller.animateTo(i);
                              }
                              onTap?.call(i);
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NutritionTabItem {
  final String label;
  final IconData icon;
  const NutritionTabItem({required this.label, required this.icon});
}

class _PillButton extends StatelessWidget {
  final NutritionTabItem item;
  final bool active;
  final Color textInactive;
  final Color textActive;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const _PillButton({
    required this.item,
    required this.active,
    required this.textInactive,
    required this.textActive,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Each item is its own capsule (radius = height/2), iOS 26 Liquid
    // Glass style: active gets a saturated accent outline + tinted glass
    // fill + a top specular sheen; inactive sits transparent.
    const double pillHeight = 38;
    final pillRadius = BorderRadius.circular(pillHeight / 2);
    // Active pill: clean accent outline + subtle accent-tinted fill.
    // No outer glow shadow, no inner white specular sheen — the user
    // explicitly does not want the foggy/halo look. The crisp ring +
    // bold accent text carries the "selected" weight on its own.
    final pillFill = active
        ? accentColor.withValues(alpha: isDark ? 0.18 : 0.12)
        : Colors.transparent;
    final pillBorder = active
        ? Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.95 : 0.85),
            width: 1.6,
          )
        : null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        height: pillHeight,
        decoration: BoxDecoration(
          color: pillFill,
          borderRadius: pillRadius,
          border: pillBorder,
        ),
        child: ClipRRect(
          borderRadius: pillRadius,
          child: Stack(
            children: [
              // Text-only labels — matches Apple Calendar's iOS 26 category
              // pill bar (Holiday / Meetups / Marketing / Focus). Icons in
              // a 4-tab strip squeeze the longest label ("Patterns") into
              // ellipsis on phone widths even at 12.5pt; ditching them
              // gives every label its full glyph width.
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? textActive : textInactive,
                        letterSpacing: 0.0,
                      ),
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
}
