import 'package:flutter/material.dart';

/// Timing math for the intro screen's auto-playing demo.
///
/// Each scene gets a fixed [sceneMs] window; the master loop is exactly
/// `sceneCount × sceneMs` long, so the loop length scales with however many
/// scenes are active (the two Gravl-gap scenes — integrations + shareables —
/// are flag-gated and may be dropped, shrinking the loop to keep timing
/// correct). The base four:
///   0 program builder · 1 live logging · 2 food scan · 3 menu analysis
/// then optionally · 4 integrations · 5 shareables.
/// All scene widgets receive a LOCAL time (ms inside their own window) so
/// their internal beats are window-relative.
///
/// [configure] is called once in [IntroScreen.initState] with the resolved
/// active-scene count; it is a no-op to call it repeatedly with the same
/// value. Defaults to the four base scenes so any read before configuration
/// (or in the legacy fallback) is still correct.
class DemoClock {
  DemoClock._();

  static const int sceneMs = 2500;

  /// Number of active scenes (4..6). Set by [configure] from the resolved
  /// feature flags; the loop and scene-fade math read it live.
  static int sceneCount = 4;

  /// Total master-loop length — derived so each scene keeps its full
  /// [sceneMs] window regardless of how many are active.
  static int get loopMs => sceneCount * sceneMs;

  /// Crossfade duration at scene boundaries.
  static const int fadeMs = 240;

  /// Set the active-scene count (clamped to the 4 base + up to 2 optional).
  static void configure(int activeScenes) {
    sceneCount = activeScenes.clamp(4, 6);
  }

  /// Global loop time in ms from the master controller's 0..1 value.
  static int timeMs(double controllerValue) =>
      (controllerValue * loopMs).floor() % loopMs;

  /// Which scene window [tMs] falls in.
  static int sceneOf(int tMs) =>
      (tMs ~/ sceneMs).clamp(0, sceneCount - 1);

  /// Time inside the current scene window.
  static int localMs(int tMs) => tMs % sceneMs;

  /// Fraction (0..1) through the current scene — drives the dot countdown.
  static double sceneFraction(int tMs) => localMs(tMs) / sceneMs;

  /// Opacity for [scene] at global [tMs]: 1 inside its window with short
  /// ease in/out ramps at the edges, 0 elsewhere.
  static double opacityFor(int scene, int tMs) {
    final start = scene * sceneMs;
    final end = start + sceneMs;
    // The first scene must be fully visible at t=0 (instant first paint);
    // it only fades OUT at its end and back IN at the loop seam.
    if (tMs < start || tMs >= end) {
      // Loop seam: scene 0 fades back in from the tail of scene 3's window.
      return 0.0;
    }
    final local = tMs - start;
    if (scene != 0 && local < fadeMs) return local / fadeMs;
    if (end - tMs < fadeMs) return (end - tMs) / fadeMs;
    return 1.0;
  }

  /// Controller value that puts the loop at the start of [scene].
  static double valueForScene(int scene) =>
      (scene * sceneMs) / loopMs;
}

/// Convenience: true once [thresholdMs] of local scene time has elapsed.
/// Used by scenes to stagger their internal beats.
bool beat(int localMs, int thresholdMs) => localMs >= thresholdMs;

/// 0..1 progress between two local-time beats, eased.
double beatT(int localMs, int fromMs, int toMs, [Curve curve = Curves.easeOut]) {
  if (localMs <= fromMs) return 0;
  if (localMs >= toMs) return 1;
  return curve.transform((localMs - fromMs) / (toMs - fromMs));
}

/// Pop-in wrapper for demo beats: fades + slides a child in once its beat
/// hits, mirroring the mockup's `vl-pop-in`.
class BeatIn extends StatelessWidget {
  final int localMs;
  final int at;
  final Widget child;

  const BeatIn({
    super.key,
    required this.localMs,
    required this.at,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final t = beatT(localMs, at, at + 260);
    if (t == 0) return const SizedBox.shrink();
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - t)),
        child: child,
      ),
    );
  }
}
