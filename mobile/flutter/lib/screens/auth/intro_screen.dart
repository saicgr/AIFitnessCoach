import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_links.dart';
import '../../widgets/glass_sheet.dart';

/// Full-screen intro with a 3D depth carousel — center screenshot is prominent,
/// adjacent ones peek behind it scaled down and faded for a card-stack effect.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  late final PageController _pageController;
  double _pageOffset = 0;
  int _currentPage = 0;
  Timer? _autoRotateTimer;

  static const _autoRotateInterval = Duration(seconds: 4);

  static const List<_PageData> _pages = [
    _PageData(
      headline: 'Your 24/7',
      headlineAccent: 'Coach',
      subtitle: 'Workouts + Nutrition + Coaching',
      image: 'assets/images/intro_phone_1.png',
      bgColor: Color(0xFFE8A0B4),
      bgColorLight: Color(0xFFF5CAD8),
      borderColor: Color(0xFFC46A82),
    ),
    _PageData(
      headline: 'Log any Meal',
      headlineAccent: 'in any way',
      subtitle: 'Photo, text, barcode — instant nutrition breakdown',
      image: 'assets/images/intro_phone_2.png',
      bgColor: Color(0xFFF0C040),
      bgColorLight: Color(0xFFF8E088),
      borderColor: Color(0xFFD49A18),
    ),
    _PageData(
      headline: 'Workouts',
      headlineAccent: 'made For You',
      subtitle: 'AI builds your perfect plan with every detail explained',
      image: 'assets/images/intro_phone_3.png',
      bgColor: Color(0xFF40C4B4),
      bgColorLight: Color(0xFF80DDD0),
      borderColor: Color(0xFF188878),
    ),
    _PageData(
      headline: 'Track Every REP',
      headlineAccent: 'See every Gain',
      subtitle: 'Sets, reps, weight — all tracked with smart suggestions',
      image: 'assets/images/intro_phone_4.png',
      bgColor: Color(0xFF78C880),
      bgColorLight: Color(0xFFB0E4B4),
      borderColor: Color(0xFF3E8E48),
    ),
    _PageData(
      headline: 'See your',
      headlineAccent: 'transformation',
      subtitle: 'Progress photos, side-by-side comparisons',
      image: 'assets/images/intro_phone_5.png',
      bgColor: Color(0xFFB898D8),
      bgColorLight: Color(0xFFD8C0F0),
      borderColor: Color(0xFF8060A8),
    ),
    _PageData(
      headline: 'It learns',
      headlineAccent: 'what you love',
      subtitle: 'Stats, streaks, achievements — all in one place',
      image: 'assets/images/intro_phone_6.png',
      bgColor: Color(0xFF9A9A9A),
      bgColorLight: Color(0xFFC4C4C4),
      borderColor: Color(0xFF606060),
    ),
    _PageData(
      headline: 'Adapts to',
      headlineAccent: 'your style',
      subtitle: 'Your exercises, your preferences, your way',
      image: 'assets/images/intro_phone_7.png',
      bgColor: Color(0xFF3A3A3A),
      bgColorLight: Color(0xFF555555),
      borderColor: Color(0xFF1A1A1A),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onScroll);
    _startAutoRotate();
  }

  @override
  void dispose() {
    _autoRotateTimer?.cancel();
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _pageOffset = _pageController.page ?? 0;
    });
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

  void _showSupportSheet() {
    HapticFeedback.lightImpact();
    showGlassSheet(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
        final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
        final cardColor = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05);
        final cardBorder = isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.08);

        return GlassSheet(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                'Need Support?',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Join our community or reach out directly',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Social icons row — only show icons with URLs
              Builder(builder: (context) {
                final socials = <Widget>[];
                if (AppLinks.instagram.isNotEmpty) {
                  socials.add(_SocialIcon(icon: FontAwesomeIcons.instagram, label: 'Instagram', url: AppLinks.instagram, isDark: isDark));
                }
                if (AppLinks.discord.isNotEmpty) {
                  socials.add(_SocialIcon(icon: FontAwesomeIcons.discord, label: 'Discord', url: AppLinks.discord, isDark: isDark));
                }
                if (AppLinks.reddit.isNotEmpty) {
                  socials.add(_SocialIcon(icon: FontAwesomeIcons.reddit, label: 'Reddit', url: AppLinks.reddit, isDark: isDark));
                }
                if (AppLinks.twitter.isNotEmpty) {
                  socials.add(_SocialIcon(icon: FontAwesomeIcons.xTwitter, label: 'Twitter', url: AppLinks.twitter, isDark: isDark));
                }
                if (socials.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: [
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: socials,
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }),

              // Email support
              GestureDetector(
                onTap: () {
                  launchUrl(Uri.parse('mailto:${AppLinks.supportEmail}'));
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mail_outline_rounded,
                        color: textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLinks.supportEmail,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageData = _pages[_currentPage];
    final topPadding = MediaQuery.of(context).padding.top;

    // Smooth gradient interpolation between pages as you drag
    final floorIndex = _pageOffset.floor().clamp(0, _pages.length - 1);
    final ceilIndex = _pageOffset.ceil().clamp(0, _pages.length - 1);
    final t = _pageOffset - floorIndex;
    final bgTop = Color.lerp(_pages[floorIndex].bgColor, _pages[ceilIndex].bgColor, t)!;
    final bgBottom = Color.lerp(_pages[floorIndex].bgColorLight, _pages[ceilIndex].bgColorLight, t)!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: Stack(
          children: [
            // ── Text: headline + subtitle ──
            Positioned(
              top: topPadding + 56,
              left: 24,
              right: 24,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Column(
                  key: ValueKey(_currentPage),
                  children: [
                    Text(
                      pageData.headline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      pageData.headlineAccent,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pageData.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 15,
                        height: 1.4,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 3D Depth Carousel ──
            Positioned(
              top: topPadding + 200,
              left: 0,
              right: 0,
              bottom: 160,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final areaWidth = constraints.maxWidth;
                  final areaHeight = constraints.maxHeight;
                  final cardWidth = areaWidth * 0.78;

                  // Build card entries with z-index for proper layering
                  final entries = <_CardEntry>[];
                  for (int i = 0; i < _pages.length; i++) {
                    final distance = _pageOffset - i;
                    final absDistance = distance.abs();
                    // Only render cards within ±3 of current page
                    if (absDistance > 3) continue;

                    final scale = math.max(0.82, 1.0 - (absDistance * 0.08));
                    final opacity = (1.0 - (absDistance * 0.35)).clamp(0.0, 1.0);
                    // Tight overlap — adjacent cards peek just slightly from behind
                    final xShift = -distance * cardWidth * 0.15;
                    final yShift = absDistance * 8.0;

                    // Blur: center=0, adjacent=6, further=12
                    final blur = (absDistance * 6.0).clamp(0.0, 14.0);

                    entries.add(_CardEntry(
                      index: i,
                      zIndex: (100 - (absDistance * 10)).toInt(),
                      scale: scale,
                      opacity: opacity,
                      xOffset: xShift,
                      yOffset: yShift,
                      blurAmount: blur,
                    ));
                  }
                  // Sort by z-index so center card renders last (on top)
                  entries.sort((a, b) => a.zIndex.compareTo(b.zIndex));

                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragUpdate: (details) {
                      final pageWidth = _pageController.position.viewportDimension;
                      _pageController.position.moveTo(
                        _pageController.position.pixels -
                            details.delta.dx * (pageWidth / cardWidth) * 0.5,
                      );
                    },
                    onHorizontalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      int target;
                      if (velocity.abs() > 200) {
                        target = velocity < 0
                            ? (_pageOffset.ceil()).clamp(0, _pages.length - 1)
                            : (_pageOffset.floor()).clamp(0, _pages.length - 1);
                      } else {
                        target = _pageOffset.round().clamp(0, _pages.length - 1);
                      }
                      _pageController.animateToPage(
                        target,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                      );
                      _resetAutoRotate();
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: entries.map((entry) {
                        return Transform.translate(
                          offset: Offset(entry.xOffset, entry.yOffset),
                          child: Transform.scale(
                            scale: entry.scale,
                            child: Opacity(
                              opacity: entry.opacity,
                              child: SizedBox(
                                width: cardWidth,
                                height: areaHeight - 20,
                                child: _PhoneCard(
                                  data: _pages[entry.index],
                                  blurAmount: entry.blurAmount,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),

            // Hidden PageView — drives _pageController for auto-rotate & page tracking
            // Placed behind everything, ignores pointer so carousel GestureDetector works
            Positioned.fill(
              child: IgnorePointer(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    HapticFeedback.selectionClick();
                  },
                  itemBuilder: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // ── Header: glassmorphic pills ──
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
                      GestureDetector(
                        onTap: _showSupportSheet,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipOval(
                                child: Image.asset(
                                  'assets/images/app_icon.png',
                                  width: 24,
                                  height: 24,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.fitness_center,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'FitWiz',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/sign-in'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom: dots + button + tagline ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
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
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 20 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3.5),
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // Get Started — glassmorphic
                      GestureDetector(
                        onTap: () => context.push('/pre-auth-quiz'),
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Get Started',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tagline
                      Text(
                        'Your personalized fitness journey starts here',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
  final Color borderColor;

  const _PageData({
    required this.headline,
    required this.headlineAccent,
    required this.subtitle,
    required this.image,
    required this.bgColor,
    required this.bgColorLight,
    required this.borderColor,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone Card — screenshot in a squircle frame
// ─────────────────────────────────────────────────────────────────────────────

class _CardEntry {
  final int index;
  final int zIndex;
  final double scale;
  final double opacity;
  final double xOffset;
  final double yOffset;
  final double blurAmount;

  const _CardEntry({
    required this.index,
    required this.zIndex,
    required this.scale,
    required this.opacity,
    required this.xOffset,
    required this.yOffset,
    required this.blurAmount,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class _PhoneCard extends StatelessWidget {
  final _PageData data;
  final double blurAmount;

  const _PhoneCard({required this.data, this.blurAmount = 0});

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: data.borderColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Image.asset(
          data.image,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              width: 200,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(
                Icons.phone_android,
                color: Colors.white.withValues(alpha: 0.3),
                size: 48,
              ),
            );
          },
        ),
      ),
    );

    if (blurAmount > 0.5) {
      card = ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: blurAmount,
            sigmaY: blurAmount,
          ),
          child: card,
        ),
      );
    }

    return Center(child: card);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Social Icon — glassmorphic circle with icon
// ─────────────────────────────────────────────────────────────────────────────

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final bool isDark;

  const _SocialIcon({
    required this.icon,
    required this.label,
    required this.url,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final labelColor = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.08);

    return GestureDetector(
      onTap: () {
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        Navigator.pop(context);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: FaIcon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
