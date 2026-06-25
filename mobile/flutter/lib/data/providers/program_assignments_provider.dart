import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../models/user_program_assignment.dart';
import '../repositories/user_program_assignment_repository.dart';
import '../services/data_cache_service.dart';

/// Disk-cache key for the user's active program assignments. Plain string
/// (the cache service accepts any key); scoped per-user by [DataCacheService].
const String _kProgramAssignmentsCacheKey = 'cache_program_assignments';

/// Active program enrollments for the current user.
///
/// Cache-first + `keepAlive` (mirrors the 2026-05 instant-tabs sweep): a
/// returning user sees their last list instantly while a fresh fetch races in
/// the background. On the very first load with no cached value the normal async
/// loading state shows.
///
/// MUST be explicitly invalidated after assign / manage / workout-complete so
/// "Week X of Y" / % complete never drifts — see
/// [refreshProgramAssignments]. Errors propagate so the card's error + Retry
/// state shows; never mock/fallback data.
final programAssignmentsProvider =
    FutureProvider<List<UserProgramAssignment>>((ref) async {
  // Hold the value across tab switches / quick navigation.
  ref.keepAlive();

  final repo = ref.watch(userProgramAssignmentRepositoryProvider);
  final userId = _currentUserId();

  // Step 1 — paint disk-cached assignments instantly when present (stale OK),
  // then overwrite with the network result below. Returning the cache only as
  // a fast first paint; the network call is still awaited so the final value
  // is always fresh.
  List<UserProgramAssignment>? cached;
  try {
    final raw = await DataCacheService.instance.getCachedList(
      _kProgramAssignmentsCacheKey,
      userId: userId,
      returnExpiredOnMiss: true,
    );
    if (raw != null) {
      cached = raw
          .map((e) => UserProgramAssignment.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  } catch (e) {
    debugPrint('⚠️ [ProgramAssignments] cache read error: $e');
  }

  // Step 2 — fetch fresh. On a transient failure WITH a cached value we serve
  // the cache rather than dumping the user to an error card; on a cold miss the
  // error propagates so the Retry state shows (no mock data).
  try {
    final fresh = await repo.listAssignments();
    // Persist for the next instant paint.
    try {
      await DataCacheService.instance.cacheList(
        _kProgramAssignmentsCacheKey,
        fresh.map((a) => a.toJson()).toList(),
        userId: userId,
      );
    } catch (e) {
      debugPrint('⚠️ [ProgramAssignments] cache write error: $e');
    }
    return fresh;
  } catch (e) {
    if (cached != null) {
      debugPrint('⚠️ [ProgramAssignments] fetch failed — serving cache: $e');
      return cached;
    }
    rethrow;
  }
});

/// Convenience: the user's PRIMARY assignments (drive the home hero / "Week X"
/// banner). Derived from [programAssignmentsProvider] so it shares its cache.
final primaryProgramAssignmentsProvider =
    Provider<AsyncValue<List<UserProgramAssignment>>>((ref) {
  return ref.watch(programAssignmentsProvider).whenData(
        (all) => all.where((a) => a.isPrimary && a.isActive).toList(),
      );
});

/// Look up the active assignment that covers a given weekday (0=Mon..6=Sun)
/// in the given slot. Returns null when none matches or the list hasn't loaded.
/// Used by the carousel / active-workout banner to map a workout's day to its
/// program when the workout itself doesn't carry the tag.
UserProgramAssignment? assignmentForWeekday(
  List<UserProgramAssignment> assignments,
  int weekday, {
  ProgramSlot? slot,
}) {
  for (final a in assignments) {
    if (!a.isActive) continue;
    if (slot != null && a.slot != slot) continue;
    if (a.coversWeekday(weekday)) return a;
  }
  return null;
}

/// Invalidate + refresh the assignments list. Call after any mutation
/// (assign a program, rename / re-day / pause / end, or completing a
/// program-sourced workout) so progress + scheduling stay in lock-step.
///
/// Clears the disk cache first so a kept-alive in-memory value can't shadow the
/// fresh fetch, then invalidates the provider to re-run it.
Future<void> refreshProgramAssignments(Ref ref) async {
  await DataCacheService.instance.invalidate(
    _kProgramAssignmentsCacheKey,
    userId: _currentUserId(),
  );
  ref.invalidate(programAssignmentsProvider);
}

/// WidgetRef overload — same as [refreshProgramAssignments] but callable from
/// the UI layer where only a [WidgetRef] is in scope.
Future<void> refreshProgramAssignmentsW(WidgetRef ref) async {
  await DataCacheService.instance.invalidate(
    _kProgramAssignmentsCacheKey,
    userId: _currentUserId(),
  );
  ref.invalidate(programAssignmentsProvider);
}

/// Live user id straight from the Supabase session (never a cached field — see
/// the JWT-expiry rule in project memory). Used to scope the disk cache.
String? _currentUserId() {
  try {
    return Supabase.instance.client.auth.currentUser?.id;
  } catch (_) {
    return null;
  }
}
