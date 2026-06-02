import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/heart_rate_provider.dart';

/// Live in-workout calories HUD (Gap 6).
///
/// Sits next to [HeartRateDisplay] during an active session. Estimates calories
/// burned SO FAR from the live heart rate (Keytel HR→kcal/min) × elapsed time;
/// falls back to a moderate MET rate (~5 kcal/min) when no watch HR is present
/// — the same model the post-session calc uses, just surfaced live. The
/// post-session value remains authoritative; this is a real-time estimate.
class LiveCaloriesDisplay extends ConsumerWidget {
  /// Elapsed workout time in seconds (from the workout timer).
  final int elapsedSeconds;
  final double iconSize;
  final double fontSize;

  // Optional profile for an accurate Keytel estimate. Sensible defaults keep
  // the widget drop-in when the caller doesn't have profile handy.
  final double weightKg;
  final int age;
  final bool isFemale;

  const LiveCaloriesDisplay({
    super.key,
    required this.elapsedSeconds,
    this.iconSize = 16,
    this.fontSize = 14,
    this.weightKg = 75,
    this.age = 30,
    this.isFemale = false,
  });

  /// Keytel et al. (2005) HR→kcal/min. Returns a non-negative rate.
  double _kcalPerMinute(int? bpm) {
    if (bpm == null || bpm <= 0) {
      return 5.0; // moderate-effort MET fallback (~5 kcal/min)
    }
    final double raw = isFemale
        ? (-20.4022 + 0.4472 * bpm - 0.1263 * weightKg + 0.074 * age) / 4.184
        : (-55.0969 + 0.6309 * bpm + 0.1988 * weightKg + 0.2017 * age) / 4.184;
    // Clamp: HR below the active threshold yields a tiny/negative raw value.
    return raw < 1.0 ? 1.0 : raw;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heartRateAsync = ref.watch(liveHeartRateProvider);
    final bpm = heartRateAsync.valueOrNull?.bpm;
    final minutes = elapsedSeconds / 60.0;
    final kcal = (_kcalPerMinute(bpm) * minutes).round();

    final color = Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_fire_department,
            size: iconSize, color: const Color(0xFFFF6B35)),
        const SizedBox(width: 4),
        Text(
          '$kcal',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          'kcal',
          style: TextStyle(
            fontSize: fontSize * 0.72,
            fontWeight: FontWeight.w500,
            color: color.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
