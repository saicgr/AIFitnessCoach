import 'dart:ui';
import 'package:flutter/material.dart';

/// Glassmorphic tooltip card shown during app tours
class AppTourTooltipCard extends StatelessWidget {
  final String title;
  final String description;
  final int currentStep; // 1-based display
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback? onPrev;
  final VoidCallback onSkip;
  final bool isDark;
  final Color accentColor;

  const AppTourTooltipCard({
    super.key,
    required this.title,
    required this.description,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
    required this.isDark,
    required this.accentColor,
    this.onPrev,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48).clamp(0.0, 360.0);
    final isLastStep = currentStep == totalSteps;

    // Translucent enough to keep the glass feel, opaque enough to stay
    // readable when something dark sits behind the card (modal scrim,
    // dark hero imagery, etc.). Light mode previously used 0.62 white
    // which composited to muddy gray + unreadable black text whenever a
    // bottom-sheet barrier or busy background was underneath.
    final bgColor = isDark
        ? const Color(0xFF1C1C1E).withValues(alpha: 0.86)
        : Colors.white.withValues(alpha: 0.94);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.08);
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark
        ? Colors.white.withValues(alpha: 0.70)
        : Colors.black.withValues(alpha: 0.60);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          width: cardWidth,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1),
            // Top-to-bottom highlight gradient gives the glass a subtle
            // sheen edge so it doesn't look like a flat translucent slab.
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: isDark ? 0.06 : 0.18),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: _CardContent(
              key: ValueKey('$currentStep/$totalSteps'),
              title: title,
              description: description,
              currentStep: currentStep,
              totalSteps: totalSteps,
              isLastStep: isLastStep,
              onNext: onNext,
              onPrev: onPrev,
              onSkip: onSkip,
              accentColor: accentColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  final String title;
  final String description;
  final int currentStep;
  final int totalSteps;
  final bool isLastStep;
  final VoidCallback onNext;
  final VoidCallback? onPrev;
  final VoidCallback onSkip;
  final Color accentColor;
  final Color textPrimary;
  final Color textSecondary;

  const _CardContent({
    super.key,
    required this.title,
    required this.description,
    required this.currentStep,
    required this.totalSteps,
    required this.isLastStep,
    required this.onNext,
    required this.onPrev,
    required this.onSkip,
    required this.accentColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: step counter + skip
          Row(
            children: [
              Text(
                '$currentStep / $totalSteps',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onSkip,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: textSecondary.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Skip tutorial',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            title,
            style: TextStyle(
              color: textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          // Description
          Text(
            description,
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Step dots
          Row(
            children: [
              ...List.generate(totalSteps, (i) {
                final isActive = i + 1 == currentStep;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 5),
                  width: isActive ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? accentColor
                        : accentColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
              const Spacer(),
              // Prev button (if not first step)
              if (onPrev != null) ...[
                GestureDetector(
                  onTap: onPrev,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: accentColor,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Next/Finish button
              GestureDetector(
                onTap: onNext,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      isLastStep ? 'Got it!' : 'Next',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
