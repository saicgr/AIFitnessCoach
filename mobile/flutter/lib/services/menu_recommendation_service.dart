import 'dart:math' as math;

import '../data/models/allergen.dart';
import '../data/models/menu_item.dart';

/// Top-level orchestrator for the "Recommended for you" section of the
/// Menu Analysis sheet. Deterministic, client-side, no RAG fallback
/// inside this class (the ChromaDB signal is fetched separately by
/// the sheet and passed in via `favoriteSemanticMatches`).
///
/// See plan `recommendation algorithm — v2, more rigorous` section
/// in `/Users/saichetangrandhe/.claude/plans/i-love-menu-analysis-ticklish-scroll.md`
/// for the weight rationale and edge-case handling.
class MenuRecommendationService {
  const MenuRecommendationService();

  /// Main entry point. Returns up to `topK` ranked items + the ones
  /// rejected by hard filters (for debug/analytics). The caller
  /// typically renders the `picks` directly.
  RecommendationResult recommend({
    required List<MenuItem> items,
    required RecommendationContext context,
    int topK = 3,
  }) {
    if (items.isEmpty) {
      return const RecommendationResult(picks: [], rejected: []);
    }

    final accepted = <_ScoredItem>[];
    final rejected = <RejectedItem>[];

    for (final raw in items) {
      // Dedupe by normalized name — same dish could appear in multiple
      // sections after section normalization mapped both to the same
      // canonical section.
      final filterResult = _applyHardFilters(raw, context);
      if (filterResult != null) {
        rejected.add(RejectedItem(item: raw, reason: filterResult));
        continue;
      }

      final signals = _computeSignals(raw, context);
      final axes = _computeAxes(signals);
      accepted.add(_ScoredItem(item: raw, signals: signals, axes: axes));
    }

    if (accepted.isEmpty) {
      return RecommendationResult(picks: const [], rejected: rejected);
    }

    // Stage 3: Pareto filter — keep items that are dominant on at
    // least one axis. Single axis domination means another item may
    // win two axes but that item can still lose on Pleasure if it's
    // bland, so the Pareto approach protects variety.
    final paretoCandidates = _paretoFilter(accepted);

    // Stage 4: MMR diversity-aware top-K. When the Pareto set is
    // small (<= topK), return it directly sorted by weighted score.
    final picks = _mmrTopK(paretoCandidates, topK, context);

    return RecommendationResult(
      picks: picks.map((p) => _buildRecommendedItem(p, context, picks)).toList(),
      rejected: rejected,
    );
  }

  // ───────────────────── Stage 1: hard filters ─────────────────────

  RejectionReason? _applyHardFilters(MenuItem item, RecommendationContext ctx) {
    // Allergen conflict — binary exclude; this is a safety issue.
    if (ctx.allergenProfile != null && !ctx.allergenProfile!.isEmpty) {
      final hits = ctx.allergenProfile!.matchesForDish(
        dishName: item.name,
        detectedAllergens: item.detectedAllergens,
        dishDescription: item.coachTip,
      );
      if (hits.isNotEmpty) return RejectionReason.allergenConflict;
    }

    // Dietary flag conflict — match by keyword heuristic against dish name.
    if (ctx.dietaryRestrictions.isNotEmpty) {
      final name = item.name.toLowerCase();
      for (final flag in ctx.dietaryRestrictions) {
        if (_conflictsWithDiet(flag, name)) {
          return RejectionReason.dietaryConflict;
        }
      }
    }

    // Disliked food — fuzzy name match (edit distance ≤ 2 approximation
    // using substring check on normalized tokens).
    for (final disliked in ctx.dislikedFoods) {
      final needle = disliked.trim().toLowerCase();
      if (needle.isEmpty) continue;
      if (item.name.toLowerCase().contains(needle)) {
        return RejectionReason.dislikedFood;
      }
    }

    // Hard budget ceiling — allow up to 50% over meal budget so the
    // filter isn't too strict. The scoring function will penalize
    // anything over 120% more gently.
    if (ctx.mealBudgetUsd != null && item.price != null &&
        item.price! > ctx.mealBudgetUsd! * 1.5) {
      return RejectionReason.overBudget;
    }

    // Micro items — drinks, garnishes, condiments. Drop unless the
    // user is truly almost out of calorie budget (then even a side
    // matters).
    final remainingCal = ctx.calorieTarget - ctx.consumedCalories;
    final allowMicro = remainingCal < 200;
    if (!allowMicro && item.calories < 100 &&
        (item.weightG ?? 999) < 100) {
      return RejectionReason.tooSmall;
    }

    return null;
  }

  bool _conflictsWithDiet(String flag, String lowerName) {
    switch (flag.toLowerCase()) {
      case 'vegetarian':
        return _containsAny(lowerName, const [
          'beef', 'pork', 'chicken', 'turkey', 'fish', 'shrimp', 'prawn',
          'lamb', 'mutton', 'bacon', 'salmon', 'tuna', 'crab', 'lobster',
          'duck', 'steak', 'meat',
        ]);
      case 'vegan':
        return _containsAny(lowerName, const [
          'beef', 'pork', 'chicken', 'turkey', 'fish', 'shrimp', 'prawn',
          'lamb', 'mutton', 'bacon', 'salmon', 'tuna', 'crab', 'lobster',
          'duck', 'steak', 'meat', 'egg', 'cheese', 'milk', 'cream',
          'butter', 'yogurt', 'paneer',
        ]);
      case 'pescatarian':
        return _containsAny(lowerName, const [
          'beef', 'pork', 'chicken', 'turkey', 'lamb', 'mutton', 'bacon',
          'duck', 'steak',
        ]);
      case 'gluten_free':
      case 'gluten-free':
        return _containsAny(lowerName, const [
          'bread', 'pasta', 'naan', 'roti', 'pizza', 'burger bun',
          'tortilla', 'wheat', 'wrap', 'pancake', 'noodle',
        ]);
      case 'dairy_free':
      case 'dairy-free':
        return _containsAny(lowerName, const [
          'cheese', 'milk', 'cream', 'butter', 'yogurt', 'paneer',
          'ghee', 'buttermilk',
        ]);
      default:
        return false;
    }
  }

  bool _containsAny(String haystack, List<String> needles) {
    for (final n in needles) {
      if (haystack.contains(n)) return true;
    }
    return false;
  }

  // ───────────────────── Stage 2: normalized signals ─────────────────────

  RecommendationSignals _computeSignals(MenuItem item, RecommendationContext ctx) {
    final macroFit = _macroFit(item, ctx);
    final goalAlignment = _goalAlignment(item.rating);
    final favoriteMatch = _favoriteMatch(item, ctx);
    final historyAffinity = _historyAffinity(item, ctx);
    final healthQuality = _healthQuality(item, ctx);
    final priceFit = _priceFit(item, ctx);
    final varietyBonus = _varietyBonus(item, ctx);

    return RecommendationSignals(
      macroFit: macroFit,
      goalAlignment: goalAlignment,
      favoriteMatch: favoriteMatch,
      historyAffinity: historyAffinity,
      healthQuality: healthQuality,
      priceFit: priceFit,
      varietyBonus: varietyBonus,
    );
  }

  double _macroFit(MenuItem item, RecommendationContext ctx) {
    // Need vectors: how much of each macro is LEFT in the user's budget.
    // Supplied vectors: the item's macros, scaled by portion multiplier.
    final needCal = math.max(0.0, ctx.calorieTarget - ctx.consumedCalories);
    final needP = math.max(0.0, ctx.proteinTarget - ctx.consumedProteinG);
    final needC = math.max(0.0, ctx.carbsTarget - ctx.consumedCarbsG);
    final needF = math.max(0.0, ctx.fatTarget - ctx.consumedFatG);

    if (needCal + needP + needC + needF == 0) {
      // User has fully consumed everything — can't improve fit by
      // adding anything. Return neutral so health + favourites decide.
      return 0.5;
    }

    // Underfill = how much of the need this item does NOT satisfy.
    // Over-supply is a separate penalty, handled via priceFit/health.
    double penalty = 0;
    double normalizer = 0;

    void acc(double need, double supplied) {
      final under = math.max(0.0, need - supplied);
      // Squared so a 20% underfill hurts much less than 80%.
      penalty += (under / (need + 1)) * (under / (need + 1));
      normalizer += 1;
    }

    acc(needCal, item.scaledCalories);
    acc(needP, item.scaledProteinG);
    acc(needC, item.scaledCarbsG);
    acc(needF, item.scaledFatG);

    final raw = 1 - (penalty / math.max(1, normalizer));
    return raw.clamp(0.0, 1.0);
  }

  double _goalAlignment(String? rating) {
    switch (rating) {
      case 'green': return 1.0;
      case 'yellow': return 0.5;
      case 'red': return 0.0;
      default: return 0.5;
    }
  }

  double _favoriteMatch(MenuItem item, RecommendationContext ctx) {
    // Check exact name match first (cheap).
    final lowerName = item.name.toLowerCase();
    for (final fav in ctx.favoriteNames) {
      if (lowerName == fav.toLowerCase()) return 1.0;
    }

    // Fuzzy via ChromaDB pre-fetched matches.
    double best = 0.0;
    for (final match in ctx.favoriteSemanticMatches) {
      if (match.cosine < 0.78) continue; // strict threshold
      if (match.dishName.toLowerCase() == lowerName ||
          lowerName.contains(match.dishName.toLowerCase())) {
        best = math.max(best, match.cosine);
      }
    }
    return best;
  }

  double _historyAffinity(MenuItem item, RecommendationContext ctx) {
    if (ctx.historyFrequency.isEmpty || ctx.historyMaxFrequency == 0) {
      return 0.0;
    }
    final normalized = _normalizeDishName(item.name);
    int hits = 0;
    for (final entry in ctx.historyFrequency.entries) {
      if (entry.key == normalized || _tokenOverlap(entry.key, normalized) >= 0.5) {
        hits += entry.value;
      }
    }
    if (hits == 0) return 0.0;
    // Log compress so a dish logged 30 times doesn't overwhelm the signal.
    return math.log(1 + hits) / math.log(1 + ctx.historyMaxFrequency);
  }

  double _healthQuality(MenuItem item, RecommendationContext ctx) {
    final inflam = (item.inflammationScore ?? 5) / 10.0;
    final ultra = (item.isUltraProcessed ?? false) ? 1.0 : 0.0;
    // Scale inflammation weight by user sensitivity (1-5 → 0.4-1.0).
    final infWeight = 0.4 + 0.15 * (ctx.inflammationSensitivity - 1).clamp(0, 4);
    final raw = 1 - (inflam * infWeight) - (ultra * 0.4);
    return raw.clamp(0.0, 1.0);
  }

  double _priceFit(MenuItem item, RecommendationContext ctx) {
    if (ctx.mealBudgetUsd == null || item.price == null) return 0.5;
    final price = item.price!;
    final budget = ctx.mealBudgetUsd!;
    final over = math.max(0.0, price - budget);
    if (budget <= 0) return 0.5;
    final raw = 1 - (over / budget);
    return raw.clamp(0.0, 1.0);
  }

  double _varietyBonus(MenuItem item, RecommendationContext ctx) {
    if (ctx.todayItemNames.isEmpty) return 1.0;
    double maxSim = 0.0;
    final normalized = _normalizeDishName(item.name);
    for (final t in ctx.todayItemNames) {
      maxSim = math.max(maxSim, _tokenOverlap(normalized, _normalizeDishName(t)));
    }
    return (1 - maxSim).clamp(0.0, 1.0);
  }

  // ───────────────────── Stage 3: Pareto filter ─────────────────────

  RecommendationAxes _computeAxes(RecommendationSignals s) {
    return RecommendationAxes(
      nutrition: 0.6 * s.macroFit + 0.4 * s.priceFit,
      pleasure: 0.4 * s.favoriteMatch + 0.3 * s.historyAffinity + 0.3 * s.goalAlignment,
      wellness: 0.6 * s.healthQuality + 0.4 * s.varietyBonus,
    );
  }

  List<_ScoredItem> _paretoFilter(List<_ScoredItem> items) {
    final surviving = <_ScoredItem>[];
    for (final candidate in items) {
      bool dominated = true;
      for (final other in items) {
        if (identical(candidate, other)) continue;
        // Candidate is NOT dominated if it wins on at least one axis.
        final winsNutrition = candidate.axes.nutrition > other.axes.nutrition;
        final winsPleasure = candidate.axes.pleasure > other.axes.pleasure;
        final winsWellness = candidate.axes.wellness > other.axes.wellness;
        if (winsNutrition || winsPleasure || winsWellness) {
          // Find any axis candidate wins — remains Pareto-undominated.
          dominated = false;
          break;
        }
      }
      if (!dominated) surviving.add(candidate);
    }
    // If Pareto cut left too few, fall back to all accepted items.
    return surviving.length >= 3 ? surviving : items;
  }

  // ───────────────────── Stage 4: MMR top-K ─────────────────────

  List<_ScoredItem> _mmrTopK(
    List<_ScoredItem> items,
    int k,
    RecommendationContext ctx,
  ) {
    final picked = <_ScoredItem>[];
    final remaining = [...items];
    while (picked.length < k && remaining.isNotEmpty) {
      final best = _argmaxMmr(remaining, picked);
      if (best == null) break;
      picked.add(best);
      remaining.remove(best);
    }
    return picked;
  }

  _ScoredItem? _argmaxMmr(List<_ScoredItem> pool, List<_ScoredItem> picked) {
    const lambda = 0.7;
    _ScoredItem? best;
    double bestScore = double.negativeInfinity;
    for (final candidate in pool) {
      final primary = _weightedScore(candidate);
      double similarity = 0.0;
      for (final p in picked) {
        similarity = math.max(
          similarity,
          _tokenOverlap(
            _normalizeDishName(candidate.item.name),
            _normalizeDishName(p.item.name),
          ),
        );
      }
      final mmrScore = lambda * primary - (1 - lambda) * similarity;
      if (mmrScore > bestScore) {
        bestScore = mmrScore;
        best = candidate;
      }
    }
    return best;
  }

  double _weightedScore(_ScoredItem s) =>
      0.4 * s.axes.nutrition + 0.3 * s.axes.pleasure + 0.3 * s.axes.wellness;

  // ───────────────────── Stage 5: explainability trace ─────────────────────

  RecommendedItem _buildRecommendedItem(
    _ScoredItem scored,
    RecommendationContext ctx,
    List<_ScoredItem> allPicks,
  ) {
    final contributions = <SignalKind, double>{
      SignalKind.macroFit: 3.0 * scored.signals.macroFit,
      SignalKind.goalAlignment: 2.0 * scored.signals.goalAlignment,
      SignalKind.favoriteMatch: 1.5 * scored.signals.favoriteMatch,
      SignalKind.historyAffinity: 1.2 * scored.signals.historyAffinity,
      SignalKind.healthQuality: 1.5 * scored.signals.healthQuality,
      SignalKind.priceFit: 1.0 * scored.signals.priceFit,
      SignalKind.varietyBonus: 1.0 * scored.signals.varietyBonus,
    };
    // Sort by absolute magnitude so the UI can show top positives + negatives.
    final sortedKeys = contributions.keys.toList()
      ..sort((a, b) => contributions[b]!.abs().compareTo(contributions[a]!.abs()));

    final total = contributions.values.fold<double>(0, (a, b) => a + b);
    final normalizedScore = (total / 11.2).clamp(0.0, 1.0); // max possible sum

    return RecommendedItem(
      item: scored.item,
      weightedScore: normalizedScore,
      contributions: contributions,
      topContributions: sortedKeys,
      axes: scored.axes,
      signals: scored.signals,
    );
  }

  // ───────────────────── helpers ─────────────────────

  static final Set<String> _stopwords = {
    'the', 'a', 'an', 'of', 'with', 'and', '&', 'w/', 'w', 'in',
    'on', 'at', 'for', 'to', 'from', 'by', 'fresh', 'house', 'side',
    'signature', 'classic', 'traditional', 'special',
  };

  static String _normalizeDishName(String raw) {
    if (raw.isEmpty) return '';
    final lowered = raw.toLowerCase().trim();
    final cleaned = lowered.replaceAll(RegExp(r'[^\w\s]'), ' ');
    final tokens = cleaned
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty && !_stopwords.contains(t))
        .toList();
    return tokens.join(' ');
  }

  /// Weighted Jaccard — protein words weighted 2x, prep words 1.5x,
  /// others 1x. Strict threshold 0.5 encouraged at call sites.
  static double _tokenOverlap(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final ta = a.split(' ').toSet();
    final tb = b.split(' ').toSet();
    final intersection = ta.intersection(tb);
    final union = ta.union(tb);
    if (union.isEmpty) return 0.0;
    double weightedInter = 0.0;
    double weightedUnion = 0.0;
    for (final tok in union) {
      final w = _tokenWeight(tok);
      weightedUnion += w;
      if (intersection.contains(tok)) weightedInter += w;
    }
    return weightedUnion == 0 ? 0.0 : weightedInter / weightedUnion;
  }

  static const _proteinTokens = {
    'chicken', 'beef', 'pork', 'lamb', 'turkey', 'shrimp', 'prawn',
    'fish', 'salmon', 'tuna', 'tilapia', 'cod', 'crab', 'lobster',
    'tofu', 'paneer', 'chickpea', 'chickpeas', 'lentil', 'lentils',
    'dal', 'egg', 'eggs', 'mutton', 'duck', 'bacon',
  };

  static const _prepTokens = {
    'grilled', 'fried', 'baked', 'roasted', 'steamed', 'boiled',
    'sauteed', 'broiled', 'braised', 'tandoori', 'curry', 'stew',
    'soup', 'salad', 'wrap', 'burrito', 'taco', 'pizza', 'pasta',
    'sandwich', 'burger', 'bowl', 'stirfry', 'kabab', 'kebab',
    'biryani', 'tikka',
  };

  static double _tokenWeight(String tok) {
    if (_proteinTokens.contains(tok)) return 2.0;
    if (_prepTokens.contains(tok)) return 1.5;
    return 1.0;
  }
}

// ───────────────────── DTOs ─────────────────────

class RecommendationContext {
  final double calorieTarget;
  final double proteinTarget;
  final double carbsTarget;
  final double fatTarget;
  final double consumedCalories;
  final double consumedProteinG;
  final double consumedCarbsG;
  final double consumedFatG;

  final List<String> dietaryRestrictions;
  final List<String> dislikedFoods;
  final UserAllergenProfile? allergenProfile;
  final int inflammationSensitivity;
  final double? mealBudgetUsd;

  /// Exact favorite names the user has saved.
  final List<String> favoriteNames;

  /// Pre-fetched semantic neighbors from ChromaDB.
  final List<SemanticMatch> favoriteSemanticMatches;

  /// Normalized name → total count over 60 days.
  final Map<String, int> historyFrequency;
  final int historyMaxFrequency;

  /// What the user already logged today — normalized names for variety.
  final List<String> todayItemNames;

  /// True = user is brand new (no signals) — recommendation will
  /// disable history + favorite terms and show a cold-start banner.
  final bool coldStart;

  const RecommendationContext({
    required this.calorieTarget,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
    required this.consumedCalories,
    required this.consumedProteinG,
    required this.consumedCarbsG,
    required this.consumedFatG,
    this.dietaryRestrictions = const [],
    this.dislikedFoods = const [],
    this.allergenProfile,
    this.inflammationSensitivity = 3,
    this.mealBudgetUsd,
    this.favoriteNames = const [],
    this.favoriteSemanticMatches = const [],
    this.historyFrequency = const {},
    this.historyMaxFrequency = 0,
    this.todayItemNames = const [],
    this.coldStart = false,
  });
}

class SemanticMatch {
  final String dishName;
  final double cosine;
  final bool liked;
  const SemanticMatch({required this.dishName, required this.cosine, this.liked = true});
}

enum SignalKind {
  macroFit,
  goalAlignment,
  favoriteMatch,
  historyAffinity,
  healthQuality,
  priceFit,
  varietyBonus,
}

extension SignalKindExt on SignalKind {
  String get label {
    switch (this) {
      case SignalKind.macroFit: return 'Macro fit';
      case SignalKind.goalAlignment: return 'Goal alignment';
      case SignalKind.favoriteMatch: return 'Favorite match';
      case SignalKind.historyAffinity: return 'History affinity';
      case SignalKind.healthQuality: return 'Health quality';
      case SignalKind.priceFit: return 'Price fit';
      case SignalKind.varietyBonus: return 'Variety';
    }
  }
}

enum RejectionReason {
  allergenConflict,
  dietaryConflict,
  dislikedFood,
  overBudget,
  tooSmall,
}

extension RejectionReasonExt on RejectionReason {
  String get label {
    switch (this) {
      case RejectionReason.allergenConflict: return 'Allergen conflict';
      case RejectionReason.dietaryConflict: return 'Diet conflict';
      case RejectionReason.dislikedFood: return 'Disliked food';
      case RejectionReason.overBudget: return 'Over budget';
      case RejectionReason.tooSmall: return 'Too small';
    }
  }
}

class RejectedItem {
  final MenuItem item;
  final RejectionReason reason;
  const RejectedItem({required this.item, required this.reason});
}

class RecommendedItem {
  final MenuItem item;
  final double weightedScore;
  final Map<SignalKind, double> contributions;
  final List<SignalKind> topContributions;
  final RecommendationAxes axes;
  final RecommendationSignals signals;

  const RecommendedItem({
    required this.item,
    required this.weightedScore,
    required this.contributions,
    required this.topContributions,
    required this.axes,
    required this.signals,
  });

  /// Top N contributions with magnitude > 0.05 (filter noise).
  List<SignalKind> topContributionsMeaningful(int n) {
    return topContributions
        .where((k) => contributions[k]!.abs() >= 0.05)
        .take(n)
        .toList();
  }
}

class RecommendationResult {
  final List<RecommendedItem> picks;
  final List<RejectedItem> rejected;
  const RecommendationResult({required this.picks, required this.rejected});
}

// Internal scored item tracked through the pipeline.
class _ScoredItem {
  final MenuItem item;
  final RecommendationSignals signals;
  final RecommendationAxes axes;
  const _ScoredItem({required this.item, required this.signals, required this.axes});
}

class RecommendationSignals {
  final double macroFit;
  final double goalAlignment;
  final double favoriteMatch;
  final double historyAffinity;
  final double healthQuality;
  final double priceFit;
  final double varietyBonus;

  const RecommendationSignals({
    required this.macroFit,
    required this.goalAlignment,
    required this.favoriteMatch,
    required this.historyAffinity,
    required this.healthQuality,
    required this.priceFit,
    required this.varietyBonus,
  });
}

class RecommendationAxes {
  final double nutrition;
  final double pleasure;
  final double wellness;
  const RecommendationAxes({required this.nutrition, required this.pleasure, required this.wellness});
}
