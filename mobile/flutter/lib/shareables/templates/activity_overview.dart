import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/shareable_hero_number.dart';

/// Activity Overview — the dark card with the heatmap pattern, hero count,
/// and 3 stat tiles (This Week, Total Time, Streak). User explicitly likes
/// this style — adopted from `stats_overview_template.dart` and made
/// aspect-aware so it can serve as the default for every kind.
class ActivityOverviewTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const ActivityOverviewTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    return ShareableCanvas(
      aspect: data.aspect,
      accentColor: data.accentColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _HeatmapPainter(data.accentColor)),
          ),
          Padding(
            padding: _padding,
            child: _content(context),
          ),
        ],
      ),
    );
  }

  EdgeInsets get _padding {
    switch (data.aspect) {
      case ShareableAspect.square:
        return const EdgeInsets.fromLTRB(28, 28, 28, 22);
      case ShareableAspect.portrait:
        return const EdgeInsets.fromLTRB(36, 44, 36, 28);
      case ShareableAspect.story:
        return const EdgeInsets.fromLTRB(40, 88, 40, 60);
    }
  }

  Widget _content(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final highlights = data.highlights.take(3).toList();
    final streak = data.highlights
        .firstWhere(
          (h) => h.label.toUpperCase().contains('STREAK'),
          orElse: () => const ShareableMetric(label: '', value: ''),
        )
        .value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title.toUpperCase(),
                    style: TextStyle(
                      color: data.accentColor,
                      fontSize: 13 * mul,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.periodLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 14 * mul,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (streak.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: data.accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: data.accentColor.withValues(alpha: 0.45)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        color: data.accentColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      streak,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12 * mul,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const Spacer(flex: 2),
        Center(
          child: ShareableHeroNumber(
            data: data,
            size: data.aspect == ShareableAspect.story ? 140 : 96,
            unitSize: 18,
            stacked: true,
            color: Colors.white,
          ),
        ),
        const Spacer(flex: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: highlights
              .map((h) => Expanded(child: _StatTile(metric: h, accent: h.accent ?? data.accentColor)))
              .toList(),
        ),
        const Spacer(flex: 1),
        if (showWatermark)
          Center(
            child: AppWatermark(textColor: Colors.white.withValues(alpha: 0.85)),
          ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final ShareableMetric metric;
  final Color accent;

  const _StatTile({required this.metric, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(metric.icon ?? Icons.show_chart_rounded,
              color: accent, size: 26),
        ),
        const SizedBox(height: 10),
        Text(
          metric.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          metric.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final Color accent;

  _HeatmapPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const cell = 14.0;
    const gap = 4.0;
    for (double x = 0; x < size.width; x += cell + gap) {
      for (double y = 0; y < size.height; y += cell + gap) {
        final n = ((x * 31 + y * 17) % 100) / 100.0;
        final alpha = 0.02 + n * 0.05;
        paint.color = accent.withValues(alpha: alpha);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, cell, cell), const Radius.circular(2)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter old) => old.accent != accent;
}
