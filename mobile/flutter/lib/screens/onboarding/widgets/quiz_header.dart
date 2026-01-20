import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Header for quiz screens with back button and question counter.
class QuizHeader extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final bool canGoBack;
  final VoidCallback onBack;
  /// Optional callback for first question to go back to welcome screen
  final VoidCallback? onBackToWelcome;

  const QuizHeader({
    super.key,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.canGoBack,
    required this.onBack,
    this.onBackToWelcome,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? const Color(0xFFB0B0B0)
        : const Color(0xFF6B6B6B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (canGoBack)
            IconButton(
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: textSecondary,
                size: 20,
              ),
            )
          else if (onBackToWelcome != null)
            IconButton(
              onPressed: onBackToWelcome,
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: textSecondary,
                size: 20,
              ),
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          Text(
            '${currentQuestion + 1} of $totalQuestions',
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          // Placeholder for symmetry
          const SizedBox(width: 48),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
