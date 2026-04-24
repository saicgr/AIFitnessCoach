import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'analysis_loading_copy.dart';

/// A dynamic loading indicator that feels alive even when waiting.
///
/// Per-mode copy: pass `analysisType` as 'plate' | 'menu' | 'buffet' (or
/// 'auto') so the headline phases + subtitle tips match what the user
/// actually uploaded. Without this, every upload feels identical.
class FoodAnalysisLoadingIndicator extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final String progressMessage;
  final String? progressDetail;
  final bool isDark;
  final String analysisType;

  const FoodAnalysisLoadingIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.progressMessage,
    this.progressDetail,
    required this.isDark,
    this.analysisType = 'plate',
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

  int _lastStep = 0;
  int _elapsedSeconds = 0;

  // Index queues for no-repeat-within-5 rotation. We pull from the head,
  // shuffle fresh indices to the back when exhausted, and never show the
  // same copy line twice in a 5-step window.
  late List<LoadingPhase> _phasesBank;
  late List<String> _tipsBank;
  final List<int> _phaseQueue = [];
  final List<int> _tipQueue = [];
  int _phaseIndex = 0;
  int _tipIndex = 0;
  int _stillWorkingIndex = 0;
  final Random _rand = Random();

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
    _phasesBank = AnalysisLoadingCopy.phasesFor(widget.analysisType);
    _tipsBank = AnalysisLoadingCopy.tipsFor(widget.analysisType);
    _phaseIndex = _nextPhaseIndex();
    _tipIndex = _nextTipIndex();

    _phaseTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (!mounted) return;
      setState(() => _phaseIndex = _nextPhaseIndex());
    });

    _tipTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!mounted) return;
      setState(() => _tipIndex = _nextTipIndex());
    });

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
        // Rotate "still working" copy every 4s past the 15s mark so the
        // long wait feels like narration, not a timer stuck on one line.
        if (_elapsedSeconds >= 15 && _elapsedSeconds % 4 == 0) {
          _stillWorkingIndex =
              (_stillWorkingIndex + 1) % AnalysisLoadingCopy.stillWorkingLines.length;
        }
      });
    });
  }

  /// Shuffle-bag rotation: refill a queue of all indices when empty,
  /// pop from the head, guarantees we see every line before repeating.
  int _nextPhaseIndex() {
    if (_phaseQueue.isEmpty) {
      final indices = List<int>.generate(_phasesBank.length, (i) => i)..shuffle(_rand);
      // Avoid immediate repeat of the currently-shown phase.
      if (indices.first == _phaseIndex && indices.length > 1) {
        final swap = indices[1];
        indices[1] = indices[0];
        indices[0] = swap;
      }
      _phaseQueue.addAll(indices);
    }
    return _phaseQueue.removeAt(0);
  }

  int _nextTipIndex() {
    if (_tipQueue.isEmpty) {
      final indices = List<int>.generate(_tipsBank.length, (i) => i)..shuffle(_rand);
      if (indices.first == _tipIndex && indices.length > 1) {
        final swap = indices[1];
        indices[1] = indices[0];
        indices[0] = swap;
      }
      _tipQueue.addAll(indices);
    }
    return _tipQueue.removeAt(0);
  }

  @override
  void didUpdateWidget(covariant FoodAnalysisLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentStep != _lastStep) {
      _lastStep = widget.currentStep;
      _stepBounceController.forward(from: 0);
    }
    // If the caller switched mode mid-flight (e.g. backend classified auto→menu)
    // rebuild the banks and reshuffle so copy matches the new mode.
    if (widget.analysisType != oldWidget.analysisType) {
      _phasesBank = AnalysisLoadingCopy.phasesFor(widget.analysisType);
      _tipsBank = AnalysisLoadingCopy.tipsFor(widget.analysisType);
      _phaseQueue.clear();
      _tipQueue.clear();
      _phaseIndex = _nextPhaseIndex();
      _tipIndex = _nextTipIndex();
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
    // through mode-specific phases so the user always sees movement
    // and menu/buffet/plate each feel distinct.
    final phase = _phasesBank[_phaseIndex % _phasesBank.length];
    final displayMessage = isPreStep
        ? phase.$1
        : (widget.progressMessage.isNotEmpty ? widget.progressMessage : phase.$1);
    final displayEmoji = phase.$2;

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
                _tipsBank[_tipIndex % _tipsBank.length],
                key: ValueKey('$_tipIndex-${_tipsBank.length}'),
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
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _elapsedSeconds >= 15
                      ? '${AnalysisLoadingCopy.stillWorkingLines[_stillWorkingIndex]}… ${_elapsedSeconds}s'
                      : '${_elapsedSeconds}s elapsed',
                  key: ValueKey('elapsed-$_elapsedSeconds-$_stillWorkingIndex'),
                  style: TextStyle(
                    fontSize: 11,
                    color: textMuted.withValues(alpha: 0.8),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
