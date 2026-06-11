import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/motion_tokens.dart';
import '../core/constants/type_scale.dart';
import '../data/services/haptic_service.dart';

/// One segment of a [TopSegmentedControl].
class TopSegmentItem {
  final String label;
  final IconData? icon;

  const TopSegmentItem({required this.label, this.icon});
}

/// Top-of-screen segmented control — the chrome-consolidation Variant A from
/// the 2026-06 UI review (docs/planning/redesign-2026-06/ui-review-mockup.html,
/// Change 3). Replaces the bottom floating sub-tab pills on Nutrition,
/// Leaderboard, and You so only ONE floating bar (the main nav) remains at the
/// bottom of those tabs.
///
/// Sits in normal flow under the screen header (not floating), full width,
/// with the selected segment tinted by the dynamic accent. Selection animates
/// with the standard motion token.
class TopSegmentedControl extends StatelessWidget {
  final List<TopSegmentItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color accentColor;

  const TopSegmentedControl({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selectedIndex,
                label: items[i].label,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () {
                    if (i == selectedIndex) return;
                    HapticService.selection();
                    onSelected(i);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: kMotionStandard,
                    curve: kMotionCurve,
                    decoration: BoxDecoration(
                      color: i == selectedIndex
                          ? accentColor.withValues(alpha: isDark ? 0.16 : 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (items[i].icon != null) ...[
                          Icon(
                            items[i].icon,
                            size: 14,
                            color: i == selectedIndex ? accentColor : muted,
                          ),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: Text(
                            items[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: kTypeLabelSize,
                              fontWeight: FontWeight.w700,
                              color: i == selectedIndex ? accentColor : muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
