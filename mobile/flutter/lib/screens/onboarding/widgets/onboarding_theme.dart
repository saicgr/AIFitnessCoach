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

  /// Primary text (headings, labels).
  Color get textPrimary =>
      isDark ? Colors.white : const Color(0xFF1A1A2E);

  /// Secondary text (subtitles, descriptions).
  Color get textSecondary =>
      isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF52525B);

  /// Muted text (skip links, disabled labels).
  Color get textMuted =>
      isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF8E8E93);

  /// Disabled text.
  Color get textDisabled =>
      isDark ? Colors.white.withValues(alpha: 0.35) : const Color(0xFFAEAEB2);

  // ── Glass base color ──────────────────────────────────────────────
  // In dark mode glass is white-on-dark; in light mode it's black-on-light.

  Color get _glass => isDark ? Colors.white : Colors.black;

  // ── Card / chip backgrounds ───────────────────────────────────────

  /// Unselected card fill.
  Color get cardFill =>
      _glass.withValues(alpha: isDark ? 0.08 : 0.04);

  /// Selected card gradient (use as `LinearGradient(colors: [...])` ).
  List<Color> get cardSelectedGradient => [
        _glass.withValues(alpha: isDark ? 0.28 : 0.08),
        _glass.withValues(alpha: isDark ? 0.16 : 0.04),
      ];

  // ── Borders ───────────────────────────────────────────────────────

  Color get borderDefault =>
      _glass.withValues(alpha: isDark ? 0.15 : 0.08);

  Color get borderSelected =>
      _glass.withValues(alpha: isDark ? 0.5 : 0.2);

  Color get borderSubtle =>
      _glass.withValues(alpha: isDark ? 0.12 : 0.06);

  // ── Checkmarks & indicators ───────────────────────────────────────

  Color get checkBg =>
      _glass.withValues(alpha: isDark ? 0.3 : 0.1);

  Color get checkIcon => textPrimary;

  Color get checkBorderUnselected =>
      _glass.withValues(alpha: isDark ? 0.3 : 0.15);

  // ── Buttons ───────────────────────────────────────────────────────

  List<Color> get buttonGradient => [
        _glass.withValues(alpha: isDark ? 0.25 : 0.08),
        _glass.withValues(alpha: isDark ? 0.15 : 0.04),
      ];

  Color get buttonBorder =>
      _glass.withValues(alpha: isDark ? 0.4 : 0.15);

  Color get buttonText => textPrimary;

  // ── Icon containers ───────────────────────────────────────────────

  /// Background for the small icon square inside option cards.
  /// Pass the icon's accent color.
  List<Color> iconContainerGradient(Color accent) => [
        accent.withValues(alpha: 0.45),
        accent.withValues(alpha: 0.25),
      ];

  Color iconContainerBorder(Color accent) =>
      accent.withValues(alpha: 0.5);

  /// Selected state icon container (white glass).
  List<Color> get iconContainerSelectedGradient => [
        _glass.withValues(alpha: isDark ? 0.3 : 0.12),
        _glass.withValues(alpha: isDark ? 0.15 : 0.06),
      ];

  Color get iconContainerSelectedBorder =>
      _glass.withValues(alpha: isDark ? 0.4 : 0.15);
}
