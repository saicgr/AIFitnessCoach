part of 'workout_repository.dart';

/// Short-lived per-workout cache for warmup/stretch reads so the workout-detail
/// screen's prefetch (on mount) warms the active-workout screen's read — the
/// warm-up appears instantly on "Start" instead of after a fresh network
/// round-trip. TTL is deliberately short so a regeneration/reorder isn't served
/// stale; mutations also evict.
class _WarmupStretchCacheEntry {
  final DateTime at;
  final List<Map<String, dynamic>>? warmup;
  final List<Map<String, dynamic>>? stretches;
  const _WarmupStretchCacheEntry(this.at, this.warmup, this.stretches);
}

final Map<String, _WarmupStretchCacheEntry> _warmupStretchCache = {};
const Duration _warmupStretchCacheTtl = Duration(seconds: 90);

/// Extension on WorkoutRepository for exercise management methods:
/// warmup/stretches generation, exercise suggestions, swap, add,
/// parse input, extend workout, custom workout creation.
extension WorkoutRepositoryExercises on WorkoutRepository {
  /// Generate warmup exercises for a workout
  ///
  /// If [durationMinutes] is null, uses the user's preference from backend (default 5 min).
  Future<List<Map<String, dynamic>>> generateWarmup(
    String workoutId, {
    int? durationMinutes,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (durationMinutes != null) {
        queryParams['duration_minutes'] = durationMinutes;
      }
      final response = await apiClient.post(
        '${ApiConstants.workouts}/$workoutId/warmup',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response.statusCode == 200) {
        // Regeneration changed the persisted list → drop the read cache.
        _warmupStretchCache.remove(workoutId);
        final data = response.data as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['exercises'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error generating warmup: $e');
      return [];
    }
  }

  /// Generate stretches for a workout
  ///
  /// If [durationMinutes] is null, uses the user's preference from backend (default 5 min).
  Future<List<Map<String, dynamic>>> generateStretches(
    String workoutId, {
    int? durationMinutes,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (durationMinutes != null) {
        queryParams['duration_minutes'] = durationMinutes;
      }
      final response = await apiClient.post(
        '${ApiConstants.workouts}/$workoutId/stretches',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response.statusCode == 200) {
        // Regeneration changed the persisted list → drop the read cache.
        _warmupStretchCache.remove(workoutId);
        final data = response.data as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['exercises'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error generating stretches: $e');
      return [];
    }
  }

  /// Generate both warmup and stretches
  ///
  /// If durations are null, uses the user's preferences from backend (default 5 min each).
  Future<Map<String, List<Map<String, dynamic>>>> generateWarmupAndStretches(
    String workoutId, {
    int? warmupDurationMinutes,
    int? stretchDurationMinutes,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (warmupDurationMinutes != null) {
        queryParams['warmup_duration'] = warmupDurationMinutes;
      }
      if (stretchDurationMinutes != null) {
        queryParams['stretch_duration'] = stretchDurationMinutes;
      }
      final response = await apiClient.post(
        '${ApiConstants.workouts}/$workoutId/warmup-and-stretches',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response.statusCode == 200) {
        // Regeneration changed the persisted lists → drop the read cache.
        _warmupStretchCache.remove(workoutId);
        final data = response.data as Map<String, dynamic>;
        return {
          'warmup': List<Map<String, dynamic>>.from(data['warmup']?['exercises_json'] ?? data['warmup']?['exercises'] ?? []),
          'stretches': List<Map<String, dynamic>>.from(data['stretches']?['exercises_json'] ?? data['stretches']?['exercises'] ?? []),
        };
      }
      return {'warmup': [], 'stretches': []};
    } catch (e, stackTrace) {
      debugPrint('❌ [Workout] Error generating warmup/stretches: $e');
      debugPrint('❌ [Workout] Warmup stackTrace: $stackTrace');
      return {'warmup': [], 'stretches': []};
    }
  }

  /// Read the PERSISTED warmup + stretches for a workout (GET, no regeneration).
  ///
  /// Each list is `null` when the server has none yet (404) so the caller can
  /// decide whether to generate. Real network/server errors are RETHROWN so the
  /// UI can surface a retry state instead of silently showing a misleading
  /// hardcoded default list (see `feedback_no_silent_fallbacks`).
  Future<({List<Map<String, dynamic>>? warmup, List<Map<String, dynamic>>? stretches})>
      fetchWarmupAndStretches(String workoutId, {bool forceRefresh = false}) async {
    // Cache hit (fresh) → instant, no network. Bridges detail → active.
    final cached = _warmupStretchCache[workoutId];
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.at) < _warmupStretchCacheTtl) {
      return (warmup: cached.warmup, stretches: cached.stretches);
    }
    Future<List<Map<String, dynamic>>?> readSection(String section) async {
      try {
        final response =
            await apiClient.get('${ApiConstants.workouts}/$workoutId/$section');
        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          return List<Map<String, dynamic>>.from(
              data['exercises_json'] ?? data['exercises'] ?? []);
        }
        return null;
      } on DioException catch (e) {
        // 404 = not generated yet → signal "needs generation", not an error.
        if (e.response?.statusCode == 404) return null;
        rethrow;
      }
    }

    final results = await Future.wait([
      readSection('warmup'),
      readSection('stretches'),
    ]);
    _warmupStretchCache[workoutId] =
        _WarmupStretchCacheEntry(DateTime.now(), results[0], results[1]);
    return (warmup: results[0], stretches: results[1]);
  }

  /// Persist a user-reordered warmup ([section] == 'warmup') or stretch
  /// ([section] == 'stretches') list for a workout. Sends the FULL reordered
  /// list of raw item maps; the backend rewrites the current row's
  /// `exercises_json` in place (a reorder is not a regeneration). Throws on
  /// network/server error so callers can surface a retry / revert.
  Future<void> saveWarmupStretchOrder(
    String workoutId,
    String section,
    List<Map<String, dynamic>> exercises,
  ) async {
    // NOTE the `/exercises` suffix. `PUT /{id}/warmup` and `PUT /{id}/stretches`
    // do not exist — those paths only accept GET/POST, so FastAPI answered the
    // reorder with 405 every time. The persist routes are
    // `PUT /{id}/warmup/exercises` and `PUT /{id}/stretches/exercises`.
    await apiClient.put(
      '${ApiConstants.workouts}/$workoutId/$section/exercises',
      data: {'exercises': exercises},
    );
    // A reorder changes the persisted list — drop the cache so the next read
    // (active screen) reflects it instead of the pre-reorder order.
    _warmupStretchCache.remove(workoutId);
  }

  /// Read the user's SAVED warm-up template (E2E #125) — the customization
  /// that CARRIES FORWARD across workouts, distinct from the per-workout
  /// `warmups` row `fetchWarmupAndStretches` reads. Returns null on a 404
  /// (nothing saved yet for this workout type) or any other failure, so the
  /// caller falls back to normal generation — never a fabricated warm-up.
  Future<List<Map<String, dynamic>>?> fetchWarmupTemplate({
    String? workoutType,
  }) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.workouts}/warmup-template',
        queryParameters:
            workoutType != null ? {'workout_type': workoutType} : null,
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['exercises'] ?? []);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null; // nothing saved yet
      debugPrint('❌ [Workout] fetchWarmupTemplate failed: $e');
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] fetchWarmupTemplate failed: $e');
      return null;
    }
  }

  /// Persist the CUSTOMIZED warm-up (add/remove/swap/duration/rest edits) so
  /// the NEXT workout of this type starts from it instead of a fresh AI
  /// generation every time. Fire this only when the user actually changed
  /// something this run. Throws on failure so the caller can log it instead
  /// of silently dropping the save.
  Future<void> saveWarmupTemplate({
    String? workoutType,
    required List<Map<String, dynamic>> exercises,
  }) async {
    await apiClient.put(
      '${ApiConstants.workouts}/warmup-template',
      data: {
        'workout_type': workoutType,
        'exercises': exercises,
      },
    );
  }

  /// Seed a brand-new workout's `warmups` row from the user's saved
  /// template. Returns the applied exercise list, or null when the user has
  /// no saved template (404) — the caller falls back to
  /// `fetchWarmupAndStretches`. Any other failure also resolves to null
  /// (never blocks workout start on a template-apply hiccup).
  Future<List<Map<String, dynamic>>?> applyWarmupTemplate(
    String workoutId,
  ) async {
    try {
      final response = await apiClient.post(
        '${ApiConstants.workouts}/$workoutId/warmup/apply-template',
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        // The per-workout row now reflects the applied template — drop the
        // read cache so a subsequent fetchWarmupAndStretches (e.g. the
        // legacy Advanced path) sees it instead of a stale/empty entry.
        _warmupStretchCache.remove(workoutId);
        return List<Map<String, dynamic>>.from(data['exercises'] ?? []);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null; // no saved template
      debugPrint('❌ [Workout] applyWarmupTemplate failed: $e');
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] applyWarmupTemplate failed: $e');
      return null;
    }
  }

  /// Get AI exercise swap suggestions.
  ///
  /// Pass a known chip label in [reason] ("Too difficult", "Too easy", ...)
  /// or a freeform user message in [customMessage]. If both are provided,
  /// [customMessage] wins. Throws on network / API errors so callers can
  /// distinguish an empty result from a failed request.
  Future<List<Map<String, dynamic>>> getExerciseSuggestions({
    required String workoutId,
    required WorkoutExercise exercise,
    required String userId,
    String? reason,
    String? customMessage,
    List<String>? avoidedExercises,
    List<String>? userEquipment,
  }) async {
    // Known reason chip → canned message mapping. Any reason value NOT in
    // this map is treated as freeform user text, so typing "I only have
    // dumbbells" no longer gets silently replaced with the default message.
    const chipMessages = {
      'Too difficult': 'I need an easier alternative',
      'Too easy': 'I want something more challenging',
      'Equipment unavailable': "I don't have the equipment for this exercise",
      'Injury concern': 'I have an injury and need a safer alternative',
      'Personal preference': 'I want a different exercise for variety',
      // AI Picks chip strip (shown above the input on the AI Picks tab) —
      // these phrases are tuned to make the suggestion graph return real,
      // muscle-aware alternatives instead of the previous "no alternatives
      // matched" empty state on a generic default message.
      'Similar muscles':
          'Suggest alternatives that target the same muscles with my available equipment',
      'Easier': 'I need an easier alternative',
      'Harder': 'I want something more challenging',
      'No machine needed':
          'Suggest alternatives that do not require gym machines',
      'Bodyweight only':
          'I only have my bodyweight — bodyweight-only alternatives please',
      'Different angle':
          'Suggest a different movement angle that hits the same muscles',
    };

    final freeform = customMessage?.trim();
    String message;
    if (freeform != null && freeform.isNotEmpty) {
      message = freeform;
    } else if (reason != null && chipMessages.containsKey(reason)) {
      message = chipMessages[reason]!;
    } else if (reason != null && reason.trim().isNotEmpty) {
      // Unknown reason value — assume the caller passed freeform text.
      message = reason.trim();
    } else {
      // Default auto-load message — context-rich enough that the suggestion
      // graph returns muscle-similar alternatives, not the previous "I want
      // an alternative exercise" that the agent occasionally treated as too
      // vague and short-circuited to empty.
      final muscle =
          exercise.muscleGroup ?? exercise.primaryMuscle ?? exercise.bodyPart;
      message = muscle != null && muscle.isNotEmpty
          ? 'Suggest exercises that target $muscle similar to ${exercise.name} using my available equipment'
          : 'Suggest exercises similar to ${exercise.name} using my available equipment';
    }

    debugPrint('🔍 [Workout] Getting suggestions for ${exercise.name} — message: "$message"');
    if (avoidedExercises != null && avoidedExercises.isNotEmpty) {
      debugPrint('🚫 [Workout] Filtering ${avoidedExercises.length} avoided exercises');
    }

    final response = await apiClient.post(
      '/exercise-suggestions/suggest',
      data: {
        'user_id': userId,
        'message': message,
        'current_exercise': {
          'name': exercise.name,
          'sets': exercise.sets ?? 3,
          'reps': exercise.reps ?? 10,
          'muscle_group': exercise.muscleGroup ?? exercise.primaryMuscle ?? exercise.bodyPart,
          'equipment': exercise.equipment,
        },
        if (avoidedExercises != null && avoidedExercises.isNotEmpty)
          'avoided_exercises': avoidedExercises,
        // Pass the user's configured equipment list so the backend can
        // filter AI Picks to compatible items only. Without this, a
        // bodyweight-only user receives suspension-trainer / pullup-bar
        // suggestions because the LangGraph search node can only fall
        // back to free-text constraint extraction (which misses the
        // common "I have no equipment" case for variety/difficulty
        // swaps where equipment isn't mentioned).
        if (userEquipment != null) 'user_equipment': userEquipment,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Server returned ${response.statusCode}');
    }
    final data = response.data as Map<String, dynamic>;
    final suggestions = List<Map<String, dynamic>>.from(data['suggestions'] ?? []);
    debugPrint('✅ [Workout] Got ${suggestions.length} suggestions');
    return suggestions;
  }

  /// Get AI exercise suggestions for adding to a workout (not swapping)
  Future<List<Map<String, dynamic>>> getExerciseSuggestionsForAdd({
    required String workoutType,
    required List<String> existingExercises,
    required String userId,
    List<String>? avoidedExercises,
  }) async {
    try {
      final message =
          'Suggest exercises to add to my $workoutType workout that already has: ${existingExercises.join(', ')}';

      debugPrint('🔍 [Workout] Getting add suggestions for $workoutType workout');

      final response = await apiClient.post(
        '/exercise-suggestions/suggest',
        data: {
          'user_id': userId,
          'message': message,
          'current_exercise': {
            'name': '',
            'muscle_group': workoutType,
          },
          'existing_exercises': existingExercises,
          'mode': 'add',
          if (avoidedExercises != null && avoidedExercises.isNotEmpty)
            'avoided_exercises': avoidedExercises,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final suggestions = List<Map<String, dynamic>>.from(data['suggestions'] ?? []);
        debugPrint('✅ [Workout] Got ${suggestions.length} add suggestions');
        return suggestions;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error getting add exercise suggestions: $e');
      return [];
    }
  }

  /// Swap an exercise in a workout
  /// Swap an exercise in a workout. Returns (Workout?, errorMessage?).
  /// errorMessage is non-null only on failure, with a user-friendly description.
  ///
  /// When [previewId] is non-null, the swap is applied to the regeneration
  /// preview cache via `POST /api/v1/workouts/preview/swap-exercise` instead of
  /// the committed-workout endpoint. Backend returns the updated preview payload
  /// with the same shape as a committed Workout. Typed exceptions are thrown for
  /// preview-specific error codes so callers can distinguish them from generic
  /// network failures:
  ///   - [PreviewExpiredException] on 404 `PREVIEW_EXPIRED`
  ///   - [PreviewNotOwnedException] on 403 `PREVIEW_NOT_OWNED`
  /// See Phase 1C/1D of the regenerate safety plan.
  Future<(Workout?, String?)> swapExercise({
    required String workoutId,
    required String oldExerciseName,
    required String newExerciseName,
    String? reason,
    String swapSource = 'ai_suggestion',
    String? section,
    Map<String, double>? cardioParams,
    String? previewId,
    bool applyToFuture = false,
  }) async {
    try {
      // Route to the preview endpoint when a preview_id is present so we
      // mutate the short-lived cache entry rather than the committed workout.
      final endpoint = previewId != null
          ? '${ApiConstants.workouts}/preview/swap-exercise'
          : '${ApiConstants.workouts}/swap-exercise';

      debugPrint('🔍 [Workout] Swap exercise → $endpoint'
          '${previewId != null ? ' [preview:$previewId]' : ''}');

      final response = await apiClient.post(
        endpoint,
        data: {
          'workout_id': workoutId,
          'old_exercise_name': oldExerciseName,
          'new_exercise_name': newExerciseName,
          if (reason != null) 'reason': reason,
          'swap_source': swapSource,
          if (section != null) 'section': section,
          if (previewId != null) 'preview_id': previewId,
          // Persisting a swap only makes sense for committed workouts, not the
          // short-lived regeneration preview cache.
          if (previewId == null && applyToFuture) 'apply_to_future': true,
          if (cardioParams != null) ...cardioParams,
        },
      );
      if (response.statusCode == 200) {
        return (Workout.fromJson(response.data as Map<String, dynamic>), null);
      }
      debugPrint('❌ [Workout] Swap failed with status ${response.statusCode}: ${response.data}');
      return (null, 'Server error (${response.statusCode}). Please try again.');
    } on DioException catch (e, stackTrace) {
      debugPrint('❌ [Workout] Error swapping exercise: $e\n$stackTrace');
      // FastAPI's HTTPException handler wraps every error body under a
      // top-level `detail` key (`content={"detail": exc.detail}` in
      // main.py's http_exception_handler) — the machine-readable code lives
      // at `detail.error`, NOT a top-level `error_code` (that key never
      // existed in any response this endpoint sends). Reading the wrong
      // shape meant NEITHER of the two typed exceptions below, nor the new
      // injury one, ever actually fired — every 404/403/409 silently fell
      // through to the generic "Failed to swap exercise" message.
      final body = e.response?.data;
      final detail = body is Map ? body['detail'] : null;
      final errorCode = detail is Map ? detail['error'] as String? : null;
      final serverMessage = detail is Map ? detail['message'] as String? : null;
      final status = e.response?.statusCode;
      // The injury-safety guard applies to BOTH the preview cache AND a
      // committed workout — a user can swap into an unsafe exercise on
      // either path, so this check is intentionally UNGATED by previewId
      // (unlike the two preview-lifecycle exceptions below, which are only
      // meaningful for the short-lived preview flow).
      if (status == 409 && errorCode == 'EXERCISE_UNSAFE_FOR_INJURY') {
        final injuries = detail is Map && detail['injuries'] is List
            ? (detail['injuries'] as List).whereType<String>().toList()
            : const <String>[];
        throw ExerciseUnsafeForInjuryException(
          (detail is Map ? detail['exercise'] as String? : null) ??
              newExerciseName,
          serverMessage ??
              '$newExerciseName isn\'t safe to program around an active '
                  'injury right now. Pick a different exercise, or mark '
                  'that injury healed first.',
          injuries: injuries,
        );
      }
      // Typed exceptions for preview-specific error codes — callers (e.g. the
      // review sheet) can catch these distinctly and surface targeted copy.
      if (previewId != null) {
        if (status == 404 && errorCode == 'PREVIEW_EXPIRED') {
          throw PreviewExpiredException(previewId, serverMessage ?? e.message ?? 'Preview expired during swap');
        }
        if (status == 403 && errorCode == 'PREVIEW_NOT_OWNED') {
          throw PreviewNotOwnedException(previewId, serverMessage ?? e.message ?? 'Preview not owned');
        }
      }
      if (status == 429) {
        return (null, 'Too many swaps. Please wait a moment and try again.');
      }
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        return (null, 'Request timed out. Please try again.');
      }
      return (null, 'Failed to swap exercise. Please try again.');
    } catch (e, stackTrace) {
      // Non-Dio errors only (e.g. a JSON decode failure on a 200 response) —
      // the typed exceptions above are thrown FROM the `on DioException`
      // clause and propagate straight to the caller without re-entering this
      // generic clause.
      debugPrint('❌ [Workout] Error swapping exercise: $e\n$stackTrace');
      return (null, 'Failed to swap exercise. Please try again.');
    }
  }

  /// List the user's active persistent exercise substitutions (A -> B), created
  /// when a swap is made with "Apply to future workouts" on.
  Future<List<Map<String, dynamic>>> listSubstitutions() async {
    try {
      final response =
          await apiClient.get('${ApiConstants.workouts}/substitutions');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final rows = (data['substitutions'] as List?) ?? const [];
        return rows.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('❌ [Workout] listSubstitutions failed: $e');
    }
    return const [];
  }

  /// Deactivate a persistent substitution so future generations revert to the
  /// AI's choice for that exercise.
  Future<bool> deleteSubstitution(String id) async {
    try {
      final response =
          await apiClient.delete('${ApiConstants.workouts}/substitutions/$id');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [Workout] deleteSubstitution failed: $e');
      return false;
    }
  }

  /// Replace a single workout's ordered exercise list (reorder/remove/edit) and
  /// PIN the workout so a later program change won't overwrite the hand-edit
  /// (F5). Returns the updated workout, or null + message on failure.
  Future<(Workout?, String?)> editWorkoutExercises({
    required String workoutId,
    required List<Map<String, dynamic>> exercises,
  }) async {
    try {
      final response = await apiClient.patch(
        '${ApiConstants.workouts}/$workoutId/exercises',
        data: {'exercises': exercises},
      );
      if (response.statusCode == 200) {
        return (Workout.fromJson(response.data as Map<String, dynamic>), null);
      }
      return (null, 'Server error (${response.statusCode}). Please try again.');
    } catch (e) {
      debugPrint('❌ [Workout] editWorkoutExercises failed: $e');
      return (null, 'Failed to save changes. Please try again.');
    }
  }

  /// Undo a hand-edit: delete the pinned workout so it regenerates from the
  /// current plan on the next read. Returns true on success.
  Future<bool> resetWorkoutToPlan(String workoutId) async {
    try {
      final response = await apiClient
          .post('${ApiConstants.workouts}/$workoutId/reset-to-plan');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [Workout] resetWorkoutToPlan failed: $e');
      return false;
    }
  }

  /// Add a new exercise to a workout. Returns `(workout, errorMessage)` —
  /// same shape as [swapExercise] — so a non-exception failure (server
  /// error, timeout) still reaches the caller with real copy instead of a
  /// bare null that collapses into a flat "Failed to add exercise".
  ///
  /// When [previewId] is non-null, the add is applied to the regeneration
  /// preview cache via `POST /api/v1/workouts/preview/add-exercise` instead of
  /// the committed-workout endpoint. Backend returns the updated preview payload
  /// with the same shape as a committed Workout. Typed exceptions are THROWN
  /// (not returned in the tuple) so callers that want to branch on them can —
  /// see [swapOrAddExceptionMessage] for a ready-made string for callers that
  /// just need copy:
  ///   - [ExerciseUnsafeForInjuryException] on 409 `EXERCISE_UNSAFE_FOR_INJURY`
  ///     (ungated by previewId — a committed-workout add can hit this too)
  ///   - [PreviewExpiredException] on 404 `PREVIEW_EXPIRED` (preview only)
  ///   - [PreviewNotOwnedException] on 403 `PREVIEW_NOT_OWNED` (preview only)
  /// See Phase 1C/1D of the regenerate safety plan.
  Future<(Workout?, String?)> addExercise({
    required String workoutId,
    required String exerciseName,
    String? exerciseId,
    int sets = 3,
    String reps = '8-12',
    int restSeconds = 60,
    String? section,
    Map<String, double>? cardioParams,
    String? previewId,
  }) async {
    // Route to the preview endpoint when a preview_id is present.
    final endpoint = previewId != null
        ? '${ApiConstants.workouts}/preview/add-exercise'
        : '${ApiConstants.workouts}/add-exercise';

    try {
      debugPrint('🔍 [Workout] Adding exercise "$exerciseName" (id: $exerciseId) → $endpoint'
          '${previewId != null ? ' [preview:$previewId]' : ''}');
      final response = await apiClient.post(
        endpoint,
        data: {
          'workout_id': workoutId,
          'exercise_name': exerciseName,
          if (exerciseId != null) 'exercise_id': exerciseId,
          'sets': sets,
          'reps': reps,
          'rest_seconds': restSeconds,
          if (section != null) 'section': section,
          if (previewId != null) 'preview_id': previewId,
          if (cardioParams != null) ...cardioParams,
        },
      );
      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Exercise added successfully');
        return (Workout.fromJson(response.data as Map<String, dynamic>), null);
      }
      debugPrint('❌ [Workout] Add failed with status ${response.statusCode}: ${response.data}');
      return (null, 'Server error (${response.statusCode}). Please try again.');
    } on DioException catch (e, stackTrace) {
      debugPrint('❌ [Workout] Error adding exercise: $e\n$stackTrace');
      // See swapExercise's identical comment: the error code lives at
      // `detail.error`, never a top-level `error_code`.
      final body = e.response?.data;
      final detail = body is Map ? body['detail'] : null;
      final errorCode = detail is Map ? detail['error'] as String? : null;
      final serverMessage = detail is Map ? detail['message'] as String? : null;
      final status = e.response?.statusCode;
      if (status == 409 && errorCode == 'EXERCISE_UNSAFE_FOR_INJURY') {
        final injuries = detail is Map && detail['injuries'] is List
            ? (detail['injuries'] as List).whereType<String>().toList()
            : const <String>[];
        throw ExerciseUnsafeForInjuryException(
          (detail is Map ? detail['exercise'] as String? : null) ??
              exerciseName,
          serverMessage ??
              '$exerciseName isn\'t safe to program around an active '
                  'injury right now. Pick a different exercise, or mark '
                  'that injury healed first.',
          injuries: injuries,
        );
      }
      // Surface typed exceptions for preview-specific error codes.
      if (previewId != null) {
        if (status == 404 && errorCode == 'PREVIEW_EXPIRED') {
          throw PreviewExpiredException(previewId, serverMessage ?? e.message ?? 'Preview expired during add');
        }
        if (status == 403 && errorCode == 'PREVIEW_NOT_OWNED') {
          throw PreviewNotOwnedException(previewId, serverMessage ?? e.message ?? 'Preview not owned');
        }
      }
      if (status == 429) {
        return (null, 'Too many additions. Please wait a moment and try again.');
      }
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        return (null, 'Request timed out. Please try again.');
      }
      return (null, 'Failed to add exercise. Please try again.');
    } catch (e, stackTrace) {
      debugPrint('❌ [Workout] Error adding exercise: $e\n$stackTrace');
      return (null, 'Failed to add exercise. Please try again.');
    }
  }

  /// Parse natural language workout input using AI.
  ///
  /// Accepts text, image (base64), or voice transcript and returns
  /// structured exercise data.
  ///
  /// Examples:
  /// - "3x10 deadlift at 135, 5x5 squat at 140"
  /// - "bench press 4 sets of 8 at 80"
  Future<ParseWorkoutInputResponse?> parseWorkoutInput({
    required String userId,
    required String workoutId,
    String? inputText,
    String? imageBase64,
    String? voiceTranscript,
    bool useKg = false,
  }) async {
    try {
      debugPrint('🤖 [Workout] Parsing workout input: text=${inputText?.substring(0, inputText.length.clamp(0, 50)) ?? "none"}');

      final response = await apiClient.post(
        '${ApiConstants.workouts}/parse-input',
        data: {
          'user_id': userId,
          'workout_id': workoutId,
          if (inputText != null) 'input_text': inputText,
          if (imageBase64 != null) 'image_base64': imageBase64,
          if (voiceTranscript != null) 'voice_transcript': voiceTranscript,
          'use_kg': useKg,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final result = ParseWorkoutInputResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        debugPrint('✅ [Workout] Parsed ${result.exercises.length} exercises');
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error parsing workout input: $e');
      rethrow;
    }
  }

  /// Parse workout input with dual-mode support (V2).
  ///
  /// Supports TWO use cases simultaneously:
  /// 1. Set logging: "135*8, 145*6" -> logs sets for CURRENT exercise
  /// 2. Add exercise: "3x10 deadlift at 135" -> adds NEW exercise
  ///
  /// Smart shortcuts supported:
  /// - "+10" -> add 10 to last weight
  /// - "same" -> repeat last set
  /// - "drop" -> 10% weight reduction
  Future<ParseWorkoutInputV2Response?> parseWorkoutInputV2({
    required String userId,
    required String workoutId,
    String? currentExerciseName,
    int? currentExerciseIndex,
    double? lastSetWeight,
    int? lastSetReps,
    String? inputText,
    String? imageBase64,
    String? voiceTranscript,
    bool useKg = false,
  }) async {
    try {
      debugPrint(
        '🤖 [Workout] Parsing V2: exercise=$currentExerciseName, '
        'text=${inputText?.substring(0, inputText.length.clamp(0, 50)) ?? "none"}',
      );

      final response = await apiClient.post(
        '${ApiConstants.workouts}/parse-input-v2',
        data: {
          'user_id': userId,
          'workout_id': workoutId,
          if (currentExerciseName != null)
            'current_exercise_name': currentExerciseName,
          if (currentExerciseIndex != null)
            'current_exercise_index': currentExerciseIndex,
          if (lastSetWeight != null) 'last_set_weight': lastSetWeight,
          if (lastSetReps != null) 'last_set_reps': lastSetReps,
          if (inputText != null) 'input_text': inputText,
          if (imageBase64 != null) 'image_base64': imageBase64,
          if (voiceTranscript != null) 'voice_transcript': voiceTranscript,
          'use_kg': useKg,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final result = ParseWorkoutInputV2Response.fromJson(
          response.data as Map<String, dynamic>,
        );
        debugPrint(
          '✅ [Workout] Parsed ${result.setsToLog.length} sets, '
          '${result.exercisesToAdd.length} exercises',
        );
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error parsing workout input V2: $e');
      rethrow;
    }
  }

  /// Add multiple parsed exercises to a workout at once.
  ///
  /// Enriches exercises with library metadata and generates set_targets.
  Future<Workout?> addExercisesBatch({
    required String workoutId,
    required String userId,
    required List<ParsedExercise> exercises,
    bool useKg = false,
  }) async {
    try {
      debugPrint('🔍 [Workout] Adding ${exercises.length} exercises to workout $workoutId');

      final response = await apiClient.post(
        '${ApiConstants.workouts}/add-exercises-batch',
        data: {
          'workout_id': workoutId,
          'user_id': userId,
          'exercises': exercises.map((e) => e.toJson()).toList(),
          'use_kg': useKg,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] ${exercises.length} exercises added successfully');
        return Workout.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error adding exercises batch: $e');
      return null;
    }
  }

  /// Get user's recent exercise swaps for quick re-selection
  Future<List<Map<String, dynamic>>> getRecentSwapHistory({
    required String userId,
    int limit = 10,
  }) async {
    try {
      debugPrint('🔍 [Workout] Getting recent swaps for user $userId');
      final response = await apiClient.get(
        '/exercise-preferences/recent-swaps',
        queryParameters: {
          'user_id': userId,
          'limit': limit,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final swaps = List<Map<String, dynamic>>.from(response.data as List);
        debugPrint('✅ [Workout] Found ${swaps.length} recent swaps');
        return swaps;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [Workout] Error getting recent swaps: $e');
      return [];
    }
  }

  /// Get fast exercise suggestions using database queries (no AI).
  /// Returns 8 similar exercises based on muscle group and equipment.
  /// ~20x faster than AI suggestions (~500ms vs ~10s).
  ///
  /// Returns a record so the caller can distinguish between three empty
  /// states: `exercise_not_found` (lookup failed), `filtered_out`
  /// (candidates existed but the user's equipment eliminated all of
  /// them), and `no_match` (muscle query returned nothing). Lets the
  /// Similar tab show honest copy instead of the previous misleading
  /// "no exercises match this muscle group" for every empty result.
  ///
  /// Pass [userEquipment] from `environmentEquipmentProvider`. If null,
  /// the backend loads it from the users row server-side.
  Future<({List<Map<String, dynamic>> suggestions, String? emptyReason})>
      getExerciseSuggestionsFast({
    required String exerciseName,
    required String userId,
    List<String>? avoidedExercises,
    List<String>? userEquipment,
    bool ignoreEquipment = false,
  }) async {
    try {
      debugPrint(
          '🔍 [Workout] Getting fast suggestions for: $exerciseName (ignoreEquipment=$ignoreEquipment)');
      final response = await apiClient.post(
        '/exercise-suggestions/suggest-fast',
        data: {
          'exercise_name': exerciseName,
          'user_id': userId,
          'avoided_exercises': avoidedExercises ?? [],
          if (userEquipment != null) 'user_equipment': userEquipment,
          if (ignoreEquipment) 'ignore_equipment': true,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        // Backend now returns a {suggestions: [...], empty_reason: ...}
        // envelope. Defensive: tolerate the legacy bare-list shape too in
        // case an older server is hit during a rolling deploy.
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final suggestions = List<Map<String, dynamic>>.from(
            (data['suggestions'] as List?) ?? const [],
          );
          final emptyReason = data['empty_reason'] as String?;
          debugPrint(
            '✅ [Workout] Got ${suggestions.length} fast suggestions '
            '(empty_reason=$emptyReason)',
          );
          return (suggestions: suggestions, emptyReason: emptyReason);
        }
        if (data is List) {
          final suggestions = List<Map<String, dynamic>>.from(data);
          debugPrint(
            '✅ [Workout] Got ${suggestions.length} fast suggestions (legacy shape)',
          );
          return (suggestions: suggestions, emptyReason: null);
        }
      }
      return (suggestions: <Map<String, dynamic>>[], emptyReason: 'no_match');
    } catch (e) {
      debugPrint('❌ [Workout] Error getting fast suggestions: $e');
      return (suggestions: <Map<String, dynamic>>[], emptyReason: 'no_match');
    }
  }

  /// Extend a workout with additional AI-generated exercises
  ///
  /// Used when users feel the workout wasn't enough and want to "do more".
  /// The AI will generate complementary exercises based on the existing workout.
  Future<Workout?> extendWorkout({
    required String workoutId,
    required String userId,
    int additionalExercises = 3,
    int additionalDurationMinutes = 15,
    bool focusSameMuscles = true,
    String? intensity, // 'lighter', 'same', 'harder'
  }) async {
    try {
      debugPrint('🔥 [Workout] Extending workout $workoutId with $additionalExercises exercises');
      final response = await apiClient.post(
        '${ApiConstants.workouts}/extend',
        data: {
          'workout_id': workoutId,
          'user_id': userId,
          'additional_exercises': additionalExercises,
          'additional_duration_minutes': additionalDurationMinutes,
          'focus_same_muscles': focusSameMuscles,
          if (intensity != null) 'intensity': intensity,
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 2), // AI generation can take time
        ),
      );
      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Workout extended successfully');
        return Workout.fromJson(response.data as Map<String, dynamic>);
      }
      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error extending workout: $e');
      return null;
    }
  }

  /// Create a custom workout from scratch
  ///
  /// Addresses complaint: "It's much better to just use the Daily Strength app
  /// and put together your own plan."
  Future<Workout?> createCustomWorkout({
    required String userId,
    required String name,
    required String workoutType,
    required String difficulty,
    required List<Map<String, dynamic>> exercises,
    int durationMinutes = 45,
    DateTime? scheduledDate,
  }) async {
    try {
      debugPrint('🏋️ [Workout] Creating custom workout: $name with ${exercises.length} exercises');
      final response = await apiClient.post(
        '${ApiConstants.workouts}/',
        data: {
          'user_id': userId,
          'name': name,
          'type': workoutType,
          'difficulty': difficulty,
          'scheduled_date': (scheduledDate ?? DateTime.now()).toIso8601String(),
          'exercises_json': jsonEncode(exercises),
          'duration_minutes': durationMinutes,
          'generation_method': 'manual',
          'generation_source': 'custom_builder',
        },
      );
      if (response.statusCode == 200) {
        debugPrint('✅ [Workout] Custom workout created successfully');
        return Workout.fromJson(response.data as Map<String, dynamic>);
      }
      debugPrint('⚠️ [Workout] Unexpected status code: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ [Workout] Error creating custom workout: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Issue 3: AI-coach in-workout mutations
  //
  // These mirror the backend tools in
  // services/langgraph_agents/tools/workout_mutation_tools.py and are
  // invoked when the user taps Apply on a ChatActionConfirmCard.
  //
  // Each method returns a (success, errorMessage) tuple so the card can
  // surface the backend's human-readable failure (RLS, stale-list, etc.)
  // instead of swallowing it. Per project rule: no silent fallbacks.
  // ─────────────────────────────────────────────────────────────────────

  /// Log a single completed set via POST /api/v1/workouts/{id}/log-set.
  /// Backend converts ``weight`` from ``weight_unit`` to kg.
  Future<(bool, String?)> logSet({
    required String workoutId,
    required String exerciseId,
    required int setIndex,
    double? weight,
    int? reps,
    int? rir,
    String? side, // 'L' | 'R' | null
    String weightUnit = 'lb',
    bool override = false,
  }) async {
    try {
      final response = await apiClient.post(
        '${ApiConstants.workouts}/$workoutId/log-set',
        data: {
          'exercise_id': exerciseId,
          'set_index': setIndex,
          if (weight != null) 'weight': weight,
          if (reps != null) 'reps': reps,
          if (rir != null) 'rir': rir,
          if (side != null) 'side': side,
          'weight_unit': weightUnit,
          'override': override,
        },
      );
      if (response.statusCode == 200) {
        return (true, null);
      }
      return (false, 'Server error (${response.statusCode}).');
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? ((e.response!.data as Map)['detail']?.toString())
          : null;
      debugPrint('❌ [Workout] logSet failed: ${e.message}');
      return (false, msg ?? 'Failed to log set. Please try again.');
    } catch (e) {
      debugPrint('❌ [Workout] logSet unexpected: $e');
      return (false, 'Failed to log set.');
    }
  }

  /// Group 2+ exercises into a superset.
  Future<(bool, String?)> createSuperset({
    required String workoutId,
    required List<String> exerciseIds,
  }) async {
    try {
      final response = await apiClient.post(
        '${ApiConstants.workouts}/$workoutId/superset',
        data: {'exercise_ids': exerciseIds, 'op': 'create'},
      );
      if (response.statusCode == 200) {
        return (true, null);
      }
      return (false, 'Server error (${response.statusCode}).');
    } on DioException catch (e) {
      final body = e.response?.data;
      String? detail;
      if (body is Map) {
        detail = body['detail']?.toString() ?? body['summary_text']?.toString();
        // Edge case 38: stale exercise list.
        if (body['reason'] == 'exercise list changed') {
          return (false, 'exercise list changed');
        }
      }
      return (false, detail ?? 'Failed to create superset.');
    } catch (e) {
      return (false, 'Failed to create superset.');
    }
  }

  /// Break an existing superset by group id.
  Future<(bool, String?)> breakSuperset({
    required String workoutId,
    required String supersetGroupId,
  }) async {
    try {
      final response = await apiClient.post(
        '${ApiConstants.workouts}/$workoutId/superset',
        data: {'superset_group_id': supersetGroupId, 'op': 'break'},
      );
      if (response.statusCode == 200) {
        return (true, null);
      }
      return (false, 'Server error (${response.statusCode}).');
    } on DioException catch (e) {
      final body = e.response?.data;
      final detail = (body is Map) ? body['detail']?.toString() : null;
      return (false, detail ?? 'Failed to break superset.');
    } catch (e) {
      return (false, 'Failed to break superset.');
    }
  }

  /// Reorder exercises in the workout. ``exerciseIds`` is the desired
  /// order; the backend keeps any in-progress exercise pinned.
  Future<(bool, String?)> reorderExercises({
    required String workoutId,
    required List<String> exerciseIds,
  }) async {
    try {
      final response = await apiClient.post(
        '${ApiConstants.workouts}/$workoutId/reorder',
        data: {'exercise_ids': exerciseIds},
      );
      if (response.statusCode == 200) {
        return (true, null);
      }
      return (false, 'Server error (${response.statusCode}).');
    } on DioException catch (e) {
      final body = e.response?.data;
      String? detail;
      if (body is Map) {
        detail = body['detail']?.toString();
        if (body['reason'] == 'exercise list changed') {
          return (false, 'exercise list changed');
        }
      }
      return (false, detail ?? 'Failed to reorder exercises.');
    } catch (e) {
      return (false, 'Failed to reorder exercises.');
    }
  }

  /// Add one more planned set (or a drop set) to an exercise mid-workout via
  /// POST /api/v1/workouts/{id}/add-set. Backed by the AI coach's ``add_set``
  /// mutation tool. ``isDropSet`` marks the new slot as a back-off (lighter, no
  /// rest) without changing how sets are logged.
  Future<(bool, String?)> addSet({
    required String workoutId,
    required String exerciseName,
    String? exerciseId,
    bool isDropSet = false,
  }) async {
    try {
      final response = await apiClient.post(
        '${ApiConstants.workouts}/$workoutId/add-set',
        data: {
          if (exerciseId != null && exerciseId.isNotEmpty)
            'exercise_id': exerciseId,
          'exercise_name': exerciseName,
          'is_drop_set': isDropSet,
        },
      );
      if (response.statusCode == 200) {
        return (true, null);
      }
      return (false, 'Server error (${response.statusCode}).');
    } on DioException catch (e) {
      final body = e.response?.data;
      final detail = (body is Map) ? body['detail']?.toString() : null;
      debugPrint('❌ [Workout] addSet failed: ${e.message}');
      return (false, detail ?? 'Failed to add set. Please try again.');
    } catch (e) {
      debugPrint('❌ [Workout] addSet unexpected: $e');
      return (false, 'Failed to add set.');
    }
  }
}
