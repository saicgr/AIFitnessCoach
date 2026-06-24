// Exercise alternatives — "swap this exercise" suggestions.
//
// HAND-WRITTEN — NO codegen (the repo's analyzer crashes on build_runner; see
// project_codegen_gotcha). [ExerciseAlternative] carries a manual `fromJson`,
// matching the plain-immutable style of `data/models/program_template.dart`.
//
// Backed by `GET /api/v1/exercises/{exercise_id}/alternatives`. The relative
// path resolves against the Dio base URL (`ApiConstants.apiBaseUrl`, i.e.
// `/api/v1`) configured on [apiClientProvider] — same convention as the rest
// of the exercises API.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

// ---------------------------------------------------------------------------
// ExerciseAlternative — one suggested swap for a given exercise.
// ---------------------------------------------------------------------------

/// A single alternative exercise returned by
/// `GET /exercises/{id}/alternatives`. Mirrors the backend row shape exactly.
class ExerciseAlternative {
  final String name;
  final String? targetMuscle;
  final String? bodyPart;
  final String? equipment;
  final String? difficultyLevel;

  /// Animated demonstration (may be null when only a still exists).
  final String? gifUrl;

  /// Static illustration / thumbnail (may be null).
  final String? imageUrl;

  /// Why this is a good swap — e.g. "same target muscle, no barbell needed".
  final String? reason;

  const ExerciseAlternative({
    required this.name,
    this.targetMuscle,
    this.bodyPart,
    this.equipment,
    this.difficultyLevel,
    this.gifUrl,
    this.imageUrl,
    this.reason,
  });

  factory ExerciseAlternative.fromJson(Map<String, dynamic> json) {
    String? str(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return ExerciseAlternative(
      name: json['name']?.toString() ?? 'Exercise',
      targetMuscle: str(json['target_muscle']),
      bodyPart: str(json['body_part']),
      equipment: str(json['equipment']),
      difficultyLevel: str(json['difficulty_level']),
      gifUrl: str(json['gif_url']),
      imageUrl: str(json['image_url']),
      reason: str(json['reason']),
    );
  }
}

// ---------------------------------------------------------------------------
// Repository — thin HTTP wrapper, errors bubble (no mock/fallback data).
// ---------------------------------------------------------------------------

/// DI provider for the alternatives repository.
final exerciseAlternativesRepositoryProvider =
    Provider<ExerciseAlternativesRepository>((ref) {
  return ExerciseAlternativesRepository(ref.watch(apiClientProvider));
});

/// Fetches alternative exercises for a given exercise id. Lets Dio exceptions
/// bubble so the screen converts them into human copy + a Retry — we never
/// swallow errors or substitute fabricated alternatives.
class ExerciseAlternativesRepository {
  final ApiClient _client;
  ExerciseAlternativesRepository(this._client);

  /// GET /exercises/{exercise_id}/alternatives →
  /// `{alternatives:[<ExerciseAlternative json>]}`.
  Future<List<ExerciseAlternative>> getAlternatives(String exerciseId) async {
    debugPrint('🏋️ [ExerciseAlternatives] getAlternatives | id=$exerciseId');
    final resp = await _client.get('/exercises/$exerciseId/alternatives');
    final data = resp.data;
    final raw = data is Map ? data['alternatives'] : null;
    final out = <ExerciseAlternative>[];
    if (raw is List) {
      for (final a in raw) {
        if (a is Map) {
          out.add(ExerciseAlternative.fromJson(Map<String, dynamic>.from(a)));
        }
      }
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// Provider.
// ---------------------------------------------------------------------------

/// Alternatives for one exercise, keyed by exercise id. autoDispose +
/// `keepAlive` so reopening the same swap sheet is instant, while distinct
/// exercises don't pile up forever. Errors propagate to the FutureProvider so
/// the UI shows its error + Retry state — we do NOT fail-open to an empty list
/// (that would hide a real failure and fabricate "no alternatives").
final exerciseAlternativesProvider = FutureProvider.autoDispose
    .family<List<ExerciseAlternative>, String>((ref, exerciseId) async {
  ref.keepAlive();
  final repo = ref.watch(exerciseAlternativesRepositoryProvider);
  return repo.getAlternatives(exerciseId);
});
