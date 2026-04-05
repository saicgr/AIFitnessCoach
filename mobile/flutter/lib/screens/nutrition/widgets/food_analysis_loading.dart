import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// A dynamic loading indicator that feels alive even when waiting
class FoodAnalysisLoadingIndicator extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final String progressMessage;
  final String? progressDetail;
  final bool isDark;

  const FoodAnalysisLoadingIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.progressMessage,
    this.progressDetail,
    required this.isDark,
  });

  @override
  State<FoodAnalysisLoadingIndicator> createState() => _FoodAnalysisLoadingIndicatorState();
}

class _FoodAnalysisLoadingIndicatorState extends State<FoodAnalysisLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _stepBounceController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _stepBounceAnimation;
  int _tipIndex = 0;
  int _dotCount = 0;
  int _lastStep = 0;

  static const _tips = [
    'Did you know? Protein keeps you full longer',
    'Fun fact: Your body burns calories digesting food',
    'Tip: Eating slowly helps you feel satisfied',
    'Tracking meals builds awareness',
    'Small choices add up to big results',
    'Fiber is your gut\'s best friend',
    'Hydration boosts metabolism',
    'Consistency beats perfection',
    'Protein helps build and repair muscle',
    'Healthy fats are essential for brain function',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _stepBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _stepBounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _stepBounceController, curve: Curves.easeOut));

    _lastStep = widget.currentStep;

    _startTipCycler();
    _startDotAnimator();
  }

  void _startTipCycler() {
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _tipIndex = (_tipIndex + 1) % _tips.length;
        });
        _startTipCycler();
      }
    });
  }

  void _startDotAnimator() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4;
        });
        _startDotAnimator();
      }
    });
  }

  @override
  void didUpdateWidget(covariant FoodAnalysisLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentStep != _lastStep) {
      _lastStep = widget.currentStep;
      _stepBounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _stepBounceController.dispose();
    super.dispose();
  }

  String get _dots => '.' * _dotCount + ' ' * (3 - _dotCount);

  @override
  Widget build(BuildContext context) {
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = widget.isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final progress = widget.totalSteps > 0 ? widget.currentStep / widget.totalSteps : 0.0;

    final displayMessage = widget.progressMessage.isNotEmpty
        ? widget.progressMessage
        : _tips[_tipIndex];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated progress ring
            AnimatedBuilder(
              animation: Listenable.merge([_pulseAnimation, _rotateController]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.rotate(
                          angle: _rotateController.value * 2 * 3.14159,
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: null,
                              strokeWidth: 3,
                              color: teal.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return CircularProgressIndicator(
                                value: value > 0 ? value : null,
                                strokeWidth: 6,
                                color: teal,
                                backgroundColor: teal.withValues(alpha: 0.15),
                                strokeCap: StrokeCap.round,
                              );
                            },
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _stepBounceAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _stepBounceAnimation.value,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${widget.currentStep}/${widget.totalSteps}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: teal,
                                    ),
                                  ),
                                  Text(
                                    'steps',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                '$displayMessage$_dots',
                key: ValueKey('$displayMessage$_dotCount'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            if (widget.progressDetail != null) ...[
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  widget.progressDetail!,
                  key: ValueKey(widget.progressDetail),
                  style: TextStyle(fontSize: 13, color: textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Animated progress bar with shimmer effect
            SizedBox(
              width: 200,
              child: Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return FractionallySizedBox(
                        widthFactor: value > 0 ? value : 0.0,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                teal,
                                teal.withValues(alpha: 0.7),
                                teal,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _rotateController,
                    builder: (context, child) {
                      return Positioned(
                        left: _rotateController.value * 180,
                        child: Container(
                          width: 20,
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'This usually takes a few seconds',
              style: TextStyle(
                fontSize: 12,
                color: textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
