import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/scores.dart';
import '../../../data/repositories/readiness_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Recovery Readiness tile for the Home composable.
///
/// Layout:
///   ┌──────────────────────────────────────────────┐
///   │  ◉  Recovery Readiness                       │
///   │     Hard session OK                          │
///   └──────────────────────────────────────────────┘
///
/// Visual: traffic-light circle (green / amber / red) tinted to the user's
/// AccentColorScope, plus a 1-line prescription derived from the readiness
/// score's `recommendedIntensity`.
///
/// States:
///   - Checked-in today  → traffic light + prescription, tappable.
///   - Calibrating (<14d / no check-in) → "Building baseline" empty state.
///
/// The composer (Wave 2) is responsible for inserting this tile in the home
/// vertical stack; this widget owns layout + interaction only. Tapping
/// pushes the named route `/readiness-detail` (the destination screen is
/// owned by the Phase A.5 refactor agent).
class ReadinessTile extends ConsumerWidget {
  const ReadinessTile({super.key});

  static const String routeName = '/readiness-detail';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    final readiness = ref.watch(todayReadinessScoreProvider);
    final calibrating = ref.watch(readinessCalibratingProvider);

    if (calibrating || readiness == null) {
      return _CalibrationTile(accent: accent);
    }

    return _CheckedInTile(readiness: readiness, accent: accent);
  }
}

// ---------------------------------------------------------------------------
// Checked-in tile
// ---------------------------------------------------------------------------

class _CheckedInTile extends StatelessWidget {
  const _CheckedInTile({required this.readiness, required this.accent});

  final ReadinessScore readiness;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final light = _trafficLightFor(readiness.level, accent);
    final prescription = _prescriptionFor(readiness);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticService.light();
            Navigator.of(context).pushNamed(ReadinessTile.routeName);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: light.withOpacity(0.30)),
            ),
            child: Row(
              children: [
                _TrafficLight(color: light),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recovery Readiness',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prescription,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.75),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.iconTheme.color?.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Calibration / empty-state tile
// ---------------------------------------------------------------------------

class _CalibrationTile extends StatelessWidget {
  const _CalibrationTile({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticService.light();
            Navigator.of(context).pushNamed(ReadinessTile.routeName);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.timelapse_rounded,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recovery Readiness',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Building baseline — check in daily for 14 days',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.75),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.iconTheme.color?.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Traffic-light dot
// ---------------------------------------------------------------------------

class _TrafficLight extends StatelessWidget {
  const _TrafficLight({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.45),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Map readiness level → traffic-light color. Tints with the user's accent
/// on the optimal end so the tile feels personalised; amber/red are kept
/// universal because warning semantics must be readable regardless of accent.
Color _trafficLightFor(ReadinessLevel level, Color accent) {
  switch (level) {
    case ReadinessLevel.optimal:
    case ReadinessLevel.good:
      // Blend toward green so the accent flavours but doesn't obscure
      // the "green = go" semantics.
      return Color.lerp(const Color(0xFF22C55E), accent, 0.35)!;
    case ReadinessLevel.moderate:
      return const Color(0xFFF59E0B); // amber
    case ReadinessLevel.low:
      return const Color(0xFFEF4444); // red
  }
}

/// One-line workout prescription derived from readiness intensity.
String _prescriptionFor(ReadinessScore readiness) {
  switch (readiness.intensity) {
    case WorkoutIntensity.max:
    case WorkoutIntensity.high:
      return 'Hard session OK';
    case WorkoutIntensity.moderate:
      return 'Normal training OK';
    case WorkoutIntensity.light:
      return 'Z2 cardio recommended';
    case WorkoutIntensity.rest:
      return 'Recovery day';
  }
}
