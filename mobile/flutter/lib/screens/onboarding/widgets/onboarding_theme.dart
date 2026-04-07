import 'dart:ui';
import 'package:flutter/material.dart';

/// Centralized color definitions for the glassmorphic onboarding flow.
///
/// All onboarding quiz widgets, sign-in screens, and gate screens should
/// use `OnboardingTheme.of(context)` to get the correct colors for the
/// current brightness. This ensures a single place to tweak the palette.
class OnboardingTheme {
  final bool isDark;

  const OnboardingTheme._({required this.isDark});

  /// Resolve the onboarding palette from the current [BuildContext].
  factory OnboardingTheme.of(BuildContext context) {
    return OnboardingTheme._(
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
  }

  // ── Background gradients ──────────────────────────────────────────

  LinearGradient get backgroundGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F9FC), Color(0xFFF0F2F8), Color(0xFFE8ECF4)],
        );

  // ── Text colors ───────────────────────────────────────────────────

  Color get textPrimary =>
      isDark ? Colors.white : const Color(0xFF1A1A2E);

  Color get textSecondary =>
      isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF52525B);

  Color get textMuted =>
      isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF8E8E93);

  Color get textDisabled =>
      isDark ? Colors.white.withValues(alpha: 0.35) : const Color(0xFFAEAEB2);

  // ── Glass base color ──────────────────────────────────────────────

  Color get _glass => isDark ? Colors.white : Colors.black;

  // ── Card / chip backgrounds ───────────────────────────────────────

  Color get cardFill => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.white.withValues(alpha: 0.55);

  List<Color> get cardSelectedGradient => isDark
      ? [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.12)]
      : [Colors.white.withValues(alpha: 0.80), Colors.white.withValues(alpha: 0.60)];

  // ── Borders ───────────────────────────────────────────────────────

  Color get borderDefault => isDark
      ? Colors.white.withValues(alpha: 0.18)
      : Colors.white.withValues(alpha: 0.70);

  Color get borderSelected => isDark
      ? Colors.white.withValues(alpha: 0.50)
      : Colors.white.withValues(alpha: 0.90);

  Color get borderSubtle => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.white.withValues(alpha: 0.50);

  // ── Checkmarks & indicators ───────────────────────────────────────

  Color get checkBg => isDark
      ? Colors.white.withValues(alpha: 0.3)
      : Colors.black.withValues(alpha: 0.08);

  Color get checkIcon => textPrimary;

  Color get checkBorderUnselected => isDark
      ? Colors.white.withValues(alpha: 0.3)
      : Colors.black.withValues(alpha: 0.15);

  // ── Accent (for active CTA buttons) ────────────────────────────────

  /// Accent color for active/enabled call-to-action buttons.
  Color get accent => const Color(0xFFFF8C00); // FitWiz orange

  // ── Buttons ───────────────────────────────────────────────────────

  List<Color> get buttonGradient => isDark
      ? [Colors.white.withValues(alpha: 0.20), Colors.white.withValues(alpha: 0.10)]
      : [Colors.white.withValues(alpha: 0.75), Colors.white.withValues(alpha: 0.55)];

  Color get buttonBorder => isDark
      ? Colors.white.withValues(alpha: 0.35)
      : Colors.white.withValues(alpha: 0.80);

  Color get buttonText => textPrimary;

  // ── Icon containers ───────────────────────────────────────────────

  List<Color> iconContainerGradient(Color accent) => [
        accent.withValues(alpha: 0.45),
        accent.withValues(alpha: 0.25),
      ];

  Color iconContainerBorder(Color accent) =>
      accent.withValues(alpha: 0.5);

  List<Color> get iconContainerSelectedGradient => isDark
      ? [Colors.white.withValues(alpha: 0.3), Colors.white.withValues(alpha: 0.15)]
      : [Colors.white.withValues(alpha: 0.6), Colors.white.withValues(alpha: 0.4)];

  Color get iconContainerSelectedBorder => isDark
      ? Colors.white.withValues(alpha: 0.4)
      : Colors.white.withValues(alpha: 0.8);
}

// ─────────────────────────────────────────────────────────────────────────────

/// Background widget with decorative gradient orbs that give the frosted
/// glass cards something to blur over. Wrap your Scaffold body in this.
class OnboardingBackground extends StatelessWidget {
  final Widget child;

  const OnboardingBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Container(
      decoration: BoxDecoration(gradient: t.backgroundGradient),
      child: Stack(
        children: [
          // ── Decorative gradient orbs ──
          // These give the BackdropFilter blur visible frosted glass effect.
          Positioned(
            top: -80,
            right: -60,
            child: _GlowOrb(
              size: 260,
              color: t.isDark
                  ? const Color(0xFF6366F1).withValues(alpha: 0.20)
                  : const Color(0xFF6366F1).withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: -100,
            child: _GlowOrb(
              size: 300,
              color: t.isDark
                  ? const Color(0xFF0EA5E9).withValues(alpha: 0.15)
                  : const Color(0xFF0EA5E9).withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: _GlowOrb(
              size: 220,
              color: t.isDark
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.18)
                  : const Color(0xFFA855F7).withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.25,
            left: 40,
            child: _GlowOrb(
              size: 160,
              color: t.isDark
                  ? const Color(0xFF14B8A6).withValues(alpha: 0.12)
                  : const Color(0xFF14B8A6).withValues(alpha: 0.08),
            ),
          ),
          // ── Content ──
          child,
        ],
      ),
    );
  }
}

/// Soft, blurred circular gradient orb for background decoration.
class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
