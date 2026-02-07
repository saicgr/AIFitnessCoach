import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/schedule_item.dart';
import '../repositories/schedule_repository.dart';

/// Simple refresh trigger -- increment to invalidate schedule providers
final scheduleRefreshProvider = StateProvider<int>((ref) => 0);

/// Fetches the up-next schedule items for the current user
final upNextScheduleProvider =
    FutureProvider.autoDispose<UpNextResponse>((ref) async {
  // Watch refresh trigger so providers auto-refresh when it changes
  ref.watch(scheduleRefreshProvider);

  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) {
    debugPrint('⚠️ [ScheduleProvider] No user ID for up-next');
    return UpNextResponse(items: [], asOf: DateTime.now());
  }

  final repository = ref.watch(scheduleRepositoryProvider);
  try {
    debugPrint('🔍 [ScheduleProvider] Fetching up-next for user $userId');
    final upNext = await repository.getUpNext(userId);
    debugPrint(
        '✅ [ScheduleProvider] Up-next loaded: ${upNext.items.length} items');
    return upNext;
  } catch (e) {
    debugPrint('❌ [ScheduleProvider] Error fetching up-next: $e');
    rethrow;
  }
});

/// Fetches the daily schedule for a specific date
final dailyScheduleProvider = FutureProvider.autoDispose
    .family<DailyScheduleResponse, DateTime>((ref, date) async {
  // Watch refresh trigger so providers auto-refresh when it changes
  ref.watch(scheduleRefreshProvider);

  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) {
    debugPrint('⚠️ [ScheduleProvider] No user ID for daily schedule');
    return DailyScheduleResponse(
      date: date,
      items: [],
      summary: {'total_items': 0, 'completed': 0, 'upcoming': 0},
    );
  }

  final repository = ref.watch(scheduleRepositoryProvider);
  try {
    debugPrint(
        '📅 [ScheduleProvider] Fetching daily schedule for ${date.toIso8601String().split('T')[0]}');
    final schedule = await repository.getDailySchedule(userId, date);
    debugPrint(
        '✅ [ScheduleProvider] Daily schedule loaded: ${schedule.items.length} items');
    return schedule;
  } catch (e) {
    debugPrint('❌ [ScheduleProvider] Error fetching daily schedule: $e');
    rethrow;
  }
});
