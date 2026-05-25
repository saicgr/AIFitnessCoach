import 'package:flutter/material.dart';

import '../../../widgets/floating_tab_bar.dart';

import '../../../l10n/generated/app_localizations.dart';
/// A single launcher entry in [WorkoutsFloatingOptionsBar].
class WorkoutsOptionItem {
  final String label;
  final IconData icon;
  const WorkoutsOptionItem({required this.label, required this.icon});
}

/// Floating launcher bar for the Workouts tab.
///
/// Thin adapter over the shared [FloatingTabBar] — keeps this widget's
/// public constructor / API stable (`workouts_screen.dart` depends on it)
/// while delegating all chrome to the one canonical floating bar.
///
/// Runs in [FloatingTabBarMode.launcher]: each item fires a real action
/// (scroll to planner, open the gym sheet, navigate to the exercise
/// library / the multi-week program library) rather than switching a
/// TabController. The active index is still reflected as a momentary
/// highlight. The bar is item-count agnostic — [items] currently carries
/// four entries (Plan / Manage Gym / Library / Programs); History moved
/// to the Workouts-tab quick-actions row in B.3.1.
class WorkoutsFloatingOptionsBar extends StatelessWidget {
  final List<WorkoutsOptionItem> items;
  final int activeIndex;
  final ValueChanged<int> onSelected;
  final Color accentColor;

  const WorkoutsFloatingOptionsBar({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onSelected,
    required this.accentColor,
  });

  /// Vertical space the floating bar occupies. Kept for callsite layout
  /// math; mirrors [kFloatingTabBarHeight].
  static const double kBarHeight = kFloatingTabBarHeight;

  @override
  Widget build(BuildContext context) {
    return FloatingTabBar(
      mode: FloatingTabBarMode.launcher,
      accentColor: accentColor,
      selectedIndex: activeIndex,
      onTap: onSelected,
      items: [
        for (final item in items)
          FloatingTabItem(
            // D5 — "Gym" reads ambiguously next to the in-tab gym
            // switcher; surface it as "Manage Gym". Remapped here (not in
            // workouts_screen.dart) so the bar's data contract is stable.
            label: item.label == AppLocalizations.of(context).workoutsGym ? AppLocalizations.of(context).workoutsFloatingOptionsManageGym : item.label,
            icon: item.icon,
          ),
      ],
    );
  }
}
