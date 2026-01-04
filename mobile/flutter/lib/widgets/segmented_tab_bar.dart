import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';

/// A modern segmented tab bar with smooth animations.
///
/// This widget replaces the default TabBar with a pill-style
/// segmented control that animates smoothly between selections.
class SegmentedTabBar extends StatelessWidget {
  final TabController controller;
  final List<SegmentedTabItem> tabs;
  final bool showIcons;
  final EdgeInsets padding;
  final double borderRadius;

  const SegmentedTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.showIcons = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: padding,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(borderRadius + 4),
        ),
        padding: const EdgeInsets.all(4),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Row(
              children: List.generate(tabs.length, (index) {
                return _SegmentedTabButton(
                  index: index,
                  item: tabs[index],
                  controller: controller,
                  isDark: isDark,
                  showIcon: showIcons,
                  borderRadius: borderRadius,
                  isFirst: index == 0,
                  isLast: index == tabs.length - 1,
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _SegmentedTabButton extends StatelessWidget {
  final int index;
  final SegmentedTabItem item;
  final TabController controller;
  final bool isDark;
  final bool showIcon;
  final double borderRadius;
  final bool isFirst;
  final bool isLast;

  const _SegmentedTabButton({
    required this.index,
    required this.item,
    required this.controller,
    required this.isDark,
    required this.showIcon,
    required this.borderRadius,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final animationValue = controller.animation?.value ?? 0.0;
    final selectionProgress = (1.0 - (animationValue - index).abs()).clamp(0.0, 1.0);

    final selectedBg = AppColors.cyan;
    const unselectedBg = Colors.transparent;
    final selectedFg = isDark ? Colors.black : Colors.white;
    final unselectedFg = AppColors.textMuted;

    final bgColor = Color.lerp(unselectedBg, selectedBg, selectionProgress)!;
    final fgColor = Color.lerp(unselectedFg, selectedFg, selectionProgress)!;
    final isSelected = controller.index == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          controller.animateTo(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            vertical: showIcon && item.icon != null ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.cyan.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: showIcon && item.icon != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: fgColor,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: fgColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (item.icon != null) ...[
                      Icon(
                        item.icon,
                        size: 18,
                        color: fgColor,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: fgColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Represents a single tab item in the segmented tab bar.
class SegmentedTabItem {
  final String label;
  final IconData? icon;

  const SegmentedTabItem({
    required this.label,
    this.icon,
  });
}
