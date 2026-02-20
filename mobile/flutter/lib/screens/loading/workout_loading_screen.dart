import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/today_workout.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../widgets/gradient_circular_progress_indicator.dart';

/// Full-screen loading screen shown after onboarding while workouts are being generated.
/// Clean circular progress design inspired by Hevy.
class WorkoutLoadingScreen extends ConsumerStatefulWidget {
  const WorkoutLoadingScreen({super.key});

  @override
  ConsumerState<WorkoutLoadingScreen> createState() => _WorkoutLoadingScreenState();
}

class _WorkoutLoadingScreenState extends ConsumerState<WorkoutLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  Timer? _pollTimer;
  Timer? _maxWaitTimer;
  int _pollCount = 0;
  int _consecutiveErrors = 0;
  int _currentStep = 0;
  double _progress = 0.0;
  bool _workoutReady = false;
  bool _hasNavigated = false;
  static const int _maxConsecutiveErrors = 5; // Navigate after 5 errors
  static const int _maxWaitSeconds = 20; // Navigate to home after 20s max

  final List<_Step> _steps = const [
    _Step('Analyzing your fitness profile', Icons.person_search),
    _Step('Setting up your AI coach', Icons.smart_toy_rounded),
    _Step('Selecting exercises', Icons.fitness_center),
    _Step('Building your plan', Icons.auto_awesome),
    _Step('Finalizing workout', Icons.rocket_launch),
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startPolling();
    _animateSteps();

    // Hard time limit: navigate to home after _maxWaitSeconds.
    // The home screen's GeneratingHeroCard handles ongoing generation gracefully.
    // This prevents the user being stuck on a bare loading screen during
    // backend cold starts or slow generation.
    _maxWaitTimer = Timer(const Duration(seconds: _maxWaitSeconds), () {
      if (!_hasNavigated && !_workoutReady) {
        debugPrint('⏱️ [WorkoutLoading] Max wait $_maxWaitSeconds s reached, navigating to home');
        _navigateToHome();
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pollTimer?.cancel();
    _maxWaitTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Trigger an immediate refresh
    ref.read(todayWorkoutProvider.notifier).refresh();
    // Poll every 3s to keep triggering fresh fetches.
    // State changes are handled reactively via ref.listen in build().
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_workoutReady) {
        _pollCount++;
        debugPrint('🔄 [WorkoutLoading] Poll refresh #$_pollCount');
        ref.read(todayWorkoutProvider.notifier).refresh();
      }
    });
  }

  /// Called reactively by ref.listen whenever provider state changes.
  /// Reacts instantly — no waiting for next poll interval.
  void _onProviderStateChanged(AsyncValue<TodayWorkoutResponse?> state) {
    if (_hasNavigated || _workoutReady) return;

    state.when(
      loading: () {},
      error: (e, _) {
        debugPrint('❌ [WorkoutLoading] Error: $e');
        _consecutiveErrors++;
        if (_consecutiveErrors >= _maxConsecutiveErrors) {
          debugPrint('⚠️ [WorkoutLoading] $_consecutiveErrors consecutive errors, navigating');
          _navigateToHome();
        }
      },
      data: (response) {
        _consecutiveErrors = 0;
        if (response != null && response.hasDisplayableContent) {
          debugPrint('✅ [WorkoutLoading] Content ready — transitioning immediately');
          _maxWaitTimer?.cancel();
          setState(() {
            _workoutReady = true;
            _progress = 1.0;
            _currentStep = _steps.length;
          });
          Future.delayed(const Duration(milliseconds: 800), _navigateToHome);
        }
      },
    );
  }

  Future<void> _animateSteps() async {
    for (int i = 0; i < _steps.length && mounted && !_workoutReady; i++) {
      await Future.delayed(Duration(milliseconds: 1200 + (i * 300)));
      if (mounted && !_workoutReady) {
        setState(() {
          _currentStep = i + 1;
          _progress = (i + 1) / _steps.length * 0.85; // Cap at 85% until ready
        });
      }
    }
  }

  void _navigateToHome() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _pollTimer?.cancel();
    if (mounted) {
      debugPrint('🏠 [WorkoutLoading] Navigating to home');
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    // React INSTANTLY to provider state changes (constructor fetch, streaming gen,
    // background poll — any source). This is the primary transition mechanism.
    // Polling just drives fresh fetches; ref.listen handles the reaction.
    ref.listen<AsyncValue<TodayWorkoutResponse?>>(
      todayWorkoutProvider,
      (_, next) => _onProviderStateChanged(next),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accentColor = isDark ? AppColors.orange : AppColorsLight.orange;
    final accentColorLight = isDark ? AppColors.orangeLight : AppColorsLight.orangeLight;
    final trackColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final stepLabel = _currentStep < _steps.length
        ? _steps[_currentStep].label
        : 'Workout ready!';
    final percentage = (_progress * 100).toInt();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Circular progress ring with glow
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    final pulse = _glowController.value < 0.5
                        ? _glowController.value * 2
                        : 2 - _glowController.value * 2;
                    final glowOpacity = _progress < 1.0 ? 0.08 + 0.12 * pulse : 0.0;

                    return Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: _progress < 1.0
                            ? [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: glowOpacity),
                                  blurRadius: 40,
                                  spreadRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: child,
                    );
                  },
                  child: SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background track
                        GradientCircularProgressIndicator(
                          size: 240,
                          strokeWidth: 12,
                          value: 1.0,
                          gradientColors: [trackColor, trackColor],
                          backgroundColor: Colors.transparent,
                        ),
                        // Progress arc
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: _progress),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return GradientCircularProgressIndicator(
                              size: 240,
                              strokeWidth: 12,
                              value: value > 0 ? value : null,
                              gradientColors: [accentColor, accentColorLight],
                              backgroundColor: Colors.transparent,
                              strokeCap: StrokeCap.round,
                            );
                          },
                        ),
                        // Center content
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_progress >= 1.0)
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 32,
                              )
                            else
                              Icon(
                                _currentStep < _steps.length
                                    ? _steps[_currentStep].icon
                                    : Icons.auto_awesome,
                                color: accentColor.withValues(alpha: 0.5),
                                size: 28,
                              ),
                            const SizedBox(height: 8),
                            Text(
                              '$percentage%',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  _progress >= 1.0 ? 'Workout Ready!' : 'Building Your Plan',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                // Step label
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    stepLabel,
                    key: ValueKey(stepLabel),
                    style: TextStyle(
                      fontSize: 15,
                      color: textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const Spacer(flex: 4),

                // Skip button after 10s (2 polls)
                AnimatedOpacity(
                  opacity: _pollCount > 2 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: TextButton(
                    onPressed: _pollCount > 2 ? _navigateToHome : null,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: textSecondary.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Step {
  final String label;
  final IconData icon;
  const _Step(this.label, this.icon);
}
