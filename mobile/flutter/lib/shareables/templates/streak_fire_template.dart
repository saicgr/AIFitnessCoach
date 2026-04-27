import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

/// Streak Fire — radial orange/red, big streak number, "DAY STREAK" tag.
class StreakFireTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const StreakFireTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final streakMetric = data.highlights.firstWhere(
      (h) => h.label.toUpperCase().contains('STREAK'),
      orElse: () => ShareableMetric(
        label: 'STREAK',
        value: data.heroValue?.toString() ?? '0',
      ),
    );

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [
        Color(0xFF7C2D12),
        Color(0xFFB45309),
        Color(0xFF1F1411),
      ],
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.6,
                  colors: [
                    const Color(0xFFFB923C).withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 56, 28, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  data.title.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13 * mul,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                const Spacer(),
                Icon(Icons.local_fire_department_rounded,
                    color: Colors.orange.shade200, size: 88),
                const SizedBox(height: 8),
                Text(
                  streakMetric.value.replaceAll(RegExp(r'[^0-9]'), '').isEmpty
                      ? streakMetric.value
                      : streakMetric.value.replaceAll(RegExp(r'[^0-9]'), ''),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 140,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                    letterSpacing: -4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'DAY STREAK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16 * mul,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const Spacer(),
                Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: data.highlights
                      .where(
                          (h) => !h.label.toUpperCase().contains('STREAK'))
                      .take(2)
                      .map(
                        (h) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              h.value,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22 * mul,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              h.label.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 10 * mul,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                if (showWatermark) AppWatermark(textColor: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

