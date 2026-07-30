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

  /// Opacity for [scene] at global [tMs] — a TRUE crossfade.
  ///
  /// The outgoing scene ramps 1→0 over the last [fadeMs] of its own window
  /// while the incoming scene ramps 0→1 over that SAME interval (its pre-roll,
  /// which lives at the tail of the previous window and wraps around the loop
  /// seam for scene 0). Total opacity therefore stays ~1 across the boundary.
  ///
  /// The previous version faded the outgoing scene out over the last [fadeMs]
  /// of its window and only started fading the incoming one in over the FIRST
  /// [fadeMs] of the next window — so for ~240 ms at every boundary BOTH scenes
  /// were at ~0 and the screen showed a blank slide. That blank frame, plus the
  /// caption switching on the boundary while the old scene was still visible,
  /// is what read as the carousel "ghosting".
  static double opacityFor(int scene, int tMs) {
    final start = scene * sceneMs;
    final end = start + sceneMs;

    // Inside its own window: full opacity, ramping out at the tail.
    if (tMs >= start && tMs < end) {
      final remaining = end - tMs;
      if (remaining < fadeMs) return remaining / fadeMs;
      return 1.0;
    }

    // Pre-roll: ramp IN during the outgoing scene's tail fade.
    final rampStart = start - fadeMs;
    if (rampStart >= 0) {
      if (tMs >= rampStart && tMs < start) return (tMs - rampStart) / fadeMs;
    } else {
      // Scene 0's pre-roll wraps to the end of the loop.
      final wrapped = loopMs + rampStart;
      if (tMs >= wrapped) return (tMs - wrapped) / fadeMs;
    }
    return 0.0;
  }

  /// Opacity for the caption that narrates the current scene. A SINGLE caption
  /// widget is ever mounted (see IntroScreen): it fades out over the boundary
  /// and back in on the new scene, so two captions can never be legible at
  /// once.
  ///
  /// There is deliberately NO `tMs < fadeMs → 1.0` special case. `tMs` is a
  /// LOOPING clock, not a launch timestamp, so that shortcut fired on EVERY
  /// pass of the loop (~every 10 s), snapping the caption 0.004 → 1.0 in one
  /// frame at the seam while every other boundary crossfades over 240 ms.
  /// Verified by simulating the loop ms-by-ms. The seam now ramps like every
  /// other boundary; the only cost is a 240 ms fade-in of the caption at
  /// launch, while the scene itself still paints instantly (opacityFor(0, 0)
  /// is 1.0).
  static double captionOpacity(int tMs) {
    final local = localMs(tMs);
    final out = (sceneMs - local) / fadeMs;
    final inn = local / fadeMs;
    final v = out < inn ? out : inn;
    return v.clamp(0.0, 1.0);
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
