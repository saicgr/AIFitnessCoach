import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/fitwiz_watermark.dart';
import '../widgets/shareable_hero_number.dart';

/// PRs — medal grid showcasing the user's recent PRs. Each highlight becomes
/// a row with a medal-style icon, exercise name, and weight.
class PRsTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const PRsTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: const [
        Color(0xFF1E1B4B),
        Color(0xFF312E81),
        Color(0xFF0F0F1F),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 56, 28, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PERSONAL RECORDS',
              style: TextStyle(
                color: const Color(0xFFFCD34D),
                fontSize: 13 * mul,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
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
            const SizedBox(height: 24),
            ShareableHeroNumber(
              data: data,
              size: data.aspect == ShareableAspect.story ? 140 : 96,
              unitSize: 18,
              stacked: false,
              color: Colors.white,
              unitColor: const Color(0xFFFCD34D),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.highlights.length.clamp(0, 5),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final h = data.highlights[i];
                  return _PRRow(rank: i + 1, metric: h);
                },
              ),
            ),
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

class _PRRow extends StatelessWidget {
  final int rank;
  final ShareableMetric metric;

  const _PRRow({required this.rank, required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFCD34D), Color(0xFFB45309)],
              ),
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              metric.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            metric.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
