import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'onboarding_theme.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Glassmorphic continue button for quiz screens.
class QuizContinueButton extends StatefulWidget {
  final bool canProceed;
  final bool isLastQuestion;
  final VoidCallback onPressed;
  final VoidCallback? onSkip;
  final String? skipText;
  final String? hintText;

  const QuizContinueButton({
    super.key,
    required this.canProceed,
    required this.isLastQuestion,
    required this.onPressed,
    this.onSkip,
    this.skipText,
    this.hintText,
  });

  @override
  State<QuizContinueButton> createState() => _QuizContinueButtonState();
}

class _QuizContinueButtonState extends State<QuizContinueButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  /// Tapping the disabled CTA used to produce no response of any kind — no
  /// shake, no toast, nothing — leaving the user with no signal about what
  /// the app wants. A haptic buzz + a horizontal shake of the button gives
  /// an unmissable "that tap registered, but you're not done yet" cue; the
  /// reason line above (`hintText`) already states what's missing.
  void _handleDisabledTap() {
    HapticFeedback.vibrate();
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Reason line for the disabled CTA — fixed-height slot (scaled with
          // the text scaler) so the button never shifts under the user's
          // thumb when the hint appears or clears. Mirrors the body-metrics
          // gate's reason line so every gated quiz step explains itself.
          SizedBox(
            height: MediaQuery.textScalerOf(context).scale(12) * 1.3 + 3,
            child: (!widget.canProceed && widget.hintText != null)
                ? Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 13,
                        color: t.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.hintText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: t.textMuted,
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (widget.onSkip != null)
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: widget.onSkip,
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      child: Text(
                        widget.skipText ?? AppLocalizations.of(context).onboardingSkip,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: t.textMuted),
                      ),
                    ),
                  ),
                ),
              if (widget.onSkip != null) const SizedBox(width: 12),
              Expanded(
                flex: widget.onSkip != null ? 5 : 1,
                child: AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    // Decaying sinusoidal shake: a few quick side-to-side
                    // wobbles that settle back to rest.
                    final v = _shakeController.value;
                    final dx = math.sin(v * math.pi * 6) * 8 * (1 - v);
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: child,
                    );
                  },
                  child: GestureDetector(
                    onTap: widget.canProceed ? widget.onPressed : _handleDisabledTap,
                    // v7: solid brand-orange CTA (System A) — the glass blur is
                    // gone, so no BackdropFilter cost on every quiz step.
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: widget.canProceed
                            ? LinearGradient(
                                colors: t.buttonGradient,
                                begin: AlignmentDirectional.topStart,
                                end: AlignmentDirectional.bottomEnd,
                              )
                            : null,
                        color: widget.canProceed ? null : t.cardFill,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: widget.canProceed
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
                            widget.isLastQuestion ? AppLocalizations.of(context).quizContinueButtonSeeMyPlan : AppLocalizations.of(context).onboardingContinueButton,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: widget.canProceed ? t.buttonText : t.textDisabled,
                            ),
                          ),
                          if (widget.canProceed) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20, color: t.buttonText),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }
}
