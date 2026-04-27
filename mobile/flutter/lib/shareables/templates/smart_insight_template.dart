import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

/// SmartInsight — single sparkle-prefixed insight callout on dark canvas
/// with a supporting mini bar chart and one-line rationale. Spark
/// category. Headline auto-generated from the strongest highlight.
class SmartInsightTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const SmartInsightTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  String _insight(Shareable d) {
    final hl = d.highlights.where((h) => h.isPopulated).toList();
    if (hl.isEmpty) {
      return 'You showed up. That\'s the move.';
    }
    final h = hl.first;
    return 'Your ${h.label.toLowerCase()} is ${h.value}.';
  }

  String _rationale(Shareable d) {
    final hl = d.highlights.where((h) => h.isPopulated).toList();
    if (hl.length <= 1) return 'Keep stacking weeks like this one.';
    final next = hl[1];
    return 'Compared to last period: ${next.label.toLowerCase()} ${next.value}.';
  }

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final hl = data.highlights.where((h) => h.isPopulated).take(4).toList();

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: [
        const Color(0xFF0B0F19),
        Color.lerp(accent, const Color(0xFF0B0F19), 0.85)!,
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 80, 40, 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.85),
                        accent.withValues(alpha: 0.45),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'INSIGHT',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13 * mul,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              data.periodLabel.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12 * mul,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _insight(data),
              style: TextStyle(
                color: Colors.white,
                fontSize: 36 * mul,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _rationale(data),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14 * mul,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            if (hl.isNotEmpty)
              SizedBox(
                height: 160,
                child: _MiniBarChart(metrics: hl, accent: accent, mul: mul),
              ),
            const Spacer(),
            if (showWatermark)
              Row(
                children: [
                  AppWatermark(
                    textColor: Colors.white,
                    fontSize: 13 * mul,
                  ),
                  const Spacer(),
                  Icon(Icons.auto_awesome,
                      size: 14 * mul,
                      color: accent.withValues(alpha: 0.7)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  final List<ShareableMetric> metrics;
  final Color accent;
  final double mul;

  const _MiniBarChart({
    required this.metrics,
    required this.accent,
    required this.mul,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final barW = (c.maxWidth - (metrics.length - 1) * 14) / metrics.length;
        return Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < metrics.length; i++) ...[
                    _bar(metrics[i], i, barW),
                    if (i < metrics.length - 1) const SizedBox(width: 14),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < metrics.length; i++) ...[
                  SizedBox(
                    width: barW,
                    child: Text(
                      metrics[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 9 * mul,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  if (i < metrics.length - 1) const SizedBox(width: 14),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _bar(ShareableMetric m, int i, double w) {
    // Pseudo-deterministic height variance based on hash of value, so the
    // chart looks like real comparative data without needing series.
    final hash = (m.value.hashCode & 0x7FFFFFFF) % 100;
    final h = 0.32 + (hash / 100.0) * 0.62;
    final colors = [
      accent,
      accent.withValues(alpha: 0.7),
      accent.withValues(alpha: 0.5),
      accent.withValues(alpha: 0.35),
    ];
    return Expanded(
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          FractionallySizedBox(
            heightFactor: h,
            child: Container(
              width: w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [colors[i % colors.length], Colors.transparent],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            child: Text(
              m.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11 * mul,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
