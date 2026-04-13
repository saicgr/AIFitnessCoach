import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_links.dart';
import '../../widgets/glass_sheet.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _expandController;
  double _pageOffset = 0;
  int _currentPage = 0;
  Timer? _autoRotateTimer;
  bool _isExpanded = false;
  bool _isCollapsing = false;

  static const _autoRotateInterval = Duration(seconds: 2);
  static const _lastIndex = 6;

  static const List<_PageData> _pages = [
    _PageData(headline: 'Your 24/7', headlineAccent: 'Coach', subtitle: 'Workouts + Nutrition + Coaching', image: 'assets/images/intro_phone_1.png', bgColor: Color(0xFFA86878), bgColorLight: Color(0xFFC4899A), borderColor: Color(0xFF8A4A5E)),
    _PageData(headline: 'Log any Meal', headlineAccent: 'in any way', subtitle: 'Photo, text, barcode — instant nutrition breakdown', image: 'assets/images/intro_phone_2.png', bgColor: Color(0xFFB89020), bgColorLight: Color(0xFFD4AD48), borderColor: Color(0xFF9A7410)),
    _PageData(headline: 'Workouts', headlineAccent: 'made For You', subtitle: 'AI builds your perfect plan with every detail explained', image: 'assets/images/intro_phone_3.png', bgColor: Color(0xFF2A9488), bgColorLight: Color(0xFF58B8AC), borderColor: Color(0xFF146860)),
    _PageData(headline: 'Track Every REP', headlineAccent: 'See every Gain', subtitle: 'Sets, reps, weight — all tracked with smart suggestions', image: 'assets/images/intro_phone_4.png', bgColor: Color(0xFF4A9A54), bgColorLight: Color(0xFF78C080), borderColor: Color(0xFF2E6E36)),
    _PageData(headline: 'See your', headlineAccent: 'transformation', subtitle: 'Progress photos, side-by-side comparisons', image: 'assets/images/intro_phone_5.png', bgColor: Color(0xFF8868A8), bgColorLight: Color(0xFFAA90C8), borderColor: Color(0xFF604880)),
    _PageData(headline: 'It learns', headlineAccent: 'what you love', subtitle: 'Stats, streaks, achievements — all in one place', image: 'assets/images/intro_phone_6.png', bgColor: Color(0xFF707070), bgColorLight: Color(0xFF959595), borderColor: Color(0xFF484848)),
    _PageData(headline: 'Adapts to', headlineAccent: 'your style', subtitle: 'Your exercises, your preferences, your way', image: 'assets/images/intro_phone_7.png', bgColor: Color(0xFF3A3A3A), bgColorLight: Color(0xFF555555), borderColor: Color(0xFF1A1A1A)),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onScroll);
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(() => setState(() {}));
    _startAutoRotate();
  }

  @override
  void dispose() {
    _autoRotateTimer?.cancel();
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() => _pageOffset = _pageController.page ?? 0);
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    HapticFeedback.selectionClick();
    if (_isCollapsing) return; // Don't re-trigger during collapse animation
    if (index == _lastIndex) {
      _autoRotateTimer?.cancel();
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && _currentPage == _lastIndex && !_isCollapsing) {
          _isExpanded = true;
          _expandController.forward();
          HapticFeedback.mediumImpact();
        }
      });
    } else if (_isExpanded) {
      // Swiped back from last page — collapse
      _isExpanded = false;
      _expandController.reverse();
      _startAutoRotate();
    }
  }

  void _collapseAndGoBack() {
    _isCollapsing = true;
    // Jump to page 0 while still expanded (card covers screen, user can't see the jump)
    _pageController.jumpToPage(0);
    setState(() {
      _currentPage = 0;
      _pageOffset = 0;
    });
    // Now collapse the card from fullscreen back to the carousel at page 0
    _isExpanded = false;
    _expandController.reverse().then((_) {
      if (mounted) {
        _isCollapsing = false;
        _startAutoRotate();
      }
    });
  }

  void _startAutoRotate() {
    _autoRotateTimer?.cancel();
    _autoRotateTimer = Timer.periodic(_autoRotateInterval, (_) {
      if (!mounted || _isExpanded) return;
      if (_currentPage >= _lastIndex) return;
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _resetAutoRotate() => _startAutoRotate();

  void _showSupportSheet() {
    HapticFeedback.lightImpact();
    showGlassSheet(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
        final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
        final cardColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05);
        final cardBorder = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08);
        return GlassSheet(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 12),
            Text('Need Support?', style: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Join our community or reach out directly', style: TextStyle(color: textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            Builder(builder: (_) {
              final socials = <Widget>[];
              if (AppLinks.instagram.isNotEmpty) socials.add(_SocialIcon(icon: FontAwesomeIcons.instagram, label: 'Instagram', url: AppLinks.instagram, isDark: isDark));
              if (AppLinks.discord.isNotEmpty) socials.add(_SocialIcon(icon: FontAwesomeIcons.discord, label: 'Discord', url: AppLinks.discord, isDark: isDark));
              if (AppLinks.reddit.isNotEmpty) socials.add(_SocialIcon(icon: FontAwesomeIcons.reddit, label: 'Reddit', url: AppLinks.reddit, isDark: isDark));
              if (AppLinks.twitter.isNotEmpty) socials.add(_SocialIcon(icon: FontAwesomeIcons.xTwitter, label: 'Twitter', url: AppLinks.twitter, isDark: isDark));
              if (socials.isEmpty) return const SizedBox.shrink();
              return Column(children: [Wrap(spacing: 16, runSpacing: 12, alignment: WrapAlignment.center, children: socials), const SizedBox(height: 24)]);
            }),
            GestureDetector(
              onTap: () { launchUrl(Uri.parse('mailto:${AppLinks.supportEmail}')); Navigator.pop(ctx); },
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: cardBorder)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.mail_outline_rounded, color: textSecondary, size: 18), const SizedBox(width: 8),
                  Text(AppLinks.supportEmail, style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    final floorIdx = _pageOffset.floor().clamp(0, _pages.length - 1);
    final ceilIdx = _pageOffset.ceil().clamp(0, _pages.length - 1);
    final t = _pageOffset - floorIdx;
    final bgTop = Color.lerp(_pages[floorIdx].bgColor, _pages[ceilIdx].bgColor, t)!;
    final bgBottom = Color.lerp(_pages[floorIdx].bgColorLight, _pages[ceilIdx].bgColorLight, t)!;

    // Expand animation value (0 = carousel, 1 = fullscreen)
    final ep = Curves.easeInOutCubic.transform(_expandController.value);
    final uiFade = (1.0 - ep * 2.5).clamp(0.0, 1.0);
    final ctaFade = ((ep - 0.4) / 0.6).clamp(0.0, 1.0);

    // Card geometry — use actual screenshot aspect ratio (1080x2400 = 2.22)
    final normalCardW = screenW * 0.68;
    final textBottom = topPad + 200.0;
    // Max height: from below text to 36px above screen bottom (for dots)
    final maxH = screenH - textBottom - 36;
    final naturalH = normalCardW * 2.22;
    final normalCardH = math.min(naturalH, maxH);
    final carouselTop = textBottom;
    final normalLeft = (screenW - normalCardW) / 2;
    final actualCarouselTop = carouselTop;

    // Card geometry — interpolated
    final cardLeft = lerpDouble(normalLeft, 0, ep)!;
    final cardTop = lerpDouble(actualCarouselTop, 0, ep)!;
    final cardW = lerpDouble(normalCardW, screenW, ep)!;
    final cardH = lerpDouble(normalCardH, screenH, ep)!;
    final bRadius = lerpDouble(30, 0, ep)!;
    final iRadius = lerpDouble(26, 0, ep)!;
    final bPad = lerpDouble(4, 0, ep)!;
    final bOpacity = (1.0 - ep).clamp(0.0, 1.0);

    final borderColor = Color.lerp(
      _pages[floorIdx].borderColor,
      _pages[ceilIdx].borderColor,
      t,
    )!.withValues(alpha: bOpacity);

    final pageData = _pages[_currentPage];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: Stack(
          children: [
            // ── Center card — expands on last page ──
            Positioned(
              left: cardLeft, top: cardTop,
              width: cardW, height: cardH,
              child: _isExpanded || ep > 0.01
                  // Expanded state — designed welcome screen, not a screenshot
                  ? _ExpandedWelcome(
                      expandProgress: ep,
                      ctaFade: ctaFade,
                      borderRadius: bRadius,
                      innerBorderRadius: iRadius,
                      borderPadding: bPad,
                      borderColor: borderColor,
                      borderOpacity: bOpacity,
                      onGetStarted: () => context.push('/pre-auth-quiz'),
                      onBack: _collapseAndGoBack,
                      onSignIn: () => context.push('/sign-in?returning=true'),
                      lastPageImage: _pages[_lastIndex].image,
                    )
                  // Normal carousel state — static frame with crossfading content
                  : Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(bRadius),
                        color: borderColor,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 12))],
                      ),
                      padding: EdgeInsets.all(bPad),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(iRadius),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              _pages[floorIdx].image,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                            if (floorIdx != ceilIdx)
                              Opacity(
                                opacity: t,
                                child: Image.asset(
                                  _pages[ceilIdx].image,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
            ),

            // Hidden PageView — always mounted so _pageController stays attached
            Positioned.fill(
              child: IgnorePointer(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Gesture layer (disabled during expansion)
            if (!_isExpanded)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (d) {
                    final pw = _pageController.position.viewportDimension;
                    final cw = screenW * 0.58;
                    _pageController.position.moveTo(
                      _pageController.position.pixels - d.delta.dx * (pw / cw) * 0.85,
                    );
                  },
                  onHorizontalDragEnd: (d) {
                    final v = d.primaryVelocity ?? 0;
                    int target;
                    if (v.abs() > 120) {
                      target = v < 0 ? _pageOffset.ceil() : _pageOffset.floor();
                    } else {
                      target = _pageOffset.round();
                    }
                    _pageController.animateToPage(
                      target.clamp(0, _pages.length - 1),
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                    );
                    _resetAutoRotate();
                  },
                ),
              ),

            // ── Header ──
            if (uiFade > 0)
              Positioned(
                top: 0, left: 0, right: 0,
                child: Opacity(
                  opacity: uiFade,
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
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.25))),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                ClipOval(child: Image.asset('assets/images/app_icon.png', width: 24, height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center, color: Colors.white, size: 20))),
                                const SizedBox(width: 8),
                                const Text('FitWiz', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ]),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/sign-in?returning=true'),
                            child: Container(
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.25))),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: const Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── Text above carousel ──
            if (uiFade > 0)
              Positioned(
                top: topPad + 56, left: 24, right: 24,
                child: Opacity(
                  opacity: uiFade,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Column(
                      key: ValueKey(_currentPage),
                      children: [
                        Text(pageData.headline, textAlign: TextAlign.center, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, shadows: [Shadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))])),
                        Text(pageData.headlineAccent, textAlign: TextAlign.center, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, shadows: [Shadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))])),
                        const SizedBox(height: 6),
                        Text(pageData.subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15, height: 1.4, shadows: [Shadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)])),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Dots below carousel ──
            if (uiFade > 0)
              Positioned(
                top: actualCarouselTop + normalCardH + 16,
                left: 0, right: 0,
                child: Opacity(
                  opacity: uiFade,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (i) {
                          final isActive = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 20 : 7, height: 7,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(3.5), color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.3)),
                          );
                        }),
                      ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DepthCards extends StatelessWidget {
  final List<_PageData> pages;
  final double pageOffset, cardWidth, cardHeight, fadeMultiplier;
  const _DepthCards({required this.pages, required this.pageOffset, required this.cardWidth, required this.cardHeight, required this.fadeMultiplier});

  @override
  Widget build(BuildContext context) {
    final entries = <_CardEntry>[];
    for (int i = 0; i < pages.length; i++) {
      final dist = pageOffset - i;
      final abs = dist.abs();
      if (abs < 0.5 || abs > 3) continue;
      entries.add(_CardEntry(
        index: i, zIndex: (100 - abs * 10).toInt(),
        scale: math.max(0.82, 1.0 - abs * 0.08),
        opacity: ((1.0 - abs * 0.35) * fadeMultiplier).clamp(0.0, 1.0),
        xOffset: -dist * cardWidth * 0.30,
        yOffset: abs * 8.0,
        blurAmount: (abs * 6.0).clamp(0.0, 14.0),
      ));
    }
    entries.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return Stack(
      clipBehavior: Clip.none, alignment: Alignment.center,
      children: entries.map((e) => Transform.translate(
        offset: Offset(e.xOffset, e.yOffset),
        child: Transform.scale(scale: e.scale, child: Opacity(opacity: e.opacity, child: RepaintBoundary(
          child: SizedBox(
            width: cardWidth, height: cardHeight,
            child: _PhoneCard(data: pages[e.index], blurAmount: e.blurAmount),
          ),
        ))),
      )).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PageData {
  final String headline, headlineAccent, subtitle, image;
  final Color bgColor, bgColorLight, borderColor;
  const _PageData({required this.headline, required this.headlineAccent, required this.subtitle, required this.image, required this.bgColor, required this.bgColorLight, required this.borderColor});
}

class _CardEntry {
  final int index, zIndex;
  final double scale, opacity, xOffset, yOffset, blurAmount;
  const _CardEntry({required this.index, required this.zIndex, required this.scale, required this.opacity, required this.xOffset, required this.yOffset, required this.blurAmount});
}

class _PhoneCard extends StatelessWidget {
  final _PageData data;
  final double blurAmount;
  const _PhoneCard({required this.data, this.blurAmount = 0});

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30), color: data.borderColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 12))],
      ),
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Image.asset(data.image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(
          width: 200, height: 400, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(26)),
          child: Icon(Icons.phone_android, color: Colors.white.withValues(alpha: 0.3), size: 48),
        )),
      ),
    );
    if (blurAmount > 0.5) {
      card = ClipRRect(borderRadius: BorderRadius.circular(30), child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount), child: card));
    }
    return Center(child: card);
  }
}

/// The expanded last-page view — designed welcome screen that fills the screen.
class _ExpandedWelcome extends StatelessWidget {
  final double expandProgress;
  final double ctaFade;
  final double borderRadius;
  final double innerBorderRadius;
  final double borderPadding;
  final Color borderColor;
  final double borderOpacity;
  final VoidCallback onGetStarted;
  final VoidCallback onBack;
  final VoidCallback onSignIn;
  final String lastPageImage;

  const _ExpandedWelcome({
    required this.expandProgress,
    required this.ctaFade,
    required this.borderRadius,
    required this.innerBorderRadius,
    required this.borderPadding,
    required this.borderColor,
    required this.borderOpacity,
    required this.onGetStarted,
    required this.onBack,
    required this.onSignIn,
    required this.lastPageImage,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: borderColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3 * borderOpacity), blurRadius: 30, offset: const Offset(0, 12))],
      ),
      padding: EdgeInsets.all(borderPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerBorderRadius),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
                Color(0xFF0F3460),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Subtle background pattern
              Positioned.fill(
                child: Opacity(
                  opacity: 0.06,
                  child: Image.asset(
                    lastPageImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // Content
              if (ctaFade > 0)
                Opacity(
                  opacity: ctaFade,
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Back button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: GestureDetector(
                              onTap: onBack,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                                    SizedBox(width: 6),
                                    Text('Back', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const Spacer(flex: 2),

                        // App icon + version
                        ClipOval(
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 80,
                            height: 80,
                            errorBuilder: (_, __, ___) => Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
                              child: const Icon(Icons.fitness_center, color: Colors.white, size: 40),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<PackageInfo>(
                          future: PackageInfo.fromPlatform(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox.shrink();
                            return Text(
                              'v${snapshot.data!.version}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Title
                        const Text(
                          'Ready to transform\nyour fitness?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        Text(
                          'Personalized workouts, smart nutrition tracking,\nand an AI coach — all in one app.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),

                        const Spacer(flex: 3),

                        // Get Started button — glassmorphic
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: GestureDetector(
                            onTap: onGetStarted,
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
                                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        const SizedBox(height: 12),

                        // Sign In link
                        GestureDetector(
                          onTap: onSignIn,
                          child: Text(
                            'Already have an account? Sign In',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                        SizedBox(height: 16 + bottomPad),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final String label, url;
  final bool isDark;
  const _SocialIcon({required this.icon, required this.label, required this.url, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final labelColor = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return GestureDetector(
      onTap: () { launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); Navigator.pop(context); },
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
          shape: BoxShape.circle, border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08)),
        ), child: Center(child: FaIcon(icon, color: iconColor, size: 22))),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: labelColor, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
