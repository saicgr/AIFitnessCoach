import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// A glassmorphic floating pill toggle for switching between
/// workout summary views (Detail / General / Advanced).
class SummaryFloatingPill extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<String> labels;

  const SummaryFloatingPill({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    this.labels = const ['Detail', 'Summary', 'Advanced'],
  });

  static const double _pillHeight = 48;
  static const double _borderRadius = 25;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillBg = isDark
        ? AppColors.elevated.withValues(alpha: 0.75)
        : Colors.white.withValues(alpha: 0.85);
    final borderColor = isDark
        ? AppColors.cardBorder.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.08);
    final unselectedText = isDark
        ? AppColors.textMuted
        : Colors.grey.shade600;

    // Dynamic width based on label count
    final pillWidth = labels.length * 95.0 + 16;
    final segmentWidth = (pillWidth - 8) / labels.length;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  width: pillWidth,
                  height: _pillHeight,
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(_borderRadius),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Stack(
                    children: [
                      // Animated sliding indicator
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        left: segmentWidth * selectedIndex,
                        top: 0,
                        bottom: 0,
                        width: segmentWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius:
                                BorderRadius.circular(_borderRadius - 4),
                          ),
                        ),
                      ),
                      // Label buttons
                      Row(
                        children: List.generate(labels.length, (i) {
                          final isSelected = selectedIndex == i;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => onChanged(i),
                              behavior: HitTestBehavior.opaque,
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : unselectedText,
                                  ),
                                  child: Text(labels[i]),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
