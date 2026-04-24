import 'package:flutter/material.dart';

import '../../workout/widgets/share_templates/_share_common.dart';
import '_report_common.dart';

/// Wrapped — Spotify-Wrapped styled vertical poster: accent-gradient canvas,
/// a slanted tape strip of highlights, and a giant hero number anchored low.
/// Reads as a year-end recap moment rather than a dashboard.
class ReportWrappedTemplate extends StatelessWidget {
  final ReportShareData data;
  final bool showWatermark;

  const ReportWrappedTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = data.accentColor;
    final hero = heroMetricFor(data);
    final unit = heroUnitFor(data);
    final taped = data.highlights.take(4).toList();

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent,
                  Color.lerp(accent, Colors.black, 0.35)!,
                  const Color(0xFF05050A),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          // Decorative slash strips reminiscent of Wrapped's color blocks.
          Positioned(
            top: 120,
            left: -60,
            right: -60,
            child: Transform.rotate(
              angle: -0.18,
              child: Container(
                height: 46,
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            bottom: 260,
            left: -60,
            right: -60,
            child: Transform.rotate(
              angle: 0.12,
              child: Container(
                height: 28,
                color: Colors.black.withValues(alpha: 0.25),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShareTrackedCaps(
                  data.periodLabel,
                  size: 12,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
                const SizedBox(height: 2),
                Text(
                  'WRAPPED',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 18),
                // Tape strip — transforms highlights into a stacked
                // label/value card deck angled for motion.
                if (taped.isNotEmpty)
                  Transform.rotate(
                    angle: -0.03,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.38),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: taped.map((h) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    h.label.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white70,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                ),
                                Text(
                                  h.value,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                const Spacer(),
                ShareTrackedCaps(
                  'YOUR NUMBER',
                  size: 10,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
                const SizedBox(height: 4),
                ShareHeroNumber(
                  value: hero,
                  unit: unit.isEmpty ? null : unit,
                  size: 180,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  (data.userDisplayName ?? 'Lifter').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ShareWatermarkBadge(enabled: showWatermark),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
