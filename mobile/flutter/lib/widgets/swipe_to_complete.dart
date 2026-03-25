import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../core/animations/app_animations.dart';
import '../core/services/haptic_service.dart';

/// A swipe-to-complete gesture widget for workout set completion.
///
/// The user swipes right across the row. A colored fill follows the finger.
/// Past a configurable threshold (default 70%), it snaps to complete with
/// a haptic burst. Below threshold, it springs back to zero.
///
/// Usage:
/// ```dart
/// SwipeToComplete(
///   onComplete: () => markSetDone(),
///   child: SetRowWidget(...),
/// )
/// ```
class SwipeToComplete extends StatefulWidget {
  /// The content to display inside the swipeable area.
  final Widget child;

  /// Called when the swipe passes the threshold and completes.
  final VoidCallback onComplete;

  /// Percentage of width that must be swiped to trigger completion (0.0 - 1.0).
  final double threshold;

  /// Color of the fill that follows the swipe.
  final Color fillColor;

  /// Color of the fill when past the threshold.
  final Color completeFillColor;

  /// Icon shown at the leading edge of the swipe.
  final IconData leadingIcon;

  /// Height of the swipeable area. If null, wraps the child.
  final double? height;

  /// Border radius of the swipeable area.
  final BorderRadius borderRadius;

  /// Whether the widget is enabled for swiping.
  final bool enabled;

  const SwipeToComplete({
    super.key,
    required this.child,
    required this.onComplete,
    this.threshold = 0.7,
    this.fillColor = const Color(0x3322C55E), // Green 20%
    this.completeFillColor = const Color(0x6622C55E), // Green 40%
    this.leadingIcon = Icons.check_rounded,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.enabled = true,
  });

  @override
  State<SwipeToComplete> createState() => _SwipeToCompleteState();
}

class _SwipeToCompleteState extends State<SwipeToComplete>
    with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  double _dragProgress = 0.0; // 0.0 to 1.0
  bool _isPastThreshold = false;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(vsync: this);
    _springController.addListener(() {
      setState(() {
        _dragProgress = _springController.value;
      });
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || _isCompleting) return;

    final width = context.size?.width ?? 1;
    final delta = details.delta.dx / width;

    setState(() {
      _dragProgress = (_dragProgress + delta).clamp(0.0, 1.0);

      // Haptic when crossing threshold
      final nowPast = _dragProgress >= widget.threshold;
      if (nowPast && !_isPastThreshold) {
        HapticService.instance.impact();
      } else if (!nowPast && _isPastThreshold) {
        HapticService.instance.tick();
      }
      _isPastThreshold = nowPast;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.enabled || _isCompleting) return;

    if (_isPastThreshold) {
      // Complete: animate to full width then call callback
      _isCompleting = true;
      HapticService.instance.heavyImpact();

      _springController.value = _dragProgress;
      _springController
          .animateTo(
        1.0,
        duration: AppAnimations.quick,
        curve: AppAnimations.decelerate,
      )
          .then((_) {
        widget.onComplete();
        // Reset after a brief pause
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _dragProgress = 0.0;
              _isPastThreshold = false;
              _isCompleting = false;
            });
          }
        });
      });
    } else {
      // Spring back to zero
      final spring = SpringDescription(mass: 1, stiffness: 400, damping: 25);
      final simulation = SpringSimulation(spring, _dragProgress, 0, 0);
      _springController.value = _dragProgress;
      _springController.animateWith(simulation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = _isPastThreshold ? widget.completeFillColor : widget.fillColor;

    // Icon opacity: fades in as drag progresses
    final iconOpacity = (_dragProgress * 3).clamp(0.0, 1.0);
    // Icon scale: bounces when past threshold
    final iconScale = _isPastThreshold ? 1.1 : 0.8 + _dragProgress * 0.2;

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              // Original child
              widget.child,

              // Swipe fill overlay
              if (_dragProgress > 0)
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _dragProgress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: fillColor,
                        borderRadius: widget.borderRadius,
                      ),
                    ),
                  ),
                ),

              // Leading checkmark icon
              if (_dragProgress > 0.05)
                Positioned(
                  left: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Opacity(
                      opacity: iconOpacity,
                      child: Transform.scale(
                        scale: iconScale,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _isPastThreshold
                                ? const Color(0xFF22C55E)
                                : const Color(0xFF22C55E).withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.leadingIcon,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Right-side hint arrow (when not dragging)
              if (_dragProgress == 0 && widget.enabled)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                      size: 20,
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
