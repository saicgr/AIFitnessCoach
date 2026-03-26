import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/intro_animations.dart';

/// Full-screen vertically-snapping PageView with 5 feature pages.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  static const List<_PageData> _pages = [
    _PageData(
      headlineParts: [
        _TextPart('Your Workouts, '),
        _TextPart('Supercharged', isAccent: true),
      ],
      subtitle:
          'AI builds your perfect plan based on your goals, equipment, and schedule.',
      leftImage: 'assets/images/intro_workout.png',
      rightImage: 'assets/images/intro_tracking.png',
      gradientEnd: Color(0xFF1A0800),
      accent: Color(0xFFF97316),
    ),
    _PageData(
      headlineParts: [
        _TextPart('AI', isAccent: true),
        _TextPart(' Coach That Knows You'),
      ],
      subtitle:
          'Chat with your coach for form checks, meal advice, and motivation — all personalized.',
      leftImage: 'assets/images/intro_ai_coach.png',
      rightImage: 'assets/images/intro_library.png',
      gradientEnd: Color(0xFF001018),
      accent: Color(0xFF06B6D4),
    ),
    _PageData(
      headlineParts: [
        _TextPart('Track '),
        _TextPart('Everything', isAccent: true),
        _TextPart(', Effortlessly'),
      ],
      subtitle:
          'Nutrition, hydration, habits, progress — log it all in one tap.',
      leftImage: 'assets/images/intro_nutrition.png',
      rightImage: 'assets/images/intro_progress.png',
      gradientEnd: Color(0xFF001A0A),
      accent: Color(0xFF22C55E),
    ),
    _PageData(
      headlineParts: [
        _TextPart('1,700+', isAccent: true),
        _TextPart(' Exercises with Video'),
      ],
      subtitle:
          'HD demos for every movement. Search, filter, build your own.',
      leftImage: 'assets/images/intro_library.png',
      rightImage: 'assets/images/intro_tracking.png',
      gradientEnd: Color(0xFF0F0018),
      accent: Color(0xFF8B5CF6),
    ),
    _PageData(
      headlineParts: [
        _TextPart('Smarter Every '),
        _TextPart('Week', isAccent: true),
      ],
      subtitle:
          'Adapts to your progress, recovery, and schedule. Your fitness evolves with you.',
      leftImage: 'assets/images/intro_progress.png',
      rightImage: 'assets/images/intro_workout.png',
      gradientEnd: Color(0xFF181000),
      accent: Color(0xFFF59E0B),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pageData = _pages[_currentPage];

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0A0A0A),
                  pageData.gradientEnd,
                ],
              ),
            ),
          ),

          // Particle field
          const Positioned.fill(
            child: ParticleField(
              particleCount: 20,
              color: Colors.white,
            ),
          ),

          // PageView
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(
              parent: PageScrollPhysics(),
            ),
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return _IntroPage(
                data: _pages[index],
                screenSize: size,
                isActive: index == _currentPage,
              );
            },
          ),

          // Top gradient overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xCC0A0A0A),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom gradient overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    pageData.gradientEnd.withOpacity(0.95),
                    Colors.transparent,
                  ],
                ),
              ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/app_icon.png',
                          width: 28,
                          height: 28,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.fitness_center,
                            color: Colors.white,
                            size: 28,
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
                    // Sign In
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

          // Bottom: page dots + button + tagline
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
                                ? pageData.accent
                                : Colors.white.withOpacity(0.3),
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
                        color: Colors.white.withOpacity(0.5),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page Data
// ─────────────────────────────────────────────────────────────────────────────

class _TextPart {
  final String text;
  final bool isAccent;
  const _TextPart(this.text, {this.isAccent = false});
}

class _PageData {
  final List<_TextPart> headlineParts;
  final String subtitle;
  final String leftImage;
  final String rightImage;
  final Color gradientEnd;
  final Color accent;

  const _PageData({
    required this.headlineParts,
    required this.subtitle,
    required this.leftImage,
    required this.rightImage,
    required this.gradientEnd,
    required this.accent,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Intro Page
// ─────────────────────────────────────────────────────────────────────────────

class _IntroPage extends StatefulWidget {
  final _PageData data;
  final Size screenSize;
  final bool isActive;

  const _IntroPage({
    required this.data,
    required this.screenSize,
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
  late final Animation<double> _scaleFade;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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

    _scaleFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.85, curve: Curves.easeOut),
    );

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
    final width = widget.screenSize.width;
    final leftWidth = width * 0.52;
    final rightWidth = width * 0.48;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),

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
            child: _buildHeadline(),
          ),

          const SizedBox(height: 12),

          // Subtitle (150ms delay via interval shift)
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final delayedFade = CurvedAnimation(
                parent: _animController,
                curve: const Interval(0.2, 0.85, curve: Curves.easeOut),
              );
              final delayedSlide = Tween<Offset>(
                begin: const Offset(0, 20),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animController,
                curve: const Interval(0.2, 0.85, curve: Curves.easeOut),
              ));
              return Opacity(
                opacity: delayedFade.value,
                child: Transform.translate(
                  offset: delayedSlide.value,
                  child: child,
                ),
              );
            },
            child: Text(
              widget.data.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Screenshots
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Opacity(
                opacity: _scaleFade.value,
                child: Transform.scale(
                  scale: 0.9 + (_scaleFade.value * 0.1),
                  child: child,
                ),
              );
            },
            child: SizedBox(
              height: widget.screenSize.height * 0.42,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Left image (larger, tilted left)
                  Positioned(
                    left: 0,
                    child: BreathingGlow(
                      color: widget.data.accent,
                      child: ParallaxContainer(
                        scrollOffset: 0.0,
                        child: Transform.rotate(
                          angle: -3 * pi / 180,
                          child: _buildScreenshot(
                            widget.data.leftImage,
                            leftWidth,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Right image (smaller, tilted right, overlapping)
                  Positioned(
                    right: 0,
                    top: 40,
                    child: BreathingGlow(
                      color: widget.data.accent,
                      child: ParallaxContainer(
                        scrollOffset: 0.0,
                        child: Transform.rotate(
                          angle: 2 * pi / 180,
                          child: _buildScreenshot(
                            widget.data.rightImage,
                            rightWidth,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeadline() {
    return Text.rich(
      TextSpan(
        children: widget.data.headlineParts.map((part) {
          if (part.isAccent) {
            // We wrap accent text inline; ShimmerText is a widget so we use
            // WidgetSpan to embed it.
            return WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: ShimmerText(
                shimmerColor: widget.data.accent,
                child: Text(
                  part.text,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: widget.data.accent,
                  ),
                ),
              ),
            );
          }
          return TextSpan(
            text: part.text,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildScreenshot(String assetPath, double width) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        assetPath,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: width,
            height: width * 1.8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.image_outlined,
              color: Colors.white.withOpacity(0.2),
              size: 48,
            ),
          );
        },
      ),
    );
  }
}
