/// Per-exercise overrides for the instructions screen's video/image framing.
///
/// Source illustrations for some exercises are exported as tall portrait
/// canvases with significant white padding baked around the figure (e.g.,
/// cable machine exercises where the rig extends beyond the body). Rendering
/// those at their native aspect leaves the figure small and surrounded by
/// empty white. This map lets us re-frame specific offenders without
/// touching the default rendering path.
///
/// To add an entry, match by the exercise's display name (case-insensitive).
library;

class ExerciseVideoCrop {
  /// Container aspect ratio to force (width / height). A tighter ratio than
  /// the source trims top/bottom whitespace.
  final double aspectRatio;

  /// Zoom factor applied inside the container (1.0 = no zoom). Values >1
  /// scale the video/image up so the baked-in margin crops against the
  /// container edges, letting the figure fill the frame.
  final double scale;

  const ExerciseVideoCrop({
    required this.aspectRatio,
    this.scale = 1.0,
  });
}

/// Keyed by lowercased exercise name. Keep this list small — only add
/// exercises whose native framing is visibly wrong.
const Map<String, ExerciseVideoCrop> exerciseVideoOverrides = {
  // Cable Cross Pushdown: native clip is tall portrait with the cable rig
  // extending far above the figure. 4:5 + 1.25× crop centres the torso.
  'cable cross pushdown': ExerciseVideoCrop(aspectRatio: 4 / 5, scale: 1.25),
};

ExerciseVideoCrop? exerciseVideoCropFor(String exerciseName) {
  return exerciseVideoOverrides[exerciseName.trim().toLowerCase()];
}
