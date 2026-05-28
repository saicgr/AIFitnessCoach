/// SubCardRanker — F4 of the home-screen overhaul.
///
/// Inputs: an unordered list of eligible `ContextualNudge` candidates emitted
/// from [contextualNudgeProvider]. Outputs: an ordered, deduplicated list
/// capped at [kSubCardDailyCap].
///
/// Ranking algorithm (see `docs/planning/home-screen-surfaces.md` §4 + §4.3):
///   1. Drop any candidate whose `dedupKey` is in the per-day shown set.
///   2. Sort by (a) AI Settings category priority (lower index wins),
///      then by (b) priority tier, then (c) perishesAt ascending.
///   3. Truncate at [kSubCardDailyCap] (default 8).
library;

import '../../data/models/contextual_nudge.dart';
import '../../data/providers/ai_settings_provider.dart';

const int kSubCardDailyCap = 8;

class SubCardRanker {
  const SubCardRanker();

  /// Rank + cap a list of eligible nudges.
  ///
  /// [order] — the user's effective category priority order
  /// (typically `aiSettingsProvider.read().effectiveCategoryOrder`).
  /// [shownTodayDedupKeys] — keys already acted on / dismissed today.
  List<ContextualNudge> rank({
    required List<ContextualNudge> candidates,
    required List<NudgeCategory> order,
    required Set<String> shownTodayDedupKeys,
  }) {
    if (candidates.isEmpty) return const [];

    // De-dup
    final filtered = candidates
        .where((c) => !shownTodayDedupKeys.contains(c.effectiveDedupKey))
        .toList();

    // Stable sort — order by (categoryPriority, tier, perishesAt).
    int catPriority(NudgeCategory cat) {
      final idx = order.indexOf(cat);
      return idx < 0 ? order.length : idx;
    }

    filtered.sort((a, b) {
      final cp = catPriority(a.category).compareTo(catPriority(b.category));
      if (cp != 0) return cp;
      final tp = a.priorityTier.index.compareTo(b.priorityTier.index);
      if (tp != 0) return tp;
      final ap = a.perishesAt ?? DateTime(9999);
      final bp = b.perishesAt ?? DateTime(9999);
      return ap.compareTo(bp);
    });

    if (filtered.length <= kSubCardDailyCap) return filtered;
    return filtered.sublist(0, kSubCardDailyCap);
  }
}

/// Helper to default a ranker setup to the AI Settings provider's order.
List<ContextualNudge> rankWithCoachUiSettings({
  required List<ContextualNudge> candidates,
  required CoachUiSettings settings,
  required Set<String> shownTodayDedupKeys,
}) {
  return const SubCardRanker().rank(
    candidates: candidates,
    order: settings.effectiveCategoryOrder,
    shownTodayDedupKeys: shownTodayDedupKeys,
  );
}
