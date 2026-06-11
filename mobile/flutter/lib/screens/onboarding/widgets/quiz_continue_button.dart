import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'onboarding_theme.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Glassmorphic continue button for quiz screens.
class QuizContinueButton extends StatelessWidget {
  final bool canProceed;
  final bool isLastQuestion;
  final VoidCallback onPressed;
  final VoidCallback? onSkip;
  final String? skipText;

  const QuizContinueButton({
    super.key,
    required this.canProceed,
    required this.isLastQuestion,
    required this.onPressed,
    this.onSkip,
    this.skipText,
  });

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (onSkip != null)
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: onSkip,
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  child: Text(
                    skipText ?? AppLocalizations.of(context).onboardingSkip,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: t.textMuted),
                  ),
                ),
              ),
            ),
          if (onSkip != null) const SizedBox(width: 12),
          Expanded(
            flex: onSkip != null ? 5 : 1,
            child: GestureDetector(
              onTap: canProceed ? onPressed : null,
              // v7: solid brand-orange CTA (System A) — the glass blur is
              // gone, so no BackdropFilter cost on every quiz step.
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 56,
                decoration: BoxDecoration(
                  gradient: canProceed
                      ? LinearGradient(
                          colors: t.buttonGradient,
                          begin: AlignmentDirectional.topStart,
                          end: AlignmentDirectional.bottomEnd,
                        )
                      : null,
                  color: canProceed ? null : t.cardFill,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: canProceed
                      ? [
                          BoxShadow(
                            color: t.accent.withValues(alpha: 0.3),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastQuestion ? AppLocalizations.of(context).quizContinueButtonSeeMyPlan : AppLocalizations.of(context).onboardingContinueButton,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: canProceed ? t.buttonText : t.textDisabled,
                      ),
                    ),
                    if (canProceed) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20, color: t.buttonText),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }
}
