import 'dart:ui';
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
/// Glassmorphic tooltip card shown during app tours.
///
/// The card is height-bounded by [maxHeight]: the title + description scroll
/// internally when content would exceed the cap, while the header (step
/// counter + Skip) and the footer (progress dots + Next/Got it) stay pinned
/// and always visible. This guarantees a consistent control footer on every
/// step and every tab — fixing the "no Next button on Home/Nutrition" issue.
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

  /// Hard ceiling for the card height. The description region scrolls if the
  /// content would exceed it so the footer is never clipped off-screen.
  final double maxHeight;

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
    required this.maxHeight,
    this.onPrev,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48).clamp(0.0, 360.0);
    final isLastStep = currentStep == totalSteps;

    // Fully opaque: the card sits over a dark tour scrim, so any
    // translucency muddies the fill and tanks text contrast. The glass
    // feel comes from the BackdropFilter blur at the edges + the shadow,
    // not from a see-through body.
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.08);
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : Colors.black.withValues(alpha: 0.62);
    // The Skip control needs to stay clearly legible — a faint secondary grey
    // rendered "barely visible" over the home header. Use a solid filled
    // capsule with a high-contrast surface so it reads in both light + dark.
    final skipBg = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.06);
    final skipBorder = isDark
        ? Colors.white.withValues(alpha: 0.30)
        : Colors.black.withValues(alpha: 0.18);
    final skipText = isDark
        ? Colors.white.withValues(alpha: 0.95)
        : Colors.black.withValues(alpha: 0.80);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          width: cardWidth,
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            // Subtle top sheen — both stops opaque (a translucent stop
            // would let the scrim bleed through and break readability,
            // and a `gradient` silently overrides any `color:` set here).
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(
                  Colors.white.withValues(alpha: isDark ? 0.05 : 0.0),
                  bgColor,
                ),
                bgColor,
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.48 : 0.20),
                blurRadius: 30,
                offset: const Offset(0, 10),
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
              skipBg: skipBg,
              skipBorder: skipBorder,
              skipText: skipText,
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
  final Color skipBg;
  final Color skipBorder;
  final Color skipText;

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
    required this.skipBg,
    required this.skipBorder,
    required this.skipText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: step counter + skip — pinned, never scrolls.
          Row(
            children: [
              Text(
                '$currentStep / $totalSteps',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onSkip,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                  decoration: BoxDecoration(
                    color: skipBg,
                    border: Border.all(color: skipBorder, width: 1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    AppLocalizations.of(context).appTourTooltipSkipTutorial,
                    style: TextStyle(
                      color: skipText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Title + description — scrolls internally if content is tall so
          // the footer below always stays visible within [maxHeight].
          Flexible(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 17.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    description,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Footer: step dots + Prev/Next — pinned, always rendered on every
          // step regardless of how tall the description is.
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
                        : accentColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
              const Spacer(),
              // Prev button (if not first step)
              if (onPrev != null) ...[
                GestureDetector(
                  onTap: onPrev,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: accentColor,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
              ],
              // Next/Finish button — always rendered on every step so the
              // tour control footer is consistent across all tabs.
              GestureDetector(
                onTap: onNext,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLastStep ? AppLocalizations.of(context).xpGoalsGotIt : AppLocalizations.of(context).commonNext,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (!isLastStep) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ],
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
