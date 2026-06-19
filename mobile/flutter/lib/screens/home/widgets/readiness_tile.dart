import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/accent_color_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/scores.dart';
import '../../../data/repositories/readiness_repository.dart';
import '../../../data/services/haptic_service.dart';

import '../../../l10n/generated/app_localizations.dart';
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
/// pushes the readiness detail route `/stats/readiness` (the Comprehensive
/// Stats screen opened on its Readiness tab).
class ReadinessTile extends ConsumerWidget {
  const ReadinessTile({super.key});

  /// GoRouter path for the readiness detail surface. Was the never-registered
  /// `/readiness-detail` named route (crashed on tap: "Navigator.onGenerateRoute
  /// was null"); the real destination is the stats screen's Readiness tab.
  static const String routeName = '/stats/readiness';

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
    final c = ThemeColors.of(context);
    final light = _trafficLightFor(readiness.level, accent);
    final prescription = _prescriptionFor(readiness);

    // Signature v2: a flat surface with a single hairline border. The traffic
    // light is the one accent (semantic), rendered as a clean dot — no glow.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticService.light();
            context.push(ReadinessTile.routeName);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.cardBorder),
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
                        AppLocalizations.of(context)
                            .readinessTileRecoveryReadiness
                            .toUpperCase(),
                        style: ZType.lbl(11, color: c.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prescription,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: c.textMuted),
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
    final c = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticService.light();
            context.push(ReadinessTile.routeName);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
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
                        AppLocalizations.of(context)
                            .readinessTileRecoveryReadiness
                            .toUpperCase(),
                        style: ZType.lbl(11, color: c.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)
                            .readinessTileBuildingBaselineCheckIn,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: c.textMuted),
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
    // Signature v2: a clean semantic dot — flat, no glow. A faint hairline ring
    // keeps it legible against the surface without the old halo.
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.35), width: 4),
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
