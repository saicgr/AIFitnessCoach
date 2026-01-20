import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/today_workout_provider.dart';

/// Full-screen loading screen shown after onboarding while workouts are being generated.
/// Features engaging animations, progress stages, and motivational content.
class WorkoutLoadingScreen extends ConsumerStatefulWidget {
  const WorkoutLoadingScreen({super.key});

  @override
  ConsumerState<WorkoutLoadingScreen> createState() => _WorkoutLoadingScreenState();
}

class _WorkoutLoadingScreenState extends ConsumerState<WorkoutLoadingScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _progressController;
  late AnimationController _iconBounceController;
  late AnimationController _particleController;

  // Animations
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;

  Timer? _pollTimer;
  Timer? _stageTimer;
  int _pollCount = 0;
  int _currentStage = 0;
  static const int _maxPolls = 60;

  // Stage data with icons, messages, and tips
  final List<_LoadingStage> _stages = [
    _LoadingStage(
      icon: Icons.person_search_rounded,
      title: 'Analyzing Your Profile',
      subtitle: 'Understanding your fitness level and goals...',
      tip: 'Your workout will be tailored to your experience level',
      progress: 0.15,
    ),
    _LoadingStage(
      icon: Icons.fitness_center_rounded,
      title: 'Selecting Exercises',
      subtitle: 'Picking the best movements for your goals...',
      tip: 'We prioritize compound movements for efficiency',
      progress: 0.35,
    ),
    _LoadingStage(
      icon: Icons.tune_rounded,
      title: 'Optimizing Sets & Reps',
      subtitle: 'Calculating optimal volume for growth...',
      tip: 'Progressive overload is key to building strength',
      progress: 0.55,
    ),
    _LoadingStage(
      icon: Icons.timer_rounded,
      title: 'Setting Rest Periods',
      subtitle: 'Balancing intensity and recovery...',
      tip: 'Rest 2-3 min for strength, 60-90s for hypertrophy',
      progress: 0.75,
    ),
    _LoadingStage(
      icon: Icons.auto_graph_rounded,
      title: 'Adding Progression',
      subtitle: 'Building in progressive overload...',
      tip: 'Small consistent gains lead to big results',
      progress: 0.90,
    ),
    _LoadingStage(
      icon: Icons.check_circle_rounded,
      title: 'Almost Ready!',
      subtitle: 'Finalizing your personalized workout...',
      tip: 'Your transformation starts today',
      progress: 1.0,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Pulse animation for the main icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotation for the orbiting elements
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Progress bar animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Icon bounce when stage changes
    _iconBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconBounceController, curve: Curves.elasticOut),
    );

    // Particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Start polling and stage progression
    _startPolling();
    _startStageProgression();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _progressController.dispose();
    _iconBounceController.dispose();
    _particleController.dispose();
    _pollTimer?.cancel();
    _stageTimer?.cancel();
    super.dispose();
  }

  void _startStageProgression() {
    // Progress through stages every 4-5 seconds
    _stageTimer = Timer.periodic(const Duration(milliseconds: 4500), (_) {
      if (mounted && _currentStage < _stages.length - 1) {
        setState(() {
          _currentStage++;
        });
        _iconBounceController.forward(from: 0);
        _progressController.animateTo(
          _stages[_currentStage].progress,
          curve: Curves.easeOutCubic,
        );
      }
    });

    // Start initial progress animation
    _progressController.animateTo(
      _stages[0].progress,
      curve: Curves.easeOutCubic,
    );
  }

  void _startPolling() {
    _checkWorkoutStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkWorkoutStatus();
    });
  }

  Future<void> _checkWorkoutStatus() async {
    _pollCount++;
    debugPrint('🔄 [WorkoutLoading] Polling for workouts (attempt $_pollCount/$_maxPolls)');

    ref.invalidate(todayWorkoutProvider);
    await Future.delayed(const Duration(milliseconds: 500));

    final todayWorkoutState = ref.read(todayWorkoutProvider);

    todayWorkoutState.when(
      loading: () {},
      error: (e, _) {
        debugPrint('❌ [WorkoutLoading] Error: $e');
      },
      data: (response) {
        if (response != null && !response.isGenerating) {
          if (response.todayWorkout != null || response.nextWorkout != null) {
            debugPrint('✅ [WorkoutLoading] Workouts ready!');
            // Jump to final stage before navigating
            setState(() {
              _currentStage = _stages.length - 1;
            });
            _progressController.animateTo(1.0, curve: Curves.easeOutCubic);
            Future.delayed(const Duration(milliseconds: 800), _navigateToHome);
          }
        }
      },
    );

    if (_pollCount >= _maxPolls) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    _pollTimer?.cancel();
    _stageTimer?.cancel();
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark
        ? AppColors.elevated
        : AppColorsLight.elevated;
    // Use orange accent for visibility in both light and dark modes
    final accentColor = isDark ? AppColors.orange : AppColorsLight.orange;
    final stage = _stages[_currentStage];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Animated background particles
            ...List.generate(6, (index) => _buildFloatingParticle(index, isDark, accentColor)),

            // Main content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Animated loading indicator with orbiting elements
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 180 * _pulseAnimation.value,
                                height: 180 * _pulseAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withValues(alpha: 0.2),
                                      blurRadius: 60,
                                      spreadRadius: 20,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // Orbiting icons
                          AnimatedBuilder(
                            animation: _rotationController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotationController.value * 2 * math.pi,
                                child: SizedBox(
                                  width: 160,
                                  height: 160,
                                  child: Stack(
                                    children: [
                                      _buildOrbitingIcon(Icons.fitness_center, 0, isDark, accentColor),
                                      _buildOrbitingIcon(Icons.favorite, 120, isDark, accentColor),
                                      _buildOrbitingIcon(Icons.bolt, 240, isDark, accentColor),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Inner circle with stage icon
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accentColor,
                                  accentColor.withValues(alpha: 0.7),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: AnimatedBuilder(
                              animation: _bounceAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 0.8 + (_bounceAnimation.value * 0.2),
                                  child: Icon(
                                    stage.icon,
                                    color: Colors.white,
                                    size: 44,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Stage title with animation
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(animation),
                          child: FadeTransition(opacity: animation, child: child),
                        );
                      },
                      child: Text(
                        stage.title,
                        key: ValueKey('title_$_currentStage'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Stage subtitle
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        stage.subtitle,
                        key: ValueKey('subtitle_$_currentStage'),
                        style: TextStyle(
                          fontSize: 16,
                          color: textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Progress bar with stage indicators
                    _buildProgressBar(isDark, accentColor),

                    const SizedBox(height: 40),

                    // Tip card
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        key: ValueKey('tip_$_currentStage'),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.lightbulb_outline_rounded,
                                color: accentColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                stage.tip,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Skip button (appears after some time)
                    AnimatedOpacity(
                      opacity: _pollCount > 8 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: TextButton(
                        onPressed: _pollCount > 8 ? _navigateToHome : null,
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
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(bool isDark, Color accentColor) {
    return Column(
      children: [
        // Progress bar
        AnimatedBuilder(
          animation: _progressController,
          builder: (context, child) {
            return Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: accentColor.withValues(alpha: 0.15),
              ),
              child: Stack(
                children: [
                  // Progress fill
                  FractionallySizedBox(
                    widthFactor: _progressController.value,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.8),
                            accentColor,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Shimmer effect
                  AnimatedBuilder(
                    animation: _particleController,
                    builder: (context, child) {
                      return Positioned(
                        left: (_progressController.value * MediaQuery.of(context).size.width * 0.8) *
                            _particleController.value - 40,
                        child: Container(
                          width: 40,
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.4),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        // Stage dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_stages.length, (index) {
            final isActive = index <= _currentStage;
            final isCurrent = index == _currentStage;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isCurrent ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isActive
                    ? accentColor
                    : accentColor.withValues(alpha: 0.2),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildOrbitingIcon(IconData icon, double angleDegrees, bool isDark, Color accentColor) {
    final angleRadians = angleDegrees * math.pi / 180;
    const radius = 70.0;

    return Positioned(
      left: 80 + radius * math.cos(angleRadians) - 14,
      top: 80 + radius * math.sin(angleRadians) - 14,
      child: Transform.rotate(
        angle: -_rotationController.value * 2 * math.pi,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.elevated
                : AppColorsLight.elevated,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: accentColor,
            size: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingParticle(int index, bool isDark, Color accentColor) {
    final random = math.Random(index);
    final startX = random.nextDouble() * 400 - 50;
    final startY = random.nextDouble() * 800;
    final size = 4.0 + random.nextDouble() * 4;
    final delay = random.nextDouble();

    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = (_particleController.value + delay) % 1.0;
        final y = startY - (progress * 200);
        final opacity = math.sin(progress * math.pi) * 0.3;

        return Positioned(
          left: startX + math.sin(progress * math.pi * 2) * 20,
          top: y,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: opacity),
            ),
          ),
        );
      },
    );
  }
}

class _LoadingStage {
  final IconData icon;
  final String title;
  final String subtitle;
  final String tip;
  final double progress;

  const _LoadingStage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tip,
    required this.progress,
  });
}
