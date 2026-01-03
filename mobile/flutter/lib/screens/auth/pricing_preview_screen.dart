import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/services/analytics_service.dart';

/// Pre-Auth Pricing Preview Screen
/// Allows users to see subscription pricing BEFORE creating an account
/// Addresses user feedback: "Info in store didn't say how much so I had to download to get information."
class PricingPreviewScreen extends ConsumerStatefulWidget {
  const PricingPreviewScreen({super.key});

  @override
  ConsumerState<PricingPreviewScreen> createState() => _PricingPreviewScreenState();
}

class _PricingPreviewScreenState extends ConsumerState<PricingPreviewScreen>
    with TickerProviderStateMixin {
  String _selectedBillingCycle = 'yearly';
  late AnimationController _rainbowController;
  DateTime? _screenEnteredAt;

  @override
  void initState() {
    super.initState();
    _screenEnteredAt = DateTime.now();
    _rainbowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Track analytics event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackPricingPreviewViewed();
    });
  }

  @override
  void dispose() {
    _rainbowController.dispose();
    _trackPricingPreviewExit();
    super.dispose();
  }

  Future<void> _trackPricingPreviewViewed() async {
    try {
      final analytics = ref.read(analyticsServiceProvider);
      await analytics.trackEvent(
        eventName: 'pricing_preview_viewed',
        category: 'conversion',
        properties: {
          'source': 'pre_auth',
          'entry_point': 'stats_welcome',
        },
        screenName: 'pricing_preview',
      );
    } catch (e) {
      debugPrint('Failed to track pricing preview viewed: $e');
    }
  }

  Future<void> _trackPricingPreviewExit() async {
    if (_screenEnteredAt == null) return;
    try {
      final analytics = ref.read(analyticsServiceProvider);
      final durationMs = DateTime.now().difference(_screenEnteredAt!).inMilliseconds;
      await analytics.trackEvent(
        eventName: 'pricing_preview_exit',
        category: 'conversion',
        properties: {
          'duration_ms': durationMs,
          'selected_billing_cycle': _selectedBillingCycle,
        },
        screenName: 'pricing_preview',
      );
    } catch (e) {
      debugPrint('Failed to track pricing preview exit: $e');
    }
  }

  Future<void> _trackSignUpIntent(String source) async {
    try {
      final analytics = ref.read(analyticsServiceProvider);
      await analytics.trackEvent(
        eventName: 'pricing_preview_signup_intent',
        category: 'conversion',
        properties: {
          'source': source,
          'selected_billing_cycle': _selectedBillingCycle,
          'time_on_screen_ms': _screenEnteredAt != null
              ? DateTime.now().difference(_screenEnteredAt!).inMilliseconds
              : 0,
        },
        screenName: 'pricing_preview',
      );
    } catch (e) {
      debugPrint('Failed to track signup intent: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            _buildHeader(colors),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Title and subtitle
                    _buildTitleSection(colors).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 24),

                    // Billing cycle tabs
                    _buildBillingCycleTabs(colors)
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 400.ms),

                    const SizedBox(height: 20),

                    // Pricing cards
                    _buildPricingCards(colors, isDark),

                    const SizedBox(height: 24),

                    // Free tier highlight
                    _buildFreeTierCard(colors)
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 400.ms),

                    const SizedBox(height: 24),

                    // App Store note
                    _buildAppStoreNote(colors)
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 400.ms),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom CTAs
            _buildBottomCTAs(colors, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: colors.textSecondary,
              size: 20,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.cyan.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility, size: 14, color: colors.cyan),
                const SizedBox(width: 6),
                Text(
                  'Preview',
                  style: TextStyle(
                    color: colors.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildTitleSection(ThemeColors colors) {
    return Column(
      children: [
        Text(
          'Simple, Transparent Pricing',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'No surprises. See exactly what you pay before signing up.',
          style: TextStyle(
            fontSize: 14,
            color: colors.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBillingCycleTabs(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _BillingTab(
            label: 'Yearly',
            sublabel: '7-day trial',
            isSelected: _selectedBillingCycle == 'yearly',
            onTap: () => setState(() => _selectedBillingCycle = 'yearly'),
            colors: colors,
          ),
          _BillingTab(
            label: 'Monthly',
            sublabel: 'Flexible',
            isSelected: _selectedBillingCycle == 'monthly',
            onTap: () => setState(() => _selectedBillingCycle = 'monthly'),
            colors: colors,
          ),
          _BillingTab(
            label: 'Lifetime',
            sublabel: 'One-time',
            isSelected: _selectedBillingCycle == 'lifetime',
            onTap: () => setState(() => _selectedBillingCycle = 'lifetime'),
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCards(ThemeColors colors, bool isDark) {
    if (_selectedBillingCycle == 'lifetime') {
      return _buildLifetimeCard(colors).animate().fadeIn(duration: 300.ms);
    }

    final isYearly = _selectedBillingCycle == 'yearly';

    return Column(
      children: [
        // Premium Plus plan with rainbow border for yearly
        if (isYearly)
          _RainbowBorderCard(
            controller: _rainbowController,
            child: _PricingTierCard(
              tierName: 'Premium Plus',
              badge: 'BEST VALUE',
              badgeColor: const Color(0xFF00D9FF),
              accentColor: const Color(0xFF00D9FF),
              price: '\$6.67',
              period: '/mo',
              billedAs: '\$79.99/year',
              features: const [
                'Unlimited workouts',
                'Unlimited food scans',
                'Full nutrition tracking',
                'Advanced analytics',
                '7-day free trial',
              ],
              colors: colors,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms)
        else
          _PricingTierCard(
            tierName: 'Premium Plus',
            badge: 'MOST POPULAR',
            badgeColor: const Color(0xFFAA66FF),
            accentColor: const Color(0xFFAA66FF),
            price: '\$9.99',
            period: '/mo',
            billedAs: 'Billed monthly',
            features: const [
              'Unlimited workouts',
              'Unlimited food scans',
              'Full nutrition tracking',
              'Advanced analytics',
            ],
            colors: colors,
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

        const SizedBox(height: 12),

        // Premium plan
        _PricingTierCard(
          tierName: 'Premium',
          badge: isYearly ? 'SAVE 33%' : '',
          badgeColor: const Color(0xFF00CC66),
          accentColor: const Color(0xFF00CC66),
          price: isYearly ? '\$4.00' : '\$5.99',
          period: '/mo',
          billedAs: isYearly ? '\$47.99/year' : 'Billed monthly',
          features: const [
            'Daily workouts',
            '5 food scans/day',
            'Full macro tracking',
          ],
          colors: colors,
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildLifetimeCard(ThemeColors colors) {
    const accentColor = Color(0xFFFFB800);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(0.15),
            accentColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Lifetime',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ONE-TIME',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '\$99.99',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pay once, use forever',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          _buildFeatureRow('Everything in Premium Plus', accentColor, colors),
          _buildFeatureRow('Lifetime updates & features', accentColor, colors),
          _buildFeatureRow('Early access to new features', accentColor, colors),
          _buildFeatureRow('No recurring charges ever', accentColor, colors),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text, Color accentColor, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: accentColor),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(fontSize: 14, color: colors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeTierCard(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free Plan Available',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Try FitWiz with limited features - no credit card required',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '\$0',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppStoreNote(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cyan.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cyan.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: colors.cyan,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'These prices are also visible in the App Store. Cancel anytime from your device settings.',
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCTAs(ThemeColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: colors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary CTA - Get Started
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _trackSignUpIntent('primary_cta');
                context.go('/pre-auth-quiz');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.cyan,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: colors.cyan.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(27),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

          const SizedBox(height: 10),

          // Secondary CTA - Start Free
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _trackSignUpIntent('start_free');
              context.go('/pre-auth-quiz');
            },
            child: Text(
              'Start with Free Plan',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

/// Billing cycle tab selector
class _BillingTab extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeColors colors;

  const _BillingTab({
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colors.cyan : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? Colors.white.withOpacity(0.8)
                      : colors.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pricing tier card
class _PricingTierCard extends StatelessWidget {
  final String tierName;
  final String badge;
  final Color badgeColor;
  final Color accentColor;
  final String price;
  final String period;
  final String billedAs;
  final List<String> features;
  final ThemeColors colors;

  const _PricingTierCard({
    required this.tierName,
    required this.badge,
    required this.badgeColor,
    required this.accentColor,
    required this.price,
    required this.period,
    required this.billedAs,
    required this.features,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Title + Badge + Price
          Row(
            children: [
              Text(
                tierName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              if (badge.isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  Text(
                    period,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          Text(
            billedAs,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          // Features
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: features
                .map((feature) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 14, color: accentColor),
                        const SizedBox(width: 4),
                        Text(
                          feature,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Rainbow animated border for premium plan
class _RainbowBorderCard extends StatelessWidget {
  final Widget child;
  final AnimationController controller;

  const _RainbowBorderCard({
    required this.child,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _getGlowColor(controller.value).withOpacity(0.3),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _RainbowBorderPainter(progress: controller.value),
            child: child,
          ),
        );
      },
    );
  }

  Color _getGlowColor(double progress) {
    final colors = [
      const Color(0xFF00D9FF),
      const Color(0xFF00FF88),
      const Color(0xFFFFB800),
      const Color(0xFFFF6B6B),
      const Color(0xFFAA66FF),
      const Color(0xFF00D9FF),
    ];

    final index = (progress * (colors.length - 1)).floor();
    final t = (progress * (colors.length - 1)) - index;

    return Color.lerp(colors[index], colors[(index + 1) % colors.length], t)!;
  }
}

class _RainbowBorderPainter extends CustomPainter {
  final double progress;

  _RainbowBorderPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );

    final gradient = SweepGradient(
      startAngle: progress * 2 * math.pi,
      endAngle: progress * 2 * math.pi + 2 * math.pi,
      colors: const [
        Color(0xFF00D9FF),
        Color(0xFF00FF88),
        Color(0xFFFFB800),
        Color(0xFFFF6B6B),
        Color(0xFFAA66FF),
        Color(0xFF00D9FF),
      ],
      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(_RainbowBorderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
