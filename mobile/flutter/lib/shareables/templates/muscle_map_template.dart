import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/anatomical_figure.dart';
import '../widgets/app_watermark.dart';

/// MuscleMap — anatomical front silhouette with muscle groups heat-coded
/// from `data.musclesWorked`. Sparkle accent. Spark category — synthesizes
/// raw set data into a single glanceable visual ("you trained your back
/// 4× this week, chest 2×, legs 1×").
class MuscleMapTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const MuscleMapTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final muscles = data.musclesWorked ?? const <String, int>{};
    final secondaryMuscles =
        data.secondaryMusclesWorked ?? const <String, int>{};
    final maxCount = muscles.values.fold<int>(0, math.max);
    final top = muscles.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topThree = top.take(3).toList();

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: [
        const Color(0xFF06080F),
        Color.lerp(accent, const Color(0xFF06080F), 0.85)!,
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 80, 36, 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 18 * mul, color: accent),
                const SizedBox(width: 8),
                Text(
                  'MUSCLE MAP',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13 * mul,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const Spacer(),
                Text(
                  data.periodLabel.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11 * mul,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26 * mul,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              muscles.isEmpty
                  ? 'Trained the body. Volume is on the board.'
                  : '${muscles.length} groups trained · top: ${topThree.first.key}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13 * mul,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: AnatomicalFigure(
                  view: BodyView.dual,
                  muscles: muscles,
                  secondaryMuscles: secondaryMuscles,
                  maxCount: maxCount == 0 ? 1 : maxCount,
                  accent: accent,
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (topThree.isNotEmpty)
              Row(
                children: [
                  for (var i = 0; i < topThree.length; i++) ...[
                    Expanded(
                      child: _legendChip(
                        topThree[i].key,
                        topThree[i].value,
                        accent,
                        mul,
                      ),
                    ),
                    if (i < topThree.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            const SizedBox(height: 18),
            if (showWatermark)
              AppWatermark(
                textColor: Colors.white,
                fontSize: 13 * mul,
              ),
          ],
        ),
      ),
    );
  }

  Widget _legendChip(String name, int count, Color accent, double mul) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 10 * mul,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22 * mul,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                count == 1 ? 'set' : 'sets',
                style: TextStyle(
                  color: accent,
                  fontSize: 11 * mul,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
