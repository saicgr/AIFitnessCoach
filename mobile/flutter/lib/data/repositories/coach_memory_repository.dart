import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../models/coach_memory.dart';
import '../services/api_client.dart';

/// Repository for the AI coach's long-term memory surface.
///
/// Wraps the `/coach/memory` + `/coach/memory/settings` endpoints. Auth is
/// handled entirely by [ApiClient] (live Supabase token via interceptor) — we
/// only call its `get/put/patch/delete` helpers.
///
/// No silent fallbacks: every method rethrows on error so the UI surfaces a
/// real error state instead of pretending success or showing stale data.
class CoachMemoryRepository {
  final ApiClient _client;

  CoachMemoryRepository(this._client);

  /// `GET /coach/memory` — the enabled flag + list of memories.
  ///
  /// [includeResolved] surfaces closed loops / superseded rows (default off).
  /// [q] is an optional server-side text filter.
  Future<CoachMemoryList> listMemories({
    bool includeResolved = false,
    String? q,
  }) async {
    try {
      final query = <String, dynamic>{
        'include_resolved': includeResolved,
      };
      final trimmed = q?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        query['q'] = trimmed;
      }
      final response = await _client.get(
        ApiConstants.coachMemory,
        queryParameters: query,
      );
      final data = response.data;
      if (data is Map) {
        return CoachMemoryList.fromJson(Map<String, dynamic>.from(data));
      }
      throw StateError(
        'listMemories: unexpected response shape ${data.runtimeType}',
      );
    } catch (e) {
      debugPrint('❌ [CoachMemoryRepo] listMemories failed: $e');
      rethrow;
    }
  }

  /// `GET /coach/memory/settings` — `{ "enabled": bool }`.
  Future<bool> getSettings() async {
    try {
      final response = await _client.get(ApiConstants.coachMemorySettings);
      return _readEnabled(response.data);
    } catch (e) {
      debugPrint('❌ [CoachMemoryRepo] getSettings failed: $e');
      rethrow;
    }
  }

  /// `PUT /coach/memory/settings` — toggles whether the coach may remember
  /// things. Returns the server-confirmed value.
  Future<bool> setEnabled(bool enabled) async {
    try {
      final response = await _client.put(
        ApiConstants.coachMemorySettings,
        data: <String, dynamic>{'enabled': enabled},
      );
      return _readEnabled(response.data);
    } catch (e) {
      debugPrint('❌ [CoachMemoryRepo] setEnabled failed: $e');
      rethrow;
    }
  }

  /// `PATCH /coach/memory/{id}` — correct the content of a memory. Returns the
  /// updated item.
  Future<CoachMemory> editMemory(String id, String content) async {
    try {
      final response = await _client.patch(
        ApiConstants.coachMemoryItem(id),
        data: <String, dynamic>{'content': content},
      );
      final data = response.data;
      if (data is Map) {
        return CoachMemory.fromJson(Map<String, dynamic>.from(data));
      }
      throw StateError(
        'editMemory: unexpected response shape ${data.runtimeType}',
      );
    } catch (e) {
      debugPrint('❌ [CoachMemoryRepo] editMemory failed: $e');
      rethrow;
    }
  }

  /// `POST /coach/memory/{id}/resolve` — close an open loop.
  Future<void> resolveMemory(String id) async {
    try {
      await _client.post(ApiConstants.coachMemoryResolve(id));
    } catch (e) {
      debugPrint('❌ [CoachMemoryRepo] resolveMemory failed: $e');
      rethrow;
    }
  }

  /// `DELETE /coach/memory/{id}` — tombstones the memory by default (soft).
  Future<void> deleteMemory(String id, {bool hard = false}) async {
    try {
      await _client.delete(
        ApiConstants.coachMemoryItem(id),
        queryParameters: <String, dynamic>{'hard': hard},
      );
    } catch (e) {
      debugPrint('❌ [CoachMemoryRepo] deleteMemory failed: $e');
      rethrow;
    }
  }

  /// `DELETE /coach/memory` — purge everything the coach remembers.
  Future<void> forgetEverything() async {
    try {
      await _client.delete(ApiConstants.coachMemory);
    } catch (e) {
      debugPrint('❌ [CoachMemoryRepo] forgetEverything failed: $e');
      rethrow;
    }
  }

  bool _readEnabled(dynamic data) {
    if (data is Map && data.containsKey('enabled')) {
      final v = data['enabled'];
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
    }
    throw StateError('coach memory settings: missing "enabled" in $data');
  }
}

/// DI provider for [CoachMemoryRepository].
final coachMemoryRepositoryProvider = Provider<CoachMemoryRepository>((ref) {
  return CoachMemoryRepository(ref.watch(apiClientProvider));
});

/// Query parameters for the memory list provider — bundled so the
/// `.family` provider has a value-equal key (record equality) and re-queries
/// only when the search text or include-resolved flag actually changes.
typedef CoachMemoryQuery = ({bool includeResolved, String? q});

/// Loads the coach memory list (enabled flag + items) for the given query.
///
/// AsyncValue surfaces loading / error / data to the UI. Auto-disposes so the
/// list isn't kept warm once the screen is gone, and invalidating it (after an
/// edit / delete / resolve / toggle) re-fetches fresh from the server.
final coachMemoryListProvider = FutureProvider.autoDispose
    .family<CoachMemoryList, CoachMemoryQuery>((ref, query) async {
  final repo = ref.watch(coachMemoryRepositoryProvider);
  return repo.listMemories(
    includeResolved: query.includeResolved,
    q: query.q,
  );
});

/// Optimistic in-memory mirror of the master enable toggle.
///
/// Seeded from the list/settings response and flipped synchronously when the
/// user taps the switch (the PUT runs in the background). Reverts on failure.
/// `null` = not yet loaded (show the server value from the list response).
class CoachMemoryEnabledNotifier extends StateNotifier<bool?> {
  CoachMemoryEnabledNotifier(this._repo) : super(null);

  final CoachMemoryRepository _repo;

  /// Seed the toggle from a freshly-loaded list/settings response without
  /// triggering a network call. No-op once the user has locally toggled.
  void seed(bool enabled) {
    state ??= enabled;
  }

  /// Flip the toggle and persist. Returns the confirmed server value; reverts
  /// local state and rethrows on failure so the caller can surface an error.
  Future<bool> setEnabled(bool enabled) async {
    final previous = state;
    state = enabled; // optimistic
    try {
      final confirmed = await _repo.setEnabled(enabled);
      state = confirmed;
      return confirmed;
    } catch (e) {
      state = previous; // revert
      rethrow;
    }
  }
}

final coachMemoryEnabledProvider =
    StateNotifierProvider.autoDispose<CoachMemoryEnabledNotifier, bool?>((ref) {
  return CoachMemoryEnabledNotifier(ref.watch(coachMemoryRepositoryProvider));
});
