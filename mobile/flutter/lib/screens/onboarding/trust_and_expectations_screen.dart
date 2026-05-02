import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_links.dart';
import '../../core/services/posthog_service.dart';

/// Trust & Expectations — Onboarding v5.1
///
/// Replaces TWO standalone screens (honest-expectations + privacy-trust)
/// with one screen that has 2 short sections. Shown between the quiz exit
/// and plan-analyzing.
///
/// Section 1: "A bit of honesty" — Cal AI pattern that builds trust by
/// being upfront that week 1 will feel slow but momentum builds in week 2-3.
/// Reduces refund requests and trial cancellations.
///
/// Section 2: "Your data stays yours" — privacy promises right before
/// personal data is collected (or rather: re-confirmed since body metrics
/// are now collected in the quiz).
class TrustAndExpectationsScreen extends ConsumerWidget {
  const TrustAndExpectationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'Before we build your plan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(),

              const SizedBox(height: 4),

              Text(
                'Two things you should know.',
                style: TextStyle(fontSize: 14, color: textSecondary),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 22),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // ── Section 1: A bit of honesty
                    _SectionHeader(
                      icon: Icons.handshake_outlined,
                      iconColor: AppColors.orange,
                      title: 'A bit of honesty',
                      isDark: isDark,
                    ).animate().fadeIn(delay: 250.ms),
                    const SizedBox(height: 8),
                    _Bullet(
                      delay: 350,
                      isDark: isDark,
                      tone: BulletTone.warm,
                      title: 'Week 1 will feel slow.',
                      detail:
                          "Most early weight change is water and glycogen — "
                          "real fat loss takes time to compound.",
                    ),
                    const SizedBox(height: 8),
                    _Bullet(
                      delay: 450,
                      isDark: isDark,
                      tone: BulletTone.warm,
                      title: 'Real change shows up in week 3.',
                      detail:
                          "By day 14-21 your body has adapted. That's when "
                          "most users see visible progress.",
                    ),
                    const SizedBox(height: 8),
                    _Bullet(
                      delay: 550,
                      isDark: isDark,
                      tone: BulletTone.warm,
                      title: "We won't sugarcoat it.",
                      detail:
                          "Your coach will adjust the plan when something "
                          "isn't working — no fluff, just direction.",
                    ),

                    const SizedBox(height: 24),

                    // ── Section 2: Your data stays yours
                    _SectionHeader(
                      icon: Icons.shield_outlined,
                      iconColor: const Color(0xFF2ECC71),
                      title: 'Your data stays yours',
                      isDark: isDark,
                    ).animate().fadeIn(delay: 700.ms),
                    const SizedBox(height: 8),
                    _Bullet(
                      delay: 800,
                      isDark: isDark,
                      tone: BulletTone.cool,
                      title: 'We never sell your data.',
                      detail:
                          'Weight, workouts, meals — none of it is sold or '
                          'shared with advertisers.',
                    ),
                    const SizedBox(height: 8),
                    _Bullet(
                      delay: 900,
                      isDark: isDark,
                      tone: BulletTone.cool,
                      title: 'Encrypted in transit and at rest.',
                      detail: 'TLS 1.3 + AES-256. Same standards as your bank.',
                    ),
                    const SizedBox(height: 8),
                    _Bullet(
                      delay: 1000,
                      isDark: isDark,
                      tone: BulletTone.cool,
                      title: 'Delete anything, anytime.',
                      detail:
                          'One tap in Settings exports or wipes everything. '
                          'GDPR + CCPA compliant.',
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => _open(AppLinks.privacyPolicy),
                      child: Center(
                        child: Text(
                          'Read our full privacy policy',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 1100.ms),
                  ],
                ),
              ),

              // ── CTA
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref.read(posthogServiceProvider).capture(
                        eventName: 'onboarding_trust_expectations_completed',
                      );
                  context.go('/plan-analyzing');
                },
                child: Container(
                  width: double.infinity,
                  height: 56,
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Sounds good',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.orange,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.auto_awesome_rounded,
                            color: AppColors.orange, size: 18),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

enum BulletTone { warm, cool }

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool isDark;
  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final int delay;
  final bool isDark;
  final BulletTone tone;
  final String title;
  final String detail;
  const _Bullet({
    required this.delay,
    required this.isDark,
    required this.tone,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accent =
        tone == BulletTone.warm ? AppColors.orange : const Color(0xFF2ECC71);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: delay.ms).fadeIn(duration: 350.ms).slideX(begin: 0.04);
  }
}
