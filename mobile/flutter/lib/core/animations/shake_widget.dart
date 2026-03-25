import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../services/haptic_service.dart';

/// A widget that can be imperatively shaken to indicate an error.
///
/// Wraps any child and provides a [shake] method via [ShakeWidgetState]
/// that triggers a rapid horizontal wobble (4 oscillations over 400ms
/// with decaying amplitude), combined with haptic error feedback.
///
/// Usage:
/// ```dart
/// final _shakeKey = GlobalKey<ShakeWidgetState>();
///
/// ShakeWidget(
///   key: _shakeKey,
///   child: TextField(...),
/// )
///
/// // On error:
/// _shakeKey.currentState?.shake();
/// ```
class ShakeWidget extends StatefulWidget {
  final Widget child;

  /// Maximum horizontal displacement in pixels.
  final double amplitude;

  /// Number of oscillation cycles.
  final int oscillations;

  /// Total duration of the shake animation.
  final Duration duration;

  /// Whether to trigger haptic feedback on shake.
  final bool hapticFeedback;

  const ShakeWidget({
    super.key,
    required this.child,
    this.amplitude = 8.0,
    this.oscillations = 4,
    this.duration = const Duration(milliseconds: 400),
    this.hapticFeedback = true,
  });

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Triggers the shake animation. Can be called multiple times.
  Future<void> shake() async {
    if (widget.hapticFeedback) {
      HapticService.instance.error();
    }
    _controller.reset();
    await _controller.forward();
  }

  double _getOffset(double t) {
    // Decaying sinusoid: sin(oscillations * 2π * t) * amplitude * (1 - t)
    final decay = 1.0 - t;
    return math.sin(t * widget.oscillations * 2 * math.pi) *
        widget.amplitude *
        decay;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_getOffset(_controller.value), 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
