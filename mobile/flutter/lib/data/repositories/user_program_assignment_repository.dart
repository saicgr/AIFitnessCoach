import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_program_assignment.dart';
import '../services/api_client.dart';

/// DI provider for the user-program-assignment repository.
final userProgramAssignmentRepositoryProvider =
    Provider<UserProgramAssignmentRepository>((ref) {
  return UserProgramAssignmentRepository(ref.watch(apiClientProvider));
});

/// Thin HTTP wrapper for the user's active program enrollments —
/// `/api/v1/program-templates/assignments`.
///
/// Backs the "My Programs" card + manage sheet. Every method returns a typed
/// model and lets Dio exceptions bubble; the UI layer converts them into human
/// copy. We never swallow errors or substitute mock data
/// (see `feedback_no_silent_fallbacks`). Modeled on
/// [ProgramTemplateRepository].
class UserProgramAssignmentRepository {
  final ApiClient _client;
  UserProgramAssignmentRepository(this._client);

  static const _base = '/program-templates/assignments';

  /// GET /assignments — list the user's active program enrollments.
  ///
  /// Backend returns `{assignments:[ {user_program_assignments cols} +
  /// display_name, duration_weeks, source_program_id ]}` (primary first).
  /// Tolerant of a bare list payload too. Wrapped in a short transient-retry
  /// so a deploy blip / cold-cache window doesn't dump the user to the error
  /// card on the first failure; non-transient errors (auth / 4xx) propagate.
  Future<List<UserProgramAssignment>> listAssignments() async {
    debugPrint('🏋️ [ProgramAssignments] listAssignments');
    final data = await _getWithRetry(_base);
    final raw = data is Map
        ? (data['assignments'] ?? const [])
        : (data is List ? data : const []);
    if (raw is! List) return const [];
    final out = <UserProgramAssignment>[];
    for (final e in raw) {
      if (e is Map) {
        out.add(
          UserProgramAssignment.fromJson(Map<String, dynamic>.from(e)),
        );
      }
    }
    // Defensive ordering: primary first, then by current week (the backend
    // already sorts primary-first, but never trust a single source of truth
    // for ordering that drives the home hero).
    out.sort((a, b) {
      if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
      return 0;
    });
    return out;
  }

  /// PATCH /assignments/{id} — rename / re-day / re-slot / pause-resume / end.
  ///
  /// Only non-null fields are sent. [status] accepts `active` | `paused` |
  /// `completed` | `abandoned`. Returns the updated assignment.
  Future<UserProgramAssignment> updateAssignment(
    String id, {
    String? customProgramName,
    List<int>? assignedDays,
    ProgramSlot? slot,
    String? status,
  }) async {
    final body = <String, dynamic>{
      if (customProgramName != null) 'custom_program_name': customProgramName,
      if (assignedDays != null) 'assigned_days': assignedDays,
      if (slot != null) 'slot': slot == ProgramSlot.addon ? 'addon' : 'primary',
      if (status != null) 'status': status,
    };
    debugPrint('🏋️ [ProgramAssignments] updateAssignment | id=$id body=$body');
    final resp = await _client.patch('$_base/$id', data: body);
    return UserProgramAssignment.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// DELETE /assignments/{id} — end (un-enroll from) a program.
  ///
  /// The backend stops expanding future workouts for this assignment; already
  /// completed sessions are kept (provenance preserved).
  Future<void> deleteAssignment(String id) async {
    debugPrint('🏋️ [ProgramAssignments] deleteAssignment | id=$id');
    await _client.delete('$_base/$id');
  }

  // ---------------------------------------------------------------------------
  // Internal — shared transient-retry GET (mirrors ProgramTemplateRepository).
  // ---------------------------------------------------------------------------

  Future<dynamic> _getWithRetry(String path) async {
    const maxAttempts = 3;
    for (var attempt = 1;; attempt++) {
      try {
        final resp = await _client.get(path);
        return resp.data;
      } on DioException catch (e) {
        if (attempt >= maxAttempts || !_isTransientFailure(e)) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
  }

  /// True for failures worth retrying: connection/receive/send timeouts,
  /// dropped connections, and 502/503/504. NOT 4xx (auth, bad input).
  bool _isTransientFailure(DioException e) {
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
}
