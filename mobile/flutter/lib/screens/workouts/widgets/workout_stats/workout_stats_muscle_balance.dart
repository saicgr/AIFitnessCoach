part of 'workout_stats_section.dart';

/// 4. PUSH / PULL / LEGS / CORE MUSCLE BALANCE.
///
/// Groups `AllStrengthScores.muscleScores` weekly sets into four movement
/// groups via a deterministic name → group map, renders a horizontal bar per
/// group, and surfaces an imbalance alert (variant pool) when the largest group
/// has more than ~1.8x the weekly sets of the smallest non-empty group.
///
/// This gives the movement-pattern split (push vs pull vs legs vs core); the
/// per-muscle anatomical view lives in the separate body-diagram heatmap card
/// (`_BodyHeatmapCard`, which reuses the shared `AnatomicalFigure`).
class _MuscleBalanceCard extends ConsumerWidget {
  final bool isDark;
  final Color accent;

  const _MuscleBalanceCard({required this.isDark, required this.accent});

  // Deterministic name → movement-group map. Keys are matched as substrings of
  // the lowercased muscle-group name so backend variants ("front_delts",
  // "lats", "rear_delts") still route correctly.
  static const Map<String, List<String>> _groupMatchers = {
    'Push': ['chest', 'pec', 'shoulder', 'delt', 'tricep'],
    'Pull': ['back', 'lat', 'bicep', 'trap', 'rhomboid', 'forearm'],
    'Legs': ['quad', 'hamstring', 'glute', 'calf', 'calves', 'leg', 'adductor'],
    'Core': ['core', 'ab', 'oblique'],
  };

  static String? _groupFor(String muscleGroup) {
    final lower = muscleGroup.toLowerCase();
    for (final entry in _groupMatchers.entries) {
      for (final token in entry.value) {
        if (lower.contains(token)) return entry.key;
      }
    }
    return null;
  }

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
        child: const _CardSkeleton(height: 120),
      );
    }

    // Aggregate weekly sets per movement group.
    final groupSets = <String, int>{'Push': 0, 'Pull': 0, 'Legs': 0, 'Core': 0};
    for (final data in muscleScores.values) {
      final group = _groupFor(data.muscleGroup);
      if (group != null) {
        groupSets[group] = groupSets[group]! + data.weeklySets;
      }
    }

    final totalSets = groupSets.values.fold<int>(0, (a, b) => a + b);
    if (totalSets == 0) {
      return StatCardShell(
        isDark: isDark,
        child: Row(
          children: [
            Icon(Icons.balance_rounded, size: 22, color: textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Train this week to see how your push, pull, legs and core sets balance out.',
                style:
                    TextStyle(fontSize: 13, height: 1.35, color: textMuted),
              ),
            ),
          ],
        ),
      );
    }

    final maxSets =
        groupSets.values.fold<int>(0, (a, b) => a > b ? a : b);

    // Imbalance: compare the largest group to the smallest NON-EMPTY group.
    final nonEmpty =
        groupSets.entries.where((e) => e.value > 0).toList(growable: false);
    String? imbalanceAlert;
    if (nonEmpty.length >= 2) {
      nonEmpty.sort((a, b) => b.value.compareTo(a.value));
      final top = nonEmpty.first;
      final bottom = nonEmpty.last;
      if (bottom.value > 0) {
        final ratio = top.value / bottom.value;
        if (ratio > 1.8) {
          imbalanceAlert =
              _imbalanceCopy(top.key, bottom.key, ratio);
        }
      }
    }

    return StatCardShell(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.balance_rounded, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Muscle balance',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              Text(
                '$totalSets sets/wk',
                style: TextStyle(fontSize: 11.5, color: textMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...groupSets.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _GroupBar(
                  label: e.key,
                  sets: e.value,
                  maxSets: maxSets,
                  accent: accent,
                  isDark: isDark,
                ),
              )),
          if (imbalanceAlert != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.warning : AppColorsLight.warning)
                    .withValues(alpha: isDark ? 0.14 : 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 16,
                      color:
                          isDark ? AppColors.warning : AppColorsLight.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      imbalanceAlert,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Imbalance alert variant pool (>=4 variants), keyed by a stable bucket of
  /// the ratio so the copy reads human and the same data reads the same. The
  /// suggested fix is tailored to whichever group is lagging. No em dashes.
  static String _imbalanceCopy(String strong, String weak, double ratio) {
    final x = ratio.toStringAsFixed(1);
    final fix = _fixFor(weak);
    final variants = <String>[
      '$strong is ${x}x your $weak volume. $fix to even things out.',
      'Your $strong sets run ${x}x ahead of $weak. $fix this week.',
      'There is a ${x}x gap favouring $strong over $weak. $fix to rebalance.',
      '$weak is lagging at ${x}x less than $strong. $fix to close the gap.',
    ];
    final bucket = ((ratio - 1.8) * 10).round().clamp(0, 1000);
    return variants[bucket % variants.length];
  }

  static String _fixFor(String weakGroup) {
    switch (weakGroup) {
      case 'Pull':
        return 'Add a row or pulldown variation';
      case 'Push':
        return 'Add a press or pushup variation';
      case 'Legs':
        return 'Add a squat or hinge variation';
      case 'Core':
        return 'Add a plank or carry variation';
      default:
        return 'Add a set or two to your $weakGroup work';
    }
  }
}

class _GroupBar extends StatelessWidget {
  final String label;
  final int sets;
  final int maxSets;
  final Color accent;
  final bool isDark;

  const _GroupBar({
    required this.label,
    required this.sets,
    required this.maxSets,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final fraction = maxSets > 0 ? (sets / maxSets).clamp(0.0, 1.0) : 0.0;
    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.05);

    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 10, color: trackColor),
                FractionallySizedBox(
                  widthFactor: fraction == 0 ? 0.02 : fraction,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: sets == 0
                          ? textMuted.withValues(alpha: 0.4)
                          : accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 28,
          child: Text(
            '$sets',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: sets == 0 ? textMuted : textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
