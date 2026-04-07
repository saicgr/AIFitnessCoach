import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// A glassmorphic floating pill toggle for switching between
/// "General" and "Advanced" workout summary views.
class SummaryFloatingPill extends StatelessWidget {
  final int selectedIndex; // 0 = General, 1 = Advanced
  final ValueChanged<int> onChanged;

  const SummaryFloatingPill({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  static const double _pillWidth = 250;
  static const double _pillHeight = 48;
  static const double _borderRadius = 25;
  static const List<String> _labels = ['General', 'Advanced'];

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
                  width: _pillWidth,
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
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        alignment: selectedIndex == 0
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          width: (_pillWidth - 8) / 2,
                          height: _pillHeight - 8,
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius:
                                BorderRadius.circular(_borderRadius - 4),
                          ),
                        ),
                      ),
                      // Label buttons
                      Row(
                        children: List.generate(_labels.length, (i) {
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
                                  child: Text(_labels[i]),
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
