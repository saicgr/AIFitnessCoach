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

import '../../l10n/generated/app_localizations.dart';

/// Capability + Community Screen — Onboarding v5 → signature-v2 repurpose.
///
/// REPLACES the old `feature_showcase` screen which the video flagged as the
/// worst placement (a feature list right before the paywall).
///
/// 2026-06 repurpose: the four big stat cards now DUPLICATE the new paywall
/// feature marquee + price anchor (1,722 exercises w/ video, latest AI, …) a
/// few screens later — same pitch twice. So the stats collapse to ONE slim
/// proof strip and the screen leads with the thing the paywall can't carry:
/// **real humans behind it** (Discord + Instagram + a team that answers before
/// you ever pay). That's authentic — fake testimonials are not.
///
/// Exercise-media wording: every exercise ships a still illustration + a real
/// vertical MP4 demo (`VERTICAL VIDEOS ALL/…`), so "HD video demos" is the
/// honest premium term. NOT "3D model" — we have video, not interactive 3D.
class CapabilityAndCommunityScreen extends ConsumerWidget {
  const CapabilityAndCommunityScreen({super.key});

  // ── Signature v2
  static const Color _accent = Color(0xFFF97316);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0B) : AppColorsLight.pureWhite;
    final surface = isDark ? const Color(0xFF141416) : AppColorsLight.elevated;
    final border = isDark ? const Color(0xFF26262B) : AppColorsLight.cardBorder;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    final textMuted = isDark
        ? AppColors.textSecondary.withValues(alpha: 0.7)
        : AppColorsLight.textSecondary.withValues(alpha: 0.8);

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 36),

              // ── Anton display headline
              Text(
                l10n.capabilityAndCommunityBuiltRight.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Anton',
                  fontSize: 38,
                  height: 1.0,
                  letterSpacing: 0.5,
                  color: textPrimary,
                ),
              ).animate().fadeIn().slideY(begin: -0.1),
              const SizedBox(height: 8),
              Text(
                l10n.capabilityAndCommunityRealNumbersRealPeople.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Barlow Condensed',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 2.4,
                  color: textMuted,
                ),
              ).animate().fadeIn(delay: 180.ms),

              const SizedBox(height: 26),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // ── Slim proof strip — three stats at a glance, NOT a
                    // four-card feature list that re-pitches the paywall.
                    Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border(
                          top: BorderSide(color: _accent, width: 1),
                          left: BorderSide(color: border),
                          right: BorderSide(color: border),
                          bottom: BorderSide(color: border),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          _ProofStat(
                            number: '1,700+',
                            label: 'exercises',
                            sub: 'HD video demos',
                            accent: _accent,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),
                          _Divider(border),
                          _ProofStat(
                            number: '1M+',
                            label: 'foods',
                            sub: 'menus · brands · recipes',
                            accent: _accent,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),
                          _Divider(border),
                          _ProofStat(
                            number: 'Latest',
                            label: 'AI model',
                            sub: 'always the newest',
                            accent: _accent,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),
                        ],
                      ),
                    ).animate(delay: 320.ms).fadeIn().slideY(begin: 0.06),

                    const SizedBox(height: 18),

                    // ── HERO: the thing the paywall can't carry — real humans.
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border(
                          top: BorderSide(color: _accent, width: 1),
                          left: BorderSide(color: border),
                          right: BorderSide(color: border),
                          bottom: BorderSide(color: border),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.capabilityAndCommunityReachUsAnytime
                                .toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Barlow Condensed',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 2,
                              color: _accent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'TALK TO A REAL HUMAN',
                            style: TextStyle(
                              fontFamily: 'Anton',
                              fontSize: 24,
                              height: 1.05,
                              letterSpacing: 0.3,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Not a faceless app. A small team builds Zealova '
                            'and answers in our Discord & DMs — before you ever '
                            'pay a cent.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _SocialChip(
                                  icon: FontAwesomeIcons.discord,
                                  label: l10n.founderNoteDiscord,
                                  color: const Color(0xFF5865F2),
                                  onTap: () => _open(AppLinks.discord),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _SocialChip(
                                  icon: FontAwesomeIcons.instagram,
                                  label: l10n.wrappedShareInstagram,
                                  color: const Color(0xFFE1306C),
                                  onTap: () => _open(AppLinks.instagram),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate(delay: 520.ms).fadeIn().slideY(begin: 0.06),
                  ],
                ),
              ),

              // ── CTA — signature-v2 solid orange, Barlow Condensed
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref
                      .read(posthogServiceProvider)
                      .capture(
                        eventName: 'onboarding_capability_community_completed',
                      );
                  context.go('/onboarding-confidence');
                },
                child: Container(
                  width: double.infinity,
                  height: 56,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      l10n.onboardingContinueButton.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Barlow Condensed',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: Color(0xFF160B03),
                      ),
                    ),
                  ),
                ),
              ).animate(delay: 700.ms).fadeIn().slideY(begin: 0.1),
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

/// One stat in the slim proof strip — big number, label, sub-line.
class _ProofStat extends StatelessWidget {
  final String number;
  final String label;
  final String sub;
  final Color accent;
  final Color textPrimary;
  final Color textMuted;

  const _ProofStat({
    required this.number,
    required this.label,
    required this.sub,
    required this.accent,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Anton',
              fontSize: 22,
              height: 1.0,
              letterSpacing: 0.3,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(fontSize: 10, height: 1.25, color: textMuted),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider(this.color);

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: color);
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
          border: Border.all(color: color.withValues(alpha: 0.28)),
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
