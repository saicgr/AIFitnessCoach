part of 'workout_stats_section.dart';

/// 8. BODY-DIAGRAM HEATMAP.
///
/// Reuses the shared [AnatomicalFigure] (front + back SVG figures, heat-shaded
/// by working-set count) — the same figure the share gallery's muscle card
/// uses. Muscles trained more this week run hotter. This complements the
/// push/pull/legs/core bars (which give the movement-pattern split) with the
/// per-muscle anatomical view the user asked for.
///
/// Honest data only: keyed off `AllStrengthScores.muscleScores` weekly sets.
/// When there are no scored muscles yet it shows an explicit empty state, never
/// a blank or fabricated figure.
class _BodyHeatmapCard extends ConsumerWidget {
  final bool isDark;
  final Color accent;

  const _BodyHeatmapCard({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muscleScores = ref.watch(muscleScoresProvider);
    final scoresLoading = ref.watch(scoresLoadingProvider);

    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    if (muscleScores.isEmpty && scoresLoading) {
      return StatCardShell(
        isDark: isDark,
        child: const _CardSkeleton(height: 200),
      );
    }

    // muscle backend-name → weekly sets. AnatomicalFigure resolves these to its
    // SVG groups (handles backend spellings + substring fallbacks internally).
    final muscles = <String, int>{};
    var maxSets = 0;
    for (final data in muscleScores.values) {
      final sets = data.weeklySets;
      if (sets <= 0) continue;
      muscles[data.muscleGroup] = sets;
      if (sets > maxSets) maxSets = sets;
    }

    if (muscles.isEmpty) {
      return StatCardShell(
        isDark: isDark,
        child: Row(
          children: [
            Icon(Icons.accessibility_new_rounded, size: 22, color: textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Log a few sets to light up the muscles you have trained this week.',
                style: TextStyle(fontSize: 13, height: 1.35, color: textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return StatCardShell(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.accessibility_new_rounded, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Muscle heatmap',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              Text(
                'sets this week',
                style: TextStyle(fontSize: 11.5, color: textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: AnatomicalFigure(
                muscles: muscles,
                maxCount: maxSets,
                accent: accent,
                view: BodyView.dual,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Cool → hot legend so the shading is legible.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Less',
                  style: TextStyle(fontSize: 10.5, color: textMuted)),
              const SizedBox(width: 8),
              Container(
                width: 90,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.18),
                      accent,
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('More',
                  style: TextStyle(fontSize: 10.5, color: textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
