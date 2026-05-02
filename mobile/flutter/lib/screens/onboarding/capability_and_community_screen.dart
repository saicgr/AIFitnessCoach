import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_links.dart';
import '../../core/services/posthog_service.dart';

/// Capability + Community Screen — Onboarding v5
///
/// REPLACES the old `feature_showcase` screen which the video specifically
/// flagged as the worst possible placement (feature listing right before
/// the paywall). Instead this screen shows:
///   1. Real verifiable numbers (1,700+ exercises, 1M+ foods, latest AI)
///   2. Discord + Instagram + email — direct access to founder/team
///
/// As the app grows, the structure flexes: stats inflate to user counts,
/// social proof testimonials fill in. Today it leads with capability
/// because that's authentic — fake testimonials are not.
class CapabilityAndCommunityScreen extends ConsumerWidget {
  const CapabilityAndCommunityScreen({super.key});

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
              const SizedBox(height: 28),
              Text(
                'Built right.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn().slideY(begin: -0.1),
              const SizedBox(height: 6),
              Text(
                "Real numbers. Real people behind it.",
                style: TextStyle(fontSize: 15, color: textSecondary),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 28),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _CapabilityRow(
                      delay: 350,
                      isDark: isDark,
                      icon: Icons.movie_rounded,
                      iconColor: const Color(0xFF00BCD4),
                      number: '1,700+',
                      title: 'Exercises with HD video',
                      detail:
                          "Every exercise has form cues + a full demonstration.",
                    ),
                    const SizedBox(height: 12),
                    _CapabilityRow(
                      delay: 500,
                      isDark: isDark,
                      icon: Icons.restaurant_menu_rounded,
                      iconColor: const Color(0xFF2ECC71),
                      number: '1M+',
                      title: 'Foods in our database',
                      detail:
                          "Restaurant menus, packaged goods, custom recipes.",
                    ),
                    const SizedBox(height: 12),
                    _CapabilityRow(
                      delay: 650,
                      isDark: isDark,
                      icon: Icons.bolt_rounded,
                      iconColor: AppColors.onboardingAccent,
                      number: 'Latest',
                      title: 'AI, updated continuously',
                      detail:
                          "Not last year's model. Always on the newest available.",
                    ),
                    const SizedBox(height: 12),
                    _CapabilityRow(
                      delay: 800,
                      isDark: isDark,
                      icon: Icons.support_agent_rounded,
                      iconColor: const Color(0xFF9B59B6),
                      number: '24/7',
                      title: 'AI coach availability',
                      detail:
                          "Plus a real human team behind it — message us anytime.",
                    ),

                    const SizedBox(height: 22),

                    // ── Community row
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.elevated : AppColorsLight.elevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.cardBorder
                              : AppColorsLight.cardBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reach us anytime',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _SocialChip(
                                  icon: FontAwesomeIcons.discord,
                                  label: 'Discord',
                                  color: const Color(0xFF5865F2),
                                  onTap: () => _open(AppLinks.discord),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _SocialChip(
                                  icon: FontAwesomeIcons.instagram,
                                  label: 'Instagram',
                                  color: const Color(0xFFE1306C),
                                  onTap: () => _open(AppLinks.instagram),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate(delay: 1000.ms).fadeIn().slideY(begin: 0.05),
                  ],
                ),
              ),

              // CTA
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref.read(posthogServiceProvider).capture(
                        eventName: 'onboarding_capability_community_completed',
                      );
                  context.go('/paywall-pricing');
                },
                child: Container(
                  width: double.infinity,
                  height: 56,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.onboardingAccent, Color(0xFFFF6B00)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.onboardingAccent.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ).animate(delay: 1200.ms).fadeIn().slideY(begin: 0.1),
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

class _CapabilityRow extends StatelessWidget {
  final int delay;
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String number;
  final String title;
  final String detail;

  const _CapabilityRow({
    required this.delay,
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.number,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      number,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: delay.ms).fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}

class _SocialChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
