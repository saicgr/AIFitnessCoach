import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:muscle_selector/muscle_selector.dart';
import 'package:muscle_selector/src/parser.dart';

import '../../widgets/body_muscle_selector.dart' show backendMuscleToPackageGroup;

/// Which figure(s) to draw out of the muscle_selector `Maps.BODY` SVG.
///
/// That SVG packs an anterior figure (left half, x < midpoint — chest,
/// quads, biceps…) and a posterior figure (right half — lats, glutes,
/// hamstrings…) into a single drawing. [front]/[back] clip to one half so
/// the two figures can be stacked vertically; [dual] renders both
/// side-by-side (the original MuscleMap layout).
enum BodyView { dual, front, back }

/// SVG path id → muscle_selector "package group" name. A single chest path
/// turns the whole pec region hot, both biceps paths share one heat value,
/// etc. Shared by [MuscleMapTemplate] and [WorkoutMuscleCardTemplate].
const Map<String, String> kBodyPathIdToGroup = {
  'chest1': 'chest', 'chest2': 'chest',
  'shoulder1': 'shoulders', 'shoulder2': 'shoulders',
  'shoulder3': 'shoulders', 'shoulder4': 'shoulders',
  'obliques1': 'obliques', 'obliques2': 'obliques',
  'abs1': 'abs', 'abs2': 'abs', 'abs3': 'abs', 'abs4': 'abs',
  'abs5': 'abs', 'abs6': 'abs', 'abs7': 'abs', 'abs8': 'abs',
  'abductor1': 'abductor', 'abductor2': 'abductor',
  'biceps1': 'biceps', 'biceps2': 'biceps',
  'calves1': 'calves', 'calves2': 'calves',
  'calves3': 'calves', 'calves4': 'calves',
  'forearm1': 'forearm', 'forearm2': 'forearm',
  'forearm3': 'forearm', 'forearm4': 'forearm',
  'glutes1': 'glutes', 'glutes2': 'glutes',
  'harmstrings1': 'harmstrings', 'harmstrings2': 'harmstrings',
  'lats1': 'lats', 'lats2': 'lats',
  'upper_back1': 'upper_back', 'upper_back2': 'upper_back',
  'quads1': 'quads', 'quads2': 'quads',
  'quads3': 'quads', 'quads4': 'quads',
  'trapezius1': 'trapezius', 'trapezius2': 'trapezius',
  'trapezius3': 'trapezius', 'trapezius4': 'trapezius',
  'trapezius5': 'trapezius',
  'triceps1': 'triceps', 'triceps2': 'triceps',
  'adductors1': 'adductors', 'adductors2': 'adductors',
  'lower_back': 'lower_back',
  'neck': 'neck',
};

/// Parsed SVG geometry — the body outline plus every named muscle path.
class _ParsedBody {
  final Path outline;
  final Map<String, Path> musclePaths;
  const _ParsedBody(this.outline, this.musclePaths);
}

/// Process-wide cache of the parsed SVG. The share gallery builds several
/// templates eagerly (and the Muscles card alone needs two figures), so we
/// parse `Maps.BODY` exactly once and reuse the geometry for every figure.
Future<_ParsedBody>? _bodyParseFuture;

Future<_ParsedBody> _parseBody() {
  return _bodyParseFuture ??= () async {
    final list = await Parser.instance.svgToMuscleList(Maps.BODY);
    Path? outline;
    final paths = <String, Path>{};
    for (final m in list) {
      if (m.id == 'human_body') {
        outline = m.path;
      } else {
        paths[m.id] = m.path;
      }
    }
    if (outline == null) {
      throw StateError('human_body outline missing from Maps.BODY');
    }
    return _ParsedBody(outline, paths);
  }();
}

/// Anatomical body silhouette with muscle groups heat-coded from a
/// `muscle name → set count` map. Cool (1 set) → warm (most-trained group),
/// accent-tinted. Untrained groups render as a faint ghost fill so the
/// figure always reads as a body, not a scatter of blobs.
class AnatomicalFigure extends StatelessWidget {
  /// Primary muscle name → working-set count (e.g. `{'chest': 6, 'lats': 4}`).
  /// Rendered on the full heat ramp.
  final Map<String, int> muscles;

  /// Secondary / synergist muscle name → working-set count. Rendered at a
  /// dim, flat intensity so primary movers visually dominate.
  final Map<String, int> secondaryMuscles;

  /// Highest set count in [muscles] — drives the top of the heat ramp.
  /// Pass 1 when [muscles] is empty so the painter never divides by zero.
  final int maxCount;

  final Color accent;
  final BodyView view;

  const AnatomicalFigure({
    super.key,
    required this.muscles,
    required this.maxCount,
    required this.accent,
    this.secondaryMuscles = const {},
    this.view = BodyView.dual,
  });

  /// Resolve a muscle_selector package group (e.g. "biceps", "harmstrings")
  /// to a set count out of [src]. Looks the group up via the reverse of
  /// [backendMuscleToPackageGroup] AND a raw substring match so spellings
  /// like "hamstrings" still resolve to the "harmstrings" SVG group.
  int _resolve(Map<String, int> src, String packageGroup) {
    if (src.isEmpty) return 0;
    String? backendKey;
    for (final entry in backendMuscleToPackageGroup.entries) {
      if (entry.value == packageGroup) {
        backendKey = entry.key;
        break;
      }
    }
    int? hit;
    if (backendKey != null && src.containsKey(backendKey)) {
      hit = src[backendKey];
    }
    if (hit == null) {
      for (final e in src.entries) {
        if (e.key.toLowerCase().contains(packageGroup)) {
          hit = e.value;
          break;
        }
      }
    }
    return hit ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ParsedBody>(
      future: _parseBody(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Loading / parse-failure: render nothing rather than a spinner.
          // The share gallery builds templates well before capture, so the
          // SVG is parsed in time; if it genuinely fails the surrounding
          // template (legend chips / exercise list) still carries the data.
          return view == BodyView.dual
              ? const AspectRatio(aspectRatio: 0.85, child: SizedBox())
              : const SizedBox.expand();
        }
        final body = snapshot.data!;
        final painter = CustomPaint(
          painter: _FigurePainter(
            outline: body.outline,
            musclePaths: body.musclePaths,
            countForGroup: (g) => _resolve(muscles, g),
            secondaryCountForGroup: (g) => _resolve(secondaryMuscles, g),
            maxCount: maxCount <= 0 ? 1 : maxCount,
            accent: accent,
            view: view,
          ),
          child: const SizedBox.expand(),
        );
        // Dual keeps the original ~1:1 (two figures side-by-side) ratio so
        // MuscleMap is pixel-unchanged. front/back fill whatever box the
        // caller hands them (typically an Expanded inside a Column).
        return view == BodyView.dual
            ? AspectRatio(aspectRatio: 0.85, child: painter)
            : painter;
      },
    );
  }
}

class _FigurePainter extends CustomPainter {
  final Path outline;
  final Map<String, Path> musclePaths;
  final int Function(String packageGroup) countForGroup;
  final int Function(String packageGroup) secondaryCountForGroup;
  final int maxCount;
  final Color accent;
  final BodyView view;

  _FigurePainter({
    required this.outline,
    required this.musclePaths,
    required this.countForGroup,
    required this.secondaryCountForGroup,
    required this.maxCount,
    required this.accent,
    required this.view,
  });

  Color _heatColor(int count) {
    if (count <= 0) return Colors.white.withValues(alpha: 0.07);
    final t = (count / maxCount).clamp(0.0, 1.0);
    // Bottom of the ramp is the accent at low alpha so a single set still
    // reads as "lit"; a top-trained group looks dramatically hotter.
    return Color.lerp(accent.withValues(alpha: 0.30), accent, t)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final svgBounds = outline.getBounds();

    // Pick the slice of the SVG to render. front = left half, back = right
    // half (confirmed from human_body.svg: chest/quads/biceps sit at low x,
    // lats/glutes/hamstrings at high x, with a wide empty gutter between).
    final midX = svgBounds.center.dx;
    final Rect sub;
    switch (view) {
      case BodyView.dual:
        sub = svgBounds;
        break;
      case BodyView.front:
        sub = Rect.fromLTRB(
            svgBounds.left, svgBounds.top, midX, svgBounds.bottom);
        break;
      case BodyView.back:
        sub = Rect.fromLTRB(
            midX, svgBounds.top, svgBounds.right, svgBounds.bottom);
        break;
    }

    const padding = 4.0;
    final availableWidth = size.width - 2 * padding;
    final availableHeight = size.height - 2 * padding;
    if (availableWidth <= 0 || availableHeight <= 0 || sub.isEmpty) return;

    final scale = math.min(
      availableWidth / sub.width,
      availableHeight / sub.height,
    );
    final destWidth = sub.width * scale;
    final destHeight = sub.height * scale;
    final dest = Rect.fromLTWH(
      (size.width - destWidth) / 2,
      (size.height - destHeight) / 2,
      destWidth,
      destHeight,
    );

    // Map sub-rect → dest. The other figure (the un-selected half) maps
    // outside `dest` and is removed by the clip below.
    final tx = dest.left - sub.left * scale;
    final ty = dest.top - sub.top * scale;
    final matrix = Float64List(16)
      ..[0] = scale
      ..[5] = scale
      ..[10] = 1.0
      ..[12] = tx
      ..[13] = ty
      ..[15] = 1.0;

    canvas.save();
    // inflate(3) keeps the kept figure's outline stroke from being clipped
    // at the edges without revealing the other figure (the SVG gutter
    // between the two figures is far wider than 3px once scaled).
    canvas.clipRect(dest.inflate(3));

    // 1) Ghost fill — every muscle at low alpha so the silhouette reads as
    // a soft figure regardless of which groups have data.
    final ghostFill = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    for (final path in musclePaths.values) {
      canvas.drawPath(path.transform(matrix), ghostFill);
    }

    // 2) Heat fill — primary movers on the full accent ramp; secondary
    // movers a dim, flat tint so the eye lands on what was worked hardest.
    final primaryCounts = <String, int>{};
    final secondaryCounts = <String, int>{};
    for (final group in kBodyPathIdToGroup.values) {
      primaryCounts.putIfAbsent(group, () => countForGroup(group));
      secondaryCounts.putIfAbsent(group, () => secondaryCountForGroup(group));
    }
    final secondaryPaint = Paint()
      ..color = accent.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    for (final entry in musclePaths.entries) {
      final group = kBodyPathIdToGroup[entry.key];
      if (group == null) continue;
      final transformed = entry.value.transform(matrix);
      final primary = primaryCounts[group] ?? 0;
      if (primary > 0) {
        canvas.drawPath(
          transformed,
          Paint()
            ..color = _heatColor(primary)
            ..style = PaintingStyle.fill,
        );
      } else if ((secondaryCounts[group] ?? 0) > 0) {
        canvas.drawPath(transformed, secondaryPaint);
      }
    }

    // 3) Body outline on top so the silhouette edge stays crisp.
    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(outline.transform(matrix), outlinePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FigurePainter old) =>
      old.maxCount != maxCount ||
      old.accent != accent ||
      old.view != view ||
      old.musclePaths != musclePaths;
}
