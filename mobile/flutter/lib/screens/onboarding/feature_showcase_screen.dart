import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/glass_back_button.dart';
import 'widgets/social_proof_badge.dart';

/// Feature Showcase onboarding screen.
///
/// Presents 3 swipeable cards highlighting high-retention features
/// (Snap & Log, Barcode Scan, AI Coach) with polished animations.
/// Navigates to `/paywall-features` on completion.
class FeatureShowcaseScreen extends ConsumerStatefulWidget {
  const FeatureShowcaseScreen({super.key});

  @override
  ConsumerState<FeatureShowcaseScreen> createState() =>
      _FeatureShowcaseScreenState();
}

class _FeatureShowcaseScreenState extends ConsumerState<FeatureShowcaseScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_FeatureData> _features = [
    _FeatureData(
      icon: Icons.camera_alt_rounded,
      color: Color(0xFF00BCD4),
      title: 'Snap & Log',
      subtitle: 'Take a photo of your meal. Get instant nutrition breakdown.',
      badge: 'Most Popular',
    ),
    _FeatureData(
      icon: Icons.qr_code_scanner_rounded,
      color: Color(0xFF9B59B6),
      title: 'Barcode Scan',
      subtitle:
          'Scan any product. Get precise nutrition from verified databases.',
      badge: 'Zero Typing',
    ),
    _FeatureData(
      icon: Icons.smart_toy_rounded,
      color: Color(0xFF2ECC71),
      title: 'AI Coach',
      subtitle:
          'Ask anything about fitness & nutrition. Your personal expert, 24/7.',
      badge: 'Users Love This',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    HapticFeedback.mediumImpact();
    if (_currentPage < _features.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.go('/paywall-features');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.pureBlack, const Color(0xFF0A0A1A)]
                : [AppColorsLight.pureWhite, const Color(0xFFF5F5FA)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar with back button ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    GlassBackButton(
                      onTap: () => context.go('/health-connect-setup'),
                    ),
                    const Spacer(),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 8),

              // ── Page content ──
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    HapticFeedback.selectionClick();
                  },
                  itemCount: _features.length,
                  itemBuilder: (context, index) {
                    return _FeatureCard(
                      feature: _features[index],
                      isDark: isDark,
                    );
                  },
                ),
              ),

              // ── Dot indicators ──
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_features.length, (index) {
                    final isActive = index == _currentPage;
                    final color = _features[index].color;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? color
                            : (isDark
                                ? AppColors.textMuted.withValues(alpha: 0.4)
                                : AppColorsLight.textMuted
                                    .withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ).animate().fadeIn(delay: 400.ms),

              // ── Continue / Get Started button ──
              _buildContinueButton(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton(bool isDark) {
    final isLastPage = _currentPage == _features.length - 1;
    final buttonColor = _features[_currentPage].color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: GestureDetector(
        onTap: _onNext,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                buttonColor,
                buttonColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: buttonColor.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    isLastPage ? 'Get Started' : 'Next',
                    key: ValueKey(isLastPage),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  isLastPage
                      ? Icons.rocket_launch_rounded
                      : Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 22,
                )
                    .animate(
                      onPlay: (controller) =>
                          controller.repeat(reverse: true),
                    )
                    .moveX(begin: 0, end: 4, duration: 600.ms),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }
}

// ─── Feature Data ───────────────────────────────────────────────────────

class _FeatureData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String badge;

  const _FeatureData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.badge,
  });
}

// ─── Feature Card ───────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final _FeatureData feature;
  final bool isDark;

  const _FeatureCard({required this.feature, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Stack(
        children: [
          // ── Main card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            decoration: BoxDecoration(
              color: isDark ? AppColors.elevated : AppColorsLight.elevated,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: feature.color.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: feature.color.withValues(alpha: 0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Animated icon ──
                _AnimatedFeatureIcon(
                  icon: feature.icon,
                  color: feature.color,
                  isDark: isDark,
                ),

                const SizedBox(height: 40),

                // ── Title ──
                Text(
                  feature.title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 400.ms)
                    .slideY(begin: 0.1, curve: Curves.easeOutCubic),

                const SizedBox(height: 16),

                // ── Subtitle ──
                Text(
                  feature.subtitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 400.ms)
                    .slideY(begin: 0.1, curve: Curves.easeOutCubic),
              ],
            ),
          ),

          // ── Social proof badge (top-right corner) ──
          Positioned(
            top: 12,
            right: 12,
            child: SocialProofBadge(
              text: feature.badge,
              color: feature.color,
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 300.ms)
                .scale(
                  begin: const Offset(0.5, 0.5),
                  curve: Curves.elasticOut,
                  duration: 600.ms,
                  delay: 400.ms,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated Feature Icon ──────────────────────────────────────────────

class _AnimatedFeatureIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark;

  const _AnimatedFeatureIcon({
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: Center(
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.25),
                color.withValues(alpha: 0.1),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 44,
            color: color,
          ),
        ),
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.06, 1.06),
          duration: 1800.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .shimmer(
          duration: 2000.ms,
          color: color.withValues(alpha: 0.15),
        );
  }
}
