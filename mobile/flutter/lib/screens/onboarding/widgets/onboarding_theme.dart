import 'package:flutter/material.dart';

import '../../../core/theme/accent_color_provider.dart';

/// Centralized color definitions for the onboarding flow ("System A",
/// first-run redesign 2026-06: black canvas + brand-accent selection).
///
/// All onboarding quiz widgets, sign-in screens, and gate screens should
/// use `OnboardingTheme.of(context)` to get the correct colors for the
/// current brightness. This ensures a single place to tweak the palette.
///
/// v7 redesign notes (mockups: docs/planning/first-run-redesign-2026-06):
/// - The blue glassmorphic gradient + animated orbs are gone; the funnel
///   now matches the app's own black + accent identity end to end.
/// - `selectionAccent` follows `context.accentColor` (was a hardcoded
///   #F97316, before that iOS green) — selected cards, checks and badges
///   read as brand, and now stay in sync with the user's chosen accent
///   instead of forcing orange regardless of setting (E2E register row 15:
///   "colour has stopped carrying meaning"). `warningAccent` stays red:
///   injury/limitation selection must NOT read as a positive confirmation.
class OnboardingTheme {
  final bool isDark;
  final Color _accent;
  final Color _accentDeep;

  const OnboardingTheme._({
    required this.isDark,
    required Color accent,
    required Color accentDeep,
  })  : _accent = accent,
        _accentDeep = accentDeep;

  /// Resolve the onboarding palette from the current [BuildContext].
  factory OnboardingTheme.of(BuildContext context) {
    final accent = context.accentColor;
    return OnboardingTheme._(
      isDark: Theme.of(context).brightness == Brightness.dark,
      accent: accent,
      // Darker gradient stop derived from the single accent read, same
      // technique as chat_media_widgets.dart's accent gradients.
      accentDeep: Color.lerp(accent, Colors.black, 0.15)!,
    );
  }

  // ── Background gradients ──────────────────────────────────────────

  LinearGradient get backgroundGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF120A04), Color(0xFF050505), Color(0xFF050505)],
          stops: [0.0, 0.35, 1.0],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF4EA), Color(0xFFFFFFFF), Color(0xFFFAFAFA)],
          stops: [0.0, 0.35, 1.0],
        );

  // ── Text colors ───────────────────────────────────────────────────

  Color get textPrimary =>
      isDark ? const Color(0xFFFAFAFA) : const Color(0xFF18181B);

  Color get textSecondary =>
      isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B);

  Color get textMuted =>
      isDark ? const Color(0xFF8A8A92) : const Color(0xFF8E8E93);

  Color get textDisabled =>
      isDark ? const Color(0xFF5F5F66) : const Color(0xFFAEAEB2);

  // ── Accent colors ─────────────────────────────────────────────────  // accent-allowlist: warning/caution - injury & limitation selections, explicitly documented as distinct from selectionAccent (must not read as a positive confirmation)

  /// App accent for CTA buttons (Continue, Generate).
  Color get accent => _accent;

  /// App accent for selection confirmation (checkmarks, counters,
  /// badges). v7: was green #34C759 — selection now reads as brand.
  Color get selectionAccent => _accent;

  /// Red accent for caution / warning selections (injuries, limitations).
  /// Semantically distinct from `selectionAccent` — "you have an injury here"
  /// reads as a warning, not a positive confirmation.
  Color get warningAccent => const Color(0xFFFF3B30);  // accent-allowlist: warning/caution - injury & limitation selections, explicitly documented as distinct from selectionAccent (must not read as a positive confirmation)

  /// Badge background for "Recommended" / "BEST" labels.
  Color get badgeBg => selectionAccent.withValues(alpha: 0.15);

  /// Badge text color.
  Color get badgeText => selectionAccent;

  // ── Card / chip backgrounds ───────────────────────────────────────

  Color get cardFill =>
      isDark ? const Color(0xFF141416) : Colors.white;

  /// Selected card gradient — orange-tinted for clear visual feedback.
  List<Color> get cardSelectedGradient => isDark
      ? [selectionAccent.withValues(alpha: 0.16), selectionAccent.withValues(alpha: 0.05)]
      : [selectionAccent.withValues(alpha: 0.12), selectionAccent.withValues(alpha: 0.04)];

  /// Selected card gradient for caution/warning state — red-tinted. Used
  /// by injury/limitation chips where "selected" means "this is a problem
  /// area" rather than "good choice."
  List<Color> get cardWarningSelectedGradient => isDark
      ? [warningAccent.withValues(alpha: 0.22), warningAccent.withValues(alpha: 0.10)]
      : [warningAccent.withValues(alpha: 0.14), warningAccent.withValues(alpha: 0.06)];

  // ── Borders ───────────────────────────────────────────────────────

  Color get borderDefault =>
      isDark ? const Color(0xFF26262A) : const Color(0xFFE4E4E7);

  /// Selected border — orange-tinted.
  Color get borderSelected => isDark
      ? selectionAccent.withValues(alpha: 0.55)
      : selectionAccent.withValues(alpha: 0.45);

  /// Selected border for caution/warning state — red-tinted.
  Color get borderWarningSelected => isDark
      ? warningAccent.withValues(alpha: 0.60)
      : warningAccent.withValues(alpha: 0.45);

  Color get borderSubtle =>
      isDark ? const Color(0xFF1D1D20) : const Color(0xFFEFEFF1);

  // ── Checkmarks & indicators ───────────────────────────────────────

  /// Solid orange background for checkmark circles.
  Color get checkBg => selectionAccent;

  /// White check icon on orange background.
  Color get checkIcon => Colors.white;

  /// Unselected checkmark circle border.
  Color get checkBorderUnselected => isDark
      ? Colors.white.withValues(alpha: 0.3)
      : Colors.black.withValues(alpha: 0.15);

  // ── Buttons ───────────────────────────────────────────────────────

  /// v7: primary buttons are SOLID brand accent (no more white glass).
  List<Color> get buttonGradient => [_accent, _accentDeep];

  Color get buttonBorder => _accent.withValues(alpha: 0.0);

  /// Ink on accent — matches the approved System A mockups' contrast ratio,
  /// computed per-accent (luminance threshold matches feature_detail_sheet.dart)
  /// since a fixed near-black no longer reads correctly on every accent choice.
  Color get buttonText =>
      _accent.computeLuminance() > 0.55 ? const Color(0xFF160B03) : Colors.white;

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

/// Background for the onboarding funnel. v7: a STATIC near-black canvas
/// with one warm ember glow at the top — the animated blue/purple orbs
/// (and their per-frame blur cost) are gone. Kept as the same widget
/// name/API so all ~30 consumers restyle without edits.
class OnboardingBackground extends StatelessWidget {
  final Widget child;

  const OnboardingBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Container(
      decoration: BoxDecoration(gradient: t.backgroundGradient),
      child: Stack(
        // MUST be expand, not the default `loose`.
        //
        // Under loose constraints a shrink-wrapping child — a
        // `SingleChildScrollView`, a `Column` with `mainAxisSize.min` — sizes
        // itself to its content, the Stack sizes to that child, and this
        // Container sizes to the Stack. The gradient then covers only as much
        // as the content, and every screen using this background sits on a
        // `Colors.transparent` Scaffold, so the remainder renders BLACK.
        //
        // That is what the email sign-in screen showed on device: content to
        // ~68% of the viewport, hard black below. The sign-in screen escaped
        // it only because its content happens to fill the height.
        //
        // Expanding here fixes the whole class at the one place that owns the
        // background, rather than requiring every screen to remember to fill.
        fit: StackFit.expand,
        children: [
          // Single static warm glow anchoring the top of the canvas.
          Positioned(
            top: -140,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 360,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.9,
                    colors: [
                      t.accent.withValues(alpha: t.isDark ? 0.10 : 0.07),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
