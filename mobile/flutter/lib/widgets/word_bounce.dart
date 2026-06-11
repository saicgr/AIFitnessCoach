import 'package:flutter/material.dart';

import '../core/constants/motion_tokens.dart';

/// Single playful bounce on VALUE CHANGES — streak ticking 12→13, XP landing,
/// a goal crossing 100%. Approved in the 2026-06 UI review (Change 4) with
/// two hard rules:
///
///  1. One element per event — never pair this with another animation on the
///     same trigger (e.g. the nav icon spin-pop).
///  2. Single bounce, no loop, and a no-op under the OS reduce-motion setting.
///
/// Usage: wrap the value text and pass the value as [trigger]; the bounce
/// plays only when [trigger] changes between builds (not on first build, so
/// cold starts stay calm).
class WordBounce extends StatefulWidget {
  final Widget child;

  /// The value being displayed. A change (by ==) triggers one bounce.
  final Object? trigger;

  const WordBounce({super.key, required this.child, required this.trigger});

  @override
  State<WordBounce> createState() => _WordBounceState();
}

class _WordBounceState extends State<WordBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _dy;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: kMotionExpressive);
    // Up-and-settle: -5px lift with a slight overshoot on the way back,
    // mirroring the mockup's wordbounce keyframes.
    _dy = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -5.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -5.0, end: 0.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_controller);
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 70,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant WordBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _dy.value),
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: widget.child,
    );
  }
}
