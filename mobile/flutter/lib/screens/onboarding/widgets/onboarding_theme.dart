import 'dart:math' as math;
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

  // ── Accent colors ─────────────────────────────────────────────────

  /// Orange accent for CTA buttons (Continue, Generate).
  Color get accent => const Color(0xFFFF8C00);

  /// Green accent for selection confirmation (checkmarks, counters, badges).
  Color get selectionAccent => const Color(0xFF34C759);

  /// Red accent for caution / warning selections (injuries, limitations).
  /// Semantically distinct from `selectionAccent` — "you have an injury here"
  /// reads as a warning, not a positive confirmation.
  Color get warningAccent => const Color(0xFFFF3B30);

  /// Badge background for "Recommended" / "BEST" labels.
  Color get badgeBg => selectionAccent.withValues(alpha: 0.15);

  /// Badge text color.
  Color get badgeText => selectionAccent;

  // ── Card / chip backgrounds ───────────────────────────────────────

  Color get cardFill => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.white.withValues(alpha: 0.55);

  /// Selected card gradient — green-tinted for clear visual feedback.
  List<Color> get cardSelectedGradient => isDark
      ? [selectionAccent.withValues(alpha: 0.18), selectionAccent.withValues(alpha: 0.08)]
      : [selectionAccent.withValues(alpha: 0.10), selectionAccent.withValues(alpha: 0.05)];

  /// Selected card gradient for caution/warning state — red-tinted. Used
  /// by injury/limitation chips where "selected" means "this is a problem
  /// area" rather than "good choice."
  List<Color> get cardWarningSelectedGradient => isDark
      ? [warningAccent.withValues(alpha: 0.22), warningAccent.withValues(alpha: 0.10)]
      : [warningAccent.withValues(alpha: 0.14), warningAccent.withValues(alpha: 0.06)];

  // ── Borders ───────────────────────────────────────────────────────

  Color get borderDefault => isDark
      ? Colors.white.withValues(alpha: 0.18)
      : Colors.white.withValues(alpha: 0.70);

  /// Selected border — green-tinted.
  Color get borderSelected => isDark
      ? selectionAccent.withValues(alpha: 0.50)
      : selectionAccent.withValues(alpha: 0.35);

  /// Selected border for caution/warning state — red-tinted.
  Color get borderWarningSelected => isDark
      ? warningAccent.withValues(alpha: 0.60)
      : warningAccent.withValues(alpha: 0.45);

  Color get borderSubtle => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.white.withValues(alpha: 0.50);

  // ── Checkmarks & indicators ───────────────────────────────────────

  /// Solid green background for checkmark circles.
  Color get checkBg => selectionAccent;

  /// White check icon on green background.
  Color get checkIcon => Colors.white;

  /// Unselected checkmark circle border.
  Color get checkBorderUnselected => isDark
      ? Colors.white.withValues(alpha: 0.3)
      : Colors.black.withValues(alpha: 0.15);

  // ── Buttons ───────────────────────────────────────────────────────

  List<Color> get buttonGradient => isDark
      ? [Colors.white.withValues(alpha: 0.20), Colors.white.withValues(alpha: 0.10)]
      : [Colors.white.withValues(alpha: 0.75), Colors.white.withValues(alpha: 0.55)];

  Color get buttonBorder => isDark
      ? Colors.white.withValues(alpha: 0.35)
      : Colors.white.withValues(alpha: 0.80);

  Color get buttonText => textPrimary;

  // ── Icon containers ───────────────────────────────────────────────

  /// Unselected icon container — uses the icon's accent color.
  List<Color> iconContainerGradient(Color iconColor) => [
        iconColor.withValues(alpha: 0.45),
        iconColor.withValues(alpha: 0.25),
      ];

  Color iconContainerBorder(Color iconColor) =>
      iconColor.withValues(alpha: 0.5);

  /// Selected icon container — KEEPS the accent color but brighter.
  List<Color> iconContainerSelectedGradient(Color iconColor) => [
        iconColor.withValues(alpha: 0.55),
        iconColor.withValues(alpha: 0.35),
      ];

  Color iconContainerSelectedBorder(Color iconColor) =>
      iconColor.withValues(alpha: 0.65);
}

// ─────────────────────────────────────────────────────────────────────────────

/// Background widget with animated decorative gradient orbs that give the
/// frosted glass cards something to blur over.
class OnboardingBackground extends StatefulWidget {
  final Widget child;

  const OnboardingBackground({super.key, required this.child});

  @override
  State<OnboardingBackground> createState() => _OnboardingBackgroundState();
}

class _OnboardingBackgroundState extends State<OnboardingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      decoration: BoxDecoration(gradient: t.backgroundGradient),
      child: Stack(
        children: [
          // Animated orbs layer — isolated for performance
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final v = _controller.value * 2 * math.pi;
                return Stack(
                  children: [
                    Positioned(
                      top: -80 + math.sin(v) * 45,
                      right: -60 + math.cos(v * 0.7) * 40,
                      child: _GlowOrb(
                        size: 260,
                        color: t.isDark
                            ? const Color(0xFF6366F1).withValues(alpha: 0.20)
                            : const Color(0xFF6366F1).withValues(alpha: 0.12),
                      ),
                    ),
                    Positioned(
                      top: screenH * 0.35 + math.cos(v * 0.8) * 55,
                      left: -100 + math.sin(v * 0.6) * 50,
                      child: _GlowOrb(
                        size: 300,
                        color: t.isDark
                            ? const Color(0xFF0EA5E9).withValues(alpha: 0.15)
                            : const Color(0xFF0EA5E9).withValues(alpha: 0.10),
                      ),
                    ),
                    Positioned(
                      bottom: -60 + math.sin(v * 0.9) * 50,
                      right: -40 + math.cos(v * 0.5) * 45,
                      child: _GlowOrb(
                        size: 220,
                        color: t.isDark
                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.18)
                            : const Color(0xFFA855F7).withValues(alpha: 0.08),
                      ),
                    ),
                    Positioned(
                      bottom: screenH * 0.25 + math.cos(v * 1.1) * 45,
                      left: 40 + math.sin(v * 0.4) * 40,
                      child: _GlowOrb(
                        size: 160,
                        color: t.isDark
                            ? const Color(0xFF14B8A6).withValues(alpha: 0.12)
                            : const Color(0xFF14B8A6).withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Content
          widget.child,
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
