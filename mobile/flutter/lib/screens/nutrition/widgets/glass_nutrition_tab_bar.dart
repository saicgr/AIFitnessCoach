import 'package:flutter/material.dart';

import '../../../widgets/floating_tab_bar.dart';

/// Floating tab bar for switching between the four Nutrition sub-screens
/// (Daily / Recipes / Patterns / Fuel).
///
/// Thin adapter over the shared [FloatingTabBar] — keeps this widget's
/// public constructor / API stable while delegating all chrome to the one
/// canonical floating bar. Runs in [FloatingTabBarMode.viewSwitcher]: it
/// drives the [controller] and reflects its current index as a sticky pill.
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

  /// Vertical space the floating bar occupies. Kept for callsite layout
  /// math; mirrors [kFloatingTabBarHeight].
  static const double kBarHeight = kFloatingTabBarHeight;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.animation ?? controller,
      builder: (_, __) => FloatingTabBar(
        mode: FloatingTabBarMode.viewSwitcher,
        accentColor: accentColor,
        selectedIndex: controller.index,
        onTap: (i) {
          if (controller.index != i) {
            controller.animateTo(i);
          }
          onTap?.call(i);
        },
        items: [
          for (final item in items)
            FloatingTabItem(label: item.label, icon: item.icon),
        ],
      ),
    );
  }
}

class NutritionTabItem {
  final String label;
  final IconData icon;
  const NutritionTabItem({required this.label, required this.icon});
}
