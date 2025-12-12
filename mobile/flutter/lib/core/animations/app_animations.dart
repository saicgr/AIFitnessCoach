import 'package:flutter/material.dart';
import 'package:sprung/sprung.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Centralized animation constants for ultra-smooth 120fps animations.
/// Uses aggressive spring physics and short durations for instant, snappy feel.
class AppAnimations {
  AppAnimations._();

  // ==========================================================================
  // SPRING CURVES - Aggressive springs for instant response
  // ==========================================================================

  /// Ultra snappy spring - for micro-interactions (taps, toggles)
  /// Very high stiffness = instant response with minimal oscillation
  static final Curve ultraSnap = Sprung(50);

  /// Snappy spring - for quick feedback (button presses, list items)
  static final Curve snappy = Sprung(40);

  /// Smooth spring - for UI transitions (modals, sheets)
  static final Curve smooth = Sprung(32);

  /// Bouncy spring - for playful interactions (celebrations, drags)
  static final Curve bouncy = Sprung(24);

  // ==========================================================================
  // ULTRA-FAST DURATIONS (targeting 120fps feel)
  // ==========================================================================

  /// Micro animations - instant feedback (8ms = 1 frame at 120fps)
  static const Duration micro = Duration(milliseconds: 50);

  /// Fast animations - button feedback, micro-interactions
  static const Duration fast = Duration(milliseconds: 100);

  /// Quick animations - list items, card transitions
  static const Duration quick = Duration(milliseconds: 150);

  /// Normal animations - most UI transitions
  static const Duration normal = Duration(milliseconds: 200);

  /// Modal animations - sheets, dialogs
  static const Duration modal = Duration(milliseconds: 250);

  /// Stagger delay between list items (very short for rapid cascade)
  static const Duration stagger = Duration(milliseconds: 30);

  /// List item animation duration
  static const Duration listItem = Duration(milliseconds: 180);

  // ==========================================================================
  // CURVES FOR 120FPS SMOOTHNESS
  // ==========================================================================

  /// Ultra fast deceleration - almost instant
  static const Curve fastOut = Curves.easeOutExpo;

  /// Standard decelerate - quick start, smooth end
  static const Curve decelerate = Curves.easeOutQuart;

  /// Subtle overshoot - barely noticeable bounce
  static const Curve overshoot = Curves.easeOutBack;

  /// Linear to ease - for scrolling/following gestures
  static const Curve linearOut = Curves.linearToEaseOut;

  /// Quick accelerate for exits
  static const Curve accelerate = Curves.easeInQuart;

  // ==========================================================================
  // ANIMATION VALUES (subtle for speed)
  // ==========================================================================

  /// Slide offset for list items (reduced for speed)
  static const double listSlideOffset = 0.08;

  /// Scale for list items on entrance (closer to 1 = faster perception)
  static const double listScaleStart = 0.97;

  /// Modal slide offset (smaller = faster feel)
  static const double modalSlideOffset = 0.12;

  /// Button press scale (subtle)
  static const double buttonPressScale = 0.96;

  /// Bubble drag scale
  static const double bubbleDragScale = 1.08;

  // ==========================================================================
  // REUSABLE ANIMATION EFFECTS (optimized for speed)
  // ==========================================================================

  /// Ultra-fast list item entrance - snappy cascade effect
  static List<Effect<dynamic>> listItemEffects({int index = 0}) => [
        FadeEffect(
          duration: listItem,
          delay: stagger * index,
          curve: fastOut,
        ),
        SlideEffect(
          begin: const Offset(0, listSlideOffset),
          end: Offset.zero,
          duration: listItem,
          delay: stagger * index,
          curve: fastOut,
        ),
        ScaleEffect(
          begin: const Offset(listScaleStart, listScaleStart),
          end: const Offset(1, 1),
          duration: listItem,
          delay: stagger * index,
          curve: fastOut,
        ),
      ];

  /// Fast modal entrance with subtle overshoot
  static List<Effect<dynamic>> modalEntranceEffects() => [
        FadeEffect(
          duration: fast,
          curve: fastOut,
        ),
        SlideEffect(
          begin: const Offset(0, modalSlideOffset),
          end: Offset.zero,
          duration: modal,
          curve: overshoot,
        ),
      ];

  /// Instant backdrop fade
  static List<Effect<dynamic>> backdropEffects() => [
        FadeEffect(
          duration: micro,
          curve: linearOut,
        ),
      ];

  // ==========================================================================
  // TYPING INDICATOR (faster cycle for more energy)
  // ==========================================================================

  /// Typing dot bounce amplitude (pixels)
  static const double typingBounceHeight = 5.0;

  /// Typing dot animation duration - faster cycle
  static const Duration typingCycleDuration = Duration(milliseconds: 800);

  /// Delay between each typing dot animation start
  static const Duration typingDotDelay = Duration(milliseconds: 100);
}

/// Extension on Widget for quick animation application
extension AppAnimationExtensions on Widget {
  /// Apply ultra-fast list item entrance animation
  Widget animateListItem({int index = 0}) {
    return animate(effects: AppAnimations.listItemEffects(index: index));
  }

  /// Apply fast modal entrance animation
  Widget animateModalEntrance() {
    return animate(effects: AppAnimations.modalEntranceEffects());
  }

  /// Apply instant backdrop fade
  Widget animateBackdrop() {
    return animate(effects: AppAnimations.backdropEffects());
  }

  /// Quick fade in animation
  Widget animateFadeIn({Duration? delay}) {
    return animate(delay: delay)
        .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut);
  }

  /// Quick slide up animation
  Widget animateSlideUp({Duration? delay, double offset = 0.05}) {
    return animate(delay: delay)
        .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut)
        .slideY(
          begin: offset,
          end: 0,
          duration: AppAnimations.quick,
          curve: AppAnimations.decelerate,
        );
  }

  /// Hero-like scale and fade animation for featured cards
  Widget animateHeroEntrance({Duration? delay}) {
    return animate(delay: delay)
        .fadeIn(duration: AppAnimations.normal, curve: AppAnimations.fastOut)
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          duration: AppAnimations.modal,
          curve: AppAnimations.overshoot,
        )
        .slideY(
          begin: 0.08,
          end: 0,
          duration: AppAnimations.modal,
          curve: AppAnimations.decelerate,
        );
  }

  /// Shimmer loading effect
  Widget animateShimmer() {
    return animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: const Duration(milliseconds: 1500),
          color: const Color(0x33FFFFFF),
        );
  }

  /// Pulse animation for attention-grabbing elements
  Widget animatePulse() {
    return animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
  }

  /// Bounce entrance for playful elements
  Widget animateBounceIn({Duration? delay}) {
    return animate(delay: delay)
        .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut)
        .scale(
          begin: const Offset(0.3, 0.3),
          end: const Offset(1, 1),
          duration: AppAnimations.modal,
          curve: AppAnimations.bouncy,
        );
  }

  /// Slide from left with rotation (for dramatic entrances)
  Widget animateSlideRotate({Duration? delay, int index = 0}) {
    final staggerDelay = (delay ?? Duration.zero) + (AppAnimations.stagger * index);
    return animate(delay: staggerDelay)
        .fadeIn(duration: AppAnimations.quick, curve: AppAnimations.fastOut)
        .slideX(
          begin: -0.15,
          end: 0,
          duration: AppAnimations.normal,
          curve: AppAnimations.decelerate,
        )
        .rotate(
          begin: -0.02,
          end: 0,
          duration: AppAnimations.normal,
          curve: AppAnimations.decelerate,
        );
  }

  /// Flip in animation (3D-like effect)
  Widget animateFlipIn({Duration? delay}) {
    return animate(delay: delay)
        .fadeIn(duration: AppAnimations.fast)
        .flipV(
          begin: 0.5,
          end: 0,
          duration: AppAnimations.modal,
          curve: AppAnimations.overshoot,
        );
  }

  /// Elastic scale for interactive feedback
  Widget animateElasticScale({Duration? delay}) {
    return animate(delay: delay)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: AppAnimations.fast);
  }
}

/// Advanced animation widgets for complex effects
class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final BorderRadius borderRadius;
  final List<Color> colors;
  final Duration duration;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    this.borderWidth = 2,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.colors = const [Color(0xFF0891B2), Color(0xFF8B5CF6), Color(0xFF0891B2)],
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
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
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: SweepGradient(
              colors: widget.colors,
              transform: GradientRotation(_controller.value * 2 * 3.14159),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.borderWidth),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.all(
                  Radius.circular(widget.borderRadius.topLeft.x - widget.borderWidth),
                ),
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// Tilt effect widget - responds to pointer/touch position
class TiltEffect extends StatefulWidget {
  final Widget child;
  final double maxTilt;
  final Duration duration;

  const TiltEffect({
    super.key,
    required this.child,
    this.maxTilt = 0.05,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<TiltEffect> createState() => _TiltEffectState();
}

class _TiltEffectState extends State<TiltEffect> {
  double _rotateX = 0;
  double _rotateY = 0;

  void _onHover(PointerEvent event) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final localPosition = box.globalToLocal(event.position);

    setState(() {
      _rotateY = (localPosition.dx / size.width - 0.5) * widget.maxTilt;
      _rotateX = (0.5 - localPosition.dy / size.height) * widget.maxTilt;
    });
  }

  void _onExit(PointerEvent event) {
    setState(() {
      _rotateX = 0;
      _rotateY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onHover,
      onExit: _onExit,
      child: AnimatedContainer(
        duration: widget.duration,
        curve: AppAnimations.decelerate,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_rotateX)
          ..rotateY(_rotateY),
        transformAlignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}

/// Staggered fade-slide for lists
class StaggeredListAnimation extends StatelessWidget {
  final List<Widget> children;
  final Duration itemDuration;
  final Duration staggerDelay;
  final double slideOffset;
  final Axis slideDirection;

  const StaggeredListAnimation({
    super.key,
    required this.children,
    this.itemDuration = AppAnimations.listItem,
    this.staggerDelay = AppAnimations.stagger,
    this.slideOffset = 0.08,
    this.slideDirection = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children.asMap().entries.map((entry) {
        return entry.value
            .animate(delay: staggerDelay * entry.key)
            .fadeIn(duration: itemDuration, curve: AppAnimations.fastOut)
            .slide(
              begin: slideDirection == Axis.vertical
                  ? Offset(0, slideOffset)
                  : Offset(slideOffset, 0),
              end: Offset.zero,
              duration: itemDuration,
              curve: AppAnimations.decelerate,
            );
      }).toList(),
    );
  }
}
