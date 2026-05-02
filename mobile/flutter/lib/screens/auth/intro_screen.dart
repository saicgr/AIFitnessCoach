import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_colors.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// Intro Screen — Onboarding v5
///
/// Single outcome-focused screen replacing the previous 7-slide feature
/// carousel ("Log any Meal in any way", "Track Every REP", etc). The
/// carousel violated the video's core principle — "don't list features,
/// sell the outcome." Cal AI ($2M/mo, $2.50/dl) opens with a single hook
/// framed as transformation, not a sequence of feature ads.
///
/// Two CTAs:
///   - Primary: "Build My Plan" → /pre-auth-quiz (new user funnel)
///   - Secondary: "I have an account" → /sign-in?returning=true
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = info.version);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    HapticFeedback.mediumImpact();
    context.push('/pre-auth-quiz');
  }

  void _onSignIn() {
    HapticFeedback.lightImpact();
    context.push('/sign-in?returning=true');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.4),
            radius: 1.2,
            colors: isDark
                ? [
                    AppColors.orange.withValues(alpha: 0.15),
                    AppColors.pureBlack,
                  ]
                : [
                    AppColors.orange.withValues(alpha: 0.08),
                    AppColorsLight.pureWhite,
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // ── Top bar: brand (logo + name + version) + sign-in
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Real app icon, not a generic gradient placeholder.
                        ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Branding.appName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                letterSpacing: -0.3,
                                height: 1.0,
                              ),
                            ),
                            if (_appVersion.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'v$_appVersion',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      textSecondary.withValues(alpha: 0.7),
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _onSignIn,
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 2),

                // ── Hero — actual app logo with pulsing halo
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) {
                    return Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.orange.withValues(
                              alpha: 0.35 + (_pulseController.value * 0.25),
                            ),
                            blurRadius: 50 + (_pulseController.value * 20),
                            spreadRadius: 6,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(34),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 132,
                          height: 132,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ).animate().scale(
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                    ),

                const SizedBox(height: 36),

                // ── Outcome-focused headline
                Text(
                  'Your body.',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    letterSpacing: -1.5,
                    height: 1.0,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),

                const SizedBox(height: 4),

                Text(
                  'Your timeline.',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: AppColors.orange,
                    letterSpacing: -1.5,
                    height: 1.0,
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15),

                const SizedBox(height: 18),

                Text(
                  "An AI coach that builds the plan, learns your body, and adjusts every week.",
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 600.ms),

                const Spacer(flex: 3),

                // ── Capability strip — verifiable signals, not features
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.glassSurface.withValues(alpha: 0.5)
                        : AppColorsLight.glassSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.cardBorder
                          : AppColorsLight.cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const _StatPill(
                        value: '1,700+',
                        label: 'Exercises',
                        color: Color(0xFF00BCD4),
                      ),
                      _Divider(),
                      const _StatPill(
                        value: '1M+',
                        label: 'Foods',
                        color: Color(0xFF2ECC71),
                      ),
                      _Divider(),
                      const _StatPill(
                        value: '24/7',
                        label: 'AI Coach',
                        color: AppColors.orange,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // ── Primary CTA
                GestureDetector(
                  onTap: _onGetStarted,
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFB366), // orangeLight
                          AppColors.orange,  // brand orange — clean warm gradient
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Build My Plan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.1),

                const SizedBox(height: 14),

                GestureDetector(
                  onTap: _onSignIn,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'I already have an account',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 1200.ms),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatPill({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 28,
      color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
    );
  }
}
