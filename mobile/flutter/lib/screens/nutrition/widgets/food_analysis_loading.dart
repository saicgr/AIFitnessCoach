import 'dart:async';
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

  Timer? _phaseTimer;
  Timer? _tipTimer;
  Timer? _elapsedTimer;

  int _tipIndex = 0;
  int _phaseIndex = 0;
  int _emojiIndex = 0;
  int _lastStep = 0;
  int _elapsedSeconds = 0;

  // Pre-step phase messages shown in rotation while waiting for the first
  // server progress event. Keeps the screen feeling alive during cold-start
  // latency instead of freezing on "Starting analysis...".
  static const _preStepPhases = [
    ('Starting analysis', '🔍'),
    ('Waking up the AI chef', '👨‍🍳'),
    ('Examining your meal', '🍽️'),
    ('Identifying ingredients', '🥗'),
    ('Estimating portions', '⚖️'),
    ('Looking up nutrition data', '📊'),
    ('Crunching the numbers', '🧮'),
    ('Almost there', '✨'),
  ];

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

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.05).animate(
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

    _phaseTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (!mounted) return;
      setState(() {
        _phaseIndex = (_phaseIndex + 1) % _preStepPhases.length;
        _emojiIndex = _phaseIndex;
      });
    });

    _tipTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!mounted) return;
      setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
    });

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
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
    _phaseTimer?.cancel();
    _tipTimer?.cancel();
    _elapsedTimer?.cancel();
    _pulseController.dispose();
    _rotateController.dispose();
    _stepBounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = widget.isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final isPreStep = widget.currentStep <= 0 || widget.totalSteps <= 0;
    final progress = isPreStep ? 0.0 : widget.currentStep / widget.totalSteps;

    // Prefer the backend's real message once steps arrive; otherwise rotate
    // through the pre-step phases so the user always sees movement.
    final phase = _preStepPhases[_phaseIndex];
    final displayMessage = isPreStep
        ? phase.$1
        : (widget.progressMessage.isNotEmpty ? widget.progressMessage : phase.$1);
    final displayEmoji = _preStepPhases[_emojiIndex].$2;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_pulseAnimation, _rotateController]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: SizedBox(
                    width: 110,
                    height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer rotating ghost ring — always moving so the
                        // user sees activity even before step progress arrives.
                        Transform.rotate(
                          angle: _rotateController.value * 2 * 3.14159,
                          child: SizedBox(
                            width: 110,
                            height: 110,
                            child: CircularProgressIndicator(
                              value: null,
                              strokeWidth: 3,
                              color: teal.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        // Inner ring: indeterminate during pre-step, becomes
                        // determinate once the backend reports real progress.
                        SizedBox(
                          width: 88,
                          height: 88,
                          child: isPreStep
                              ? CircularProgressIndicator(
                                  strokeWidth: 6,
                                  color: teal,
                                  backgroundColor: teal.withValues(alpha: 0.15),
                                  strokeCap: StrokeCap.round,
                                )
                              : TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: progress),
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return CircularProgressIndicator(
                                      value: value,
                                      strokeWidth: 6,
                                      color: teal,
                                      backgroundColor: teal.withValues(alpha: 0.15),
                                      strokeCap: StrokeCap.round,
                                    );
                                  },
                                ),
                        ),
                        // Center label: cycling emoji while waiting, step
                        // counter once real progress starts.
                        AnimatedBuilder(
                          animation: _stepBounceAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _stepBounceAnimation.value,
                              child: isPreStep
                                  ? AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 350),
                                      transitionBuilder: (w, anim) => ScaleTransition(
                                        scale: anim,
                                        child: FadeTransition(opacity: anim, child: w),
                                      ),
                                      child: Text(
                                        displayEmoji,
                                        key: ValueKey(displayEmoji),
                                        style: const TextStyle(fontSize: 36),
                                      ),
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${widget.currentStep}/${widget.totalSteps}',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: teal,
                                          ),
                                        ),
                                        Text(
                                          'steps',
                                          style: TextStyle(fontSize: 10, color: textMuted),
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

            const SizedBox(height: 28),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (w, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(anim),
                  child: w,
                ),
              ),
              child: Text(
                '$displayMessage…',
                key: ValueKey(displayMessage),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            if (widget.progressDetail != null && widget.progressDetail!.isNotEmpty) ...[
              const SizedBox(height: 6),
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

            const SizedBox(height: 20),

            // Shimmering progress bar — indeterminate sweep during pre-step,
            // fills up to real fraction once steps arrive.
            SizedBox(
              width: 220,
              child: Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  if (!isPreStep)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return FractionallySizedBox(
                          widthFactor: value,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [teal, teal.withValues(alpha: 0.7), teal],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      },
                    ),
                  // Sweeping highlight — during pre-step this IS the
                  // progress signal; during real progress it's a shimmer.
                  AnimatedBuilder(
                    animation: _rotateController,
                    builder: (context, child) {
                      final sweepPos = _rotateController.value * 220 - 40;
                      return Positioned(
                        left: sweepPos,
                        child: Container(
                          width: 40,
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                isPreStep
                                    ? teal.withValues(alpha: 0.7)
                                    : Colors.white.withValues(alpha: 0.4),
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

            // Rotating tip — always visible as a secondary reassurance line.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                _tips[_tipIndex],
                key: ValueKey(_tipIndex),
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Elapsed counter appears after 3s so short/cached runs don't
            // flash a timer, but long waits get reassurance that time is
            // passing and nothing is frozen.
            if (_elapsedSeconds >= 3) ...[
              const SizedBox(height: 10),
              Text(
                _elapsedSeconds >= 15
                    ? 'Still working… ${_elapsedSeconds}s'
                    : '${_elapsedSeconds}s elapsed',
                style: TextStyle(
                  fontSize: 11,
                  color: textMuted.withValues(alpha: 0.8),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
