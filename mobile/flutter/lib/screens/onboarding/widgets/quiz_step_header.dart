import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'onboarding_theme.dart';

/// The ONE title/subtitle block every pre-auth quiz step renders.
///
/// Before this existed each step hand-rolled its own header and they drifted:
/// titles at 20 / 22 / 24 / 28 pt, subtitles at 12 / 13 / 14 / 15, gaps of
/// 4 / 6 / 10 / 16, and body padding at 20 on some steps and 24 on others. The
/// result is that consecutive steps of the same quiz start at different heights
/// and different left edges — the "goals screen is top-aligned, fitness-level
/// screen has dead space above the question" report.
///
/// Steps must use [QuizStepHeader] for the header and [kQuizStepHPad] for
/// their horizontal padding so the whole funnel keeps one rhythm.
class QuizStepHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const QuizStepHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: t.textPrimary,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
        if (subtitle != null) ...[
          const SizedBox(height: kQuizStepTitleGap),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 13.5,
              color: t.textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
        const SizedBox(height: kQuizStepHeaderGap),
      ],
    );
  }
}

/// Horizontal body padding shared by every quiz step.
const double kQuizStepHPad = 24;

/// Gap between the step title and its subtitle.
const double kQuizStepTitleGap = 6;

/// Gap between the header block and the step's first option.
const double kQuizStepHeaderGap = 16;
