import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/program_template.dart';
import '../models/user_program_assignment.dart';
import '../services/api_client.dart';

/// Response for `POST /program-templates/assign` (the unified Start-program
/// flow). Kept here (not in the read-only model file) so this stream owns it.
class AssignResult {
  final bool success;
  final String? assignmentId;
  final String? templateId;
  final int workoutsCreated;

  const AssignResult({
    required this.success,
    this.assignmentId,
    this.templateId,
    this.workoutsCreated = 0,
  });

  factory AssignResult.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v.trim()) ?? 0;
      return 0;
    }

    final s = json['success'];
    return AssignResult(
      success: s is bool ? s : true,
      assignmentId: json['assignment_id']?.toString(),
      templateId: json['template_id']?.toString(),
      workoutsCreated: toInt(json['workouts_created']),
    );
  }
}

/// DI provider for the program-template repository.
final programTemplateRepositoryProvider =
    Provider<ProgramTemplateRepository>((ref) {
  return ProgramTemplateRepository(ref.watch(apiClientProvider));
});

/// Filter key for [programLibraryBrowseProvider]. A Dart record gives value
/// equality, so the same filter combo reuses one cached provider instance.
typedef ProgramLibraryFilter = ({
  String? category,
  String? difficulty,
  int? sessionsPerWeek,
  String? search,
  List<String>? goals,
  int? durationMin,
  int? durationMax,
});

/// Cache-first browse of the curated program library, keyed by the active
/// filter tuple. `keepAlive` means a returning user (same filters) sees the
/// last result instantly instead of a blocking skeleton every open; the first
/// load with no cached value still resolves through the normal async states.
///
/// The screen invalidates this provider for the current filter to force a
/// silent refresh. Errors propagate so the existing error + Retry card shows
/// (we never substitute mock/fallback data).
final programLibraryBrowseProvider = FutureProvider.autoDispose
    .family<ProgramLibraryResult, ProgramLibraryFilter>((ref, filter) async {
  // Hold the result across screen rebuilds / quick back-and-forth navigation
  // so it's served instantly on return. autoDispose still reclaims it once no
  // longer referenced for a while.
  ref.keepAlive();
  final repo = ref.watch(programTemplateRepositoryProvider);
  // Scoped resilience: the library is static reference data behind a single
  // GET. A transient backend blip — a deploy restart, a cold cache prewarm, a
  // whole-backend stall — shouldn't dump the user straight to the "could not
  // load the program library" card on the first failure. Retry a couple of
  // times on TRANSIENT failures only; real errors (auth / 4xx) propagate
  // immediately so we never mask a genuine problem or substitute mock data.
  return _browseLibraryWithRetry(repo, filter);
});

/// Browse the library, retrying up to 3 times on transient network/server
/// failures with a short backoff. Non-transient errors rethrow on attempt 1.
Future<ProgramLibraryResult> _browseLibraryWithRetry(
  ProgramTemplateRepository repo,
  ProgramLibraryFilter filter,
) async {
  const maxAttempts = 3;
  for (var attempt = 1;; attempt++) {
    try {
      return await repo.browseLibrary(
        category: filter.category,
        difficulty: filter.difficulty,
        sessionsPerWeek: filter.sessionsPerWeek,
        search: filter.search,
        goals: filter.goals,
        durationMin: filter.durationMin,
        durationMax: filter.durationMax,
      );
    } on DioException catch (e) {
      if (attempt >= maxAttempts || !_isTransientLibraryFailure(e)) rethrow;
      // 400ms then 800ms — enough to ride out a restart / cold-cache window.
      await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
    }
  }
}

/// True for failures worth retrying: connection/receive/send timeouts, dropped
/// connections, and 502/503/504 (gateway / restart). NOT 4xx (auth, bad input).
bool _isTransientLibraryFailure(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.connectionError:
      return true;
    default:
      final code = e.response?.statusCode ?? 0;
      return code == 502 || code == 503 || code == 504;
  }
}

/// Cache-first curated-featured programs (`GET /library/featured`). Same
/// cache-first + transient-retry posture as [programLibraryBrowseProvider]:
/// `keepAlive` so a returning user sees the last result instantly. Errors
/// propagate so the screen's error + Retry card shows; never mock data.
final programFeaturedProvider =
    FutureProvider.autoDispose<ProgramLibraryResult>((ref) async {
  ref.keepAlive();
  final repo = ref.watch(programTemplateRepositoryProvider);
  return repo.getFeatured();
});

/// Cache-first personalized recommendations (`GET /library/recommended`).
/// Same posture as [programFeaturedProvider].
final programRecommendedProvider =
    FutureProvider.autoDispose<ProgramLibraryResult>((ref) async {
  ref.keepAlive();
  final repo = ref.watch(programTemplateRepositoryProvider);
  return repo.getRecommended();
});

/// Cache-first category facet counts (`GET /library/categories`) — drives the
/// category chips / filter rail. Same posture as [programFeaturedProvider].
final programCategoryCountsProvider = FutureProvider.autoDispose<
    List<({String category, int count})>>((ref) async {
  ref.keepAlive();
  final repo = ref.watch(programTemplateRepositoryProvider);
  return repo.getCategoryCounts();
});

/// Thin HTTP wrapper for `/api/v1/program-templates/*`.
///
/// Every method returns a typed model and lets Dio exceptions bubble — the
/// screen layer converts them into human copy. We never swallow errors or
/// substitute mock data (see `feedback_no_silent_fallbacks`). Modeled on
/// `body_analyzer_repository.dart`.
class ProgramTemplateRepository {
  final ApiClient _client;
  ProgramTemplateRepository(this._client);

  static const _base = '/program-templates';

  // -------------------------------------------------------------------------
  // Library — the first-ever API over the 259-row `programs` table.
  // -------------------------------------------------------------------------

  /// GET /library — browse the curated program library.
  ///
  /// All filters are optional. `category` matches `program_category`,
  /// `difficulty` matches `difficulty_level`, `sessionsPerWeek` matches
  /// `sessions_per_week`, `search` is a free-text name match.
  Future<ProgramLibraryResult> browseLibrary({
    String? category,
    String? difficulty,
    int? sessionsPerWeek,
    String? search,
    List<String>? goals,
    int? durationMin,
    int? durationMax,
  }) async {
    final query = <String, dynamic>{};
    if (category != null && category.isNotEmpty) {
      query['category'] = category;
    }
    if (difficulty != null && difficulty.isNotEmpty) {
      query['difficulty_level'] = difficulty;
    }
    if (sessionsPerWeek != null) {
      query['sessions_per_week'] = sessionsPerWeek;
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (goals != null) {
      final clean = goals
          .map((g) => g.trim())
          .where((g) => g.isNotEmpty)
          .toList(growable: false);
      if (clean.isNotEmpty) {
        query['goals'] = clean.join(',');
      }
    }
    if (durationMin != null) {
      query['duration_min'] = durationMin;
    }
    if (durationMax != null) {
      query['duration_max'] = durationMax;
    }
    debugPrint('🏋️ [ProgramTemplate] browseLibrary | filters=$query');
    final resp = await _client.get(
      '$_base/library',
      queryParameters: query.isEmpty ? null : query,
    );
    return ProgramLibraryResult.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// GET /library/featured — curated/editorial featured programs.
  ///
  /// Same `{total, programs}` shape as [browseLibrary]. Wrapped in the shared
  /// transient-retry so a deploy blip doesn't dump the user to the error card.
  Future<ProgramLibraryResult> getFeatured() {
    debugPrint('🏋️ [ProgramTemplate] getFeatured');
    return _getLibraryResultWithRetry('$_base/library/featured');
  }

  /// GET /library/recommended — personalized program recommendations.
  ///
  /// Same `{total, programs}` shape as [browseLibrary]. Wrapped in the shared
  /// transient-retry.
  Future<ProgramLibraryResult> getRecommended() {
    debugPrint('🏋️ [ProgramTemplate] getRecommended');
    return _getLibraryResultWithRetry('$_base/library/recommended');
  }

  /// GET /library/categories — category facet counts for the filter rail.
  ///
  /// Returns `{categories:[{category, count}]}`; we surface a list of typed
  /// `(category, count)` records. Wrapped in the shared transient-retry.
  Future<List<({String category, int count})>> getCategoryCounts() async {
    debugPrint('🏋️ [ProgramTemplate] getCategoryCounts');
    final data = await _getMapWithRetry('$_base/library/categories');
    final raw = data['categories'];
    final out = <({String category, int count})>[];
    if (raw is List) {
      for (final c in raw) {
        if (c is Map) {
          final category = c['category']?.toString() ?? '';
          if (category.isEmpty) continue;
          final count = _toInt(c['count']);
          out.add((category: category, count: count));
        }
      }
    }
    return out;
  }

  /// Coerce a loose JSON number/string into an int, defaulting to 0.
  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
  }

  /// GET a `{total, programs}` route with the shared transient-retry posture
  /// (same backoff + transient classification as [_browseLibraryWithRetry]).
  Future<ProgramLibraryResult> _getLibraryResultWithRetry(String path) async {
    final data = await _getMapWithRetry(path);
    return ProgramLibraryResult.fromJson(data);
  }

  /// GET a JSON object with up to 3 attempts, retrying only TRANSIENT failures
  /// (timeouts / dropped connections / 502-503-504). Non-transient errors
  /// (auth / 4xx) rethrow immediately. Mirrors [_browseLibraryWithRetry] for
  /// the static library reference routes.
  Future<Map<String, dynamic>> _getMapWithRetry(String path) async {
    const maxAttempts = 3;
    for (var attempt = 1;; attempt++) {
      try {
        final resp = await _client.get(path);
        return Map<String, dynamic>.from(resp.data as Map);
      } on DioException catch (e) {
        if (attempt >= maxAttempts || !_isTransientLibraryFailure(e)) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
  }

  /// GET /library/{program_id} — full structured preview of one program.
  Future<ProgramTemplate> previewLibraryProgram(String programId) async {
    debugPrint('🏋️ [ProgramTemplate] previewLibraryProgram | id=$programId');
    final resp = await _client.get('$_base/library/$programId');
    return ProgramTemplate.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// GET /library/{program_id} — the SAME endpoint as [previewLibraryProgram],
  /// but parsed into BOTH the editorial card (name/tagline/who-for/phases/
  /// joined_count) and the normalized sample-week template (name/days). The
  /// detail page needs both: the card-level editorial + phase content for the
  /// Overview tab, and the day-by-day for the Schedule tab. One request, two
  /// views over the same payload (the backend merges card fields + `**normalized`).
  Future<({ProgramLibraryCard card, ProgramTemplate sampleWeek})>
      getLibraryDetail(String programId) async {
    debugPrint('🏋️ [ProgramTemplate] getLibraryDetail | id=$programId');
    final resp = await _client.get('$_base/library/$programId');
    final data = Map<String, dynamic>.from(resp.data as Map);
    // The detail payload carries the id as `program_id` (not `id`), so seed the
    // id the card model reads — preserving the caller's prefixed/branded form
    // — before parsing. Don't clobber an `id` if the backend ever sends one.
    final cardData = Map<String, dynamic>.from(data);
    cardData.putIfAbsent('id', () => data['program_id'] ?? programId);
    if ((cardData['id']?.toString() ?? '').isEmpty) {
      cardData['id'] = programId;
    }
    return (
      card: ProgramLibraryCard.fromJson(cardData),
      sampleWeek: ProgramTemplate.fromJson(data),
    );
  }

  // -------------------------------------------------------------------------
  // Favorites — the user's hearted library programs (Your Programs hub).
  // -------------------------------------------------------------------------

  /// GET /favorites — the user's favorited library programs as full cards.
  Future<List<ProgramLibraryCard>> listFavorites() async {
    debugPrint('🏋️ [ProgramTemplate] listFavorites');
    final resp = await _client.get('$_base/favorites');
    final data = Map<String, dynamic>.from(resp.data as Map);
    final raw = data['programs'];
    final out = <ProgramLibraryCard>[];
    if (raw is List) {
      for (final p in raw) {
        if (p is Map) {
          out.add(ProgramLibraryCard.fromJson(Map<String, dynamic>.from(p)));
        }
      }
    }
    return out;
  }

  /// GET /favorites/ids — just the favorited program ids (drives heart state).
  Future<Set<String>> favoriteIds() async {
    debugPrint('🏋️ [ProgramTemplate] favoriteIds');
    final resp = await _client.get('$_base/favorites/ids');
    final data = Map<String, dynamic>.from(resp.data as Map);
    final raw = data['program_ids'];
    final out = <String>{};
    if (raw is List) {
      for (final id in raw) {
        final s = id?.toString();
        if (s != null && s.isNotEmpty) out.add(s);
      }
    }
    return out;
  }

  /// POST /favorites {program_id} — favorite a program.
  Future<void> addFavorite(String programId) async {
    debugPrint('🏋️ [ProgramTemplate] addFavorite | id=$programId');
    await _client.post('$_base/favorites', data: {'program_id': programId});
  }

  /// DELETE /favorites/{program_id} — un-favorite a program.
  Future<void> removeFavorite(String programId) async {
    debugPrint('🏋️ [ProgramTemplate] removeFavorite | id=$programId');
    await _client.delete('$_base/favorites/$programId');
  }

  /// POST /from-program/{program_id} — clone a library program into a NEW
  /// editable saved template. Returns the saved row.
  ///
  /// Throws [ProgramParseException] with `parse_error` if the source program
  /// has no structured workouts (the backend 422s).
  Future<ProgramTemplate> importFromProgram(String programId) async {
    debugPrint('🏋️ [ProgramTemplate] importFromProgram | id=$programId');
    try {
      final resp = await _client.post('$_base/from-program/$programId');
      return ProgramTemplate.fromJson(
        Map<String, dynamic>.from(resp.data as Map),
      );
    } on DioException catch (e) {
      throw _mapParseError(e) ?? e;
    }
  }

  // -------------------------------------------------------------------------
  // Assign — enroll the user in a library program (slot/days/start-date) and
  // expand it forward into scheduled workouts. The unified "Start program"
  // flow (Primary vs Add-on, Replace vs Run-alongside) calls this.
  // -------------------------------------------------------------------------

  /// POST /assign — enroll the user in a library program.
  ///
  /// [programId] is the library card id (curated plain id or branded uuid —
  /// pass the bare uuid for branded). [assignedDays] are weekday ints
  /// 0=Mon..6=Sun the program occupies. [slot] is `primary` | `addon`.
  /// [startDate] is `YYYY-MM-DD`. [replace] (primary only) replaces the current
  /// primary instead of running alongside. [durationWeeks] optionally overrides
  /// the program's length. [customize] carries the AI-tailoring toggles.
  Future<AssignResult> assignProgram({
    required String programId,
    required List<int> assignedDays,
    required ProgramSlot slot,
    required String startDate,
    bool replace = false,
    int? durationWeeks,
    bool adaptToLevel = false,
    bool swapForInjuries = false,
    bool fitEquipment = false,
  }) async {
    final body = <String, dynamic>{
      'program_id': programId,
      'assigned_days': assignedDays,
      'slot': slot == ProgramSlot.addon ? 'addon' : 'primary',
      'start_date': startDate,
      'replace': replace,
      if (durationWeeks != null) 'duration_weeks': durationWeeks,
      if (adaptToLevel || swapForInjuries || fitEquipment)
        'customize': {
          'adapt_to_level': adaptToLevel,
          'swap_for_injuries': swapForInjuries,
          'fit_equipment': fitEquipment,
        },
    };
    debugPrint('🏋️ [ProgramTemplate] assignProgram | id=$programId '
        'slot=${body['slot']} days=$assignedDays replace=$replace');
    try {
      final resp = await _client.post('$_base/assign', data: body);
      return AssignResult.fromJson(
        Map<String, dynamic>.from(resp.data as Map),
      );
    } on DioException catch (e) {
      throw _mapParseError(e) ?? e;
    }
  }

  // -------------------------------------------------------------------------
  // Parse — free-text → reviewable (NOT saved) template draft.
  // -------------------------------------------------------------------------

  /// POST /parse — parse a free-text program description.
  ///
  /// The response is a DRAFT (`source='parsed'`, no `id`). The user reviews /
  /// edits it, then calls [createTemplate] to persist.
  ///
  /// Throws [ProgramParseException] on a 422 — `not_a_program` when the text
  /// was not a workout program, `parse_error` when parsing failed outright.
  Future<ProgramTemplate> parseDescription(String description) async {
    debugPrint(
        '🤖 [ProgramTemplate] parseDescription | len=${description.length}');
    try {
      final resp = await _client.post(
        '$_base/parse',
        data: {'description': description},
      );
      return ProgramTemplate.fromJson(
        Map<String, dynamic>.from(resp.data as Map),
      );
    } on DioException catch (e) {
      throw _mapParseError(e) ?? e;
    }
  }

  /// POST /import-photo — OCR a photo/PDF of a written program into a DRAFT
  /// template (`source='imported'`, no `id`). The user reviews / edits it in
  /// the builder, then calls [createTemplate] to persist.
  ///
  /// Pass EITHER [imageBase64] + [mimeType] (in-memory bytes) OR [s3Key] (an
  /// already-uploaded object). Throws [ProgramParseException] on a 422 —
  /// `not_a_program` when the image wasn't a program, `parse_error` otherwise.
  Future<ProgramTemplate> importFromPhoto({
    String? imageBase64,
    String? mimeType,
    String? s3Key,
  }) async {
    final body = <String, dynamic>{};
    if (s3Key != null && s3Key.isNotEmpty) {
      body['s3_key'] = s3Key;
    } else if (imageBase64 != null && imageBase64.isNotEmpty) {
      body['image_base64'] = imageBase64;
      body['mime_type'] = mimeType ?? 'image/jpeg';
    } else {
      throw const ProgramParseException(
        'parse_error',
        'No image provided. Pick a photo or PDF of your program first.',
      );
    }
    debugPrint('🤖 [ProgramTemplate] importFromPhoto | '
        '${s3Key != null ? 's3=$s3Key' : 'bytes=${imageBase64?.length}'}');
    try {
      final resp = await _client.post('$_base/import-photo', data: body);
      return ProgramTemplate.fromJson(
        Map<String, dynamic>.from(resp.data as Map),
      );
    } on DioException catch (e) {
      throw _mapParseError(e) ?? e;
    }
  }

  // -------------------------------------------------------------------------
  // CRUD.
  // -------------------------------------------------------------------------

  /// POST / — create a template from authored / parsed JSON.
  ///
  /// Throws [ProgramParseException] (`parse_error`) if every day is rest —
  /// the backend rejects an all-rest program.
  Future<ProgramTemplate> createTemplate(ProgramTemplate template) async {
    debugPrint('🏋️ [ProgramTemplate] createTemplate | name=${template.name}');
    try {
      final resp = await _client.post(
        _base,
        data: template.toCreateJson(),
      );
      return ProgramTemplate.fromJson(
        Map<String, dynamic>.from(resp.data as Map),
      );
    } on DioException catch (e) {
      throw _mapParseError(e) ?? e;
    }
  }

  /// GET /user/{user_id} — list templates owned by a user.
  Future<List<ProgramTemplate>> listForUser(String userId) async {
    debugPrint('🏋️ [ProgramTemplate] listForUser | user=$userId');
    final resp = await _client.get('$_base/user/$userId');
    final data = resp.data;
    final list = data is List
        ? data
        : (data is Map ? (data['templates'] as List? ?? const []) : const []);
    return list
        .whereType<Object>()
        .map((e) =>
            ProgramTemplate.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// GET /{template_id} — fetch one saved template.
  Future<ProgramTemplate> getTemplate(String templateId) async {
    debugPrint('🏋️ [ProgramTemplate] getTemplate | id=$templateId');
    final resp = await _client.get('$_base/$templateId');
    return ProgramTemplate.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// PATCH /{template_id} — edit a saved template.
  Future<ProgramTemplate> updateTemplate(
    String templateId,
    ProgramTemplate template,
  ) async {
    debugPrint('🏋️ [ProgramTemplate] updateTemplate | id=$templateId');
    final resp = await _client.patch(
      '$_base/$templateId',
      data: template.toCreateJson(),
    );
    return ProgramTemplate.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// DELETE /{template_id} — delete a saved template.
  Future<void> deleteTemplate(String templateId) async {
    debugPrint('🏋️ [ProgramTemplate] deleteTemplate | id=$templateId');
    await _client.delete('$_base/$templateId');
  }

  // -------------------------------------------------------------------------
  // Scheduling.
  // -------------------------------------------------------------------------

  /// POST /{template_id}/schedule — expand a template forward into workouts.
  ///
  /// [startDate] must be `YYYY-MM-DD`. [weeks] is clamped 1..12 by the caller.
  /// [dayAlignment] is `start_today` or `calendar_weekday`. [dayTimes] maps a
  /// stringified day index to a `HH:MM` user-local time; absent days default
  /// to noon server-side.
  Future<ScheduleResult> scheduleTemplate(
    String templateId, {
    required String startDate,
    required int weeks,
    required String dayAlignment,
    required Map<String, String> dayTimes,
  }) async {
    debugPrint(
        '🏋️ [ProgramTemplate] scheduleTemplate | id=$templateId weeks=$weeks '
        'align=$dayAlignment times=${dayTimes.length}');
    final resp = await _client.post(
      '$_base/$templateId/schedule',
      data: {
        'start_date': startDate,
        'weeks': weeks,
        'day_alignment': dayAlignment,
        'day_times': dayTimes,
      },
    );
    return ScheduleResult.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// POST /{template_id}/regenerate-future — rebuild not-yet-completed
  /// workouts after a template edit.
  Future<ScheduleResult> regenerateFuture(String templateId) async {
    debugPrint('🏋️ [ProgramTemplate] regenerateFuture | id=$templateId');
    final resp = await _client.post('$_base/$templateId/regenerate-future');
    return ScheduleResult.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  // -------------------------------------------------------------------------
  // Error mapping.
  // -------------------------------------------------------------------------

  /// Maps a 422 Dio response carrying `{error, message}` into a typed
  /// [ProgramParseException]. Returns null when the error is something else
  /// so the caller can rethrow the original [DioException].
  ProgramParseException? _mapParseError(DioException e) {
    final resp = e.response;
    if (resp == null || resp.statusCode != 422) return null;
    final body = resp.data;
    if (body is Map) {
      final code = body['error']?.toString();
      if (code != null && code.isNotEmpty) {
        final msg = body['message']?.toString() ??
            'We could not read that program. Please check the format and try again.';
        return ProgramParseException(code, msg);
      }
      // FastAPI's default 422 shape — surface as a generic parse error.
      final detail = body['detail'];
      if (detail != null) {
        return ProgramParseException('parse_error', detail.toString());
      }
    }
    return ProgramParseException(
      'parse_error',
      'We could not read that program. Please check the format and try again.',
    );
  }
}
