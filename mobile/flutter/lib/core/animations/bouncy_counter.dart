import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../services/haptic_service.dart';

/// A slot-machine style animated number counter.
///
/// Each digit rolls up/down independently with spring physics and a
/// stagger delay, creating a satisfying "slot machine" effect when
/// the displayed number changes.
///
/// Usage:
/// ```dart
/// BouncyCounter(
///   value: 1234,
///   textStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
/// )
/// ```
class BouncyCounter extends StatelessWidget {
  /// The number to display.
  final int value;

  /// Text style for the digits.
  final TextStyle? textStyle;

  /// Optional prefix (e.g., "+" or "$").
  final String prefix;

  /// Optional suffix (e.g., " XP" or " kcal").
  final String suffix;

  /// Stagger delay between each digit animation (left to right).
  final Duration staggerDelay;

  /// Whether to trigger haptic feedback when digits settle.
  final bool hapticFeedback;

  /// Spring stiffness — higher = snappier.
  final double springStiffness;

  /// Spring damping ratio — lower = more bouncy.
  final double springDamping;

  const BouncyCounter({
    super.key,
    required this.value,
    this.textStyle,
    this.prefix = '',
    this.suffix = '',
    this.staggerDelay = const Duration(milliseconds: 30),
    this.hapticFeedback = true,
    this.springStiffness = 300.0,
    this.springDamping = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    final digits = value.toString().split('');
    final style = textStyle ?? Theme.of(context).textTheme.headlineMedium;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefix.isNotEmpty)
          Text(prefix, style: style),
        ...digits.asMap().entries.map((entry) {
          return _BouncyDigit(
            key: ValueKey('digit_${entry.key}_${digits.length}'),
            digit: int.parse(entry.value),
            index: entry.key,
            textStyle: style,
            staggerDelay: staggerDelay,
            hapticFeedback: hapticFeedback && entry.key == digits.length - 1,
            springStiffness: springStiffness,
            springDamping: springDamping,
          );
        }),
        if (suffix.isNotEmpty)
          Text(suffix, style: style),
      ],
    );
  }
}

class _BouncyDigit extends StatefulWidget {
  final int digit;
  final int index;
  final TextStyle? textStyle;
  final Duration staggerDelay;
  final bool hapticFeedback;
  final double springStiffness;
  final double springDamping;

  const _BouncyDigit({
    super.key,
    required this.digit,
    required this.index,
    this.textStyle,
    required this.staggerDelay,
    required this.hapticFeedback,
    required this.springStiffness,
    required this.springDamping,
  });

  @override
  State<_BouncyDigit> createState() => _BouncyDigitState();
}

class _BouncyDigitState extends State<_BouncyDigit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;
  int _currentDigit = 0;
  int _previousDigit = 0;
  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    _currentDigit = widget.digit;
    _previousDigit = widget.digit;
    _controller = AnimationController(vsync: this);
    _offsetAnimation = const AlwaysStoppedAnimation(0.0);
  }

  @override
  void didUpdateWidget(covariant _BouncyDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.digit != widget.digit) {
      _previousDigit = _currentDigit;
      _currentDigit = widget.digit;
      _animateDigitChange();
    }
  }

  void _animateDigitChange() {
    final spring = SpringDescription(
      mass: 1.0,
      stiffness: widget.springStiffness,
      damping: widget.springDamping,
    );

    final simulation = SpringSimulation(spring, 0, 1, 0);

    _controller.reset();

    // Determine scroll direction: new digit > old → scroll up, else scroll down
    final direction = _currentDigit > _previousDigit ? -1.0 : 1.0;

    _offsetAnimation = _controller.drive(
      Tween<double>(begin: direction, end: 0.0)
          .chain(CurveTween(curve: _SpringCurve(simulation))),
    );

    // Apply stagger delay
    Future.delayed(widget.staggerDelay * widget.index, () {
      if (!mounted) return;
      _controller.animateWith(simulation).then((_) {
        if (widget.hapticFeedback && mounted) {
          HapticService.instance.tick();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstBuild) {
      _isFirstBuild = false;
      return _buildDigitText(_currentDigit);
    }

    return AnimatedBuilder(
      animation: _offsetAnimation,
      builder: (context, child) {
        final digitHeight = _getDigitHeight();
        return SizedBox(
          width: _getDigitWidth(),
          height: digitHeight,
          child: ClipRect(
            child: Stack(
              children: [
                // Current digit (target)
                Transform.translate(
                  offset: Offset(0, _offsetAnimation.value * digitHeight),
                  child: _buildDigitText(_currentDigit),
                ),
                // Previous digit (exiting)
                if (_offsetAnimation.value != 0)
                  Transform.translate(
                    offset: Offset(
                      0,
                      (_offsetAnimation.value - (_offsetAnimation.value > 0 ? 1 : -1)) * digitHeight,
                    ),
                    child: _buildDigitText(_previousDigit),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDigitText(int digit) {
    return Text(
      digit.toString(),
      style: widget.textStyle,
      textAlign: TextAlign.center,
    );
  }

  double _getDigitHeight() {
    final style = widget.textStyle ?? const TextStyle(fontSize: 24);
    final fontSize = style.fontSize ?? 24;
    final height = style.height ?? 1.2;
    return fontSize * height;
  }

  double _getDigitWidth() {
    // Measure the widest digit (8 is typically widest)
    final painter = TextPainter(
      text: TextSpan(text: '8', style: widget.textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }
}

/// Converts a SpringSimulation into a Curve for use with Tween.chain().
class _SpringCurve extends Curve {
  final SpringSimulation simulation;

  const _SpringCurve(this.simulation);

  @override
  double transformInternal(double t) {
    // SpringSimulation runs from 0 to "done", but we normalize to 0..1.
    // We evaluate the simulation at a scaled time and clamp.
    final simTime = t * 1.5; // scale factor to ensure simulation completes
    return simulation.x(simTime).clamp(0.0, 1.0);
  }
}
