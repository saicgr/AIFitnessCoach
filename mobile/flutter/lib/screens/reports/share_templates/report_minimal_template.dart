import 'dart:ui';

import 'package:flutter/material.dart';

import '../../workout/widgets/share_templates/_share_common.dart';
import '_report_common.dart';

/// Minimal — transparent-canvas frosted stat pill, designed for IG-Story
/// overlays where the user will drop it on top of their own photo/video.
/// The background is intentionally near-transparent so alpha capture yields
/// a clean cutout when exported.
class ReportMinimalTemplate extends StatelessWidget {
  final ReportShareData data;
  final bool showWatermark;

  const ReportMinimalTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final hero = heroMetricFor(data);
    final unit = heroUnitFor(data);

    return RepaintBoundary(
      child: Container(
        // Dark transparent base so preview-over-background is legible while
        // alpha capture still strips the majority of the canvas.
        color: Colors.black.withValues(alpha: 0.15),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShareTrackedCaps(
                      data.periodLabel,
                      size: 10,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 3,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          hero,
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -2,
                            height: 1,
                          ),
                        ),
                        if (unit.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            unit,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: data.accentColor,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (showWatermark) ...[
                      const SizedBox(height: 14),
                      const ShareWatermarkBadge(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
