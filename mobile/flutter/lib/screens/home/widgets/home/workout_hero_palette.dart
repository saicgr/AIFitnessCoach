/// The colour decisions for the Home "next workout" hero card, extracted from
/// the widget so they can be reasoned about — and tested — as one unit.
///
/// ── Why this is a separate file ─────────────────────────────────────────
/// The card is a photo-backed surface, and its legibility depends on a chain
/// of choices that must all agree: the card fill, the direction the photo is
/// pushed, the colour the scrim ramps into, and the text colours that end up
/// sitting on that scrim. When those were inline in the widget they drifted
/// apart twice:
///
///   * the fill was hard-coded dark (`0xFF0F0F11`) in BOTH themes while the
///     title read `ThemeColors.textPrimary` — near-black in light mode. Black
///     Anton masthead on a black photo: the title was invisible in light mode.
///   * the obvious patch (pin every foreground to white) fixed legibility but
///     left a black slab sitting in an otherwise white Home.
///
/// Both are the same defect: the surface and the foreground were decided
/// independently. Here they are decided together, from ONE `isDark`, and
/// `workout_hero_palette_test.dart` asserts the result actually contrasts in
/// both themes — so neither failure mode can come back silently.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/theme_colors.dart';

/// Every colour the workout hero card paints, derived from the active theme.
@immutable
class WorkoutHeroPalette {
  /// The card's own surface fill.
  final Color cardFill;

  /// The colour the photo scrim ramps INTO at the foot of the card — the same
  /// value the card fill tends toward, so text lands on a known background.
  final Color scrimBase;

  /// Tint applied to the exercise photo, pushing it toward [scrimBase] so it
  /// never reads as a foreign block against the fill.
  final Color imageTint;
  final BlendMode imageBlendMode;

  /// Bottom→top scrim ramp (top, middle, foot) over the photo.
  final List<Color> scrimColors;

  final Color titleColor;
  final Color subColor;
  final Color metaColor;

  /// Halo behind text sitting on the photo, in the surface's own colour.
  final List<Shadow> textShadows;

  final Color pillFill;
  final Color pillBorder;
  final Color pillText;

  /// "ACTIVE" badge label on the program row.
  final Color activeBadgeText;

  const WorkoutHeroPalette({
    required this.cardFill,
    required this.scrimBase,
    required this.imageTint,
    required this.imageBlendMode,
    required this.scrimColors,
    required this.titleColor,
    required this.subColor,
    required this.metaColor,
    required this.textShadows,
    required this.pillFill,
    required this.pillBorder,
    required this.pillText,
    required this.activeBadgeText,
  });

  /// [overImage] — an exercise illustration is behind the text.
  /// [isToday] — the date pill is the filled accent "TODAY" variant.
  factory WorkoutHeroPalette.of(
    ThemeColors c, {
    required bool overImage,
    required bool isToday,
  }) {
    final isDark = c.isDark;
    // Everything downstream ramps toward this. Decide it FIRST — the two past
    // bugs both came from picking foregrounds without reference to it.
    final scrimBase = isDark ? Colors.black : Colors.white;

    return WorkoutHeroPalette(
      // --d-surface2 on dark; the standard raised surface on light.
      cardFill: isDark ? const Color(0xFF0F0F11) : c.elevated,
      scrimBase: scrimBase,
      imageTint: scrimBase.withValues(alpha: isDark ? 0.45 : 0.34),
      imageBlendMode: isDark ? BlendMode.darken : BlendMode.lighten,
      scrimColors: [
        // Light mode needs a heavier ramp: white over a mid-tone photo hides
        // less than black does at the same alpha, and the text below is dark.
        scrimBase.withValues(alpha: isDark ? 0.10 : 0.22),
        scrimBase.withValues(alpha: isDark ? 0.48 : 0.66),
        scrimBase.withValues(alpha: isDark ? 0.90 : 0.95),
      ],
      titleColor: isDark ? Colors.white : c.textPrimary,
      subColor: isDark
          ? Colors.white.withValues(alpha: overImage ? 0.88 : 0.72)
          : c.textSecondary,
      metaColor: isDark
          ? Colors.white.withValues(alpha: overImage ? 0.80 : 0.60)
          : c.textMuted,
      textShadows: overImage
          ? [Shadow(color: scrimBase, blurRadius: 8, offset: const Offset(0, 1))]
          : const <Shadow>[],
      pillFill: isToday
          ? c.accent
          : (overImage
              ? scrimBase.withValues(alpha: isDark ? 0.42 : 0.62)
              : Colors.transparent),
      pillBorder: isToday
          ? c.accent
          : (isDark
              ? Colors.white.withValues(alpha: overImage ? 0.38 : 0.24)
              : c.cardBorder),
      pillText: isToday
          ? c.accentContrast
          : (isDark
              ? Colors.white.withValues(alpha: overImage ? 0.92 : 0.72)
              : c.textSecondary),
      // White only reads on the DARK-mode over-photo treatment; on the light
      // scrim it needs the accent.
      activeBadgeText: (isDark && overImage) ? Colors.white : c.accent,
    );
  }

  /// The effective background a foreground colour is judged against: the foot
  /// of the scrim composited over the card fill (or the bare fill with no
  /// photo). This is what the title/meta actually sit on.
  Color effectiveTextBackground({required bool overImage}) => overImage
      ? Color.alphaBlend(scrimColors.last, cardFill)
      : cardFill;

  /// Gradient stops for [scrimColors]. Fixed — the ramp shape is the same in
  /// both themes, only the colours change.
  static const List<double> scrimStops = [0.0, 0.45, 1.0];

  /// Stack scrim, ready to drop into a `Positioned.fill`.
  LinearGradient get scrimGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: scrimColors,
        stops: scrimStops,
      );
}
