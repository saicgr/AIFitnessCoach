import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../widgets/glass_back_button.dart';
import 'onboarding_theme.dart';

/// Floating header for quiz screens: back button + time-remaining label.
///
/// v7 redesign: the "Step X of 6" counter pill is replaced by a
/// time-remaining estimate ("~2 min left") — completion anxiety research
/// favors time over step counts, and the segmented progress bar below
/// already communicates position.
class QuizHeader extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback? onBackToWelcome;

  const QuizHeader({
    super.key,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.canGoBack,
    required this.onBack,
    this.onBackToWelcome,
  });

  /// Rough per-question pace (~15s) → whole minutes, floored at 1 so the
  /// label never promises "0 min" while questions remain.
  int get _minutesLeft {
    final remaining = math.max(1, totalQuestions - currentQuestion);
    return math.max(1, (remaining * 15 / 60).ceil());
  }

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (canGoBack || onBackToWelcome != null)
            GlassBackButton(
              onTap: () {
                HapticFeedback.lightImpact();
                (canGoBack ? onBack : onBackToWelcome!)();
              },
            )
          else
            const SizedBox(width: 44),

          Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: Text(
              l10n.quizMinutesLeft(_minutesLeft),
              style: TextStyle(
                color: t.accent,
                fontFamily: 'Barlow Condensed',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
