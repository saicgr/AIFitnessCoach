// Response shape for `GET /xp/weekly-summary` and `GET /xp/next-level-preview`.
// Hand-rolled (no codegen) — the surface is small and adding these to the
// json_serializable graph would force another `build_runner` pass which is
// pinned off per `project_codegen_gotcha.md`.

class WeeklyXpSummary {
  /// XP earned in the last 7 rolling days (inclusive of today).
  final int thisWeekXp;

  /// XP earned in the 7-day window BEFORE thisWeekXp — drives the delta chip.
  final int lastWeekXp;

  /// Seven values, oldest-first. `sparkline[0]` = six days ago, `[6]` = today.
  /// Server guarantees length 7 so the UI never has to pad.
  final List<int> sparkline7day;

  /// Short key the UI maps to a nudge string (e.g. "log_breakfast"). Empty
  /// string means no useful nudge is pending — hide the row in that case.
  final String nextNudge;

  const WeeklyXpSummary({
    required this.thisWeekXp,
    required this.lastWeekXp,
    required this.sparkline7day,
    required this.nextNudge,
  });

  factory WeeklyXpSummary.fromJson(Map<String, dynamic> json) {
    final raw = (json['sparkline_7day'] as List?) ?? const [];
    return WeeklyXpSummary(
      thisWeekXp: (json['this_week_xp'] as num?)?.toInt() ?? 0,
      lastWeekXp: (json['last_week_xp'] as num?)?.toInt() ?? 0,
      sparkline7day: raw.map((e) => (e as num?)?.toInt() ?? 0).toList(),
      nextNudge: json['next_nudge'] as String? ?? '',
    );
  }

  /// Delta vs last week. Positive = improving.
  int get delta => thisWeekXp - lastWeekXp;

  /// Delta as a percentage of last week. Guards against divide-by-zero
  /// (first week always shows a positive delta if any XP was earned).
  double? get deltaPercent {
    if (lastWeekXp <= 0) return null;
    return (delta / lastWeekXp) * 100;
  }

  /// Max value in the sparkline — used to normalise bar heights to 0–1.
  int get sparklineMax {
    int m = 0;
    for (final v in sparkline7day) {
      if (v > m) m = v;
    }
    return m;
  }

  /// Empty state — returned by the provider when the backend call fails or
  /// the user has no data yet. Keeps the UI reactive rather than forcing
  /// every consumer to handle null.
  static const empty = WeeklyXpSummary(
    thisWeekXp: 0,
    lastWeekXp: 0,
    sparkline7day: [0, 0, 0, 0, 0, 0, 0],
    nextNudge: '',
  );
}


/// Minimal reward descriptor surfaced on the XP card's next-level chip.
/// Icon names are Material Icons keys; the UI maps them to real IconData
/// via `_rewardIconFor()` so the server can add new icons without a client
/// release.
class NextLevelReward {
  final String kind;   // 'functional' | 'cosmetic' | 'merch' | 'pricing'
  final String label;
  final String icon;   // Material Icons key
  final String tier;   // 'silver' | 'gold' | 'platinum'

  const NextLevelReward({
    required this.kind,
    required this.label,
    required this.icon,
    required this.tier,
  });

  factory NextLevelReward.fromJson(Map<String, dynamic> json) {
    return NextLevelReward(
      kind: json['kind'] as String? ?? 'cosmetic',
      label: json['label'] as String? ?? 'New unlock',
      icon: json['icon'] as String? ?? 'auto_awesome_outlined',
      tier: json['tier'] as String? ?? 'silver',
    );
  }

  static const fallback = NextLevelReward(
    kind: 'cosmetic',
    label: 'New cosmetic unlock',
    icon: 'auto_awesome_outlined',
    tier: 'silver',
  );
}


class NextLevelPreview {
  final int level;
  final int xpInLevel;
  final int xpToNext;
  final NextLevelReward reward;

  const NextLevelPreview({
    required this.level,
    required this.xpInLevel,
    required this.xpToNext,
    required this.reward,
  });

  factory NextLevelPreview.fromJson(Map<String, dynamic> json) {
    final rewardRaw = json['reward'];
    return NextLevelPreview(
      level: (json['level'] as num?)?.toInt() ?? 1,
      xpInLevel: (json['xp_in_level'] as num?)?.toInt() ?? 0,
      xpToNext: (json['xp_to_next'] as num?)?.toInt() ?? 150,
      reward: rewardRaw is Map<String, dynamic>
          ? NextLevelReward.fromJson(rewardRaw)
          : NextLevelReward.fallback,
    );
  }

  /// Progress fraction 0.0–1.0 for the bar.
  double get progressFraction {
    if (xpToNext <= 0) return 1.0;
    return (xpInLevel / xpToNext).clamp(0.0, 1.0);
  }
}
