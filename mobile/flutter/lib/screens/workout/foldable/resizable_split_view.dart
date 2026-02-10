/// Resizable Split View
///
/// A generic widget that splits two children vertically with a draggable
/// divider. Used in foldable workout layouts to let users resize the
/// exercise pane vs. the info/chat pane.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';

/// A vertical split view with a draggable divider between [topChild] and
/// [bottomChild].
///
/// The user can drag the divider to resize the ratio between the two panes.
/// The ratio is clamped between [minTopRatio] and [maxTopRatio].
class ResizableSplitView extends StatefulWidget {
  /// Widget displayed in the top section.
  final Widget topChild;

  /// Widget displayed in the bottom section.
  final Widget bottomChild;

  /// Initial ratio of top section height to total height (0.0 - 1.0).
  final double initialTopRatio;

  /// Minimum allowed ratio for the top section.
  final double minTopRatio;

  /// Maximum allowed ratio for the top section.
  final double maxTopRatio;

  const ResizableSplitView({
    super.key,
    required this.topChild,
    required this.bottomChild,
    this.initialTopRatio = 0.6,
    this.minTopRatio = 0.3,
    this.maxTopRatio = 0.8,
  })  : assert(initialTopRatio >= 0.0 && initialTopRatio <= 1.0),
        assert(minTopRatio >= 0.0 && minTopRatio <= 1.0),
        assert(maxTopRatio >= 0.0 && maxTopRatio <= 1.0),
        assert(minTopRatio <= maxTopRatio);

  @override
  State<ResizableSplitView> createState() => _ResizableSplitViewState();
}

class _ResizableSplitViewState extends State<ResizableSplitView> {
  late double _topRatio;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _topRatio = widget.initialTopRatio.clamp(
      widget.minTopRatio,
      widget.maxTopRatio,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        const dividerHeight = 4.0;
        // Touch target extends beyond the visual divider
        const dividerTouchHeight = 24.0;
        final availableHeight = totalHeight - dividerTouchHeight;
        final topHeight = availableHeight * _topRatio;
        final bottomHeight = availableHeight * (1.0 - _topRatio);

        return Column(
          children: [
            // Top child
            SizedBox(
              height: topHeight,
              child: widget.topChild,
            ),

            // Draggable divider
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) {
                HapticFeedback.selectionClick();
                setState(() => _isDragging = true);
              },
              onVerticalDragUpdate: (details) {
                setState(() {
                  final delta = details.delta.dy / availableHeight;
                  _topRatio = (_topRatio + delta).clamp(
                    widget.minTopRatio,
                    widget.maxTopRatio,
                  );
                });
              },
              onVerticalDragEnd: (_) {
                setState(() => _isDragging = false);
              },
              child: SizedBox(
                height: dividerTouchHeight,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: dividerHeight,
                    decoration: BoxDecoration(
                      color: _isDragging
                          ? (isDark ? AppColors.accent : AppColors.orange)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: _isDragging ? 48 : 32,
                        height: dividerHeight,
                        decoration: BoxDecoration(
                          color: _isDragging
                              ? (isDark ? AppColors.accent : AppColors.orange)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom child
            SizedBox(
              height: bottomHeight,
              child: widget.bottomChild,
            ),
          ],
        );
      },
    );
  }
}
