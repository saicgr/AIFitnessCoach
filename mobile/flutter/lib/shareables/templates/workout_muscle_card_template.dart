import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../shareable_canvas.dart';
import '../shareable_data.dart';
import '../widgets/anatomical_figure.dart';
import '../widgets/app_watermark.dart';

/// "Muscles" — the Hevy-style workout share card.
///
/// Left column: workout name + a compact exercise list, each row prefixed
/// with its set count ("4x  Squat (Barbell)"). Right column: front + back
/// anatomical figures with the worked muscle groups heat-coded from
/// `data.musclesWorked`. This is the format users screenshot most — the
/// glanceable "what I trained + what it hit" card.
class WorkoutMuscleCardTemplate extends StatelessWidget {
  final Shareable data;
  final bool showWatermark;

  const WorkoutMuscleCardTemplate({
    super.key,
    required this.data,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final mul = data.aspect.bodyFontMultiplier;
    final accent = data.accentColor;
    final exercises = data.exercises ?? const <ShareableExercise>[];

    // Visible exercise cap by aspect — story (9:16) is tall and fits the
    // most, square (1:1) the least. The remainder collapses into a single
    // "…and N more" line so the list never overflows the card.
    final isStory = data.aspect == ShareableAspect.story;
    final isPortrait = data.aspect == ShareableAspect.portrait;
    final maxVisible = isStory
        ? 11
        : isPortrait
            ? 8
            : 6;
    final visible = exercises.take(maxVisible).toList();
    final overflow = exercises.length - visible.length;

    final muscles = data.musclesWorked ?? const <String, int>{};
    final secondaryMuscles =
        data.secondaryMusclesWorked ?? const <String, int>{};
    final maxCount = muscles.values.fold<int>(0, math.max);
    final user = data.userDisplayName?.trim();

    return ShareableCanvas(
      aspect: data.aspect,
      // Flat navy — deliberately not accent-tinted so the accent only
      // shows up where it carries meaning (the set-count numbers + the
      // muscle heat-map), mirroring the reference card.
      backgroundOverride: const [Color(0xFF0B1326), Color(0xFF080E1C)],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 60, 24, 38),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Left: title + exercise list + footer ──────────────────
            Expanded(
              flex: 58,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32 * mul,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 18 * mul),
                  Expanded(
                    child: visible.isEmpty
                        ? _emptyState(mul)
                        : _ExerciseList(
                            exercises: visible,
                            overflow: overflow,
                            accent: accent,
                            mul: mul,
                          ),
                  ),
                  SizedBox(height: 10 * mul),
                  _footer(mul, user),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // ─── Right: stacked front + back anatomy ───────────────────
            Expanded(
              flex: 42,
              child: Column(
                children: [
                  Expanded(
                    child: AnatomicalFigure(
                      view: BodyView.front,
                      muscles: muscles,
                      secondaryMuscles: secondaryMuscles,
                      maxCount: maxCount,
                      accent: accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: AnatomicalFigure(
                      view: BodyView.back,
                      muscles: muscles,
                      secondaryMuscles: secondaryMuscles,
                      maxCount: maxCount,
                      accent: accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer(double mul, String? user) {
    return Row(
      children: [
        if (showWatermark)
          const AppWatermark(
            textColor: Colors.white,
            iconSize: 26,
            fontSize: 15,
          ),
        const Spacer(),
        if (user != null && user.isNotEmpty)
          Text(
            '@$user',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13 * mul,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Widget _emptyState(double mul) {
    // Catalog gates this template on requiresExercises, so this should be
    // unreachable in practice — kept so a malformed payload renders a
    // clear message instead of a blank column.
    return Center(
      child: Text(
        'No exercises logged',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 14 * mul,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The compact "Nx  Exercise name" list. Set count is the number of logged
/// sets for the exercise; a 0-set exercise (planned-but-unlogged) renders
/// without a prefix rather than a fake "1x".
class _ExerciseList extends StatelessWidget {
  final List<ShareableExercise> exercises;
  final int overflow;
  final Color accent;
  final double mul;

  const _ExerciseList({
    required this.exercises,
    required this.overflow,
    required this.accent,
    required this.mul,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final ex in exercises)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6 * mul),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40 * mul,
                  child: Text(
                    ex.sets.isNotEmpty ? '${ex.sets.length}x' : '',
                    style: TextStyle(
                      color: accent,
                      fontSize: 19 * mul,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    ex.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 18 * mul,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (overflow > 0)
          Padding(
            padding: EdgeInsets.only(top: 8 * mul),
            child: Text(
              '...and $overflow more exercise${overflow == 1 ? '' : 's'}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 15 * mul,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
