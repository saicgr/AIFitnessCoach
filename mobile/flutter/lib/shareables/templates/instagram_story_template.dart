import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// Instagram Story-native — pink → orange → yellow gradient with the
/// hero number giant-typed and centered. Designed for the 9:16 aspect
/// users post directly to Stories. Falls back gracefully on 4:5 / 1:1.
class InstagramStoryTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const InstagramStoryTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final hero = data.heroValue == null
        ? data.title
        : '${data.heroPrefix ?? ''}${data.heroValue}${data.heroSuffix ?? ''}';
    final unit = data.heroUnitSingular.toUpperCase();
    final firstHighlight = data.highlights.isNotEmpty
        ? data.highlights.first.value
        : data.periodLabel;

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [
        Color(0xFFEC4899),
        Color(0xFFF97316),
        Color(0xFFEAB308),
      ],
      child: Stack(
        children: [
          // Top — handle pill
          Positioned(
            top: 56,
            left: 36,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '@${(data.userDisplayName ?? 'you').toLowerCase().split(' ').first}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14 * mul,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // Center — emoji + hero number + unit
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('💪', style: TextStyle(fontSize: 80 * mul)),
                const SizedBox(height: 18),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    hero,
                    style: TextStyle(
                      fontSize: 92 * mul,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -2,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (unit.isNotEmpty)
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 18 * mul,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                if (firstHighlight.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    firstHighlight.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14 * mul,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Bottom — brand wordmark
          Positioned(
            bottom: 56,
            left: 36,
            child: Text(
              Branding.appName.toLowerCase(),
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16 * mul,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (showWatermark)
            Positioned(
              bottom: 36,
              right: 36,
              child: const AppWatermark(textColor: Colors.white70),
            ),
        ],
      ),
    );
  }
}
