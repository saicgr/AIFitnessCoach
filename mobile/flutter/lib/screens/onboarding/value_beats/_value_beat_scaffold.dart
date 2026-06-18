import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/onboarding_theme.dart';

/// Shared building blocks for the onboarding "value beat" interstitials.
///
/// Value beats are short, non-input reward/value screens shown BETWEEN quiz
/// questions to sustain momentum (Gravl-gap parity). They live in this folder
/// and each returns just a Column/Padding body — the host quiz scaffold
/// supplies its own [OnboardingBackground] + [Scaffold], so these widgets must
/// NOT add their own.
///
/// This file is private plumbing (filename prefixed `_`); the five public beat
/// widgets compose these helpers so spacing, the checkmark bullet, and the
/// brand-orange continue CTA stay identical across every beat.

/// A single checkmark bullet row: orange filled check + title (+ optional
/// secondary line). Matches the onboarding card idiom (white check on orange).
class ValueBeatCheckBullet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;

  const ValueBeatCheckBullet({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.check_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: t.checkBg,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: t.accent.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: t.checkIcon),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: t.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The brand-orange "Continue" CTA used to close out every value beat. Mirrors
/// [QuizContinueButton] visually (solid orange gradient, dark ink, glow) so the
/// beats feel native to the funnel without depending on the quiz's l10n strings.
class ValueBeatContinueButton extends StatelessWidget {
  final VoidCallback onContinue;
  final String label;

  const ValueBeatContinueButton({
    super.key,
    required this.onContinue,
    this.label = 'Continue',
  });

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onContinue();
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: t.buttonGradient,
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: t.accent.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: t.buttonText,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 20, color: t.buttonText),
          ],
        ),
      ),
    );
  }
}

/// Standard headline + optional supporting line for a value beat. Keeps the
/// 32pt bold / 16pt secondary rhythm used across the quiz screens.
class ValueBeatHeadline extends StatelessWidget {
  final String headline;
  final String? supporting;

  const ValueBeatHeadline({
    super.key,
    required this.headline,
    this.supporting,
  });

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headline,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: t.textPrimary,
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.08),
        if (supporting != null) ...[
          const SizedBox(height: 12),
          Text(
            supporting!,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: t.textSecondary,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.05),
        ],
      ],
    );
  }
}
