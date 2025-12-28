import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Asset paths for Lottie animations
class LottieAssets {
  LottieAssets._();

  static const String successCheckmark = 'assets/lottie/success_checkmark.json';
  static const String loadingFitness = 'assets/lottie/loading_fitness.json';
  static const String loadingDots = 'assets/lottie/loading_dots.json';
  static const String emptyState = 'assets/lottie/empty_state.json';
  static const String celebration = 'assets/lottie/celebration.json';
  static const String achievement = 'assets/lottie/achievement.json';
}

/// Animated success checkmark - plays once by default
class LottieSuccess extends StatelessWidget {
  final double size;
  final bool repeat;
  final Color? color;
  final VoidCallback? onComplete;

  const LottieSuccess({
    super.key,
    this.size = 80,
    this.repeat = false,
    this.color,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      LottieAssets.successCheckmark,
      width: size,
      height: size,
      repeat: repeat,
      onLoaded: (composition) {
        if (onComplete != null && !repeat) {
          Future.delayed(composition.duration, onComplete);
        }
      },
      delegates: color != null
          ? LottieDelegates(
              values: [
                ValueDelegate.colorFilter(
                  const ['**'],
                  value: ColorFilter.mode(color!, BlendMode.srcATop),
                ),
              ],
            )
          : null,
    );
  }
}

/// Animated fitness loading indicator - loops continuously
class LottieLoading extends StatelessWidget {
  final double size;
  final Color? color;
  final bool useDots;

  const LottieLoading({
    super.key,
    this.size = 60,
    this.color,
    this.useDots = false,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      useDots ? LottieAssets.loadingDots : LottieAssets.loadingFitness,
      width: size,
      height: size,
      repeat: true,
      delegates: color != null
          ? LottieDelegates(
              values: [
                ValueDelegate.colorFilter(
                  const ['**'],
                  value: ColorFilter.mode(color!, BlendMode.srcATop),
                ),
              ],
            )
          : null,
    );
  }
}

/// Animated empty state illustration - loops gently
class LottieEmpty extends StatelessWidget {
  final double size;
  final Color? color;

  const LottieEmpty({
    super.key,
    this.size = 150,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      LottieAssets.emptyState,
      width: size,
      height: size,
      repeat: true,
      delegates: color != null
          ? LottieDelegates(
              values: [
                ValueDelegate.colorFilter(
                  const ['**'],
                  value: ColorFilter.mode(color!, BlendMode.srcATop),
                ),
              ],
            )
          : null,
    );
  }
}

/// Celebration animation for workout completion - plays once
class LottieCelebration extends StatelessWidget {
  final double size;
  final VoidCallback? onComplete;

  const LottieCelebration({
    super.key,
    this.size = 200,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      LottieAssets.celebration,
      width: size,
      height: size,
      repeat: false,
      onLoaded: (composition) {
        if (onComplete != null) {
          Future.delayed(composition.duration, onComplete);
        }
      },
    );
  }
}

/// Achievement/badge unlock animation - plays once
class LottieAchievement extends StatelessWidget {
  final double size;
  final Color? color;
  final VoidCallback? onComplete;

  const LottieAchievement({
    super.key,
    this.size = 100,
    this.color,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      LottieAssets.achievement,
      width: size,
      height: size,
      repeat: false,
      onLoaded: (composition) {
        if (onComplete != null) {
          Future.delayed(composition.duration, onComplete);
        }
      },
      delegates: color != null
          ? LottieDelegates(
              values: [
                ValueDelegate.colorFilter(
                  const ['**'],
                  value: ColorFilter.mode(color!, BlendMode.srcATop),
                ),
              ],
            )
          : null,
    );
  }
}

/// Generic Lottie wrapper with common options
class LottieAnimation extends StatelessWidget {
  final String asset;
  final double? width;
  final double? height;
  final bool repeat;
  final bool reverse;
  final Color? color;
  final BoxFit fit;
  final VoidCallback? onComplete;

  const LottieAnimation({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.repeat = false,
    this.reverse = false,
    this.color,
    this.fit = BoxFit.contain,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      asset,
      width: width,
      height: height,
      repeat: repeat,
      reverse: reverse,
      fit: fit,
      onLoaded: (composition) {
        if (onComplete != null && !repeat) {
          Future.delayed(composition.duration, onComplete);
        }
      },
      delegates: color != null
          ? LottieDelegates(
              values: [
                ValueDelegate.colorFilter(
                  const ['**'],
                  value: ColorFilter.mode(color!, BlendMode.srcATop),
                ),
              ],
            )
          : null,
    );
  }
}

/// Controller-based Lottie widget for more control
class LottieControlled extends StatefulWidget {
  final String asset;
  final double? width;
  final double? height;
  final bool autoPlay;
  final bool repeat;
  final Color? color;
  final void Function(AnimationController)? onControllerReady;

  const LottieControlled({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.autoPlay = true,
    this.repeat = false,
    this.color,
    this.onControllerReady,
  });

  @override
  State<LottieControlled> createState() => _LottieControlledState();
}

class _LottieControlledState extends State<LottieControlled>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    if (widget.onControllerReady != null) {
      widget.onControllerReady!(_controller);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      widget.asset,
      controller: _controller,
      width: widget.width,
      height: widget.height,
      onLoaded: (composition) {
        _controller.duration = composition.duration;
        if (widget.autoPlay) {
          if (widget.repeat) {
            _controller.repeat();
          } else {
            _controller.forward();
          }
        }
      },
      delegates: widget.color != null
          ? LottieDelegates(
              values: [
                ValueDelegate.colorFilter(
                  const ['**'],
                  value: ColorFilter.mode(widget.color!, BlendMode.srcATop),
                ),
              ],
            )
          : null,
    );
  }
}
