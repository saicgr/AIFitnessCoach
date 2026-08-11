/// The Home workout-hero card is a photo-backed surface, and it has shipped
/// TWO opposite legibility bugs, both from the same root cause — the surface
/// and the foreground were decided independently:
///
///   1. the fill was hard-coded dark (`0xFF0F0F11`) in BOTH themes while the
///      title read `ThemeColors.textPrimary`, which is near-black in light
///      mode → black masthead on a black photo, invisible in light mode;
///   2. the patch for (1) pinned every foreground to white, which fixed
///      legibility but left a black slab sitting in an otherwise white Home.
///
/// `WorkoutHeroPalette` now derives fill, photo tint, scrim and every
/// foreground from ONE `isDark`. These tests assert the property that both
/// bugs violated: **the text must actually contrast against the surface it
/// lands on, in both themes** — and, separately, that the card belongs to the
/// theme it is rendered in rather than being a fixed dark brick.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/theme/theme_colors.dart';
import 'package:fitwiz/screens/home/widgets/home/workout_hero_palette.dart';

/// WCAG relative luminance.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// WCAG contrast ratio between an opaque foreground and background.
double _contrast(Color fg, Color bg) {
  // Foregrounds carry alpha (e.g. white at 0.60) — composite first, otherwise
  // we'd score a colour the user never actually sees.
  final flat = Color.alphaBlend(fg, bg);
  final a = _luminance(flat), b = _luminance(bg);
  final hi = math.max(a, b), lo = math.min(a, b);
  return (hi + 0.05) / (lo + 0.05);
}

/// `ThemeColors`'s constructor is private — it is always built from a
/// BuildContext — so the palette is captured out of a one-frame pump at the
/// requested brightness. The assertions themselves stay pure.
Future<WorkoutHeroPalette> _palette(
  WidgetTester tester, {
  required bool isDark,
  required bool overImage,
  required bool isToday,
}) async {
  late WorkoutHeroPalette captured;
  // A bare `Theme` rather than `MaterialApp`: MaterialApp resolves brightness
  // through themeMode/platformBrightness, which made a second pump in the same
  // test silently keep the first theme.
  await tester.pumpWidget(
    Theme(
      data: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Builder(
        key: ValueKey('palette-$isDark-$overImage-$isToday'),
        builder: (context) {
          captured = WorkoutHeroPalette.of(
            ThemeColors.of(context),
            overImage: overImage,
            isToday: isToday,
          );
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  group('WorkoutHeroPalette contrasts in both themes', () {
    for (final isDark in [true, false]) {
      final mode = isDark ? 'dark' : 'light';

      for (final overImage in [true, false]) {
        final backing = overImage ? 'over a photo' : 'on the flat fill';

        testWidgets('$mode, $backing: title clears 4.5:1', (tester) async {
          final p = await _palette(tester,
              isDark: isDark, overImage: overImage, isToday: true);
          final bg = p.effectiveTextBackground(overImage: overImage);
          expect(_contrast(p.titleColor, bg), greaterThanOrEqualTo(4.5),
              reason: 'the Anton masthead is the primary content — bug (1) '
                  'scored ~1.0 here');
        });

        testWidgets('$mode, $backing: subtitle and meta clear 3:1',
            (tester) async {
          final p = await _palette(tester,
              isDark: isDark, overImage: overImage, isToday: true);
          final bg = p.effectiveTextBackground(overImage: overImage);
          // Secondary text at 12.5-11.5pt bold — 3:1 is the large/secondary bar.
          expect(_contrast(p.subColor, bg), greaterThanOrEqualTo(3.0));
          expect(_contrast(p.metaColor, bg), greaterThanOrEqualTo(3.0));
        });

        testWidgets('$mode, $backing: the non-today date pill is readable',
            (tester) async {
          final p = await _palette(tester,
              isDark: isDark, overImage: overImage, isToday: false);
          final base = p.effectiveTextBackground(overImage: overImage);
          final pillBg = Color.alphaBlend(p.pillFill, base);
          expect(_contrast(p.pillText, pillBg), greaterThanOrEqualTo(3.0));
        });
      }
    }
  });

  group('the card belongs to its theme', () {
    testWidgets('light mode paints a LIGHT card, dark mode a DARK one',
        (tester) async {
      final light = await _palette(tester,
          isDark: false, overImage: true, isToday: true);
      final dark = await _palette(tester,
          isDark: true, overImage: true, isToday: true);

      expect(_luminance(light.cardFill), greaterThan(0.5),
          reason: 'bug (2): a hard-coded dark slab in an otherwise white Home');
      expect(_luminance(dark.cardFill), lessThan(0.1));
    });

    testWidgets('the scrim ramps toward the card fill, not a fixed black',
        (tester) async {
      for (final isDark in [true, false]) {
        final p = await _palette(tester,
            isDark: isDark, overImage: true, isToday: true);
        final foot = Color.alphaBlend(p.scrimColors.last, p.cardFill);
        // The foot of the scrim IS the text background; it must land on the
        // same side of the light/dark line as the card itself.
        expect((_luminance(foot) > 0.5), equals(!isDark),
            reason: 'scrimBase must follow the theme');
      }
    });

    testWidgets('the photo is pushed toward the surface, not always darkened',
        (tester) async {
      final dark = await _palette(tester,
          isDark: true, overImage: true, isToday: true);
      expect(dark.imageBlendMode, BlendMode.darken);

      final light = await _palette(tester,
          isDark: false, overImage: true, isToday: true);
      expect(light.imageBlendMode, BlendMode.lighten);
    });

    testWidgets('the over-photo text halo is the surface colour, not black',
        (tester) async {
      final light = await _palette(tester,
          isDark: false, overImage: true, isToday: true);
      expect(light.textShadows.single.color, Colors.white,
          reason: 'dark text over a photo needs a WHITE halo');

      final dark = await _palette(tester,
          isDark: true, overImage: true, isToday: true);
      expect(dark.textShadows.single.color, Colors.black);
    });

    testWidgets('no halo when there is no photo to read over', (tester) async {
      for (final isDark in [true, false]) {
        final p = await _palette(tester,
            isDark: isDark, overImage: false, isToday: true);
        expect(p.textShadows, isEmpty);
      }
    });
  });
}
