import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/food_image.dart';
import '../widgets/macro_viz.dart';

/// FoodPolaroid — the meal photo as a classic instant-camera print: an
/// off-white frame, a slight tilt, a soft drop shadow, on a warm-tinted
/// backdrop. The dish name sits in the wide bottom border as a handwritten-
/// style caption; a one-line numeric macro readout sits beneath it; the date
/// + watermark close the print's bottom strip.
///
/// Renders across all 3 aspects — the polaroid is sized to the canvas's
/// shorter axis so it never overflows on the square (1:1) canvas.
class FoodPolaroidTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const FoodPolaroidTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final nutrition = data.nutrition ?? const ShareableNutrition();
    final photoUrl = data.foodImageUrls?.isNotEmpty == true
        ? data.foodImageUrls!.first
        : null;
    final isStory = data.aspect == ShareableAspect.story;

    return ShareableCanvas(
      aspect: data.aspect,
      // Warm, dark, slightly accent-tinted backdrop — a tabletop the print
      // is resting on. Deliberately not pure black so the white print pops.
      backgroundOverride: [
        Color.lerp(const Color(0xFF1A1714), accent, 0.16)!,
        Color.lerp(const Color(0xFF0C0A09), accent, 0.06)!,
      ],
      child: Padding(
        // Story canvas is tall — extra vertical padding centers the print.
        padding: EdgeInsets.symmetric(
          horizontal: 64,
          vertical: isStory ? 96 : 56,
        ),
        child: Center(
          // FittedBox scales the fixed-width print down to whatever the
          // canvas leaves — guarantees it never overflows on any aspect.
          child: FittedBox(
            fit: BoxFit.contain,
            child: Transform.rotate(
              angle: -2.4 * math.pi / 180, // gentle, hand-placed tilt
              child: SizedBox(
                width: 760,
                child: _Polaroid(
                  data: data,
                  mul: mul,
                  accent: accent,
                  nutrition: nutrition,
                  photoUrl: photoUrl,
                  showWatermark: showWatermark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The off-white print itself: a thin top/side border, a near-square photo
/// window, and a tall bottom border carrying the caption + macros + footer.
class _Polaroid extends StatelessWidget {
  final Shareable data;
  final double mul;
  final Color accent;
  final ShareableNutrition nutrition;
  final String? photoUrl;
  final bool showWatermark;

  const _Polaroid({
    required this.data,
    required this.mul,
    required this.accent,
    required this.nutrition,
    required this.photoUrl,
    required this.showWatermark,
  });

  @override
  Widget build(BuildContext context) {
    const paperA = Color(0xFFFBF8F1);
    const paperB = Color(0xFFEFEAE0);
    const ink = Color(0xFF1F1B16);

    final mealLabel = data.mealLabel?.trim();
    final date = data.periodLabel.trim();
    final user = data.userDisplayName?.trim();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [paperA, paperB],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 48,
            spreadRadius: 2,
            offset: Offset(0, 22),
          ),
        ],
      ),
      // Classic polaroid border: equal thin top/sides, tall bottom strip.
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Photo window — near-square, the instant-print look ────────
          AspectRatio(
            aspectRatio: 1.04,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FoodImage(
                    url: photoUrl,
                    fit: BoxFit.cover,
                    fallbackBuilder: () => DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(accent, Colors.black, 0.30)!,
                            Color.lerp(accent, Colors.black, 0.70)!,
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Text('🍽️', style: TextStyle(fontSize: 72)),
                      ),
                    ),
                  ),
                  // Faint vignette so the photo sits inside the print.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: 0.95,
                        colors: [Color(0x00000000), Color(0x33000000)],
                        stops: [0.74, 1.0],
                      ),
                    ),
                  ),
                  // Meal eyebrow tucked into the photo's top-left corner.
                  if (mealLabel != null && mealLabel.isNotEmpty)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          mealLabel.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10 * mul,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          // ─── Handwritten-style caption (the dish name) ─────────────────
          Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              // Cursive family with a graceful fallback — looks handwritten
              // where available, still legible everywhere else.
              fontFamily: 'Brush Script MT',
              fontFamilyFallback: const [
                'Snell Roundhand',
                'Segoe Script',
                'cursive',
              ],
              color: ink,
              fontSize: 30 * mul,
              fontWeight: FontWeight.w600,
              height: 1.05,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          // ─── One-line numeric macro readout ────────────────────────────
          Center(
            child: MacroViz(
              nutrition: nutrition,
              style: MacroVizStyle.numbers,
              accentColor: accent,
              textColor: ink,
              scale: 0.62 * mul,
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: ink.withValues(alpha: 0.14)),
          const SizedBox(height: 10),
          // ─── Bottom strip — date + watermark ───────────────────────────
          Row(
            children: [
              if (showWatermark)
                const AppWatermark(
                  textColor: ink,
                  iconSize: 18,
                  fontSize: 12,
                ),
              const Spacer(),
              if (date.isNotEmpty || (user != null && user.isNotEmpty))
                Flexible(
                  child: Text(
                    [
                      if (date.isNotEmpty) date,
                      if (user != null && user.isNotEmpty) '@$user',
                    ].join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: ink.withValues(alpha: 0.5),
                      fontSize: 11 * mul,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
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
