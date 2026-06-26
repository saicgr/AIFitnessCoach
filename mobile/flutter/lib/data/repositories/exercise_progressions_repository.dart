import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// Repository + hand-written models for the skill-based
/// exercise-progressions feature.
///
/// Mirrors the live backend contract in
/// `backend/api/v1/exercise_progressions.py` + `_endpoints.py` +
/// `_models.py`, which is aligned to the REAL deployed Postgres schema
/// (migrations 081 + 089):
///  - `exercise_progression_chains` (id, name, description, category)
///  - `exercise_progression_steps`  (id, chain_id, exercise_name, step_order,
///    difficulty_level, prerequisites, unlock_criteria, tips, video_url)
///  - `user_exercise_mastery`       (progression_chain_id, progression_status,
///    consecutive_easy_sessions, total_sessions, current_max_reps, ...)
///
/// Models are HAND-WRITTEN (manual `fromJson`) — codegen (`build_runner`) is
/// intentionally NOT used in this repo (see project CLAUDE.md). Models live in
/// this file rather than a separate model file because
/// `lib/data/models/exercise_progression.dart` already exists for an unrelated
/// (singular-named) feature surface and must not be disturbed.
///
/// Endpoint surface (the ApiClient base URL already includes `/api/v1`):
///  - GET  `/exercise-progressions/user/{userId}/mastery?ready_only=bool`
///         returns a list of `ExerciseMasteryWithChain`
///  - GET  `/exercise-progressions/user/{userId}/suggestions`
///         returns a list of `ProgressionSuggestionItem`
///  - GET  `/exercise-progressions/chains?category=`
///         returns a list of `ProgressionChain` (each with its ordered steps)
///  - POST `/exercise-progressions/user/{userId}/accept-progression`
///         body `{current_exercise, new_exercise}`; returns AcceptProgressionResponse
///
/// Errors are NOT swallowed — they bubble up so the screen can render a
/// real error state (per the no-silent-fallbacks rule).

// ===========================================================================
// Parse helpers — defensive against missing / null / mistyped fields.
// ===========================================================================

int _asInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double? _asDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

double _asDouble(dynamic v, [double fallback = 0.0]) =>
    _asDoubleOrNull(v) ?? fallback;

bool _asBool(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true';
  if (v is num) return v != 0;
  return fallback;
}

DateTime? _asDateOrNull(dynamic v) {
  if (v is String && v.trim().isNotEmpty) return DateTime.tryParse(v);
  return null;
}

List<String> _asStringList(dynamic v) {
  if (v is List) {
    return v.where((e) => e != null).map((e) => e.toString()).toList();
  }
  return const [];
}

Map<String, dynamic> _asStringMap(dynamic v) {
  if (v is Map) return Map<String, dynamic>.from(v);
  return const <String, dynamic>{};
}

// ===========================================================================
// MasteryStatus — backend `MasteryStatus` enum (stored in
// user_exercise_mastery.progression_status).
// ===========================================================================

enum ProgressionMasteryStatus {
  learning,
  proficient,
  mastered,
  progressed;

  static ProgressionMasteryStatus fromValue(dynamic raw) {
    switch ((raw ?? '').toString().toLowerCase()) {
      case 'proficient':
        return ProgressionMasteryStatus.proficient;
      case 'mastered':
        return ProgressionMasteryStatus.mastered;
      case 'progressed':
        return ProgressionMasteryStatus.progressed;
      case 'learning':
      default:
        return ProgressionMasteryStatus.learning;
    }
  }

  String get label {
    switch (this) {
      case ProgressionMasteryStatus.learning:
        return 'Learning';
      case ProgressionMasteryStatus.proficient:
        return 'Proficient';
      case ProgressionMasteryStatus.mastered:
        return 'Mastered';
      case ProgressionMasteryStatus.progressed:
        return 'Progressed';
    }
  }
}

// ===========================================================================
// ProgressionStep — a single rung in a chain.
//
// Maps to a row of `exercise_progression_steps` (backend `ProgressionStep`).
// Difficulty is an INTEGER 1-10 (`difficulty_level`), not a float score. The
// real table has no `description`, `cues`, `common_mistakes` or
// `library_exercise_id` columns — form guidance lives in the single `tips`
// text field, and `unlock_criteria` is the JSONB that drives `recommended_reps`.
// ===========================================================================

class ProgressionStep {
  final String id;
  final String name;
  final int order;

  /// 1-10 integer difficulty (`difficulty_level` column).
  final int difficultyLevel;

  /// Form tips for this step (`tips` column). May be null.
  final String? tips;
  final String? videoUrl;
  final List<String> prerequisites;

  /// Raw unlock criteria JSONB, e.g. {reps: 12, sets: 3, consecutive_sessions: 3}.
  final Map<String, dynamic> unlockCriteria;

  /// Backend-derived rep range (synthesized from [unlockCriteria]).
  final String recommendedReps;

  const ProgressionStep({
    required this.id,
    required this.name,
    required this.order,
    required this.difficultyLevel,
    this.tips,
    this.videoUrl,
    this.prerequisites = const [],
    this.unlockCriteria = const {},
    this.recommendedReps = '8-12',
  });

  factory ProgressionStep.fromJson(Map<String, dynamic> json) {
    return ProgressionStep(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      order: _asInt(json['order']),
      difficultyLevel: _asInt(json['difficulty_level'], 5),
      tips: json['tips']?.toString(),
      videoUrl: json['video_url']?.toString(),
      prerequisites: _asStringList(json['prerequisites']),
      unlockCriteria: _asStringMap(json['unlock_criteria']),
      recommendedReps: (json['recommended_reps'] ?? '8-12').toString(),
    );
  }
}

// ===========================================================================
// ProgressionChain — backend `ProgressionChainResponse`.
//
// Maps to `exercise_progression_chains`. The real table is categorised by
// skill movement (`category`: pushup / pullup / squat / handstand / ...), NOT
// by muscle group, and has no `chain_type` column.
// ===========================================================================

class ProgressionChain {
  final String id;
  final String name;

  /// Skill-movement category (`category` column): pushup, pullup, squat, etc.
  final String? category;
  final String? description;
  final int totalSteps;
  final List<ProgressionStep> steps;

  const ProgressionChain({
    required this.id,
    required this.name,
    this.category,
    this.description,
    this.totalSteps = 0,
    this.steps = const [],
  });

  factory ProgressionChain.fromJson(Map<String, dynamic> json) {
    final steps = (json['steps'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => ProgressionStep.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return ProgressionChain(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: json['category']?.toString(),
      description: json['description']?.toString(),
      totalSteps: _asInt(json['total_steps'], steps.length),
      steps: steps,
    );
  }
}

// ===========================================================================
// ExerciseMasteryWithChain — backend `ExerciseMasteryWithChain` (a superset
// of `ExerciseMastery`, adds `chain_name` + `next_step`).
//
// Maps to `user_exercise_mastery`. `current_step_order` is DERIVED by the
// backend (the table stores no such column); there is no `mastered_at` or
// `average_difficulty_rating` column on the real schema.
// ===========================================================================

class ExerciseMasteryWithChain {
  final String id;
  final String userId;
  final String exerciseName;
  final String? chainId;

  /// Derived position of this exercise within its chain (backend-computed
  /// from `exercise_progression_steps`; not a stored column).
  final int? currentStepOrder;
  final ProgressionMasteryStatus status;
  final int totalSessions;
  final int consecutiveEasySessions;
  final int consecutiveHardSessions;
  final int currentMaxReps;
  final double? currentMaxWeight;
  final bool readyForProgression;
  final String? suggestedNextVariant;
  final int progressionAcceptedCount;
  final int progressionDeclinedCount;
  final DateTime? firstPerformedAt;
  final DateTime? lastPerformedAt;

  /// Null when the exercise is not part of a tracked progression chain.
  final String? chainName;
  final ProgressionStep? nextStep;

  const ExerciseMasteryWithChain({
    required this.id,
    required this.userId,
    required this.exerciseName,
    this.chainId,
    this.currentStepOrder,
    this.status = ProgressionMasteryStatus.learning,
    this.totalSessions = 0,
    this.consecutiveEasySessions = 0,
    this.consecutiveHardSessions = 0,
    this.currentMaxReps = 0,
    this.currentMaxWeight,
    this.readyForProgression = false,
    this.suggestedNextVariant,
    this.progressionAcceptedCount = 0,
    this.progressionDeclinedCount = 0,
    this.firstPerformedAt,
    this.lastPerformedAt,
    this.chainName,
    this.nextStep,
  });

  /// True when this exercise belongs to a skill-based progression chain.
  bool get isInChain => (chainId ?? '').isNotEmpty;

  factory ExerciseMasteryWithChain.fromJson(Map<String, dynamic> json) {
    final nextRaw = json['next_step'];
    return ExerciseMasteryWithChain(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      exerciseName: (json['exercise_name'] ?? '').toString(),
      chainId: json['chain_id']?.toString(),
      currentStepOrder: json['current_step_order'] == null
          ? null
          : _asInt(json['current_step_order']),
      status: ProgressionMasteryStatus.fromValue(json['status']),
      totalSessions: _asInt(json['total_sessions']),
      consecutiveEasySessions: _asInt(json['consecutive_easy_sessions']),
      consecutiveHardSessions: _asInt(json['consecutive_hard_sessions']),
      currentMaxReps: _asInt(json['current_max_reps']),
      currentMaxWeight: _asDoubleOrNull(json['current_max_weight']),
      readyForProgression: _asBool(json['ready_for_progression']),
      suggestedNextVariant: json['suggested_next_variant']?.toString(),
      progressionAcceptedCount: _asInt(json['progression_accepted_count']),
      progressionDeclinedCount: _asInt(json['progression_declined_count']),
      firstPerformedAt: _asDateOrNull(json['first_performed_at']),
      lastPerformedAt: _asDateOrNull(json['last_performed_at']),
      chainName: json['chain_name']?.toString(),
      nextStep: nextRaw is Map
          ? ProgressionStep.fromJson(Map<String, dynamic>.from(nextRaw))
          : null,
    );
  }
}

// ===========================================================================
// ProgressionSuggestionItem — backend `ProgressionSuggestion`.
//
// Named with an `Item` suffix to avoid colliding with the unrelated
// `ProgressionSuggestion` class in
// `lib/data/models/exercise_progression.dart`. Difficulty is an INTEGER 1-10
// (`difficulty_level`), not a float score.
// ===========================================================================

class ProgressionSuggestionItem {
  final String exerciseName;
  final int currentDifficultyLevel;
  final String suggestedExercise;
  final int suggestedDifficultyLevel;
  final String chainId;
  final String chainName;
  final String reason;
  final double confidence;
  final Map<String, dynamic> stats;

  const ProgressionSuggestionItem({
    required this.exerciseName,
    required this.currentDifficultyLevel,
    required this.suggestedExercise,
    required this.suggestedDifficultyLevel,
    required this.chainId,
    required this.chainName,
    required this.reason,
    required this.confidence,
    this.stats = const {},
  });

  factory ProgressionSuggestionItem.fromJson(Map<String, dynamic> json) {
    return ProgressionSuggestionItem(
      exerciseName: (json['exercise_name'] ?? '').toString(),
      currentDifficultyLevel: _asInt(json['current_difficulty_level'], 5),
      suggestedExercise: (json['suggested_exercise'] ?? '').toString(),
      suggestedDifficultyLevel: _asInt(json['suggested_difficulty_level'], 6),
      chainId: (json['chain_id'] ?? '').toString(),
      chainName: (json['chain_name'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      confidence: _asDouble(json['confidence']).clamp(0.0, 1.0),
      stats: _asStringMap(json['stats']),
    );
  }
}

// ===========================================================================
// AcceptProgressionResponse — backend `AcceptProgressionResponse`.
// ===========================================================================

class AcceptProgressionResponse {
  final bool success;
  final String oldExercise;
  final ProgressionMasteryStatus oldStatus;
  final String newExercise;
  final ProgressionMasteryStatus newStatus;
  final String message;

  const AcceptProgressionResponse({
    required this.success,
    required this.oldExercise,
    required this.oldStatus,
    required this.newExercise,
    required this.newStatus,
    required this.message,
  });

  factory AcceptProgressionResponse.fromJson(Map<String, dynamic> json) {
    return AcceptProgressionResponse(
      success: _asBool(json['success']),
      oldExercise: (json['old_exercise'] ?? '').toString(),
      oldStatus: ProgressionMasteryStatus.fromValue(json['old_status']),
      newExercise: (json['new_exercise'] ?? '').toString(),
      newStatus: ProgressionMasteryStatus.fromValue(json['new_status']),
      message: (json['message'] ?? '').toString(),
    );
  }
}

// ===========================================================================
// HoldHistory — per-session best-hold series for a timed skill (Dr-Yaad #11).
// ===========================================================================

class HoldPoint {
  final DateTime performedAt;
  final int bestHoldSeconds;
  const HoldPoint({required this.performedAt, required this.bestHoldSeconds});

  factory HoldPoint.fromJson(Map<String, dynamic> json) => HoldPoint(
        performedAt:
            DateTime.tryParse((json['performed_at'] ?? '').toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0),
        bestHoldSeconds: _asInt(json['best_hold_seconds']),
      );
}

class HoldHistory {
  final String exerciseName;
  final List<HoldPoint> points;
  final int? currentBestHoldSeconds;
  final int? targetHoldSeconds;

  const HoldHistory({
    required this.exerciseName,
    required this.points,
    this.currentBestHoldSeconds,
    this.targetHoldSeconds,
  });

  bool get hasData => points.length >= 2;

  factory HoldHistory.fromJson(Map<String, dynamic> json) => HoldHistory(
        exerciseName: (json['exercise_name'] ?? '').toString(),
        points: (json['points'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => HoldPoint.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        currentBestHoldSeconds: json['current_best_hold_seconds'] == null
            ? null
            : _asInt(json['current_best_hold_seconds']),
        targetHoldSeconds: json['target_hold_seconds'] == null
            ? null
            : _asInt(json['target_hold_seconds']),
      );
}

// ===========================================================================
// Repository
// ===========================================================================

/// DI provider for the exercise-progressions repository.
final exerciseProgressionsRepositoryProvider =
    Provider<ExerciseProgressionsRepository>((ref) {
  return ExerciseProgressionsRepository(ref.watch(apiClientProvider));
});

/// Thin HTTP wrapper for the `/exercise-progressions/*` endpoints.
///
/// Each method returns the typed model; errors bubble up so the UI can show a
/// real error state. We do NOT swallow exceptions here per the
/// no-silent-fallbacks rule.
class ExerciseProgressionsRepository {
  final ApiClient _client;

  ExerciseProgressionsRepository(this._client);

  /// GET /exercise-progressions/user/{userId}/mastery
  ///
  /// Returns every exercise the user has tracked mastery for. When
  /// [readyOnly] is true the backend filters to exercises flagged
  /// `ready_for_progression`.
  Future<List<ExerciseMasteryWithChain>> getUserMastery(
    String userId, {
    bool readyOnly = false,
  }) async {
    debugPrint('🏋️ [Progressions] mastery | user=$userId readyOnly=$readyOnly');
    final resp = await _client.get(
      '/exercise-progressions/user/$userId/mastery',
      queryParameters: readyOnly ? {'ready_only': true} : null,
    );
    final data = resp.data as List<dynamic>? ?? const [];
    return data
        .whereType<Map>()
        .map((e) =>
            ExerciseMasteryWithChain.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// GET /exercise-progressions/user/{userId}/suggestions
  ///
  /// Exercises the user is ready to advance on, with the suggested next
  /// (harder) variant and a confidence score.
  Future<List<ProgressionSuggestionItem>> getSuggestions(String userId) async {
    debugPrint('🏋️ [Progressions] suggestions | user=$userId');
    final resp = await _client.get(
      '/exercise-progressions/user/$userId/suggestions',
    );
    final data = resp.data as List<dynamic>? ?? const [];
    return data
        .whereType<Map>()
        .map((e) =>
            ProgressionSuggestionItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// GET /exercise-progressions/user/{userId}/hold-history/{exerciseName}
  ///
  /// Per-session best-hold time-series for a timed skill (Dr-Yaad #11). Drives
  /// the hold-time chart. Returns an empty-points [HoldHistory] for first-timers.
  Future<HoldHistory> getHoldHistory(String userId, String exerciseName) async {
    debugPrint('🏋️ [Progressions] hold-history | user=$userId ex=$exerciseName');
    final resp = await _client.get(
      '/exercise-progressions/user/$userId/hold-history/'
      '${Uri.encodeComponent(exerciseName)}',
    );
    return HoldHistory.fromJson(Map<String, dynamic>.from(resp.data as Map));
  }

  /// GET /exercise-progressions/chains
  ///
  /// All progression chains (each carries its ordered steps list).
  /// Optionally filter by [category] (e.g. pushup, pullup, squat).
  Future<List<ProgressionChain>> getChains({String? category}) async {
    final query = <String, dynamic>{};
    if (category != null && category.isNotEmpty) {
      query['category'] = category;
    }
    debugPrint('🏋️ [Progressions] chains | filters=$query');
    final resp = await _client.get(
      '/exercise-progressions/chains',
      queryParameters: query.isEmpty ? null : query,
    );
    final data = resp.data as List<dynamic>? ?? const [];
    return data
        .whereType<Map>()
        .map((e) => ProgressionChain.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// POST /exercise-progressions/user/{userId}/accept-progression
  ///
  /// User accepts a progression: marks [currentExercise] as progressed and
  /// starts a fresh mastery record for [newExercise].
  Future<AcceptProgressionResponse> acceptProgression({
    required String userId,
    required String currentExercise,
    required String newExercise,
  }) async {
    debugPrint(
        '🏋️ [Progressions] accept | $currentExercise -> $newExercise');
    final resp = await _client.post(
      '/exercise-progressions/user/$userId/accept-progression',
      data: {
        'current_exercise': currentExercise,
        'new_exercise': newExercise,
      },
    );
    return AcceptProgressionResponse.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }
}
