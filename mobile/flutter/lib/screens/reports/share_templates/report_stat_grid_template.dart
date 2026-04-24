import 'package:flutter/material.dart';

import '../../workout/widgets/share_templates/_share_common.dart';
import '_report_common.dart';

/// Stat Grid — 2xN squircle tiles generated straight from highlights[].
/// Best for nutrition-style macro breakdowns and any report with a tidy set
/// of parallel metrics. Locks out with ShareLockOverlay when highlights is
/// empty — a grid of placeholders reads as broken, not minimalist.
class ReportStatGridTemplate extends StatelessWidget {
  final ReportShareData data;
  final bool showWatermark;

  const ReportStatGridTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = data.highlights.take(6).toList();
    final accent = data.accentColor;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: accentGradient(accent),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 38, 22, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShareTrackedCaps(
                  data.periodLabel,
                  size: 11,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
                const SizedBox(height: 4),
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: tiles.length,
                    itemBuilder: (context, i) {
                      final h = tiles[i];
                      return _GridTile(highlight: h, accent: accent);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShareTrackedCaps(
                      data.userDisplayName?.toUpperCase() ?? 'LIFTER',
                      size: 10,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    ShareWatermarkBadge(enabled: showWatermark),
                  ],
                ),
              ],
            ),
          ),
          if (tiles.isEmpty)
            const ShareLockOverlay(message: 'Log more to unlock'),
        ],
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  final ReportHighlight highlight;
  final Color accent;

  const _GridTile({required this.highlight, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShareTrackedCaps(
            highlight.label,
            size: 9,
            color: Colors.white.withValues(alpha: 0.65),
            letterSpacing: 2,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              highlight.value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.8,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
