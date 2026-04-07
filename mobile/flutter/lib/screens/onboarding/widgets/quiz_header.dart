import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../widgets/glass_back_button.dart';

/// Floating header for quiz screens with glassmorphic back button and question counter.
/// Always uses white/glass styling for gradient backgrounds.
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

  String _getProgressText() {
    if (currentQuestion <= 5) {
      return 'Step ${currentQuestion + 1} of 6';
    } else if (currentQuestion >= 6 && currentQuestion <= 9) {
      return 'Personalize your plan';
    } else if (currentQuestion >= 10) {
      return 'Nutrition setup';
    }
    return 'Step ${currentQuestion + 1} of $totalQuestions';
  }

  @override
  Widget build(BuildContext context) {
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

          // Glassmorphic counter pill — always white-on-glass
          ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  _getProgressText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
