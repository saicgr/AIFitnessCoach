import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// The strict, AI-generated "Progress Pros & Cons" report for a single exercise
/// (or whole-body when `exerciseName` is null). Mirrors EXACTLY the JSON the
/// backend returns from `POST /feedback/progress-analysis`, so the card stays
/// presentation-only and the contract lives in one place.
///
/// Per project rule `feedback_no_silent_fallbacks`, the repository never
/// fabricates this — a failed fetch throws and the card surfaces a retry.
class ProgressAnalysis {
  /// Genuine wins grounded in the logged history (volume up, e1RM PR, etc.).
  final List<String> pros;

  /// Honest watch-outs / weaknesses (declining lift, skipped sessions, …).
  final List<String> cons;

  /// Explicit plateau callouts (lifts that have stalled). Often empty.
  final List<String> plateaus;

  /// The single most-leveraged thing to focus on next.
  final List<String> nextFocus;

  /// A longer free-form markdown narrative (rendered via SimpleMarkdownText).
  final String summaryMarkdown;

  /// False when there isn't enough logged history to analyze (<2 sessions).
  /// The card shows a "keep logging" empty state rather than fake bullets.
  final bool hasHistory;

  /// True when the backend returned a deterministic, non-LLM fallback (e.g.
  /// the model was unavailable). Surfaced subtly so the user knows.
  final bool isFallback;

  /// True when this came from the server-side cache (no fresh LLM spend).
  final bool cached;

  /// ISO-8601 timestamp the analysis was generated, for the "updated …" label.
  final String generatedAt;

  const ProgressAnalysis({
    required this.pros,
    required this.cons,
    required this.plateaus,
    required this.nextFocus,
    required this.summaryMarkdown,
    required this.hasHistory,
    required this.isFallback,
    required this.cached,
    required this.generatedAt,
  });

  /// Parses the `POST /feedback/progress-analysis` response body. Tolerant of
  /// missing keys (treats them as empty) but never invents content.
  factory ProgressAnalysis.fromJson(Map<String, dynamic> json) {
    List<String> stringList(dynamic v) {
      if (v is List) {
        return v
            .map((e) => e.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList();
      }
      return const <String>[];
    }

    return ProgressAnalysis(
      pros: stringList(json['pros']),
      cons: stringList(json['cons']),
      plateaus: stringList(json['plateaus']),
      nextFocus: stringList(json['next_focus']),
      summaryMarkdown: (json['summary_markdown'] as String?)?.trim() ?? '',
      hasHistory: json['has_history'] == true,
      isFallback: json['is_fallback'] == true,
      cached: json['cached'] == true,
      generatedAt: (json['generated_at'] as String?)?.trim() ?? '',
    );
  }

  /// True when the report carries no actionable content at all — used by the
  /// card to decide between the rendered report and the empty state.
  bool get isEmpty =>
      pros.isEmpty &&
      cons.isEmpty &&
      plateaus.isEmpty &&
      nextFocus.isEmpty &&
      summaryMarkdown.isEmpty;
}

/// Repository wrapping the on-demand progress-analysis fetch. Uses the same
/// [ApiClient] / Dio pattern as `WorkoutAiRecapCard` so auth, base URL and the
/// `user_id` source all match the rest of the feedback features.
class ProgressAnalysisRepository {
  final ApiClient _api;

  const ProgressAnalysisRepository(this._api);

  /// Fetches (and, server-side, caches) the AI Progress Pros & Cons report.
  ///
  /// - [exerciseName] null → whole-body analysis.
  /// - [window] one of `'8w'` / `'6m'` / `'1y'` / `'all'` (default `'8w'`).
  /// - [force] true bypasses the server cache to regenerate.
  ///
  /// Throws on any failure (not signed in, network, malformed body) — callers
  /// surface the error with a retry. No silent fallback to fake data.
  Future<ProgressAnalysis> fetchProgressAnalysis({
    String? exerciseName,
    String? gymProfileId,
    String window = '8w',
    bool force = false,
  }) async {
    final userId = await _api.getUserId();
    if (userId == null) {
      throw Exception('Not signed in');
    }

    final res = await _api.post(
      '/feedback/progress-analysis',
      data: <String, dynamic>{
        'user_id': userId,
        'exercise_name': exerciseName,
        'gym_profile_id': gymProfileId,
        'window': window,
        'force': force,
      },
      options: Options(
        // On-demand AI generation can take several seconds; give it room.
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    final data = res.data;
    if (res.statusCode == 200 && data is Map<String, dynamic>) {
      return ProgressAnalysis.fromJson(data);
    }
    if (res.statusCode == 200 && data is Map) {
      return ProgressAnalysis.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Could not build your progress report');
  }
}

/// Provider for the [ProgressAnalysisRepository] (one per [ApiClient]).
final progressAnalysisRepositoryProvider =
    Provider<ProgressAnalysisRepository>((ref) {
  return ProgressAnalysisRepository(ref.watch(apiClientProvider));
});

/// The keyed arguments for an on-demand progress-analysis trigger. Kept as a
/// value type so the card can pass exactly what it needs.
class ProgressAnalysisArgs {
  /// Null for a whole-body analysis.
  final String? exerciseName;

  /// The selected progress-filter gym (null = pooled "All gyms").
  final String? gymProfileId;

  /// One of `'8w'` / `'6m'` / `'1y'` / `'all'`.
  final String window;

  const ProgressAnalysisArgs({
    this.exerciseName,
    this.gymProfileId,
    this.window = '8w',
  });

  @override
  bool operator ==(Object other) =>
      other is ProgressAnalysisArgs &&
      other.exerciseName == exerciseName &&
      other.gymProfileId == gymProfileId &&
      other.window == window;

  @override
  int get hashCode => Object.hash(exerciseName, gymProfileId, window);
}
