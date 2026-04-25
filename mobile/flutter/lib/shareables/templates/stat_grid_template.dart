import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/fitwiz_watermark.dart';
import '../widgets/shareable_hero_number.dart';

/// Stat Grid — title + hero on top half, 2×2 grid of highlights on the
/// bottom half. Designed for kinds with 4+ rich metrics.
class StatGridTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const StatGridTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final tiles = data.highlights.take(4).toList();

    return ShareableCanvas(
      aspect: data.aspect,
      accentColor: data.accentColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 56, 28, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.title.toUpperCase(),
              style: TextStyle(
                color: data.accentColor,
                fontSize: 13 * mul,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.periodLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13 * mul,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            ShareableHeroNumber(
              data: data,
              size: data.aspect == ShareableAspect.story ? 130 : 96,
              unitSize: 18,
              stacked: false,
              color: Colors.white,
              unitColor: data.accentColor,
            ),
            const SizedBox(height: 28),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                physics: const NeverScrollableScrollPhysics(),
                children: tiles.map((m) => _Tile(metric: m, accent: data.accentColor)).toList(),
              ),
            ),
            const SizedBox(height: 12),
            if (showWatermark)
              Align(
                alignment: Alignment.centerRight,
                child: FitWizWatermark(textColor: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final ShareableMetric metric;
  final Color accent;

  const _Tile({required this.metric, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(metric.icon ?? Icons.show_chart_rounded,
                    color: accent, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  metric.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
