import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';

/// Animation types for different slides
enum SlideAnimationType {
  counter,    // Animated number counting up
  orbit,      // Icons orbiting center
  cards,      // Cycling style cards
  calendar,   // Days appearing animation
  floating,   // Multiple floating icons
  flame,      // Growing streak flame
}

/// Welcome screen with intro slides for new users
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoSlideTimer;
  bool _userInteracted = false;

  // Auto-slide duration
  static const _autoSlideDuration = Duration(seconds: 5);

  late final AnimationController _progressController;

  // Sign-in state
  bool _isLoading = false;
  String? _loadingMessage;
  final List<String> _loadingMessages = [
    'Connecting to server...',
    'Waking up backend (cold start)...',
    'Almost there...',
    'Verifying credentials...',
  ];

  final List<_SlideData> _slides = [
    // Slide 1: Exercise Library with animated counter
    _SlideData(
      title: '1,792\nExercises',
      subtitle: 'Every move, every muscle, every goal—with HD video demos',
      primaryColor: AppColors.cyan,
      secondaryColor: AppColors.purple,
      icon: Icons.fitness_center,
      features: ['HD video demos', 'Beginner to Advanced', 'Filter by equipment'],
      animationType: SlideAnimationType.counter,
      counterTarget: 1792,
    ),
    // Slide 2: AI Agents
    _SlideData(
      title: '5 AI Agents\nOne App',
      subtitle: 'Coach, Nutrition, Workout, Recovery, and Hydration experts—all at your service',
      primaryColor: AppColors.purple,
      secondaryColor: AppColors.cyan,
      icon: Icons.auto_awesome,
      features: ['@coach for guidance', '@nutrition for meals', '@hydration for water'],
      animationType: SlideAnimationType.orbit,
      agentIcons: [Icons.smart_toy, Icons.restaurant_menu, Icons.fitness_center, Icons.healing, Icons.water_drop],
    ),
    // Slide 3: AI Personalization (100 unique combinations!)
    _SlideData(
      title: '100 AI\nPersonalities',
      subtitle: '10 coaching styles × 10 communication tones—mix and match your perfect coach',
      primaryColor: AppColors.orange,
      secondaryColor: AppColors.error,
      icon: Icons.tune,
      features: ['Zen Master + Pirate', 'Drill Sergeant + Gen Z', 'Roast Mode + British'],
      animationType: SlideAnimationType.cards,
      styleCards: ['Motivational', 'Tough Love', 'Zen Master', 'Roast Mode', 'Hype Beast'],
    ),
    // Slide 4: AI-Generated Workouts
    _SlideData(
      title: 'AI-Generated\nMonthly Plans',
      subtitle: '30-day schedules crafted for your goals, equipment, and fitness level',
      primaryColor: AppColors.success,
      secondaryColor: AppColors.cyan,
      icon: Icons.calendar_month,
      features: ['Adapts to injuries', 'Progressive overload', 'Creative workout names'],
      animationType: SlideAnimationType.calendar,
    ),
    // Slide 5: Complete Tracking
    _SlideData(
      title: 'Track\nEverything',
      subtitle: 'Nutrition, hydration, body metrics, PRs—all in one place',
      primaryColor: const Color(0xFFE91E63), // Pink
      secondaryColor: AppColors.purple,
      icon: Icons.analytics,
      features: ['AI meal analysis', 'Auto PR detection', '10+ body metrics'],
      animationType: SlideAnimationType.floating,
      trackingIcons: [Icons.restaurant, Icons.water_drop, Icons.monitor_weight, Icons.emoji_events, Icons.favorite],
    ),
    // Slide 6: Smart Reminders & Motivation
    _SlideData(
      title: 'Smart\nReminders',
      subtitle: 'AI notifications like "30g protein left today" keep you on track without annoying you',
      primaryColor: AppColors.orange,
      secondaryColor: const Color(0xFFFFD700), // Gold
      icon: Icons.local_fire_department,
      features: ['Nutrition nudges', 'Workout streaks', 'Weekly AI summaries'],
      animationType: SlideAnimationType.flame,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _autoSlideDuration,
    );
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _progressController.forward(from: 0);
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer(_autoSlideDuration, () {
      if (mounted && !_userInteracted) {
        _nextPage(auto: true);
      }
    });
  }

  void _resetAutoSlide() {
    _userInteracted = true;
    _autoSlideTimer?.cancel();
    _progressController.stop();
    // Resume auto-slide after 10 seconds of no interaction
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _userInteracted = false;
        _startAutoSlide();
      }
    });
  }

  void _nextPage({bool auto = false}) {
    if (!auto) {
      HapticFeedback.lightImpact();
      _resetAutoSlide();
    }
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
      if (auto) _startAutoSlide();
    }
    // On last slide, sign-in buttons are shown instead of navigating
  }

  void _previousPage() {
    HapticFeedback.lightImpact();
    _resetAutoSlide();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goToPage(int index) {
    HapticFeedback.lightImpact();
    _resetAutoSlide();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  void _skipToSignIn() {
    HapticFeedback.mediumImpact();
    _resetAutoSlide();
    _pageController.animateToPage(
      _slides.length - 1, // Go to last slide
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = _loadingMessages[0];
    });

    // Cycle through loading messages for long waits (Render cold start)
    int messageIndex = 0;
    final messageTimer = Stream.periodic(
      const Duration(seconds: 3),
      (_) => _loadingMessages[++messageIndex % _loadingMessages.length],
    ).listen((message) {
      if (mounted && _isLoading) {
        setState(() => _loadingMessage = message);
      }
    });

    try {
      await ref.read(authStateProvider.notifier).signInWithGoogle();
    } finally {
      messageTimer.cancel();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
        });
      }
    }
  }

  void _signInWithApple() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Apple Sign In coming soon!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.purple,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final currentSlide = _slides[_currentPage];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Animated background gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5,
                colors: [
                  currentSlide.primaryColor.withOpacity(isDark ? 0.15 : 0.08),
                  backgroundColor,
                ],
              ),
            ),
          ),

          // Floating particles
          ...List.generate(6, (index) => _FloatingParticle(
            index: index,
            color: currentSlide.primaryColor,
            isDark: isDark,
          )),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar with progress indicator and Skip button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                  child: Row(
                    children: [
                      // Progress indicator
                      Expanded(
                        child: Row(
                          children: List.generate(_slides.length, (index) {
                            final isActive = index == _currentPage;
                            final isPast = index < _currentPage;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => _goToPage(index),
                                child: Container(
                                  height: 4,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    color: isPast
                                        ? currentSlide.primaryColor
                                        : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                                  ),
                                  child: isActive
                                      ? AnimatedBuilder(
                                          animation: _progressController,
                                          builder: (context, child) {
                                            return FractionallySizedBox(
                                              alignment: Alignment.centerLeft,
                                              widthFactor: _userInteracted ? 1 : _progressController.value,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(2),
                                                  color: currentSlide.primaryColor,
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : null,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      // Skip button (only show when not on last slide)
                      if (_currentPage < _slides.length - 1) ...[
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: _skipToSignIn,
                          style: TextButton.styleFrom(
                            foregroundColor: textMuted,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text('Skip'),
                        ),
                      ],
                    ],
                  ),
                ),

                // Page view with slides
                Expanded(
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity! < -100) {
                        _nextPage();
                      } else if (details.primaryVelocity! > 100) {
                        _previousPage();
                      }
                    },
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                        if (!_userInteracted) _startAutoSlide();
                      },
                      itemCount: _slides.length,
                      itemBuilder: (context, index) {
                        return _SlideWidget(
                          data: _slides[index],
                          isActive: _currentPage == index,
                          slideIndex: index,
                        );
                      },
                    ),
                  ),
                ),

                // Bottom navigation
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: _currentPage == _slides.length - 1
                      ? _buildSignInSection(isDark, textMuted)
                      : _buildNavigationSection(isDark, textMuted, currentSlide),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Navigation section for slides 1-5
  Widget _buildNavigationSection(bool isDark, Color textMuted, _SlideData currentSlide) {
    return Column(
      children: [
        // Navigation buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Back button (only show on pages > 0)
            if (_currentPage > 0)
              Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.only(right: 12),
                child: OutlinedButton(
                  onPressed: _previousPage,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    side: BorderSide(
                      color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .slideX(begin: -0.2),

            // Continue button
            SizedBox(
              width: 220,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _nextPage(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentSlide.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 4,
                  shadowColor: currentSlide.primaryColor.withOpacity(0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              )
                  .animate(
                    onPlay: (c) => c.repeat(reverse: true),
                  )
                  .shimmer(
                    duration: 2000.ms,
                    color: Colors.white.withOpacity(0.2),
                  ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Already have an account
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: TextStyle(
                color: textMuted,
                fontSize: 14,
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.go('/login');
              },
              child: Text(
                'Sign In',
                style: TextStyle(
                  color: currentSlide.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Sign-in section for the last slide
  Widget _buildSignInSection(bool isDark, Color textMuted) {
    final authState = ref.watch(authStateProvider);
    final buttonColor = isDark ? Colors.white : AppColorsLight.elevated;
    final buttonTextColor = isDark ? Colors.black87 : AppColorsLight.textPrimary;

    return Column(
      children: [
        // Back button row
        if (_currentPage > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 56,
              height: 56,
              margin: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  side: BorderSide(
                    color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                ),
              ),
            ),
          ),

        // Google Sign In button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _signInWithGoogle,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: buttonTextColor,
              disabledBackgroundColor: buttonColor.withOpacity(0.5),
              elevation: isDark ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: isDark
                    ? BorderSide.none
                    : BorderSide(color: AppColorsLight.cardBorder, width: 1),
              ),
            ),
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? Colors.black54 : AppColorsLight.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _loadingMessage ?? 'Signing in...',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.black54 : AppColorsLight.textMuted,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://www.google.com/favicon.ico',
                        width: 20,
                        height: 20,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.g_mobiledata,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: buttonTextColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),

        const SizedBox(height: 12),

        // Apple Sign In button with "Coming Soon" label
        Column(
          children: [
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 10,
                color: textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signInWithApple,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  disabledBackgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                  elevation: isDark ? 0 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.apple,
                      size: 24,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Continue with Apple',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.1),

        const SizedBox(height: 16),

        // Error message
        if (authState.status == AuthStatus.error && authState.errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    authState.errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().shake(),

        const SizedBox(height: 16),

        // Terms
        Text(
          'By continuing, you agree to our Terms of Service and Privacy Policy',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textMuted),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }
}

class _SlideData {
  final String title;
  final String subtitle;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  final List<String> features;
  final SlideAnimationType animationType;
  final int? counterTarget;
  final List<IconData>? agentIcons;
  final List<String>? styleCards;
  final List<IconData>? trackingIcons;

  const _SlideData({
    required this.title,
    required this.subtitle,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    required this.features,
    this.animationType = SlideAnimationType.counter,
    this.counterTarget,
    this.agentIcons,
    this.styleCards,
    this.trackingIcons,
  });
}

class _SlideWidget extends StatelessWidget {
  final _SlideData data;
  final bool isActive;
  final int slideIndex;

  const _SlideWidget({
    required this.data,
    required this.isActive,
    required this.slideIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Main visual based on animation type
          _buildAnimatedVisual(context),

          const SizedBox(height: 32),

          // Title with gradient
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [data.primaryColor, data.secondaryColor],
            ).createShader(bounds),
            child: Text(
              data.title,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
              textAlign: TextAlign.center,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.3, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            data.subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: textSecondary,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(delay: 150.ms, duration: 400.ms)
              .slideY(begin: 0.2, delay: 150.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 24),

          // Feature chips
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: data.features.asMap().entries.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: data.primaryColor.withOpacity(isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: data.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: data.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.value,
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
                  .animate(target: isActive ? 1 : 0)
                  .fadeIn(delay: Duration(milliseconds: 250 + (entry.key * 100)))
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    delay: Duration(milliseconds: 250 + (entry.key * 100)),
                    curve: Curves.easeOutBack,
                  );
            }).toList(),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildAnimatedVisual(BuildContext context) {
    switch (data.animationType) {
      case SlideAnimationType.counter:
        return _CounterAnimation(
          target: data.counterTarget ?? 0,
          primaryColor: data.primaryColor,
          secondaryColor: data.secondaryColor,
          isActive: isActive,
        );
      case SlideAnimationType.orbit:
        return _OrbitAnimation(
          icons: data.agentIcons ?? [],
          primaryColor: data.primaryColor,
          secondaryColor: data.secondaryColor,
          isActive: isActive,
        );
      case SlideAnimationType.cards:
        return _CardsAnimation(
          cards: data.styleCards ?? [],
          primaryColor: data.primaryColor,
          secondaryColor: data.secondaryColor,
          isActive: isActive,
        );
      case SlideAnimationType.calendar:
        return _CalendarAnimation(
          primaryColor: data.primaryColor,
          secondaryColor: data.secondaryColor,
          isActive: isActive,
        );
      case SlideAnimationType.floating:
        return _FloatingIconsAnimation(
          icons: data.trackingIcons ?? [],
          primaryColor: data.primaryColor,
          secondaryColor: data.secondaryColor,
          isActive: isActive,
        );
      case SlideAnimationType.flame:
        return _FlameAnimation(
          primaryColor: data.primaryColor,
          secondaryColor: data.secondaryColor,
          isActive: isActive,
        );
    }
  }
}

// ============================================================================
// ANIMATION WIDGETS
// ============================================================================

/// Animated counter from 0 to target
class _CounterAnimation extends StatefulWidget {
  final int target;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isActive;

  const _CounterAnimation({
    required this.target,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isActive,
  });

  @override
  State<_CounterAnimation> createState() => _CounterAnimationState();
}

class _CounterAnimationState extends State<_CounterAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _countAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _countAnimation = IntTween(begin: 0, end: widget.target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    // Start animation if active on first load
    if (widget.isActive) {
      // Small delay to let the widget fully render first
      Future.microtask(() {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void didUpdateWidget(_CounterAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
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
    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background glow
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.primaryColor.withOpacity(0.3),
                  widget.primaryColor.withOpacity(0),
                ],
              ),
            ),
          ),
          // Icon background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [widget.primaryColor, widget.secondaryColor],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.primaryColor.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _countAnimation,
                  builder: (context, child) {
                    return Text(
                      NumberFormat('#,###').format(_countAnimation.value),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.fitness_center,
                  color: Colors.white70,
                  size: 24,
                ),
              ],
            ),
          )
              .animate(target: widget.isActive ? 1 : 0)
              .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.easeOutBack),
        ],
      ),
    );
  }
}

/// 5 AI agent icons orbiting
class _OrbitAnimation extends StatefulWidget {
  final List<IconData> icons;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isActive;

  const _OrbitAnimation({
    required this.icons,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isActive,
  });

  @override
  State<_OrbitAnimation> createState() => _OrbitAnimationState();
}

class _OrbitAnimationState extends State<_OrbitAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.success,      // Nutrition - green
      AppColors.orange,       // Workout - orange
      const Color(0xFFE91E63), // Recovery - pink
      AppColors.cyan,         // Hydration - cyan
      AppColors.purple,       // Coach - purple
    ];

    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Center icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.primaryColor, widget.secondaryColor],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor.withOpacity(0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
              ),
              // Orbiting icons
              ...List.generate(widget.icons.length, (index) {
                final angle = (_controller.value * 2 * math.pi) + (index * 2 * math.pi / widget.icons.length);
                final radius = 75.0;
                final x = math.cos(angle) * radius;
                final y = math.sin(angle) * radius;

                return Transform.translate(
                  offset: Offset(x, y),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors[index % colors.length].withOpacity(0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icons[index],
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    )
        .animate(target: widget.isActive ? 1 : 0)
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
  }
}

/// Cycling style cards
class _CardsAnimation extends StatefulWidget {
  final List<String> cards;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isActive;

  const _CardsAnimation({
    required this.cards,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isActive,
  });

  @override
  State<_CardsAnimation> createState() => _CardsAnimationState();
}

class _CardsAnimationState extends State<_CardsAnimation> {
  int _currentCard = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCycling();
  }

  void _startCycling() {
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _currentCard = (_currentCard + 1) % widget.cards.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background cards (stacked)
          ...List.generate(3, (index) {
            final offset = (2 - index) * 8.0;
            final scale = 1 - ((2 - index) * 0.05);
            return Transform.translate(
              offset: Offset(0, offset),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 200,
                  height: 100,
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withOpacity(0.1 + (index * 0.1)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.primaryColor.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
            );
          }),
          // Front card with current style
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
            child: Container(
              key: ValueKey(_currentCard),
              width: 200,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.primaryColor, widget.secondaryColor],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.psychology, color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    widget.cards[_currentCard],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate(target: widget.isActive ? 1 : 0)
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
  }
}

/// Calendar days appearing
class _CalendarAnimation extends StatefulWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final bool isActive;

  const _CalendarAnimation({
    required this.primaryColor,
    required this.secondaryColor,
    required this.isActive,
  });

  @override
  State<_CalendarAnimation> createState() => _CalendarAnimationState();
}

class _CalendarAnimationState extends State<_CalendarAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    // Start animation if active on first load
    if (widget.isActive) {
      Future.microtask(() {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void didUpdateWidget(_CalendarAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 180,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevated : AppColorsLight.elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.primaryColor.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month, color: widget.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Your Month',
                  style: TextStyle(
                    color: widget.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Grid of days
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return GridView.count(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(28, (index) {
                      final showDay = index / 28 < _controller.value;
                      final isWorkout = [0, 2, 4, 7, 9, 11, 14, 16, 18, 21, 23, 25].contains(index);
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: showDay ? 1 : 0.2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: showDay && isWorkout
                                ? widget.primaryColor
                                : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: showDay && isWorkout
                              ? const Icon(Icons.fitness_center, color: Colors.white, size: 10)
                              : null,
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    )
        .animate(target: widget.isActive ? 1 : 0)
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
  }
}

/// Floating tracking icons
class _FloatingIconsAnimation extends StatefulWidget {
  final List<IconData> icons;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isActive;

  const _FloatingIconsAnimation({
    required this.icons,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isActive,
  });

  @override
  State<_FloatingIconsAnimation> createState() => _FloatingIconsAnimationState();
}

class _FloatingIconsAnimationState extends State<_FloatingIconsAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.icons.length, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 2000 + (index * 200)),
      )..repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.success,
      AppColors.cyan,
      AppColors.orange,
      const Color(0xFFFFD700),
      const Color(0xFFE91E63),
    ];

    final positions = [
      const Offset(-60, -40),
      const Offset(60, -30),
      const Offset(-50, 30),
      const Offset(50, 50),
      const Offset(0, 0),
    ];

    return SizedBox(
      width: 200,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(widget.icons.length, (index) {
          return AnimatedBuilder(
            animation: _controllers[index],
            builder: (context, child) {
              final bounce = math.sin(_controllers[index].value * math.pi) * 10;
              return Transform.translate(
                offset: positions[index] + Offset(0, bounce),
                child: Container(
                  width: index == 4 ? 60 : 48,
                  height: index == 4 ? 60 : 48,
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors[index].withOpacity(0.4),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icons[index],
                    color: Colors.white,
                    size: index == 4 ? 28 : 22,
                  ),
                ),
              );
            },
          );
        }),
      ),
    )
        .animate(target: widget.isActive ? 1 : 0)
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
  }
}

/// Growing flame animation
class _FlameAnimation extends StatefulWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final bool isActive;

  const _FlameAnimation({
    required this.primaryColor,
    required this.secondaryColor,
    required this.isActive,
  });

  @override
  State<_FlameAnimation> createState() => _FlameAnimationState();
}

class _FlameAnimationState extends State<_FlameAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1 + (_controller.value * 0.1);
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: 140 * scale,
                height: 140 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.primaryColor.withOpacity(0.3),
                      widget.primaryColor.withOpacity(0),
                    ],
                  ),
                ),
              ),
              // Main flame circle
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [widget.secondaryColor, widget.primaryColor],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '7 Days',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    )
        .animate(target: widget.isActive ? 1 : 0)
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.easeOutBack);
  }
}

// ============================================================================
// UTILITY WIDGETS
// ============================================================================

class _FloatingParticle extends StatefulWidget {
  final int index;
  final Color color;
  final bool isDark;

  const _FloatingParticle({
    required this.index,
    required this.color,
    required this.isDark,
  });

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final double _startX;
  late final double _startY;
  late final double _size;

  @override
  void initState() {
    super.initState();
    final random = math.Random(widget.index);
    _startX = random.nextDouble();
    _startY = random.nextDouble();
    _size = 4 + random.nextDouble() * 8;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10 + random.nextInt(10)),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = math.sin(_controller.value * math.pi * 2) * 30;
        return Positioned(
          left: _startX * size.width + offset,
          top: _startY * size.height + (offset * 0.5),
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(widget.isDark ? 0.3 : 0.2),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
