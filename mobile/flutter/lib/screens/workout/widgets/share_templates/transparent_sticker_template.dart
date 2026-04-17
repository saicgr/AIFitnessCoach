import 'dart:ui';
import 'package:flutter/material.dart';
import '_share_common.dart';

/// Transparent Sticker — frosted-glass stat pill on a transparent
/// background. The caller must render this with an alpha-channel
/// capture so the PNG has real transparency for IG Stories overlay.
class TransparentStickerTemplate extends StatelessWidget {
  final String workoutName;
  final double? totalVolumeKg;
  final int totalSets;
  final int durationSeconds;
  final DateTime completedAt;
  final bool showWatermark;
  final String weightUnit;

  const TransparentStickerTemplate({
    super.key,
    required this.workoutName,
    this.totalVolumeKg,
    required this.totalSets,
    required this.durationSeconds,
    required this.completedAt,
    this.showWatermark = true,
    this.weightUnit = 'lbs',
  });

  @override
  Widget build(BuildContext context) {
    final useKg = weightUnit == 'kg';
    // Outer container is transparent; only the pill is visible when
    // the capture has alpha channel enabled.
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(40),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShareTrackedCaps(
                    workoutName,
                    size: 10,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 3,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    totalVolumeKg == null
                        ? '—'
                        : formatShareWeightCompact(totalVolumeKg, useKg: useKg),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ShareTrackedCaps(
                    'VOLUME',
                    size: 9,
                    color: const Color(0xFFF59E0B),
                    letterSpacing: 3,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 1,
                    width: 80,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _pillStat('$totalSets', 'SETS'),
                      const SizedBox(width: 18),
                      _pillStat(
                          formatShareDurationLong(durationSeconds), 'TIME'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ShareWatermarkBadge(enabled: showWatermark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pillStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.6),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
