import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/program_template.dart';
import '../services/api_client.dart';

/// DI provider for the program-template repository.
final programTemplateRepositoryProvider =
    Provider<ProgramTemplateRepository>((ref) {
  return ProgramTemplateRepository(ref.watch(apiClientProvider));
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
    debugPrint('🏋️ [ProgramTemplate] browseLibrary | filters=$query');
    final resp = await _client.get(
      '$_base/library',
      queryParameters: query.isEmpty ? null : query,
    );
    return ProgramLibraryResult.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// GET /library/{program_id} — full structured preview of one program.
  Future<ProgramTemplate> previewLibraryProgram(String programId) async {
    debugPrint('🏋️ [ProgramTemplate] previewLibraryProgram | id=$programId');
    final resp = await _client.get('$_base/library/$programId');
    return ProgramTemplate.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
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
