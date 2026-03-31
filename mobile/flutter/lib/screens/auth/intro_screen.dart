import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';

/// Full-screen horizontally-swiping intro with 5 feature pages.
/// Each page: bold caption at top, single centered screenshot, colored background.
/// Matches Play Store screenshot style (Flo-inspired).
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoRotateTimer;

  static const _autoRotateInterval = Duration(seconds: 4);

  static const List<_PageData> _pages = [
    _PageData(
      headline: 'Your AI Coach.',
      headlineAccent: 'Ask Anything.',
      subtitle: 'Chat with your coach for form checks, meal advice, and motivation.',
      image: 'assets/images/intro_ai_coach.png',
      bgColor: Color(0xFF2D2D2D),
      bgColorLight: Color(0xFF3A3A3A),
      accent: Color(0xFF06B6D4),
      textOnBg: Colors.white,
      subtitleOnBg: Colors.white70,
    ),
    _PageData(
      headline: 'Type Any Meal.',
      headlineAccent: 'Instant Nutrition.',
      subtitle: 'Describe what you ate — AI breaks it down into calories and macros.',
      image: 'assets/images/intro_nutrition.png',
      bgColor: Color(0xFFF97316),
      bgColorLight: Color(0xFFFF8C3A),
      accent: Colors.white,
      textOnBg: Colors.white,
      subtitleOnBg: Colors.white70,
    ),
    _PageData(
      headline: 'Every Exercise.',
      headlineAccent: 'Chosen For You.',
      subtitle: 'AI builds your perfect plan — and tells you why it picked each one.',
      image: 'assets/images/intro_workout.png',
      bgColor: Color(0xFF6B7280),
      bgColorLight: Color(0xFF8B95A5),
      accent: Colors.white,
      textOnBg: Colors.white,
      subtitleOnBg: Colors.white70,
    ),
    _PageData(
      headline: 'Track Every Rep.',
      headlineAccent: 'See Every Gain.',
      subtitle: 'Heatmaps, streaks, PRs — watch your progress stack up.',
      image: 'assets/images/intro_progress.png',
      bgColor: Color(0xFF166534),
      bgColorLight: Color(0xFF22863A),
      accent: Color(0xFF4ADE80),
      textOnBg: Colors.white,
      subtitleOnBg: Colors.white70,
    ),
    _PageData(
      headline: 'It Learns',
      headlineAccent: 'What You Love.',
      subtitle: 'Your staples, your schedule, your way. Fitness that\'s truly yours.',
      image: 'assets/images/intro_library.png',
      bgColor: Color(0xFFB45309),
      bgColorLight: Color(0xFFD97706),
      accent: Color(0xFFFDE68A),
      textOnBg: Colors.white,
      subtitleOnBg: Colors.white70,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoRotate();
  }

  @override
  void dispose() {
    _autoRotateTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoRotate() {
    _autoRotateTimer?.cancel();
    _autoRotateTimer = Timer.periodic(_autoRotateInterval, (_) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % _pages.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _resetAutoRotate() {
    _startAutoRotate();
  }

  @override
  Widget build(BuildContext context) {
    final pageData = _pages[_currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [pageData.bgColor, pageData.bgColorLight],
          ),
        ),
        child: Stack(
          children: [
            // PageView
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification &&
                    notification.dragDetails != null) {
                  _resetAutoRotate();
                }
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _IntroPage(
                    data: _pages[index],
                    isActive: index == _currentPage,
                  );
                },
              ),
            ),

            // Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ClipOval(
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              width: 28,
                              height: 28,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.fitness_center,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'FitWiz',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.push('/sign-in'),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom: dots + button + tagline
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Page indicator dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (index) {
                          final isActive = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Get Started button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => context.push('/pre-auth-quiz'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tagline
                      Text(
                        'Your AI-powered fitness journey starts here',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page Data
// ─────────────────────────────────────────────────────────────────────────────

class _PageData {
  final String headline;
  final String headlineAccent;
  final String subtitle;
  final String image;
  final Color bgColor;
  final Color bgColorLight;
  final Color accent;
  final Color textOnBg;
  final Color subtitleOnBg;

  const _PageData({
    required this.headline,
    required this.headlineAccent,
    required this.subtitle,
    required this.image,
    required this.bgColor,
    required this.bgColorLight,
    required this.accent,
    required this.textOnBg,
    required this.subtitleOnBg,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Intro Page — single centered screenshot, bold caption at top
// ─────────────────────────────────────────────────────────────────────────────

class _IntroPage extends StatefulWidget {
  final _PageData data;
  final bool isActive;

  const _IntroPage({
    required this.data,
    required this.isActive,
  });

  @override
  State<_IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<_IntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    if (widget.isActive) {
      _animController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _IntroPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: screenHeight * 0.12),

          // Headline
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeIn.value,
                child: Transform.translate(
                  offset: _slideUp.value,
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                Text(
                  widget.data.headline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: widget.data.textOnBg,
                    height: 1.1,
                  ),
                ),
                Text(
                  widget.data.headlineAccent,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: widget.data.accent,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeIn.value,
                child: child,
              );
            },
            child: Text(
              widget.data.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.data.subtitleOnBg,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Single centered screenshot
          Expanded(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final scaleFade = CurvedAnimation(
                  parent: _animController,
                  curve: const Interval(0.2, 0.85, curve: Curves.easeOut),
                );
                return Opacity(
                  opacity: scaleFade.value,
                  child: Transform.scale(
                    scale: 0.92 + (scaleFade.value * 0.08),
                    child: child,
                  ),
                );
              },
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      widget.data.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        // Placeholder when screenshot assets don't exist yet
                        return Container(
                          width: 280,
                          height: 500,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone_android,
                                color: Colors.white.withValues(alpha: 0.3),
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Screenshot',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Space for bottom controls
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
