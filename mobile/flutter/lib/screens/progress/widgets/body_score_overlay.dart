import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:muscle_selector/muscle_selector.dart';
import 'package:muscle_selector/src/parser.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/muscle_status.dart';
import '../../../data/models/scores.dart';
import '../../../widgets/body_muscle_selector.dart';

/// SVG path ID to muscle group mapping.
/// Copied from body_muscle_selector.dart (local to getMuscleGroupFromMuscle).
const Map<String, List<String>> _muscleGroupPathIds = {
  'chest': ['chest1', 'chest2'],
  'shoulders': ['shoulder1', 'shoulder2', 'shoulder3', 'shoulder4'],
  'obliques': ['obliques1', 'obliques2'],
  'abs': ['abs1', 'abs2', 'abs3', 'abs4', 'abs5', 'abs6', 'abs7', 'abs8'],
  'abductor': ['abductor1', 'abductor2'],
  'biceps': ['biceps1', 'biceps2'],
  'calves': ['calves1', 'calves2', 'calves3', 'calves4'],
  'forearm': ['forearm1', 'forearm2', 'forearm3', 'forearm4'],
  'glutes': ['glutes1', 'glutes2'],
  'harmstrings': ['harmstrings1', 'harmstrings2'],
  'lats': ['lats1', 'lats2'],
  'upper_back': ['upper_back1', 'upper_back2'],
  'quads': ['quads1', 'quads2', 'quads3', 'quads4'],
  'trapezius': [
    'trapezius1',
    'trapezius2',
    'trapezius3',
    'trapezius4',
    'trapezius5',
  ],
  'triceps': ['triceps1', 'triceps2'],
  'adductors': ['adductors1', 'adductors2'],
  'lower_back': ['lower_back'],
  'neck': ['neck'],
};

/// Reverse lookup: SVG path ID -> package group name.
final Map<String, String> _pathIdToGroup = () {
  final map = <String, String>{};
  for (final entry in _muscleGroupPathIds.entries) {
    for (final id in entry.value) {
      map[id] = entry.key;
    }
  }
  return map;
}();

/// A CustomPaint widget that renders a human body diagram (front + back)
/// with strength score badges overlaid on each scored muscle group.
class BodyScoreOverlay extends StatefulWidget {
  final Map<String, StrengthScoreData> muscleScores;
  final Map<String, MuscleStatus>? muscleStatuses;
  final Function(String muscleGroup)? onTapMuscle;
  final double height;
  final bool isDark;

  /// When false, disables InteractiveViewer, GestureDetector, and hint text.
  /// Used for share templates where the diagram should be static.
  final bool interactive;

  const BodyScoreOverlay({
    super.key,
    required this.muscleScores,
    this.muscleStatuses,
    this.onTapMuscle,
    this.height = 380,
    this.isDark = false,
    this.interactive = true,
  });

  @override
  State<BodyScoreOverlay> createState() => _BodyScoreOverlayState();
}

class _BodyScoreOverlayState extends State<BodyScoreOverlay> {
  Path? _bodyOutlinePath;
  Map<String, Path> _musclePaths = {}; // keyed by SVG path id (e.g. 'chest1')
  bool _pathsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMusclePaths();
  }

  Future<void> _loadMusclePaths() async {
    try {
      final muscles = await Parser.instance.svgToMuscleList(Maps.BODY);
      if (!mounted) return;

      Path? bodyOutline;
      final musclePaths = <String, Path>{};

      for (final muscle in muscles) {
        if (muscle.id == 'human_body') {
          bodyOutline = muscle.path;
        } else {
          musclePaths[muscle.id] = muscle.path;
        }
      }

      if (bodyOutline != null) {
        setState(() {
          _bodyOutlinePath = bodyOutline;
          _musclePaths = musclePaths;
          _pathsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to load muscle SVG paths: $e');
    }
  }

  /// Build the affine transform matrix that maps SVG coordinates to widget coordinates.
  Float64List _buildMatrix(Size size) {
    final svgBounds = _bodyOutlinePath!.getBounds();
    const padding = 4.0;
    final availableWidth = size.width - 2 * padding;
    final availableHeight = size.height - 2 * padding;

    final scaleX = availableWidth / svgBounds.width;
    final scaleY = availableHeight / svgBounds.height;
    final scale = math.min(scaleX, scaleY);

    final scaledWidth = svgBounds.width * scale;
    final scaledHeight = svgBounds.height * scale;

    final tx = (size.width - scaledWidth) / 2 - svgBounds.left * scale;
    final ty = (size.height - scaledHeight) / 2 - svgBounds.top * scale;

    return Float64List(16)
      ..[0] = scale
      ..[5] = scale
      ..[10] = 1.0
      ..[12] = tx
      ..[13] = ty
      ..[15] = 1.0;
  }

  /// Inverse-transform a local position back into SVG coordinates for hit testing.
  Offset _invertPoint(Offset local, Float64List matrix) {
    final scale = matrix[0];
    final tx = matrix[12];
    final ty = matrix[13];
    return Offset((local.dx - tx) / scale, (local.dy - ty) / scale);
  }

  void _handleTap(TapDownDetails details, Size paintSize) {
    if (!_pathsLoaded || _bodyOutlinePath == null) return;
    if (widget.onTapMuscle == null) return;

    final matrix = _buildMatrix(paintSize);
    final svgPoint = _invertPoint(details.localPosition, matrix);

    // Check each muscle path for containment
    for (final entry in _musclePaths.entries) {
      if (entry.value.contains(svgPoint)) {
        // Map SVG path id -> package group name -> backend muscle name
        final packageGroup = _pathIdToGroup[entry.key];
        if (packageGroup != null) {
          final backendName = packageGroupToBackendMuscle[packageGroup];
          if (backendName != null) {
            widget.onTapMuscle!(backendName);
            return;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textMuted =
        widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    if (!_pathsLoaded || _bodyOutlinePath == null) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: widget.isDark ? AppColors.cyan : AppColorsLight.cyan,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Loading body diagram...',
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
            ],
          ),
        ),
      );
    }

    Widget bodyPaint = LayoutBuilder(
      builder: (context, constraints) {
        final paintSize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        Widget paint = CustomPaint(
          size: paintSize,
          painter: _BodyScorePainter(
            bodyOutlinePath: _bodyOutlinePath!,
            musclePaths: _musclePaths,
            muscleScores: widget.muscleScores,
            muscleStatuses: widget.muscleStatuses,
            isDark: widget.isDark,
          ),
        );
        if (widget.interactive) {
          paint = GestureDetector(
            onTapDown: (details) => _handleTap(details, paintSize),
            child: paint,
          );
        }
        return paint;
      },
    );

    if (widget.interactive) {
      bodyPaint = InteractiveViewer(
        minScale: 0.8,
        maxScale: 2.5,
        child: bodyPaint,
      );
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: bodyPaint,
    );
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _BodyScorePainter extends CustomPainter {
  final Path bodyOutlinePath;
  final Map<String, Path> musclePaths;
  final Map<String, StrengthScoreData> muscleScores;
  final Map<String, MuscleStatus>? muscleStatuses;
  final bool isDark;

  _BodyScorePainter({
    required this.bodyOutlinePath,
    required this.musclePaths,
    required this.muscleScores,
    this.muscleStatuses,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ---- transform setup ----
    final svgBounds = bodyOutlinePath.getBounds();
    const padding = 4.0;
    final availableWidth = size.width - 2 * padding;
    final availableHeight = size.height - 2 * padding;

    final scaleX = availableWidth / svgBounds.width;
    final scaleY = availableHeight / svgBounds.height;
    final scale = math.min(scaleX, scaleY);

    final scaledWidth = svgBounds.width * scale;
    final scaledHeight = svgBounds.height * scale;

    final tx = (size.width - scaledWidth) / 2 - svgBounds.left * scale;
    final ty = (size.height - scaledHeight) / 2 - svgBounds.top * scale;

    final matrix = Float64List(16)
      ..[0] = scale
      ..[5] = scale
      ..[10] = 1.0
      ..[12] = tx
      ..[13] = ty
      ..[15] = 1.0;

    // ---- collect scored & unscored paths ----
    // Build set of path IDs that belong to scored muscle groups.
    final scoredPathIds = <String>{};
    // Map: package group name -> StrengthScoreData
    final groupScoreMap = <String, StrengthScoreData>{};

    for (final entry in muscleScores.entries) {
      final backendName = entry.key;
      final packageGroup = backendMuscleToPackageGroup[backendName];
      if (packageGroup == null) continue;
      groupScoreMap[packageGroup] = entry.value;
      final pathIds = _muscleGroupPathIds[packageGroup];
      if (pathIds != null) {
        scoredPathIds.addAll(pathIds);
      }
    }

    // ---- draw unscored muscles (neutral outline) ----
    final unscoredPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final entry in musclePaths.entries) {
      if (!scoredPathIds.contains(entry.key)) {
        canvas.drawPath(entry.value.transform(matrix), unscoredPaint);
      }
    }

    // SVG midpoint separates front (left) and back (right) body views.
    final svgMidX = svgBounds.center.dx;

    // ---- draw scored muscle groups (filled + badge per body view) ----
    for (final groupEntry in groupScoreMap.entries) {
      final packageGroup = groupEntry.key;
      final scoreData = groupEntry.value;
      final pathIds = _muscleGroupPathIds[packageGroup];
      if (pathIds == null) continue;

      final fillColor =
          Color(scoreData.levelColor).withValues(alpha: 0.35);
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;

      // Separate paths by body view (front = left half, back = right half)
      Rect? frontBounds;
      Rect? backBounds;

      for (final id in pathIds) {
        final rawPath = musclePaths[id];
        if (rawPath == null) continue;
        final transformedPath = rawPath.transform(matrix);
        canvas.drawPath(transformedPath, fillPaint);

        final rawCenterX = rawPath.getBounds().center.dx;
        final tBounds = transformedPath.getBounds();

        if (rawCenterX < svgMidX) {
          frontBounds = frontBounds == null
              ? tBounds
              : frontBounds.expandToInclude(tBounds);
        } else {
          backBounds = backBounds == null
              ? tBounds
              : backBounds.expandToInclude(tBounds);
        }
      }

      // Draw badge + status bar for each body view that has paths
      for (final viewBounds in [frontBounds, backBounds]) {
        if (viewBounds == null) continue;
        _drawScoreBadge(
          canvas,
          viewBounds.center,
          scoreData.strengthScore,
          Color(scoreData.levelColor),
        );

        if (muscleStatuses != null) {
          final backendName = packageGroupToBackendMuscle[packageGroup];
          if (backendName != null) {
            final status = muscleStatuses![backendName];
            if (status != null) {
              _drawStatusBar(canvas, viewBounds.center, status);
            }
          }
        }
      }
    }

    // ---- body outline on top ----
    final outlinePaint = Paint()
      ..color =
          (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(bodyOutlinePath.transform(matrix), outlinePaint);
  }

  /// Draws a small rounded-rect badge with the score number.
  void _drawScoreBadge(
      Canvas canvas, Offset center, int score, Color badgeColor) {
    const badgeWidth = 28.0;
    const badgeHeight = 18.0;
    const borderRadius = 9.0;

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: center, width: badgeWidth, height: badgeHeight),
      const Radius.circular(borderRadius),
    );

    // Badge background
    final bgPaint = Paint()
      ..color = badgeColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rect, bgPaint);

    // Score text
    final textPainter = TextPainter(
      text: TextSpan(
        text: score.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  /// Draws a 5-segment status bar below the score badge.
  void _drawStatusBar(Canvas canvas, Offset badgeCenter, MuscleStatus status) {
    const segmentWidth = 4.0;
    const segmentHeight = 3.0;
    const gap = 1.0;
    const segmentCount = 5;
    const totalWidth =
        segmentCount * segmentWidth + (segmentCount - 1) * gap;

    final startX = badgeCenter.dx - totalWidth / 2;
    final topY = badgeCenter.dy + 12;

    final filledPaint = Paint()
      ..color = status.color
      ..style = PaintingStyle.fill;
    final emptyPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < segmentCount; i++) {
      final x = startX + i * (segmentWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, topY, segmentWidth, segmentHeight),
        const Radius.circular(1),
      );
      canvas.drawRRect(rect, i < status.filledSegments ? filledPaint : emptyPaint);
    }
  }

  @override
  bool shouldRepaint(_BodyScorePainter oldDelegate) {
    return oldDelegate.muscleScores != muscleScores ||
        oldDelegate.muscleStatuses != muscleStatuses ||
        oldDelegate.isDark != isDark;
  }
}
