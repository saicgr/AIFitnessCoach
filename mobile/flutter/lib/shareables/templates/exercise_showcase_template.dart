import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/app_watermark.dart';

/// ExerciseShowcase — hero exercise illustration full-bleed (uses real
/// imageUrl from the wired adapter), exercise name in massive type, sets/
/// reps/weight strip across the bottom, accent border. The "look at this
/// lift" format.
class ExerciseShowcaseTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const ExerciseShowcaseTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final ex = (data.exercises ?? const <ShareableExercise>[])
        .firstWhere((e) => e.sets.isNotEmpty,
            orElse: () => (data.exercises?.isNotEmpty ?? false)
                ? data.exercises!.first
                : const ShareableExercise(name: '—'));
    final sets = ex.sets;
    final topSet = sets.isEmpty
        ? null
        : sets.reduce((a, b) {
            final aw = (a.weight ?? 0) * a.reps;
            final bw = (b.weight ?? 0) * b.reps;
            return bw > aw ? b : a;
          });

    return ShareableCanvas(
      aspect: data.aspect,
      backgroundOverride: [
        const Color(0xFF000000),
        Color.lerp(accent, Colors.black, 0.7)!,
      ],
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed exercise illustration.
          Positioned.fill(
            child: ex.imageUrl != null
                ? Image.network(
                    ex.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(accent),
                  )
                : _placeholder(accent),
          ),
          // Vertical scrim.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Accent border.
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: accent, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 80, 36, 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'EXERCISE OF THE DAY',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 11 * mul,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.4,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  ex.name.toUpperCase(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: data.aspect == ShareableAspect.story ? 64 : 48,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                    letterSpacing: -1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.7),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (topSet != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        _setStat('SETS', sets.length.toString(), mul),
                        Container(
                          width: 1,
                          height: 28,
                          color: Colors.white.withValues(alpha: 0.20),
                        ),
                        _setStat('REPS', '${topSet.reps}', mul),
                        if (topSet.weight != null) ...[
                          Container(
                            width: 1,
                            height: 28,
                            color: Colors.white.withValues(alpha: 0.20),
                          ),
                          _setStat(
                            'TOP WEIGHT',
                            '${topSet.weight!.round()} ${topSet.unit}',
                            mul,
                          ),
                        ],
                      ],
                    ),
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
        ],
      ),
    );
  }

  Widget _setStat(String label, String value, double mul) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22 * mul,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10 * mul,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(Color accent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent,
            Color.lerp(accent, Colors.black, 0.7)!,
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.fitness_center_rounded,
            color: Colors.white24, size: 200),
      ),
    );
  }
}
