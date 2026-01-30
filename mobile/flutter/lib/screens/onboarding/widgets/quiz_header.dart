import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

/// Floating header for quiz screens with glassmorphic back button and question counter.
/// Positioned absolutely over content with blur effect for modern look.
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

  /// Calculate phase-aware progress text based on current question
  String _getProgressText() {
    // Phase 1: Show normal step count (Screens 0-5)
    if (currentQuestion <= 5) {
      return 'Step ${currentQuestion + 1} of 6';  // Always show "of 6" for Phase 1
    }
    // Phase 2: Optional personalization (Screens 6-9)
    else if (currentQuestion >= 6 && currentQuestion <= 9) {
      return 'Personalize your plan';  // User-selected: Action-oriented, positive
    }
    // Phase 3: Nutrition (Screens 10-11)
    else if (currentQuestion >= 10) {
      return 'Nutrition setup';  // Simple, descriptive
    }
    // Fallback (shouldn't happen)
    return 'Step ${currentQuestion + 1} of $totalQuestions';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Floating back button
          if (canGoBack || onBackToWelcome != null)
            _FloatingButton(
              isDark: isDark,
              onPressed: canGoBack ? onBack : onBackToWelcome!,
              child: Icon(
                Icons.arrow_back_ios_rounded,
                size: 18,
                color: isDark ? Colors.white : const Color(0xFF0A0A0A),
              ),
            )
          else
            const SizedBox(width: 44),

          // Floating question counter with phase-aware text
          _FloatingCounter(
            isDark: isDark,
            text: _getProgressText(),  // ← UPDATED to use phase-aware text
          ),
        ],
      ),
    );
  }
}

/// Glassmorphic floating button with blur effect
class _FloatingButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onPressed;
  final Widget child;

  const _FloatingButton({
    required this.isDark,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glassmorphic floating counter pill
class _FloatingCounter extends StatelessWidget {
  final bool isDark;
  final String text;

  const _FloatingCounter({
    required this.isDark,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0A0A0A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
