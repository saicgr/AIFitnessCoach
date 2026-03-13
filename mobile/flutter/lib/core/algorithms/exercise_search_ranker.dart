import 'dart:math';

import '../../services/collaborative_score_service.dart';
import '../../services/offline_workout_generator.dart';

/// A ranked exercise result with score and recommendation flag.
class RankedExercise {
  final OfflineExercise exercise;
  final double score;
  final bool isRecommended;

  const RankedExercise({
    required this.exercise,
    required this.score,
    this.isRecommended = false,
  });
}

/// Multiplicative multi-signal ranker for exercise search results.
///
/// Uses 5 signals:
/// 1. Match quality (text relevance base score)
/// 2. Canonical boost (difficulty-based — beginner = canonical)
/// 3. Popularity boost (from collaborative scores, fuzzy-resolved)
/// 4. Personal boost (favorites)
/// 5. Name simplicity factor (shorter names = more canonical)
class ExerciseSearchRanker {
  Map<String, double> _resolvedPopularity = {};

  ExerciseSearchRanker._();

  /// Factory constructor that loads popularity data.
  static Future<ExerciseSearchRanker> create() async {
    final ranker = ExerciseSearchRanker._();
    final rawPopularity = await CollaborativeScoreService.getAllMaxScores();
    ranker._rawPopularity = rawPopularity;
    return ranker;
  }

  Map<String, double> _rawPopularity = {};

  /// Resolve popularity names against the actual exercise library.
  /// Must be called once after loading exercises.
  void resolvePopularityForLibrary(List<OfflineExercise> exercises) {
    _resolvedPopularity = _resolvePopularity(_rawPopularity, exercises);
  }

  /// One-time fuzzy mapping: 95 popularity names → 2078 library names.
  /// Uses word-subset matching with partial coverage scoring.
  Map<String, double> _resolvePopularity(
    Map<String, double> rawPopularity,
    List<OfflineExercise> exercises,
  ) {
    final resolved = <String, double>{};

    // Pre-tokenize popularity names
    final popEntries = rawPopularity.entries.map((e) {
      final words = e.key.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();
      return (name: e.key, words: words, score: e.value);
    }).toList();

    for (final ex in exercises) {
      final libName = (ex.name ?? '').toLowerCase();
      if (libName.isEmpty) continue;

      final libWords =
          libName.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();
      if (libWords.isEmpty) continue;

      double bestScore = 0.0;

      for (final pop in popEntries) {
        // Check if all popularity words appear in the library name
        if (pop.words.every((w) => libWords.contains(w))) {
          final coverage = pop.words.length / libWords.length;
          final score = pop.score * coverage;
          if (score > bestScore) {
            bestScore = score;
          }
        }
      }

      if (bestScore > 0) {
        resolved[libName] = bestScore;
      }
    }

    return resolved;
  }

  /// Rank a list of exercises against a search query.
  /// Returns exercises sorted by multiplicative score, with top picks flagged.
  List<RankedExercise> rank(
    List<OfflineExercise> exercises,
    String query, {
    Set<String>? favoriteNames,
  }) {
    if (exercises.isEmpty || query.isEmpty) return [];

    final queryLower = query.toLowerCase().trim();
    final favorites = favoriteNames ?? <String>{};

    final scored = <RankedExercise>[];
    for (final ex in exercises) {
      final name = (ex.name ?? '').toLowerCase();
      if (name.isEmpty) continue;

      final matchQuality = _matchQuality(name, queryLower);
      if (matchQuality <= 0) continue;

      final canonicalBoost = _canonicalBoost(ex.difficultyNum);
      final popularityBoost = _resolvedPopularity[name] ?? 0.0;
      final personalBoost = favorites.contains(name) ? 0.5 : 0.0;
      final simplicity = _nameSimplicity(name);

      final score = matchQuality *
          (1 + canonicalBoost) *
          (1 + popularityBoost) *
          (1 + personalBoost) *
          simplicity;

      scored.add(RankedExercise(exercise: ex, score: score));
    }

    // Sort descending by score
    scored.sort((a, b) => b.score.compareTo(a.score));

    // Determine top picks: need >= 3 results, top score >= 1.2,
    // and gap between #3 and #4 >= 5%
    if (scored.length >= 3 && scored[0].score >= 1.2) {
      final hasGap = scored.length == 3 ||
          (scored[2].score - scored[3].score) / scored[2].score >= 0.05;

      if (hasGap) {
        return [
          for (int i = 0; i < scored.length; i++)
            RankedExercise(
              exercise: scored[i].exercise,
              score: scored[i].score,
              isRecommended: i < 3,
            ),
        ];
      }
    }

    return scored;
  }

  /// Bigram-based fuzzy search fallback when exact matching returns 0 results.
  List<OfflineExercise> fuzzySearch(
    List<OfflineExercise> exercises,
    String query,
  ) {
    if (query.length < 3) return [];

    final results = <OfflineExercise>[];
    for (final ex in exercises) {
      final name = ex.name ?? '';
      if (_fuzzyMatch(name, query)) {
        results.add(ex);
      }
    }
    return results;
  }

  // ─── Private Helpers ─────────────────────────────────────────────

  /// Text relevance score based on how well the name matches the query.
  double _matchQuality(String name, String query) {
    if (name == query) return 1.0;
    if (name.startsWith(query)) return 0.85;
    // Word-boundary match: query appears after a space
    if (name.contains(' $query')) return 0.70;
    if (name.contains(query)) return 0.40;
    return 0.0;
  }

  /// Difficulty-based canonical boost. Lower difficulty = more canonical.
  double _canonicalBoost(int? difficultyNum) {
    final d = difficultyNum ?? 5;
    return (10 - d) / 10.0;
  }

  /// Mild penalty for long names (shorter = more canonical).
  double _nameSimplicity(String name) {
    return 0.7 + 0.3 * (1 - min(name.length, 30) / 30.0);
  }

  /// Generate character bigrams for fuzzy matching.
  static Set<String> _bigrams(String s) =>
      {for (int i = 0; i < s.length - 1; i++) s.substring(i, i + 2)};

  /// Bigram similarity check with 50% overlap threshold.
  static bool _fuzzyMatch(String text, String query) {
    final textLower = text.toLowerCase();
    final queryLower = query.toLowerCase();
    if (textLower.contains(queryLower) || queryLower.contains(textLower)) {
      return true;
    }
    if (queryLower.length < 3 || textLower.length < 3) return false;
    final tBigrams = _bigrams(textLower);
    final qBigrams = _bigrams(queryLower);
    if (qBigrams.isEmpty || tBigrams.isEmpty) return false;
    final common = qBigrams.intersection(tBigrams).length;
    final smaller =
        qBigrams.length < tBigrams.length ? qBigrams.length : tBigrams.length;
    return common / smaller >= 0.5;
  }
}
