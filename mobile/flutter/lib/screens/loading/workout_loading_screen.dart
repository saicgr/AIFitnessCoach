import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/today_workout_provider.dart';

/// Full-screen loading screen shown after onboarding while workouts are being generated.
/// Polls the todayWorkoutProvider until workouts are ready, then navigates to home.
class WorkoutLoadingScreen extends ConsumerStatefulWidget {
  const WorkoutLoadingScreen({super.key});

  @override
  ConsumerState<WorkoutLoadingScreen> createState() => _WorkoutLoadingScreenState();
}

class _WorkoutLoadingScreenState extends ConsumerState<WorkoutLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  Timer? _pollTimer;
  int _pollCount = 0;
  static const int _maxPolls = 60; // Max 2 minutes (60 * 2 seconds)

  String _loadingMessage = 'Creating your personalized workout plan...';
  final List<String> _loadingMessages = [
    'Creating your personalized workout plan...',
    'Analyzing your fitness goals...',
    'Designing exercises for your level...',
    'Optimizing your weekly schedule...',
    'Adding progressive overload...',
    'Fine-tuning rest periods...',
    'Almost there...',
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Start polling for workout readiness
    _startPolling();

    // Cycle through loading messages
    _cycleMessages();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _cycleMessages() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          final currentIndex = _loadingMessages.indexOf(_loadingMessage);
          final nextIndex = (currentIndex + 1) % _loadingMessages.length;
          _loadingMessage = _loadingMessages[nextIndex];
        });
        _cycleMessages();
      }
    });
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

    // Force refresh the provider
    ref.invalidate(todayWorkoutProvider);

    // Wait a moment for the provider to update
    await Future.delayed(const Duration(milliseconds: 500));

    final todayWorkoutState = ref.read(todayWorkoutProvider);

    todayWorkoutState.when(
      loading: () {
        debugPrint('🔄 [WorkoutLoading] Still loading...');
      },
      error: (e, _) {
        debugPrint('❌ [WorkoutLoading] Error: $e');
        // Continue polling on error
      },
      data: (response) {
        debugPrint('📊 [WorkoutLoading] Response: isGenerating=${response?.isGenerating}, '
            'todayWorkout=${response?.todayWorkout != null}, '
            'nextWorkout=${response?.nextWorkout != null}');

        // Check if workouts are ready
        if (response != null && !response.isGenerating) {
          if (response.todayWorkout != null || response.nextWorkout != null) {
            debugPrint('✅ [WorkoutLoading] Workouts ready! Navigating to home...');
            _navigateToHome();
          }
        }
      },
    );

    // Timeout - go to home anyway after max polls
    if (_pollCount >= _maxPolls) {
      debugPrint('⚠️ [WorkoutLoading] Timeout reached, navigating to home anyway');
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    _pollTimer?.cancel();
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

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated loading indicator with glow effect
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyan.withValues(alpha: 0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    // Spinner
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        color: AppColors.cyan,
                        backgroundColor: AppColors.cyan.withValues(alpha: 0.2),
                      ),
                    ),
                    // Center icon
                    Icon(
                      Icons.fitness_center_rounded,
                      color: AppColors.cyan,
                      size: 40,
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // Main message
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _loadingMessage,
                    key: ValueKey(_loadingMessage),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 16),

                // Subtitle
                Text(
                  'This usually takes less than a minute',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Shimmer loading bar
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Container(
                      height: 6,
                      width: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: AppColors.cyan.withValues(alpha: 0.2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Stack(
                          children: [
                            Positioned(
                              left: _shimmerController.value * 240 - 60,
                              child: Container(
                                width: 60,
                                height: 6,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppColors.cyan,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // Skip button (after some time)
                if (_pollCount > 5)
                  TextButton(
                    onPressed: _navigateToHome,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
