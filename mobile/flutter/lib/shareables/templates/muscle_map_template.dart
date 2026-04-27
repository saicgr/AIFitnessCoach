import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:muscle_selector/muscle_selector.dart';
import 'package:muscle_selector/src/parser.dart';

import '../../widgets/body_muscle_selector.dart' show backendMuscleToPackageGroup;
import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

/// MuscleMap — anatomical front silhouette with muscle groups heat-coded
/// from `data.musclesWorked`. Sparkle accent. Spark category — synthesizes
/// raw set data into a single glanceable visual ("you trained your back
/// 4× this week, chest 2×, legs 1×").
class MuscleMapTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const MuscleMapTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final muscles = data.musclesWorked ?? const <String, int>{};
    final maxCount = muscles.values.fold<int>(0, math.max);
    final top = muscles.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topThree = top.take(3).toList();

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: [
        const Color(0xFF06080F),
        Color.lerp(accent, const Color(0xFF06080F), 0.85)!,
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 80, 36, 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 18 * mul, color: accent),
                const SizedBox(width: 8),
                Text(
                  'MUSCLE MAP',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13 * mul,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const Spacer(),
                Text(
                  data.periodLabel.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11 * mul,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26 * mul,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              muscles.isEmpty
                  ? 'Trained the body. Volume is on the board.'
                  : '${muscles.length} groups trained · top: ${topThree.first.key}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13 * mul,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: _AnatomicalBody(
                  muscles: muscles,
                  maxCount: maxCount == 0 ? 1 : maxCount,
                  accent: accent,
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (topThree.isNotEmpty)
              Row(
                children: [
                  for (var i = 0; i < topThree.length; i++) ...[
                    Expanded(
                      child: _legendChip(
                        topThree[i].key,
                        topThree[i].value,
                        accent,
                        mul,
                      ),
                    ),
                    if (i < topThree.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            const SizedBox(height: 18),
            if (showWatermark)
              AppWatermark(
                textColor: Colors.white,
                fontSize: 13 * mul,
              ),
          ],
        ),
      ),
    );
  }

  Widget _legendChip(String name, int count, Color accent, double mul) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 10 * mul,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22 * mul,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                count == 1 ? 'set' : 'sets',
                style: TextStyle(
                  color: accent,
                  fontSize: 11 * mul,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// SVG path id → muscle_selector "package group" name. Mirrors the
/// internal grouping in body_score_overlay.dart's _pathIdToGroup so a
/// single chest path turns the whole pec region red, both biceps paths
/// share one heat value, etc.
const Map<String, String> _pathIdToGroup = {
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

/// Anatomical front + back body silhouette with heat-coded muscle groups.
/// Replaces the old hand-painted blocky stick figure that users were
/// rightfully calling out as wrong-looking.
class _AnatomicalBody extends StatefulWidget {
  final Map<String, int> muscles;
  final int maxCount;
  final Color accent;

  const _AnatomicalBody({
    required this.muscles,
    required this.maxCount,
    required this.accent,
  });

  @override
  State<_AnatomicalBody> createState() => _AnatomicalBodyState();
}

class _AnatomicalBodyState extends State<_AnatomicalBody> {
  Path? _bodyOutline;
  Map<String, Path> _musclePaths = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await Parser.instance.svgToMuscleList(Maps.BODY);
      if (!mounted) return;
      Path? outline;
      final paths = <String, Path>{};
      for (final m in list) {
        if (m.id == 'human_body') {
          outline = m.path;
        } else {
          paths[m.id] = m.path;
        }
      }
      if (outline != null) {
        setState(() {
          _bodyOutline = outline;
          _musclePaths = paths;
        });
      }
    } catch (_) {
      // Leave the silhouette empty — the legend chips below still convey
      // the data; we just lose the visual.
    }
  }

  /// Resolve a muscle group name (e.g. "biceps", "harmstrings") to the
  /// number of sets logged. Looks the group up via the package mapping
  /// AND the raw backend key so spellings like "hamstrings" still match.
  int _countForGroup(String packageGroup) {
    // Reverse lookup: package group → backend muscle name.
    String? backendKey;
    for (final entry in backendMuscleToPackageGroup.entries) {
      if (entry.value == packageGroup) {
        backendKey = entry.key;
        break;
      }
    }
    int? hit;
    if (backendKey != null && widget.muscles.containsKey(backendKey)) {
      hit = widget.muscles[backendKey];
    }
    // Fallback: substring match against the package group name itself.
    if (hit == null) {
      for (final e in widget.muscles.entries) {
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
    if (_bodyOutline == null) {
      // Loading: render a soft accent halo so the share card isn't blank
      // mid-capture. Padding keeps the slot stable.
      return SizedBox(
        height: double.infinity,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.accent.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }
    return AspectRatio(
      // Front + back dual SVG is roughly 1:1 (two figures side-by-side).
      aspectRatio: 0.85,
      child: CustomPaint(
        painter: _BodyPainter(
          bodyOutline: _bodyOutline!,
          musclePaths: _musclePaths,
          countForGroup: _countForGroup,
          maxCount: widget.maxCount,
          accent: widget.accent,
        ),
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  final Path bodyOutline;
  final Map<String, Path> musclePaths;
  final int Function(String packageGroup) countForGroup;
  final int maxCount;
  final Color accent;

  _BodyPainter({
    required this.bodyOutline,
    required this.musclePaths,
    required this.countForGroup,
    required this.maxCount,
    required this.accent,
  });

  Color _heatColor(int count) {
    if (count <= 0) return Colors.white.withValues(alpha: 0.07);
    final t = (count / maxCount).clamp(0.0, 1.0);
    // Cool low → warm high; bottom of the ramp is the accent at low alpha
    // so a single set still reads as "lit", but a top-trained group looks
    // dramatically hotter.
    return Color.lerp(
      accent.withValues(alpha: 0.30),
      accent,
      t,
    )!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final svgBounds = bodyOutline.getBounds();
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

    // 1) Base ghost fill — every muscle painted at low alpha so the
    // silhouette reads as a soft figure regardless of which groups have
    // data.
    final ghostFill = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    for (final path in musclePaths.values) {
      canvas.drawPath(path.transform(matrix), ghostFill);
    }

    // 2) Heat fill — overlay each muscle group with an accent-tinted
    // color whose intensity scales with set count.
    final groupCounts = <String, int>{};
    for (final entry in _pathIdToGroup.entries) {
      groupCounts.putIfAbsent(entry.value, () => countForGroup(entry.value));
    }
    for (final entry in musclePaths.entries) {
      final group = _pathIdToGroup[entry.key];
      if (group == null) continue;
      final count = groupCounts[group] ?? 0;
      if (count <= 0) continue;
      final paint = Paint()
        ..color = _heatColor(count)
        ..style = PaintingStyle.fill;
      canvas.drawPath(entry.value.transform(matrix), paint);
    }

    // 3) Body outline on top so the silhouette edge stays crisp over the
    // heat fills.
    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(bodyOutline.transform(matrix), outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) =>
      old.maxCount != maxCount ||
      old.accent != accent ||
      old.musclePaths != musclePaths;
}
