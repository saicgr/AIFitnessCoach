import 'dart:math' as math;
import 'dart:typed_data';
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

/// Anatomical anchor (x, y) for each muscle-group strength pill, expressed
/// as a fraction of the body panel's width and height.
///
/// Mirrors the approach in `measurement_body_view.dart`'s `_bodyAnchor` but
/// keyed by the 12 MUSCLE GROUPS the strength-score backend returns (keys
/// match `backendMuscleToPackageGroup`'s package-group values). The SVG is
/// a front + back dual-view silhouette (`muscle_selector`'s Maps.BODY), so
/// left-half anchors sit on the front view and right-half anchors on the
/// back view — matching how users mentally map chest → front, traps → back.
///
/// Keys are `muscle_selector` PACKAGE group names (lowercase, includes the
/// package's misspelling 'harmstrings'). Resolved to backend muscle names
/// via `packageGroupToBackendMuscle` when calling `onTapMuscle`.
const Map<String, Offset> _strengthAnchor = {
  // Front view (left half of the dual SVG, roughly x < 0.5).
  'chest':        Offset(0.25, 0.22),
  'shoulders':    Offset(0.11, 0.18),
  'biceps':       Offset(0.07, 0.30),
  'forearm':      Offset(0.05, 0.42),
  'abs':          Offset(0.25, 0.36),
  'quads':        Offset(0.19, 0.62),
  // Back view (right half of the dual SVG, roughly x > 0.5).
  'trapezius':    Offset(0.75, 0.15),
  'triceps':      Offset(0.93, 0.30),
  'upper_back':   Offset(0.75, 0.28),
  'glutes':       Offset(0.75, 0.50),
  'harmstrings':  Offset(0.81, 0.64),
  'calves':       Offset(0.81, 0.84),
};

/// A body diagram that renders a ghost-tinted silhouette (front + back)
/// and overlays a floating muscle-score pill on each major group at its
/// anatomical position. Supersedes the old badge-dot painter look.
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

    Widget bodyLayer = LayoutBuilder(
      builder: (context, constraints) {
        final paintSize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        // Ghost silhouette — low-alpha CustomPaint so the body reads as a
        // soft faded backdrop, with the pill layer carrying all information.
        Widget silhouette = CustomPaint(
          size: paintSize,
          painter: _GhostSilhouettePainter(
            bodyOutlinePath: _bodyOutlinePath!,
            musclePaths: _musclePaths,
            isDark: widget.isDark,
          ),
        );
        if (widget.interactive) {
          silhouette = GestureDetector(
            onTapDown: (details) => _handleTap(details, paintSize),
            child: silhouette,
          );
        }

        // Unclipped pill layer — edge-anchored pills (e.g. biceps at x=0.07,
        // triceps at x=0.93) must render outside the body rect without being
        // clipped. Mirror the `Stack(clipBehavior: Clip.none)` pattern from
        // MeasurementBodyView.
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: silhouette),
            for (final entry in _strengthAnchor.entries)
              _positionedPillFor(
                packageGroup: entry.key,
                anchor: entry.value,
                w: constraints.maxWidth,
                h: constraints.maxHeight,
              ),
          ],
        );
      },
    );

    if (widget.interactive) {
      bodyLayer = InteractiveViewer(
        minScale: 0.8,
        maxScale: 2.5,
        clipBehavior: Clip.none,
        child: bodyLayer,
      );
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: bodyLayer,
    );
  }

  /// Resolve a package-group anchor to its backend score/status and emit a
  /// positioned pill centered on the anchor. Returns a `SizedBox.shrink()`
  /// Positioned if the muscle isn't scored — still rendered so tapping the
  /// anatomical region hits the ghost silhouette underneath.
  Widget _positionedPillFor({
    required String packageGroup,
    required Offset anchor,
    required double w,
    required double h,
  }) {
    final backendName = packageGroupToBackendMuscle[packageGroup];
    final score = backendName == null ? null : widget.muscleScores[backendName];
    final status =
        backendName == null ? null : widget.muscleStatuses?[backendName];

    return Positioned(
      top: anchor.dy * h,
      left: anchor.dx * w,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: _StrengthPill(
          packageGroup: packageGroup,
          backendName: backendName,
          score: score,
          status: status,
          isDark: widget.isDark,
          interactive: widget.interactive,
          onTap: widget.onTapMuscle,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ghost silhouette painter — low-alpha body outline + muscle paths so the
// figure reads as a soft backdrop, not a data chart.
// ---------------------------------------------------------------------------

class _GhostSilhouettePainter extends CustomPainter {
  final Path bodyOutlinePath;
  final Map<String, Path> musclePaths;
  final bool isDark;

  _GhostSilhouettePainter({
    required this.bodyOutlinePath,
    required this.musclePaths,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
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

    // Ghost fill — every muscle painted at α 0.25 so the silhouette reads
    // as a soft tinted figure. Matches the `_ghostTint` mood used by
    // measurement_body_view.dart.
    final ghostFill = Paint()
      ..color = (isDark ? const Color(0xFF1F2937) : Colors.black)
          .withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    for (final path in musclePaths.values) {
      canvas.drawPath(path.transform(matrix), ghostFill);
    }

    // Body outline on top — slightly darker so the silhouette edge is
    // readable on both light and dark backgrounds.
    final outlinePaint = Paint()
      ..color =
          (isDark ? Colors.white : Colors.black).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(bodyOutlinePath.transform(matrix), outlinePaint);
  }

  @override
  bool shouldRepaint(_GhostSilhouettePainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.bodyOutlinePath != bodyOutlinePath ||
        oldDelegate.musclePaths != musclePaths;
  }
}

// ---------------------------------------------------------------------------
// Strength pill — capsule chip styled like `_DerivedMetricPill` in
// measurement_body_view.dart. Renders: [icon] [short name] [score] [trend].
// ---------------------------------------------------------------------------

/// Human-readable short labels for each package-group key.
const Map<String, String> _groupShortName = {
  'chest': 'Chest',
  'shoulders': 'Shoulders',
  'biceps': 'Biceps',
  'triceps': 'Triceps',
  'forearm': 'Forearm',
  'abs': 'Core',
  'upper_back': 'Back',
  'trapezius': 'Traps',
  'glutes': 'Glutes',
  'quads': 'Quads',
  'harmstrings': 'Hams',
  'calves': 'Calves',
};

IconData _iconForGroup(String group) {
  switch (group) {
    case 'chest':
      return Icons.accessibility_new;
    case 'shoulders':
    case 'trapezius':
      return Icons.accessibility;
    case 'biceps':
    case 'triceps':
      return Icons.fitness_center;
    case 'forearm':
      return Icons.back_hand;
    case 'abs':
      return Icons.center_focus_strong;
    case 'upper_back':
      return Icons.airline_seat_recline_extra;
    case 'glutes':
      return Icons.airline_seat_legroom_extra;
    case 'quads':
      return Icons.directions_walk;
    case 'harmstrings':
      return Icons.directions_run;
    case 'calves':
      return Icons.directions_run;
    default:
      return Icons.fitness_center;
  }
}

class _StrengthPill extends StatelessWidget {
  final String packageGroup;
  final String? backendName;
  final StrengthScoreData? score;
  final MuscleStatus? status;
  final bool isDark;
  final bool interactive;
  final Function(String muscleGroup)? onTap;

  const _StrengthPill({
    required this.packageGroup,
    required this.backendName,
    required this.score,
    required this.status,
    required this.isDark,
    required this.interactive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final hasData = score != null;
    final accent = hasData ? Color(score!.levelColor) : textMuted;
    final borderColor =
        hasData ? accent.withValues(alpha: 0.4) : cardBorder;

    // Adaptive sizing — pills can grow with text scaler but clamp so they
    // don't collide with paired anchors on narrow devices.
    final scaler = MediaQuery.textScalerOf(context);
    final labelSize = scaler.scale(9.5).clamp(9.5, 12.0);
    final valueSize = scaler.scale(10.5).clamp(10.5, 13.5);

    final pill = Container(
      padding: const EdgeInsets.fromLTRB(6, 2, 4, 2),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForGroup(packageGroup), size: 11, color: accent),
          const SizedBox(width: 3),
          Text(
            _groupShortName[packageGroup] ?? packageGroup,
            style: TextStyle(
              fontSize: labelSize.toDouble(),
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            hasData ? score!.strengthScore.toString() : '—',
            style: TextStyle(
              fontSize: valueSize.toDouble(),
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          if (status != null) ...[
            const SizedBox(width: 3),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: status!.color.withValues(alpha: 0.18),
              ),
              child: Icon(status!.icon, size: 10, color: status!.color),
            ),
          ],
        ],
      ),
    );

    // Share templates (interactive==false) get a static pill with no press
    // feedback so exported images don't show ripple / tap highlights.
    if (!interactive || onTap == null || backendName == null) {
      return pill;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap!(backendName!),
      child: pill,
    );
  }
}
