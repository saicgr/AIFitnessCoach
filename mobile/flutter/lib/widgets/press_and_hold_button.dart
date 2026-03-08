import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A button that requires a press-and-hold gesture to confirm an action.
/// Shows a progress fill expanding left-to-right as the user holds.
class PressAndHoldButton extends StatefulWidget {
  final VoidCallback onConfirmed;
  final Duration holdDuration;
  final String label;
  final Color? color;

  const PressAndHoldButton({
    super.key,
    required this.onConfirmed,
    this.holdDuration = const Duration(milliseconds: 2500),
    this.label = 'Hold to Accept',
    this.color,
  });

  @override
  State<PressAndHoldButton> createState() => _PressAndHoldButtonState();
}

class _PressAndHoldButtonState extends State<PressAndHoldButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isHolding = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_completed) {
        _completed = true;
        HapticFeedback.heavyImpact();
        widget.onConfirmed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (_completed) return;
    HapticFeedback.mediumImpact();
    setState(() => _isHolding = true);
    _controller.forward();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_completed) return;
    if (_controller.status != AnimationStatus.completed) {
      _controller.reset();
    }
    setState(() => _isHolding = false);
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? const Color(0xFFF97316);
    final fillColor = HSLColor.fromColor(buttonColor)
        .withLightness(
            (HSLColor.fromColor(buttonColor).lightness + 0.15).clamp(0.0, 1.0))
        .toColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onLongPressStart: _onLongPressStart,
          onLongPressEnd: _onLongPressEnd,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _isHolding ? 0.98 : 1.0,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: buttonColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      // Progress fill
                      FractionallySizedBox(
                        widthFactor: _controller.value,
                        child: Container(color: fillColor),
                      ),
                      // Label
                      Center(
                        child: _completed
                            ? const Icon(Icons.check, color: Colors.white, size: 24)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.touch_app_outlined,
                                      size: 20, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.label,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        AnimatedOpacity(
          opacity: _completed ? 0.0 : 0.6,
          duration: const Duration(milliseconds: 200),
          child: Text(
            'Press and hold to acknowledge',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black45,
            ),
          ),
        ),
      ],
    );
  }
}
